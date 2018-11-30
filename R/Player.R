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

    # -- list existing player profiles
    players = function() {
      p <- private$load()
      tibble::tibble(
        name = purrr::map_chr(p, "name"),
        amount = purrr::map_chr(p, "amount")
      )
    },

    # -- start playing in the casino
    # TODO: Why can't I update `self` with the `private$recover()` function????
    start = function() {
      private$recover()       # check for existing player history
      #private$update()        # update data in '.casino'
    },

    # -- print player info
    print = function(...) {
      cat("Player: \n")
      cat("  Name: ", self$name, "\n", sep = "")
      cat("  Amount:  ", self$amount, "\n", sep = "")
      cat("  Level:  ", self$level, "\n", sep = "")
      cat("  Played:  ", nrow(self$history), "\n", sep = "")
      invisible(self)
    },

    # -- place a bet
    bet = function(amount) {
      new_money <- self$amount - amount
      if (new_money >= 0) {
        self$amount <- new_money
        message(paste0("You bet ", amount, "; you have ", new_money, " left."))
      } else {
        message(paste0("You cannot bet ", amount, "; you only have ", self$amount, "!"))
      }
      private$update()
    },

    # -- record the outcome of a single game played; update 'amount' in account
    record = function(game, outcome, bet, win, net) {
      new_game <- tibble::tibble(game = game, outcome = outcome, bet = bet, win = win, net = net)
      self$history <- dplyr::bind_rows(self$history, new_game)
      self$amount <- self$amount + win
      private$update()
    },

    # -- player history summary
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

    # load an existing '.casino' file with all player histories
    load = function() {
      switch(file.exists(".casino") + 1, NULL, readRDS(".casino"))
    },

    # load past info for this character
    recover = function() {
      p <- private$load()
      id <- which(purrr::map_chr(p, "name") == self$name)
      if (length(id) == 1) {
        message("Player record found!\n")
        self <- p[[id]]
        self$name <- p[[id]]$name
        # self$amount <- p[[id]]$amount
      }
    },

    # update existing information for current player in '.casino' file
    update = function() {
      p <- private$load()
      if (is.null(p)) {
        p <- list(self)
      } else {
        id <- which(purrr::map_chr(p, "name") == self$name)
        if (length(id) == 1) {
          p[[id]] <- self
        } else if (length(id) == 0) {
          p <- c(p, self)
        } else {
          stop("Something is wrong.... there's > 1 of a name....\n")
        }
      }
      saveRDS(p, ".casino")
    }

  )
)