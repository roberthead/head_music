# Pitch Class Set Analysis

As a music theorist studying atonal music

I want to analyze pitch class sets

So that I can identify set relationships and transformations

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
