#' Blackjack R6 Class
#' @importFrom magrittr "%>%"
#' @examples
#' set.seed(101315)
#' setup()
#'
#' # sit at the blackjack table
#' x <- Blackjack$new(who = "Player 1", bet = 10)
#'
#' # play a hand
#' x$play()
#'
#' x$hit()
#'
#' x$stand()
#'
#' # play a hand blind w/out drawing
#' x$play()$stand()
#'
#' # clean-up
#' delete()
#' @export
Blackjack <- R6::R6Class("Blackjack",

  public = list(

    decks = NULL,
    bet = NULL,
    who = NULL,

    verbose = NULL,
    sound = NULL,

    # TODO: make the 'dealer' object private (so player cannot see the first card!!)
    player = NULL,
    dealer = NULL,

    active = FALSE,

    # setup blackjack table
    initialize = function(who = NA, decks = 1,  bet = 10, verbose = TRUE, sound = TRUE) {
      self$decks <- decks
      private$deck <- Deck$new(decks)
      self$who <- Player$new(who)
      self$bet <- bet
      self$verbose <- verbose
      self$sound <- sound
    },

    # print method
    print = function(...) {
      if (!self$active) {
        cat("Blackjack (w/ ", self$decks, " decks): \n")
        cat("Player: ", self$who$name, "\n", sep = "")
        cat("Bank: ", self$who$balance, "\n", sep = "")
        cat("Start a new game with `play()`.", "\n", sep = "")
      } else {
        p <- private$score_hand("player")$total
        d <- private$score_hand("dealer")$total
        cat(" Player Hand: {", paste(self$player$value, collapse = ", "), "} = ", p, "\n", sep = "")
        cat(private$print_dealer())
        cat("Will you `hit()` or `stand()`?", "\n", sep = "")
      }
      # TODO: print outcome of a game
      invisible(self)
    },

    # -- start a new game
    play = function(bet = self$bet) {
      if (self$active)
        stop("You already started a game!")
      self$bet <- self$who$bet(bet)
      self$player <- self$dealer <- NULL
      if (private$deck$cards_left() < 15)
        private$deck$shuffle()
      for (i in 1:2) {
        private$deal("player")
        private$deal("dealer")
      }
      self$active <- TRUE
      private$check_scores()    # check if anyone has 21 yet
      if (self$verbose)
        print(self)
      invisible(self)
    },

    # -- hit
    hit = function() {
      if (self$active)
        private$deal("player")
      private$check_scores()
      if (self$verbose)
        print(self)
      invisible(self)
    },

    # -- stand
    stand = function() {
      private$end_game()
    }
  ),

  active = list(),

  private = list(

    deck = NULL,

    # -- print-helper: print the dealer's hand
    print_dealer = function() {
      paste(" Dealer Hand: {?, ", paste(self$dealer$value[-1], collapse = ", "), "} = ?\n", sep = "")
    },

    # -- deal a card to player/dealer
    deal = function(to = "player") {
      self[[to]] <- dplyr::bind_rows(self[[to]], private$deck$draw())
    },

    # -- end the game
    end_game = function() {
      private$play_dealer()
      result <- private$score()
      self$who$record(game = "Blackjack", outcome = result$outcome, bet = result$bet, win = result$win, net = result$net)
      self$active <- FALSE
      if (self$sound && result$win > 0)
        beepr::beep("fanfare")
      if (self$verbose) {
        cat("Game over! ", result$outcome, "\n", sep = "")
        cat("  You ", ifelse(result$net >= 0, "won", "lost"), " ", result$net, "!\n", sep = "")
        cat("  Now you have ", self$who$balance, " in your account.\n", sep = "")
      }
    },

    # -- finish the dealers turn
    play_dealer = function() {
      keep_going <- TRUE
      while (keep_going) {
        total <- private$score_hand("dealer")$total
        if (total > 16) {
          keep_going <- FALSE
        } else {
          private$deal("dealer")
        }
      }
    },

    # Scoring
    # -- get all possible ace totals for a hand
    ace_totals = function(to = "player") {
      n_aces <- sum(self[[to]] == "A")
      if (n_aces == 0)
        return(0)
      ace_combos <- combn(rep(c(1, 11), n_aces), n_aces)
      sort(
        unique(
          apply(ace_combos, 2, sum)
        )
      )
    },
    # -- score a single hand (player or dealer)
    score_hand = function(to = "player") {
      score <- self[[to]] %>%
        dplyr::mutate(
          value = dplyr::case_when(
            value %in% c("J", "Q", "K") ~ 10,
            value != "A" ~ suppressWarnings(as.numeric(value))
          )
        ) %>%
        dplyr::summarise(
          cards = dplyr::n(),
          total = sum(value, na.rm = TRUE)
        )
      # get all score possiblities (based on Aces)
      scores <- purrr::map_df(
        private$ace_totals(to),
        ~dplyr::mutate(score, total = total + .x)
        )
      # return the 'best' score among all options
      if (all(scores$total > 21)) {
        head(scores, 1)
      } else {
        scores %>%
          dplyr::filter(total <= 21) %>%
          tail(1)
      }
    },

    # -- get the result of a single game
    score = function() {
      p <- private$score_hand("player")$total
      d <- private$score_hand("dealer")$total
      tibble::tibble(
        player = p,
        dealer = d,
        outcome = dplyr::case_when(
          p > 21 ~ "player bust",       # player bust
          d > 21 ~ "dealer bust",       # dealer bust
          p == d ~ "push",              # tie
          p > d ~ "player wins",        # player wins
          p < d ~ "dealer wins"         # dealer wins
        ),
        bet = self$bet,
        win = dplyr::case_when(
          outcome %in% c("player wins", "dealer bust") ~ self$bet * 2,
          outcome %in% c("dealer wins", "player bust") ~ 0,
          outcome %in% "push" ~ self$bet
        ),
        net = win - bet
      )
    },

    # -- check for blackjack and/or 21, and if found end the game
    check_scores = function() {
      score <- private$score()
      if (score$player == 21 & nrow(self$player) == 2)
          message("You got Blackjack!\n")
      if (score$dealer == 21 & nrow(self$dealer) == 2)
        message("Dealer got Blackjack!\n")
      if (score$player >= 21)
        private$end_game()
    }
  )
)
