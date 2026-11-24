<!--
metadata:
  created_at:   2026-11-24T13:44:31-05:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-11-24T13:44:31-05:00
-->

# Story: Recognize the Escape Tone (Échappée)

## Summary

AS a consumer of the gem grading counterpoint (BardTheory's exercises)
I WANT the gem to recognize an escape tone as a dissonance figure
SO THAT a guide that allows the figure can accept it, instead of marking a well-formed échappée as an untreated dissonance

## Acceptance Criteria

- `HeadMusic::Style::Guideline::DissonanceFigures` answers `escape_tone?(note)`: the note is dissonant and unaccented, approached by step from a consonant note, and left by a leap in the opposite direction to a consonant note
- The size of the leap is settled in planning (a third is the textbook case; see Open Questions)
- `DissonanceFigureDetection` delegates `escape_tone?` alongside the existing figures, so any dissonance guideline can opt in through `recognized_figure?`
- Recognition is separate from permission: adding the predicate changes no existing guide's marks. Which guides allow the figure is decided by the open question below
- The first three notes of a double neighbor (C–D–B, going on to C) are not reported as an escape tone when the figure completes as a double neighbor; planning decides whether the two predicates may both be true for that note or the double neighbor takes precedence
- Specs cover an ascending and a descending escape tone, a step-then-leap in the same direction (not an escape tone), a leap to a dissonance (not an escape tone), and the double neighbor case
- CHANGELOG entry under Unreleased

## Notes

Raised on 2026-11-24 while reviewing BardTheory's dictionary entry for the double neighbor. The two figures share a step followed by a leap of a third the other way; they differ in where the leap lands. A double neighbor leaps to the second neighbor and steps back to the pitch it started from. An escape tone leaps to a stable tone and moves on.

Today the gem recognizes four figures in `lib/head_music/style/guideline/dissonance_figures.rb`: passing tone, neighbor tone, nota cambiata, and double neighbor. `TripleMeterDissonanceTreatment` accepts a passing tone or a neighbor tone on beats 2 and 3 and nothing else, so an escape tone in a triple-meter exercise is marked as an error.

The escape tone is a three-note figure, so it fills a 3:1 bar exactly, as the neighbor tone does: E–F–D over one cantus firmus note, with F dissonant on beat 2 and D consonant on beat 3.

BardTheory's dictionary entry for the escape tone currently says "Fux doesn't discuss it, and it's rare in Palestrina, but later tonal counterpoint allows it on weak beats." That entry and the `triple-meter-guidelines` lesson follow whatever this story decides.

### Open questions

- **Should triple-meter counterpoint (3:1 third species) allow the escape tone?** Rob's position is that the figure is intrinsic to 3:1. If yes, `TripleMeterDissonanceTreatment#recognized_figure?` accepts it, and BardTheory's `triple-meter-guidelines` lesson and escape tone dictionary entry change to match. If no, the figure is introduced in [eighteenth-century-two-voice-counterpoint-guide](eighteenth-century-two-voice-counterpoint-guide.md), which already lists the escape tone among the unaccented figures needing new detection, and this story supplies the predicate that guide uses.
- If triple meter allows it, does 4:1 third species allow it too, or is it specific to 3:1?
- Is the leap limited to a third, or is any leap in the opposite direction an escape tone?
- Must the escape tone fall on a particular beat (beat 2 of 3, so the leap lands inside the bar), or may it sit on the last beat and leap to the next downbeat?

## Implementation Plan

[to be filled in by /stories plan]
