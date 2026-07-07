<!--
metadata:
  created_at:   2026-07-07T11:19:50-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-07-07T11:19:50-07:00
-->

# Story: LilyPond Export

## Summary

AS a developer using HeadMusic

I WANT to render a `HeadMusic::Content::Composition` as a LilyPond document

SO THAT I can hand my compositions to engravers, collaborators, and toolchains that consume LilyPond source

## Background

[LilyPond](https://lilypond.org/) is a text-based engraving language widely used for high-quality score output. A LilyPond source file (`.ly`) typically combines commands such as `\key`, `\time`, and `\clef` with note/rest tokens (for example `c4 d8 r8`) and voice/staff constructs like `\score`, `\new Staff`, and `\new Voice`.

This story renders *outward* (HeadMusic objects → LilyPond text). It is the complement of the inward notation-interpreter stories under the [Notation Module epic](../epics/notation-module.md) — the [ABC Notation interpreter](../done/abc-notation-interpreter.md) and [LilyPond interpreter](lilypond-interpreter.md) both read text *into* the object model via `HeadMusic::Notation::<Format>.parse`. Export is the reverse trip.

`HeadMusic::Content::Composition` already carries everything a basic score needs: `name`, `composer`, `key_signature`, `meter`, `voices` (each with placements of pitched, durationed notes across bars), and per-bar key/meter changes. This story turns that model into valid LilyPond source text.

## Example

```ruby
composition = HeadMusic::Content::Composition.new(
  name: "Exercise",
  key_signature: "G major",
  meter: "4/4"
)
voice = composition.add_voice(role: "Cantus firmus")
# ... voice.place(...) some notes ...

lily = composition.to_lilypond
lily            # => String of LilyPond source (e.g. \score { ... })
```

## Acceptance Criteria

- `HeadMusic::Content::Composition#to_lilypond` returns a String containing syntactically valid LilyPond source.
- The output carries composition identity through a `\header` block: `title` from `name`, and `composer` when present.
- The document emits one musical stream per voice (for example `\new Staff`/`\new Voice` inside `\score`) and keeps note/rest ordering and bar progression intact.
- Pitched notes render with correct LilyPond pitch spelling (step + accidental suffixes like `is`/`es`) and octave markers (`'` / `,` as needed by the chosen mode).
- Durations render correctly (`1`, `2`, `4`, `8`, `16`, dotted forms), including chained/tied values where needed.
- Rests render as LilyPond rests (`r`) with the correct durations.
- The first emitted measure includes key signature and meter (`\key`, `\time`) and a sensible default clef; mid-piece key/meter changes emit `\key` / `\time` at the bar where they occur.
- A generated example is accepted by a LilyPond reader toolchain (e.g. HeadMusic's LilyPond parser and/or LilyPond CLI) without syntax errors.
- Specs cover: a single-voice diatonic example, an example with accidentals, an example with rests, a multi-voice example, and a mid-piece key/meter change.

## Notes

**Entry-point shape — decided** (during planning of the [ABC Notation Export](../current/abc-notation-export.md) story; adopt the same pattern here):

- `HeadMusic::Notation::LilyPond.render(composition, **options)` → a `Writer` orchestrator (plus small helper classes, mirroring the ABC module's facade-plus-helpers layout).
- `Composition#to_lilypond(**options)` is a one-line delegate with opaque `**options` pass-through, so `Composition` stays format-ignorant; the option vocabulary lives with `LilyPond.render`.
- Render failures raise a `LilyPond::RenderError` subclassing the shared `HeadMusic::Notation::RenderError` base (introduced by the ABC export story) — not any `ParseError` subclass.
- Mirror the parser-side fail-before-building contract: validate the whole composition up front and raise before emitting, so callers never receive a truncated document.

**Scope.** Start with the subset the object model already expresses cleanly: pitch (step/octave/alter), durations with dots, rests, key and time signatures, per-bar key/meter changes, one staff/voice stream per voice, work title, and composer. Explicitly out of scope for a first cut (candidates for follow-up stories): advanced layout overrides, articulations/dynamics, tuplets, lyrics, chord mode, multiple staves per part, and LilyPond *import* beyond the parser story's current subset.

**Open questions for planning.**
- Should export be absolute pitch output or `\relative` output by default (with an option for the other mode)?
- How should `tied_value` chains map: explicit `~` ties only, or duration splitting strategy with bar-aware formatting?
- Default clef selection: fixed treble, or derived from voice range / instrument when data is available?
- Minimum document envelope for v1: always emit `\version`, `\header`, and `\score`, or allow a bare music expression as output?

## Implementation Plan

Intentionally omitted for now.
