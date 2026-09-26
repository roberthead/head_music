<!--
metadata:
  created_at:   2026-09-25T14:05:53-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-09-25T14:05:53-07:00
-->

# Story: Timeline Expressions: Tempo Words, Gradual Tempo Changes, and Meter Symbols

## Summary

AS a developer using HeadMusic

I WANT a flow's timeline to keep tempo words, gradual tempo changes, and common- and cut-time symbols

SO THAT an imported score keeps "Allegro", "rit.", and 𝄴 instead of flattening them to a number and `4/4`

## Background

The timeline holds meter, key, and tempo, and it changes them only at downbeats. Three things the formats say about the timeline are lost:

- **Tempo words.** `Tempo.get("allegro")` answers a quarter note at 120 and forgets the word. ABC writes `Q:"Allegro" 1/4=120`, LilyPond `\tempo "Allegro" 4 = 120`, MusicXML `<words>` beside `<metronome>`, and kern `!!!OMD` for a movement designation.
- **Gradual changes.** Ritardando and accelerando appear in every format, as text in most and as `<sound tempo>` in MusicXML. The timeline only has step changes, so the `Conductor`'s clock time is wrong through a ritardando.
- **Meter symbols.** `Meter.common_time` answers `4/4`. ABC writes `M:C` and `M:C|`, MusicXML `symbol="common"` and `symbol="cut"`, and kern `*met(c)`. A score read back shows numerals where the composer wrote a symbol.

This story also covers the tempo half of the format gaps found in the 2026-09-25 inventory: ABC `Q:` and LilyPond `\tempo` raise on import, and only kern writes tempo at all.

## Example

```ruby
flow.change_tempo(1, HeadMusic::Rudiment::Tempo.new("quarter", 120, text: "Allegro"))
flow.add_tempo_ramp(from: "12:1", to: "13:1", to_tempo: HeadMusic::Rudiment::Tempo.new("quarter", 80), text: "rit.")
flow.change_meter(1, HeadMusic::Rudiment::Meter.common_time)   # remembers its symbol

flow.tempo_at(1).text # => "Allegro"
flow.meter.symbol     # => :common
```

## Acceptance Criteria

### Tempo words

- [ ] A tempo can carry text, with or without a metronome mark, and keeps it through JSON
- [ ] A tempo with text and no number still answers a beats-per-minute value, from the named defaults `Tempo` already has, so the `Conductor` can run; the flow records that the number was not written
- [ ] `Tempo.get("allegro")` keeps the word as its text

### Gradual tempo changes

- [ ] A flow can hold a tempo ramp from one position to another toward a target tempo, with optional text ("rit.", "accel.", "rall.")
- [ ] The `Conductor` converts positions to clock time through a ramp by interpolating the tempo, and back from clock time to positions
- [ ] "a tempo" (restoring the tempo in force before the ramp) can be expressed and round-trips
- [ ] Overlapping ramps raise `ArgumentError`

### Meter symbols

- [ ] A meter can carry a common-time or cut-time symbol, and a meter with a symbol stays equal to its numeric meter for every calculation
- [ ] The symbol is kept through JSON and through the timeline's meter changes

### Formats

- [ ] ABC reads and writes `Q:`, including quoted tempo text, and `M:C` / `M:C|`
- [ ] LilyPond reads and writes `\tempo` with text and a metronome mark, and writes numeric or symbolic time signatures to match the meter
- [ ] MusicXML writes `<metronome>`, `<sound tempo>`, `<words>` for tempo text and ramps, and the time `symbol` attribute
- [ ] kern reads and writes `*met(c)` and `*met(c|)`, and tempo text through `!!!OMD` for the opening tempo
- [ ] Existing schema-4 documents read unchanged
- [ ] Maintains 90%+ test coverage

## Notes

- Timeline changes are downbeat-only (`Timeline.ensure_downbeat!`). A ramp needs positions in the middle of a bar, so it probably lives beside the timeline's events rather than as one of them. Planning should decide.
- MIDI export (backlog) will want ramps too, since tempo meta events can step through one.
- Chord symbols are also a layer on the timeline, but they tie into harmony analysis and should get a story of their own.

## Open Questions

1. Is a ramp's shape always linear in beats per minute, or should it allow a curve?
2. Does tempo text also cover character words that are not tempos ("dolce", "maestoso"), or do those belong to text directions in [Marks on Notes](../current/marks-on-notes.md)?

## Implementation Plan

[to be filled in by /stories plan]
