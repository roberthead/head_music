# Pitch Set Classification

As a music theorist

I want to classify pitch sets by their size and properties

So that I can analyze and categorize harmonic structures

Note: A PitchSet is unlike a PitchClassSet in that the pitches have spellings with octaves rather than Spellings only or octave-less 0-11 designations.

## Scenario: Get size of pitch set

Given I have a pitch set with N pitches

When I call the size method

Then it should return the number of pitches in the set

## Scenario: Identify empty set

Given I have no pitches

When I create a pitch set

Then it should be identified as an EmptySet

## Scenario: Identify monad

Given I have a single pitch

When I check the pitch set type

Then it should be identified as a Monad

And monad? should return true

## Scenario: Identify dyad

Given I have exactly two pitches

When I check the pitch set type

Then it should be identified as a Dyad

And dyad? should return true

## Scenario: Distinguish triads from trichords

Given I have three pitches

When I analyze the pitch set

Then trichord? should return true for any 3-pitch set

And triad? should return true only if they form stacked thirds

## Scenario: Identify larger pitch sets

Given I have a pitch set with N pitches

When I check the classification

Then it should be identified as:
  - Tetrachord (4 pitches) with seventh_chord? check
  - Pentachord (5 pitches)
  - Hexachord (6 pitches)
  - Heptachord (7 pitches)
  - Octachord (8 pitches)
  - Nonachord (9 pitches)
  - Decachord (10 pitches)
  - Undecachord (11 pitches)
  - Dodecachord (12 pitches)
