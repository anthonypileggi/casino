
#' List all player profiles
#' @param file full path to file containing player profiles
#' @export
players <- function(file = Sys.getenv("CASINO_FILE")) {
  p <-  switch(file.exists(file) + 1, NULL, readRDS(file))
  tibble::tibble(
    name = purrr::map_chr(p, "name"),
    balance = purrr::map_chr(p, "balance")
  )
}