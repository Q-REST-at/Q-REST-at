#install.packages("tidyverse")
#install.packages("rstatix")
library(tidyverse)
library(rstatix)

raw_df <- read.csv("./workshop_data.csv") # has added "made up" GPTQ data
head(raw_df)


# create df containing data for BTHS
# TODO: there needs to be some better logic for this than doing it manually
accuracy_df <- raw_df %>%
  select(model, quantization, dataset, iteration, accuracy) %>%
  filter(dataset == "BTHS")


result <- friedman_test(accuracy_df, accuracy ~ quantization | iteration)

if (result$p < 0.05) { # $p accesses the p-value since the column has only 1 row
  print("Reject null hypothesis")
} else {
  print("Fail to reject null hypothesis")
}

