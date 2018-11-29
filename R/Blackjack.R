#' Blackjack R6 Class
#' @importFrom magrittr "%>%"
#' @export
Blackjack <- R6::R6Class("Blackjack",
  public = list(
    decks = NULL,
    bet = NULL,
    deck = NULL,
    who = NULL,
    player = NULL,
    dealer = NULL,
    history = NULL,
    active = FALSE,
    initialize = function(decks = 1, who = NA, bet = 10) {
      self$decks <- decks
      self$deck <- Deck$new(decks)
      self$who <- who
      self$bet <- bet
    },
    print = function(...) {
      cat("Blackjack (w/ ", self$decks, " decks): \n")
      cat("  Player: ", self$who$name, "\n", sep = "")
      cat("  Bet: ", self$bet, "\n", sep = "")
      if (self$active) {
        p <- private$summarize_hand("player")$total
        d <- private$summarize_hand("dealer")$total
        cat(" Player Hand: {", paste(self$player$value, collapse = ", "), "} = ", p, "\n", sep = "")
        cat(" Dealer Hand: {", paste(self$dealer$value, collapse = ", "), "} = ", d, "\n", sep = "")
        cat("Will you `hit()` or `stand()`?", "\n", sep = "")
      } else {
        cat(" Start a new game with `play().", "\n", sep = "")
      }
      invisible(self)
    },
    # -- prep
    deal = function(to = "player") {
      self[[to]] <- dplyr::bind_rows(self[[to]], self$deck$draw())
    },
    # -- gameplay
    play = function(bet = self$bet) {
      self$bet <- bet
      self$who$bet(bet)
      self$player <- self$dealer <- NULL
      if (self$deck$cards_left() < 15)
        self$deck$shuffle()
      for (i in 1:2) {
        self$deal("player")
        self$deal("dealer")
      }
      self$active <- TRUE
      print(self)
      invisible(self)
    },
    hit = function() {
      if (self$active)
        self$deal("player")
      if (private$summarize_hand("player")$total > 21) {
        private$record()
      } else {
        print(self)
      }
      invisible(self)
    },
    stand = function() {
      private$play_dealer()
      private$record()
    },
    # -- spit out post-game player info
    cash_out = function() {
      self$who
    },
    # get the result of a single game
    result = function() {
      p <- private$summarize_hand("player")$total
      d <- private$summarize_hand("dealer")$total
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
    }
  ),


  private = list(

    # finish the dealers turn
    play_dealer = function() {
      keep_going <- TRUE
      while (keep_going) {
        total <- private$summarize_hand("dealer")$total
        if (total > 16) {
          keep_going <- FALSE
        } else {
          self$deal("dealer")
        }
      }
    },

    # summarize a single hand (player or dealer)
    summarize_hand = function(to = "player") {
      self[[to]] %>%
        dplyr::mutate(
          value = dplyr::case_when(
            value %in% c("J", "Q", "K") ~ 10,
            value %in% "A" ~ 11,        # TODO: spread out all options, esp. if there are > 1 Ace
            TRUE ~ suppressWarnings(as.numeric(value))
          )
        ) %>%
        dplyr::summarise(
          cards = dplyr::n(),
          total = sum(value)
        )
    },

    # record the results of a single game
    record = function() {
      result <- self$result()
      print(result)
      self$history <- dplyr::bind_rows(self$history, result)
      self$who$record(game = "Blackjack", outcome = result$outcome, bet = result$bet, win = result$win, net = result$net)
      self$active <- FALSE
    }
  )
)
