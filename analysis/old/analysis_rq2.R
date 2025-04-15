# RQ2: The goal is to compare whether there is a model that is better at
#.         detecting trace links between requirements and test.
#
# Step 1: 
# Install, load libraries, initialise constants.
#
# install.packages(tidyverse)
library(tidyverse)  # - tidyverse for data wrangling, and plotting

# Load constant values, such as palletes, and labels.
CUSTOM_PALLETE = c("GPT-3.5" = "#4cc9f0", "GPT-4"   = "#219ebc", 
                    "LLAMA"   = "#8ecae6", "MISTRAL" = "#ffb703", 
                    "MIXTRAL" = "#fb8500")

# Define here which measures to analyse. The options are:
#.  Precision, Recall, F1, Accuracy, Balanced_Accuracy, 
#.  TP (True Positives), TN, FP, FN.
ANALYZED_MEASURES = c("Precision", "Recall")

# Step 2:
# Loads the dataset into a data frame, and creates a long table 
#.  with observations per measure. For RQ2, we focus on the 
#.  BASE prompt. The long table is then summarised into descriptive
#.  statistics: mean, median and standard deviation (SD).

raw.df <- read.csv("data/all_results.csv")

rq2.summary.df <- raw.df %>% 
  filter(Prompt == "BASE") %>% 
  select(Model, Dataset, all_of(ANALYZED_MEASURES)) %>%
  gather(key = "Measure", value = "Value", -c("Model", "Dataset")) %>%
  group_by(Dataset, Model, Measure) %>% 
  summarise(Mean = mean(Value), Median = median(Value), SD = sd(Value),
            YMin = Mean - SD, YMax = Mean + SD)

# Step 3:
# Export a table with the summary information for the models with 
#.  the BASE prompt. We focus on Precision and Recall, but more Measures can be For RQ2, we focus on the 
#.  BASE prompt. The long table is then summarised into descriptive
#.  statistics: mean, median and standard deviation (SD).
#.  
#.  This exports Table 4 in the paper.

write.csv(rq2.summary.df, file = "output/RQ2 Summary Table.csv")

# Step 4:
# Create and export a bar plot with error bars to show variance for each model.

rq2.plot <- ggplot(rq2.summary.df, aes(x = Model, y = Median, fill = Model, group = Measure)) +
  geom_col(width = 0.8) + 
  geom_errorbar(aes(ymin = YMin, ymax = YMax), alpha = 0.8, width = 0.5) +
  scale_y_continuous(limits = c(0,1), breaks = seq(0,1,by=0.1)) +
  facet_grid(vars(Measure), vars(Dataset), scales = "free") +
  scale_fill_manual(values = CUSTOM_PALLETE) +
  theme_bw() + theme(legend.position = "bottom", axis.text.x = element_text(angle = 90))

ggsave(rq2.plot, filename = "output/RQ2 LLM Comparison.pdf", width = 22, height = 15, units = "cm", device = cairo_pdf())
dev.off()