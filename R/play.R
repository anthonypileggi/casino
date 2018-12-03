
#' Play in the casino
#' @export
play <- function(name = "Player 1") {

  # Create/Load player profile
  name <- readline(prompt = "Enter your name: ")
  Player$new(name)

  # Start playing
  game <- readline(prompt = "Available Games:\n\t1. Blackjack\n\t2. Poker\n\t3. Slots\n\nWhat game do you want to play?  ")
  if (game %in% c("1", "Blackjack")) {
    g <- Blackjack$new(who = name)
  } else if (game %in% c("2", "Poker")) {
    type <- readline(prompt = "Options:\n\t1. Draw\n\t2. Stud\n\nWhat game do you want to play?  ")
    if (tolower(type) %in% c("1", "draw")) {
      g <- Poker$new(who = name, type = "draw")
    } else if (tolower(type) %in% c("2", "stud")) {
      g <- Poker$new(who = name, type = "stud")
    }
  } else if (game %in% c("3", "Slots")) {
    g <- Slots$new(who = name)
  }

  return(g)
}