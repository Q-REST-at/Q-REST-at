# RQ3: The goal is to detect the impact of different 
#.         prompt structures in the model's performance.
# 
# Step 1: 
# Install, load libraries, initialize constants. We create a few functions to
#.  foster reuse and replication of our analysis.
#
# install.packages(tidyverse)
library(tidyverse)  # - tidyverse for data wrangling, and plotting
library(reshape2)   # - reshape2 for creating longer tables easier.
library(rcompanion) # - rcompanion has implementations for the Vargha-Delaney A12 measure.
library(janitor)    # - janitor adds margin columns/rows to tables.


# Load constant values, such as palletes, and labels.
CUSTOM_PALLETE = c("GPT-3.5" = "#4cc9f0", "GPT-4"   = "#219ebc", 
                   "LLAMA"   = "#8ecae6", "MISTRAL" = "#ffb703", 
                   "MIXTRAL" = "#fb8500")

# Define here which measures to analyse. The options are:
#.  Precision, Recall, F1, Accuracy, Balanced_Accuracy, 
#.  TP (True Positives), TN, FP, FN.
ANALYZED_MEASURES = c("Precision", "Recall")
ALPHA = 0.05 # level of significance for statistical tests.

#  The function receives as input two columns in a dataframe containing, 
#.    respectively, the measurements (e.g., Precision values), and the 
#.    corresponding model such as GPT, LLAMA.
#. The function returns a data frame with information from the parwise test,
#.    and effect size (^A12)
get.posthoc.pvalue.df <- function(value.df, factor.df, paired = F, p.adj = 'bonferroni'){
  posthoc.pval <-pairwise.wilcox.test(x = value.df, g = factor.df, 
                                      paired = F, p.adj='bonferroni')$p.value %>% melt() %>% 
    filter(!is.na(value)) %>% 
    select(PromptB = Var1, PromptA = Var2, pvalue=value)
  
  posthoc.vda <- multiVDA(x = value.df, g = factor.df, statistic = "VDA")$pairs %>% 
    select(Comparison, VDA) %>%
    separate(Comparison, into = c("PromptA", "PromptB"), sep = " - ")
  
  posthoc.df <- left_join(posthoc.pval, posthoc.vda, by = c("PromptA", "PromptB"))
  return(posthoc.df)
}

# Vargha, A. and H.D. Delaney. A Critique and Improvement of the CL Common Language Effect Size Statistics of
# McGraw and Wong. 2000. Journal of Educational and Behavioral Statistics 25(2):101–132.
# 
# Of course, these interpretations have no universal authority. They are just guidelines based on the judgement of 
# the authors, and are probably specific to field of study and specifics of the situation under study.
# 
# You might see the original paper for their discussion on the derivation of these guidelines.
# 
# Small : 0.56  – < 0.64 or > 0.34 – 0.44
# Medium: 0.64  – < 0.71 or > 0.29 – 0.34
# Large : ≥ 0.71 or ≤ 0.29

map.vda.effect <- function(vda.value) {
  effect <- ""
  if((0.56 <= vda.value & vda.value < 0.64) | (0.34 < vda.value & vda.value <= 0.44)) {
    effect <- "Small"
  } else if((0.64 <= vda.value & vda.value < 0.71) | (0.29 < vda.value & vda.value <= 0.34)) {
    effect <- "Medium"
  } else if(vda.value >= 0.71 | vda.value <= 0.29) {
    effect <- "Large"
  } else {
    effect <- "Negligible"
  }
  return(factor(effect, levels = c("Negligible", "Small", "Medium", "Large")))
}

# Step 2:
# Loads the dataset into a data frame, and creates a long table 
#.  with observations per measure. For RQ3, we focus on the 
#.  the eight prompt structures per model. The long table is then
#.  summarised into descriptive statistics: mean, median and standard deviation (SD).

raw.df <- read.csv("data/all_results.csv")

# Step 3:
#   Create two figures showing (i) the precision and recall of each prompt PER MODEL.

