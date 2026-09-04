<!--
metadata:
  created_at:   2026-07-04T12:05:19-07:00
  activated_at: 2026-09-03T18:23:09-07:00
  planned_at:   2026-09-03T19:25:55-07:00
  finished_at:
  updated_at:   2026-09-04T15:13:46-07:00
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

The round-trip specs must consume the LilyPond export story's golden fixtures (see `spec/head_music/notation/lily_pond/writer_spec.rb`), retroactively automating the export story's toolchain-acceptance proof.

- Home for the interpreter: `HeadMusic::Notation`, mirroring the ABC story. Consider `lib/head_music/notation/lily_pond/` for the parser and its helpers.
- The `Composition` API to target: `name`, `key_signature`, `meter`, and `voices` (via `add_voice`), with notes placed through the `Voice` / `Placement` / `Note` classes in `HeadMusic::Content`.
- Reuse existing rudiments (`KeySignature`, `Meter`, `Pitch`, duration/`RhythmicValue` concepts) rather than re-deriving them in the parser.
- `\relative` mode is the subtlest piece: each pitch is placed in the octave nearest the previous pitch, adjusted by any `'`/`,` marks. Establish the resolution algorithm early and test it thoroughly.
- Scope the first pass to a practical subset: a single `\score` / music expression with common commands and note/rest sequences. Explicitly out of scope for v1: lyrics (`\lyricmode`), chord mode (`\chordmode` / `<...>`), articulations and dynamics, tuplets (`\times`), variables (`music = { ... }`), and full `\book` documents.

## Open Questions

1. Should the parser accept a full `.ly` document (with `\version`, `\header`, `\layout`) and extract the music, or only a bare music expression for v1?
2. LilyPond has no single "title" the way ABC does — should `\header { title = ... }` map to the composition `name`, and if the block is absent, leave it nil?
3. Should absolute mode and `\relative` mode share one pitch resolver with a mode flag, or be handled by separate strategies?

## Decisions

Resolved by the owner after planning (2026-09-03):

1. **Chords `<...>` are in scope for v1.** The writer already emits them and the ABC parser imports them, so chord-bearing compositions must round-trip. This supersedes the "chord mode" exclusion in the Notes above; `\chordmode` itself stays out of scope.
2. **A bar-check mismatch raises `ParseError`.** LilyPond only warns, but the gem cannot warn without printing, and a wrong bar count would silently misplace every later note.
3. **Unknown `\header` (and `\with`) string fields are ignored.** Only `title` and `composer` are read; other string-valued fields are skipped, unlike the ABC parser which raises on unknown header fields.
4. **`~` ties are in v1, intra-bar only.** They fold into one placement's `tied_value` chain as in ABC; a tie across a bar check raises.

## Implementation Plan

### Overview

Add `HeadMusic::Notation::LilyPond.parse(string)` as a two-pass pipeline mirroring the ABC parser's fail-before-building contract: `Lexer` → `ParsePreflight` → `DocumentReader` (tokens → a validated, composition-free `Document` of per-voice event streams; all pitch/duration/key/meter/tie validation happens here) → `CompositionBuilder` (replays the streams onto a fresh `Composition`). Two passes are mandatory, not stylistic: `Composition` has no `key_signature=`/`meter=` setters and the writer emits `\key`/`\time` inside `\new Voice { }`, so the composition cannot be constructed until the first voice's opening commands are known.

### Decisions on the open questions

