# Consonance and Dissonance Classification

As a music theorist or counterpoint student

I want to classify intervals by their consonance and dissonance levels

So that I can apply proper voice leading rules

## Scenario: Classify open consonances

Given I have a perfect fifth or perfect octave

When I check the consonance classification

Then it should be identified as "open consonance"

## Scenario: Classify soft consonances

Given I have a third or sixth interval (major or minor)

When I check the consonance classification

Then it should be identified as "soft consonance"

## Scenario: Classify mild dissonances

Given I have a major second or minor seventh

When I check the consonance classification

Then it should be identified as "mild dissonance"

## Scenario: Classify sharp dissonances

Given I have a minor second or major seventh

When I check the consonance classification

Then it should be identified as "sharp dissonance"

## Scenario: Handle perfect fourth context

Given I have a perfect fourth interval

When I check the consonance classification

Then it should indicate context-dependent classification

And note it can be either consonant or dissonant

## Scenario: Classify tritone

Given I have a tritone interval

When I check the consonance classification

Then it should be identified as "neutral" or "restless"