chosen.datasets <- unique(raw.df$Dataset)

rq3.complete.df <- tibble()

for(current.dataset in chosen.datasets) {
  
  rq3.long.df <- raw.df %>% 
    filter(Dataset == current.dataset) %>% 
    select(Model, Prompt, Precision, Recall) %>%
    gather(key = "Measure", value = "Value", -c("Model", "Prompt"))
  
  rq3.summary.df <- rq3.long.df %>%
    group_by(Model, Prompt, Measure) %>% 
    summarise(Mean = mean(Value), Median = median(Value), SD = sd(Value), 
              YMin = Mean - SD, YMax = Mean + SD) %>% 
    group_by(Model, Measure) %>%
    mutate(MedianDiff = Median - Median[Prompt == "BASE"], 
           Improvement = MedianDiff > 0.0, Hline= Median[Prompt == "BASE"])
  
  rq3.complete.df <- bind_rows(rq3.complete.df, rq3.summary.df) #Save current table in an archive.
  
  write.csv(rq3.summary.df, file = paste0("output/RQ3 Summary Table ", current.dataset,".csv"))
  
  rq3.plot <- ggplot(rq3.summary.df, aes(x = Prompt, y = Median, fill = Model)) +
    geom_col(width = 0.8) + 
    geom_hline(aes(yintercept = Hline), linetype = "dashed") +
    geom_errorbar(aes(ymin = YMin, ymax = YMax), alpha = 0.7, width = 0.5) +
    scale_y_continuous(limits = c(0,1), breaks = seq(0,1,by=0.2)) +
    facet_grid(vars(Measure), vars(Model), scales = "free") +
    scale_fill_manual(values = CUSTOM_PALLETE) +
    theme_bw() + theme(legend.position = "bottom", axis.text.x = element_text(angle = 90))
  
  ggsave(rq3.plot, filename = paste0("output/RQ3 Prompt Results ", current.dataset,".pdf"), width = 22, height = 15, units = "cm", device = cairo_pdf())
  dev.off()
  
}

## Step 4.1:
#.   Since there were many comparisons, and some of the visual differences 
#.   between some prompts were inconclusive. Therefore, we perform statistical
#.   analysis of the data. We begin with a Kruskal-Wallis test, followed by 
#.   pairwise posthoc analysis using Mann-Whitney, alpha = 0.05, and Bonferroni correction,

# reshape the dataframe to be in the long form 
kw.prompt.df <- raw.df %>% 
  mutate(Treatment = paste(Dataset,Model,Prompt,sep = "-")) %>% 
  select(Dataset, Model, Prompt, Precision, Recall)

kw.table <- tibble()
for(dataset in unique(kw.prompt.df$Dataset)) {
  for(current.model in unique(kw.prompt.df$Model)) {
    print(paste(dataset,": Calculating KruskalWallis Test for ",current.model, "..."))
    temp.df <- kw.prompt.df %>% filter(Model == current.model & Dataset == dataset)
    
    kw.results.precision <- kruskal.test(Precision ~ Prompt, data = temp.df)
    kw.results.recall    <- kruskal.test(Recall ~ Prompt   , data = temp.df)
    
    kw.temp.df <- data.frame(Model  = current.model, Precision = kw.results.precision$p.value, 
                             Recall = kw.results.recall$p.value) %>% 
      mutate(Dataset = dataset)
    
    kw.table <- bind_rows(kw.table, kw.temp.df)
  }
}

write.csv(kw.table, file = paste0("output/RQ3 Kruskal-Wallis ", current.dataset,".csv"))

## Step 4.2:
#  Posthoc Analysis with the subset of dataset, models and prompts that meet 
#.   the threshold: Precision >= 0.75 and Recall >= 0.8.
#.   In this analysis, there was only one pair for BTHS, so we proceed with ENCO.

