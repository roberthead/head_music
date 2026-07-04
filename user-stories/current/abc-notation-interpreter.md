<!--
metadata:
  created_at:   2026-07-04T12:05:19-07:00
  activated_at: 2026-07-04T12:21:27-07:00
  planned_at:   2026-07-04T12:37:50-07:00
  finished_at:
  updated_at:   2026-07-04T14:38:24-07:00
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
- [ ] `Composition` gains `composer` and `origin` string attributes (set at initialization, exposed via `attr_reader`) mapped from the ABC `C:` and `O:` fields
- [ ] `Composition` gains a `comments` collection of `HeadMusic::Content::Comment` value objects (`composition`, `text`, optional `position`), with `add_comment(text, position = nil)`; a header `N:` field maps to an unpositioned comment
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
2. **Extend `Composition` with `composer`, `origin`, and `comments`.** `composer` and
   `origin` are strings set at initialization time and exposed via `attr_reader`,
   giving the ABC fields `C:` (composer) and `O:` (origin) a first-class home rather
   than being dropped or stashed in a metadata hash.

   `comments` is a collection of `HeadMusic::Content::Comment` value objects — `text`
   plus an optional `HeadMusic::Content::Position` — because the ABC standard allows
   `N:` in the tune body and inline as well as in the header. A header `N:` maps to an
   unpositioned comment.

   `Comment.new(composition, text, position = nil)` takes the composition as its first
   argument, following the `Placement` precedent. A position passed in string or
   symbol form is constructed against that composition; a position passed as a
   `HeadMusic::Content::Position` must agree with (belong to) that composition, or the
   constructor raises. `Composition.new(comments: ...)` accepts a string or array of
   strings (coerced to unpositioned comments), and `add_comment(text, position = nil)`
   mirrors `add_voice`, constructing the comment with `self`.

   The attribute is named `comments` rather than ABC's field name "notes" to avoid
   overloading a term that means note objects everywhere else in the gem (e.g.
   `voice.notes`). Reference: ABC v2.1 standard §3.1.11 — `N:` "contains general
   annotations, such as references to other tunes which are similar, details on how
   the original notation of the tune was converted to abc, etc."
3. **Default-note-length and meter interaction lives in the parser.** No new duration
   helper in `Rudiment`.

## References

- https://en.wikipedia.org/wiki/ABC_notation
- https://abcnotation.com/
- https://abcnotation.com/wiki/abc:standard:v2.1

## Implementation Plan

### Overview

Add `HeadMusic::Notation::ABC.parse(string) → HeadMusic::Content::Composition` as a small family of classes under `lib/head_music/notation/abc/`: line-based regex parsing for the header, a `StringScanner` (stdlib) token lexer for the body, and sequential placement via the established `voice.place(voice.next_position, rhythmic_value, pitch)` pattern. No new runtime dependencies.

### Steps

1. **Add `Content::Comment` and extend `Composition` with `composer`, `origin`, `comments`**

   - New value object `HeadMusic::Content::Comment`: `attr_reader :composition, :text, :position`; `initialize(composition, text, position = nil)` following the `Placement` precedent (anchor object first, positional args). Position handling mirrors `Placement#ensure_position`: a `HeadMusic::Content::Position` is taken as-is but must belong to the same composition (raise `ArgumentError` otherwise — stricter than `Placement`, which trusts the caller); a string/symbol is coerced via `Position.new(composition, position)`; nil means unpositioned. `to_s` returns the text.
   - `Composition`: add kwargs to `initialize(name: nil, key_signature: nil, meter: nil, composer: nil, origin: nil, comments: nil)`. `composer`/`origin` are plain string passthrough with `attr_reader`s. `comments` accepts a string or array of strings, coerced to unpositioned `Comment` objects built with `self`; `attr_reader :comments` defaults to `[]`. Add `add_comment(text, position = nil)` mirroring `add_voice`, constructing `Comment.new(self, text, position)`. Additive and backward compatible; `ensure_attributes` is private so its signature can grow freely. Verified: no existing callers of `composition.comments`/`composer`/`origin` in lib or spec.
   - Wire `require "head_music/content/comment"` into the content loading sequence in `lib/head_music.rb`.
   - Files: `lib/head_music/content/comment.rb`, `lib/head_music/content/composition.rb`, `spec/head_music/content/comment_spec.rb`, `spec/head_music/content/composition_spec.rb`

