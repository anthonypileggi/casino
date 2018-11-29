#' Poker R6 Class
#' @importFrom magrittr "%>%"
#' @export
Poker <- R6::R6Class("Poker",
  public = list(
    decks = NULL,
    type = NULL,
    bet = NULL,
    deck = NULL,
    who = NULL,
    hand = NULL,
    keep = NULL,
    history = NULL,
    turn = NULL,
    initialize = function(decks = 1, type = c("draw", "stud"), who = NA, bet = 10) {
      self$decks <- decks
      self$deck <- Deck$new(decks)
      self$type <- type
      self$who <- who
      self$bet <- bet
      self$turn <- 0
    },
    print = function(...) {
      if (self$turn == 0) {
        cat("Game: Poker (w/ ", self$decks, " decks): \n")
        cat("Player: ", self$who$name, "\n", sep = "")
        cat("Bank: ", self$who$amount, "\n", sep = "")
        cat(" Start a new game with `play().", "\n", sep = "")
      } else if (self$turn == 1) {
        cat(" Hand: ", self$print_hand(), "\n", sep = "")
        cat("Choose cards to `hold()`` and then `draw()`.", "\n", sep = "")
      } else if (self$turn == 2) {
        score <- tail(self$history, 1)
        cat(" Hand: ", paste(self$hand$value, self$hand$suit, collapse = ", "), "\n", sep = "")
        cat(" Result: ", score$outcome, "\n", sep = "")
        cat("   You ", ifelse(score$net >= 0, "won", "lost"), " ", score$net, "!\n", sep = "")
        cat("   Now you have ", self$who$amount, " in your account.\n", sep = "")
        cat("Do you want to `play()` again?", "\n", sep = "")
      }
      invisible(self)
    },
    print_hand = function() {
      paste(
        purrr::map_chr(
          1:nrow(self$hand),
          function(i) {
            card <- paste(self$hand$value[i], self$hand$suit[i])
            if (self$keep[i])
              card <- crayon::underline(crayon::bold(card))
            card
          }
        ),
        collapse = ", "
      )
    },
    # -- prep
    deal = function(n) {
      self$hand <- dplyr::bind_rows(self$hand, self$deck$draw(n))
      self$turn <- self$turn + 1
    },
    # -- gameplay
    play = function(bet = self$bet) {
      self$bet <- bet
      self$who$bet(bet)
      self$hand <- NULL
      if (self$deck$cards_left() < 10)
        self$deck$shuffle()
      self$deal(5)
      self$keep <- rep(FALSE, 5)
      if (self$type == "draw") {
        self$turn <- 1
        print(self)
      } else if (self$type == "stud") {
        self$turn <- 2
        self$end_game()
      }
      invisible(self)
    },
    hold = function(...) {
      id <- c(...)
      self$keep[id] <- TRUE
      print(self)
      invisible(self)
    },
    draw = function() {
      if (self$turn == 1) {
        n <- sum(!self$keep)
        self$hand <- self$hand[self$keep, ]
        self$deal(n)
        self$end_game()
      } else {
        message("The game is over.  Start a new game with `play()`.")
      }
      invisible(self)
    },
    end_game = function() {
      score <- self$score()
      self$history <- dplyr::bind_rows(self$history, score)
      self$who$record(game = "Poker", outcome = score$outcome, bet = score$bet, win = score$win, net = score$net)
      print(self)
      self$turn <- 0
    },
    # -- spit out post-game player info
    cash_out = function() {
      self$who
    },
    # -- score a poker hand
    score = function() {
      self$hand %>%
        dplyr::mutate(
          old_value = value,
          value = dplyr::case_when(
            value == "J"  ~ 11,
            value == "Q" ~ 12,
            value == "K" ~ 13,
            value == "A" & all(2:5 %in% value) ~ 1,      # make A==1 if hand includes 2,3,4,5
            value == "A" ~ 14,
            TRUE ~ suppressWarnings(as.numeric(value))
          )
        ) %>%
        dplyr::summarize(
          is_straight = all(diff(sort(value)) == 1),
          is_flush = length(unique(suit)) == 1,
          uniques = length(table(value)),
          n_pairs = sum(table(value) == 2),
          n_kind = max(table(value)),
          outcome =
            dplyr::case_when(
              all(value %in% 10:14) & is_flush ~ "royal flush",
              is_straight & is_flush ~ "straight flush",
              n_kind == 4 ~ "4-of-a-kind",
              n_kind == 3 & n_pairs == 2 ~ "full house",
              is_flush ~ "flush",
              is_straight ~ "straight",
              max(table(value)) == 3 ~ "3-of-a-kind",
              n_pairs == 2 & n_kind == 2 ~ "two pair",
              n_pairs == 1 & n_kind == 2 ~ "one pair",
              TRUE ~ paste(old_value[which.max(value)], "high")
            )
        ) %>%
        dplyr::left_join(
          private$payout,
          by = "outcome"
        ) %>%
        dplyr::mutate(
          multiplier = ifelse(is.na(multiplier), 0, multiplier),
          bet = self$bet,
          win = bet * multiplier,
          net = win - bet
        ) %>%
        dplyr::select(outcome, bet, win, net)
    }
  ),

  private = list(

    payout = dplyr::tribble(
        ~outcome, ~multiplier,
        "royal flush", 100,
        "straight flush", 50,
        "4-of-a-kind", 40,
        "full house", 30,
        "flush", 25,
        "straight", 20,
        "3-of-a-kind", 15,
        "two pair", 5,
        "one pair", 1
      )

  )

)