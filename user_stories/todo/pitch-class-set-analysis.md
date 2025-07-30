# Pitch Class Set Analysis

As a music theorist studying atonal music

I want to analyze pitch class sets

So that I can identify set relationships and transformations

## Scenario: Get size of pitch class set

Given I have a pitch class set

When I call the size method

Then it should return the number of unique pitch classes

## Scenario: Check if monad

Given I have a pitch class set with one pitch class

When I call monad?

Then it should return true

## Scenario: Check if dyad

Given I have a pitch class set with two pitch classes

When I call dyad?

Then it should return true

## Scenario: Check if triad

Given I have a pitch class set with three pitch classes

When I call triad?

Then it should return true only if they form stacked thirds

## Scenario: Check if trichord

Given I have a pitch class set with three pitch classes

When I call trichord?

Then it should return true for any 3-pitch class set

## Scenario: Find normal form

Given I have a pitch class set

When I request the normal form

Then I should receive the most compact rotation

And it should minimize the interval span

## Scenario: Find prime form

Given I have a pitch class set

When I request the prime form

Then I should receive the most compact form

And it should consider both the original and all inversions

And it should be the optimal normal form among all possibilities

## Scenario: Compare equivalent sets

Given I have two different pitch class sets

When I compare their prime forms

Then I can determine if they are equivalent

And identify the transformation relationship between them
