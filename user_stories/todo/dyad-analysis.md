# Dyad Analysis

As a music analyst or counterpoint student

I want to analyze two-note combinations (dyads)

So that I can understand harmonic implications in two-part music

Constructor should accept to pitches (or pitch classes) and an optional key

## Scenario: Identify interval in dyad

Given I have two pitches forming a dyad

When I access the interval property

Then I should receive the correct interval between the pitches

## Scenario: List possible triads from fifth

Given I have a dyad forming a perfect fifth

When I request possible triads

Then I should receive both major and minor triad options

And each should contain the given pitches

## Scenario: List possible triads from third

Given I have a dyad forming a minor third

When I request possible triads

Then I should receive minor and diminished triad options

And for a major third I should receive major and augmented options

## Scenario: Find possible seventh chords

Given I have a dyad

When I request possible seventh chords

Then I should receive all seventh chords containing those pitches

And they should include appropriate inversions

## Scenario: Handle enharmonic possibilities

Given I have a dyad with enharmonic possibilities

When I request possible enharmonic chords

Then I should receive chords based on enharmonic respellings

And each should be correctly identified
