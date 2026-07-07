<!--
metadata:
  created_at:   2026-07-06T15:46:51-07:00
  activated_at: 2026-07-06T15:59:05-07:00
  planned_at:   2026-07-06T16:11:07-07:00
  finished_at:
  updated_at:   2026-07-06T17:32:41-07:00
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

### Overview

Add a writer side to `HeadMusic::Notation::ABC` that mirrors the parser's facade-plus-small-helpers shape: `ABC.render(composition)` backed by a `Writer` orchestrator plus `PitchWriter` and `DurationWriter` collaborators, with `Composition#to_abc` as a one-line delegate. Parse/render agreement is achieved by construction — the writer reuses the parser's own maps and, for accidentals, consults a live `PitchBuilder` instance as an oracle — and is locked in by round-trip specs over the existing interpreter fixtures.

### Resolved Design Decisions

1. **Entry point**: `HeadMusic::Notation::ABC.render(composition, **options)` → `Writer.new(composition, **options).to_s`; `Composition#to_abc(**options)` delegates (constant resolves at call time, so no load-order issue — `lib/head_music.rb` requires content before notation, but only method bodies reference the Notation constant). This is the precedent the backlog MusicXML story should copy (`Notation::MusicXML.render` + `#to_musicxml`); update that story file to record it.
2. **Error class**: new `HeadMusic::Notation::RenderError < StandardError` beside `ParseError` in `lib/head_music/notation.rb`, with `ABC::RenderError < Notation::RenderError` in `lib/head_music/notation/abc.rb`. Do **not** reuse `UnsupportedFeatureError` — it subclasses `ParseError`, so callers rescuing `Notation::ParseError` around parse code would swallow export failures.
3. **`L:` policy**: fixed `L:1/8`, always emitted explicitly. Every binary rhythmic value is expressible as an `n` or `n/d` multiplier of 1/8, and an explicit field avoids depending on the meter-conditional default in `header.rb`. Deriving `L:` from note content is deferred as an optimization.
4. **Accidental policy**: bar-persistent minimal marking, honoring the model's spelling (never respell). `PitchWriter` owns a `PitchBuilder` instance as an oracle: for each note it computes letter + octave marks, asks the builder what an *unmarked* note would parse to given current bar state and key signature, emits a mark only on mismatch (via `PitchBuilder::ACCIDENTAL_FRAGMENTS.invert`, which cleanly yields `"#"→"^"`, `""→"="`, `"x"→"^^"`, `"bb"→"__"`), then feeds the emitted token back through the builder to update bar state; `start_new_bar` at each barline, exactly as `Parser#handle_bar_line` does. This makes re-parse-identity true by construction, including the killer case `^F … =F` in one bar.
5. **Tied-value chains**: collapse to a single multiplier token rather than raise. `DurationResolver` itself *produces* `tied_value` chains from single tokens like `A5` (5/8 of a whole note), so summing the chain's Rational total and emitting one multiplier round-trips to an identical chain. Guard: raise `ABC::RenderError` when the total isn't a power-of-two fraction within `DurationResolver::MAX_FRACTION`. (Emitting `-` ties was rejected: the lexer treats `-` as unsupported, which would break the round trip in the other direction.)
6. **Duration math**: compute fractions as Rationals forward from `unit` + `dots` + tied chain (small `RhythmicUnit#fraction` helper returning `Rational(numerator, denominator)`), never from the Float `relative_value`/`total_value`. Multiplier formatting: `""` for 1, `"n"` for integers, `"n/d"` otherwise — all forms `DurationResolver::MULTIPLIER_PATTERN` accepts.
7. **Line wrapping**: 4 bars per line, tokens space-separated within a bar, `|` between bars, `|]` terminating the tune (already in `Parser::SECTION_ENDING_STYLES`). Deterministic and matches the fixture style in `spec/head_music/notation/abc_spec.rb`.
8. **`X:`**: emit `X:1` by default; accept an optional `reference_number:` keyword. No model change — `Composition` has no reference-number attribute and the parser discards `X:` anyway, so nothing round-trips through it. Exclude `X:` from equivalence assertions.
9. **Fail before emitting**: mirror the parser's fail-before-building contract — `Writer` validates the whole composition up front (multi-voice, mid-piece changes, gaps, unrepresentable durations) and raises `RenderError` naming the feature, so callers never receive a truncated ABC string.

