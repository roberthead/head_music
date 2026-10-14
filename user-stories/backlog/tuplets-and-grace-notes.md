<!--
metadata:
  created_at:   2026-09-25T14:05:52-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-10-14T15:16:39-07:00
-->

# Story: Tuplets and Grace Notes

## Summary

AS a developer or researcher using HeadMusic

I WANT flows to hold tuplets and grace notes

SO THAT I can import the large share of real repertoire that uses them, instead of having the import refuse the whole file

## Background

Every notation format the gem reads or will read expresses tuplets and grace notes:

| Concept | ABC | LilyPond | MusicXML | kern | MEI |
|---|---|---|---|---|---|
| Tuplet | `(3CDE`, `(p:q:r` | `\tuplet 3/2 { c8 d e }`, `\times 2/3` | `<time-modification>`, `<tuplet>` | `12c 12d 12e`, `3%2c` | `<tuplet>`, `<tupletSpan>` |
| Grace note | `{g}A`, `{/g}A` | `\grace`, `\acciaccatura`, `\appoggiatura`, `\slashedGrace` | `<grace slash>` | `q`, `Q` | `@grace` |

The readers handle them badly today:

- ABC's `LineScanner` refuses tuplets and grace notes.
- LilyPond's `MusicReader` raises on `\tuplet` and the grace commands.
- kern's `DurationReader` raises `UnsupportedFeatureError` on tuplet durations. Its `TokenReader` drops grace notes and moves any slur on one to the note it leads to.

Tuplets are now the most common reason a real file fails to import.

The model has no place for either. `RhythmicValue` is a unit, dots, and a tied chain, with no tuplet ratio. A `NoteEvent` holds its sounds, markings, and syllables, but no grace notes. Positions count 960 ticks to a quarter note and 240 subticks to a tick, which is 230,400 subticks (2¹⁰·3²·5²) to a quarter. Ratios built from 2, 3, and 5, such as triplets, sextuplets, and quintuplets, land on whole subticks. Septuplets and other ratios with a prime factor above 5 do not.

This story was last of the model-gap stories. It now comes first among the format stories, as the prerequisite of [MusicXML Import](musicxml-import.md). That makes it also a prerequisite of [MIDI Export](midi-export.md), [MEI Export](mei-export.md), and [MEI Import](mei-import.md), which come after MusicXML Import and rely on it.

## Example

```ruby
triplet = HeadMusic::Rudiment::RhythmicValue.get("eighth", tuplet: "3:2")
voice.place("1:1", triplet, "C4")
voice.place("1:1:320", triplet, "D4")
voice.place("1:2", triplet, "E4")
voice.group_tuplet(from: "1:1", to: "1:2")

note = voice.place("1:3", :quarter, "G4")
note.add_grace_note("A4", :sixteenth, slashed: true)
```

The method names above are a sketch, to be settled in planning.

## Acceptance Criteria

### Tuplets in the model

- [ ] A rhythmic value can carry a tuplet ratio, written as actual to normal (`3:2`, `5:4`, `6:4`, `7:4`, `2:3`, …). Its total value is its plain value times normal over actual
- [ ] `RhythmicValue#name` and `#to_s` name the ratio (for example "triplet eighth", "5:4 sixteenth"), and two values are equal only when their ratios are equal too
- [ ] A voice holds tuplet groups, each naming a ratio, a written unit for its bracket, and the voice events it brackets. A group's events must be consecutive, carry its ratio, and fill its span exactly; `ArgumentError` names the group otherwise
- [ ] A group may mix values under one ratio, such as a quarter and an eighth under 3:2, and may hold rests and chords
- [ ] A value with a ratio but no group is allowed. Writers that need a bracket write one for each run of such values
- [ ] Ratios that land on whole subticks keep exact positions and durations
- [ ] Ratios that do not land on whole subticks, such as septuplets, are rounded. Each onset in a group falls on the subtick nearest its exact place, measured from the group's start, so the group's span stays exact and rounding never accumulates. A lone value with such a ratio rounds its duration to the nearest subtick. Every note keeps its written value and ratio, so writers write what was read
- [ ] `Voice::Continuity` and the bar-length checks accept bars filled with tuplets, rounded or not
- [ ] A tuplet note that crosses a barline is split by `BarSplitter` into tied notes of the same ratio. A writer whose format cannot bracket across a barline raises `RenderError` naming the group
- [ ] Nested tuplets raise `ArgumentError` in the model, and `UnsupportedFeatureError` in readers

### Grace notes in the model

- [ ] A note event can carry grace notes that come before it. Each grace note has one or more pitches, a written rhythmic value, and a slashed (acciaccatura) or unslashed (appoggiatura) flag
- [ ] Grace notes take no time: they do not move positions, fill bars, or count toward continuity
- [ ] Grace notes may carry articulations and ties to their main note, and a slur may begin on the first of them. The kern reader then keeps a slur on its grace note rather than moving it to the main note
- [ ] A rest event refuses grace notes with `ArgumentError`, as it refuses markings
- [ ] Melodic and harmonic analysis, and every guide, ignore grace notes

