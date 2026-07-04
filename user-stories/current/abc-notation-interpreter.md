<!--
metadata:
  created_at:   2026-07-04T12:05:19-07:00
  activated_at: 2026-07-04T12:21:27-07:00
  planned_at:
  finished_at:
  updated_at:   2026-07-04T12:27:19-07:00
-->

# Story: ABC Notation Interpreter

## Summary

AS a developer using HeadMusic

I WANT to pass a string of ABC notation and receive a `HeadMusic::Content::Composition`

SO THAT I can import folk tunes and other ABC-encoded music into the object model for analysis, transformation, and re-rendering

## Background

[ABC notation](https://abcnotation.com/) is a compact, text-based system widely used for folk and traditional music. A tune is expressed as a header of information fields (tune number `X:`, title `T:`, meter `M:`, default note length `L:`, key `K:`, etc.) followed by a body of notes, bar lines, and other musical symbols.

This is the first of the notation-interpreter stories under the [Notation Module epic](../epics/notation-module.md), which lists ABC notation among the text-based formats the Notation module could eventually support. A companion [LilyPond interpreter](lilypond-interpreter.md) story covers the other major text-based engraving format.

The interpreter reads *inward* (text → HeadMusic objects). Rendering *outward* (HeadMusic objects → ABC text) is a separate, out-of-scope concern.

## Example

```ruby
abc = <<~ABC
  X:1
  T:Speed the Plough
  M:4/4
  L:1/8
  K:G
  |:GABc dedB|dedB dedB|c2ec B2dB|c2A2 A2BA|
ABC

composition = HeadMusic::Notation::ABC.parse(abc)
composition        # => HeadMusic::Content::Composition
composition.name   # => "Speed the Plough"
```

## Acceptance Criteria

- [ ] A documented entry point accepts an ABC string and returns a `HeadMusic::Content::Composition` (e.g. `HeadMusic::Notation::ABC.parse(string)`)
- [ ] The tune title (`T:`) maps to the composition `name`
- [ ] `Composition` gains `composer`, `origin`, and `notes` attributes (set at initialization, exposed via `attr_reader`), and the ABC fields `C:`, `O:`, and `N:` map to them
- [ ] The key field (`K:`) maps to the composition `key_signature`
- [ ] The meter field (`M:`, including `C` for common time and `C|` for cut time) maps to the composition `meter`
- [ ] The default note length field (`L:`) is honored when computing note durations
- [ ] Body notes produce a voice with placements whose pitch, octave, and duration reflect the ABC source
- [ ] Note pitch letters, octave markers (`,` and `'`), and accidentals (`^`, `_`, `=`) are interpreted correctly
- [ ] Bar lines and note-length multipliers/divisors (e.g. `A2`, `A/2`) are handled
- [ ] Multi-voice tunes (`V:` fields) produce multiple voices; a single-voice tune produces one voice
- [ ] Malformed input raises a clear, specific error rather than failing silently or returning a partial composition
- [ ] Specs cover a representative real tune end-to-end plus focused cases for pitch, octave, accidental, duration, meter, and key parsing
- [ ] Maintains 90%+ test coverage

## Notes

- Home for the interpreter: `HeadMusic::Notation` (the module owning text/visual representation of music). Consider `lib/head_music/notation/abc/` for the parser and its helpers.
- The `Composition` API to target: `name`, `key_signature`, `meter`, and `voices` (via `add_voice`), with notes placed through the `Voice` / `Placement` / `Note` classes in `HeadMusic::Content`.
- Reuse existing rudiments where possible: `KeySignature`, `Meter`, `Pitch`, `RhythmicValue` / duration concepts, rather than re-deriving them in the parser.
- Scope the first pass to a practical subset of the ABC spec (single tune per string, common header fields, notes/rests/bar lines, basic decorations). Explicitly out of scope for v1: lyrics (`w:`), chord symbols, ornament glyphs, tuplets beyond the common case, and tune books containing many `X:` records.

## Decisions

Resolved from the original open questions:

1. **One tune per call.** The entry point accepts a single ABC tune for v1. Tune books
   (multiple `X:` records in one string) are out of scope.
2. **Extend `Composition` with `composer`, `origin`, and `notes`.** These are set at
   initialization time and exposed via `attr_reader`, giving the ABC fields `C:`
   (composer), `O:` (origin), and `N:` (notes) a first-class home rather than being
   dropped or stashed in a metadata hash.
3. **Default-note-length and meter interaction lives in the parser.** No new duration
   helper in `Rudiment`.

## Implementation Plan

[to be filled in by /stories plan]
