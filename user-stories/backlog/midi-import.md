<!--
metadata:
  created_at:   2026-09-24T18:58:30-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-10-15T21:24:00-07:00
-->

# Story: MIDI Import

## Summary

AS a developer using HeadMusic

I WANT to read a Standard MIDI File into a `HeadMusic::Content::Flow`

SO THAT I can analyze music that exists only as MIDI, such as files from online archives and sequenced arrangements

## Background

MIDI records performance, not notation. Importing it means inferring three things the file does not say:

- **Spelling.** Key number 61 could be C♯ or D♭. [Key and Spelling Inference](key-and-spelling-inference.md) does this, and lands before this story.
- **Rhythmic values.** Ticks must be quantized to note values. Notes that cross a barline must be split and tied, and durations that are not a single value must become tied chains. `BarSplitter` already splits notes at barlines for the writers.
- **Voices.** A track, or a channel within a track, may hold several simultaneous lines, which must be separated into voices or chords.

[MIDI Export](midi-export.md) lands earlier. It defines `HeadMusic::MIDI`, the General MIDI program and percussion-key data in the instrument catalog, and an SMF reader in `spec/support`, which this story promotes into the gem.

## Prerequisites

- [MIDI Export](midi-export.md), for the module, the GM data, and the SMF event reader
- [Key and Spelling Inference](key-and-spelling-inference.md), for key finding and spelling

## Example

```ruby
flow = HeadMusic::MIDI.parse(File.binread("invention.mid"))
flow.voices.first.voice_events.first.pitch.to_s # => "C4"
```

## Acceptance Criteria

### Entry point and file

- [ ] `HeadMusic::MIDI.parse(bytes, **options)` returns a `HeadMusic::Content::Flow` from an SMF of format 0 or 1
- [ ] A truncated or malformed file raises `MIDI::ParseError` naming the byte offset. Examples are a missing `MThd`, a chunk that runs past the end, or a bad variable-length quantity
- [ ] Unknown chunk types are skipped, as the SMF specification asks. Running status is read
- [ ] SysEx, controller, pitch-bend, aftertouch, and unrecognized meta events are skipped
- [ ] A format 2 file, which holds independent sequences rather than one piece, raises `MIDI::UnsupportedFeatureError`. So does a file with an SMPTE time division, which has no beat to quantize to

### Timeline

- [ ] Time-signature meta events set the meter and lay out the bars, including changes. A change that does not fall on a barline raises `UnsupportedFeatureError`, since the model would need a short bar in the middle of the piece
- [ ] Tempo meta events become tempo changes, taking the tempo in force at each bar's downbeat. Changes within a bar are skipped until [Timeline Expressions](timeline-expressions.md) can hold gradual ones
- [ ] Key-signature meta events set the key signature and tonal context, including changes
- [ ] When the file has no key signature, or the caller passes `key: :infer`, the key regions come from key finding. Many files carry a default C major they do not mean

### Notes and rhythms

- [ ] Note on and note off pairs become note events, a note on with velocity 0 counts as a note off, and repeated note ons of one key on one channel pair first in, first out
- [ ] A note still sounding at the end of its track ends there
- [ ] Every note is spelled by the speller from the prerequisite, using the key in force
- [ ] Onsets and durations are quantized to a grid, set by the `grid:` option. By default the grid is the coarsest that places every onset and release exactly at the file's resolution, among sixteenths, thirty-seconds, sixty-fourths, and their triplet divisions. When none fits, the default is sixteenths
- [ ] Notes and rests are written as single values where one fits, and as tied chains otherwise. A note that crosses a barline is split and tied
- [ ] Time between notes in a voice becomes rests, and a voice that starts late or ends early is padded, so every voice satisfies `Voice::Continuity`
- [ ] A file whose first note falls before its first full bar starts with a pickup

### Parts and voices

- [ ] In format 1, each track that holds notes becomes a part; a track that holds notes on several channels becomes one part per channel. Format 0 is split by channel
- [ ] A track name meta event becomes the part's player name, and the sequence name the flow's name
- [ ] A program change sets the part's instrument through the GM program data, and a later program change becomes an instrument change at its bar
- [ ] Channel 10 becomes an unpitched part, its key numbers mapped to unpitched sounds through the GM percussion data, or to the generic unpitched sound when a key maps to none
- [ ] Notes in one part that start and end together, after quantizing, become one chord
- [ ] Notes that overlap without forming a chord go to separate voices. Each note joins the voice free at its onset whose last pitch is nearest, and opens a new voice when none is free

### Lyrics

- [ ] Lyric meta events attach syllables to the note they fall on, and a trailing hyphen sets `hyphen_after`

### Round trip and real files

- [ ] A flow written by MIDI Export parses back to the same key numbers, rhythmic values, meter, key signature, tempo, instruments, and lyrics, given the export's tick resolution. Spelling is compared separately: the spec pins every note spelled differently from the written flow
- [ ] With `KERN_CORPUS` pointing at the Bach chorales, every chorale goes through kern import, MIDI export, and MIDI import. The spec records the rate of pitches spelled as the original, and pins it as a floor
- [ ] At least one sequenced MIDI file from a public archive, under a license that allows it, parses end to end and is committed as a fixture
- [ ] Maintains 90%+ test coverage

## Notes

- **Round trips leave out what export performs rather than notates:**
  - Repeats and jumps are played out, so they come back written out.
  - Staccato notes are shortened, so they come back as shorter notes and rests.
  - Grace notes take time from their neighbors, so they come back as short notes.
  - Dynamics become velocities.

  Round-trip specs use flows without these, or compare against `Flow#performance_order`.
- **Follow-up: dynamics from velocity.** Accents and hairpins move velocities off the export's level table, so a reader would invent level changes. A useful version needs its own rules for runs, thresholds, and ramps.
- **Follow-up: live performances.** Human-performed MIDI, unquantized, with rubato and no tempo map, needs beat tracking before quantizing. v1 is scoped to sequenced files.
- **From Key and Spelling Inference** (2026-10-15): voices are separated before spelling, so melodic direction applies; the spelling floor should cite that story's inferred-key chorale figure.
- **Shapes MIDI Export writes** (decided in that story, 2026-10-15): a first bar shorter than the meter that follows is a pickup, which export trims to its first onset, and a tempo should be restated in the meter's beat, since export writes microseconds per quarter.
- The voice separation above is a first fit. Contour- and range-aware separation, which would let the counterpoint guides grade imported polyphony, is a follow-up.

## Decisions

- **The module is `HeadMusic::MIDI`** (decided 2026-10-14), shared with MIDI Export.
- **Key finding and spelling are a separate prerequisite story** (decided 2026-10-14), in `HeadMusic::Analysis`.
- **One part per track and channel, voices separated by first fit, chords for notes that start and end together** (decided 2026-10-14). This settles the earlier questions about voice separation and the default grid.
- **Valid content the model cannot hold is skipped, not raised** (decided 2026-09-26, as policy for every reader). Format 2, SMPTE time division, and a time-signature change within a bar raise, because each leaves no honest flow to build.

## Implementation Plan

[to be filled in by /stories plan]
