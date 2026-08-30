<!--
metadata:
  created_at:   2026-07-07T11:19:50-07:00
  activated_at: 2026-08-29T18:03:27-07:00
  planned_at:   2026-08-29T18:17:39-07:00
  finished_at:
  updated_at:   2026-08-30T09:45:32-07:00
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

**Entry-point shape — decided** (during planning of the [ABC Notation Export](../done/abc-notation-export.md) story; adopt the same pattern here):

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

### Overview

Add a third exporter mirroring the MusicXML shape — `HeadMusic::Notation::LilyPond.render(composition, **options)` backed by `Writer` + a thin eager `RenderPlan` + stateless `PitchWriter`/`DurationWriter`/`KeyMapper` helpers and a `Preflight`, with `Composition#to_lilypond(**options)` as a one-line delegate. Output is an absolute-pitch, Dutch-note-name, fully compilable `\version`/`\header`/`\score` document; all `RenderError` paths fire before any text is assembled. This story is also the rule-of-three trigger for three small shared extractions (clef selection, preflight checks, tied-chain walking).

### Resolved Design Decisions

1. **Absolute pitch mode, not `\relative`** (unanimous across specialists). Every token is self-contained — stateless to emit (like `MusicXML::PitchWriter`), safe to machine-generate, and self-verifiable for anyone hand-editing the file linearly (including screen-reader users). A `relative:` option is a clean additive follow-up.
2. **Ties: explicit `~` per `tied_value` link; no duration splitting.** Chains arise within a single placement (e.g. 5/8-whole values) and LilyPond accepts `c'2~ c'8` freely; barline-crossing placements are rejected in Preflight (mirroring `music_xml/preflight.rb`'s `ensure_notes_within_barlines`), so bar-aware splitting can never be needed. Rests in a chain emit consecutive untied rests, as MusicXML does.
3. **Clef: range-derived, by extracting the existing selector.** Move `MusicXML::ClefSelector` (zero XML in it — returns a `Rudiment::Clef` from a MIDI-midpoint-vs-middle-C policy, treble for empty voices) to `HeadMusic::Notation::ClefSelector`; duplicating 20 lines risks the same voice getting different clefs from different exporters if either copy drifts. `treble_clef` → `\clef treble`, `bass_clef` → `\clef bass`.
4. **Envelope: always the full document** — `\version "2.24.0"`, `\header`, `\score { << … >> \layout { } }`, trailing newline. Only a complete compilable file satisfies "accepted by a toolchain"; 2.24 is the stable LTS series universally packaged, and everything emitted predates it. No bare-expression mode (no user for it — the `\header` criterion already forces the envelope).
5. **Naming**: constant `HeadMusic::Notation::LilyPond`, so files are `lib/head_music/notation/lily_pond.rb` + `lily_pond/` (standard snake_case of the constant, same convention as `music_xml.rb`/`MusicXML`). Facade requires helpers via `Dir[...].sort.each`, and is required from `lib/head_music/notation.rb`.
6. **Chords are IN scope** (correcting the story's scope list). `Placement#chord?`/`#pitches` exist and both sibling exporters render simultaneous notes; under fail-before-emit, silently dropping pitches is not an available behavior, and `<c' e' g'>4` is trivial. What stays out is LilyPond `\chordmode` (letter-name chord symbols — nothing in the model maps to it).
7. **Lyrics: silently dropped, pinned by a spec.** The music is complete and compilable without them, and a follow-up `\addlyrics` story is purely additive (LilyPond lyric alignment is a separate context with its own semantics, unlike MusicXML's per-note element). Trade-off (lossiness vs raising) flagged under Risks for the owner.
8. **Dutch note names, per the story's own criteria** (`is`/`es`/`isis`/`eses`; the mechanical letter+suffix table yields `aes`/`ees` for A♭/E♭, which LilyPond Dutch accepts — spec these two explicitly). The best-practices suggestion of `\language "english"` is overruled by the story text.
9. **Options posture**: `render`/`to_lilypond` keep the decided `**options` pass-through, but `Writer#initialize` declares no keywords yet — misspelled options raise `ArgumentError` naturally, matching `music_xml.rb`'s "keywords will be added with the first one."

### File Layout

```
lib/head_music/notation/clef_selector.rb          (moved from music_xml/, renamespaced)
lib/head_music/notation/preflight_checks.rb       (new shared mixin, parameterized by render_error_class)
lib/head_music/notation/lily_pond.rb              (facade, .render, RenderError)
lib/head_music/notation/lily_pond/duration_writer.rb
lib/head_music/notation/lily_pond/key_mapper.rb
lib/head_music/notation/lily_pond/pitch_writer.rb
lib/head_music/notation/lily_pond/preflight.rb
lib/head_music/notation/lily_pond/render_plan.rb
lib/head_music/notation/lily_pond/string_text.rb  (escaping helper, analog of xml_text.rb)
lib/head_music/notation/lily_pond/writer.rb
```

Specs mirror one-to-one under `spec/head_music/notation/lily_pond/`, plus `spec/support/lily_pond_helpers.rb`.

### Steps

1. **Shared extractions (run the full suite after each move)**
   - Move `lib/head_music/notation/music_xml/clef_selector.rb` → `lib/head_music/notation/clef_selector.rb`, module `HeadMusic::Notation`, body unchanged; update the one call site in `lib/head_music/notation/music_xml/writer.rb` and move its spec to `spec/head_music/notation/clef_selector_spec.rb`.
   - Extract `HeadMusic::Notation::PreflightChecks` (mixin parameterized by `render_error_class`, following `placement_validation.rb`'s pattern) covering the checks ABC and MusicXML duplicate with byte-identical messages: voice-contiguity via `Voice#first_gap`, first-placement-starts-bar, notes-within-barlines, bar-marker normalization. Migrate `music_xml/preflight.rb` and `abc/writer.rb`'s `validate!` onto it (this deletes code). Fallback: if the ABC migration balloons, land the shared module with MusicXML + LilyPond as consumers and defer the ABC migration with a note.
   - Add `RhythmicValue#tied_chain` (returns the `[self, tied_value, …]` link array — a fact about the rudiment, currently walked separately by both duration writers) with a unit spec.
   - Files: `lib/head_music/notation/clef_selector.rb`, `lib/head_music/notation/preflight_checks.rb`, `lib/head_music/rudiment/rhythmic_value.rb`, `lib/head_music/notation.rb` (requires), touched preflights/specs.

2. **Facade + error class + delegate wiring**
   - `lib/head_music/notation/lily_pond.rb` mirroring `music_xml.rb`: `def self.render(composition, **options) = Writer.new(composition, **options).to_s`; `class RenderError < HeadMusic::Notation::RenderError; end`; `Dir[File.join(__dir__, "lily_pond", "*.rb")].sort.each { |file| require file }`. Add `require "head_music/notation/lily_pond"` to `lib/head_music/notation.rb`.
   - Files: `lib/head_music/notation/lily_pond.rb`, `lib/head_music/notation.rb`, `spec/head_music/notation/lily_pond_spec.rb`

3. **`PitchWriter`** (stateless; parallelizable with steps 4–5 once signatures are pinned)
   - `self.token(pitch)` → e.g. `"cis''"`. Letter from `pitch.letter_name.to_s.downcase`; suffix from `pitch.alteration_semitones` (`nil`/`0` → `""`, `1` → `"is"`, `-1` → `"es"`, `2` → `"isis"`, `-2` → `"eses"`, else `RenderError`). Never use `alteration.to_s` (Unicode trap from the ABC story). Expose `self.alteration_suffix(semitones_or_nil)` for KeyMapper reuse.
   - **Octave math (verified)**: this gem's middle C is C4/register 4; LilyPond absolute `c'` is middle C, plain `c` is C3. So marks = `register - 3`: positive → `"'" * marks`, negative → `"," * -marks`. Spot checks: C4 → `c'`, C3 → `c`, E2 → `e,`, C7 → `c''''`.
   - Files: `lib/head_music/notation/lily_pond/pitch_writer.rb`, `spec/head_music/notation/lily_pond/pitch_writer_spec.rb`

4. **`DurationWriter`** (stateless)
   - `self.token(rhythmic_value)` → `"4."`, `"\breve"` etc. for one link (ignores `tied_value`): frozen map on `unit_name` like MusicXML's `TYPES_BY_UNIT_NAME` — `"maxima"→"\maxima"`, `"longa"→"\longa"`, `"double whole"→"\breve"`, `"whole"→"1"` … `"two hundred fifty-sixth"→"256"`; `fetch` with `RenderError` fallback; append `"." * dots`. No Rational math needed — LilyPond durations are symbolic (the only arithmetic anywhere is whole-bar-rest sizing from meter integers).
   - Files: `lib/head_music/notation/lily_pond/duration_writer.rb`, `spec/head_music/notation/lily_pond/duration_writer_spec.rb`

5. **`KeyMapper`** (stateless)
   - `self.token(key_signature)` → `"\key gis \major"`. Tonic from `tonic_spelling`'s letter downcased + `PitchWriter.alteration_suffix`; double-altered tonics are legal LilyPond (`\key gisis \major`) — do not copy ABC's rejection. Mode: the same nine `scale_type.name` keys as `MusicXML::KeyMapper::MODE_NAMES_BY_SCALE_TYPE`, mapped to `\major`/`\minor`/`\ionian`/`\aeolian`/`\dorian`/`\phrygian`/`\lydian`/`\mixolydian`/`\locrian`; anything else → `RenderError`.
   - Files: `lib/head_music/notation/lily_pond/key_mapper.rb`, `spec/head_music/notation/lily_pond/key_mapper_spec.rb`

6. **`Preflight`**
   - `self.check!(composition)`: `ensure_voices` (zero voices → `RenderError`, matching MusicXML), then the shared `PreflightChecks` (marker normalization, contiguity/gaps, notes-within-barlines — the check that makes decision 2 safe), then `ensure_pitched_sounds` for every placement via the existing `PlacementValidation` mixin with `render_error_class` → `LilyPond::RenderError` (run here rather than during assembly, honoring fail-before-emit strictly).
   - Files: `lib/head_music/notation/lily_pond/preflight.rb`, `spec/head_music/notation/lily_pond/preflight_spec.rb`

7. **`RenderPlan`** (a slimmed `MusicXML::RenderPlan` — no divisions, no beams; LilyPond auto-beams)
   - Pinned readers: `bar_numbers` (`earliest_bar_number..latest_bar_number`), `measure_key_changes`/`measure_time_changes` (`bar_numbers.zip(composition.bars)` where the bar carries a marker), `first_measure_key`/`first_measure_meter` (change at first bar || composition default), `effective_meter(bar_number)`, `placements_by_bar(voice)`, `tokens_by_placement`. Constructor eagerly computes all of these so every `RenderError` (unmappable key/duration, triple alteration) fires at construction — the mirrored guarantee of `render_plan.rb`'s `precompute_eager_data`.
   - Token building: rest → `tied_chain.map { "r#{Duration…}" }.join(" ")` (no `~`); single pitch → pitch token per link joined with `"~ "` (`c'2~ c'8`); chord → `<c' e' g'>4` with pitches low-to-high, ties tying the whole chord.
   - Files: `lib/head_music/notation/lily_pond/render_plan.rb`, `spec/head_music/notation/lily_pond/render_plan_spec.rb`

8. **`StringText`** (escaping)
   - `escape(text)` doubles `\` then escapes `"`, for `\header` field values (always emitted quoted). This is a genuine safety surface, not cosmetics: LilyPond embeds executable Scheme, so an unescaped quote in `composition.name` can break out of the string into code that runs at compile time.
   - Files: `lib/head_music/notation/lily_pond/string_text.rb`, `spec/head_music/notation/lily_pond/string_text_spec.rb`

9. **`Writer`**
   - `to_s`: `Preflight.check!` → build `RenderPlan` → assemble a line array, `join("\n") + "\n"` (both existing writers' convention; no heredoc templates). Document shape: `\version "2.24.0"`; `\header { title = "…" composer = "…" }` (composer line omitted when nil; both escaped); `\score { << one staff per voice >> \layout { } }`.
   - Per voice, in `composition.voices` order: `\new Staff \with { instrumentName = "…" } { \new Voice { … } }` (the `\with` block only when `voice.role` is present — parity with MusicXML's part-name and free outline navigation in editors); then `\clef` from `Notation::ClefSelector.for(voice)` (compare against `Clef.get(:treble_clef)`/`(:bass_clef)` identity — the selector only returns those two), `first_measure_key`, `\time top/bottom`.
   - Then **one line per bar** ending in a trailing `|` bar check (unanimous recommendation: compile-time position verification and line-equals-bar navigation): prepend `measure_key_changes[bar]`/`\time` from `measure_time_changes[bar]` when present — **in every voice's stream**, since `\key` is per-staff in a `<< >>` (only `\time` propagates score-wide); skip at the first bar (already emitted). A bar with no placements for a voice (voice ended early) emits `R1*top/bottom` from `effective_meter`. Pickup bars need no `\partial`: Preflight's contiguity guarantees any bar before 1 is written out in full with rests and compiles as an ordinary bar.
   - Files: `lib/head_music/notation/lily_pond/writer.rb`, `spec/head_music/notation/lily_pond/writer_spec.rb`

10. **`Composition#to_lilypond`**
    - One-line delegate beside `to_abc`/`to_musicxml` (`lib/head_music/content/composition.rb` ~line 87): `HeadMusic::Notation::LilyPond.render(self, **options)`.
    - Files: `lib/head_music/content/composition.rb`, `spec/head_music/content/composition_spec.rb`

11. **Verification wiring + polish**
    - Add `spec/support/lily_pond_helpers.rb` (below); amend `user-stories/backlog/lilypond-interpreter.md` with one line: its round-trip specs must consume this story's golden fixtures (retroactively automating toolchain proof). Run `bundle exec rubocop -a` and the full suite; confirm ≥ 90% coverage. Record the one-time manual `lilypond` compile of the golden fixture in the story's Review section.

Steps 3–5 are independent and parallelizable once their signatures (pinned above) are fixed; 6–9 depend on them.

### Output Design & Accessibility

- Absolute pitch mode, one bar per line with trailing `|` bar checks, short lines — each token self-contained and verifiable in isolation; positional mistakes become compile-time errors with bar numbers, the non-visual substitute for glancing at engraved output.
- Full self-contained envelope + trailing newline: compiles as-is in Frescobaldi/lilypond.org; a low-vision user gets large print by adding one `#(set-global-staff-size …)` line.
- `instrumentName` from `voice.role` gives named, findable structures without the name-mangling subproblem of variable extraction (see non-goals).
- `RenderError` messages are complete plain-prose sentences carrying bar numbers and remedies, in the mold of `abc/writer.rb`'s "insert explicit rests to fill gaps" — no caret/column art, no color, accidentals spelled in prose ("F-sharp"), never ♯/♭ glyphs. The fail-before-emit contract is itself the main accessibility win: no truncated document plus vague error to debug non-visually.

### Edge Cases (all with pinned behavior and a spec)

- Extreme registers both directions (`c,,,,` ↔ `c''''`); `isis`/`eses`; `aes`/`ees` spellings; triple alteration → `RenderError`.
- Minor and all seven church modes; harmonic-minor/whole-tone scale types → `RenderError`; double-altered tonic keys allowed.
- Tied chains (5/8-whole → `c'2~ c'8`); rests in chains untied; chord ties tie the whole chord.
- Whole-bar and trailing-bar rests → `R1*n/d` sized by the effective meter, including after a meter change.
- Zero voices → `RenderError` (MusicXML parity); an empty voice → staff with treble clef/key/time and whole-bar rests across the composition's bar range, pinned by the simplest spec.
- Header escaping: title `The "Great" \ Escape` → `title = "The \"Great\" \\ Escape"`; nil composer omits the line; name never nil (Composition defaults it).
- Mid-piece `\key` emitted in every staff at the change bar; `\time` likewise (harmless duplication, score-wide effect).
- Barline-crossing placements and positional gaps → up-front `RenderError` from Preflight.

### Testing Strategy

- **Per-helper unit specs** with the pinned signatures (files listed per step above), mirroring the `music_xml/` spec layout.
- **Writer integration specs** covering the five acceptance scenarios, building inputs the preferred way (`HeadMusic::Notation::ABC.parse` + existing `spec/support/abc_fixtures.rb`): (1) diatonic single voice via `SPEED_THE_PLOUGH`; (2) accidentals via `CHROMATIC_AIR` (also asserts the composer line); (3) rests via `voice.place(position, :quarter)` with nil sound, plus `R1*` padding; (4) multi-voice via two `add_voice`/`place` voices with one low voice asserting `\clef bass` and staff order; (5) mid-piece changes via `change_key_signature(3, "D major")` + `change_meter(3, "3/4")`, asserting the commands land in bar 3's line of **every** voice. Plus tie-chain, escaping, chord, lyrics-dropped, and empty-voice cases.
- **"Valid LilyPond" without a parser or local CLI — three layers**: (1) structural helper assertions on every output (`spec/support/lily_pond_helpers.rb`: balanced `{}`/`<<>>` counts, bar-check count = bar count, every music-expression token matches a note/rest/command shape regex); (2) **one golden exact-document heredoc spec** for a tiny fixture (the `music_xml/writer_spec.rb` precedent) pinning the envelope so drift is reviewed; (3) a guarded integration spec that compiles the golden fixture with `lilypond` **only when the binary is on PATH** and `skip`s otherwise — asserting exit status only, never stdout/stderr text (project rule). One manual compile recorded in the story Review, and the interpreter backlog story amended to adopt the golden fixtures for future automated round-trips.

### Explicit Non-goals (each with its reason)

- **Lyrics** (`Placement#syllables` exists): dropped in v1 with a spec pinning the lossiness — `\addlyrics` is a separate context with its own alignment semantics, and adding it later changes no v1 output.
- **`\chordmode` chord symbols**: nothing in the model maps to letter-name chord symbols. (Simultaneous-note chords are *in* scope — decision 6.)
- **Repeats/voltas**: degrade to plain barlines, matching ABC's documented stance; lossless repeats deserve one cross-format story rather than three divergent v1s.
- **Manual beaming**: LilyPond's auto-beamer is meter-correct; emitting `[ ]` would fight the engraver for zero acceptance-criteria gain.
- **Named music variables** (`cantusFirmus = {…}`): requires deterministic identifier mangling (letters-only, collision handling) for modest gain; `instrumentName` delivers the navigation benefit without it.
- **`\midi { }`**, **`origin`/extra header fields**, **`\relative` option**, **`\partial`**: respectively — doubles compile work with no criterion behind it; LilyPond has no standard origin field and custom fields don't print; additive later; unnecessary because contiguity forces pickups to be written out in full.
- **Unpitched/percussion**: rejected via the shared mixin like both siblings — `\drummode` is a different pitch language entirely.
- **A LilyPond parser / true round-trip**: parsing a Scheme-embedded language is a different order of work; the three-layer verification plus the interpreter-story fixture handoff substitutes.

### Risks & Open Questions

**Owner confirmed (2026-08-29):** chords render as simultaneous-note chords; lyrics drop silently (spec-pinned); the guarded lilypond shell-out spec is in; ABC migrates onto the shared PreflightChecks mixin in Step 1 (no deferral).

- **Chords-in-scope is a correction to the story text** — the story listed "chord mode" out of scope, which is right, but simultaneous notes (`Placement#chord?`) must render or raise; this plan renders them. Confirm the owner agrees with the widened reading.
- **Lyrics: drop vs raise** — plan drops silently (spec-pinned). If lossless-or-error is preferred, switching to a Preflight `RenderError` is a three-line change.
- **Guarded `lilypond` shell-out spec** — skips when the binary is absent, so CI stays deterministic; if the maintainer wants zero shell-outs in the suite, demote it to a documented manual step and rely on layers 1–2.
- **Shared-extraction scope** (Step 1) — migrating ABC's `validate!` onto `PreflightChecks` deletes duplicated code but widens the diff; the fallback (share between MusicXML + LilyPond only, defer ABC) is pre-authorized in the step.
- **`\version "2.24.0"` pin** — lives in one Writer constant; the golden spec and guarded compile are the tripwires if a future LilyPond deprecates anything emitted.
- **`ClefSelector` move** is a minor internal breaking change (`MusicXML::ClefSelector` ceases to exist; one in-repo call site); a one-line alias inside the MusicXML module is available if zero breakage is wanted.
- **Golden-spec brittleness**: any formatting tweak rewrites the golden document — accepted, same trade MusicXML made.

## Review

Reviewed 2026-08-30 at commit `eb67b40` plus the uncommitted working tree (all implementation changes were uncommitted at review time). Product-manager and code-reviewer agents ran in parallel; the code reviewer compiled seven rendered documents through the installed `lilypond` 2.24 binary, and the two verification-sensitive findings below were independently re-confirmed against the code.

### Acceptance criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | `#to_lilypond` returns valid LilyPond source | ✅ (with the ragged-voice caveat in finding 1) | Delegate at `lib/head_music/content/composition.rb:91`; fail-before-emit traced through `Writer#to_s` |
| 2 | `\header` with title, composer when present | ✅ | `Writer#header_lines` + `StringText.escape`; escaping specs |
| 3 | One stream per voice, ordering/bars intact | ✅ | One `\new Staff`/`\new Voice` per voice in order; bar-check lines; specs pin note order and staff order |
| 4 | Pitch spelling and octave marks | ✅ | `pitch_writer.rb`; table specs C4→`c'` … B0→`b,,,`, `aes'`/`ees''`, `cisis'`/`feses`; compiled clean |
| 5 | Durations, dots, tied chains | ✅ | Symbolic map + `tied_chain` join with `~`; `c'2~ c'8` and chord-tie specs |
| 6 | Rests | ✅ | `r` tokens, untied chains, `R1*n/d` fills |
| 7 | First-measure `\key`/`\time`/clef; mid-piece changes at their bar | ✅ | Emitted per staff (correct, `\key` is per-staff in `<< >>`); specs assert exactly two bar-3 change lines |
| 8 | Accepted by a LilyPond toolchain | ✅ | Guarded compile spec ran for real (lilypond on PATH) and passed; owner also compiled `chromatic_air.ly` manually on 2026-08-30 — the one-time manual compile the plan's Step 11 called for |
| 9 | The five spec scenarios | ✅ | All five in `writer_spec.rb`, plus empty-voice, escaping, lyrics-drop, no-role, zero-voices, golden document |

### Code review findings

**1. Important — a voice ending mid-bar emits an under-filled bar that LilyPond rejects at the bar check.** `writer.rb` `bar_tokens` substitutes `R1*n/d` only for bars with *no* placements; a bar with some placements that don't fill it emits a short line (`c4 |` in 4/4), and `PreflightChecks#ensure_contiguous_voices` checks leading/interior gaps only, never trailing fill. Reproduced and compile-verified (bar check fails, staves desync). MusicXML shares the hole silently; LilyPond's `|` turns it into a compile failure. Fix: pad the trailing remainder with rests in `bar_tokens`, or reject trailing gaps in Preflight. **Blocks finish.**

**2. Important — `normalize_bar_markers` is dead code with a false "why" comment, pinned by two vacuous specs.** `Bar#key_signature=`/`#meter=` are coercing writers (`bar.rb:20-26`, verified), so the mixin's comment ("Bar's accessors are bare attr_accessors") is wrong and the two "coerces … in place" specs in `lily_pond/preflight_spec.rb` (and their MusicXML precedent) pass with the method deleted. Either delete the method + specs, or keep it as a deliberate defensive guarantee with an honest comment. Confirmed independently.

**3. Important — the structural spec helper cannot detect finding 1.** `lily_pond_helpers.rb` checks balance, line counts, and token shape but not that durations sum to the effective meter — the exact invariant `|` asserts. Add a duration-sum check, and/or route the multi-voice/meter-change/empty-voice fixtures through `compile_quietly` (currently only the golden fixture compiles).

**Minor/advisory:** memoize `RenderPlan#bar_numbers` (rebuilt per bar in `writer.rb:103`); key/meter changes recorded past `latest_bar_number` are silently dropped (defensible, but silent); `**options` forwards into a `Writer#initialize` that takes none, giving an uninformative arity error (`MusicXML.render` takes no `**options` at all); strengthen the lyrics-drop spec to pin the surviving music (`bar_check_lines == ["c'1 |"]`); `installed_lilypond` should use `ENV.fetch("PATH", "")`.

**Verified correct:** fail-before-emit holds on every path after `Preflight.check!`; escaping order (backslash first) confirmed by execution; octave marks, suffixes, ties, chord ordering, `R1*` sizing, and duplicated per-staff `\key` changes all compile clean; the ABC/MusicXML migration onto `PreflightChecks` is behaviorally equivalent with messages preserved verbatim; no stale `MusicXML::ClefSelector` references; CLAUDE.md spec rules honored.
