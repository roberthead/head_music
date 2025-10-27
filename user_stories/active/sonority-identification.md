# Sonority Identification

As a music theorist or composer

I want to identify and work with named sonorities

So that I can analyze and create harmonic structures

## Scenario: Get sonority by identifier

Given I need a specific sonority

When I call Sonority.get with an identifier like "major_triad"

Then I should receive the corresponding sonority object

And it should contain the correct interval structure

## Scenario: Generate pitch collection from sonority

Given I have a sonority identifier and a root pitch

When I call a method to generate pitches

Then I should receive the correct pitches for that sonority

And they should be in the specified inversion

## Scenario: Access sonority from pitch collection

Given I have a PitchCollection object

When I call the sonority method

Then I should receive the corresponding Sonority object

And it should correctly identify the harmonic content
