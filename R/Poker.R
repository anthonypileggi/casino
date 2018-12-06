#' Poker R6 Class
#' @importFrom magrittr "%>%"
#' @examples
#' set.seed(101315)
#' setup()
#'
#' # draw poker
#' x <- Poker$new(who = "Player 1", type = "draw", bet = 10)
#' x$play()
#' x$hold(1, 2, 5)
#' x$draw()
#'
#' # stud poker (bet 20)
#' x <- Poker$new(who = "Player 1", type = "stud", bet = 20)
#' x$play()
#'
#' # clean-up
#' delete()
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
    turn = NULL,

    verbose = NULL,
    sound = NULL,

    initialize = function(decks = 1, type = c("draw", "stud"), who = NA, bet = 10, verbose = TRUE, sound = TRUE) {
      self$decks <- decks
      self$deck <- Deck$new(decks)
      self$type <- type[1]
      self$who <- Player$new(who)
      self$bet <- bet
      self$turn <- 0
      self$verbose <- verbose
      self$sound <- sound
    },
    print = function(...) {
      if (self$turn == 0) {
        cat("Game: Poker (w/ ", self$decks, " decks): \n")
        cat("Player: ", self$who$name, "\n", sep = "")
        cat("Bank: ", self$who$balance, "\n", sep = "")
        cat(" Start a new game with `play().", "\n", sep = "")
      } else if (self$turn == 1) {
        cat(" Hand: ", self$print_hand(), "\n", sep = "")
        cat("Choose cards to `hold()`` and then `draw()`.", "\n", sep = "")
      } else if (self$turn == 2) {
        score <- tail(self$who$history, 1)
        cat(" Hand: ", paste(self$hand$value, self$hand$suit, collapse = ", "), "\n", sep = "")
        cat(" Result: ", score$outcome, "\n", sep = "")
        #cat("   You ", ifelse(score$net >= 0, "won", "lost"), " ", score$net, "!\n", sep = "")
        self$print_outcome()
        cat("   Now you have ", self$who$balance, " in your account.\n", sep = "")
        cat("Do you want to `play()` again?", "\n", sep = "")
      }
      invisible(self)
    },

    # print helpers (for adding color to terminal output)
    print_outcome = function() {
      score <- tail(self$who$history, 1)
      color_f <- switch(1 + (score$net >= 0), crayon::red, crayon::green)
      cat(color_f("   You ", ifelse(score$net >= 0, "won", "lost"), " ", score$net, "!\n", sep = ""))
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
      if (self$turn != 0)
        stop("You already started a game!")
      #self$bet <- bet
      self$bet <- self$who$bet(bet)
      self$hand <- NULL
      if (self$deck$cards_left() < 10)
        self$deck$shuffle()
      self$deal(5)
      self$keep <- rep(FALSE, 5)
      if (self$type == "draw") {
        self$turn <- 1
        if (self$verbose)
          print(self)
      } else if (self$type == "stud") {
        self$turn <- 2
        self$end_game()
      }
      invisible(self)
    },

    # -- select cards to HOLD
    hold = function(...) {
      id <- c(...)
      self$keep[id] <- TRUE
      if (self$verbose)
        print(self)
      invisible(self)
    },

    # -- draw more cards (pending ones with HOLD status)
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

    # -- end a poker game; determine outcome; record results
    end_game = function() {
      score <- self$score()
      self$who$record(game = "Poker", outcome = score$outcome, bet = score$bet, win = score$win, net = score$net)
      if (self$sound && score$win > 0)
        play_sound()
      if (self$verbose)
        print(self)
      self$turn <- 0
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
          mode = tail(as.numeric(names(sort(table(value)))), 1),
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
              n_pairs == 1 & n_kind == 2 & mode > 10 ~ "one pair (jacks or better)",
              n_pairs == 1 & n_kind == 2 & mode <= 10 ~ "one pair",
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
    },

    # -- see payout table
    get_payout = function(bet = self$bet) {
      dplyr::mutate(
        private$payout,
        win = bet * multiplier
      )
    }
  ),

  private = list(

    # -- payout table
    payout = dplyr::tribble(
        ~outcome, ~multiplier,
        "royal flush", 800,
        "straight flush", 200,
        "4-of-a-kind", 25,
        "full house", 10,
        "flush", 7,
        "straight", 5,
        "3-of-a-kind", 3,
        "two pair", 2,
        "one pair (jacks or better)", 1
      )

  )

)