2. **Module skeleton, wiring, and error hierarchy**

   - `lib/head_music/notation/abc.rb`: `module HeadMusic::Notation::ABC` with `self.parse(abc_string) = Parser.new(abc_string).composition`. The gem has no custom error classes yet (only bare `ArgumentError`s in `rudiment/mode.rb`, `rudiment/key.rb`), so this establishes the convention: a shared `HeadMusic::Notation::ParseError < StandardError` base in `lib/head_music/notation.rb` (deliberate — the companion LilyPond interpreter story reuses it), then `HeadMusic::Notation::ABC::ParseError < HeadMusic::Notation::ParseError` carrying structured `line_number:`/`snippet:` data, plus one subclass `UnsupportedFeatureError` for valid-but-out-of-scope ABC. Two classes, not a zoo — specificity lives in the message.
   - `ABC` references `Content::Composition` only at parse time, never load time — `notation` loads before `content` in `lib/head_music.rb`, so keep it that way.
   - Files: `lib/head_music/notation/abc.rb`, `lib/head_music/notation.rb`, `spec/head_music/notation/abc_spec.rb` (error-shape specs)

3. **Header parsing and key mapping**

   - `Header`: split header/body at the `K:` line; line-regex dispatch on field letters (`X: T: C: O: N: M: L: V: K:`); enforce `K:` present and last (missing `K:` raises — otherwise the composition silently defaults to C major, exactly the forbidden "partial composition"). Map `M:C` → common time and `M:C|` → cut time **before** calling `Meter.get`, and validate other `M:` values match `\d+/\d+` — passing `"C"` raw to `Meter.get` misbehaves and pollutes its process-wide memoization cache. When `L:` is absent, apply the ABC 2.1 default rule (meter value < 0.75 → 1/16, else 1/8).
   - `KeyMapper`: `/\A([A-G])([#♯b♭]?)\s*([A-Za-z]*)/`, then mode-word normalization by first-three-letters prefix (case-insensitive): `""`/`maj`/`ion` → major; exact `m`, `min`, `aeo` → minor; `dor`, `phr`, `lyd`, `mix`, `loc` accordingly. Emit `"G major"`-style strings for `KeySignature.get` (which splits tonic/scale-type on whitespace — never pass raw ABC like `"Ador"` through, it would be read as a tonic spelling). `K:none`/`K:HP` or unrecognized modes raise.
   - Files: `lib/head_music/notation/abc/header.rb`, `lib/head_music/notation/abc/key_mapper.rb`, `spec/head_music/notation/abc/header_spec.rb`, `spec/head_music/notation/abc/key_mapper_spec.rb`

4. **Duration resolution**

   - `DurationResolver`: `fraction = Rational(L) × multiplier` (`A2`→2, `A3/2`→3/2, `A/2` and `A/`→1/2, `A//`→1/4). All arithmetic in `Rational`, converting to the gem's float `relative_value` only when selecting the unit. Numerators 1/3/7/15 over power-of-two denominators → plain/dotted/double-dotted/triple-dotted `RhythmicValue`. Other numerators (e.g. `A5` = 5/8) → greedy binary decomposition into `tied_value` chains (verified working: `RhythmicValue.new(:half, tied_value: ...)` yields correct `total_value` and `ticks`, and `Placement#next_position` advances by ticks, so tied values place correctly). Non-power-of-two denominators or absurd multipliers raise. Never fall through to `RhythmicValue.new`'s silent invalid-dots-→-0 coercion — resolve explicitly or raise.
   - Files: `lib/head_music/notation/abc/duration_resolver.rb`, `spec/head_music/notation/abc/duration_resolver_spec.rb`

