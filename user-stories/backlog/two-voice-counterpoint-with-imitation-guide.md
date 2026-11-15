<!--
metadata:
  created_at:   2026-11-15T14:57:30-05:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-11-15T15:52:47-05:00
-->

# Story: Two-Voice Counterpoint with Imitation Guide

## Summary

AS a consumer of the gem grading imitative writing (BardTheory's Unit 10 `imitative-opening` exercise, and later its invention units)
I WANT the gem to find where one voice imitates another, and a guide that grades a two-voice passage that opens in imitation
SO THAT imitation is judged by analysis and not just stated in the exercise's instructions, and the same detection can later support inventions, canons, and sequences

## Acceptance Criteria

### Imitation detection (Analysis)

- A new analysis class (working name `HeadMusic::Analysis::Imitation`) finds imitations within a flow. Each one reports:
  - the leading voice and its passage (start position, notes)
  - the following voice and its passage
  - the time delay between the two entries
  - the transposition, as a diatonic interval (and whether it is also exact by semitones, that is, real rather than tonal)
  - how the passage was changed, if at all: none, inversion, augmentation, diminution, or retrograde, with each that is supported pinned by a spec
  - how closely the follower matches: the share of intervals and of durations that match, so callers can set their own strictness
- Detection works at any transposition and any delay. Restricting to the unison, octave, fifth, and fourth is a job for the guideline, not the detector
- Detection works between any two voices of a flow, not only a two-voice flow
- A follower that changes the opening interval (a tonal answer) or the ending still counts as imitation, at a lower match score, as long as the rest of the passage matches
- A minimum passage length (notes and/or duration) keeps a single repeated interval or scale fragment from counting as imitation. The default is chosen and justified in the specs
- Detected against real repertoire: at least three Bach two-part inventions read from kern or MusicXML fixtures through the gem's own readers, with the subject entries, delays, and intervals the scores show

### Guideline and guide

- A guideline that grades an opening in imitation: the second voice enters with the first voice's opening material after a delay, while the first voice keeps going. A loose imitation lowers the grade in proportion to its match score; it never disqualifies
- The guideline is configured through `.with(...)`, with the same three settings as the sequence guideline in [two-voice-counterpoint-with-sequence-guide](two-voice-counterpoint-with-sequence-guide.md), so an exercise can ask for, say, real imitation at the fifth after one bar:
  - `offset:` the rhythmic offset, meaning the delay between the two entries (for example, one bar or half a bar), or any
  - `kind:` `:real` (the follower copies the leader's intervals exactly, by semitones as well as by steps), `:free` (a tonal answer, or changes in interval or rhythm), or any
  - `transposition:` the interval of imitation, or a list of them. The default is the unison, octave, fifth, and fourth; setting it wider (for example, imitation at the second for a canon exercise) is allowed
  - An imitation that misses a setting lowers the grade in proportion to how far it misses
- A registered composite guide, `two_voice_counterpoint_with_imitation`, that is the free two-voice counterpoint guide plus the imitation guideline as a primary item. The guide passes its configuration through to the guideline, following the precedent of `Guides::ContourMelody.with(contour:)` and its registered presets
- Display names and instructions in every locale (en, en_GB, de, es, fr, it, ru)
- CHANGELOG entry under Unreleased

## Notes

### Depends on

[free-two-voice-counterpoint-guide](free-two-voice-counterpoint-guide.md). This guide adds a primary item to that one, so the free guide has to exist first. The detector does not depend on it and can be built in parallel.

### Why build general detection now

BardTheory's exercise asks only for an imitative opening, but the backlog has more uses for it:

- Unit 11 (two-part inventions): finding subject and countersubject entries
- Unit 13 (sinfonias): three-voice expositions
- Sequences: a voice imitating itself at a new pitch level. If the detector accepts the same voice as leader and follower, sequence detection comes almost for free. BardTheory's Unit 10 story mentions a sequence exercise "once the gem can recognize a sequence"
- Canon: imitation that continues through the whole passage

The detector should not take on BardTheory's limits (two voices, the opening only, four intervals).

### Approach ideas, not decisions

- Compare voices as sequences of (diatonic melodic interval, duration ratio) pairs, not as pitches, so transposition doesn't matter. Use steps for diatonic imitation and semitones to tell real from tonal.
- Inversion negates the interval direction. Augmentation and diminution scale the duration ratios by a constant.
- Rests and ties in the leader's passage need a defined treatment before matching.

### Open questions

- Retrograde is rare in practice and much harder to hear. Include it, or defer it with a reason?
- Should the result report every overlapping match or only the longest one per entry? Inventions repeat the subject constantly, so this decides how noisy the output is.
- How long must the first voice play alone before the second enters, for the guideline? Bar-aligned only, or any beat?
- Where should "the opening" end? The first N bars, or the first imitation found?

## Implementation Plan

[to be filled in by /stories plan]
