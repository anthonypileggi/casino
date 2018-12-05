
#' List all player profiles
#' @export
players <- function(file = ".casino") {
  p <-  switch(file.exists(file) + 1, NULL, readRDS(file))
  tibble::tibble(
    name = purrr::map_chr(p, "name"),
    balance = purrr::map_chr(p, "balance")
  )
}