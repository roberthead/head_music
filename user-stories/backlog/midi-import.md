<!--
metadata:
  created_at:   2026-09-24T18:58:30-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-09-24T18:58:30-07:00
-->

# Story: MIDI Import

## Summary

AS a developer using HeadMusic

I WANT to read a Standard MIDI File into a `HeadMusic::Content::Flow`

SO THAT I can analyze music that exists only as MIDI, such as performances captured from a keyboard or files from online archives

## Background

MIDI records performance, not notation. Importing it means inferring three things the file does not say:

- **Spelling.** Key number 61 could be C♯ or D♭. The key signature, the surrounding scale degrees, and the melodic direction must choose.
- **Rhythmic values.** Ticks must be quantized to note values. Notes that cross a barline must be split and tied, and durations that are not a single value must become tied chains.
- **Voices.** A track, or a channel within a track, may hold several simultaneous lines that must be separated into voices or chords.

That inference is why this story is separate from, and lower priority than, [MIDI Export](midi-export.md), which should land first and share its event reader and writer vocabulary.

## Example

```ruby
flow = HeadMusic::Notation::MIDI.parse(File.binread("invention.mid"))
flow.voices.first.placements.first.pitch.to_s # => "C4"
```

## Acceptance Criteria

- [ ] `HeadMusic::Notation::MIDI.parse(bytes)` returns a `HeadMusic::Content::Flow` from SMF formats 0 and 1
- [ ] Tempo, time-signature, and key-signature meta events map to the flow's timeline, including changes
- [ ] Note on / note off pairs (including note on with velocity 0) become placements
- [ ] Pitches are spelled from the key signature, falling back to a documented rule when it is absent or ambiguous
- [ ] Onsets and durations are quantized to a grid, with a configurable resolution
- [ ] Notes that cross a barline are split and tied
- [ ] Format 0 files are separated by channel; each track or channel becomes a part
- [ ] Simultaneous notes that start and end together become chords; overlapping notes become separate voices, or raise `UnsupportedFeatureError` if deferred
- [ ] Every flow written by MIDI export parses back to the same pitches and rhythmic values, given that the export's tick resolution matches the grid
- [ ] Truncated or malformed files raise `MIDI::ParseError`
- [ ] Maintains 90%+ test coverage

## Notes

- Human-performed MIDI (unquantized, with rubato and no tempo map) is much harder than sequenced MIDI. Scope v1 to sequenced files, and treat live performances as a follow-up.
- Spelling inference is useful on its own, so consider putting it in `Analysis` where it could serve other callers.
- SysEx, controller, pitch-bend, and aftertouch events are skipped.

## Open Questions

1. Should the quantization grid default to the smallest value that fits the file, or to sixteenths?
2. How much voice separation belongs in v1? One voice per channel with chords is the simplest honest start.

## Implementation Plan

[to be filled in by /stories plan]
