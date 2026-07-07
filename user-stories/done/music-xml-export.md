<!--
metadata:
  created_at:   2026-07-06T15:41:38-07:00
  activated_at: 2026-07-07T07:51:41-07:00
  planned_at:   2026-07-07T08:05:52-07:00
  finished_at:
  updated_at:   2026-07-07T09:29:34-07:00
-->

# Story: MusicXML Export

## Summary

AS a developer using HeadMusic

I WANT to render a `HeadMusic::Content::Composition` as a MusicXML document

SO THAT I can hand my compositions to notation editors, engravers, and playback tools that speak the industry-standard interchange format

## Background

[MusicXML](https://www.w3.org/2021/06/musicxml40/) is the de-facto interchange format for Western music notation, readable by Finale, Sibelius, MuseScore, Dorico, and most other scorewriters. It encodes a score as XML: a `<score-partwise>` document with `<part-list>`, one `<part>` per voice, `<measure>` elements, and `<note>` elements carrying `<pitch>` (step/octave/alter), `<duration>`, `<type>`, plus per-measure `<attributes>` for key, time signature, clef, and divisions.

This story renders *outward* (HeadMusic objects → MusicXML text). It is the complement of the inward notation-interpreter stories under the [Notation Module epic](../epics/notation-module.md) — the [ABC Notation interpreter](../done/) and [LilyPond interpreter](lilypond-interpreter.md) both read text *into* the object model via `HeadMusic::Notation::<Format>.parse`. Export is the reverse trip.

`HeadMusic::Content::Composition` already carries everything a basic score needs: `name`, `composer`, `key_signature`, `meter`, `voices` (each with placements of pitched, durationed notes across bars), and per-bar key/meter changes. This story turns that model into a valid MusicXML string.

## Example

```ruby
composition = HeadMusic::Content::Composition.new(
  name: "Exercise",
  key_signature: "G major",
  meter: "4/4"
)
voice = composition.add_voice(role: "Cantus firmus")
# ... voice.place(...) some notes ...

xml = composition.to_musicxml
xml            # => String of well-formed <score-partwise> MusicXML
```

## Acceptance Criteria

- `HeadMusic::Content::Composition#to_musicxml` returns a String containing a well-formed, schema-valid `<score-partwise>` MusicXML document (correct DOCTYPE/version).
- The document carries the composition's identity: `<work-title>` from `name` and `<creator type="composer">` from `composer` when present.
- Each voice becomes a `<part>` (with a matching `<part-list>`/`<score-part>` entry), and each bar becomes a `<measure>`.
- Pitched notes render `<pitch>` with correct `<step>`, `<octave>`, and `<alter>`; each note carries a `<duration>`, `<type>`, and correct `<divisions>`.
- Rests render as `<rest>` notes with the right duration.
- The first measure's `<attributes>` emit the key signature (fifths), time signature (`<beats>`/`<beat-type>`), and a sensible default clef; mid-piece key/meter changes emit new `<attributes>` on the bar where they occur.
- Round-tripping through a MusicXML reader (e.g. MuseScore or an XML-schema validator) accepts the output without errors.
- Specs cover: a single-voice diatonic example, an example with accidentals, an example with rests, a multi-voice example, and a mid-piece key/meter change.

## Notes

**Entry-point shape — decided** (during planning of the [ABC Notation Export](../current/abc-notation-export.md) story; adopt the same pattern here):

- `HeadMusic::Notation::MusicXML.render(composition, **options)` → a `Writer` orchestrator (plus small helper classes, mirroring the ABC module's facade-plus-helpers layout).
- `Composition#to_musicxml(**options)` is a one-line delegate with opaque `**options` pass-through, so `Composition` stays format-ignorant; the option vocabulary lives with `MusicXML.render`.
- Render failures raise a `MusicXML::RenderError` subclassing the shared `HeadMusic::Notation::RenderError` base (introduced by the ABC export story) — not any `ParseError` subclass.
- Mirror the parser-side fail-before-building contract: validate the whole composition up front and raise before emitting, so callers never receive a truncated document.

**Scope.** Start with the subset the object model already expresses cleanly: pitch (step/octave/alter), duration/type, rests, key & time signatures, per-bar key/meter changes, one part per voice, work title and composer. Explicitly out of scope for a first cut (candidates for follow-up stories): beaming, ties/slurs, tuplets, dynamics, articulations, lyrics, multiple staves per part, and MusicXML *import* (the inward direction).

**Open questions for planning.**
- How is `<divisions>` chosen from the model's duration representation, and how do note durations map to `<type>` + `<dot>`?
- Default clef selection — fixed treble, or derived from voice range / instrument if available?
- XML generation approach: Ruby stdlib (`REXML`/`Builder`) vs. hand-built strings — prefer a dependency-free stdlib path if practical.
- `score-partwise` vs. `score-timewise` — `score-partwise` is the near-universal choice; confirm.

## Implementation Plan

### Overview

Render `HeadMusic::Content::Composition` to a `<score-partwise>` MusicXML 4.0 string via `HeadMusic::Notation::MusicXML.render` — a `Writer` orchestrator plus small pinned helpers mirroring `lib/head_music/notation/abc/`, hand-building XML with a single escaping choke point (zero new runtime dependencies), validating the entire composition before emitting a byte, and expanding `tied_value` chains into real `<tie>`d notes.

### Resolved Design Decisions

1. **`<divisions>`: composition-wide LCM, computed with forward Rational math.** One `<divisions>` for the whole piece: LCM of (a) the denominator of every chain element's duration in quarter notes — `Rational(unit.numerator, unit.denominator) * Rational(2**(dots+1) - 1, 2**dots) * 4`, the exact pattern from `lib/head_music/notation/abc/duration_writer.rb` (never `relative_value`/`total_value`, which return Floats) — and (b) `Rational(4 * top_number, bottom_number).denominator` for the base meter plus every `bar.meter` change, so whole-measure rest durations are always integers (a 3/8 bar is 3/2 quarters). A fixed constant like 960 fails integrality for triple-dotted small values; LCM yields the small readable numbers real exporters emit. `<type>` maps directly from `unit.name` via an explicit frozen map ("double whole"→"breve", "longa"→"long", "sixteenth"→"16th", …); `dots` (0–3 in the model) emits that many `<dot/>` elements — no derivation from duration needed.
2. **Clef: derived from voice range, not fixed treble.** `Voice#lowest_pitch`/`#highest_pitch` and `Pitch#midi_note_number` already exist; rule: bass clef when the midpoint of the voice's MIDI range is below 60, else treble; treble for rest-only/empty voices. Returns the existing `HeadMusic::Rudiment::Clef` (`clef.pitch.letter_name` → `<sign>`, `clef.line` → `<line>`). Trade-off vs. fixed treble: ~5 extra lines buys non-absurd rendering of bass-range cantus firmus voices.
3. **XML generation: hand-built strings, no new runtime dependency.** Runtime deps stay activesupport/humanize/i18n. REXML is a bundled (not default) gem in Ruby 3.3+, so runtime use would require declaring it; Builder is an unnecessary dep for a fixed-shape tree. The only free-text fields are `name`, `composer`, and part-name (voice `role`): all text nodes go through one private `escape(text)` helper — a frozen 5-entity gsub map (`& < > " '`) — so raw interpolation never appears in emit code.
4. **`score-partwise` confirmed.** The model is voice-major (`voices[n].placements`), mapping 1:1 to partwise parts; timewise would be a pointless transpose. Emit `<?xml version="1.0" encoding="UTF-8"?>` (no `standalone`) + the standard partwise 4.0 PUBLIC DOCTYPE, pinned by one exact-string spec.
5. **`tied_value` chains: emit real tied notes.** Each chain element becomes its own `<note>` with the placement's pitch; element *i* gets `<tie type="start"/>` unless last, `<tie type="stop"/>` unless first (middles get both), mirrored by `<notations><tied/>`. Rest chains emit consecutive `<rest/>` notes with no ties. Divergence from ABC's collapse-to-one-multiplier is deliberate; validation runs **per chain link** (each link's unit/dots must be independently renderable), not per summed fraction.
6. **Spec validation: layered, no XSD.** (a) One small canonical score pinned by exact-string heredoc (declaration/DOCTYPE/formatting); (b) REXML well-formedness parse + XPath structural assertions everywhere else; (c) cross-format consistency against ABC fixtures. XSD validation would need nokogiri plus the vendored multi-file schema — poor cost/benefit; MuseScore import is a one-time manual verification recorded in the story review, not a spec. `rexml` becomes an explicit development dependency.
7. **Gaps and uneven voices: raise on internal gaps, pad missing measures.** Internal gaps within a voice raise `RenderError` with ABC's "insert explicit rests" guidance (per-voice, unlike ABC's first-voice-only check); a voice's first placement must start its bar. But leading/trailing whole missing measures (a voice entering late or ending early) are padded with whole-measure rests (`<rest measure="yes"/>` sized to `meter_at(n)`), so every part spans `earliest_bar_number..latest_bar_number` — readers expect equal measure counts across parts.
8. **Barline-crossing placements: raise for v1.** `Position#+` can roll a duration past its barline; MusicXML cannot represent an overfull measure. `validate!` computes cumulative Rational offsets against bar capacity and raises `RenderError` naming the position. Split-and-tie across the barline is the natural follow-up story; raising keeps v1's tie logic confined to `tied_value` chains.
9. **Key mapping: emit `<fifths>` = `num_sharps - num_flats` even beyond ±7** (G♯ major → 8 is schema-valid; some readers render theoretical keys oddly — accepted, documented in a spec). `<mode>` from `scale_type.name` via explicit map (major/ionian, minor/aeolian, dorian, phrygian, lydian, mixolydian, locrian); anything else (harmonic_minor, whole_tone, …) raises `RenderError`, mirroring `abc/key_mapper.rb`.
10. **Metadata:** always emit `<work><work-title>` (`name` is never nil — `Composition#ensure_attributes` defaults it); `<creator type="composer">` only when `composer` present; add `<identification><encoding><software>head_music X.Y.Z</software>` (one line, provenance for free; omit `<encoding-date>` so golden fixtures stay deterministic). `origin` is deliberately dropped in v1.
11. **Options:** ABC's exact shape — facade passes `**options` opaquely; `Writer` declares explicit keyword parameters, so typo'd options raise `ArgumentError` for free. No allowlist code.
12. **Naming:** module `HeadMusic::Notation::MusicXML`, snake_case files `music_xml.rb` / `music_xml/`. Notation-format precedent is all-caps (`ABC`); requires are manual (no autoloader inflection constraint), and `lib/head_music/notation.rb` already spells it "MusicXML".

### Steps

1. **Facade + wiring**
   - Create `lib/head_music/notation/music_xml.rb` mirroring `abc.rb`: `def self.render(composition, **options) = Writer.new(composition, **options).to_s`; `class RenderError < HeadMusic::Notation::RenderError; end`; trailing `Dir` glob requiring `music_xml/*.rb`.
   - Add `require "head_music/notation/music_xml"` beside the ABC require in `lib/head_music/notation.rb`. No `lib/head_music.rb` change needed.
   - Files: `lib/head_music/notation/music_xml.rb`, `lib/head_music/notation.rb`

2. **`Voice#first_gap` domain query**
   - Add to `Content::Voice`: `def first_gap` → `[expected_position, found_placement]` or nil (the `each_cons(2)` / `next_position` walk from `abc/writer.rb:56-67`, plus first-placement-starts-bar). Each writer raises its own format-specific `RenderError` from it; refactoring the ABC writer onto it is optional and deferred (rule of three for a shared Notation concern).
   - Files: `lib/head_music/content/voice.rb`, `spec/head_music/content/voice_spec.rb`

3. **`KeyMapper`** — class-method helper, pinned contract:
   - `self.fifths(key_signature)` → Integer; `self.mode(key_signature)` → String, raises `MusicXML::RenderError` for unmappable scale types.
   - Files: `lib/head_music/notation/music_xml/key_mapper.rb`

4. **`PitchWriter`** — stateless (MusicXML `<alter>` is absolute; none of ABC's bar-accidental state is needed):
   - `self.attributes(pitch)` → `{step: String ("A".."G"), alter: Integer | nil, octave: Integer}` using `pitch.letter_name.to_s`, `pitch.alteration_semitones` (nil → omit `<alter>`), `pitch.register` (this gem's C4 = middle C matches MusicXML octave numbering).
   - Files: `lib/head_music/notation/music_xml/pitch_writer.rb`

5. **`Divisions`**
   - `self.for(composition)` → Integer ≥ 1: LCM over all chain-element quarter-note denominators (all voices, walking `tied_value` chains) and all meter denominators (base + `bar.meter` markers). Empty composition → 1.
   - Files: `lib/head_music/notation/music_xml/divisions.rb`

6. **`DurationWriter`**
   - `Component = Struct.new(:duration, :type, :dots, :tie_start, :tie_stop, keyword_init: true)`; `initialize(divisions)` (Integer); `components(rhythmic_value)` → `Array<Component>`, validating each chain link, raising `MusicXML::RenderError` for unmappable units; `self.single_quarter_fraction(rhythmic_value)` → Rational (shared with `Divisions`). Frozen `TYPES_BY_UNIT_NAME` map.
   - Files: `lib/head_music/notation/music_xml/duration_writer.rb`

7. **`ClefSelector`**
   - `self.for(voice)` → `HeadMusic::Rudiment::Clef` (`:treble_clef` or `:bass_clef` per MIDI-midpoint rule; treble fallback).
   - Files: `lib/head_music/notation/music_xml/clef_selector.rb`

8. **`Writer`** — orchestrator, `initialize(composition)` (explicit keywords only as options are added), `#to_s`
   - `validate!`: voices present (zero voices → `RenderError`; schema requires ≥1 part); per-voice gap/start checks via `Voice#first_gap`; barline-crossing check (cumulative Rational offset vs `meter_at` bar capacity; `tick` is integer 960/quarter — see `position.rb`); eager dry-runs of `KeyMapper`, `PitchWriter`, `DurationWriter#components` over every key signature and placement so every possible `RenderError` fires before assembly ("callers never receive a truncated document").
   - Then assemble as nested line arrays joined once (ABC's `header_lines + body_lines` pattern): declaration/DOCTYPE → `<work-title>` → `<identification>` (creator when present, encoding/software) → `<part-list>` (`<score-part id="P1">`…, `<part-name>` = escaped `voice.role` or `"Voice N"` — the element is schema-required) → per voice a `<part id="Pn">`: chunk placements by `bar_number` (ABC's `chunk_while`), iterate the full `earliest..latest` bar range; first measure `<attributes>` = divisions/key/time/clef, later measures emit `<attributes>` with only the changed element when `composition.bars[n]` carries a marker — **repeated in every part**; empty bars → whole-measure rest; per placement, `DurationWriter#components` × `PitchWriter.attributes`, tie elements suppressed for rests. Schema-mandated `<note>` child order: pitch-or-rest, `<duration>`, `<tie>`, `<type>`, `<dot>`s, `<notations><tied/>`. Measures numbered from `earliest_bar_number`; bars < 1 get `number="0" implicit="yes"` (pickup convention). Private `escape(text)` choke point.
   - Files: `lib/head_music/notation/music_xml/writer.rb`

9. **Composition delegate + gemspec**
   - `def to_musicxml(**options) = HeadMusic::Notation::MusicXML.render(self, **options)` after `#to_abc` (`lib/head_music/content/composition.rb:72`).
   - `spec.add_development_dependency "rexml", "~> 3.4"` in `head_music.gemspec` (bundled-gem status means specs can't assume it under Bundler; never required from `lib/`).
   - Files: `lib/head_music/content/composition.rb`, `head_music.gemspec`

10. **Specs** (see Testing Strategy), then `bundle exec rubocop -a` and `bundle exec rake` (90% coverage gate; ABC hit it via one error-path spec per `validate!` rule — do the same).

### Reuse & Consistency Mechanisms

- Same facade → orchestrator → pinned-helper decomposition, validate-then-emit contract, and error grammar as ABC (lowercase, actionable, names the bar/position: "insert explicit rests to fill gaps").
- Exact-Rational duration math reuses the documented ABC technique (`abc/duration_writer.rb:21-36`); `Voice#first_gap` centralizes the contiguity query without a premature shared-validator abstraction.
- Deliberate divergences from ABC, each with a reason recorded above: multi-voice supported, mid-piece changes supported, tied chains expanded rather than collapsed, per-link validation, `<fifths>` beyond ±7 allowed (MusicXML can express what ABC's K: field cannot).
- Stable part ids `P1..Pn` and `role` → `<part-name>` chosen so a future MusicXML *import* story round-trips voice roles; golden fixtures live in `spec/support/` for reuse by that story (same shared-corpus move as the ABC pair).

### Edge Cases

- Zero voices → `RenderError`; voice with zero placements → one part of whole-measure rests (key/meter always have defaults).
- Rest-only voice → treble clef fallback; rest `tied_value` chains → consecutive rests, no ties.
- Placement crossing its barline → `RenderError` (v1); underfull final bar → left underfull (matches ABC tolerance).
- Double-altered tonics: `<fifths>` of 8 emitted, spec-documented; exotic scale types raise.
- Pickup bars (`earliest_bar_number` < 1) → `number="0" implicit="yes"`.
- Free text: `name: %(Für <Elise> & "Friends")` must survive the escape choke point; XML 1.0-forbidden control characters in name/composer/role rejected in `validate!`.
- Float leakage is the standing correctness trap: any use of `relative_value`/`total_value`/Float ticks in this feature is a bug.

### Testing Strategy

- Helper-level specs: `spec/head_music/notation/music_xml/{key_mapper,pitch_writer,duration_writer,divisions,clef_selector}_spec.rb` — fifths (C/G/F/E♭, A minor, D dorian → 0, G♯ major → 8), modes + raises; alter nil/±1/±2 and octave; type map incl. breve/long/16th, dots 1–3, tied-chain components with tie flags, unmappable raises; LCM cases (eighth-note piece → 2, 3/8 meter, empty → 1); clef selection three ways.
- `spec/head_music/notation/music_xml/writer_spec.rb` — the five acceptance scenarios: (1) single-voice diatonic from `ABCFixtures::SPEED_THE_PLOUGH` (build fixtures via `ABC.parse`) via XPath assertions, plus one small hand-built composition as an exact heredoc pinning declaration/DOCTYPE; (2) accidentals via `ABCFixtures::CHROMATIC_AIR`, asserting the `<alter>` sequence; (3) rests; (4) multi-voice with unequal lengths — equal measure counts, whole-measure-rest padding, part-list ids, attributes repeated per part; (5) `change_meter`/`change_key_signature` mid-piece — `<attributes>` exactly on those measures in every part. Error paths: no voices, internal gap, mid-bar first placement, barline crossing, unmappable scale type, control characters. Escaping spec with hostile metadata.
- `spec/support/music_xml_helpers.rb`: `parse_musicxml(xml)` (REXML) + XPath text/count helpers, auto-loaded like `abc_round_trip.rb`; every rendered document in specs must pass a REXML parse.
- Cross-format property: for each ABC fixture, MusicXML note/rest count and step/alter/octave sequence equal the composition's placements (analog of `expect_abc_round_trip`).
- Delegation example for `#to_musicxml` in `spec/head_music/content/composition_spec.rb`.
- One-time manual MuseScore import of a generated file, recorded in the story's review notes — not CI.

### Acceptance-Criteria Gaps Found

- "Schema-valid" and "round-trips through MuseScore" are not executable as written — restated as: REXML well-formedness + XPath structure + golden fixture in CI; MuseScore manually, once.
- `<part-name>` content was unspecified yet schema-required — now pinned (`role`, else "Voice N").
- The singular "emit new `<attributes>` on the bar" hid that partwise repeats attributes **per part** — now explicit.
- Unspecified behaviors now decided: zero voices (raise), empty voice (rest measures), barline-crossing (raise), pickup numbering (`implicit="yes"`), `origin` (deliberately dropped), `<software>` stamp (added), `<accidental>` display elements (explicitly out — `<alter>` carries semantics).

### Risks & Open Questions

- **Specialist disagreements resolved editorially** (revisit only if review disagrees): range-derived clef over fixed treble; emit out-of-range `<fifths>` rather than raise; raise on barline-crossing rather than split-and-tie (split-and-tie is the identified follow-up story, and multi-voice counterpoint content may hit it soon).
- Theoretical keys (`fifths` > 7) may render oddly in some readers though schema-valid — accepted, spec-documented.
- Meter-change-vs-position consistency: positions placed before a later `change_meter` reflect the model's own semantics; the writer renders stored positions as-is (pre-existing model caveat, not a writer bug).
- If preserving `origin` is wanted, `<identification><miscellaneous>` is a one-line add.

## Review

Reviewed 2026-07-07 at commit `42e9742` (all implementation changes uncommitted in the working tree at review time). Reviewers: product-manager (acceptance criteria) and code-reviewer (quality), in parallel, plus direct DTD validation with `xmllint` against the MusicXML 4.0 DTD fetched from the W3C source. Full suite: 5,520 examples, 0 failures; 99.71% line / 97.2% branch coverage; rubocop clean (427 files).

### Acceptance criteria

| # | Criterion | Verdict | Evidence |
|---|---|---|---|
| 1 | Well-formed, schema-valid `<score-partwise>` with correct DOCTYPE/version | ✅ met | Golden fixture pins declaration/DOCTYPE/`version="4.0"` byte-for-byte (writer_spec.rb:82-175); every rendered spec document passes a REXML parse; three generated sample documents (Chromatic Air, a multi-voice exercise with rests + tied chain, a two-part change study) validate against the actual MusicXML 4.0 DTD via `xmllint --dtdvalid` |
| 2 | `<work-title>` from `name`, `<creator type="composer">` when present | ✅ met | writer.rb:170-187, escaped via the single choke point; golden fixture + hostile-metadata escaping spec |
| 3 | Voice → `<part>` + `<score-part>`; bar → `<measure>` | ✅ met | Stable `P1..Pn` ids, `<part-name>` from role or "Voice N"; multi-voice spec asserts equal measure counts with whole-measure-rest padding for the shorter voice |
| 4 | `<pitch>` step/octave/alter; `<duration>`, `<type>`, correct `<divisions>` | ✅ met | Stateless PitchWriter (nil alter omitted); DurationWriter's exact Rational math with frozen type map; Divisions LCM (empty→1, eighths→2, 3/8→2, mid-piece changes included); Chromatic Air `<alter>` sequence asserted |
| 5 | Rests as `<rest>` with right duration | ✅ met | `<rest/>` notes with durations/types asserted; `<rest measure="yes"/>` for empty measures sized by effective meter |
| 6 | First-measure attributes (fifths, beats/beat-type, clef); mid-piece changes on the right bar | ✅ met | divisions/key/time/clef in schema order, clef range-derived per voice (G2/F4 asserted across two voices); change specs assert `<attributes>` with only the changed elements on measure 3 and none elsewhere; verified directly that changes repeat in every part (P1 and P2 both carry key+time on measure 3) and the document is DTD-valid |
| 7 | Accepted by a MusicXML reader / schema validator | ✅ met (validator) / ⚠️ optional (reader) | The schema-validator half is satisfied: three sample documents are structurally DTD-valid against MusicXML 4.0 (`xmllint --dtdvalid`, entity warnings only). MuseScore is not installed on this machine; an import into a real scorewriter remains an optional manual check |
| 8 | Specs cover the five named scenarios | ✅ met | Single-voice diatonic (Speed the Plough + golden fixture), accidentals (Chromatic Air), rests, multi-voice unequal lengths, mid-piece key/meter change — all in writer_spec.rb, plus tied chains, five error paths, escaping, `Voice#first_gap`, and `#to_musicxml` delegation |

### Code review findings (no blockers)

1. **Should-fix: `**options` passthrough raises a confusing `ArgumentError`.** `MusicXML.render(composition, **options)` splats into `Writer.new`, whose initializer takes no keywords, so any option raises `ArgumentError: wrong number of arguments (given 2, expected 1)` rather than `unknown keyword: ...`. The plan intended typo'd options to raise `ArgumentError` "for free," but the wrong-arity message is misleading and no spec covers the path. Cheapest fix: leave the facade as-is (splatting empty options works) and add a spec documenting the behavior, or drop `**options` until a first real option exists.
2. **Should-fix: pickup (`implicit="yes"`) measures are advertised but nearly unreachable and untested.** A genuine partial anacrusis raises the first-placement-must-start-its-bar `RenderError`; the branch is only reachable when bar 0 is fully filled (e.g. with explicit leading rests). Either add a spec for the rest-filled pickup form or trim the comment to match the "fully-filled bars only" reality.
3. **Nit: rest tied-chains untested** — writer comments claim consecutive independent rests, guards exist, but no spec constructs a rest with a `tied_value`.
4. **Nit: multi-bar exact-fill note rejection untested** — a breve spanning exactly two 4/4 bars is correctly rejected by `ensure_notes_within_barlines`, but the spec only covers an overflowing note.

Verified-correct probes by the reviewer: no malformed document can escape (`validate!` force-evaluates everything that can raise before assembly); schema element order in `<attributes>`, `<note>`, and `<pitch>`; tie stop-before-start convention; escaping completeness; exact Rational duration math with `whole_measure_duration`'s `.numerator` shortcut guaranteed safe by the Divisions denominator set; `next_position` correct for tied chains; identity-keyed memoization safe despite `Placement#==` comparing position only; `normalize_bar_markers` idempotent across double renders (though rendering does normalize raw string bar markers in place — documented deviation, accepted).

**Verdict: ready to finish.** Nothing blocks; findings 1–2 are small polish items and 3–4 are optional spec additions. The only remaining manual step, importing a generated file into a scorewriter, is optional now that DTD validation has passed.
