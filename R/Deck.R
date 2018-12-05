#' Deck R6 Class
#' @importFrom magrittr "%>%"
#' @export
Deck <- R6::R6Class("Deck",
  public = list(

    decks = NULL,
    deck = NULL,
    discard = NULL,

    # -- create a new deck
    initialize = function(decks = 1) {
      self$decks <- decks
      private$create()
      self$shuffle()
    },

    # -- print method
    print = function(...) {
      cat("Deck: \n")
      cat("  Decks: ", self$decks, "\n", sep = "")
      cat("  Cards:  ", 52 * self$decks, "\n", sep = "")
      cat("  Cards dealt:  ", 52 * self$decks - nrow(self$deck), "\n", sep = "")
      cat("  Cards left:  ", nrow(self$deck), "\n", sep = "")
      cat("  Next card:  ", self$deck$value[1], " ", self$deck$suit[1], "s\n", sep = "")
      invisible(self)
    },

    # -- reset deck and shuffle
    shuffle = function() {
      private$create()
      self$deck <- dplyr::sample_n(self$deck, nrow(self$deck))
      invisible(self)
    },

    # -- draw 'n' cards from the top of the deck
    draw = function(n = 1) {
      # TODO: shuffling in the middle of a game is probably not okay!
      if (self$cards_left() < n)
        self$shuffle()
      cards <- self$deck[1:n, ]
      self$deck <- self$deck[-(1:n), ]
      cards
    },

    # -- how many cards are left in the deck?
    cards_left = function() {
      nrow(self$deck)
    }

  ),


  private = list(

    # create a new set of decks
    create = function() {
      deck <-
        tidyr::crossing(
          value = c(2:10, "J", "Q", "K", "A"),
          #suit = c("heart", "diamond", "spade", "club")
          suit = c("\u2665", "\u2666", "\u2660", "\u2663")
        )
      self$deck <- purrr::map_df(1:self$decks, ~deck)
    }

  )
)