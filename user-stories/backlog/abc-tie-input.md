<!--
metadata:
  created_at:   2026-07-19T11:46:34-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-07-19T11:46:34-07:00
-->

# Story: ABC Tie Input

## Summary

AS a developer authoring music with the ABC interpreter

I WANT to write explicit ties (`-`) between notes

SO THAT I can control how a sustained duration is engraved — including durations that span a barline — instead of accepting the interpreter's automatic decomposition

## Background

The [ABC Notation interpreter](../done/abc-notation-interpreter.md) reads ABC text into a `HeadMusic::Content::Composition` via `HeadMusic::Notation::ABC.parse`. It handles pitches, durations, chords, broken rhythm, and voltas — but it **deliberately rejects the tie character `-`**. `BodyLexer#scan_unsupported` folds `-` into an `:unsupported` token (character class `/[()\-~.]/`, whose comment reads "Recognizable ABC we deliberately don't handle: grace notes, decorations, tuplets, slurs, **ties**, and special rests"), and `Parser#reject_unsupported_tokens` then raises `UnsupportedFeatureError`.

Ties are already *modeled* everywhere except at the input boundary:

- `HeadMusic::Rudiment::RhythmicValue` carries a `tied_value`, and its string form round-trips "half tied to eighth".
- `ABC::DurationResolver#build_rhythmic_value` already emits tied chains, decomposing any non-dotted-expressible duration by **greedily peeling the largest dotted head each pass**. So `E5` (five eighths under `L:1/8`) always becomes **half tied to eighth** (4 + 1) — the resolver never chooses 3 + 2.
- The ABC exporter's `DurationWriter` already **collapses** a tied chain back into a single multiplier ("A tied chain collapses to one multiplier, round-tripping tokens like `A5`").

The gap is authoring. Because the split is derived greedily and can't be overridden, an author cannot ask for a **dotted quarter tied to a quarter** (3 + 2) rather than **half tied to an eighth** (4 + 1), and — more fundamentally — cannot tie a note *across a barline*, which is the primary reason ties exist in ABC.

This surfaced concretely in bardtheory's "Three Blind Mice" seed. In `6/8` with `L:1/8`, measure 8 is `E5 G` — a sustained E leading to a pickup G. The author wants that E engraved as a dotted quarter tied to a quarter; the interpreter can only produce half-tied-to-eighth, and `E3-E2 G` fails to parse.

The [Notation Module epic](../epics/notation-module.md) already lists this as planned work: "Future: … ties …" and "Ties (connecting same pitches across bars)."

## Example

```
X:1
T:Tie examples
M:6/8
L:1/8
K:C
% Author-chosen split: dotted quarter tied to a quarter, then a pickup G
E3-E2 G |
% Tie across a barline: the C sustains from bar 1 into bar 2
C6 | C3-C3 |]
```

```ruby
composition = HeadMusic::Notation::ABC.parse(abc)
# The E in bar 1 is a single sounding note whose RhythmicValue is
# "dotted quarter tied to quarter" — the authored split, not 4 + 1.
# The tied C sustains across the barline as one note.
```

## Acceptance Criteria

- The lexer recognizes `-` immediately following a note (or chord) as a **tie token** rather than an unsupported feature; `-` in any other position still surfaces the existing clear error.
- A tie between two **same-pitch** notes parses into a single sounding note whose `RhythmicValue` is the authored head tied to the authored tail: `E3-E2` → *dotted quarter tied to quarter* (3 + 2), overriding the greedy resolver rather than re-decomposing to 4 + 1.
- Tie **chains** parse: `E2-E2-E2` yields a single note with a nested tied value spanning the whole duration.
- A tie **across a barline** joins the last note of a measure to the first note of the next measure of the same pitch, producing one sustained note that spans the bar line.
- A tie between **different pitches** is not a tie in ABC (that notation is a slur). It raises a `ParseError` with line number and snippet — or is classified as an unsupported slur — but never silently produces a wrong pitch. (Pick one behavior and document it.)
- The resulting model renders correctly through `to_musicxml`: tied notes emit MusicXML `<tie>` / `<tied>` so playback and engraving treat them as one sustained pitch, not two re-articulated notes.
- Decide and document the **ABC export** behavior for authored ties: whether `DurationWriter` preserves the authored split on round-trip or continues collapsing tied chains to a single multiplier (today it collapses, so `E3-E2` would re-export as `E5`). Round-trip specs assert whichever behavior is chosen.
- Specs cover: an author-chosen intra-measure split, a tie across a barline, a multi-note tie chain, a mismatched-pitch tie (error/slur path), and a MusicXML render asserting the `<tied>` elements.

## Notes

**Touch points (for planning, not prescriptive):**

- `ABC::BodyLexer` — remove `-` from `scan_unsupported`; add a `scan_tie` producing a `:tie` token. Keep the "unterminated / dangling tie" cases as clear `ParseError`s.
- `ABC::Parser` — when a `:tie` token joins two adjacent note placements, merge them into one placement whose `RhythmicValue` uses the authored head with the tail as its `tied_value`, bypassing `DurationResolver`'s greedy split for the tied span. Cross-barline ties are the hard part: a single note must span two measures' placement bookkeeping.
- `ABC::DurationResolver` — unchanged for un-tied durations; explicit ties should *supply* the split rather than derive it.
- `Notation::MusicXML::Writer` / `DurationWriter` — verify tied `RhythmicValue`s already emit `<tie type="start"/stop">` and `<tied>`; the greedy resolver produces tied chains today, so this path may already work and just need coverage.
- `ABC::DurationWriter` (export) — the round-trip decision above lives here.

**Scope boundaries (candidates for follow-up, not v1):**

- Ties inside or between chords (`[CEG]-[CEG]`).
- Slurs `( … )`, which share the `-`-adjacent lexer neighborhood but are a distinct musical construct.
- Preserving an authored split through ABC *export* if that proves to conflict with the exporter's canonical-form goal.

Related: [ABC Notation interpreter](../done/abc-notation-interpreter.md), [ABC Chord Input](../done/abc-chord-input.md), [ABC Notation Export](../done/abc-notation-export.md), [Notation Module epic](../epics/notation-module.md).

## Implementation Plan

[to be filled in by /stories plan]
