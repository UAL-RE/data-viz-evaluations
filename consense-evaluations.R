# Consensing evaluations from reviewers
# Jeff Oliver
# jcoliver@arizona.edu
# 2026-04-17

library(dplyr)

eval_year <- "2026"

# Creating consensus evaluation for final rankings of entries. There will be 
# three things:
# 1. A mean score for each of the criteria for each entry (averaging across 
#    judges)
# 2. A mean of total mean scores (averaging across judges)
# 3. A mean rank (averaging across judges)

# Data coming in have
# + Entry name in row 2
# + Criteria scores in rows 3-9
# + Score in row 15 (mean of 6-7 criteria)
# + Rank in row 17

# Read in files
evaluation_files <- list.files(path = "data/2026/evaluations",
                               pattern = "*.csv$",
                               full.names = TRUE)
