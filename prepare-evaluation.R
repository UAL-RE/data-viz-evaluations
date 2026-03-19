# Process entries for evaluation
# Jeff Oliver
# jcoliver@arizona.edu
# 2021-04-07
# Update 2026-03-19

library(tidyverse)
library(rmarkdown)

eval_year <- "2026"

if (!dir.exists("output")) {
  dir.create("output")
}
if (!dir.exists(paste0("output/", eval_year))) {
  dir.create(paste0("output/", eval_year))
}

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
#       to FiLa.* (acceptable values of *: png, jpg). PDF and gif files were 
#       *not* renamed, prompting a message that they should be viewed online.

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


# 1. Sheet for evaluations
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
rmarkdown::render(input = "Entries.Rmd", 
                  # output_format = "pdf_document",
                  output_file = paste0("output/", eval_year, "/Entries"),
                  params = list(responses = uniq_responses,
                                eval_year = eval_year))
