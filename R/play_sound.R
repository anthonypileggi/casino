
#' Play a sound (if possible)
#' @param sound character string or number specifying the sound (see \code{\link[beepr]{beep}})
#' @note requires the `beepr` package
play_sound <- function(sound = "fanfare") {
  if ("beepr" %in% utils::installed.packages()[, 1])
    beepr::beep(sound)
}