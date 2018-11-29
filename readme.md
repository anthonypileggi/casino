
<!-- README.md is generated from README.Rmd. Please edit that file -->
casino <img src="man/figures/logo.png" align="right" alt="" width="120" />
==========================================================================

> Welcome to the casino, we've got fun and games
>
> We got everything you want and we know your name
>
> We are the people that can find whatever you may need
>
> And if you got no money, don't worry! You can play for free!

Overview
--------

Play casino games in the R console!

Installation
------------

``` r
# Install development version from GitHub
devtools::install_github("anthonypileggi/casino")
```

Getting Started
---------------

### Create a Player

Start off by creating your player.

``` r
library(casino)

# Create a new player
player <- Player$new(name = "Anthony", amount = 100)
player
#> Player: 
#>   Name: Anthony
#>   Amount:  100
#>   Level:  1
#>   Played:
```

Then it's time to head off to the casino! What should we play first?

### Poker (5-card stud)

``` r
x <- Poker$new(who = player, type = "stud")
x$play(bet = 5)
#> You bet 5; you have 95 left.
#>  Hand: A ♦, 4 ♠, 2 ♠, 7 ♥, 2 ♥
#>  Result: one pair
#>    You won 0!
#>    Now you have 100 in your account.
#> Do you want to `play()` again?
x$play(bet = 10)
#> You bet 10; you have 90 left.
#>  Hand: 5 ♠, J ♣, K ♥, K ♠, 3 ♥
#>  Result: one pair
#>    You won 0!
#>    Now you have 100 in your account.
#> Do you want to `play()` again?
x$play(bet = 15)
#> You bet 15; you have 85 left.
#>  Hand: 7 ♠, 4 ♥, 6 ♦, A ♣, J ♠
#>  Result: A high
#>    You lost -15!
#>    Now you have 85 in your account.
#> Do you want to `play()` again?
player <- x$cash_out()     # leave the table
```

### Poker (5-card draw)

``` r
x <- Poker$new(who = player, type = "draw")
x$play(bet = 15)
#> You bet 15; you have 70 left.
#>  Hand: Q ♠, K ♥, 9 ♣, J ♣, 7 ♥
#> Choose cards to `hold()`` and then `draw()`.
x$hold(1, 2, 5)
#>  Hand: Q ♠, K ♥, 9 ♣, J ♣, 7 ♥
#> Choose cards to `hold()`` and then `draw()`.
x$draw()
#>  Hand: Q ♠, K ♥, 7 ♥, 6 ♠, 9 ♠
#>  Result: K high
#>    You lost -15!
#>    Now you have 70 in your account.
#> Do you want to `play()` again?
player <- x$cash_out()     # leave the table
```

### Blackjack

``` r
x <- Blackjack$new(who = player)
for (i in 1:5)
  x$play(bet = 5)$stand()
#> You bet 5; you have 65 left.
#> Blackjack (w/  1  decks): 
#>   Player: Anthony
#>   Bet: 5
#>  Player Hand: {6, 9} = 15
#>  Dealer Hand: {2, 8} = 10
#> Will you `hit()` or `stand()`?
#> # A tibble: 1 x 6
#>   player dealer outcome       bet   win   net
#>    <dbl>  <dbl> <chr>       <dbl> <dbl> <dbl>
#> 1     15     21 dealer wins     5     0    -5
#> You bet 5; you have 60 left.
#> Blackjack (w/  1  decks): 
#>   Player: Anthony
#>   Bet: 5
#>  Player Hand: {2, 2} = 4
#>  Dealer Hand: {4, 3} = 7
#> Will you `hit()` or `stand()`?
#> # A tibble: 1 x 6
#>   player dealer outcome       bet   win   net
#>    <dbl>  <dbl> <chr>       <dbl> <dbl> <dbl>
#> 1      4     17 dealer wins     5     0    -5
#> You bet 5; you have 55 left.
#> Blackjack (w/  1  decks): 
#>   Player: Anthony
#>   Bet: 5
#>  Player Hand: {8, 6} = 14
#>  Dealer Hand: {9, Q} = 19
#> Will you `hit()` or `stand()`?
#> # A tibble: 1 x 6
#>   player dealer outcome       bet   win   net
#>    <dbl>  <dbl> <chr>       <dbl> <dbl> <dbl>
#> 1     14     19 dealer wins     5     0    -5
#> You bet 5; you have 50 left.
#> Blackjack (w/  1  decks): 
#>   Player: Anthony
#>   Bet: 5
#>  Player Hand: {6, Q} = 16
#>  Dealer Hand: {A, 8} = 19
#> Will you `hit()` or `stand()`?
#> # A tibble: 1 x 6
#>   player dealer outcome       bet   win   net
#>    <dbl>  <dbl> <chr>       <dbl> <dbl> <dbl>
#> 1     16     19 dealer wins     5     0    -5
#> You bet 5; you have 45 left.
#> Blackjack (w/  1  decks): 
#>   Player: Anthony
#>   Bet: 5
#>  Player Hand: {4, J} = 14
#>  Dealer Hand: {A, K} = 21
#> Will you `hit()` or `stand()`?
#> # A tibble: 1 x 6
#>   player dealer outcome       bet   win   net
#>    <dbl>  <dbl> <chr>       <dbl> <dbl> <dbl>
#> 1     14     21 dealer wins     5     0    -5
player <- x$cash_out()
```

### Cashing out

What a fun day at the casino! Or, was it? Let's see how we did...

``` r
# Overall
player$summarize_history()
#> # A tibble: 1 x 4
#>   games   bet   win   net
#>   <int> <dbl> <dbl> <dbl>
#> 1     9    70    15   -55

# By Game
player$summarize_history(game)  
#> # A tibble: 2 x 5
#>   game      games   bet   win   net
#>   <chr>     <int> <dbl> <dbl> <dbl>
#> 1 Blackjack     5    25     0   -25
#> 2 Poker         4    45    15   -30
```

Well I guess you'll be back tomorrow. See you then!
