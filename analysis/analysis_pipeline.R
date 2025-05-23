#install.packages("tidyverse")
#install.packages("rstatix")
#install.packages("coin") # Used internally by rstatix's Wilcox_effsize()
library(tidyverse)
library(rstatix)

options(scipen = 50) # Show decimals instead of scientific notation (RStudio)


#============================== SELECT WHICH RQ ===============================#

use_rq1 = TRUE

#============================ LOAD EXPERIMENT DATA ============================#

# Load data
if (use_rq1) {
  raw_df <- read.csv("./data/rq1_flat_df.csv")
} else {
  raw_df <- read.csv("./data/rq2_flat_df.csv")
}


#=============================== PRE-PROCESSING ===============================#

# Metrics to test
rq1_metrics <- c("balanced_accuracy", "recall", "precision", "f1")
rq2_metrics <- c("time_to_analyze", "vram_max_usage_mib")

# Set which RQ metrics to use
metrics <- if (use_rq1) rq1_metrics else rq2_metrics


# Expand the metrics columns to "true" long format
long_df <- raw_df %>%
  select(model, quantization, dataset, iteration, all_of(metrics)) %>%
  pivot_longer(cols = all_of(metrics), names_to = "metric", values_to = "value")

# Group by: model, dataset, metric
grouped_df <- long_df %>%
  group_by(model, dataset, metric) %>%
  nest() # puts the actual data inside a tibble for each row (group)



#=============================== FRIEDMAN TEST ================================#

# Wrapper function for Friedman test
# This lets us apply the function on the nested data
run_friedman <- function(df) {
  friedman_test(df, value ~ quantization | iteration)
}

# Apply test using the map function
friedman_results <- grouped_df %>%
  mutate(test_result = map(data, run_friedman)) %>%
  unnest(cols = test_result) %>% # this unpacks the test result tibble
  select(-.y., -method) %>% # remove redundant columns
  mutate(significant = p < 0.05)

# Filter the significant results
significant_results <- friedman_results %>%
  filter(p < 0.05)



#=================== FILTER NO-VARIANCE QUANTIZATION GROUPS ===================#

# Function to remove quantization groups with zero or NA variance
filter_variance <- function(df) {
  # Calculate variance per quantization group
  group_vars <- df %>%
    group_by(quantization) %>%
    summarize(var = var(value), .groups = "drop") %>%
    filter(!is.na(var) & var > 0)
  
  # Keep only groups with variance
  df %>% 
    filter(quantization %in% group_vars$quantization)
}

# Apply the filtering to each nested data frame
filtered_df <- grouped_df %>%
  mutate(data = map(data, filter_variance))

# Remove rows with not enough quantization groups left for pairwise comparison
filtered_df <- filtered_df %>%
  # n_distinct counts distinct quantization groups for each nested dataframe
  # map_lgl returns a vector of boolean values; filter rows using the vector
  filter(map_lgl(data, function(x) dplyr::n_distinct(x$quantization) >= 2))



#========================= POST-HOC PAIRWISE TESTING ==========================#

# Wrapper function for Pairwise Wilcox test
run_posthoc <- function(df) {
  pairwise_wilcox_test(
    df, 
    value ~ quantization,
    paired = TRUE,
    p.adjust.method = "holm")
}

# Guide--Interpreting adjusted P-value column:
# ***	== Very strong evidence of difference
# **  == Strong evidence
# *	  == Moderate evidence
# ns	== Not significant


# Version evaluating ALL pairs regardless of Friedman results
posthoc_results <- filtered_df %>%
  mutate(posthoc = map(data, run_posthoc))

# Version with filtering to only evaluate significant results
#posthoc_results <- filtered_df %>%
#  semi_join(significant_results, by = c("model", "dataset", "metric")) %>%
#  mutate(posthoc = map(data, run_posthoc))



#========================== EFFECT SIZE CALCULATION ===========================#

run_effsize <- function(df) {
  # Count the unique number of quantization groups
  q_groups <- unique(df$quantization)
  
  # If the row does not contain at least two quantization groups, we can't
  # perform any meaningful pairwise (effect size) analysis
  if (length(q_groups) < 2) {
    return(tibble::tibble(group1 = NA, group2 = NA, effsize = NA, magnitude = NA, status = "skip"))
  }
  
  # Generate all pairwise combinations (n choose 2) of quantization groups
  group_pairs <- combn(sort(q_groups), 2, simplify = FALSE)
  
  # Apply wilcox_effsize to each unique pair of quantization groups individually
  # This avoids losing all results due to the error: "all pairwise differences equal zero",
  # which occurs when all values in the paired comparison are identical (zero difference)
  # By evaluating one pair at a time, we preserve valid results even if one pair fails
  map_dfr(group_pairs, function(pair) {
    df_pair <- df %>% filter(quantization %in% pair)
    
    # Try to compute effect size just for this pair
    result <- tryCatch({
      eff <- wilcox_effsize(df_pair, value ~ quantization, paired = TRUE)
      eff %>% mutate(status = "ok")
    }, error = function(e) {
      # This catch handles errors like "all pairwise differences equal zero"
      # Instead of skipping the result entirely, we log the pair with NA values,
      # making it explicit which group comparisons failed
      message("Effect size failed for pair: ", paste(pair, collapse = " vs "), " → ", e$message)
      tibble(
        group1 = pair[1],
        group2 = pair[2],
        effsize = NA_real_,
        # Add n1 and n2 for schema consistency, to not break the function that
        # combines the nested posthoc + effect size dataframes
        n1 = df_pair %>% filter(quantization == pair[1]) %>% nrow(),
        n2 = df_pair %>% filter(quantization == pair[2]) %>% nrow(),
        magnitude = NA_character_,
        status = "error"
      )
    })
    
    return(result)
  })
}

# Apply effect size to each nested dataframe
effsize_results <- posthoc_results %>%
  mutate(effsize = map(data, run_effsize))



#============================== COMBINE RESULTS ===============================#

# Combine posthoc and effect size nested data frames row-by-row
combined_results <- effsize_results %>%
  mutate(
    # Combine the posthoc and effsize nested data frames
    # The map2 function iterates over two arguments simultaneously
    analysis_results = map2(posthoc, effsize, function(post, eff) {
      # Drop the n1 and n2 columns from the effect size table (eff)
      # to prevent duplicated columns (e.g., n1.x, n1.y) after the join
      eff_clean <- eff %>% select(-n1, -n2)
      
      # Join by group1/group2 (inner join keeps only matching comparisons)
      full_join(post, eff_clean, by = c("group1", "group2")) %>%
        select(
          group1, group2,
          n1, n2, statistic, p, p.adj, p.adj.signif,
          effsize, magnitude, status
        )
    })
  ) %>%
  select(-posthoc, -effsize)  # Drop the old nested columns if not needed



#============================== OUTPUT RESULTS ================================#


# Remove the nested data before flattening
summary_results <- combined_results %>%
  select(-data) %>%
  unnest(analysis_results)


write_csv(summary_results, "results/rq1_post-hoc_results.csv")


