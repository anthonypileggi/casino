
#' Play in the casino
#' @export
play <- function(name = "Player 1") {

  # Create/Load player profile
  name <- readline(prompt = "Enter your name: ")
  Player$new(name)

  # Start playing
  again <- "y"
  while (tolower(again) %in% c("1", "y")) {
    game <- readline(prompt = "Available Games:\n\t1. Blackjack\n\t2. Poker\n\t3. Slots\n\t4. Quit\n\nWhat game do you want to play?  ")
    if (tolower(game) %in% c("1", "blackjack")) {
      play_blackjack(name)
    } else if (tolower(game) %in% c("2", "poker")) {
      type <- readline(prompt = "Options:\n\t1. Draw\n\t2. Stud\n\nWhat game do you want to play?  ")
      if (tolower(type) %in% c("1", "draw")) {
        play_poker(name, type = "draw")
      } else if (tolower(type) %in% c("2", "stud")) {
        play_poker(name, type = "stud")
      }
    } else if (tolower(game) %in% c("3", "slots")) {
      play_slots(name)
    } else if (tolower(game) %in% c("4", "quit")) {
      again <- "n"
    } else {
      message("Invalid selection!  Please choose from options [1-4].")
    }
  }

  return("Thanks for playing!")
}

#' Play poker
play_poker <- function(name, type) {
  g <- Poker$new(who = name, type = type)
  keep_playing <- ""
  while (keep_playing == "") {
    g$play()
    while (g$turn != 0) {
      action <- readline(prompt = "Choose [1-5] to HOLD, or press [ENTER] to DRAW.  ")
      if (action %in% as.character(1:5)) {
        g$hold(as.numeric(action))
      } else {
        g$draw()
      }
    }
    keep_playing <- readline(prompt = "Press [Enter] to play again, or type anything to stop.  ")
  }
}

#' Play blackjack
play_blackjack <- function(name) {
  g <- Blackjack$new(who = name)
  keep_playing <- ""
  while (keep_playing == "") {
    g$play()
    while (g$active) {
      act <- readline(prompt = "Options:\n\t1. Hit\n\t2. Stand  ")
      if (tolower(act) %in% c("1", "hit"))
        g$hit()
      if (tolower(act) %in% c("2", "stand"))
        g$stand()
    }
    keep_playing <- readline(prompt = "Press [Enter] to play again, or type anything to stop.  ")
  }
}

#' Play the slot machine
play_slots <- function(name) {
  g <- Slots$new(who = name)
  keep_playing <- ""
  while (keep_playing == "") {
    g$play()
    keep_playing <- readline(prompt = "Press [Enter] to spin again, or anything else to stop.  ")
  }
}