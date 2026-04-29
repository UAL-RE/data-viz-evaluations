# Prepare result notification letters (in Word Doc format)
# Jeff Oliver
# jcoliver@arizona.edu
# 2026-04-29

# library(quarto)

eval_year <- 2026

# Read in result information
results <- read.csv(file = "data/2026/evaluations/results.csv")

# Make sure destination for results exists
if (!dir.exists(paste0("output/", eval_year))) {
  dir.create(paste0("output/", eval_year))
}
if (!dir.exists(paste0("output/", eval_year, "/result_letters"))) {
  dir.create(paste0("output/", eval_year, "/result_letters"))
}

# Create entry ID (FiLa) (we use this for file naming)
results$entry <- paste0(substr(x = results$first, start = 1, stop = 2),
                        substr(x = results$last, start = 1, stop = 2))

# Iterate over entries, creating one Word doc for each
for (e_i in 1:nrow(results)) {
  output_file <- paste0("output/", eval_year, 
                        "/result_letters/Notification - ", entry)
  if (results$result[e_i] == 0) {
    # Losing entries have result of 0, prepare with appropriate template
    
  } else {
    # Winning entries have result of 1, 2, 3 (4 could be honorable mention, 
    # but this functionality doesn't exist yet)
    quarto::quarto_render(input = "Result-win-template.qmd",
                          output_file = output_file,
                          execute_params = list(email = results$email[e_i],
                                                  first_name = results$first[e_i],
                                                  place = results$result[e_i],
                                                  category = results$category[e_i]))
  }
}