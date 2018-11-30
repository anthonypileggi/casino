
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
#>  Hand: 4 ♣, J ♦, 8 ♦, 4 ♦, 8 ♠
#>  Result: two pair
#>    You won 20!
#>    Now you have 120 in your account.
#> Do you want to `play()` again?
x$play(bet = 10)
#> You bet 10; you have 110 left.
#>  Hand: Q ♣, 7 ♥, K ♣, 10 ♠, A ♥
#>  Result: A high
#>    You lost -10!
#>    Now you have 110 in your account.
#> Do you want to `play()` again?
x$play(bet = 15)
#> You bet 15; you have 95 left.
#>  Hand: 9 ♥, 6 ♥, 10 ♥, 5 ♠, K ♦
#>  Result: K high
#>    You lost -15!
#>    Now you have 95 in your account.
#> Do you want to `play()` again?
player <- x$cash_out()     # leave the table
```

### Poker (5-card draw)

``` r
x <- Poker$new(who = player, type = "draw")
x$play(bet = 15)
#> You bet 15; you have 80 left.
#>  Hand: 4 ♥, 7 ♥, A ♠, 8 ♠, 4 ♦
#> Choose cards to `hold()`` and then `draw()`.
x$hold(1, 2, 5)
#>  Hand: 4 ♥, 7 ♥, A ♠, 8 ♠, 4 ♦
#> Choose cards to `hold()`` and then `draw()`.
x$draw()
#>  Hand: 4 ♥, 7 ♥, 4 ♦, 7 ♣, 4 ♣
#>  Result: 3-of-a-kind
#>    You won 210!
#>    Now you have 305 in your account.
#> Do you want to `play()` again?
player <- x$cash_out()     # leave the table
```

### Blackjack

``` r
x <- Blackjack$new(who = player)
for (i in 1:5)
  x$play(bet = 5)$stand()
#> You bet 5; you have 300 left.
#> Blackjack (w/  1  decks): 
#>   Player: Anthony
#>   Bet: 5
#>  Player Hand: {10, 8} = 18
#>  Dealer Hand: {A, Q} = 21
#> Will you `hit()` or `stand()`?
#> # A tibble: 1 x 6
#>   player dealer outcome       bet   win   net
#>    <dbl>  <dbl> <chr>       <dbl> <dbl> <dbl>
#> 1     18     21 dealer wins     5     0    -5
#> You bet 5; you have 295 left.
#> Blackjack (w/  1  decks): 
#>   Player: Anthony
#>   Bet: 5
#>  Player Hand: {7, 8} = 15
#>  Dealer Hand: {K, 2} = 12
#> Will you `hit()` or `stand()`?
#> # A tibble: 1 x 6
#>   player dealer outcome       bet   win   net
#>    <dbl>  <dbl> <chr>       <dbl> <dbl> <dbl>
#> 1     15     22 dealer bust     5    10     5
#> You bet 5; you have 300 left.
#> Blackjack (w/  1  decks): 
#>   Player: Anthony
#>   Bet: 5
#>  Player Hand: {Q, 6} = 16
#>  Dealer Hand: {6, 10} = 16
#> Will you `hit()` or `stand()`?
#> # A tibble: 1 x 6
#>   player dealer outcome       bet   win   net
#>    <dbl>  <dbl> <chr>       <dbl> <dbl> <dbl>
#> 1     16     25 dealer bust     5    10     5
#> You bet 5; you have 305 left.
#> Blackjack (w/  1  decks): 
#>   Player: Anthony
#>   Bet: 5
#>  Player Hand: {J, 3} = 13
#>  Dealer Hand: {9, J} = 19
#> Will you `hit()` or `stand()`?
#> # A tibble: 1 x 6
#>   player dealer outcome       bet   win   net
#>    <dbl>  <dbl> <chr>       <dbl> <dbl> <dbl>
#> 1     13     19 dealer wins     5     0    -5
#> You bet 5; you have 300 left.
#> Blackjack (w/  1  decks): 
#>   Player: Anthony
#>   Bet: 5
#>  Player Hand: {6, 3} = 9
#>  Dealer Hand: {9, 5} = 14
#> Will you `hit()` or `stand()`?
#> # A tibble: 1 x 6
#>   player dealer outcome       bet   win   net
#>    <dbl>  <dbl> <chr>       <dbl> <dbl> <dbl>
#> 1      9     20 dealer wins     5     0    -5
player <- x$cash_out()
```

### Slot Machine

``` r
x <- Slots$new(who = player, bet = 1)
x$play()
#> You bet 1; you have 299 left.
#>  Reels: * * ^
#>    You lost -1!
#>    Now you have 299 in your account.
#> Do you want to `play()` again?

# Let's just go for it...
x$play(spins = 5)
#> You bet 1; you have 298 left.
#>  Reels: * * #
#>    You lost -1!
#>    Now you have 298 in your account.
#> You bet 1; you have 297 left.
#>  Reels: * ^ ^
#>    You lost -1!
#>    Now you have 297 in your account.
#> You bet 1; you have 296 left.
#>  Reels: ^ # &
#>    You lost -1!
#>    Now you have 296 in your account.
#> You bet 1; you have 295 left.
#>  Reels: * * %
#>    You lost -1!
#>    Now you have 295 in your account.
#> You bet 1; you have 294 left.
#>  Reels: * ^ &
#>    You lost -1!
#>    Now you have 294 in your account.
#> Do you want to `play()` again?
```

### Cashing out

What a fun day at the casino! Or, was it? Let's see how we did...

``` r
# Overall
player$summarize_history()
#> # A tibble: 1 x 4
#>   games   bet   win   net
#>   <int> <dbl> <dbl> <dbl>
#> 1    15    76   270   194

# By Game
player$summarize_history(game)  
#> # A tibble: 3 x 5
#>   game      games   bet   win   net
#>   <chr>     <int> <dbl> <dbl> <dbl>
#> 1 Blackjack     5    25    20    -5
#> 2 Poker         4    45   250   205
#> 3 Slots         6     6     0    -6
```

Well I guess you'll be back tomorrow. See you then!
