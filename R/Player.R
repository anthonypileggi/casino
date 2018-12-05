#' Player R6 Class
#' @importFrom magrittr "%>%"
#' @import ggplot2
#' @export
Player <- R6::R6Class("Player",

  public = list(

    # -- player name
    name = NULL,

    # -- create/load player profile (via local '.casino' file)
    initialize = function(name = NA) {
      if (is.na(name))
        stop("You must choose a name for your player!")
      self$name <- name
      private$recover()                # check for (and load) existing player history, or create a new profile
    },

    # -- print method (player info)
    print = function(...) {
      cat("Player: \n")
      cat("  Name: ", self$name, "\n", sep = "")
      cat("  Balance:  ", private$.balance, "\n", sep = "")
      cat("  Level:  ", private$.level, "\n", sep = "")
      cat("  Played:  ", nrow(private$.history), "\n", sep = "")
      cat("  Debt:  ", self$debt(), "\n", sep = "")
      invisible(self)
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
    reset = function(keep_history = FALSE) {
      private$.balance <- 0
      if (!keep_history) {
        message("Reseting profile for ", self$name, "...\n", sep = "")
        private$.history <- private$.history[-(1:nrow(private$.history)), ]
        private$.level <- 1
      }
      private$add_funds(100)
      private$update()
      invisible(self)
    },

    # -- place a bet
    bet = function(amount) {
      # loan funds if balance is currently at 0
      if (private$.balance == 0)
        private$add_funds(100)
      if (amount > private$.balance) {
        message(paste0("You cannot bet ", amount, "; you only have ", private$.balance, "!"))
        amount <- private$.balance
      }
      if (amount > 0) {
        private$.balance <- private$.balance - amount
        message(paste0("You bet ", amount, "; you have ", private$.balance, " left."))
        private$update()
      }
      invisible(amount)
    },

    # -- record the outcome of a single game played; update 'amount' in account
    record = function(game, outcome, bet, win, net) {
      new_game <- tibble::tibble(date = Sys.time(), game = game, outcome = outcome, bet = bet, win = win, net = net)
      private$.history <- dplyr::bind_rows(private$.history, new_game)
      private$.balance <- private$.balance + win
      private$set_level()
      private$update()
    },

    # -- total bank debt
    debt = function() {
      sum(private$.history$win[private$.history$game == "Bank"])
    },

    # -- summarize player gameplay history
    summary = function(...) {
      groups <- rlang::quos(...)
      private$.history %>%
        dplyr::filter(game != "Bank") %>%
        dplyr::group_by(!!!groups) %>%
        dplyr::summarize(
          games = dplyr::n(),
          bet = sum(bet),
          win = sum(win),
          net = sum(net)
        )
    },

    # -- plot player history
    plot = function() {
      private$.history %>%
        dplyr::mutate(balance = cumsum(net)) %>%
        ggplot(aes(x = date, y = balance)) +
        geom_step() +
        geom_point(aes(color = game)) +
        geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
        labs(x = "Date", y = "Balance", color = NULL) +
        theme_bw()
    }
  ),

  active = list(
    balance = function(value) {
      if (missing(value)) {
        private$.balance
      } else {
        cat(crayon::red("Oh, you want more money? LOL Nice try! :-)"))
        stop("Oh, you want more money? LOL Nice try! :-)", call. = FALSE)
      }
    },
    level = function(value) {
      if (missing(value)) {
        private$.level
      } else {
        cat(crayon::red("If you want more skill levels, you'll need to actually play!\n"))
        #stop("Oh, you want more skills? LOL Nice try! :-)", call. = FALSE)
      }
    },
    history = function(value) {
      if (missing(value)) {
        dplyr::mutate(private$.history, balance = cumsum(net))
      } else {
        cat(crayon::red("Nice try Marty McFly, but you cannot change the past!\n"))
        #stop("Are you Marty McFly?!  You cannot change the past.", call. = FALSE)
      }
    }
  ),

  private = list(

    # everyone starts with a Level 1 w/ a balance of 100
    .balance = 0,
    .level = 1,
    .history = tibble::tibble(date = Sys.time()[-1], game = character(), outcome = character(), bet = numeric(), win = numeric(), net = numeric()),

    # level progression
    levels = tibble::tibble(level = 0:99, threshold = (2 ^ level) - 1),
    set_level = function() {
      gains <- sum(private$.history$win[private$.history$game != "Bank"], na.rm = TRUE)
      private$.level <- tail(dplyr::filter(private$levels, threshold <= gains)$level, 1)
    },

    # check balance; reload if empty
    check_balance = function() {
      if (private$.balance == 0) {     # if player has 0 balance
        message("You have no money!")
        private$add_funds(100)
      }
    },

    # add funds to a player's balance
    add_funds = function(value) {
      self$record(game = "Bank", outcome = "Loan", bet = 0, win = value, net = value)
    },

    # load an existing '.casino' file with all player histories
    load = function() {
      file <- Sys.getenv("CASINO_FILE")
      if (!file.exists(file))
        stop("No '.casino' file was found.  Run `setup()` to create one.")
      readRDS(file)
    },

    # save a list of players in '.casino'
    save = function(players) {
      saveRDS(players, Sys.getenv("CASINO_FILE"))
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
      private$check_balance()    # if no player was found, this will create a new one
    }

  )
)