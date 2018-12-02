#' Slots R6 Class
#' @importFrom magrittr "%>%"
#' @export
Slots <- R6::R6Class("Slots",
  public = list(
    bet = NULL,
    who = NULL,
    reel = NULL,
    reels = NULL,
    turn = NULL,
    # -- setup machine
    initialize = function(who = NA, bet = 10) {
      self$who <- Player$new(who)
      self$bet <- bet
      self$reel <- c("!", "@", "#", "$", "%", "^", "&", "*")
      self$reel <- sample(rep(self$reel, (1:length(self$reel)) ^ 3))
      self$turn <- 0
    },

    # -- print
    print = function(...) {
      if (self$turn == 0) {
        cat("Slot Machine: \n")
        cat("Player: ", self$who$name, "\n", sep = "")
        cat("Bank: ", self$who$balance, "\n", sep = "")
        cat(" Start a new game with `play().", "\n", sep = "")
      } else if (self$turn == 1) {
        score <- tail(self$who$history, 1)
        cat(" Reels: ", self$print_reels(), "\n", sep = "")
        cat("   You ", ifelse(score$net >= 0, "won", "lost"), " ", score$net, "!\n", sep = "")
        cat("   Now you have ", self$who$balance, " in your account.\n", sep = "")
      }
      invisible(self)
    },

    # -- print reel in terminal using crayon highlighting
    print_reels = function() {
      reels <- crayon::bold(paste(self$reels, collapse = " "))
      switch(length(unique(self$reels)),
        crayon::bgGreen(reels),
        crayon::bgYellow(reels),
        crayon::bgRed(reels)
        )
    },

    # -- gameplay
    play = function(bet = self$bet, spins = 1) {
      self$bet <- bet
      for (i in 1:spins) {
        self$who$bet(bet)
        private$spin()
        private$end_game()
      }
      cat(crayon::italic("Do you want to `play()` again?", "\n", sep = ""))
      invisible(self)
    },

    # -- see payout table
    get_payout = function(bet = self$bet) {
      dplyr::mutate(
        private$payout(),
        win = bet * multiplier
      )
    }
  ),

  private = list(

    # -- spin reels
    spin = function() {
      self$reels <- sample(self$reel, 3)
      invisible(self)
    },

    # -- payout structure
    payout = function() {
      freq <- table(self$reel)
      tibble::tibble(
        outcome = purrr::map_chr(names(freq), ~paste(rep(.x, 3), collapse = " ")),
        multiplier = as.numeric(floor(1 / ((freq / sum(freq)) ^ 3)))
      ) %>%
        dplyr::arrange(desc(multiplier))
    },

    # -- score of a single game/spin
    score = function() {
      dplyr::left_join(
        tibble::tibble(outcome = paste(self$reels, collapse = " ")),
        private$payout(),
        by = "outcome"
      ) %>%
        dplyr::mutate(
          multiplier = ifelse(is.na(multiplier), 0, multiplier),
          bet = self$bet,
          win = bet * multiplier,
          net = win - bet
        )
    },

    # -- end game and record results
    end_game = function() {
      score <- private$score()
      self$who$record(game = "Slots", outcome = score$outcome, bet = score$bet, win = score$win, net = score$net)
      self$turn <- 1
      print(self)
    }

  )
)