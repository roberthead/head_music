<!--
metadata:
  created_at:   2026-09-24T18:58:30-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-09-24T18:58:30-07:00
-->

# Story: MIDI Export

## Summary

AS a developer using HeadMusic

I WANT to render a `HeadMusic::Content::Flow` as a Standard MIDI File

SO THAT I can hear what I have composed or generated, and hand it to DAWs, sequencers, and synthesizers

## Background

A Standard MIDI File (SMF) is a binary format of timed events: note on and note off with a key number and velocity, plus meta events for tempo, time signature, key signature, and track name. Unlike the notation formats, MIDI records performance, not spelling: C♯ and D♭ are the same key number, and durations are ticks rather than note values.

`HeadMusic::Time` already has what export needs: the `Conductor`, `TempoMap`, and `MeterMap` convert musical positions to clock time, and pitches already know their MIDI numbers. Export is mostly the job of walking placements and writing the bytes.

## Example

```ruby
bytes = flow.to_midi
File.binwrite("exercise.mid", bytes)
```

## Acceptance Criteria

- [ ] `HeadMusic::Notation::MIDI.render(flow)` and `Flow#to_midi` return a binary String holding a valid SMF
- [ ] Format 1 is written: a conductor track carrying tempo, time-signature, and key-signature meta events, then one track per voice (or per part — see Open Questions)
- [ ] Each pitched placement emits note on / note off at the correct tick; chords emit one note per pitch; rests emit nothing
- [ ] Tied notes sound as one note, not re-articulated
- [ ] Mid-piece tempo, meter, and key changes emit meta events at the correct ticks
- [ ] Track names come from the part or voice role; the flow's name becomes the sequence name
- [ ] A part with an instrument emits a General MIDI program change when the instrument maps to one; unpitched percussion goes to channel 10 if the model carries it
- [ ] A transposing instrument's notes sound at concert pitch
- [ ] Tick resolution (ticks per quarter note) is chosen so every rhythmic value the flow uses lands on a whole tick
- [ ] The output opens in at least one real MIDI tool (e.g. MuseScore, GarageBand, or `timidity`) without errors
- [ ] Specs decode the bytes and assert on events, not on raw byte strings alone
- [ ] Maintains 90%+ test coverage

## Notes

- Keep it dependency-free: SMF is simple enough to write with `Array#pack`.
- Velocity is a constant default in v1. Dynamics, articulations, and swing are follow-ups.
- `MIDI` might belong beside `Notation` rather than inside it, since MIDI is not notation. Decide during planning; `HeadMusic::Notation::MIDI` is only a placeholder here.
- [MIDI Import](midi-import.md) is a separate, lower-priority story.

## Open Questions

1. One track per voice or one per part? A part with two voices on one instrument usually wants one track and one channel.
2. Should the render take options for velocity, channel assignment, or program override?

## Implementation Plan

[to be filled in by /stories plan]
