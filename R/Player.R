#' Player R6 Class
#' @importFrom magrittr "%>%"
#' @export
Player <- R6::R6Class("Player",
  public = list(
    name = NULL,
    amount = NULL,
    level = 1,
    history = NULL,
    initialize = function(name = "Joe Player", amount = 100) {
      self$name <- name
      self$amount <- amount
    },
    print = function(...) {
      cat("Player: \n")
      cat("  Name: ", self$name, "\n", sep = "")
      cat("  Amount:  ", self$amount, "\n", sep = "")
      cat("  Level:  ", self$level, "\n", sep = "")
      cat("  Played:  ", nrow(self$history), "\n", sep = "")
      invisible(self)
    },
    bet = function(amount) {
      new_money <- self$amount - amount
      if (new_money >= 0) {
        self$amount <- new_money
        message(paste0("You bet ", amount, "; you have ", new_money, " left."))
      } else {
        message(paste0("You cannot bet ", amount, "; you only have ", self$amount, "!"))
      }
    },
    # -- record the outcome of a single game played; update 'amount' in account
    record = function(game, outcome, bet, win, net) {
      new_game <- tibble::tibble(game = game, outcome = outcome, bet = bet, win = win, net = net)
      self$history <- dplyr::bind_rows(self$history, new_game)
      self$amount <- self$amount + win
    },
    summarize_history = function(...) {
      groups <- rlang::quos(...)
      self$history %>%
        dplyr::group_by(!!!groups) %>%
        dplyr::summarize(
          games = dplyr::n(),
          bet = sum(bet),
          win = sum(win),
          net = sum(net)
        )
    }
  ),
  private = list(

  )
)