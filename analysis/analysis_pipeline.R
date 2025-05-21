#install.packages("tidyverse")
#install.packages("rstatix")
library(tidyverse)
library(rstatix)


#============================ LOAD EXPERIMENT DATA ===========================#

# Load data
raw_df <- read.csv("./data/rq1_flat_df.csv")
head(raw_df)


#=============================== PRE-PROCESSING ==============================#

# Metrics to test
metrics <- c("balanced_accuracy", "recall", "precision", "f1")

# Expand the metrics columns to "true" long format
long_df <- raw_df %>%
  select(model, quantization, dataset, iteration, all_of(metrics)) %>%
  pivot_longer(cols = all_of(metrics), names_to = "metric", values_to = "value")

# Group by: model, dataset, metric
grouped_df <- long_df %>%
  group_by(model, dataset, metric) %>%
  nest() # puts the actual data inside a tibble for each row (group)


#=============================== FRIEDMAN TEST ===============================#

# Wrapper function for Friedman test
# This lets us apply the function on the nested data
run_friedman <- function(df) {
  # TODO: the variable assignment might even be redundant
  #result <- friedman_test(df, value ~ quantization | iteration)
  friedman_test(df, value ~ quantization | iteration)
}

# Apply test using the map function
friedman_results <- grouped_df %>%
  mutate(test_result = map(data, run_friedman)) %>%
  unnest(cols = test_result) %>% # this unpacks the test result tibble
  select(-.y., -method) # remove redundant columns

# Filter the significant results
significant_results <- friedman_results %>%
  filter(p < 0.05)


#========================= POST-HOC PAIRWISE TESTING =========================#

# TODO list:
# ============
# - add check for no variance data
# - evaluate effect size


# Wrapper function for Pairwise Wilcox test
run_posthoc <- function(df) {
  pairwise_wilcox_test(df, value ~ quantization, p.adjust.method = "holm")
}

# Guide--Interpreting adjusted P-value column:
# ***	== Very strong evidence of difference
# **  == Strong evidence
# *	  == Moderate evidence
# ns	== Not significant

# TODO: Filter for no variance values
#filtered_grouped_df <- grouped_df %>%


# Version evaluating ALL pairs regardless of Friedman results
posthoc_results <- grouped_df %>%
  mutate(posthoc = map(data, run_posthoc))

# Version with filtering to only evaluate significant results
posthoc_results <- grouped_df %>%
  semi_join(significant_results, by = c("model", "dataset", "metric")) %>%
  mutate(posthoc = map(data, run_posthoc))











#==============================================================================#

# OLD STUFF + FRANCISCO CODE FROM MEETING (NOT USED)

###########################################################################

# Outlines different methods from the PMCMRplus package (page 62):
# https://cran.r-project.org/web/packages/PMCMRplus/PMCMRplus.pdf 

# One of the methods available in the package is Nemenyi's test, 
# but this is based on Tukey's range test: 
# https://real-statistics.com/anova-repeated-measures/friedman-test/friedman-test-post-hoc-analysis/ 
# - which assumes normality?
# https://en.wikipedia.org/wiki/Tukey%27s_range_test#Assumptions

# I have followed this guy's video as a example starting point for what method
# to choose: https://www.youtube.com/watch?v=_gQBiJgvb74 
# This test has a reduced type II error-rate, but maybe we want to prioritize
# minimizing type I errors?

# THIS IS THE WAY (FROM FRANCISCO / MEETING)
temp.df <- data.frame(grouped_df$data[3])
pairwise.wilcox.test(temp.df$value, temp.df$quantization, paired = TRUE, p.adjust.method = "bonf")



#============================ OLD WITH ???TEST ===============================#
run_posthoc <- function(df) {
  # I'm too tired, not sure if this is right...
  frdAllPairsExactTest(
    df$value, 
    df$quantization, 
    df$iteration, 
    p.adjust.method = "bonferroni"
  )# %>%
  #tidy() #TODO: doesn't work - uncomment and reproduce stack trace
}


posthoc_results <- grouped %>%
  # Keep only rows where the model+dataset+metric combination exists in significant results
  semi_join(significant_results, by = c("model", "dataset", "metric")) %>%
  # Apply the post-hoc test to all the data tibbles (quant, iteration, value)
  mutate(posthoc = map(data, run_posthoc)) #%>% # TODO: doesn't work onwards - uncomment, reproduce & fix
  # Unpack similarly to the Friedman
  #unnest(posthoc)
  # TODO: drop redundant cols?


