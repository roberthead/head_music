# Band Score Order

As a band director or arranger

I want to organize instruments in band score order

So that my scores follow standard concert band conventions

## Scenario: Display instruments in band order

Given I have a composition for concert band

When I request the score order for a band arrangement

Then the instruments should be ordered as follows:
  - Flutes
  - Oboes
  - Bassoons
  - Clarinets
  - Saxophones
  - Cornets
  - Trumpets
  - Horns
  - Trombones
  - Euphoniums
  - Tubas
  - Timpani
  - Percussion

## Scenario: Recognize different percussion placement

Given I am working with both orchestral and band scores

When I compare the score orders

Then I should note that percussion placement differs:
  - In orchestral scores: percussion appears after brass
  - In band scores: percussion appears at the bottom
