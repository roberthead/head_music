<!--
metadata:
  created_at:   2026-09-25T14:05:52-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-09-25T14:05:52-07:00
-->

# Story: Tuplets and Grace Notes

## Summary

AS a developer or researcher using HeadMusic

I WANT flows to hold tuplets and grace notes

SO THAT I can import the large share of real repertoire that uses them, instead of having the import refuse the whole file

## Background

Every notation format the gem reads expresses tuplets and grace notes, and each reader refuses them today:

| Concept | ABC | LilyPond | MusicXML | kern | MEI |
|---|---|---|---|---|---|
| Tuplet | `(3CDE` | `\tuplet 3/2 { c8 d e }` | `<time-modification>`, `<tuplet>` | `12c 12d 12e` | `<tuplet>` |
| Grace note | `{g}A` | `\grace`, `\acciaccatura`, `\appoggiatura` | `<grace>` | `q`, `Q` | `@grace` |

The model has no place for either. `RhythmicValue` is a unit, dots, and a tied chain, with no tuplet ratio. Kern's reader raises on tuplet durations and drops grace notes, a decision the [kern story](../done/humdrum-kern-import-and-export.md) recorded as waiting on this change to the core duration model. After unsupported expressive markings (see [Marks on Notes](marks-on-notes.md)), tuplets are the most common reason a real file fails to import.

This is the deepest of the five model-gap stories: it changes rhythmic values and position arithmetic, which everything else depends on. It is last in priority because the other four are additive and lower risk.

## Example

```ruby
triplet = HeadMusic::Rudiment::RhythmicValue.get("eighth", tuplet: "3:2")
voice.place("1:1", triplet, "C4")
voice.place("1:1:320", triplet, "D4")   # positions depend on the tick resolution
voice.place("1:2", triplet, "E4")

voice.place("1:3", :quarter, "G4").grace_notes << HeadMusic::Content::GraceNote.new("A4", slashed: true)
```

## Acceptance Criteria

### Tuplets in the model

- [ ] A rhythmic value can carry a tuplet ratio (`3:2`, `5:4`, `6:4`, `2:3`, …), and its total value is scaled by the ratio
- [ ] Positions and durations stay exact for every ratio the formats use; a ratio the tick resolution cannot represent raises `ArgumentError` rather than rounding
- [ ] Tuplet membership is kept: a flow can tell which placements form one tuplet group, so a writer can bracket them and a reader's grouping round-trips
- [ ] A tuplet group that crosses a barline raises in the writers that cannot split it
- [ ] Nested tuplets raise `UnsupportedFeatureError` in v1
- [ ] `Voice::Continuity` and the bar-length checks accept bars filled with tuplets

### Grace notes in the model

- [ ] A placement can carry grace notes that come before it, each with pitches, a notated rhythmic value, and a slashed (acciaccatura) or unslashed (appoggiatura) flag
- [ ] Grace notes take no time: they do not move positions, fill bars, or count toward continuity
- [ ] Melodic and harmonic analysis ignore grace notes by default (see Open Questions)

### Serialization and formats

- [ ] Flow JSON writes tuplet ratios, tuplet groups, and grace notes, within schema 4 as optional keys; existing schema-4 documents read unchanged
- [ ] ABC, LilyPond, and kern read tuplets and grace notes that they refuse or drop today
- [ ] ABC, LilyPond, MusicXML, and kern write them
- [ ] Each format round-trips a flow that has triplets, a quintuplet, and grace notes before a downbeat
- [ ] Maintains 90%+ test coverage

## Notes

- The format sections are large. If planning finds them too big for one story, keep the model, JSON, and one reader and writer here, and move the rest into a follow-up story.
- `BarSplitter` and `DottedDuration.rhythmic_value_for` assume binary fractions. Both need a rule for tuplet fractions.
- The Style guides are built on species counterpoint, which has no tuplets or grace notes, so no guideline needs to change. A later story could teach melodic guidelines about ornamental grace notes.
- MIDI export (backlog) would sound grace notes by borrowing time from the note before or after them. That choice belongs to that story.

## Open Questions

1. Is a tuplet a property of each rhythmic value, or a group object that owns its placements? Formats disagree: kern puts it on each duration, while ABC, LilyPond, and MusicXML bracket a group.
2. Should analysis be able to include grace notes when a caller asks, for example when checking an ornamented melody?

## Implementation Plan

[to be filled in by /stories plan]
