# Description

This is the data package for the analysis of a paper that compares the performance of different LLMs and prompt structures in identifying trace links between tests and requirements.

### The data includes:

-   ```data/:``` The folder with the CSV file with the measures (e.g., precision and recall) of running the models 30 times each for each of the eight prompt structures chosen.
-   ```analysis_rq2.R```. The R script used to create figures and tables in the paper for RQ2 which compares the five LLMs.
-   ```analysis_rq3.R```. The R script used to create figures, tables and statistical tests for RQ3 which compares the effect of eight prompt templates for five different LLMs.

### How use this package

We recommend opening the folder as a project in RStudio. Begin by reading the scripts `analyse_rq2.R` followed by `analyse_rq3.R`. Moreover, browse through the CSV files.
