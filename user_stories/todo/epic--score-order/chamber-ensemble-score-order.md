# Chamber Ensemble Score Order

As a chamber music composer

I want to organize instruments in standard chamber ensemble orders

So that my scores follow established conventions for small ensembles

## Scenario: Display brass quintet in standard order

Given I have a brass quintet composition

When I request the score order

Then the instruments should be ordered as follows:
  - Trumpet I
  - Trumpet II
  - Horn
  - Trombone
  - Tuba

## Scenario: Display woodwind quintet in standard order

Given I have a woodwind quintet composition

When I request the score order

Then the instruments should be ordered as follows:
  - Flute
  - Oboe
  - Clarinet
  - Horn
  - Bassoon
