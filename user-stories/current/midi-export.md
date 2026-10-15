<!--
metadata:
  created_at:   2026-09-24T18:58:30-07:00
  activated_at: 2026-10-15T11:05:36-07:00
  planned_at:
  finished_at:
  updated_at:   2026-10-15T11:05:36-07:00
-->

# Story: MIDI Export

## Summary

AS a developer using HeadMusic

I WANT to render a `HeadMusic::Content::Flow` as a Standard MIDI File

SO THAT I can hear what I have composed or generated, and hand it to DAWs, sequencers, and synthesizers

## Background

A Standard MIDI File (SMF) is a binary format of timed events. It has note on and note off with a key number and velocity, and meta events for tempo, time signature, key signature, track names, and lyrics. MIDI records performance, not spelling: C♯ and D♭ are the same key number, and durations are ticks rather than note values.

The model now holds most of what a performance needs:

- **Pitch and time.** `Pitch#midi_note_number`, the timeline's meter, key, and tempo changes, and `HeadMusic::Time` for positions.
- **Order of play.** `Flow#performance_order` unfolds repeats, endings, D.C., and D.S. into the bars as played.
- **Loudness.** `Voice#dynamic_at` answers the dynamic level in force at a position from the voice's and the part's dynamic events. Note dynamics (*sf*, *sfz*, *rfz*, *fp*), articulations, and hairpins are held too.
- **Instruments.** Parts have instruments, with mid-piece instrument changes and sounding transpositions. Unpitched sounds name their instrument.

Two things are missing. The instrument catalog has no General MIDI program numbers, and unpitched instruments have no GM percussion key numbers. This story adds both.

## Example

```ruby
bytes = flow.to_midi
File.binwrite("exercise.mid", bytes)
```

## Acceptance Criteria

### Entry point and file

- [ ] `HeadMusic::MIDI.render(flow, **options)` and `Flow#to_midi` return a binary `String` holding a format 1 SMF
- [ ] Track 0 is the conductor track. It holds the sequence name (from the flow's name), and the tempo, time-signature, and key-signature meta events
- [ ] Each part gets one track and one channel, with its voices merged into that track; the track name comes from the part's player name, or else its instrument's name
- [ ] Pitched parts take channels 1–9 and 11–16 in score order. A flow with more than fifteen pitched parts raises `MIDI::RenderError` naming the count
- [ ] Ticks per quarter note are the smallest number at which every onset and duration the flow uses, tuplets included, lands on a whole tick. This is computed from written values and ratios, so a septuplet is exact in MIDI though the model rounds it. When no number up to 32767 fits, the writer uses 960 and rounds each note to the nearest tick
- [ ] The writer raises `RenderError` for an empty flow, before writing any bytes

### Notes

- [ ] Each pitched note event writes note on and note off at its ticks, and a chord writes one per pitch; rests write nothing
- [ ] Tied notes sound as one note, not re-struck
- [ ] Two voices of one part that hold the same key number at once sound as one note, from the first onset to the last release, since one channel cannot hold a key twice
- [ ] Grace notes take their time from a neighbor. An acciaccatura sounds as a thirty-second note taken from the start of the note it precedes. An appoggiatura takes half the value of that note
- [ ] Staccato sounds for half the note's value, staccatissimo for a quarter, and tenuto for all of it; other notes sound for their full value
- [ ] Unpitched note events go to channel 10, at the GM percussion key their instrument names, or at a documented default key when it names none
- [ ] With `transposed: true`, a part's pitches are read as written and sound at concert pitch, as the other writers read that option

### Order of play

- [ ] Bars are written in `Flow#performance_order`, so repeats, endings, D.C., and D.S. are played out, and a meter, key, or tempo change is written again each time its bar is played

### Loudness

- [ ] Each dynamic level maps to a documented velocity, from *ppp* to *fff*. A note's velocity comes from `Voice#dynamic_at` at its onset. With no level in force, a documented default is used
- [ ] A note dynamic of *sf*, *sfz*, or *rfz* raises that note's velocity by a documented amount. An *fp* note sounds at *f*, and the notes after it at *p*, as `dynamic_at` already answers
- [ ] Accent and marcato raise a note's velocity by a documented amount
- [ ] Under a hairpin, a note's velocity is interpolated by its onset. The ramp runs from the level in force at the hairpin's start to the level placed at its end. When no level is placed at its end, the ramp runs to one level beyond the start, in the hairpin's direction
- [ ] A voice hairpin applies to its own voice, and a part hairpin to every voice of the part

### Instruments

- [ ] Every instrument in the catalog that has a General MIDI program records it, and every unpitched percussion instrument that has a GM percussion key records it
- [ ] A part writes a program change at its start, and another at each instrument change, when the instrument has a GM program; a part without one writes none, and plays as the synthesizer's default

### Lyrics

- [ ] Each syllable writes a lyric meta event at its note's onset, with a hyphen after it when `hyphen_after` is set

### Verification

- [ ] Specs decode the bytes with a reader in `spec/support` and assert on events and ticks, not on raw byte strings alone. MIDI Import may promote that reader into the gem
- [ ] The ABC, LilyPond, and kern fixtures each render, and their decoded notes match the flow's key numbers and onsets
- [ ] A rendered fixture opens in at least one real MIDI tool (MuseScore, GarageBand, `timidity`, or `fluidsynth`) without errors, checked by hand and recorded in the story
- [ ] Maintains 90%+ test coverage

## Notes

- The SMF is written without a dependency, with `Array#pack` and a variable-length quantity helper, and without running status.
- Note velocities are fixed at each attack. Swelling a held note through a hairpin would take controller 11 (expression) events, and that is a follow-up.
- **Follow-up: ornament realization.** Trills, mordents, and turns sound as plain notes. A realization depends on style and tempo: the starting note, the speed, and where the trill ends.
- **Waits on Timeline Expressions:** fermatas, ritardandos, and accelerandos come with [Timeline Expressions](timeline-expressions.md), which teaches the `Conductor` to keep time through them. The writer should then write the matching tempo events.
- A MIDI key signature holds only major or minor. A tonal context in another mode writes its signature as major.
- **No `Layout#to_midi` in v1.** An SMF is one sequence, so several flows would have to be joined or written as several files. The caller can render each realized flow instead.

## Decisions

- **The module is `HeadMusic::MIDI`** (decided 2026-10-14), beside `Notation` and `Time`, since MIDI holds performance, not notation. `MIDI::RenderError` and `MIDI::ParseError` live there, and [MIDI Import](midi-import.md) builds in the same module.
- **One track per part** (decided 2026-10-14). A part is one instrument, which in MIDI means one channel and one program. This matches how scorewriters export.
- **Dynamics, accents, and hairpins shape velocity in v1** (decided 2026-10-14). This reverses the original constant-velocity scope, since the model now holds all three.
- **This story follows MusicXML Import** in the backlog order (decided 2026-10-14), and so lands after [Tuplets and Grace Notes](tuplets-and-grace-notes.md). That is why the tick resolution and grace-note criteria cover them.

## Implementation Plan

[to be filled in by /stories plan]
