clean_insider_data_to_new_folder <- function(
    input_folder = "db/NASDAQ/insider_data/",
    output_folder = "db/NASDAQ/insider_data_clean/"
) {
  if (!dir.exists(output_folder)) {
    dir.create(output_folder, recursive = TRUE)
  }
  
  files <- list.files(input_folder, pattern = "\\.csv$", full.names = TRUE)
  
  for (file in files) {
    df <- readr::read_csv(file, show_col_types = FALSE)
    
    # Remove the "Shares Total" column if it exists
    df_clean <- dplyr::select(df, -dplyr::any_of("Shares Total"))
    
    filename <- basename(file)
    readr::write_csv(df_clean, file.path(output_folder, filename))
  }
  
  message(length(files), " insider files cleaned and saved to ", output_folder)
}
