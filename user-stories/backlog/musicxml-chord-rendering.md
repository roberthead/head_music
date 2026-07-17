<!--
metadata:
  created_at:   2026-07-17T12:54:19-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-07-17T13:48:24-07:00
-->

# Story: MusicXML Chord Rendering

## Summary

AS a developer using HeadMusic

I WANT `Composition#to_musicxml` to render chord placements as stacked notes

SO THAT block chords display on one staff in MusicXML-consuming renderers (OSMD, MuseScore, etc.)

## Background

The content model represents a chord as a single `Placement` holding a `pitches` array (see the Chord Placement Model story): one position, one rhythmic value, many pitches. Because a chord is one placement, `Voice#first_gap` contiguity works by construction — no special grouping is needed. The MusicXML writer, however, currently guards against chords: it raises when it encounters a placement where `chord?` is true, because it only knows how to emit the single derived `placement.pitch` and would otherwise silently render the top note alone. It never emits the `<chord/>` element, which is how MusicXML marks a note as sounding simultaneously with the previous note.

This story is a prerequisite for BardTheory's staff-notation-view story, which renders compositions via `to_musicxml` → OSMD and requires block chords on the treble staff. The complementary input half is [ABC Chord Input](abc-chord-input.md) — that story gets chords *into* the model; this one gets them *out* to notation.

## Scope

- Replace the writer's chord guard with real rendering: a chord placement emits one `<note>` per pitch, first note plain, each subsequent note carrying `<chord/>`, per the MusicXML 4.0 convention. All notes share the placement's rhythmic value.
- Emit chord notes in a deterministic order (low to high) regardless of the `pitches` array order.
- Chords spanning voices are *not* merged — each voice remains its own part; only the pitches of a single placement form a chord.

## Example

```ruby
composition = HeadMusic::Content::Composition.new(name: "Chorale", key_signature: "C major", meter: "4/4")
voice = composition.add_voice(role: "Treble")
voice.place("1:1", :half, %w[C4 E4 G4])
voice.place("1:3", :half, %w[D4 F4 A4])

xml = composition.to_musicxml
# E4 and G4 <note> elements at beat 1 each contain <chord/>; OSMD renders two stacked triads
```

## Acceptance Criteria

- A chord placement emits as a MusicXML chord (`<chord/>` on all but the first note), replacing the writer's raise-on-chord guard
- A composition mixing chords and single notes renders with correct measure durations
- Chord notes emit low to high
- Existing single-line compositions render byte-identically to before (no regression)
- Output validates against the MusicXML 4.0 schema (matching the writer's existing spec approach)
- Rubocop and all specs pass

## Implementation Plan

[to be filled in by /stories plan]
