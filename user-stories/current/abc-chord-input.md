<!--
metadata:
  created_at:   2026-07-17T12:54:19-07:00
  activated_at: 2026-07-18T17:27:15-07:00
  planned_at:   2026-07-18T17:36:25-07:00
  finished_at:
  updated_at:   2026-07-18T19:39:39-07:00
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
- Accept **uniform** per-note lengths inside the brackets, per ABC 2.1 §4.17: `[C2E2G2]` means the same as `[CEG]2`, and inner and outer modifiers multiply (`[C2E2G2]3` ≡ `[CEG]6` — the standard's own example). A note with no inner modifier has implicit length 1, so `[C2EG]` is *unequal*.
- **Unequal** per-note lengths (`[C2EG]`, `[C2E2G4]`) are legal ABC (chord duration = first note) but unrepresentable without silent reinterpretation in a one-rhythmic-value placement; reject them with a clear `ParseError` rather than quietly adopting first-note-wins.
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
- Uniform per-note lengths inside brackets are accepted: `[C2E2G2]` parses identically to `[CEG]2`, and `[C2E2G2]3` identically to `[CEG]6` (inner × outer)
- Unequal per-note lengths inside brackets raise a `ParseError` with a helpful message
- Inline fields (`[K:...]`, `[M:...]`) are still recognized and not confused with chords
- `#to_abc` writes chord placements as bracket chords (replacing the raise-on-chord guard); parse → write → parse round-trips
- The writer's `RenderError` guard for unpitched sounds is unchanged
- Rubocop and all specs pass

## Implementation Plan

### Overview

Lex `[CEG]2` into a single structured `:chord` token in `BodyLexer`, generalize the parser's `PendingNote` from `:pitch` to `:pitches` so chords flow through the existing pitch_builder → duration_resolver → `Voice#place` pipeline (which already accepts pitch arrays), and replace the writer's chord guard with bracket emission through the existing `PitchWriter` oracle. No content-model changes: the Sound Model (v17.0.0) already represents chords.

### Steps

1. **Lexer: emit structured `:chord` tokens**

   - Add a `notes: nil` field to the `Token` Data.define (`body_lexer.rb:12-24`) and a small `ChordNote = Data.define(:accidental, :letter, :octave_marks)`.
   - In `scan_bracket` (`body_lexer.rb:159-181`), keep the existing dispatch order untouched — `[|` is consumed earlier by `BAR_LINE_PATTERN` (line 28), then `[1`/`[2` voltas, then `[K:...]` inline fields — and replace the chord-as-`:unsupported` branch with a `scan_chord` entered on `/\[(\^\^|\^|__|_|=)?[A-Ga-g]/`. Widening the entry check to allow a leading accidental fixes a real gap: today `[^CEG]` matches neither `/\[[A-Ga-g]/` nor any other branch and hits `raise_unexpected_character`.
   - `scan_chord`: loop the accidental/letter/octave-marks portion of `NOTE_PATTERN` into `ChordNote`s; after each inner note, raise `ParseError` if a digit or slash follows (per-note duration) — message: `Chord notes cannot have individual lengths; write the length after the bracket, e.g. "[CEG]2"` (`ParseError` appends `" (line N)"` itself; never put "line" in the message). On `]`, scan the outer `[\d/]*` suffix into the token's `length` field. At end of line with no `]`, raise `ParseError` (`Unterminated chord; expected "]"`). On any other inner character (tie, space, rest, decoration — e.g. `[C-E]`, `[Cz]`), rewind and emit the whole bracket group as one `:unsupported` token, preserving today's `UnsupportedFeatureError` path. `[]` keeps today's behavior (`raise_unexpected_character` → `ParseError`).
   - Files: `lib/head_music/notation/abc/body_lexer.rb`, `spec/head_music/notation/abc/body_lexer_spec.rb` (flip the chord-as-unsupported spec near line 211; add chord-token, error, and `[|`/`[1`/`[K:G]` disambiguation-pin specs).

2. **Parser: handle `:chord` via a generalized `PendingNote`**

   - Rename `PendingNote`'s `:pitch` field to `:pitches` (`parser.rb:40`); `handle_note` wraps its pitch in a one-element array; `flush_pending_note` passes the array through `place` to `voice.place` unchanged. `handle_broken_rhythm` only touches `scale`, so broken rhythm beside chords (`[CEG]>[DFA]`) works with no extra code — in scope.
   - Add `when :chord then handle_chord(token)` to the `handle` dispatch (`parser.rb:146-155`). `handle_chord` mirrors `handle_note`: map each `ChordNote` through `state.pitch_builder.pitch(...)` in bracket order (explicit accidentals write `@bar_accidentals`, so an accidental inside a chord persists for the rest of the bar — correct ABC semantics, for free), raise `ParseError` (`Chord pitches must be unique`, token line, bracket snippet) if two inner notes resolve to the same pitch, then set the pending note. The check compares resolved pitches, so `[Cc]` (octaves) and enharmonics like `[^cd]` stay valid.
   - `[C]` parses as an ordinary single-note placement (`note?` true, `chord?` false).
   - Files: `lib/head_music/notation/abc/parser.rb`, `spec/head_music/notation/abc/parser_spec.rb` (remove the "a chord" row from the unsupported table near line 377; replace the `[CEG]` lexeme used by the late-body test near line 407 with another unsupported construct such as `{g}`; add a chord block asserting the story's chorale example verbatim).

3. **Writer: replace the chord guard with bracket emission**

   - In `#token` (`writer.rb:122-130`): keep `ensure_pitched_sounds` first (the unpitched `RenderError` guard at 132-138 is untouched), delete the line-124 chord guard, and add a chord branch: `"[#{placement.pitches.sort.map { |pitch| pitch_writer.token(pitch) }.join}]#{multiplier}"`. Sorting low-to-high and feeding the oracle in that same emission order keeps `PitchWriter`'s load-bearing bar-accidental state exactly mirroring what a re-parse accumulates — one loop serves both emission and oracle commitment so they cannot diverge.
   - Files: `lib/head_music/notation/abc/writer.rb`, `spec/head_music/notation/abc/writer_spec.rb` (flip the two chord `RenderError` contexts near lines 221-247 to emission assertions; leave the unpitched contexts near 249-277 untouched; add chord cases to the "round trips" block near line 294).

4. **Round-trip helper: compare full pitch sets**

   - `spec/support/abc_round_trip.rb` (line 28) compares placements via `#pitch` (top pitch only); switch to sorted `pitches` strings — backward compatible (one-element arrays for notes, empty for rests). Add a chorale-style chord fixture with accidentals to the writer's round-trip specs.
   - Files: `spec/support/abc_round_trip.rb`.

5. **Polish and verification**

   - `bundle exec rubocop -a`, then full `bundle exec rake` (90% coverage floor).

### Decisions

1. **Token design — one `:chord` token**, not `chord_start`/`chord_end` framing (specialists split; resolved for the single token). The parser's dispatch and `PendingNote` machinery assume one token per placeable event; framing tokens would push per-note-duration rejection, in-chord guarding of rest/bar/voice tokens, and dangling-bracket detection into new parser state. Trade-off: the lexer gains one structured field on the deliberately flat `Token`, which is cheaper than a parser mode.
2. **Accidentals and durations** flow through the existing seams unchanged: sequential `pitch_builder.pitch` calls give bar-persistent accidentals (spec `[^FA] F` → both F sharp), and the outer suffix goes through `duration_resolver.rhythmic_value` exactly like a note length. **Broken rhythm next to chords is in scope** (free via the `:pitches` generalization).
3. **Per-note durations rejected in the lexer**, which owns line/column/snippet context and has raising precedent (`volta_token`, `raise_unexpected_character`). Message includes the remedy inline (see Step 1).
4. **Duplicate pitches raise `ParseError`** (specialists split 2–2; resolved for raise). `Placement` dedups via `uniq` (`placement.rb:130`), so `[CC]` would silently collapse to a non-chord and could never round-trip; silent data loss contradicts the subsystem's fail-fast character ("Volta passes must be unique" precedent). Trade-off: ABC parsing becomes stricter than `Voice#place([C4, C4])`, which is acceptable because the API's dedup is idempotent-merge semantics while parse-time collapse loses author intent.
5. **Stays `:unsupported`** (→ `UnsupportedFeatureError`, matching single-note handling): ties/slurs/graces/decorations adjacent to chords lex as their own tokens unchanged; any non-note character inside brackets makes the whole group one `:unsupported` token; quoted `"Am"` untouched.
6. **Writer emits pitches sorted low-to-high** — merged placements have arbitrary insertion order, so sorting is the only deterministic choice, and it matches the low-to-high convention in the MusicXML Chord Rendering backlog story. `[GEC]` re-emits as `[CEG]`; the content model has no note-order semantics.
7. **Round-trip asserts parse → write → parse placement equivalence** via the extended `expect_abc_round_trip` helper (order-insensitive pitch comparison), not raw `to_h` equality, which is fragile to rhythmic-value spellings and input pitch order.
8. **Spec inventory** (all flips confirmed by grep; nothing outside the ABC subsystem references chord parsing): `body_lexer_spec.rb:~211`, `parser_spec.rb:~377` and `~407`, `writer_spec.rb:~221-247`, `spec/support/abc_round_trip.rb:28`.

### Testing Strategy

- **Lexer**: token structure, accidental-leading chords, outer length, `[C]`, the four-way `[` disambiguation pins (`[|`, `[1`, `[K:G]`, chord), errors (per-note duration, unterminated, `[]`), tie-inside-bracket unsupported.
- **Parser**: the story's chorale example verbatim (positions and pitch arrays); `chord?` and shared rhythmic value; accidental persistence after a chord and reset at the bar line; broken rhythm around chords; duplicate-pitch `ParseError` (and `[Cc]`/enharmonic validity); inline fields still `UnsupportedFeatureError`; chords in multi-voice bodies.
- **Writer and round-trip**: bracket emission with duration suffix; accidentals inside emitted chords updating bar state for later notes; parse → write → parse equivalence including a chord fixture; existing fixtures as regression.
- Error messages asserted by exact text (tests-as-documentation).

### Risks & Open Questions

- **Unterminated `[CEG` changes error class** from `UnsupportedFeatureError` to `ParseError` — correct (malformed syntax of a now-supported feature) but a behavior change for invalid input; pinned by spec.
- **`ParseError` has no `column:` kwarg and never folds `snippet` into its message** (`lib/head_music/notation/abc.rb:22-27`) — the new messages are written to be self-sufficient without it. Widening `ParseError` to include column/snippet would help all errors but touches existing message-asserting specs; deferred to its own small story.
- **Pre-existing gap**: `DurationResolver#raise_error` passes no `line_number:` (`duration_resolver.rb:106-108`), so `[CEG]0` raises without a line. Optional in-story fix: rescue-and-re-raise in `Parser#place` with the token's line; otherwise note and defer.
- ~~**Uniform inner durations `[C2E2G2]`** rejected in v1~~ — superseded by the Amendment below.
- **`PendingNote` field rename** touches `handle_note`, `flush_pending_note`, and `handle_broken_rhythm` (`pending_note.with(scale:)` is field-agnostic); it is private with no spec coupling — do it as one atomic change.
- The duplicate-pitch decision (raise) and single-note-bracket normalization (`[C]` re-emits unbracketed) are judgment calls made by the planner; flag before implementation if either should go the other way.

### Amendment (2026-07-18): uniform inner lengths

After the first review, we checked ABC 2.1 §4.17 directly: inner length modifiers are legal ("All the notes within a chord should normally have the same length, but if not, the chord duration is that of the first note") and inner × outer modifiers multiply ("[C2E2G2]3 has the same meaning as [CEG]6"). The v1 blanket rejection refused conforming input, so the story is amended: accept uniform inner lengths, reject unequal ones.

- Lexer: `ChordNote` gains a `length` field; `scan_chord` scans each inner note's optional `[\d/]*` suffix instead of raising on it. The per-note-duration `ParseError` moves to the parser, where uniformity is a semantic question.
- Parser: `handle_chord` compares inner lengths as parsed fractions (so `[C4/2E2G2]` counts as uniform with `2`), treating a missing inner length as 1. Unequal → `ParseError` with a message stating the rule and both accepted spellings. Uniform → effective length = inner fraction × outer fraction, fed through the same duration seam as before.
- Writer: unchanged — emission stays canonical (`[CEG]2` form, never inner lengths), so `[C2E2G2]` normalizes on round-trip like `[GEC]` does.
- The Review section's addendum below covers re-verification.

## Review

Reviewed 2026-07-18 at commit `77d128c` (base of `story/abc-chord-input`); **all reviewed changes were uncommitted working-tree changes** on that branch. Reviewers: product-manager (empirical acceptance-criteria verification) and code-reviewer (full-diff quality review with empirical probes). Full suite: 5824 examples, 0 failures; 99.76% line coverage; rubocop clean (431 files).

### Acceptance criteria

- ✅ **`ABC.parse` reads `[CEG]` chords** — chorale example verified verbatim: one all-pitched placement per bracket group, `chord?` true, shared rhythmic value; pinned by the parser spec's story-example block.
- ✅ **Duration suffix applies to the whole chord** — `[CEG]2`/`[EGC']4` yield half/whole; slash lengths (`[CEG]/`) pinned.
- ✅ **Per-note durations raise ParseError** — `[C2EG]` → `Chord notes cannot have individual lengths; write the length after the bracket, e.g. "[CEG]2" (line N)`; exact-message pin.
- ✅ **Inline fields not confused with chords** — `[K:G]`/`[M:3/4]` still `UnsupportedFeatureError`; `[|` bar line and `[1` volta unchanged; four-way disambiguation pinned.
- ✅ **`#to_abc` emits bracket chords; round-trips** — guard deleted, `chord_token` emits sorted low-to-high; chorale renders `[CEG]4 [DFA]4|[C,EG]8|]` and re-parses to identical pitch sets; accidental-chord and scrambled-order fixtures pinned.
- ✅ **Unpitched RenderError guard unchanged** — byte-identical to main, still first in `#token`; unpitched and mixed placements still raise; pre-existing specs untouched.
- ✅ **Rubocop and all specs pass** — see counts above.

### Scope/Decision probes — all verified

`[^CEG]` accidental-first chords (a fixed gap from main); accidental persistence within the bar and reset at bar lines; broken rhythm `[CEG]>[DFA]`; duplicate rejection (`[CEC]` raises) with `[Cc]` octaves and `[^C_D]` enharmonics valid; `[C]` → plain note, re-emits unbracketed; ties/decorations inside brackets fall back to `UnsupportedFeatureError`; quoted `"Am"` untouched; round-trip helper compares full sorted pitch sets.

### Code review findings

No blocking, should-fix, or reportable nit findings. The crux concern — whether sorted emission keeps the writer's bar-accidental oracle consistent with re-parse order — was traced and empirically confirmed safe: `PitchBuilder` keys bar accidentals by `[letter_name, octave]`, so a lower pitch's accidental cannot bleed into a higher same-letter pitch; the worst case (C4/G♯4/G5 → `[C^Gg]`) round-trips exactly. Lexer rewind paths, `[` disambiguation ordering, and the outer-length regex were probed clean (the regex's tolerance of `3/2`/`//` is identical to single-note handling — consistent, not a regression). The old chord guard is fully removed with no stale references.

Minor notes, non-blocking:

1. Multi-voice chords work (verified empirically) but are unpinned — the plan's testing strategy listed them; a small spec could be added later.
2. `[CEG]0` raises without a line number — pre-existing `DurationResolver` gap shared with single notes (`C0`), deferred per the plan's Risks.
3. Uniform inner durations (`[C2E2G2]`) rejected in v1 as decided; possible sugar follow-up.

### Verdict

**Ready to commit and finish.** Both reviewers independently reached the same conclusion; every acceptance criterion has both spec pinning and live-behavior confirmation.

### Addendum (2026-07-18): uniform inner lengths implemented

The uniform-inner-length amendment (above) was implemented after the review, directly rather than via agents:

- `body_lexer.rb`: `ChordNote` gained a `length` field; `CHORD_NOTE_PATTERN` captures each note's `[\d/]*` suffix; the lexer-side per-note-length `ParseError` was removed (the lexer now records inner lengths verbatim).
- `duration_resolver.rb`: added a public `length_fraction(string)` returning a length string's bare fraction (`""` → 1), reused for uniformity comparison.
- `parser.rb`: `uniform_chord_length` compares inner lengths as reduced fractions (so `[C4/2E2G2]` counts as uniform) and returns the shared fraction; `defer_placement` folds it into `scale`, which composes multiplicatively with the outer length and any broken-rhythm scale (`unit × outer × inner × broken`, order-independent). Unequal lengths raise `Chord notes must share one length; write it after the bracket ("[CEG]2") or repeat it on every note ("[C2E2G2]")`.
- Writer unchanged: emission stays canonical, so `[C2E2G2]` normalizes to the outer-length form on round-trip.

Verified: `[C2E2G2]` ≡ `[CEG]2`; `[C2E2G2]3` ≡ `[CEG]6` (the standard's example); `[C4/2E2G2]` uniform; broken rhythm composes correctly; `[C2EG]` and `[C2E2G4]` raise. Full suite 5831 examples, 0 failures, 99.76% line coverage; rubocop clean. New specs: lexer captures per-note lengths (uniform and uneven); parser reads uniform lengths, multiplies inner × outer, treats `4/2`≡`2` as uniform, and rejects unequal; writer round-trips and normalizes a uniform-inner-length fixture.
