<!--
metadata:
  created_at:   2026-07-06T15:46:51-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-07-06T15:46:51-07:00
-->

# Story: ABC Notation Export

## Summary

AS a developer using HeadMusic

I WANT to render a `HeadMusic::Content::Composition` as an ABC notation string

SO THAT I can round-trip compositions back out to the compact, text-based format the [ABC interpreter](../done/abc-notation-interpreter.md) already reads in

## Background

[ABC notation](https://abcnotation.com/) is a compact, text-based music format: a tune header of `X:`/`T:`/`C:`/`M:`/`L:`/`K:` fields followed by a body of pitch tokens (`C D E F`, octave marks `,`/`'`, accidentals `^`/`_`/`=`), durations (`A2`, `A/2`), rests (`z`), and barlines (`|`).

This story renders *outward* (HeadMusic objects → ABC text). It is the complement of the [ABC Notation interpreter](../done/abc-notation-interpreter.md), which already reads text *into* the object model via `HeadMusic::Notation::ABC.parse`. Together they form a round trip: `ABC.parse(str).to_abc` should reproduce an equivalent tune.

`HeadMusic::Content::Composition` already carries what a basic tune needs: `name`, `composer`, `key_signature`, `meter`, and `voices` holding placements of pitched, durationed notes across bars. This story turns that model into an ABC string, reusing the interpreter's helper classes (`Header`, `KeyMapper`, `PitchBuilder`, `DurationResolver`) in reverse where practical.

## Example

```ruby
composition = HeadMusic::Notation::ABC.parse(<<~ABC)
  X:1
  T:Exercise
  M:4/4
  L:1/8
  K:G
  g a b c' d' c' b g |
ABC

composition.to_abc      # => String of ABC notation reproducing an equivalent tune
```

## Acceptance Criteria

- `HeadMusic::Content::Composition#to_abc` returns a String of valid ABC notation.
- The header emits `X:` (tune number), `T:` from `name`, `C:` from `composer` when present, `M:` from the meter, `L:` (unit note length), and `K:` from the key signature.
- Pitched notes render with the correct letter, octave marks (`,`/`'`), and accidentals (`^`/`_`/`=`) relative to the key signature.
- Note durations render relative to the `L:` unit length (e.g. `A2`, `A/2`); rests render as `z` with matching duration.
- Barlines (`|`) separate bars; the output is line-wrapped reasonably.
- **Round trip**: `HeadMusic::Notation::ABC.parse(composition.to_abc)` produces a composition equivalent to the original (same pitches, durations, key, meter) for the supported subset — asserted by specs.
- Specs cover: a single-voice diatonic tune, a tune with accidentals, a tune with varied durations and rests, and a round-trip assertion over an interpreter fixture.

## Notes

**Entry-point shape.** The user's framing is `Composition#to_abc`. To mirror the Notation module's inward pattern (`HeadMusic::Notation::ABC.parse`), the rendering logic likely belongs in the `HeadMusic::Notation::ABC` module (e.g. a `Renderer`/`Writer` class, or `ABC.render(composition)`), with `Composition#to_abc` as a thin delegate. Confirm this split during planning so export code lives in the Notation module rather than bloating `Composition`. This is the same design question raised by the [MusicXML Export](music-xml-export.md) story — resolve both consistently.

**Reuse the interpreter.** The ABC interpreter already encodes the pitch↔letter, key↔`K:`, and duration↔unit-length mappings (`lib/head_music/notation/abc/`). Prefer inverting/reusing `KeyMapper`, `PitchBuilder`, and `DurationResolver` over reimplementing them, so parse and render stay in agreement.

**Scope.** Start with the subset the interpreter round-trips cleanly: single tune, header fields above, pitches/octaves/accidentals, durations, rests, barlines. Out of scope for a first cut (follow-up candidates): multi-voice (`V:`) output, ties/slurs, tuplets, chords, decorations, lyrics (`w:`), and tune books (`parse_book`'s inverse).

**Open questions for planning.**
- How is `L:` (unit note length) chosen from the model's durations — fixed `1/8`, or derived from the shortest/most-common note?
- Accidental spelling: honor the pitch's spelling from the model, or normalize against the key signature?
- Line-wrapping / bars-per-line policy for readable output.
- Does `X:` (tune number) come from anywhere on the composition, or default to `1`?

## Implementation Plan

[to be filled in by /stories plan]
