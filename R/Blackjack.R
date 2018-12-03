#' Blackjack R6 Class
#' @importFrom magrittr "%>%"
#' @export
Blackjack <- R6::R6Class("Blackjack",

  public = list(

    decks = NULL,
    bet = NULL,
    who = NULL,

    # TODO: make the 'dealer' object private (so player cannot see the first card!!)
    player = NULL,
    dealer = NULL,

    active = FALSE,

    # setup blackjack table
    initialize = function(decks = 1, who = NA, bet = 10) {
      self$decks <- decks
      private$deck <- Deck$new(decks)
      self$who <- Player$new(who)
      self$bet <- bet
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
        cat(self$print_dealer())
        cat("Will you `hit()` or `stand()`?", "\n", sep = "")
      }
      # TODO: print outcome of a game
      invisible(self)
    },

    print_dealer = function() {
      paste(" Dealer Hand: {?, ", paste(self$dealer$value[-1], collapse = ", "), "} = ?\n", sep = "")
    },

    # -- start a new game
    play = function(bet = self$bet) {
      self$bet <- bet
      self$who$bet(bet)
      self$player <- self$dealer <- NULL
      if (private$deck$cards_left() < 15)
        private$deck$shuffle()
      for (i in 1:2) {
        private$deal("player")
        private$deal("dealer")
      }
      self$active <- TRUE
      print(self)
      invisible(self)
    },

    # -- hit
    hit = function() {
      if (self$active)
        private$deal("player")
      if (private$score_hand("player")$total > 21) {
        private$end_game()
      } else {
        print(self)
      }
      invisible(self)
    },

    # -- stand
    stand = function() {
      private$play_dealer()
      private$end_game()
    }
  ),

  active = list(),

  private = list(

    deck = NULL,

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
          head(1)
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
    }

  )
)
