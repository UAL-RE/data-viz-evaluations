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

# Create a CSV with FiLa for each judge for eaiser pasting into Google Sheet
indexes <- paste0(substr(x = uniq_responses$`First Name`, start = 1, stop = 2),
                  substr(x = uniq_responses$`Last Name`, start = 1, stop = 2))

eval_indexes <- matrix(data = indexes[eval_assignments],
                       nrow = nrow(eval_assignments),
                       byrow = FALSE)
rownames(eval_indexes) <- judges$name
write.csv(x = eval_indexes, 
          file = paste0("output/", eval_year, "/assignments.csv"))

for (j in 1:nrow(judges)) {
  judge_name <- judges$name[j]
  # Pull out the rows corresponding to entries assigned to this judge
  responses_for_judge <- uniq_responses[eval_assignments[j, ], ]
  # Make the pdf the judge will use for evaluations
  message("Rendering Entries PDF for ", judge_name)
  rmarkdown::render(input = "Entries-mult.Rmd", 
                    # output_format = "pdf_document",
                    output_file = paste0("output/", eval_year, "/Entries-", judge_name),
                    params = list(responses = responses_for_judge,
                                  eval_year = eval_year,
                                  judge_name = judge_name))
}

# Finally, we want a single PDF with all entries
message("Rendering PDF of all entries")
rmarkdown::render(input = "Entries.Rmd",
                  output_file = paste0("output/", eval_year, "/All-Entries"),
                  params = list(responses = uniq_responses, 
                                eval_year = eval_year))
