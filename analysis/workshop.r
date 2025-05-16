#################################################
# WORKSHOP CODE
#################################################

#install.packages("tidyverse")
library(tidyverse)

raw_df <- read.csv("./workshop_data.csv")

do_stuff <- function(thing) {
  if (thing < 0.5) {
    TRUE
  } else {
    FALSE
  }
  # implicit return version (simple one-liner):
  #thing < 0.5
}

# Vectorise makes the function apply to a vector of values (i.e. column)
do_stuff_v <- Vectorize(do_stuff)

#Paste(Column_name, " --> ", Other_column_name) #concatenation

accuracy_df <- raw_df %>% # piping to commands below
  select(model, quantization, dataset, iteration, accuracy) %>%
  filter(model == "MIS" & quantization == "AWQ") %>%
  mutate(new_value = do_stuff_v(accuracy)) # add another column


summ_accuracy_df <- accuracy_df %>%
  group_by() %>% #idk the logic to group by treatment
  tally(iteration = "Observations") %>% # Could also do the count by summarise and n() (unsure of exact syntax)
  #ungroup() # if at any point you want to ungroup
  mutate(Percent = round(100 * Observations / sum(Observations), 1)) %>%
  summarise(mean(accuracy), median(accuracy), sd(accuracy))

# How to melt (using Francisco's sample data -> student ID column + multiple question cols with score values
# e.g. (Q1.2, Q.2))
long_question_df <- raw_df %>%
  select(ID, starts_with("Q")) %>%
  filter(!is.na(Points)) %>%
  gather(key == "Question", value = "Points", -ID) %>% # the last "minus" excludes columns from the melt
  group_by(Question) %>% # this is the melt
  summarise(Mean = mean(Points))

# Notes: NHST analysis input parameters
# "This thing" ~ (with respect to) ["these", "things"]
# Points ~ (Questions + Grade) # multi-factorial analysis?
# Accuracy ~ (Model + Quant) # with our stuffs

palette("#345876", "#487747")
# Plotting example
# Useful to have wide tables for this
ggplot(long_question_df, aes(x = Question, y = Points, fill = Question)) +  # ggplot pipes using "+"
  geom_boxplot() +
  geom_hline(yintercept = 20, linetype = "dashed") + # adds horizontal line to plot at y-value
  scale_y_continuous(limits = c(0, 20), breaks = seq(0, 50, by = 5)) +
  scale_fill_manual() + # create own colour palette
  #scale_fill_brewer(palette = "Dark2") + # https://r-graph-gallery.com/38-rcolorbrewers-palettes.html
  theme_bw() + # minimalist theme
  theme(legend.position = "bottom") # legend on bottom instead of right side