#. We mitigate the number of required comparisons by performing the statistical
#.   only on those subsets of models and prompts that meet a minimal precision
#.   and requirement threshold…
accepted.df <- raw.df %>% 
  select(Dataset, Model, Prompt, all_of(ANALYZED_MEASURES)) %>%
  group_by(Dataset, Model, Prompt) %>% 
  summarise(Mean.Prec = mean(Precision), SD.Prec = sd(Precision),
            Mean.Rec = mean(Recall), SD.Rec = sd(Recall)) %>% 
  filter(Mean.Prec >= 0.75 & Mean.Rec >= 0.8) %>% 
  mutate(Treatment = paste(Dataset,Model,Prompt,sep = "-"))

prompts.df <- raw.df %>% 
  mutate(Treatment = paste(Dataset,Model,Prompt,sep = "-")) %>% 
  filter((Treatment %in% accepted.df$Treatment) & Dataset == "ENCO") %>% 
  select(Model, Prompt, Precision, Recall)

prompt.precis.df <- tibble()
prompt.recall.df <- tibble()

for(current.model in unique(prompts.df$Model)) {
  print(paste("Calculating Pairwise Mann-Whitney Test for ",current.model, "..."))
  
  temp.df <- prompts.df %>% filter(Model == current.model)
  
  posthoc.precision.df <- get.posthoc.pvalue.df(temp.df$Precision, temp.df$Prompt) %>% 
    mutate(Model = current.model) %>% 
    select(Model, PromptA, PromptB, pvalue, VDA)
  
  posthoc.recall.df <- get.posthoc.pvalue.df(temp.df$Recall, temp.df$Prompt) %>% 
    mutate(Model = current.model) %>% 
    select(Model, PromptA, PromptB, pvalue, VDA)
  
  prompt.precis.df <- bind_rows(prompt.precis.df, posthoc.precision.df)
  prompt.recall.df <- bind_rows(prompt.recall.df, posthoc.recall.df)
}

# Add columns to the pairwise tests to indicate SSD and the Effect Size.
rq3.pair.prec.df <- prompt.precis.df %>% 
  rowwise() %>% 
  mutate(SSD = ifelse(pvalue < ALPHA, "Yes", "No"), 
         Eff.Size = map.vda.effect(VDA), VDA = round(VDA, 2), pvalue = round(pvalue, 3),
         Best = ifelse(VDA >= 0.56, PromptA, ifelse(VDA <= 0.44, PromptB, "---")))

rq3.pair.recall.df <- prompt.recall.df %>% 
  rowwise() %>% 
  mutate(SSD = ifelse(pvalue < ALPHA, "Yes", "No"), 
         Eff.Size = map.vda.effect(VDA), VDA = round(VDA, 2), pvalue = round(pvalue, 3),
         Best = ifelse(VDA >= 0.56, PromptA, ifelse(VDA <= 0.44, PromptB, "---")))

write.csv(rq3.pair.prec.df  , file = paste0("output/RQ3 Pairwise Precision ", current.dataset,".csv"))
write.csv(rq3.pair.recall.df, file = paste0("output/RQ3 Pairwise Recall ", current.dataset,".csv"))

# Summarises all pairwise comparisons to show how often each prompt has shown
#.  improved precision and recall for each model. This is Table 5 in the paper.
rq3.summ.precision <- rq3.pair.prec.df %>% 
  filter(SSD == "Yes") %>% 
  group_by(Model, Best) %>% 
  tally(name = "Total.Wins") %>% 
  spread(key = Model, value = Total.Wins) %>% 
  adorn_totals(c("row", "col"))

rq3.summ.recall <- rq3.pair.recall.df %>% 
  filter(SSD == "Yes" & Eff.Size == "Large") %>% 
  group_by(Model, Best) %>% 
  tally(name = "Total.Wins") %>% 
  spread(key = Model, value = Total.Wins) %>% 
  adorn_totals(c("row", "col"))

write.csv(rq3.summ.recall   , file = "output/RQ3 Summary Recall.csv"   )
write.csv(rq3.summ.precision, file = "output/RQ3 Summary Precision.csv")