<!--
metadata:
  created_at:   2026-07-17T12:54:19-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-07-17T12:54:19-07:00
-->

# Story: MusicXML Chord Rendering

## Summary

AS a developer using HeadMusic

I WANT `Composition#to_musicxml` to render co-positioned placements as a chord

SO THAT block chords display as stacked notes on one staff in MusicXML-consuming renderers (OSMD, MuseScore, etc.)

## Background

The content model permits chords — a `Voice` holds multiple placements at the same position — but the MusicXML writer cannot render them. `Voice#first_gap` expects each placement to begin exactly at the previous placement's `next_position`, so a second placement at the *same* position registers as a gap and `ensure_contiguous_voices` raises a `RenderError` (`lib/head_music/notation/music_xml/writer.rb`). The writer also never emits the `<chord/>` element, which is how MusicXML marks a note as sounding simultaneously with the previous note.

This story is a prerequisite for BardTheory's staff-notation-view story, which renders compositions via `to_musicxml` → OSMD and requires block chords on the treble staff. The complementary input half is [ABC Chord Input](abc-chord-input.md) — that story gets chords *into* the model; this one gets them *out* to notation.

## Scope

- Co-positioned placements within a voice render as one chord: first note plain, each subsequent note carrying `<chord/>`, per the MusicXML 4.0 convention.
- Contiguity checking treats a co-positioned group as a single rhythmic event: the group advances the expected position once, by the shared rhythmic value.
- Chord members must share a rhythmic value; mismatched durations at the same position raise a clear `RenderError` (fail loudly, consistent with the writer's existing gap and barline errors).
- Emit chord notes in a deterministic order (low to high) regardless of insertion order.
- Chords spanning voices are *not* merged — each voice remains its own part; only same-voice co-positioned placements form a chord.

## Example

```ruby
composition = HeadMusic::Content::Composition.new(name: "Chorale", key_signature: "C major", meter: "4/4")
voice = composition.add_voice(role: "Treble")
voice.place("1:1", :half, "C4")
voice.place("1:1", :half, "E4")
voice.place("1:1", :half, "G4")
voice.place("1:3", :half, "D4")
voice.place("1:3", :half, "F4")
voice.place("1:3", :half, "A4")

xml = composition.to_musicxml
# E4 and G4 <note> elements at beat 1 each contain <chord/>; OSMD renders two stacked triads
```

## Acceptance Criteria

- Co-positioned placements in a voice emit as a MusicXML chord (`<chord/>` on all but the first note)
- A composition mixing chords and single notes renders with correct measure durations
- Mismatched durations at one position raise `RenderError` with a helpful message
- Chord notes emit low to high
- Existing single-line compositions render byte-identically to before (no regression)
- Output validates against the MusicXML 4.0 schema (matching the writer's existing spec approach)
- Rubocop and all specs pass

## Implementation Plan

[to be filled in by /stories plan]