1. **Accept the full document shape as a fixed envelope, not a general `.ly` grammar** (no owner confirmation needed; the round-trip note already forces it). Grammar: optional `\version STRING`; optional `\header { WORD = STRING ... }`; optional `\score { ... }` wrapping the music plus `\layout { }`/`\midi { }` blocks (skipped wholesale, balanced); then exactly one music expression: `{ }`, `\relative [PITCH] { }`, `\absolute { }`, `\new Staff|Voice [= STRING] [\with { WORD = STRING ... }] music`, or `<< \new ... >>`. A second `\score`, `\book`/`\bookpart`, top-level assignments (`melody = { }`), and `\include` raise `UnsupportedFeatureError`. Bare notes outside braces raise `ParseError` (LilyPond rejects them too).
2. **Yes: `title` → `name`, `composer` → `composer`, both nil when absent** (`Composition` then defaults the name to "Composition", which round-trips since the writer always emits a title). Strings are unescaped as the exact inverse of `StringText.escape`. Other `\header` string fields (`tagline`, `subtitle`, `arranger`) are ignored; non-string values (`\markup`, `##f`, `#(...)`) raise `UnsupportedFeatureError`. Owner-confirmed: ignore (ABC's precedent is to raise).
3. **One `PitchReader` with a nullable reference pitch.** Absolute and relative differ in exactly one function (where octave marks count from); spelling is shared. `PitchReader.absolute` vs `PitchReader.relative(reference)`; `DocumentReader` keeps a stack of readers (push on `\relative`/`\absolute`, pop at the end of the wrapped expression).

Additional decisions discovered (each with reasoning):

- **Chords `<c' e' g'>4` are in v1 (owner-confirmed; supersedes the story's chord exclusion).** Re-derived reason: `RenderPlan#chord_token` already emits them, the ABC parser already imports chords, so any chord-bearing composition would fail the round trip; the `<`/`>` tokens are needed for `<< >>` anyway; the relative-mode rule is oracle-verified (~30 lines).
- **`~` ties in v1, intra-bar only**, folding into one placement's `tied_value` chain exactly as `ABC::VoiceState` does. A tie across a bar check raises "Ties across bar checks are not yet supported" (the writer never emits one).
- **`R<dur>[*n/d]` becomes one rest placement** whose value is `DottedDuration.rhythmic_value_for(fraction)` (e.g. `R1*4/4` → whole, `R1*3/4` → dotted half, `R1*5/4` → whole tied to quarter) and is accepted only when the fraction equals exactly one bar of the meter in force at the cursor; otherwise `UnsupportedFeatureError "multi-bar rests"`. Reasons: an advance-only cursor would leave gaps the writer's `ensure_contiguous_voices` rejects on re-render; `R1*4` means four bars in LilyPond and `R1*100000` would be an O(n²) placement flood. `*` on ordinary notes/rests → `UnsupportedFeatureError`.
- **Bar check `|` mismatch raises `ParseError` (owner-confirmed).** LilyPond itself only warns (verified with the binary: it compiles and continues), but the gem cannot warn without printing, and a wrong bar count silently misplaces every later note. Message mirrors LilyPond's: `Bar check failed at: 1/2 in bar 2`.
- **Mid-piece `\key`/`\time`** at a bar start after bar 1 → `change_key_signature`/`change_meter`; the writer repeats the change in every voice's stream, so an identical change already in force at that bar is a no-op and a conflicting one raises `ParseError`. A `\key`/`\time` mid-bar → `UnsupportedFeatureError` (valid LilyPond the bar-anchored model cannot hold).
- **`\relative` with no reference pitch → `f` (F3)**, as LilyPond 2.18+ (oracle-verified). `<< >>` inside `\relative` and nested `\relative` around `<< >>` → `UnsupportedFeatureError` (post-`>>` reference semantics are ambiguous); the idiomatic `\new Staff { \relative c' { ... } }` is fully supported.
- **Duration carry-over is parser-global** (one `DurationReader` per parse; oracle-verified that it crosses `\new Staff` boundaries and carries dots: `g4. a` → `a4.`). A dot with no number (`d.`) is a LilyPond syntax error → `ParseError`.
- **`\clef` is consumed and ignored** (WORD or STRING; the model has no clef slot, `ClefSelector` decides at render). `\version` consumed. Dutch contractions `as`/`es`/`ases`/`eses` accepted as aliases of `aes`/`ees`/...; spacer rests `s` → `UnsupportedFeatureError`.
- **Extract the fraction → `RhythmicValue` decomposition into the existing `HeadMusic::Notation::DottedDuration`** (`rhythmic_value_for(fraction)`, inverse of its `dotted_unit_fraction`) rather than copying ABC's greedy-head code (a guaranteed flay hit on `rake validate`).

### Verified facts the design rests on (probed / oracle-checked with lilypond 2.26.0)

- `Meter.get("0/4")` then one `place` **hangs the process** (`Position#roll_over_counts`); `"4/0"`/`"4/3"` leak `ZeroDivisionError`/`NoMethodError`; `Meter.get` and `KeySignature.get` memoize garbage process-wide; `KeySignature.get("nonsense")`/`("Fis major")` return a nil-tonic key; `KeySignature.get("A harmonic minor")` raises `NoMethodError`; `Pitch.from_name` returns nil for garbage; `RhythmicValue.new(unit, dots: 4)` silently becomes 0 dots. Every `.get` is therefore gated by textual validation.
- `Position#+` rolls over with `composition.meter_at(bar)`, so a `change_meter` must be applied before that bar's notes are placed (event order guarantees this).
- `Voice#place` silently merges a same-position placement into a chord — the builder only ever places at `voice.next_position`.
- `RhythmicValue#==`/`#to_s` are name-based (exact; no Float), so round-trip duration comparison uses `rhythmic_value.to_s`.
- `Dir[...].sort` loads `duration_reader.rb` before `duration_writer.rb` and `pitch_reader.rb` before `pitch_writer.rb`: inverse tables must be lazily memoized class methods, never class-body constants.
- Relative-mode oracle table (all verified): `c' g`→G3, `c' g'`→G4, `c' f`→F4, `c' b`→B3, `c' c,`→C3, `b, c`→C3, `c' fis`→F♯4, `bes' e`→E5, `c' e''`→E6, `\relative { c d }`→C3 D3, `c' <e g b> d`→D4 (reference = chord's first note), rests keep the reference, story example → G3 A3 B3 C4 D4 C4 B3 G3.

### Files

Facade `lib/head_music/notation/lily_pond.rb` (modify):

```ruby
def self.parse(lily_pond_string) = Parser.new(lily_pond_string).composition

class ParseError < HeadMusic::Notation::ParseError
  attr_reader :line_number, :column, :snippet
  def initialize(message, line_number: nil, column: nil, snippet: nil)  # appends " (line N)" as ABC does
end
class UnsupportedFeatureError < ParseError; end
```

`lib/head_music/notation/dotted_duration.rb` (modify): add `rhythmic_value_for(fraction)` → `RhythmicValue` (dots via odd factor; greedy-head tied chain otherwise) or nil when the fraction is ≤ 0, > 8 whole notes, or has a non-power-of-two denominator; moved verbatim from `abc/duration_resolver.rb` (`build_rhythmic_value`, `single_value`, `greedy_head`, `leading_set_bits`, `unit_for`, `odd_factor`, `power_of_two?`, `DOTS_BY_ODD_FACTOR`, `UNIT_NAMES_BY_MULTIPLE`). `ABC::DurationResolver` keeps `validate_fraction!` and its three messages and delegates.

`lib/head_music/notation/lily_pond/string_text.rb` (modify): add `StringText.unescape(text)` = `text.gsub(/\(["\])/, '')`.

New files under `lib/head_music/notation/lily_pond/` (names avoid the writer-side `Preflight`, `KeyMapper`, `PitchWriter`, `DurationWriter`):

| File | Class | Public signature |
| --- | --- | --- |
| `token.rb` | `Token` | `Data.define(:type, :line, :column, :lexeme, :letter, :suffix, :octave_marks, :duration, :multiplier)`; all but type/line/column default nil |
| `lexer.rb` | `Lexer` | `new(source)`, `#tokens` (memoized) |
| `parse_preflight.rb` | `ParsePreflight` | `.ensure_input_present(source)`, `.reject_unsupported_tokens(tokens)`, `.ensure_balanced_delimiters(tokens)` |
| `pitch_reader.rb` | `PitchReader` | `.absolute`, `.relative(reference_pitch)`, `#relative?`, `#pitch(note_token)`, `#chord_pitches(note_tokens)`, `.alterations_by_suffix` (memoized invert of `PitchWriter::ALTERATION_SUFFIXES`) |
| `duration_reader.rb` | `DurationReader` | `new`, `#rhythmic_value(token)` (carries the last explicit duration, initial `"4"`), `#whole_bar_fraction(token)`, `.unit_names_by_duration` (memoized invert of `DurationWriter::DURATIONS_BY_UNIT_NAME`) |
| `key_reader.rb` | `KeyReader` | `.key_signature(pitch_token, mode_token)`, `.scale_types_by_mode_command` (memoized invert of `KeyMapper::MODE_COMMANDS_BY_SCALE_TYPE`) |
| `meter_reader.rb` | `MeterReader` | `.meter(number_token)` |
| `voice_stream.rb` | `VoiceStream` | `new(role)`, `#role`, `#events`, `#music?`, `#add_note(pitches, rhythmic_value, line)`, `#add_rest(rhythmic_value, line)`, `#add_whole_bar_rest(fraction, line)`, `#open_tie(line)`, `#bar_check(line)`, `#change_key_signature(key, line)`, `#change_meter(meter, line)`, `#finish`; `Event = Data.define(:kind, :line, :pitches, :rhythmic_value, :fraction, :key_signature, :meter)` |
| `document.rb` | `Document` | `new`, `#title`/`#title=`, `#composer`/`#composer=`, `#streams`, `#add_stream(role)`, `#first_key_signature`, `#first_meter` |
| `document_reader.rb` | `DocumentReader` | `new(tokens)`, `#document` |
| `composition_builder.rb` | `CompositionBuilder` | `new(document)`, `#composition` |
| `parser.rb` | `Parser` | `new(source)`, `#composition` (memoized only on success) |

Specs: `spec/head_music/notation/lily_pond/{lexer,parse_preflight,pitch_reader,duration_reader,key_reader,meter_reader,voice_stream,document_reader,composition_builder,parser,round_trip}_spec.rb`; `spec/head_music/notation/dotted_duration_spec.rb` (extend); `spec/support/lily_pond_fixtures.rb` (new), `spec/support/lily_pond_round_trip.rb` (new), `spec/support/lily_pond_helpers.rb` (modify: absorb `installed_lilypond`, `compile_quietly`, and the "a compilable document" shared example from `writer_spec.rb`), `spec/head_music/notation/lily_pond/writer_spec.rb` (modify: consume the shared fixtures, no assertion changes). Also `README.md` and `CHANGELOG.md`.

### Lexer design

One `StringScanner` over the whole document (LilyPond is brace-structured, not line-structured). Before scanning: `delete_prefix("\uFEFF")`, then `ParseError "LilyPond input is not valid UTF-8"` unless `valid_encoding?` (regexes on invalid UTF-8 raise `ArgumentError` inside `StringScanner`). Track `@line` and `@line_start` (in `charpos`) through every consumed lexeme; `column = charpos - @line_start + 1`. Snippets via `scanner.peek(20)`.

Skips at each position, in order: whitespace; `/%\{.*?%\}/m` (block comments do not nest; unterminated → `ParseError "Unterminated block comment"` at the opener's line); `/%[^\n]*/`. Comments are skipped in-loop, never pre-stripped, so `%` inside strings and line numbers both survive.

Token patterns in match order:

| Pattern | Token |
| --- | --- |
| `/"((?:[^"\]\|\.)*)"/` → `StringText.unescape`; lone `"` → `ParseError "Unterminated string"` | `:string` |
| `<<` / `>>` | `:open_parallel` / `:close_parallel` |
| `<` | `:open_chord` |
| `>` + optional DURATION + optional MULTIPLIER | `:close_chord` |
| `{` `}` `\|` `~` `=` | `:open_brace` `:close_brace` `:bar_check` `:tie` `:equals` |
| `\\` (voice separator) | `:unsupported` |
| `/\([A-Za-z]+)/` | `:command` (lexeme without backslash) |
| NOTE_PATTERN | `:note` (letter, suffix normalized to nil/is/es/isis/eses, octave_marks, duration, multiplier) |
| `/([rR])(?![A-Za-z])(DURATION)?(MULTIPLIER)?/` | `:rest` / `:whole_bar_rest` |
| `/s(?![A-Za-z])(DURATION)?/` | `:unsupported` (spacer) |
| `/[A-Za-z_][A-Za-z0-9_]*/` | `:word` |
| `/\d+(?:\/\d+)?/` | `:number` |
| `/#\S*/`, `[`, `]`, `(`, `)`, `/[-^_][.>^_+!-]?/`, `:`, `!`, `?` | `:unsupported` |
| anything else | `ParseError "Unexpected character \"x\" at column N"` |

```ruby
DURATION_PATTERN   = /(?:\d+|\breve|\longa|\maxima)\.*/
MULTIPLIER_PATTERN = %r{\*(\d+(?:/\d+)?)}
NOTE_PATTERN = /(?:(a|e)(ses|s)|([a-g])(isis|eses|is|es)?)(?![A-Za-z])('+|,+)?(#{DURATION_PATTERN})?#{MULTIPLIER_PATTERN}?/o
```

The alias branch comes first; the `(?![A-Za-z])` lookahead keeps `bass`, `treble`, `composer`, `alto`, `Staff` as `:word`. Spec every writer-emitted word. `\breve`/`\longa`/`\maxima` are recognized only attached to a note/rest; standalone (after whitespace) they lex as `:command` and are rejected as unexpected — acceptable, the writer never emits that spacing.

### Pitch resolution

```
LETTERS = %w[c d e f g a b]                       # LilyPond octaves start at c, like the gem's register
step(pitch)  = pitch.register * 7 + LETTERS.index(letter)
absolute:  register = 3 + marks_up - marks_down   # inverse of PitchWriter (c' = C4, c = C3)
relative:  candidate = reference.register * 7 + LETTERS.index(letter)
           diff = candidate - step(reference)     # letters only; accidentals ignored
           candidate -= 7 if diff > 3             # fifth or more up wraps down
           candidate += 7 if diff < -3            # fifth or more down wraps up
           candidate += 7 * (marks_up - marks_down)
           register = candidate.div(7)
           result = Pitch.from_name("#{LETTER}#{fragment}#{register}")   # fragment: "", "#", "b", "x", "bb"
           @reference = result                    # notes only; rests never call #pitch
chord (relative): pitches resolved left to right, each relative to the previous; then @reference = pitches.first
```

`from_name` returning nil → `ParseError "Pitch \"c''''''\" is out of range"`. The `\relative` argument is read with an absolute reader and must carry no duration (`ParseError "\relative expects a pitch"`); accidentals on it are legal (`\relative cis'`). `\key` pitch tokens never touch the reference.

### Duration resolution

Base = token minus dots → `unit_names_by_duration.fetch` else `ParseError "Unrecognized duration \"3\""` (covers `c3`, `c0`, `c512`); `dots > 3` → `ParseError "Too many dots"`; `RhythmicValue.new(unit_name, dots:)`. Omitted duration reuses the last explicit one (dots included); initial default quarter. `R` tokens: `whole_bar_fraction` = `DottedDuration.dotted_unit_fraction(base value) * Rational(n, d)` (`d == 0` → `ParseError`); the builder checks it against the meter in force and places `DottedDuration.rhythmic_value_for(fraction)` as one rest. Ties fold in `VoiceStream`: `~` marks the pending note; the next note must have identical sorted pitches ("A tie must connect two notes of the same pitch"), its value is appended at the deep end of the chain (`append_tied`, as `ABC::VoiceState`); `~` with no pending note → "A tie must follow a note"; tie then rest/`\key`/`\time`/end → "A tie must be followed by a note"; tie then `|` → "Ties across bar checks are not yet supported".

### Structure (DocumentReader) and building (CompositionBuilder)

`DocumentReader` is a recursive descent over the token array with a context stack (`:document`, `:score`, `:header`, `:with`, `:staff`, `:voice`, `:music`) and a pitch-reader stack. Rules:

- Command dispatch through a frozen hash `{"version" => :read_version, "header" => ..., "score", "layout", "midi", "new", "with", "relative", "absolute", "key", "time", "clef"}`; any other `\word` (commands and variable references share the syntax) → `UnsupportedFeatureError "Unsupported LilyPond feature \"\tuplet\""`. This one rule covers `\tuplet`, `\times`, `\chordmode`, `\lyricmode`, `\addlyrics`, `\partial`, `\bar`, `\tempo`, `\mark`, `\repeat`, `\transpose`, `\fixed`, `\language`, `\grace`, `\markup`, `\include`, dynamics, articulations and `\melody`.
- Contexts: `\new Staff`/`\new Voice [= STRING] [\with { instrumentName = STRING }]`; a `\new Voice` inherits the enclosing Staff's `instrumentName` as its role when it has none; other `\with` assignments ignored; `= STRING` names consumed and ignored. A context yields a voice when it has events, or when it is explicit and has no child contexts (so `\new Staff { }` is a legitimate empty voice, matching the writer's empty-voice fixture, while `\new Staff { \new Voice { ... } }` yields exactly one voice). The implicit root context (bare `{ }` / `\relative c' { }`) yields a voice only if it has events. Voice order = document order. Two sequential `\new Voice` blocks in one Staff → two voices. `\new` of any other type → `UnsupportedFeatureError`.
- `<< >>` items must each start with `\new` (optionally wrapped in `\relative`/`\absolute`), else `UnsupportedFeatureError "Simultaneous music without \new contexts"`.
- `\key NOTE \MODE` → `KeyReader`: note token must have no marks/duration; mode must be a `:command` in the inverted table else `ParseError "Unrecognized mode \"\blues\" in \key command"`; tonic built as ASCII (`F#`, `Bb`); double-altered tonics → `ParseError`; then `KeySignature.get("#{tonic} #{scale_type}")`.
- `\time NUMBER` → `MeterReader`: lexeme must match `/\A(\d+)\/(\d+)\z/`, top ≥ 1, bottom a power of two in 1..256, else `ParseError "Invalid \time signature \"4/3\""`. Non-negotiable given the `Position` hang.
- Chords: only `:note` tokens without durations inside (`ParseError "Chord notes cannot carry durations"`); `<>` → `ParseError "Empty chord"`; duration on the `:close_chord` token.
- Stray `:word`/`:number`/`:string`/`:equals` in music → `ParseError "Unexpected token \"foo\""`.

`Document#first_key_signature`/`#first_meter`: the first `:key`/`:time` event in stream order that precedes any note/rest in its stream; absent → `Composition` defaults (C major, 4/4 — also LilyPond's defaults; pin in a spec).

`CompositionBuilder#composition`: `Composition.new(name: title, key_signature: first_key, meter: first_meter, composer:)`; for each yielded stream `add_voice(role:)` and replay events, always placing at `voice.next_position`. `:bar_check` → raise `ParseError "Bar check failed at: 1/2 in bar 2"` unless `next_position.count == 1 && tick.zero?` (elapsed fraction summed from the bar's placements via `DottedDuration.dotted_unit_fraction`). `:whole_bar_rest` → fraction must equal `Rational(meter.top_number, meter.bottom_number)` of `composition.meter_at(bar)` at a bar start, else `UnsupportedFeatureError`. `:key`/`:time` → `apply_change`: not at a bar start → `UnsupportedFeatureError "\key mid-bar"`; bar 1 → must equal the composition's seed else `ParseError "Conflicting \key at bar 1"`; bar > 1 → no-op when `key_signature_at(bar)`/`meter_at(bar)` already equals it, `change_key_signature`/`change_meter` otherwise, `ParseError "Conflicting \time at bar 3"` if the bar already holds a different explicit value. No voices → `ParseError "LilyPond input contains no music"`. `Parser#composition` assigns the memo only after the builder returns.

### Error-handling contract

`ParseError` (malformed): blank input (`"LilyPond input is blank"`), invalid UTF-8, unexpected character, unterminated string/block comment, unbalanced `{}`/`<< >>` (reported at the opener's line), notes outside braces, unexpected token, unrecognized duration/too many dots/zero multiplier denominator, pitch out of range, argument shape of `\key`/`\time`/`\clef`/`\relative`/`\version`, unrecognized mode, invalid time signature, the four tie errors, bar check failure, conflicting key/time, empty chord, chord note with duration, no music. `UnsupportedFeatureError` (valid LilyPond outside v1): every unknown `\command`, `\new` of non-Staff/Voice, `\`, `#` Scheme, `[ ] ( )`, articulations, `s` spacers, `*` on notes, multi-bar `R`, non-string header values, variable assignments, second `\score`, `<<` without `\new` items or inside `\relative`, mid-bar `\key`/`\time`. Message grammar mirrors ABC: capitalised, offending lexeme in double quotes built with `%("#{lexeme}")` (not `.inspect`, which doubles backslashes), the ` (line N)` suffix added by the error class; messages echo the source token (`fis'`), never `Pitch#to_s` (Unicode `♯`/`𝄪`). Every rudiment call that can raise or return nil is gated by validation, so nothing outside the `ParseError` family escapes.

### Steps

1. **Extract the writer fixtures and toolchain helpers (pure refactor)**
   - Move every `let(:composition)` from `writer_spec.rb` into module `LilyPondFixtures` with one method each (`speed_the_plough`, `chromatic_air`, `rests`, `duo`, `key_and_meter_change`, `tacet`, `song`, `escaped_header`, `anonymous`, `air`); move `installed_lilypond`, `compile_quietly`, and the "a compilable document" shared example into `lily_pond_helpers.rb`; rewrite `writer_spec.rb` to consume them with no assertion changes.
   - Files: `spec/support/lily_pond_fixtures.rb`, `spec/support/lily_pond_helpers.rb`, `spec/head_music/notation/lily_pond/writer_spec.rb`
2. **`DottedDuration.rhythmic_value_for` and `StringText.unescape`**
   - Move the greedy decomposition out of `ABC::DurationResolver` (which keeps `validate_fraction!` and delegates); spec table 1, 3/4, 7/8, 5/4, 9/8, 1/3 → nil, 9 → nil; spec `unescape(escape(s)) == s` on the quotes/backslashes fixture strings; run the ABC specs.
   - Files: `lib/head_music/notation/dotted_duration.rb`, `lib/head_music/notation/abc/duration_resolver.rb`, `lib/head_music/notation/lily_pond/string_text.rb`, `spec/head_music/notation/dotted_duration_spec.rb`, `spec/head_music/notation/lily_pond/string_text_spec.rb`
3. **Facade, errors, `Parser` skeleton, `ParsePreflight.ensure_input_present`**
   - `parse`, `ParseError` (with `column:`), `UnsupportedFeatureError`; parser_spec input-validation and memoization examples mirroring `abc/parser_spec.rb`.
   - Files: `lib/head_music/notation/lily_pond.rb`, `lily_pond/parser.rb`, `lily_pond/parse_preflight.rb`, `spec/.../parser_spec.rb`, `spec/.../parse_preflight_spec.rb`
4. **`Token` + `Lexer`**
   - Every token type; multi-line block comments preserving line numbers; `%` inside a string; string escapes; aliases; lookahead words (`bass`, `treble`, `composer`, `Staff`, `instrumentName`); line/column (character-based); BOM; both unterminated errors; each `:unsupported` lexeme.
   - Files: `lily_pond/token.rb`, `lily_pond/lexer.rb`, `spec/.../lexer_spec.rb`
5. **`ParsePreflight.reject_unsupported_tokens` / `.ensure_balanced_delimiters`** + spec.
6. **`DurationReader`** — all 12 base durations, dots, carry-over including dots, `R` fractions, the error rows, and the inversion guard spec (every `DurationWriter::DURATIONS_BY_UNIT_NAME` value reads back to its unit).
   - Files: `lily_pond/duration_reader.rb`, `spec/.../duration_reader_spec.rb`
7. **`PitchReader` absolute** — `c`→C3, `c'`→C4, `c,,`→C1, five suffixes, aliases, out of range, inversion guard against `PitchWriter::ALTERATION_SUFFIXES`.
8. **`PitchReader` relative** — the oracle table above, default `f`, chord rule, `chord_pitches`.
   - Files: `lily_pond/pitch_reader.rb`, `spec/.../pitch_reader_spec.rb`
9. **`KeyReader` + `MeterReader`** — nine modes, `fis`→F♯ major, `es`→E♭ major, bad mode, marks rejected, double-altered tonic; `4/4`, `6/8`, `2/2`; reject `4/3`, `0/4`, `4`, `4/0`.
   - Files: `lily_pond/key_reader.rb`, `lily_pond/meter_reader.rb`, two specs
10. **`VoiceStream`** — event order, tie folding into one value, all tie errors, `music?`.
    - Files: `lily_pond/voice_stream.rb`, `spec/.../voice_stream_spec.rb`
11. **`Document` + `DocumentReader`** — header mapping and unescaping, `\score`/`\layout`/`\midi` skipping, `\version`, context yield rules and role inheritance, `\relative` stack (nested, default `f`, `\absolute`), `<<` rules, chords, `\clef`, every unsupported/unexpected path.
    - Files: `lily_pond/document.rb`, `lily_pond/document_reader.rb`, `spec/.../document_reader_spec.rb`
12. **`CompositionBuilder` + end-to-end parser spec**
    - Bar check pass/fail/overflow, key/time seeding, whole-bar rests (accepted in 4/4, 3/4, 5/4; multi-bar rejected), mid-piece changes duplicated across two voices idempotent, conflicts, mid-bar rejection; parser_spec: the story example asserting pitches G3 A3 B3 C4 D4 C4 B3 G3, eighth durations, G major, 4/4; comment-only and `{ }` inputs; the adversarial table (one row per error message, asserting the class and `/line \d+/`); a single-character-deletion mutation loop over the golden "Air" document asserting nothing outside `ParseError` escapes.
    - Files: `lily_pond/composition_builder.rb`, `spec/.../composition_builder_spec.rb`, `spec/.../parser_spec.rb`
13. **Round-trip helper and spec**
    - `expect_lily_pond_round_trip(composition)`: render → parse; compare `key_signature`, `meter.to_s`, `name`, `composer`, `voices.map(&:role)`; per voice, index reparsed placements by `position.to_s` and for every original placement assert equal sorted pitch strings and `rhythmic_value.to_s`; every reparsed placement with no counterpart must be a rest (the writer's `R1*n/d` padding — covers `duo`, `tacet`); `song` round-trips with syllables ignored; per bar compare `key_signature_at`/`meter_at`. Cover every fixture except no-voices, plus a non-ASCII header fixture (`"Ægir"`/`"Dvořák"`) and a chord/tie fixture.
    - Files: `spec/support/lily_pond_round_trip.rb`, `spec/head_music/notation/lily_pond/round_trip_spec.rb`
14. **Oracle spec (in `round_trip_spec.rb`)** — with `lilypond` present (skip otherwise): every hand-written parser input shape (relative excerpt, absolute duo with roles, chromatic relative, ties + rests, `R1*5/4` in 5/4, block comments, chord) compiles as authored and after `render(parse(source))`; each relative fixture parses equal to a hand-written absolute twin; every `LilyPondFixtures` composition's render compiles (routing every fixture shape, not just the golden one, through the toolchain).
15. **Polish** — README feature line, Quick Start snippet (single-quoted heredoc) and the supported-subset sentence; CHANGELOG `## [Unreleased]` / `### Added` "LilyPond import." entry; `bundle exec rubocop -a`; `bundle exec rake` for coverage.

### Design Considerations

- Inward = `Notation::LilyPond.parse`, outward = `Composition#to_lilypond`; do not add `Composition.from_lilypond` (no `from_abc` exists).
- Reject silently-wrong outcomes over permissiveness: unknown `\word` raises rather than being skipped, because skipping a `\transpose` or `\tuplet` would yield a plausible wrong composition.
- Keep `lib/` a pure text → object function: never follow `\include`, never evaluate `#(...)`; the `lilypond` binary is invoked only from specs.
- Inverse tables live as memoized class methods over the writer constants (single source of truth), each guarded by a spec that reads every writer value back.
- Error messages interpolate the LilyPond source lexeme, never `Pitch#to_s`/`KeySignature#to_s` (Unicode `♯`, `𝄪` render as tofu in CI logs); columns are character-based.
- Invalid UTF-8 raises a specific `ParseError`; a leading BOM is stripped; non-ASCII header text round-trips byte-for-byte (spec in step 13). No i18n for parse errors, consistent with ABC.

### Testing Strategy

Unit spec per helper (`described_class`, no stdout assertions); the oracle table for relative mode lives in `pitch_reader_spec.rb`; the adversarial error table and mutation loop in `parser_spec.rb` prove the error-class contract; the round-trip spec consumes the extracted writer fixtures so the export story's toolchain proof is automated; the oracle spec compiles every distinct input shape and every fixture with the real binary, skipping when absent. Coverage stays above 90% because every branch in the readers is a table row.

Acceptance-criteria mapping:

| Criterion | Spec |
| --- | --- |
| Entry point returns a Composition | `parser_spec.rb` (story example) |
| `\key` → key_signature | `key_reader_spec.rb`, `composition_builder_spec.rb` (seed + mid-piece), `round_trip_spec.rb` |
| `\time` → meter | `meter_reader_spec.rb`, `composition_builder_spec.rb`, `parser_spec.rb` |
| Octave marks and accidental suffixes | `pitch_reader_spec.rb` (absolute), `lexer_spec.rb` (aliases) |
| Durations, dots, carry-over | `duration_reader_spec.rb`, `parser_spec.rb` |
| Relative and absolute modes | `pitch_reader_spec.rb` (oracle table), `round_trip_spec.rb` (absolute twins) |
| Rests distinct from notes | `composition_builder_spec.rb`, `round_trip_spec.rb` (`rests` fixture) |
| Staff/Voice groupings → voices | `document_reader_spec.rb`, `round_trip_spec.rb` (`duo`, `key_and_meter_change`) |
| Comments and whitespace ignored | `lexer_spec.rb`, `parser_spec.rb` |
| Malformed input raises specifically, never partial | `parser_spec.rb` adversarial table + mutation loop, `parse_preflight_spec.rb` |
| Representative excerpt + focused cases | `parser_spec.rb` end-to-end; per-helper specs |
| 90%+ coverage | `bundle exec rake` |
| Round-trip of export fixtures | `round_trip_spec.rb` + oracle examples |

### Risks & Open Questions

The four owner-confirmation items are resolved; see the Decisions section above.

Risks and notes:

- `\time` validation is safety-critical: an unvalidated `0/4` hangs the process. The same hang exists in the ABC parser (`M:0/4`) — recommend a follow-up story adding a rudiment-level guard (`Meter.valid_time_signature?`) rather than widening this one.
- The relative-mode lexer ambiguity between note names and identifiers rests entirely on the `(?![A-Za-z])` lookahead and alias-first alternation; a missed case is a silently wrong pitch, hence the writer-word specs in step 4.
- `R1*5/4` re-renders as `r1 r4`, not `R1*5/4`; positions and durations survive, byte-level idempotence does not (no fixture depends on it).
- A hand-written note crossing a barline with no `|` parses (LilyPond auto-splits) but the writer's `Preflight` rejects re-rendering it — a parser/writer asymmetry, not a defect; pin in a spec.
- Steps 1 and 2 touch done-story code (`writer_spec.rb`, `ABC::DurationResolver`); both are behavior-preserving and covered by existing specs, but keep them as separate commits.
- Follow-up story candidates: `\`/`\voiceN` voices on one staff, `\partial` pickups, `\addlyrics` → `Placement#sing`, variables and `\include`, multi-bar rests, mid-bar key/time changes.

## Review

Reviewed 2026-09-03 at commit `7476e45` plus the uncommitted working tree (all implementation changes are uncommitted). Reviewers: product-manager (criteria), code-reviewer (quality, with the `lilypond` 2.26.0 binary as an oracle). Suite: 7478 examples, 0 failures, 99.75% line / 96.71% branch coverage; rubocop clean; rubycritic 86.73 (unchanged).

### Acceptance criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Documented entry point returns a `Composition` | ✅ | `lily_pond.rb` `self.parse`; README feature line, Quick Start heredoc, subset paragraph; CHANGELOG `[Unreleased]`. `parser_spec.rb` "the story's example". |
| 2 | `\key` → `key_signature` | ✅ | `key_reader.rb` inverts `KeyMapper`'s table; builder seeds from `Document#first_key_signature`. `key_reader_spec.rb` (13 modes, inversion guard, 7 error rows), `composition_builder_spec.rb` seed/change/no-op/conflict rows. |
| 3 | `\time` → `meter` | ✅ | `meter_reader.rb` rejects `0/4`, `4/0`, `4/3`, `4/512`; builder seeds and applies `change_meter`. `meter_reader_spec.rb`, `composition_builder_spec.rb`. |
| 4 | Octave marks and `is`/`es` incl. doubles | ✅ | `lexer.rb` `NOTE_PATTERN` (alias-first, lookahead); `pitch_reader.rb` absolute mode. `pitch_reader_spec.rb` table + inversion guard over `PitchWriter::ALTERATION_SUFFIXES`; `lexer_spec.rb` alias and word rows. Reviewer swept all 84 letter×suffix combinations against the binary: only the 28 quarter-tone names differ, and the model cannot hold those. |
| 5 | Durations, dots, carry-over | ✅ | `duration_reader.rb` (global carry, default quarter, dots carried). `duration_reader_spec.rb` (12 base durations, dots, carry across rests and chords, error rows). |
| 6 | `\relative` and absolute modes | ✅ | `pitch_reader.rb` fourth-reach rule; reader stack for nested `\relative`/`\absolute`, default `f`. Reviewer checked 23 cases with `\displayLilyMusic`; all match. `pitch_reader_spec.rb` oracle table; five relative/absolute twin pairs in `lily_pond_round_trip_spec.rb`. |
| 7 | Rests distinct from notes | ✅ | `VoiceStream` rest events carry no pitches. `composition_builder_spec.rb` "keeps rests distinct from notes"; `rests` fixture round trip. |
| 8 | Staff/Voice groupings → voices | ✅ | `document_reader.rb` contexts and `Context#voice?`. `document_reader_spec.rb` (bare, Staff∘Voice, empty Staff, parallel order, sequential Voices, role inheritance); `duo` and `key_and_meter_change` round trips. |
| 9 | Comments and whitespace ignored | ✅ | `lexer.rb` skips in-loop, never pre-strips. `lexer_spec.rb` (7 examples incl. line/column tracking across block comments), `parser_spec.rb` end-to-end. |
| 10 | Malformed input raises specifically, never partial | ⚠️ | Two-pass fail-before-building holds under 72,000 fuzz inputs and the two mutation loops in `parser_spec.rb`. Two targeted escapes remain (Important 1 and 2 below). |
| 11 | Representative excerpt + focused cases | ✅ | `parser_spec.rb` story example and full golden document (re-renders byte-identically); per-helper specs for pitch, octave, accidental, duration, relative, meter, key. |
| 12 | 90%+ coverage | ✅ | 99.75% line. |
| Notes | Round trip consumes the export story's golden fixtures | ✅ | `writer_spec.rb` now reads every fixture from `spec/support/lily_pond_fixtures.rb`; `lily_pond_round_trip_spec.rb` round-trips all 10 and compiles each with the binary, plus 13 hand-written inputs as authored and after parse-and-render. All 36 oracle examples ran. |
| Decision 1 | Chords in scope | ✅ | `read_chord`; relative chord rule. `document_reader_spec.rb`, `composition_builder_spec.rb`, chord round trip and twin. |
| Decision 2 | Bar-check mismatch raises | ✅ | `composition_builder.rb` "Bar check failed at: 3/4 in bar 1". Underfilled, overfilled, tick-level rows. |
| Decision 3 | Unknown header fields ignored | ✅ | `document_reader.rb` `read_assignments`; `tagline`/`subtitle`/`shortInstrumentName` ignored, non-string values raise. |
| Decision 4 | Intra-bar ties | ✅ | `voice_stream.rb` folds into one `tied_value` chain; tie across `|` raises. All five tie errors specced. |

### Code review findings

**Important**

1. **`Encoding::CompatibilityError` escapes the `ParseError` family.** `parser.rb` runs `ParsePreflight.ensure_input_present` before the lexer, and its `strip` raises on a UTF-8-tagged string with invalid bytes, before the lexer's own UTF-8 guard can run. `File.read` returns UTF-8-tagged strings, so a `.ly` file saved in Latin-1 with an accented composer name hits this. Confirmed by running it. Fix: make the blank check encoding-safe (`to_s.b.strip.empty?`) or move it after lexing.
2. **`SystemStackError` on deeply nested braces.** `read_sequential` recurses through `read_music_item` with no depth bound while the lexer and balance check are iterative, so nesting around 6000 deep passes preflight and overflows the reader. Confirmed at 8000. Purely adversarial. Fix: a depth counter in `read_music_expression` raising `ParseError "Music expressions are nested too deeply"`.
3. **`append_tied` is byte-identical to `ABC::VoiceState#append_tied`**, the largest flay hit in the module (mass 96), and the same-pitch guard and its message duplicate too. The story handled exactly this for `DottedDuration` and did not follow through here. A shared `HeadMusic::Notation::TiedValue.append(head, tail)` beside `DottedDuration` would close it.
4. **`apply_key_signature` and `apply_meter` are structurally identical** in `composition_builder.rb` (flay mass 86), differing only in four method names.
5. **Three specs would pass with the behavior they name broken.** `voice_stream_spec.rb` "ties chords with the same pitches in any order" asserts only the event count; `composition_builder_spec.rb` "treats a restated key as a no-op" asserts only that nothing raises; `meter_reader_spec.rb` "returns the same meter the rudiment resolves" is tautological.

**Minor**

- `lily_pond_round_trip_spec.rb`: the `include LilyPondRoundTripSources` is dead (every reference is fully qualified); the relative/absolute twin examples compare two renders through the same writer rather than pinning one side to a pitch list; oracle examples are named by ordinal ("input 7") rather than by the descriptive keys the tables already have.
- `composition_builder_spec.rb`: three bar-check "passes" examples are `not_to raise_error` where asserting placements would pin the boundaries.
- Four `equal(x)` memoization examples pin `||=` rather than behavior; the "does not memoize a failure" example is the one that matters.
- `lexer_spec.rb` suffix table is a self-map; an array says the same. Three error tables could be collapsed (`key_reader_spec.rb` five identical "expects a pitch and a mode" blocks, `voice_stream_spec.rb` four "must be followed by a note", `document_reader_spec.rb` three "Duration multipliers").
- Quarter-tone note names (`cih`, `ceh`, …) surface as `Unexpected token` rather than an `UnsupportedFeatureError` naming the quarter tone. `lexer.rb` interpolates an unexpected character raw, so a NUL byte renders invisibly; `inspect` would read better.

**Verified sound**

- Relative-mode algorithm matches the binary on 23 cases including chord-internal relativity, nested `\relative`, `\absolute` inside `\relative`, and the default `f` reference.
- The `DottedDuration` refactor is behavior-preserving: old and new resolvers agree on 270 values; three unreachable-unit error messages differ only in wording, with the new text the more accurate.
- No nil-tonic key signature leaks across 9 modes × 8 tonics. Every listed hostile input (`\key` at EOF, `<<` inside chords, `R1*0`, `\time 0/4`, NUL bytes, `R1*1000000`, nested `\score`) lands as a `ParseError` with a line number.
- `Voice#place` is O(n²) (4000 notes in 6.8s), but that is `HeadMusic::Content`, shared with ABC, and not introduced here.

### Scope notes from the product review

- The shipped unsupported set is wider than the story's out-of-scope list: mid-bar `\key`/`\time`, multi-bar and non-bar-filling `R`, `*` multipliers, `s` spacers, `\\`, `\partial`, `\bar`, `\tempo`, `\repeat`, `\transpose`, `\fixed`, `\grace`, `<< >>` without `\new` items or inside `\relative`, `\include`, Scheme, and `[ ] ( )` all raise `UnsupportedFeatureError`. Worth enumerating in the finish notes.
- The round-trip spec lives at `spec/head_music/notation/lily_pond_round_trip_spec.rb`, not under `lily_pond/` as the plan said, to satisfy the spec-path cop for a spec describing the `LilyPond` module.
- A note crossing a barline with no `|` parses but will not re-render (pinned in `parser_spec.rb`); `R1*5/4` re-renders as `r1 r4` (pinned). Both were predicted in the plan.

### Blocks finish

Important 1 and 2 contradict criterion 10 and should be fixed before finish; both are small. Important 3 through 5 are quality items the owner may take now or defer.

### Resolution (2026-09-04)

All findings were taken. The blank-input check now strips on raw bytes so the lexer's UTF-8 guard is reached; the reader bounds nesting at 1000 levels and raises a `ParseError` beyond it; tie appending moved to `RhythmicValue#append_tied`, shared by both parsers; the key and meter appliers collapsed into one parameterized method; quarter-tone names lex as unsupported; invisible characters are named by their escape; and every spec noted above was tightened, collapsed into a table, or removed. Re-validated: 7492 examples, 0 failures, 99.75% line coverage, rubocop clean, rubycritic 86.92.
