# Sonority Identification

As a music theorist or composer

I want to identify and work with named sonorities

So that I can analyze and create harmonic structures

## Scenario: Get sonority by identifier

Given I need a specific sonority

When I call Sonority.get with an identifier like "major triad"

Then I should receive the corresponding sonority object

And it should contain the correct interval structure

## Scenario: Identify sonority from pitch set

Given I have a set of pitches

When I call Sonority.for with the pitch set

Then I should receive the identified sonority

And it should correctly name the harmonic structure

## Scenario: Generate pitch set from sonority

Given I have a sonority and a root pitch

When I call Sonority.pitch_set_for with root pitch and inversion

Then I should receive the correct pitches

And they should be in the specified inversion

## Scenario: Access sonority from pitch set

Given I have a PitchSet object

When I call the sonority method

Then I should receive the corresponding Sonority object

And it should correctly identify the harmonic content

## Scenario: Work with triads

Given I need to analyze triadic harmony

When I work with Triad objects

Then I should be able to identify major, minor, diminished, and augmented triads

And access their specific properties and methods

## Scenario: Work with seventh chords

Given I need to analyze seventh chord harmony

When I work with SeventhChord objects

Then I should be able to identify all common seventh chord types

And note that nothing beyond seventh chords is needed to analyze pre-Romantic music