### Serialization

- [ ] Flow JSON writes tuplet ratios, tuplet groups, and grace notes as optional keys within schema 5, and existing schema-5 documents read unchanged
- [ ] A bad group, such as one whose events do not fill its span, raises naming its path, such as `voices[0].tuplets[2]`

### Readers

- [ ] ABC reads `(3`, `(p:q:r`, and the meter-dependent default for `(n`, as tuplet groups. It reads `{…}` as grace notes before the next note, and `{/…}` as slashed ones
- [ ] LilyPond reads `\tuplet n/d { … }` as tuplet groups, including the span form `\tuplet 3/2 4 { … }`, which starts a new group each quarter, and the older `\times d/n { … }`. It reads `\grace`, `\acciaccatura`, `\appoggiatura`, and `\slashedGrace` as grace notes
- [ ] kern reads non-power-of-two reciprocals (`3`, `6`, `12`, `20`, `24`, …) and `%` durations as tuplet values. It infers groups by gathering consecutive values of one ratio until they fill a span of a plain note value, and reads `q` as slashed grace notes and `Q` as unslashed ones
- [ ] LilyPond `\afterGrace` and grace notes before a rest are skipped, as the model holds grace notes only before a note
- [ ] Every file that imports today still imports, and the tuplet and grace fixtures that raised now import

### Writers

- [ ] ABC writes `(p:q:r` groups, or the short `(3` form where it means the same thing, and `{…}` and `{/…}` grace notes
- [ ] LilyPond writes `\tuplet n/d { … }` groups, and `\acciaccatura`, `\appoggiatura`, or `\grace` before the main note, as the flags call for
- [ ] kern writes tuplet values as reciprocals, or `%` where no integer reciprocal exists, and grace notes as `q` and `Q` tokens on rows of their own
- [ ] MusicXML writes `<time-modification>` on every tuplet note, `<tuplet type="start">` and `<tuplet type="stop">` on each group's ends, and `<grace>` with `slash="yes"` for acciaccaturas. `<divisions>` are computed from written values and ratios, so they are exact for septuplets too
- [ ] A written duration for a tuplet value comes from its value and ratio, never from its rounded ticks. `DottedDuration.rhythmic_value_for` and the duration writers get a rule for this

### Tests

- [ ] Each format round-trips a flow with triplets, a sextuplet, a quintuplet, a septuplet, a group mixing values, a tuplet note crossing a barline (in the formats that allow it), and grace notes of both kinds before a downbeat
- [ ] A seeded random generator in `spec/support` round-trips 100 seeds per format, naming the seed on failure
- [ ] Every LilyPond output compiles under lilypond 2.26 without warnings
- [ ] Maintains 90%+ test coverage

## Notes

- **Build order.** This follows the shape that worked for Place Dynamics Where No Note Starts and Hairpins. First a shared base on the story branch: the model, JSON, `BarSplitter`, duration-writer rules, fixtures, and the seeded generator. Then one worktree per format, built from that base commit.
- MusicXML reading belongs to [MusicXML Import](musicxml-import.md), and MEI to its two stories. Each takes this model as given.
- [MIDI Export](midi-export.md) sounds grace notes by taking time from the note they precede, and its tick resolution allows for tuplets.
- **Follow-up: nested tuplets.** They are rare outside twentieth-century repertoire, and holding them would mean groups within groups in every bracket writer. They raise because skipping one would leave its bar short.
- **Follow-up: grace notes after a note.** LilyPond's `\afterGrace` and trill terminations would need grace notes held after a note. They are skipped until a caller needs them.
- **Follow-up: grace notes in analysis.** No guide needs them. A later story could teach melodic guidelines about ornamental grace notes, and add an option to include them then.

## Decisions

- **A tuplet is a ratio on each value, plus a group on the voice** (decided 2026-10-14). The ratio keeps durations and positions simple arithmetic. The group says which events one bracket holds, which the bracket formats need, and which tells two triplets from one sextuplet. kern, which writes no brackets, has its groups inferred on reading.
- **Ratios that do not divide the subtick grid are rounded to the nearest subtick** (decided 2026-10-14). This reverses the earlier plan to raise `ArgumentError`. Each onset rounds from its group's start, so the group stays exact, and the written value and ratio are kept for writers.
- **Analysis ignores grace notes, with no option yet** (decided 2026-10-14). No caller needs one, and an option with no caller is guesswork about its shape.
- **The format work stays in this story** (decided 2026-10-14). The earlier note offered to split the formats out, but MusicXML Import needs the MusicXML writer's half, and every reader that refuses tuplets today is the problem this story solves.
- **This story is the prerequisite of MusicXML Import** (decided 2026-10-14), so it moves to the front of the format work.

## Implementation Plan

[to be filled in by /stories plan]