### Steps

1. **Error classes**
   - Add `HeadMusic::Notation::RenderError` to `lib/head_music/notation.rb`; add `ABC::RenderError` to `lib/head_music/notation/abc.rb`.
   - Extend the error-hierarchy examples in `spec/head_music/notation/abc_spec.rb`.
   - Files: `lib/head_music/notation.rb`, `lib/head_music/notation/abc.rb`

2. **`DurationWriter`**
   - `#multiplier_string(rhythmic_value)` using Rational math per decisions 5–6; raises `RenderError` for non-power-of-two or oversized fractions. (Filename `duration_writer.rb` sorts after `duration_resolver.rb`, preserving the helpers' load-order convention; keep cross-references runtime-only regardless.)
   - Files: `lib/head_music/notation/abc/duration_writer.rb`, `spec/head_music/notation/abc/duration_writer_spec.rb`

3. **`PitchWriter`**
   - Constructor takes a key signature; exposes `#token(pitch)` and `#start_new_bar`. Octave marks invert `PitchBuilder#octave_for`: register ≥ 5 → lowercase + `"'" * (register − 5)`; register ≤ 4 → uppercase + `"," * (4 − register)`. Accidentals via the PitchBuilder-oracle approach (decision 4); memoize `ACCIDENTAL_FRAGMENTS.invert` in a method, not at class-body load time.
   - Files: `lib/head_music/notation/abc/pitch_writer.rb`, `spec/head_music/notation/abc/pitch_writer_spec.rb`

4. **`K:` inversion in `KeyMapper`**
   - Add `KeyMapper.abc_value(key_signature)` with an explicit `ABC_SUFFIXES_BY_MODE` map (`"major" => ""`, `"minor" => "m"`, `"dorian" => "dor"`, …) — `MODE_NAMES_BY_PREFIX` is many-to-one and cannot be mechanically inverted. Tonic from `letter_name` + `alteration&.ascii` — **not** `tonic_spelling.to_s`, which returns Unicode (`"F♯"`) that the `K:` pattern rejects. Raise `RenderError` for double-altered tonics and unmapped scale types.
   - Files: `lib/head_music/notation/abc/key_mapper.rb`, `spec/head_music/notation/abc/key_mapper_spec.rb`

5. **`Writer` + `ABC.render`**
   - Up-front validation (decision 9), then header (`X:`, `T:` from `name` — never nil, defaults to `"Composition"`; `C:` when `composer` present; `O:` when `origin` present — `Header` already parses both, and omitting them would lose metadata on round trip; `M:` via `Meter#to_s` (`"4/4"`); `L:1/8`; `K:` last, as the parser requires). Body: walk `voices.first.placements` (already sorted), group by `position.bar_number`, notes → `PitchWriter#token` + multiplier, rests → `"z"` + multiplier, `start_new_bar` per bar, wrap per decision 7. String building is a token array + `join`.
   - Files: `lib/head_music/notation/abc/writer.rb`, `lib/head_music/notation/abc.rb`, `spec/head_music/notation/abc/writer_spec.rb`

6. **`Composition#to_abc`**
   - One-line delegate with opaque `**options` pass-through so `Composition` stays format-ignorant; option vocabulary lives with `ABC.render`.
   - Files: `lib/head_music/content/composition.rb`, `spec/head_music/content/composition_spec.rb`

7. **Round-trip specs, shared fixtures, lint**
   - Extract the ABC example tunes currently inlined in parser specs into shared fixtures under `spec/support/` so parser and writer exercise the identical corpus; add the equivalence helper (below); run `bundle exec rubocop -a`.
   - Files: `spec/support/` (fixtures + helper), `spec/head_music/notation/abc/writer_spec.rb`

### Reuse & Parse/Render Agreement

- **Shared directly**: `PitchBuilder::ACCIDENTAL_FRAGMENTS` (injective — invert it), the `PitchBuilder` instance itself as the accidental-state oracle, `DurationResolver::MULTIPLIER_PATTERN`/`MAX_FRACTION` as the writer's output contract.
- **New writer-side, spec-guarded**: `ABC_SUFFIXES_BY_MODE` in `KeyMapper` (the prefix map is non-invertible); octave-mark emission (trivial inverse of `octave_for`).
- **Deliberately not inverted**: `DurationResolver`'s greedy decomposition — the writer works forward from unit + dots, which is simpler and exact.
- **Agreement mechanism**: oracle reuse makes accidentals correct by construction; everything else is held together by two spec properties — semantic round trip and string fixpoint (`render(parse(render(c))) == render(c)`), the latter catching normalization drift cheaply.

### Edge Cases

- **Note outside the key** (F♮ in G major): oracle mismatch → emit `=`. **Same-bar cancellation** (`^F … F♮`): bar state holds sharp → emit `=` on the second note; the state comparison handles returning to key defaults automatically.
- **Double sharps/flats**: `"x"→"^^"`, `"bb"→"__"` via the inverted map; explicit spec case.
- **Tied chains**: collapsed to one multiplier token (decision 5); `RenderError` when uncollapsible.
- **Gaps between placements**: strict — require each placement at `previous.next_position` (and the first at count 1, tick 0); otherwise `RenderError` with "insert explicit rests." (Strict-raise chosen for v1 as simpler and explicit — relax later to auto-fill with `z` if callers hit it. Logged as an open question.)
- **Pickup / first bar ≠ 1 / notes crossing barlines**: notes stay in their starting bar; barlines may land differently than a hand-written anacrusis source, but placement-level equivalence (pitches, durations, positions) survives the round trip — note this in specs.
- **Multi-voice**: `voices.length > 1` → `RenderError` ("multi-voice ABC output is not supported"). Zero voices/empty voice → header plus empty body, which re-parses to an empty default voice — asserted by the first, simplest spec.
- **Mid-piece key/meter changes**: any bar carrying a `meter` or `key_signature` → `RenderError`; inline `[K:]`/`[M:]` wouldn't re-parse anyway.
- **Nil name/meter/key_signature**: impossible — `Composition#ensure_attributes` defaults all three.
- **Repeats/voltas**: parser captures `Bar#starts_repeat` etc.; writer degrades them to plain `|` per story scope — flagged as an open question.

### Testing Strategy

- **Unit, per step**: `duration_writer_spec.rb` (multipliers `""`, `"2"`, `"3"`, `"1/2"`, `"3/2"`, `"5"` from a tied chain, error cases); `pitch_writer_spec.rb` (octave marks across registers 2–7, key-implied omission, `=` cancellation, bar-state reset, `^^`/`__`); `key_mapper_spec.rb` additions (`C`→`"C"`, A minor→`"Am"`, D dorian→`"Ddor"`, F# minor→`"F#m"`, error paths).
- **Integration** (`writer_spec.rb`): the four acceptance tunes — diatonic single voice, accidentals, varied durations + rests — plus the error paths (multi-voice, meter change, gap). Build input compositions via `ABC.parse`.
- **Round trip**: `expect_abc_round_trip(composition)` helper in `spec/support/` — since there is no `Composition#==`, compare `key_signature.name`, `meter.to_s` (Meter memoizes; use `==`/`to_s`, never object identity), `name`, `composer`, and zipped per-placement `[pitch spelling + register, Rational duration total, position.to_s]`. Assert over interpreter fixtures including an accidental-heavy one, plus the string-fixpoint property.

### Beyond the Acceptance Criteria (gaps planning surfaced)

- Multi-voice, mid-piece changes, gaps, and uncollapsible durations all needed defined behavior — resolved as up-front `RenderError` (decisions 5, 9).
- "Equivalent" in the round-trip criterion needed a definition — resolved as spelling-level (not merely enharmonic) pitch equality plus Rational duration, position, key name, meter, and title; `X:` excluded.
- The parse/render asymmetry is real and accepted: the parser reads multi-voice tunes and repeats that the writer will refuse or degrade — `parse(str).to_abc` can raise for valid parser input. Documented via error messages and specs rather than widened scope.
- Bar-persistent accidentals and dotted durations each get explicit spec cases; the criteria's "round trip" alone would not have forced them.
- The MusicXML backlog story should be updated to adopt this entry-point shape and the shared `Notation::RenderError` base.

### Risks & Open Questions

- **Strict gaps vs. `z`-filling**: v1 raises on non-contiguous placements; if real callers (e.g. counterpoint exercises with late voice entries) hit this, auto-filling whole-bar gaps with rests is the natural relaxation.
- **Repeats/voltas degrade to `|`**: acceptable under the story's barline-only scope, but lossy for parsed fixtures containing `|:` `:|` — confirm lossless repeats aren't required before fixtures with repeats are used in fixpoint specs.
- **`T:Composition` for defaulted names**: the plan emits it (simplest; round-trips fine). If the placeholder title is unwanted in output, omitting `T:` when the name equals the default is a one-line change — user call.
- **Float `relative_value` remains a latent trap** model-wide; this plan routes around it with Rational math, but a follow-up making `RhythmicValue` fraction-native would harden both sides.

## Review

Reviewed 2026-07-06 at commit `e66e49e` (all implementation changes uncommitted in the working tree at review time). Reviewers: product-manager (acceptance criteria) and code-reviewer (quality), in parallel. Full suite: 5,293 examples, 0 failures; 99.55% line coverage; rubocop clean.

### Acceptance criteria

| # | Criterion | Verdict | Evidence |
|---|---|---|---|
| 1 | `Composition#to_abc` returns valid ABC String | ✅ met | `composition.rb:72-74` delegate → `ABC.render`; composition_spec asserts string, `reference_number:` pass-through, RenderError propagation; validity proven by re-parse specs |
| 2 | Header emits X:/T:/C:/M:/L:/K: | ✅ met | `writer.rb:82-93` (C: only when composer present, `.compact`); asserted in writer_spec golden outputs; K: via `KeyMapper.abc_value` with 10 mapped keys + round-trips in key_mapper_spec |
| 3 | Letters, octave marks, accidentals relative to key | ✅ met | `pitch_writer.rb` oracle design; pitch_writer_spec covers C2–C7, `^`/`_`/`=`, `^^`/`__`, key-implied omission, same-bar persistence, `start_new_bar` reset; Chromatic Air integration spec asserts minimal marks + re-parse spelling equality |
| 4 | Durations relative to L:, rests as `z` | ✅ met | `duration_writer.rb` exact Rational math incl. tied-chain collapse; Rest Study spec asserts `z2`/`z3`/`z6`. Note: fractional multipliers emit `A1/2`, not the `A/2` shorthand — valid ABC, round-trips cleanly |
| 5 | Barlines separate bars; reasonable wrapping | ✅ met | `writer.rb:95-103` — 4 bars/line, `\|]` terminator; Speed the Plough golden output |
| 6 | Round trip asserted by specs | ✅ met | `spec/support/abc_round_trip.rb` helper (key, meter, name, composer, per-placement pitch/position/duration); plus string-fixpoint assertion — stronger than required |
| 7 | Required spec coverage | ✅ met | Diatonic (Speed the Plough), accidentals (Chromatic Air), durations+rests (Rest Study), round trip over shared interpreter fixtures (`spec/support/abc_fixtures.rb`, also used by abc_spec) |

Designed limitations (multi-voice, mid-piece key/meter changes, positional gaps → fail-before-emit `RenderError`; repeats degrade to `|`) are implemented exactly as scoped, each with a spec.

### Code review findings (all advisory; no blockers)

1. **Layering note** — `Composition#to_abc` gives Content a runtime-only reference into Notation::ABC. Thin, tested, no load-time cycle; accepted as the planned convenience delegate.
2. **`PitchWriter#verify_round_trip` is load-bearing** (`pitch_writer.rb:65-69`) — its oracle feedback side effect maintains bar-persistent state; the comment documents this, but a future "cleanup" removing the call would silently break accidentals. Optional rename (e.g. `commit_and_verify`).
3. **`KeyMapper` API asymmetry** — instance-based parse path vs. class-method render path. Stylistic only.
4. **Minor spec gaps** — no integration spec exercises a fractional multiplier inside a full tune body (unit-level only); `PitchWriter`'s RenderError path untested (hard to reach with real pitches). Low risk.
5. **Verified-correct probes** — octave-mark inversion exact across C0–C9; oracle state cannot leak after RenderError; barline-spanning notes round-trip to identical positions; contiguity guard sound (Position counts/ticks always integers).

**Verdict: ready to finish.** Nothing blocks; findings 2 and 4 are optional polish.
