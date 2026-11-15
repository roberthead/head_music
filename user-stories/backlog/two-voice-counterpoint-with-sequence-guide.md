<!--
metadata:
  created_at:   2026-11-15T15:20:00-05:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-11-15T15:20:00-05:00
-->

# Story: Two-Voice Counterpoint with Sequence Guide

## Summary

AS a consumer of the gem grading sequential writing (the sequence exercise BardTheory's Unit 10 story is waiting on, and later the episodes in its invention units)
I WANT the gem to find sequences in a passage, and a guide that grades a two-voice passage that must contain one
SO THAT a student's sequence is checked by analysis: is the pattern actually restated, at a consistent interval, enough times, in both voices

## Acceptance Criteria

### Sequence detection (Analysis)

- A new analysis class (working name `HeadMusic::Analysis::Sequence`) finds sequences within a flow. Each one reports:
  - the model (the first statement): voice(s), start position, and duration
  - each later statement and its transposition from the one before it
  - the step of the sequence, when the statements move by a consistent interval (for example, down a second or up a fourth)
  - whether it is diatonic (consistent in steps) or real (also consistent in semitones), and whether it leaves the key
  - how closely each statement matches the model, so callers can set their own strictness
- **Melodic sequence:** one voice restates its own pattern immediately, at a new pitch level
- **Contrapuntal sequence:** both voices restate their patterns together over the same span, by the same transposition, so the intervals between the voices recur (for example, a chain of 7–6 suspensions, or parallel tenths over a descending bass). The result says whether a sequence is melodic in one voice or contrapuntal across voices
- A sequence needs a model plus at least one restatement to be reported. The guideline decides how many it requires
- Statements must follow one another directly. A pattern repeated after unrelated material is imitation or recurrence, not a sequence
- A last statement that is cut short or changed to make a cadence still counts, at a lower match score
- Detected against real repertoire: episodes from at least three Bach two-part inventions, read from kern or MusicXML fixtures through the gem's own readers, with the statements and intervals the scores show

### Guideline and guide

- A guideline that requires a sequence: at least a model and two restatements (three statements in all), contrapuntal across both voices. A melodic-only sequence, a two-statement sequence, or a loose match lowers the grade in proportion; nothing disqualifies
- A secondary guideline, `AvoidOverlongSequences` (working name), that lowers the grade when a sequence runs past a set number of statements, following the textbook warning against mechanical repetition. The limit and its source are pinned in the spec
- A registered composite guide, `two_voice_counterpoint_with_sequence`, that is the free two-voice counterpoint guide plus the sequence guideline as a primary item
- Display names and instructions in every locale (en, en_GB, de, es, fr, it, ru)
- CHANGELOG entry under Unreleased

## Notes

### Depends on

- [free-two-voice-counterpoint-guide](free-two-voice-counterpoint-guide.md): this guide adds to it
- [two-voice-counterpoint-with-imitation-guide](two-voice-counterpoint-with-imitation-guide.md): its detector compares a passage against another passage at any transposition. A melodic sequence is a voice imitating itself right away at a new level, so sequence detection should build on that matching rather than build a second copy of it. If the imitation story ships its detector without letting a voice follow itself, this story adds that

### What sequence detection adds to imitation matching

- Statements follow one another directly, with no gap and no overlap
- The transposition is consistent across three or more statements: the step of the sequence
- Matching runs across voices at once: in a contrapuntal sequence each voice's segment matches its own model at the same transposition and over the same span
- Finding the model's length: the same passage could be read as a two-beat model stated four times or a one-bar model stated twice. The detector needs a rule for this, such as preferring the shortest model that covers the passage

### Scope

- Two voices for the guide. The detector should accept any number of voices, since three-voice episodes come up in BardTheory Unit 13
- Harmonic sequences named by root motion (descending fifths, ascending 5–6) need Roman-numeral or chord-root analysis of the passage. Reporting root motion is out of scope unless planning finds a cheap way to get it from `Analysis::Sonority`; the contrapuntal pattern stands in for it here

### Open questions

- Is a sequence of two statements enough for the detector to report? (The guideline asks for three either way.)
- How many statements count as overlong? Textbooks commonly warn against going past three, but the source needs to be named.
- Does a sequence have to be contrapuntal for full credit, or does a melodic sequence over a free bass count?
- Does a real sequence that changes key earn anything beyond a diatonic one, or is it just reported?

## Implementation Plan

[to be filled in by /stories plan]
