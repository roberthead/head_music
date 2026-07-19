<!--
metadata:
  created_at:   2026-07-17T12:54:19-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-07-18T16:03:28-07:00
-->

# Story: ABC Chord Input

## Summary

AS a developer using HeadMusic

I WANT the ABC parser to accept bracket chord syntax (e.g. `[CEG]2`) and produce chord placements

SO THAT I can author block chords in ABC and load them into the content model

## Background

The content model represents a chord as a single `Placement` holding two or more pitched sounds (see the Chord Placement Model and Sound Model stories): one position, one rhythmic value, many sounds. `Placement#sounds` (a frozen array) is the source of truth — each sound is a `Rudiment::Pitch` or a `Rudiment::UnpitchedSound` — and `Placement#pitches` is the derived pitched subset. `chord?` is true when a placement has two or more pitched sounds; `note?` means exactly one sound of either kind. `Voice#place` accepts an array of pitches directly, and `Composition#to_h` / `.from_h` round-trip chords via the `"sounds"` key under schema version 3, where each pitch serializes as a string (e.g. `"C4"`).

The ABC importer, however, rejects chords: the body lexer scans `[...]` groups (that are not inline fields like `[K:...]`) as `:unsupported` tokens (`lib/head_music/notation/abc/body_lexer.rb`), and the parser raises `ParseError` on any unsupported token (`lib/head_music/notation/abc/parser.rb`). The ABC writer likewise guards against chords, raising when a placement's `chord?` is true rather than silently emitting only the top pitch. (The writer's separate `RenderError` guard for placements containing unpitched sounds is untouched by this story — every bracketed ABC note resolves to a `Pitch`, so this story only ever produces all-pitched placements; percussion rendering waits for its own story.)

This story is a prerequisite for BardTheory's staff-notation-view story, whose write pipeline is ABC-in (`ABC.parse` → `#to_h`) and which requires block chords on the treble staff. The complementary rendering half is [MusicXML Chord Rendering](musicxml-chord-rendering.md) — this story gets chords *into* the model; that one gets them *out* to notation.

## Scope

- Parse `[CEG]` bracket groups in the tune body into a single placement whose sounds are the bracketed pitches. Each bracketed note resolves to a `Pitch`, so the resulting placement is all-pitched and answers `chord?` (two or more pitched sounds).
- Support a duration suffix outside the brackets (`[CEG]2`) applying to the chord placement's single rhythmic value, consistent with how durations attach to single notes.
- Per-note durations inside the brackets (`[C2EG]`) are unrepresentable in the model (one rhythmic value per placement); reject them with a clear `ParseError`.
- Replace the ABC writer's chord guard with real emission: `#to_abc` writes a chord placement as bracket syntax, so ABC round-trips chords.
- Leave the writer's `RenderError` guard for unpitched sounds in place — this story handles pitched chords only.
- Quoted chord *symbols* (`"Am"`) remain unsupported — they are annotations, not notes, and stay out of scope.

## Example

```ruby
composition = HeadMusic::Notation::ABC.parse(<<~ABC)
  X:1
  T:Chorale Fragment
  M:4/4
  L:1/4
  K:C
  [CEG]2 [DFA]2 | [EGC']4 |]
ABC

voice = composition.voices.first
voice.placements.map { |p| [p.position.to_s, p.pitches.map(&:to_s)] }
# => [["1:1:000", ["C4", "E4", "G4"]], ["1:3:000", ["D4", "F4", "A4"]], ["2:1:000", ["E4", "G4", "C5"]]]

composition.to_abc # emits the chords back as bracket groups
```

## Acceptance Criteria

- `ABC.parse` reads `[CEG]`-style chords into a single all-pitched placement (`chord?` true, every sound a `Pitch`) with a shared rhythmic value
- A duration suffix after the closing bracket applies to the whole chord
- Per-note durations inside brackets raise a `ParseError` with a helpful message
- Inline fields (`[K:...]`, `[M:...]`) are still recognized and not confused with chords
- `#to_abc` writes chord placements as bracket chords (replacing the raise-on-chord guard); parse → write → parse round-trips
- The writer's `RenderError` guard for unpitched sounds is unchanged
- Rubocop and all specs pass

## Implementation Plan

[to be filled in by /stories plan]
