# Process entries for evaluation, where multiple evaluation pdfs are created
# Jeff Oliver
# jcoliver@arizona.edu
# 2021-04-07
# Update 2026-03-19

library(tidyverse)
library(rmarkdown)

eval_year <- "2026"
# Minimum number of evaluations for each entry. Will be used with the number of 
# entries (i.e. number of rows in data/YYYY/responses.csv) and the number of 
# judges (i.e. number of rows in data/YYYY/judges.csv) to determine 
# assignments. About 95% confident the math works.
min_evals <- 3

# This will create
# 1. Sheet for scoring entries, (or part of it) with FiLa as column heading, 
#    where FiLa is the first two initials of First and Last names, respectively
# 2. Single PDF with one entry per page
#    For this to work, a couple of notes:
#    a. Had to use the xelatex engine (instead of pdflatex?) to get some 
#       symbols in abstracts to display 
#    b. To insert images into the pdf, I downloaded all the images, stuck them
#       in data/images, and renamed those that could be inserted. That is, any 
#       files that were single, static images of acceptable format were renamed 
#       to FiLa.* (acceptable values of *: png, jpg, pdf).

responses <- readr::read_csv(file = paste0("data/", eval_year, "/responses.csv"))

# Timestamp needs to be converted from character
responses$Timestamp <- lubridate::as_datetime(x = responses$Timestamp,
                                              format = "%m/%d/%Y %H:%M:%S",
                                              tz = "MST")

# Drop duplicate entries, retaining most recent entry only
# responses <- responses
uniq_responses <- responses %>%
  arrange(desc(Timestamp)) %>%
  distinct(`First Name`, `Last Name`, .keep_all = TRUE) %>%
  arrange(`First Name`)

# # We only want judges to evaluate 12-15 entries. If there are more than that, 
# # we will go ahead and divvy them up.
# num_entries <- 32
# num_judges <- 6 # Assumes JCO as sixth judge
# num_eval <- 16
# assignments <- matrix(data = 1:num_entries, 
#                       nrow = num_judges, 
#                       ncol = num_eval, 
#                       byrow = TRUE)
# 
# assignments
# # Now, we want to randomize within a column. The below really only works for 
# # specific number of judges (6), evaluations per judge (16), and number of 
# # entries (32).
# # Each column index takes only two values: i and i + 16
# rand_assign <- matrix(data = NA, nrow = num_judges, ncol = num_eval)
# # Brute force
# for (i in 1:ncol(rand_assign)) {
#   rand_assign[, i] <- sample(x = c(rep(i, times = 3), rep(i + 16, times = 3)),
#                              size = 6)
# }
# table(rand_assign)

# 1. Sheet for overall evaluations; includes all FiLa combinations
initials <- paste0(substr(x = uniq_responses$`First Name`, start = 1, stop = 2),
                   substr(x = uniq_responses$`Last Name`, start = 1, stop = 2))
eval_sheet <- data.frame(matrix(nrow = 1, ncol = length(initials)))
names(eval_sheet) <- initials
if(!dir.exists("output")) {
  dir.create("output")
}
if(!dir.exists(paste0("output/", eval_year))) {
  dir.create(paste0("output/", eval_year))
}
readr::write_csv(x = eval_sheet, file = paste0("output/", eval_year, "/evaluations.csv"))

# 2. PDF with one entry per page
# Iterate over all judges, pulling out only "responses" (i.e. entries) that are 
# assigned to that judge
judges <- read.csv(file = paste0("data/", eval_year, "/judges.csv"))

# Number of evaluations for each judge to perform
num_evals <- ceiling(min_evals * nrow(uniq_responses) / nrow(judges))

# Matrix of evaluation assignments
eval_assignments <- matrix(data = 1:nrow(uniq_responses), 
                           nrow = nrow(judges), 
                           ncol = num_evals, 
                           byrow = TRUE)
rownames(eval_assignments) <- judges$name
# This is fine, but *rows* are not unique (that is, three judges evaluate the 
# same 16 entries). Add validator and iterate shuffling until each row is 
# unique
valid <- FALSE
num_attempts <- 0
set.seed(20260325)
while (!valid & num_attempts < 100) {
  eval_assignments <- apply(X = eval_assignments,
                            MARGIN = 2,
                            FUN = function(x) {
                              return(sample(x))
                            })
  # Kudos to Claude for this validation code
  valid <- all(apply(X = eval_assignments, 
                     MARGIN = 1, 
                     FUN = function(row) {
                       return(length(row) == length(unique(row)))
                     }))
  num_attempts <- num_attempts + 1
}
if (valid) {
  message("Assignments complete after ", num_attempts, " attempts.")
} else {
  warning("Could not assign evaluations after ", num_attempts, " attempts.")
}
# Ideally things worked, and we can sort each row for easier viewing
# I don't love that I have to transpose the apply output :(
eval_assignments <- t(apply(X = eval_assignments,
                          MARGIN = 1,
                          FUN = function(i) {
                            return(sort(i))
                          }))

# TODO: Create evaluations CSV for each judge

for (j in 1:nrow(judges)) {
  judge_name <- judges$name[j]
  # Pull out the rows corresponding to entries assigned to this judge
  responses_for_judge <- uniq_responses[sort(eval_assignments[j, ]), ]
  # Make the pdf the judge will use for evaluations
  message("Rendering Entries PDF for ", judge_name)
  rmarkdown::render(input = "Entries-mult.Rmd", 
                    # output_format = "pdf_document",
                    output_file = paste0("output/", eval_year, "/Entries-", judge_name),
                    params = list(responses = responses_for_judge,
                                  eval_year = eval_year,
                                  judge_name = judge_name))
}
