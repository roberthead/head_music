<!--
metadata:
  created_at:   2026-09-25T14:05:53-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-09-26T15:10:42-07:00
-->

# Story: Timeline Expressions: Tempo Words, Gradual Tempo Changes, Fermatas, and Meter Symbols

## Summary

AS a developer using HeadMusic

I WANT a flow's timeline to keep tempo words, gradual tempo changes, fermatas, and common- and cut-time symbols

SO THAT an imported score keeps "Allegro", "rit.", its fermatas, and 𝄴 instead of flattening them to a number and `4/4`, and the `Conductor` keeps time through them

## Background

The timeline holds meter, key, and tempo, and it changes them only at downbeats. Four things the formats say about the timeline are lost:

- **Tempo words.** `Tempo.get("allegro")` answers a quarter note at 120 and forgets the word. ABC writes `Q:"Allegro" 1/4=120`, LilyPond `\tempo "Allegro" 4 = 120`, MusicXML `<words>` beside `<metronome>`, and kern `!!!OMD` for a movement designation.
- **Gradual changes.** Ritardando and accelerando appear in every format, as text in most and as `<sound tempo>` in MusicXML. The timeline only has step changes, so the `Conductor`'s clock time is wrong through a ritardando.
- **Fermatas.** ABC writes `H` or `!fermata!`, LilyPond `\fermata`, MusicXML `<fermata>`, kern `;`, and MEI `<fermata>`, each on a note or rest. ABC and LilyPond raise on them, and kern drops them, although in the Bach chorales fermatas mark the ends of phrases.
- **Meter symbols.** `Meter.common_time` answers `4/4`. ABC writes `M:C` and `M:C|`, MusicXML `symbol="common"` and `symbol="cut"`, and kern `*met(c)`. A score read back shows numerals where the composer wrote a symbol.

A fermata is written on notes and rests, but it belongs to the timeline. It does not change any note's pitch or written value, and the positions after it are unchanged; it changes clock time, and it stops every part at once. So a fermata is a hold on the flow's timeline: a position, the rhythmic span it holds, and how much longer the hold lasts, which the `Conductor` applies. It is not a `Time::TempoEvent`, which is a change that lasts until the next one; after a hold, the tempo is the tempo before it. The written symbols come back out of the hold: a writer puts a fermata on every voice event sounding when it begins.

This story also covers the tempo half of the format gaps found in the 2026-09-25 inventory: ABC `Q:` and LilyPond `\tempo` raise on import, and only kern writes tempo at all.

## Example

```ruby
flow.change_tempo(1, HeadMusic::Rudiment::Tempo.new("quarter", 120, text: "Allegro"))
flow.add_tempo_ramp(from: "12:1", to: "13:1", to_tempo: HeadMusic::Rudiment::Tempo.new("quarter", 80), text: "rit.")
flow.change_meter(1, HeadMusic::Rudiment::Meter.common_time)   # remembers its symbol
flow.add_fermata("4:3", :half)                                   # holds a half note's span at 4:3

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

### Fermatas

- [ ] A flow's timeline can hold a fermata at any position, including in the middle of a bar, spanning a rhythmic value, with a stretch the `Conductor` applies (a default, such as twice the span, when none is given)
- [ ] The `Conductor` lengthens clock time through a fermata by its stretch and leaves every musical position unchanged; clock time converts back to positions across it
- [ ] A fermata leaves the tempo in force unchanged: `tempo_at` answers the same before and after it
- [ ] Overlapping fermatas raise `ArgumentError`
- [ ] The timeline's fermatas are kept through JSON

### Meter symbols

- [ ] A meter can carry a common-time or cut-time symbol, and a meter with a symbol stays equal to its numeric meter for every calculation
- [ ] The symbol is kept through JSON and through the timeline's meter changes

### Formats

- [ ] ABC reads and writes `Q:`, including quoted tempo text, and `M:C` / `M:C|`
- [ ] LilyPond reads and writes `\tempo` with text and a metronome mark, and writes numeric or symbolic time signatures to match the meter
- [ ] MusicXML writes `<metronome>`, `<sound tempo>`, `<words>` for tempo text and ramps, and the time `symbol` attribute
- [ ] kern reads and writes `*met(c)` and `*met(c|)`, and tempo text through `!!!OMD` for the opening tempo
- [ ] ABC (`H`, `!fermata!`), LilyPond (`\fermata`), and kern (`;`) read fermatas written on voice events in any voice into timeline fermatas, and ABC, LilyPond, MusicXML, and kern write each timeline fermata on every voice event sounding when it begins
- [ ] The hand-encoded chorale fixture keeps its fermatas on import, as timeline fermatas at the ends of its phrases
- [ ] Existing schema-5 documents read unchanged
- [ ] Maintains 90%+ test coverage

## Notes

- Timeline changes are downbeat-only (`Timeline.ensure_downbeat!`). Ramps and fermatas both need positions in the middle of a bar, so they probably live beside the timeline's changes rather than among them, and should share that mechanism. Planning should decide.
- Fermatas moved here from [Articulations, Ornaments, Dynamics](../current/articulations-ornaments-fermatas-dynamics.md) (2026-09-26), so the mid-bar timeline mechanism is built once. Until this story lands, the readers drop fermatas.
- Deriving the written symbols normalizes some sources: a part that marked only its last moving note under a held note in another voice, a fermata over a barline, and a general pause all come back as a fermata on every voice event sounding when the hold begins.
- MIDI export (backlog) will want ramps too, since tempo meta events can step through one.
- Chord symbols are also a layer on the timeline, but they tie into harmony analysis and should get a story of their own.

## Open Questions

1. Is a ramp's shape always linear in beats per minute, or should it allow a curve?
2. When fermatas in different voices sit on events that start at different times, such as a bass eighth under a soprano quarter, where does the one hold begin, and what span does it hold?
3. Does tempo text also cover character words that are not tempos ("dolce", "maestoso"), or do those wait for the free-text directions that [Articulations, Ornaments, Dynamics](../current/articulations-ornaments-fermatas-dynamics.md) left out of scope?

## Implementation Plan

[to be filled in by /stories plan]
