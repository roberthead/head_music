<!--
metadata:
  created_at:   2026-07-04T12:05:19-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-07-04T12:05:19-07:00
-->

# Story: LilyPond Interpreter

## Summary

AS a developer using HeadMusic

I WANT to pass a string of LilyPond notation and receive a `HeadMusic::Content::Composition`

SO THAT I can import LilyPond-encoded music into the object model for analysis, transformation, and re-rendering

## Background

[LilyPond](https://lilypond.org/) is a text-based music engraving language. Music is written in `\relative` or absolute mode as a sequence of pitches with durations (e.g. `c4 d4 e4 f4`), organized with commands such as `\key`, `\time`, `\clef`, and grouping constructs like `\score`, `\new Staff`, and `\new Voice`.

This is the second of the notation-interpreter stories under the [Notation Module epic](../epics/notation-module.md), which lists LilyPond among the text-based engraving formats the Notation module could eventually support. It is the companion to the [ABC Notation interpreter](abc-notation-interpreter.md) story and should follow the same entry-point shape and module home.

The interpreter reads *inward* (text → HeadMusic objects). Rendering *outward* (HeadMusic objects → LilyPond text) is a separate, out-of-scope concern.

## Example

```ruby
lily = <<~LILY
  \\relative c' {
    \\key g \\major
    \\time 4/4
    g8 a b c d c b g
  }
LILY

composition = HeadMusic::Notation::LilyPond.parse(lily)
composition            # => HeadMusic::Content::Composition
composition.meter.to_s # => "4/4"
```

## Acceptance Criteria

- [ ] A documented entry point accepts a LilyPond string and returns a `HeadMusic::Content::Composition` (e.g. `HeadMusic::Notation::LilyPond.parse(string)`)
- [ ] `\key` maps to the composition `key_signature`
- [ ] `\time` maps to the composition `meter`
- [ ] Pitches with LilyPond octave marks (`'` up, `,` down) and accidental suffixes (`is`/`es`, including doubles) are interpreted correctly
- [ ] Durations (`1`, `2`, `4`, `8`, `16`, dotted values, and duration carry-over when omitted) map to the correct rhythmic values
- [ ] `\relative` mode resolves each pitch's octave relative to the previous pitch; absolute mode is also supported
- [ ] Rests (`r`) are represented distinctly from pitched notes
- [ ] `\new Staff` / `\new Voice` groupings produce multiple voices; a single music expression produces one voice
- [ ] Comments (`%` and `%{ ... %}`) and insignificant whitespace are ignored
- [ ] Malformed input raises a clear, specific error rather than failing silently or returning a partial composition
- [ ] Specs cover a representative excerpt end-to-end plus focused cases for pitch, octave, accidental, duration, relative-mode resolution, meter, and key parsing
- [ ] Maintains 90%+ test coverage

## Notes

- Home for the interpreter: `HeadMusic::Notation`, mirroring the ABC story. Consider `lib/head_music/notation/lily_pond/` for the parser and its helpers.
- The `Composition` API to target: `name`, `key_signature`, `meter`, and `voices` (via `add_voice`), with notes placed through the `Voice` / `Placement` / `Note` classes in `HeadMusic::Content`.
- Reuse existing rudiments (`KeySignature`, `Meter`, `Pitch`, duration/`RhythmicValue` concepts) rather than re-deriving them in the parser.
- `\relative` mode is the subtlest piece: each pitch is placed in the octave nearest the previous pitch, adjusted by any `'`/`,` marks. Establish the resolution algorithm early and test it thoroughly.
- Scope the first pass to a practical subset: a single `\score` / music expression with common commands and note/rest sequences. Explicitly out of scope for v1: lyrics (`\lyricmode`), chord mode (`\chordmode` / `<...>`), articulations and dynamics, tuplets (`\times`), variables (`music = { ... }`), and full `\book` documents.

## Open Questions

1. Should the parser accept a full `.ly` document (with `\version`, `\header`, `\layout`) and extract the music, or only a bare music expression for v1?
2. LilyPond has no single "title" the way ABC does — should `\header { title = ... }` map to the composition `name`, and if the block is absent, leave it nil?
3. Should absolute mode and `\relative` mode share one pitch resolver with a mode flag, or be handled by separate strategies?

## Implementation Plan

[to be filled in by /stories plan]