5. **Body lexer**

   - `BodyLexer`: `StringScanner` over the body producing token structs (`:note`, `:rest`, `:bar_line`, `:broken_rhythm`, `:voice_change`) with letter/case, accidental marks, octave marks, length string, and line/column. Strip `%` comments, join `\` continuations, skip beaming whitespace, treat a blank line as end of tune. Anchored character-class regexes only (no nested quantifiers — no ReDoS exposure); an unmatched character raises `ParseError` with line/column. Check `abc_string.valid_encoding?` up front (UTF-8 assumed; document it) so encoding problems surface as `ParseError`, not a deep regex `ArgumentError`.
   - Files: `lib/head_music/notation/abc/body_lexer.rb`, `spec/head_music/notation/abc/body_lexer_spec.rb`

6. **Pitch building (octaves, accidentals, key signature)**

   - `PitchBuilder`: octave = (uppercase ? 4 : 5) + apostrophes − commas, so `C`=C4 (middle C), `c`=C5, `C,`=C3, `c'`=C6. Accidental marks `^ ^^ _ __ =` → name fragments `# x b bb ""` — verified `Pitch.from_name("F##4")` returns nil; double sharp must be `"Fx4"`.
   - Full ABC-standard accidental semantics in v1: unmarked notes take the key signature (in `K:G`, body `F` → F#); an explicit accidental persists for that letter+octave until the next bar line; `=` cancels. Implemented as a hash keyed by `[letter, octave]` in the parser, cleared on every `:bar_line` token. Rationale: "accidentals interpreted correctly" means correct per the standard — the naive per-note reading silently imports wrong pitches in real folk tunes, violating the no-silent-failure criterion in spirit. Key-signature lookup via `key_signature.alterations` spellings.
   - Files: `lib/head_music/notation/abc/pitch_builder.rb`, `spec/head_music/notation/abc/pitch_builder_spec.rb`

7. **Parser orchestration**

   - `Parser`: parse and validate the entire header and tokenize the entire body **before** constructing the `Composition` — the no-partial-composition guarantee falls out structurally (the composition is a local; any raise abandons it), and full pre-validation ensures no factory caches are touched by bad input. Then build: header attrs → `Composition.new`, `V:` ids → `add_voice(role: id)` (inline `V:` lines switch the current voice; no `V:` → one voice), notes/rests placed at each voice's own `next_position` cursor. `z` + length → rest placement (nil pitch). Bar-line variants (`|`, `|:`, `:|`, `::`, `||`, `|]`, `[|`) all reset accidental state and are otherwise structural no-ops — no repeat expansion, no bar-length validation in v1. Broken rhythm `>`/`<` (dot one neighbor, halve the other) is included — trivially cheap and present in nearly every hornpipe. Everything else lexable-but-unsupported (chords `[CEG]`, quoted chord symbols, grace notes `{}`, ties `-`, slurs, tuplets `(3`, decorations, `Z`, `x`, `w:`, inline `[K:]`/`[M:]` changes, first/second endings) raises `UnsupportedFeatureError` naming the token and line — never silently skipped.
   - Files: `lib/head_music/notation/abc/parser.rb`, `spec/head_music/notation/abc/parser_spec.rb`

8. **End-to-end spec, coverage, and polish**

   - Full "Speed the Plough" end-to-end spec plus a 6/8 tune to prove compound-meter position advancement (verified in console: eighths in 6/8 roll `1:6:000 → 2:1:000`). Run `bundle exec rubocop -a` and `bundle exec rake` for the 90% floor.
   - Files: `spec/head_music/notation/abc_spec.rb`

### Key Design Decisions

- **Architecture**: line-regex header + `StringScanner` body lexer, not a grammar library (gemspec allows no new runtime deps; `strscan` is stdlib) and not the regex-cascade style of `RhythmicValue::Parser` (no position tracking — the clear-error criterion demands line/column). ABC in this scope is regular, not recursive; a token loop is the whole parser.
- **API**: `parse` is the right verb (matches `Pitch::Parser.parse`); `.get` is wrong here (parsing isn't a cacheable value-object lookup). One deliberate divergence: existing internal `parse` methods return nil on failure; `ABC.parse` raises, because it is a boundary for untrusted external input. Only `ABC.parse` is public API; the helper classes are internal, documented by their specs.
- **Durations**: `Rational` math throughout; dotted forms for 3/7/15 numerators; `tied_value` chains for other binary fractions; raise for non-binary.
- **Errors**: fail-fast, first error raises. Three outcome classes: parses; valid-but-unsupported → `UnsupportedFeatureError`; malformed → `ParseError` — both with line numbers.

### Testing Strategy

House style: one behavior per `it`, heredocs (`<<~ABC`) rather than fixture files — the ABC sits next to its assertions, serving the tests-as-documentation philosophy. Coverage per acceptance criterion:

- `abc_spec.rb` — "Speed the Plough" end-to-end (name, 4/4, G major/1 sharp, one voice, eighth-note pitches G4 A4 B4 C5…, `c2`→quarter, bar rollover) plus a 6/8 tune; nil/empty input raises.
- `header_spec.rb` — every field mapping, `M:C`/`M:C|`, `L:` default rule (2/4→1/16, 4/4→1/8), missing-`K:` raises, field-after-`K:` raises.
- `key_mapper_spec.rb` — normalization table: `G`, `Bb`, `Gm`, `Gmin`, `Ador`, `Dmix`, `F#m`, case-insensitivity, abbreviation prefixes, invalid mode raises.
- `duration_resolver_spec.rb` — fraction table incl. dotted/double-dotted, `A5` → tied half+eighth asserting `total_value` (not `==` — `RhythmicValue#==` compares `to_s`), non-binary raises.
- `pitch_builder_spec.rb` — octave matrix (`C c C, c' c,,`), `^ ^^ _ __ =`, key-signature application (F in G → F#4, `=F` → F4), bar persistence and reset at `|`.
- `body_lexer_spec.rb` / `parser_spec.rb` — length strings, comments, continuation, rests, multi-voice with independent cursors, every unsupported feature raising with line/column. Error-path specs assert class and message (`raise_error(..., /line 3/)`) — these branches are also what holds the 90% coverage floor.

### Risks & Open Questions

- **`Meter.get("C")` behavior**: possibly an `ArgumentError`, possibly a silently memoized garbage meter — verify which during implementation; either way the pre-mapping in step 3 is mandatory.
- **Repeats not expanded**: `|: :|` are consumed as plain bar lines, so total placed length differs from performed length. Plan assumes acceptable for v1, documented in specs; expansion is a natural v2 (as are inline `[K:]`/`[M:]` changes — `Composition#change_key_signature`/`#change_meter` already exist).
- **Body/inline `N:` fields**: out of scope for v1 (they raise `UnsupportedFeatureError` like other inline fields), but the `Comment` model's optional position means supporting them later is additive — no API change.
- **Pickup bars**: placement starts at `1:1:0`, so a pickup shifts notated downbeats relative to `Position` bar numbers, skewing beat-strength analysis. V1 accepts and documents; padding bar 1 with a leading rest is a possible v2 behavior.
- **Multi-voice scope**: `V:` support stays (it is an acceptance criterion), constrained to header-declared voices plus inline `V:` switching — no per-voice clefs or transposition.
- **Encoding**: UTF-8 assumed and stated in specs; Latin-1 legacy ABC files are out of scope.
