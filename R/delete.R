
#' Delete all player history and re-lock the casino
#' @export
delete <- function() {
  file <- Sys.getenv("CASINO_FILE")
  if (file.exists(file))
    unlink(file)
  Sys.unsetenv("CASINO_FILE")
}
