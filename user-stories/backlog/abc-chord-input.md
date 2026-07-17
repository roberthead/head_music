<!--
metadata:
  created_at:   2026-07-17T12:54:19-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-07-17T12:54:19-07:00
-->

# Story: ABC Chord Input

## Summary

AS a developer using HeadMusic

I WANT the ABC parser to accept bracket chord syntax (e.g. `[CEG]2`) and produce co-positioned placements

SO THAT I can author block chords in ABC and load them into the content model

## Background

The content model already supports chords: a `Voice` accepts multiple placements at the same position, and `Voice#place` keeps co-positioned placements in insertion order (`lib/head_music/content/voice.rb`). `Composition#to_h` / `.from_h` serialize placements individually, so co-positioned placements should round-trip through the hash serialization without changes — but this has not been exercised.

The ABC importer, however, rejects chords: the body lexer scans `[...]` groups (that are not inline fields like `[K:...]`) as `:unsupported` tokens (`lib/head_music/notation/abc/body_lexer.rb`), and the parser raises `ParseError` on any unsupported token (`lib/head_music/notation/abc/parser.rb`). So `HeadMusic::Notation::ABC.parse` cannot read a block chord at all.

This story is a prerequisite for BardTheory's staff-notation-view story, whose write pipeline is ABC-in (`ABC.parse` → `#to_h`) and which requires block chords on the treble staff. The complementary rendering half is [MusicXML Chord Rendering](musicxml-chord-rendering.md) — this story gets chords *into* the model; that one gets them *out* to notation.

## Scope

- Parse `[CEG]` bracket groups in the tune body into one placement per pitch, all at the same position in the same voice.
- Support a duration suffix outside the brackets (`[CEG]2`) applying to every note of the chord, consistent with how durations attach to single notes.
- v1 may require uniform durations within a chord: reject per-note durations inside the brackets (`[C2EG]`) with a clear `ParseError` rather than guessing semantics.
- `#to_abc` (the ABC writer) emits bracket syntax for co-positioned placements, so ABC round-trips chords.
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
voice.placements.map { |p| [p.position.to_s, p.pitch.to_s] }
# => three placements sharing position 1:1:000, three sharing 1:3:000, three sharing 2:1:000

composition.to_abc # emits the chords back as bracket groups
```

## Acceptance Criteria

- `ABC.parse` reads `[CEG]`-style chords into co-positioned placements with a shared rhythmic value
- A duration suffix after the closing bracket applies to the whole chord
- Per-note durations inside brackets raise a `ParseError` with a helpful message (unless full support proves cheap)
- Inline fields (`[K:...]`, `[M:...]`) are still recognized and not confused with chords
- `#to_abc` writes co-positioned placements as bracket chords; parse → write → parse round-trips
- `#to_h` / `.from_h` round-trips a composition containing chords (verified by spec)
- Rubocop and all specs pass

## Implementation Plan

[to be filled in by /stories plan]
