<!--
metadata:
  created_at:   2026-07-19T11:46:34-07:00
  activated_at: 2026-07-19T11:52:42-07:00
  planned_at:   2026-07-19T11:57:00-07:00
  finished_at:
  updated_at:   2026-07-19T15:54:58-07:00
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
- A tie **across a barline** joins the last note of a measure to the first note of the next measure of the same pitch, producing one sustained note that spans the bar line. **(Deferred to a follow-up — see the Implementation Plan's scope decision. v1 detects an author tie that would cross a barline and raises a clear `ParseError`, "Ties across barlines are not yet supported," rather than joining the notes.)**
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

### Scope decision

This story ships **intra-note (within-bar) author-controlled ties** and reuses the existing tie-rendering pipeline end to end. The MusicXML writer already turns a `RhythmicValue` with a `tied_value` chain into multiple `<note>` elements carrying `<tie>`/`<tied>` (`MusicXML::DurationWriter#components`, `Writer#tie_lines`/`#notation_lines`). So the only gap is the ABC **input** boundary: letting the parser build a placement whose `RhythmicValue` is the author's chosen head-plus-tail instead of the resolver's greedy split.

**Cross-barline ties are deferred.** A single placement cannot span a bar — the MusicXML writer's `ensure_notes_within_barlines` rejects that outright, and representing a tie *between two placements* would require a new concept in the Voice/Placement model plus writer changes. This story instead detects an author tie that would cross a barline (a `-` immediately before a bar line) and raises a clear, specific `ParseError` at parse time. Tracked as a follow-up in Scope Boundaries.

### Step 1 — Lexer: emit a `:tie` token (`abc/body_lexer.rb`)

- Add `scan_tie` to the `scan_token` chain, placed **before** `scan_unsupported`: match a single `-` and push `Token.new(type: :tie, line:, column:)`.
- Remove `-` from `scan_unsupported`'s character class (`/[()\-~.]/` → `/[()~.]/`) so slurs `()`, staccato `.`, and roll `~` stay unsupported while `-` no longer does.
- `-` inside volta ranges (`VOLTA_DIGITS_PATTERN`, `[…]`/trailing-volta paths) is unaffected — those are scanned in their own branches before the note stream reaches `scan_tie`.

### Step 2 — Parser: combine tied notes into one placement (`abc/parser.rb`)

- Extend `VoiceState` with a `tie_open` flag (+ a `tie_line` for error reporting).
- Extend `PendingNote` with a `tied_prefix:` field (default `nil`) — a pre-built `RhythmicValue` holding everything tied *before* this note's own `(length, scale)`.
- `handle_tie(token)`: require a `pending_note` and not `awaiting_scale`; otherwise raise `ParseError` ("A tie must follow a note" / broken-rhythm conflict). Set `state.tie_open = true`, record the line. Do **not** flush the pending note.
- In `handle_note`/`handle_chord`: when `state.tie_open` is set, don't defer normally. Instead:
  - Validate the new pitches equal the pending pitches (set equality). Mismatch → `ParseError` "A tie must connect two notes of the same pitch" with line/snippet (this is the ABC slur case).
  - Build the head chain: `head = append_tied(pending.tied_prefix, resolve(pending))` where `resolve` = `duration_resolver.rhythmic_value(pending.length, scale: pending.scale)` and `append_tied(prefix, tail)` returns `tail` when `prefix` is nil, else a copy of `prefix` whose deepest `tied_value` is `tail` (recursive rebuild via `RhythmicValue.new(unit, dots:, tied_value:)`, since `RhythmicValue` has no setters).
  - Set the new `pending_note` to the incoming note with `tied_prefix: head`; clear `tie_open`. Keeping it pending preserves broken-rhythm deferral and lets `E2-E2-E2` chains accumulate.
- `flush_pending_note`/`place`: when `pending.tied_prefix` is present, place `append_tied(pending.tied_prefix, resolve(pending))` as the single placement's value; otherwise unchanged.
- Guard the non-note terminators so an open tie fails fast and specifically:
  - `handle_bar_line` while `tie_open` → `ParseError` "Ties across barlines are not yet supported" (the deferred case).
  - `handle_rest` / `handle_volta` / `handle_voice_change` while `tie_open` → `ParseError` "A tie must connect two notes of the same pitch" (a tie to a non-note).
  - `finish` while `tie_open` → `ParseError` "Tie has no following note" (dangling tie at end of tune).
- `handle` gains a `when :tie then handle_tie(token)` branch.

### Step 3 — Verify the render path is already correct

No writer changes expected. Confirm by test that a parsed `E3-E2` produces a placement whose `rhythmic_value.to_s == "dotted quarter tied to quarter"` and that `to_musicxml` emits `<tie type="start"/>` + `<tied type="start"/>` on the first note and the `stop` pair on the second. If a gap surfaces, fix it in `MusicXML::Writer`, but the existing greedy-resolver output already exercises this path.

### Step 4 — Specs

- **Lexer** (`spec/.../abc/body_lexer_spec.rb`): `-` lexes as a `:tie` token; `()`, `.`, `~` still lex as `:unsupported`.
- **Parser** (`spec/.../abc/parser_spec.rb` or the interpreter spec): author split `E3-E2` → one note, `RhythmicValue` "dotted quarter tied to quarter" (assert it differs from the greedy `E5` → "half tied to eighth"); a chain `C2-C2-C2`; mismatched pitch `E3-D2` raises the same-pitch `ParseError`; cross-barline `E3-|E3` raises "not yet supported"; dangling `E3-` at end raises; tie with no preceding note (`-E3`) raises.
- **Round-trip / MusicXML** (`spec/.../music_xml_spec.rb` or the ABC interpreter → MusicXML spec): parsing the Three-Blind-Mice-style measure and rendering asserts the `<tied>` start/stop elements.
- Follow existing spec structure/naming in `spec/head_music/notation/abc/`.

### Step 5 — Docs & housekeeping

- Update the `scan_unsupported` comment (currently lists "ties" among deliberately-unhandled constructs) to reflect that ties are now handled on input.
- If a README/CHANGELOG enumerates supported ABC features, add ties (input, within-bar).
- Run `bundle exec rspec` and `bundle exec standardrb`/`rubocop` (whichever the repo uses) to green before finishing.

### Files touched

- `lib/head_music/notation/abc/body_lexer.rb` — `scan_tie`, unsupported char-class edit, comment.
- `lib/head_music/notation/abc/parser.rb` — `:tie` handling, `PendingNote`/`VoiceState` extension, `append_tied`, terminator guards.
- `spec/head_music/notation/abc/*` and the MusicXML spec — new coverage.
- Possibly `CHANGELOG`/README if they enumerate ABC feature support.

### Scope Boundaries (Not in v1)

- **Cross-barline ties** (`E3-|E3`) — needs a tie-between-placements concept in the Voice/Placement model and MusicXML writer; raises a clear "not yet supported" error for now.
- **Ties on/between chords** (`[CEG]-[CEG]`) — the pitch-set-equality guard would admit identical chords, but this path is not a v1 target and gets at most light coverage; document as follow-up.
- **Slurs** (`( … )`) — distinct construct, remains unsupported.
- **ABC export of authored ties** — the exporter still collapses tied chains to a single multiplier (`E3-E2` → `E5`); preserving an authored split on export is out of scope. Export round-trip specs assert the current collapsing behavior.

## Review

_Reviewed 2026-07-19 at commit `8323de5` (implementation in `93023bb`, committed to `main` — no `story/abc-tie-input` branch was cut). All 236 examples in the ABC lexer/parser and MusicXML writer specs pass; the full suite still needs to be run to confirm nothing else regressed._

### Acceptance criteria

- ✅ **Lexer tie token; `-` elsewhere still errors.** `scan_tie` is inserted before `scan_unsupported` and emits a `:tie` token (`body_lexer.rb:285-290`); `-` was removed from the unsupported char class (`body_lexer.rb:298`). A leading tie is rejected in the parser ("A tie must follow a note", `parser.rb:226-235`). Note: a stray `-` with nothing else to match now yields the generic "Unexpected character" error rather than the old `UnsupportedFeatureError "-"` — arguably clearer, but a behavior change.
- ✅ **Authored split preserved, overrides greedy resolver.** `tie_onto_pending` + `append_tied` build the nested `RhythmicValue` from the authored lengths (`parser.rb:240-363`). `parser_spec.rb:295-306` asserts `E3-E2` → `"dotted quarter tied to quarter"` and contrasts it against the greedy `"half tied to eighth"`.
- ✅ **Tie chains nest into one value.** `append_tied` recurses; `C2-C2-C2` → `"quarter tied to quarter tied to quarter"` (`parser_spec.rb:308-311`).
- ❌ **Cross-barline spanning tie — consciously deferred.** Not implemented; `handle_bar_line` raises "Ties across barlines are not yet supported" (`parser.rb:294`). The deferral is clean, documented in code/CHANGELOG/commit, and tested (`parser_spec.rb:323-326`). The original criterion is not met by design — this was scoped out in the plan. _Follow-up: the story's AC text has now been annotated to record the deferral._
- ✅ **Different-pitch tie raises, never silent.** `ensure_tie_pitches_match` raises "A tie must connect two notes of the same pitch" (`parser.rb:251-258`); `E3-D2` tested (`parser_spec.rb:318-321`). Behavior (raise, not slur) is documented in the CHANGELOG.
- ✅ **MusicXML `<tie>`/`<tied>` render.** No writer change needed — reuses the existing tied-`RhythmicValue` path. `writer_spec.rb:363-380` asserts note types `quarter quarter eighth`, a dot on note 1, and `tied` start/stop counts `[1,0,0]`/`[0,1,0]`.
- ✅ **ABC export round-trip decided/documented/asserted.** Behavior is decided (collapse to one multiplier: `E3-E2` → `E5`) and documented in the story's Scope Boundaries. _Follow-up: a round-trip spec was added (`writer_spec.rb`, "with an authored tie collapsing to a single multiplier") asserting that parsing `E3-E2 G` and re-exporting yields `E5 G` — pinning the intentional asymmetry between input (preserves the authored split) and export (collapses it)._
- ✅ **Five required spec cases present** (intra-measure split, cross-barline [asserts the deferral error], chain, mismatched pitch, MusicXML `<tied>`), plus bonus error-path coverage (dangling tie, no-preceding-note, tie-to-rest, whole-bar simple-meter tie).

### Code review findings

1. **(Should-fix, confirmed bug) `handle_broken_rhythm` does not reject an open tie — silent wrong output.** `parser.rb:277-289`. Every other terminator calls `reject_open_tie`, but this one was overlooked; its guard checks only `awaiting_scale`/`pending_note.nil?`. Verified: `A->A` parses **without error** into a bogus "dotted eighth tied to sixteenth" (both the tie and the broken-rhythm ×3/2·×1/2 scaling applied at once) instead of raising like `A-z` or `A-|` do. Fix: add `reject_open_tie(state, token.line, "A tie must be followed by a note")` at the top of `handle_broken_rhythm`, with a spec for `A->A` / `A-<A`.
2. **(Nice-to-have) Pitch match mixes two comparison semantics.** `parser.rb:252` — `pending.pitches.sort == pitches.sort`. `sort` orders by `Pitch#<=>` (MIDI number; enharmonics tie), then array `==` compares by `Pitch#==` (spelling). They disagree on enharmonics, so `^C-_D` is rejected as "same pitch" mismatch — defensible, but worth a one-line "why" comment.
3. **(Nice-to-have) Bar-line tie message can mislead.** `parser.rb:294` — `E3-|]` (dangling tie at a section end) reports "Ties across barlines are not yet supported" though nothing crosses a barline. Minor; the terminator can't distinguish the two cases and the message is right for the tested `E3-|E3`.

### Test coverage gaps

- **Tie + broken rhythm** (`A->A`) — the untested path behind finding #1.
- **Successful chord-to-chord tie** — the lexer tokenizes `[CEG]-c`, but no parser spec fuses a chord tie into one placement.
- **Open tie across a voice change** (`parser.rb:318`) and **across a volta** (`parser.rb:308`) — both `reject_open_tie` branches are unexercised.

### Blocks `finish`?

Nothing outstanding. **Finding #1** (the `A->A` silent-miscompute) has been fixed: `handle_broken_rhythm` now calls `reject_open_tie` and `A->A`/`A-<A` raise a clear `ParseError`, with a covering spec. The two follow-up items called out under criteria 4 and 7 have also been addressed — the export round-trip spec was added and the deferred cross-barline AC was annotated. The remaining nice-to-haves (pitch-comparison comment, bar-line message wording, chord-to-chord / voice-change / volta coverage) are non-blocking.
