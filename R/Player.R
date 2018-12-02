#' Player R6 Class
#' @importFrom magrittr "%>%"
#' @export
Player <- R6::R6Class("Player",

  public = list(

    # player name
    name = NULL,

    initialize = function(name = "Joe Player") {
      self$name <- name
      private$recover()                # check for (and load) existing player history
      if (private$.balance == 0) {     # if player has 0 balance
        message()
        self$reset()
      }

      private$update()                 # add/update data in '.casino'
    },

    # -- list existing player profiles
    players = function() {
      p <- private$load()
      tibble::tibble(
        name = purrr::map_chr(p, "name"),
        balance = purrr::map_chr(p, "balance")
      )
    },

    # -- reset player profile
    reset = function() {
      message("Reseting profile for ", self$name, "...\n", sep = "")
      private$.balance <- 100
      private$.level <- 1
      private$.history <- NULL
      private$update()
      invisible(self)
    },

    # -- print player info
    print = function(...) {
      cat("Player: \n")
      cat("  Name: ", self$name, "\n", sep = "")
      cat("  Balance:  ", private$.balance, "\n", sep = "")
      cat("  Level:  ", private$.level, "\n", sep = "")
      cat("  Played:  ", nrow(private$.history), "\n", sep = "")
      invisible(self)
    },

    # -- place a bet
    bet = function(amount) {
      new_money <- private$.balance - amount
      if (new_money >= 0) {
        private$.balance <- new_money
        message(paste0("You bet ", amount, "; you have ", new_money, " left."))
      } else {
        stop(paste0("You cannot bet ", amount, "; you only have ", private$.balance, "!"), call. = FALSE)
      }
      private$update()
    },

    # -- record the outcome of a single game played; update 'amount' in account
    record = function(game, outcome, bet, win, net) {
      new_game <- tibble::tibble(game = game, outcome = outcome, bet = bet, win = win, net = net)
      private$.history <- dplyr::bind_rows(private$.history, new_game)
      private$.balance <- private$.balance + win
      private$set_level()
      private$update()
    },

    # -- player history summary
    summarize_history = function(...) {
      groups <- rlang::quos(...)
      private$.history %>%
        dplyr::group_by(!!!groups) %>%
        dplyr::summarize(
          games = dplyr::n(),
          bet = sum(bet),
          win = sum(win),
          net = sum(net)
        )
    }
  ),

  active = list(
    balance = function(value) {
      if (missing(value)) {
        private$.balance
      } else {
        stop("Oh, you want more money? LOL Nice try! :-)", call. = FALSE)
      }
    },
    level = function(value) {
      if (missing(value)) {
        private$.level
      } else {
        stop("Oh, you want more skills? LOL Nice try! :-)", call. = FALSE)
      }
    },
    history = function(value) {
      if (missing(value)) {
        private$.history
      } else {
        stop("Are you Marty McFly?!  You cannot change the past.", call. = FALSE)
      }
    }
  ),

  private = list(

    # everyone starts with a Level 1 w/ a balance of 100
    .balance = 100,
    .level = 1,
    .history = NULL,

    # level progression
    levels = tibble::tibble(level = 1:99, threshold = 2 ^ level),
    set_level = function() {
      gains <- sum(private$.history$win, na.rm = TRUE)
      private$.level <- tail(filter(private$levels, threshold <= gains)$level, 1)
    },

    # check balance
    check_balance = function() {
      if (private$.balance == 0) {     # if player has 0 balance
        message("You have no money!")
        self$reset()
      }
    },

    # load an existing '.casino' file with all player histories
    load = function() {
      switch(file.exists(".casino") + 1, NULL, readRDS(".casino"))
    },

    # save a list of players in '.casino'
    save = function(players) {
      saveRDS(players, ".casino")
    },

    # load past info for the player
    recover = function() {
      p <- private$load()
      if (!is.null(p)) {
        id <- which(purrr::map_chr(p, "name") == self$name)
        if (length(id) == 1) {
          message("Loading player profile...\n")
          private$.balance <- p[[id]]$balance
          private$.level <- p[[id]]$level
          private$.history <- p[[id]]$history
        }
      }
      private$check_balance()
    },

    # delete a player profile
    delete = function() {
      p <- private$load()
      if (!is.null(p)) {
        id <- which(purrr::map_chr(p, "name") == self$name)
        if (length(id) == 1)
          private$save(p[-id])
      }
    },

    # add a player profile
    add = function() {
      p <- private$load()
      p <- c(p, self)
      private$save(p)
    },

    # update existing information for current player in '.casino' file
    update = function() {
      private$delete()
      private$add()
    }

  )
)