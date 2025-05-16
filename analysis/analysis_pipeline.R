#install.packages("tidyverse")
#install.packages("rstatix")
#install.packages("PMCMRplus")
library(tidyverse)
library(rstatix)
library(PMCMRplus)

# Load data
raw_df <- read.csv("./workshop_data.csv") # has added "made up" GPTQ data
head(raw_df)

# Metrics to test
metrics <- c("balanced_accuracy", "recall", "precision", "f1")

# Expand the metrics columns to "true" long format
long_df <- raw_df %>%
  select(model, quantization, dataset, iteration, all_of(metrics)) %>%
  pivot_longer(cols = all_of(metrics), names_to = "metric", values_to = "value")

# Group by: model, dataset, metric
grouped <- long_df %>%
  group_by(model, dataset, metric) %>%
  nest() # puts the actual data inside a tibble for each row (group)

# Wrapper function for Friedman test
# This lets us apply the function on the nested data
run_friedman <- function(df) {
  # TODO: the variable assignment might even be redundant
  result <- friedman_test(df, value ~ quantization | iteration)
}

# Apply test using the map function
friedman_results <- grouped %>%
  mutate(test_result = map(data, run_friedman)) %>%
  unnest(cols = test_result) %>% # this unpacks the test result tibble
  select(-.y., -method) # remove redundant columns

# Filter the significant results
significant_results <- friedman_results %>%
  filter(p < 0.05)


######################## POST-HOC PAIRWISE TESTING ######################## 

# WIP !!!
# We get some result but it isn't as tidy as we would want it.

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

run_posthoc <- function(df) {
  # I'm too tired, not sure if this is right...
  frdAllPairsExactTest(
    df$value, 
    df$quantization, 
    df$iteration, 
    p.adjust.method = "bonferroni"
  )# %>%
  #tidy() #TODO: doesn't work
}


posthoc_results <- grouped %>%
  # Keep only rows where the model+dataset+metric combination exists in significant results
  semi_join(significant_results, by = c("model", "dataset", "metric")) %>%
  # Apply the post-hoc test to all the data tibbles (quant, iteration, value)
  mutate(posthoc = map(data, run_posthoc)) #%>% # TODO: doesn't work onwards
  # Unpack similarly to the Friedman
  #unnest(posthoc)
  # TODO: drop redundant cols?


