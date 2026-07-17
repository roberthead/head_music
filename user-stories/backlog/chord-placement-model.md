<!--
metadata:
  created_at:   2026-07-17T13:20:33-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-07-17T13:20:33-07:00
-->

# Story: Chord Placement Model

## Summary

AS a developer using HeadMusic

I WANT a `Placement` to hold an array of pitches instead of a single pitch attribute

SO THAT a chord within a voice is modeled as one rhythmic event, with its shared position and duration guaranteed by structure rather than convention

## Background

A chord within a single voice shares one stem and therefore one rhythmic value; different durations at the same position indicate different voices. Modeling a chord as multiple co-positioned placements leaves that invariant unenforced and quietly breaks the "voice is a sequence of events" assumptions in `Voice` — `melodic_note_pairs` would compute a melodic interval between simultaneous chord tones, and `first_gap` would falsely report a gap at every chord (the second chord tone starts at the same position as the first, not at `previous.next_position`).

Every notation format also treats a chord as a single event with multiple pitches: ABC `[CEG]2`, LilyPond `<c e g>2`, and MusicXML's `<chord/>` grouping. Moving to a `pitches` array makes the model match, which is a prerequisite for [ABC Chord Input](abc-chord-input.md) and [MusicXML Chord Rendering](musicxml-chord-rendering.md).

## Scope

- `Placement` stores a `pitches` array (empty for a rest, one element for a single note, multiple for a chord).
- `Placement#pitch` becomes a derived method returning the *highest* pitch in `pitches` (nil when empty), so melodic analysis of chordal music follows the top line.
- `Placement#note?` remains true when any pitch is present; `#rest?` when none. Add a `#chord?` predicate (two or more pitches).
- `Voice#place` accepts a single pitch (as today) or an array of pitches.
- Serialization: `Placement#to_h` emits a `"pitches"` array; `Composition.from_h` accepts both the new `"pitches"` key and the legacy singular `"pitch"` key so existing serialized hashes still load.
- Backward compatibility is a hard requirement: all existing specs and single-pitch code paths behave identically without modification.
- Out of scope: per-tone attributes within a chord (ties, fingerings, noteheads), ABC/MusicXML chord syntax (separate stories), and any change to `Voice`'s melodic analysis beyond what `#pitch` delegation already provides.

## Example

```ruby
voice.place("2:1", :half, %w[C4 E4 G4])

placement = voice.last_placement
placement.pitches.map(&:to_s)  # => ["C4", "E4", "G4"]
placement.pitch.to_s           # => "G4" (highest pitch)
placement.chord?               # => true

placement.to_h
# => { "position" => "2:1:000", "rhythmic_value" => "half", "pitches" => ["C4", "E4", "G4"] }
```

## Acceptance Criteria

- `Placement` exposes `#pitches` (always an array) and derives `#pitch` as the highest pitch, nil for rests
- `Voice#place` accepts a single pitch or an array of pitches; existing single-pitch call sites are unchanged
- `#chord?` is true for two or more pitches; `#note?` / `#rest?` semantics are unchanged for single notes and rests
- `#to_h` emits `"pitches"`; `.from_h` accepts both `"pitches"` and legacy `"pitch"`, and a chord round-trips through `to_h` / `from_h`
- The entire existing spec suite passes without modification (no-op for single-pitch code)
- New specs cover chord construction, `#pitch` derivation, predicates, and serialization round-trips
- Rubocop passes

## Notes

- Choosing the highest pitch for `#pitch` means `Voice#pitches`, `#highest_pitch`, `#melodic_note_pairs`, and style analysis follow the top line of chordal textures — the conventional melody line — without any changes to `Voice`.
- The [ABC Chord Input](abc-chord-input.md) and [MusicXML Chord Rendering](musicxml-chord-rendering.md) backlog stories were written assuming co-positioned placements; their Background/Scope sections should be updated to build on this model once this story lands.

## Implementation Plan

[to be filled in by /stories plan]
