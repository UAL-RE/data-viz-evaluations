# Consensing evaluations from reviewers
# Jeff Oliver
# jcoliver@arizona.edu
# 2026-04-17

library(dplyr)
library(tidyr)

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

# Read in files, transpose scores, then join into single dataframe
evaluation_files <- list.files(path = "data/2026/evaluations",
                               pattern = "*.csv$",
                               full.names = TRUE)
evaluation_list <- lapply(X = evaluation_files,
                          FUN = read.csv,
                          skip = 1,
                          nrows = 16)
names(evaluation_list) <- gsub(pattern = ".csv",
                               replacement = "",
                               x = gsub(pattern = paste0("data/", eval_year, "/evaluations/Evaluations - "),
                                        replacement = "",
                                        x = evaluation_files),
                               fixed = TRUE)
evaluation_scores <- lapply(X = evaluation_list,
                            FUN = function(x) {
                              # We have a data frame coming in; just pull out 
                              # mean scores
                              scores <- x[x$Criterion == "Mean", 2:17]
                              scores_long <- data.frame(Entry = colnames(scores),
                                                        Score = as.numeric(t(scores)))
                              rownames(scores_long) <- NULL
                              # Shouldn't have to do this, but here we are...
                              colnames(scores_long)[2] <- "Score"
                              
                              # Same as above with rank
                              ranks <- x[x$Criterion == "Rank", 2:17]
                              ranks_long <- data.frame(Entry = colnames(ranks),
                                                       Rank = as.numeric(t(ranks)))
                              rownames(ranks_long) <- NULL
                              colnames(ranks_long)[2] <- "Rank"
                              
                              # Stick 'em together
                              scores_long <- scores_long %>%
                                left_join(ranks_long,
                                          by = "Entry")
                              return(scores_long)
                            }
                            )
all_scores <- evaluation_scores %>%
  bind_rows(.id = "Judge")

# Next couple of lines are ugly
summary_scores <- all_scores %>%
  group_by(Entry) %>%
  summarize(mean_score = round(mean(Score), digits = 3),
            mean_rank = round(mean(Rank), digits = 3)) %>%
  ungroup()

summary_mat <- matrix(data = c(summary_scores$mean_score,
                               summary_scores$mean_rank),
                      nrow = 2,
                      byrow = TRUE)
summary_wide <- as.data.frame(summary_mat, row.names = c("score", "rank"))
colnames(summary_wide) <- summary_scores$Entry 

if(any(summary_wide[1, ] > 5)) {
  warning("Check scores - value above maximum (5) detected")
} else {
  message("Passed score check (no values above maximum)")
  write.csv(x = summary_wide,
            file = "output/2026/consensus.csv",
            row.names = TRUE)
}
