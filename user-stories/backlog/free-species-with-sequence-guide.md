<!--
metadata:
  created_at:   2026-11-15T15:20:00-05:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-11-15T19:12:18-05:00
-->

# Story: Free Species with Sequence Guide

## Summary

AS a consumer of the gem grading sequential writing (the sequence exercise BardTheory's Unit 10 story is waiting on, and later the episodes in its invention units)
I WANT the gem to find sequences in a passage, and a guide that grades a two-voice passage that must contain one
SO THAT a student's sequence is checked by analysis: is the pattern actually restated, at a consistent interval, in the way the exercise asked for

## Acceptance Criteria

### Sequence detection (Analysis)

- A new analysis class (working name `HeadMusic::Analysis::Sequence`) finds sequences within a flow. Each one reports:
  - the model (the first statement): voice(s), start position, and duration
  - each later statement and its transposition from the one before it
  - the rhythmic offset: the time from one statement's start to the next
  - the step of the sequence, when the statements move by a consistent interval (for example, down a second or up a fourth)
  - real or free: whether each statement copies the model's intervals exactly, by semitones as well as by steps (real), or only by scale steps or with changes (free)
  - same key or transposed: whether the sequence stays in the key or leads out of it
  - how closely each statement matches the model, so callers can set their own strictness
- A model and one restatement, two statements in all, is enough to report a sequence
- **Melodic sequence:** one voice restates its own pattern immediately, at a new pitch level
- **Contrapuntal sequence:** both voices restate their patterns together over the same span, by the same transposition, so the intervals between the voices recur (for example, a chain of 7–6 suspensions, or parallel tenths over a descending bass). The result says whether a sequence is melodic in one voice or contrapuntal across voices
- Statements must follow one another directly. A pattern repeated after unrelated material is imitation or recurrence, not a sequence
- A last statement that is cut short or changed to make a cadence still counts, at a lower match score
- Detected against real repertoire: episodes from at least three Bach two-part inventions, read from kern or MusicXML fixtures through the gem's own readers, with the statements and intervals the scores show

### Guideline and guide

- A guideline that requires a sequence, configured through `.with(...)` the way `MinimumNotes.with(3)` and `ContourMelody.with(contour:)` are:
  - `statements:` the minimum number of statements (default 3: a model and two restatements)
  - `offset:` the rhythmic offset between statements (for example, one bar or half a bar), or any
  - `kind:` `:real`, `:free`, or any
  - `transposition:` the step of the sequence (for example, down a second), or any
  - Each setting left unset accepts anything. A sequence that falls short of a setting lowers the grade in proportion to how far it misses; nothing disqualifies
- A melodic sequence in one voice over a free bass earns full credit. A contrapuntal sequence is not required
- A secondary guideline, `AvoidOverlongSequences` (working name), lowers the grade from the fourth consecutive statement on. Its spec cites Kennan (see Sources) for the limit of three
- A registered composite guide, `free_species_with_sequence`, that is the free species guide plus the sequence guideline as a primary item. The guide passes its configuration through to the guideline, so an exercise can ask for, say, a real sequence down a second at one-bar offsets
- Display names and instructions in every locale (en, en_GB, de, es, fr, it, ru)
- CHANGELOG entry under Unreleased

## Notes

### Depends on

- [free-species-guide](../current/free-species-guide.md): this guide adds to it
- [free-species-with-imitation-guide](free-species-with-imitation-guide.md): its detector compares a passage against another passage at any transposition. A melodic sequence is a voice imitating itself right away at a new level, so sequence detection should build on that matching rather than build a second copy of it. If the imitation story ships its detector without letting a voice follow itself, this story adds that

### What sequence detection adds to imitation matching

- Statements follow one another directly, with no gap and no overlap
- The transposition is consistent across the statements: the step of the sequence
- Matching runs across voices at once: in a contrapuntal sequence each voice's segment matches its own model at the same transposition and over the same span
- Finding the model's length: the same passage could be read as a two-beat model stated four times or a one-bar model stated twice. The detector needs a rule for this, such as preferring the shortest model that covers the passage. The answer decides whether a passage trips the overlong guideline, so the specs must pin it

### Configuration precedent

`Guides::ContourMelody.with(contour:, minimum_melodic_intervals:)` is a configured guide with named presets in `Guide`'s registry (`arch_contour_melody`, …). This guide can follow that pattern: the registered key is the unconfigured guide, and an exercise that wants a specific sequence configures it, or registers a preset if one turns out to be common.

### Scope

- Two voices for the guide. The detector should accept any number of voices, since three-voice episodes come up in BardTheory Unit 13
- Harmonic sequences named by root motion (descending fifths, ascending 5–6) need chord-root analysis of the passage. Reporting root motion is out of scope unless planning finds a cheap way to get it from `Analysis::Sonority`; the contrapuntal pattern stands in for it here

### Sources

- **Kent Kennan, *Counterpoint: Based on Eighteenth-Century Practice*, 3rd ed., ch. "The Single Melodic Line":** "too many consecutive appearances of a pattern in a sequence make for a monotonous and over-obvious effect. As a rule, three may be considered a safe limit." "Appearances" counts the model, so three statements is the limit. Checked against the archive.org full text (`KentKennanCounterpoint`). The same passage adds that sequence can justify an unusual melodic feature, but not one that is actually objectionable.
- **Aldwell & Schachter, *Harmony and Voice Leading*** (as summarized in a SFCM course supplement, not checked against the book): three iterations is the usual maximum unless the pattern is very short and simple. That exception is a reason to make the limit configurable later; not this story's scope.
- **Horton, Byrne & Ritchey, *Harmony Through Melody*** (secondary, not checked): repetition of a melodic figure should stop at the third statement.
- **Salzer & Schachter, *Counterpoint in Composition*:** a sequence happens within a single part and imitation between parts (printed p. 352, beside Example 9-59). They have the student avoid sequences in species exercises (p. 8 for the cantus firmus; p. 353 for combined species), and call a chain of suspensions "the closest permissible approximation to the sequence in species counterpoint" (fourth species, p. 83). So a free-counterpoint guide that rewards sequences departs from the species guides on purpose, and the guide's instruction text should say so. A matching `AvoidSequences` guideline for the species guides is a possible follow-up.

## Implementation Plan

[to be filled in by /stories plan]
