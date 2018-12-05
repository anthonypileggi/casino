
#' Allow casino to store player profiles in a local file (and)
#' @param file full path to file
#' @export
setup <- function(file = file.path(getwd(), ".casino")) {

  # create file for storing player profiles (if it doesn't exist)
  if (file.exists(file)) {
    message("Found an existing record of players at '", file, "'")
  } else {
    message("No records found.\nStoring player records at '", file, "'")
    saveRDS(NULL, file)
  }

  # set the CASINO_FILE environment variable to this file
  file <- normalizePath(file)
  if (Sys.getenv("CASINO_FILE") != file) {
    message("Updating value for environment variable 'CASINO_FILE'.")
    Sys.setenv(CASINO_FILE = file)
  }

}