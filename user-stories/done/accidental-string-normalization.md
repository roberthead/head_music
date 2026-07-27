<!--
metadata:
  created_at:   2026-07-26T18:56:39-07:00
  activated_at: 2026-07-26T19:28:59-07:00
  planned_at:   2026-07-26T20:05:31-07:00
  finished_at:  2026-07-27T07:27:30-07:00
  updated_at:   2026-07-27T07:27:30-07:00
-->

# Story: Accidental String Normalization

## Summary

AS a developer building on head_music
I WANT a string utility that converts accidentals between ASCII and canonical Unicode
SO THAT every consumer stops hand-rolling its own `gsub` chain and getting the double accidentals wrong

## Acceptance Criteria

### The utility

- A public utility converts ASCII accidentals in a string to canonical Unicode: `Bb` → `B♭`, `F#` → `F♯`, `Bbb` → `B𝄫`, `Cx` → `C𝄪`.
- **`##` converts to `𝄪`.** It's the notation most writers reach for, and the gem currently rejects it outright.
- The reverse direction is public too: Unicode → ASCII, emitting the spellings the gem's own parsers accept (`x` for double sharp, not `##`).
- Both directions are **idempotent** — running either on already-converted text is a no-op.
- Conversion is **all-or-nothing per accidental.** A double never half-converts; `C##` yields `C𝄪`, never `C♯#`.
- The utility handles a bare accidental token, a pitch name, and accidentals embedded in prose.
- English words containing accidental-shaped substrings are untouched: "Above", "Absence", "Bebop", "ebb", "back".

### Consistent behavior across the gem

- **`##` is recognized everywhere `bb` is**, removing the asymmetry between the two doubles. `Alteration.get("##")` resolves to `double_sharp` and `Spelling.get("C##")` returns `C𝄪`, matching how `bb` already behaves.
- **Every hand-rolled conversion in the gem is replaced by the utility**, and the `gsub`/`tr` chain it replaced is deleted. The full list is in the Notes; none is left behind as a second implementation.
- Any two call sites given the same input produce the same output. Today they don't: `instrument_name.rb` renders `Bbb` as `B♭♭` while `Spelling` renders it `B𝄫`.
- A characterization spec pins the behavior of each migrated call site so the consolidation is provably lossless — the ABC notation writers in particular have consumers that reject Unicode.

## Notes

### Why this exists

Every consumer of the gem that needs to display or accept accidentals writes its own conversion, and they disagree with each other. This story consolidates that into one tested utility.

The immediate trigger: `bardtheory` needed to normalize drafted dictionary definitions and built `app/services/accidental_converter.rb` locally — six anchored regex rules plus a residue detector. It works, but it's the fourth or fifth independent implementation of this idea across the two repos, and it deliberately refuses to handle doubles because the gem gives it nowhere good to land them.

### What the gem has today (verified 2026-07-26)

**Correct glyph data exists** — `lib/head_music/rudiment/alterations.yml`, loaded at `alteration.rb:14-15`:

| identifier | semitones | ascii | unicode | html_entity |
| --- | --- | --- | --- | --- |
| `double_flat` | -2 | `bb` | `𝄫` | `&#119083;` |
| `flat` | -1 | `b` | `♭` | `&#9837;` |
| `natural` | 0 | `` | `♮` | `&#9838;` |
| `sharp` | 1 | `#` | `♯` | `&#9839;` |
| `double_sharp` | 2 | `x` | `𝄪` | `&#119082;` |

The glyphs are the correct single codepoints — 𝄫 U+1D12B and 𝄪 U+1D12A, not the doubled-single fallback `♭♭`/`♯♯`. This is the right foundation; the story is about exposing it, not fixing it.

**A pitch-name round-trip works** via parse-then-`to_s`, and it already handles doubles:

```ruby
Spelling.get("Bb")   # => "B♭"
Spelling.get("Bbb")  # => "B𝄫"
Spelling.get("Cx")   # => "C𝄪"
Spelling.get("C##")  # => nil     <-- the gap
```

**`##` is not recognized.** `Alteration::PATTERN` (`alteration.rb:19-20`) is:

```ruby
/𝄫|bb|♭|b|♮|♯|\#|𝄪|x/
```

`#` appears as a single alternative with no two-character branch, so `Alteration.get("##")` returns `nil` and `Spelling::MATCHER` (`spelling.rb:11`) rejects `"C##"` entirely. Double flat is spelled `bb` and works; double sharp is spelled only `x`. That asymmetry is the surprising part, and it's what makes `##` the specific thing to fix.

**No general string utility exists.** There is no `to_unicode`, `normalize`, `canonical`, or `glyph` method in `lib/`. `Spelling`/`Pitch` expose an `Alteration` but have no `ascii`/`unicode` method of their own.

### The hand-rolled implementations to replace

- `lib/head_music/instruments/instrument_name.rb:47` — `format_pitch_name`, a private `tr("b", "♭").tr("#", "♯")`. **Singles only, and it corrupts doubles**: `"Bbb"` becomes `"B♭♭"`, and `"Above"` would become `"A♭ove"` if it ever saw prose.
- `lib/head_music/rudiment/key_signature.rb:21` and `lib/head_music/rudiment/scale.rb:13` — inline `gsub(/#|♯/, "sharp").gsub(/(\w)[b♭]/, '\1flat')`, singles only.
- `lib/head_music/notation/abc/key_mapper.rb:53` and `abc/pitch_writer.rb:53` — manual `alteration&.ascii` concatenation for the Unicode → ASCII direction.
- `lib/head_music/notation/abc/key_mapper.rb:7` — `KEY_PATTERN = /\A([A-G])([#♯b♭]?)\s*([A-Za-z]*)/`, singles only.
- `lib/head_music/utilities/hash_key.rb:32-40` — `desymbolized_string` maps accidentals to word suffixes. Handles both doubles, but targets snake_case symbols rather than notation. Note the ordering: `gsub("♯", "_sharp")` runs before `gsub("𝄪", "_double_sharp")`, harmless only because `𝄪` is a distinct codepoint — worth tidying while nearby.

Downstream in `bardtheory`:

- `app/services/accidental_converter.rb` — six anchored rules for pitches, Roman numerals, and scale degrees, plus a residue detector. Deliberately declines doubles. Should collapse onto this utility once it exists, keeping only its Roman-numeral and scale-degree rules, which are notation the gem doesn't model.
- `app/services/pivot_chord_service.rb:127` — `gsub("♭", "b").gsub("♯", "#").gsub("\u{1D12B}", "bb")` for the Unicode → ASCII direction. **Omits `\u{1D12A}` (𝄪)**, so a double sharp survives as Unicode and then fails the `Pitch.get` that consumes it.

### Design notes for whoever picks this up

**Prose is the hard part, not pitch names.** A pitch name has a known shape; prose does not. The rule that makes prose safe is anchoring every pattern to a musical context rather than to a bare `b` or `#`. Two findings from bardtheory's implementation, both measured against a real 65-document corpus, are worth inheriting:

1. **No `/i` flag.** Case-insensitivity has a real false positive: `B7` (a B dominant seventh) becomes `♭7`. Every genuine flat-degree is lowercase; every pitch name is uppercase. Case-sensitivity separates them for free.
2. **`(?![a-z])`, not a trailing `\b`.** A literal `\b` correctly rejects "Above" and "Absence" but also rejects `Ab7`, a genuine flat. The negative lookahead does both correctly.

**Half-conversion is the failure mode to design against.** A naive single-accidental rule applied to `C##` converts the first symbol and leaves `C♯#` — worse than not converting, because it looks converted. Match doubles before singles.

**`##` is accepted everywhere, not just by the utility** (decided 2026-07-26). Widen `Alteration::PATTERN` so `Spelling.get("C##")` works, rather than having the utility pre-map `##` → `x` and leaving the grammar asymmetric. Widening changes parsing behavior for existing callers, so it wants the characterization specs above — but the alternative leaves the gem permanently accepting `bb` while rejecting `##`, which is the confusing state this story exists to end.

Note the ordering constraint this creates: `##` must be matched **before** the single `#` alternative in `PATTERN`, or the regex engine takes the single and leaves a stray `#`. The same applies to `bb` before `b`, which the current pattern already gets right.

**Naturals are a live question.** `natural`'s `ascii` is the empty string, so `Alteration.get("")` returns `nil` and `Spelling.get("C").to_s` is `"C"` — naturals never render as `♮`. Whether the utility should ever *emit* `♮` needs deciding; the safe default is no.

**The downstream consumer is a real constraint, not hypothetical.** `bardtheory` has a story waiting on this one (`accidental-converter-on-head-music`), and its `AccidentalConverter` is the closest thing to a reference implementation for the prose case — six anchored rules, measured against a 65-document corpus. Worth reading before designing the prose matcher rather than starting cold.

## Learnings

### Measurement beat intuition every time it came up

Three design questions were settled by running candidates against a real corpus rather than reasoning about them, and in each case the measured answer differed from the plausible one:

- Extending the chord-quality allowlist to `x` looks symmetric with extending it to `b`. It costs `Axminster`, `Exmoor`, `Axman`, `Axion` and buys only `Cxm7`, which is not real notation.
- Including mode words (`dor`, `ion`, `lyd`) in the allowlist looks obviously right for a music gem. It costs five `Ebion*` words and buys nothing, because space-free mode syntax is ABC input that reaches `KEY_PATTERN`, not this utility.
- `sus` clears `Absurd` by one letter; `dim` clears `Abdomen` and `Abdicate` by one. Nothing about that is visible by inspection.

The measurements are now pinned as specs, so the next person doesn't have to re-derive them — and can't silently break them.

### Characterization specs inherit the blind spots of whoever writes the migration

The most useful finding of the whole story. A 21-key ABC no-Unicode guard was written *specifically* to catch unicode leaking into a `K:` field. The leak that actually happened was on a natural-spelled tonic, and every key in the sample had a plain or accidental tonic. Right idea, wrong sample, zero protection.

The same shape recurred in the hostile-input corpus for the extension rule: every case started with a digit or lowercase (`1.0b2`, `0x1b2f`, `1b2c3d`), so the letter-initial shape (`Figure C2b3`, `A1b2`) was entirely unpinned. **Collecting examples is not the same as varying the shape systematically.** When building negative test cases, enumerate the structural variants first, then find an instance of each — not the other way round.

This is a direct argument for adversarial review by someone who didn't write the code. Both blind spots were found by review, and neither could have been found by the specs as written.

### Widening a parser is not symmetric with widening a writer

Making `KEY_PATTERN` accept `##` also made it accept `Cx` as an ABC tonic, which produced a confident wrong answer — `C𝄪 major`, "no sharps or flats" — where the narrow pattern had raised a clean `ParseError`. The writer already refused to render such a tonic, so reader and writer silently disagreed.

**Replacing an error with a plausible lie is a regression even when no test fails.** Any time a pattern is widened, ask separately what the *other* direction now has to reject.

### Check where a test actually runs before trusting it

The word-list sweep read the host's `/usr/share/dict/words` and asserted a macOS-specific result. CI runs `ubuntu-latest`, which has no such file, so the spec skipped — the guard it promised never ran where it mattered, and would have failed spuriously on a Linux box with a different word list. Vendoring a fixture made it deterministic and real. A skip is not a pass.

### Check whether an "out of scope" is yours or inherited

Altered extensions (`Bbmaj7#11`) were deferred because the plan grouped them with Roman numerals and scale degrees. Challenged, the grouping didn't survive: `#11` is part of a chord symbol, a Roman numeral isn't. The work took about ten minutes and closed a real gap — half-converting a chord symbol is the same failure mode as half-converting a double.

The lesson is not "be more ambitious." It's that a scope boundary copied from an upstream document should be re-derived before it's defended.

### Parallel review with different mandates found disjoint defects

The product-manager and code-reviewer agents ran concurrently over the same commit and their findings barely overlapped. The PM found the natural-sign leak and the missing acceptance-criteria pins; the reviewer found the parse-side asymmetry, the CI fragility, and the locale-dependent memoization. Neither would have surfaced the other's set. Two mandates, not two passes.

### Verify the plan's own claims

The plan asserted `KeySignature.get("C bebop")` hashed to `:c_be_flatop`. True of the `gsub` in isolation, unreachable through the public API — `bebop` is not a scale type this gem defines. One claim in maybe forty, but it had a spec written against it before it was checked. Plans are evidence, not fact.

### Accepted debt

Criterion 10 ("none is left behind as a second implementation") is **partially met, accepted deliberately**. `lib/head_music/utilities/hash_key.rb` still hard-codes all five glyphs, mapping glyph → word suffix (`♭` → `_flat`). That is a third direction the utility doesn't model, so it is duplication of the glyph *inventory* rather than a competing conversion. The list is small, stable, and now spec-covered. Deriving it from `Alteration` remains a clean follow-up if the inventory ever grows again.

## Review

Reviewed 2026-07-26 against commit `75e54ee` by a product-manager agent (acceptance criteria) and a code-reviewer agent (quality and correctness), running in parallel. Every finding below was independently reproduced before being acted on. Fixes are uncommitted at the time of writing; the suite is at **6316 examples, 0 failures**, RuboCop clean, no vulnerabilities, 99.70% line coverage, RubyCritic 87.94.

### Acceptance criteria

| # | Criterion | Verdict |
| --- | --- | --- |
| 1 | ASCII → canonical Unicode (`Bb`, `F#`, `Bbb`, `Cx`) | ✅ met |
| 2 | `##` converts to `𝄪` | ✅ met |
| 3 | Reverse direction public, emits `x` not `##` | ✅ met |
| 4 | Both directions idempotent | ✅ met — swept 30,000 words plus the full corpus, zero non-idempotent inputs |
| 5 | All-or-nothing per accidental | ✅ met for valid notation; `C###` → `C𝄪#` is now pinned as known residue |
| 6 | Bare token, pitch name, prose | ✅ met, all three tested |
| 7 | English words untouched | ✅ met — independently re-measured over 235,976 words |
| 8 | `##` recognized everywhere `bb` is | ✅ met; the two assertions the story names verbatim had **no spec** and now do |
| 9 | Any two call sites agree | ✅ met for uppercase input; the lowercase divergence is real and now documented |
| 10 | Every hand-rolled conversion replaced | ⚠️ **partially met** — see below |
| 11 | Characterization spec per migrated call site | ✅ met after fixes; three sites had no spec at review time |

### Findings fixed during review

**1. ABC regression — unicode leaking into a `K:` field (blocking).** `KeyMapper.abc_value(KeySignature.get("C♮ major"))` returned `"C♮"`. The migration replaced a concatenation that dropped naturals for free (`Alteration#ascii` is `""` for a natural) with `to_ascii`, which preserves `♮` by design. The double-altered guard above it catches doubles but not naturals. Fixed by dropping the natural explicitly at the ABC boundary. **This is exactly what the ABC guard specs existed to catch and didn't** — all 21 keys in the guard list had a plain or accidental tonic, never a natural one.

**2. ABC reader accepted what the writer refuses (blocking).** Widening `KEY_PATTERN` to the full `Alteration::PATTERN` was necessary for the `(?:...)` fix, but it also admitted `bb`, `##`, and `x` as tonics. `K:Cx` parsed to `C𝄪 major` reporting "no sharps or flats" — musically wrong — where the narrower pattern used to raise a clean `ParseError`. A plausible-looking wrong answer is worse than an error. Fixed by mirroring the double-altered guard on the parse side.

**3. The extension rule fired on non-chord identifiers.** `Figure C2b3` → `Figure C2♭3`, `A1b2` → `A1♭2`. The chord-token scope blocks digit-initial strings (`1.0b2`, `0x1B2F`) but not letter-initial ones, and every hostile case in the spec started with a digit or lowercase letter, so the whole shape was unpinned. Fixed by requiring the altered degree to be a real chord extension (`EXTENSION_DEGREES = %w[13 11 9 6 5 4]`). Measured: eliminates all seven false positives with zero must-convert regressions and an unchanged dictionary baseline.

**4. The dictionary spec was green-by-skip on CI.** It read the host's `/usr/share/dict/words` and asserted exact equality against a macOS `web2`-specific result (`Abmho` is a web2-ism). CI runs `ubuntu-latest`, which has no such file — so the guard the comment promised never ran where it mattered, and would have failed spuriously on a Linux box with `wamerican`. Replaced with a vendored 2,391-word fixture (`spec/support/fixtures/prose_words_at_risk.txt`) containing every capitalized word whose second character could begin an accidental — the exact set the guards protect.

**5. Three migrated call sites had no characterization spec** despite being plan steps: `Note::PITCH_PATTERN`, `HashKey`, and the whole-document ABC guard. All three now pinned.

**6. `representations` memoization froze a locale-dependent value.** `#name` resolves through `I18n.locale`. Inert today (only `:en` names are registered), but latent: once the German names in `locales/de.yml` are wired up, `Alteration.get("Kreuz")` would depend on which locale was active at first call. Now memoized per locale, with the duplicate entries the widening introduced deduped.

**7. Two undocumented narrowings.** The utility is deliberately case-sensitive and reads a bare token as an accidental, so `to_unicode("eb")` is `"eb"` while `Spelling.get("eb")` is `E♭`, and `to_unicode("bb")` is `𝄫` while `Spelling.get("bb")` is `B♭`. Both follow from being safe over prose. Now stated in the class comment, the CHANGELOG, and specs.

**8. Minor.** `ascii_matcher`/`unicode_matcher` made private (no external consumer); the equal-length sort-stability caveat noted where it could mislead; a redundant map assertion dropped.

### Accepted, not fixed

- **`hash_key.rb` remains a second hard-coded glyph inventory** (criterion 10). It maps glyph → word suffix (`♭` → `_flat`), a third direction the utility doesn't model, so `to_unicode`/`to_ascii` genuinely cannot replace it — but the criterion as written says "none is left behind as a second implementation," and by the letter one is. Deriving it from `Alteration` is a reasonable follow-up.
- **`pitch_writer.rb` not migrated.** Correct: it's a lookup key into `ACCIDENTAL_FRAGMENTS.invert`, not a conversion, and the `""` → `"="` entry means natural must stay in the map. The `#ascii` invariant it depends on is now pinned.
- **`C###` → `C𝄪#` half-converts** while `Bbbb` is left whole. Neither is valid notation; the asymmetry is recorded as a spec rather than hidden.
- **`dyad_spec` pins a private method and two magic counts.** Deliberate — the surrounding assertions are `be_an(Array)`, which is what let the 28 → 35 change pass silently in the first place.

### Verified sound

No reachable `KeyError` in either gsub block (every alternative derives from the same map; `CHORD_QUALITIES` and `EXTENSION_DEGREES` appear only in zero-width lookaheads). Both regex-interpolation fixes are correct with unchanged capture counts, and `pitch/parser.rb` and `spelling.rb` were correctly left alone — they already wrap the interpolation in a group. `nil`, `""`, frozen strings, newlines, and already-converted input all behave. No ReDoS: 50,000 words in 33ms.

## Implementation Plan

### Overview

Add `HeadMusic::Utilities::Accidentals` — a class-method-only utility mirroring `Utilities::Case` — that derives its ASCII↔Unicode maps **lazily** from `Alteration.all`, keeping `alterations.yml` the single source of truth. Add `##` as a second `symbols:` record under `double_sharp`, sort `SYMBOLS` longest-first, and widen `representations` to span all symbol records. Then delete each hand-rolled chain — or, where the input is already Unicode, delete it in favor of nothing at all.

The forward direction converts **whole chord symbols**, not just pitch names: `Bbmaj7#11` → `B♭maj7♯11`. It does this by scoping conversion to a candidate chord token, which is what makes the altered-extension rule safe to include at all.

The planner reports verifying the change set against patched scratch copies: the full suite passes all 6097 examples with exactly two failures, the hard-coded regex literals at `alteration_spec.rb:101-102`, which should be behavioral regardless. Re-verify during implementation rather than trusting this.

### Decisions on the open questions

**1. Home: `HeadMusic::Utilities::Accidentals`, required at `lib/head_music.rb:57`.**

Load order is a non-issue *because every `Alteration` reference sits inside a memoized class method* — nothing touches it at class-definition time. This matters more than it looks: a file at line 58 referencing `Alteration::PATTERN` eagerly raises `uninitialized constant HeadMusic::Rudiment` (the *module* doesn't exist yet), and `Alteration.all` is poisoned at **every** load point because `initialize_musical_symbols` instantiates `Notation::MusicalSymbol`, unavailable until line 156. Lazy memoization dissolves both. This also rules out a `Notation` home — `Rudiment` would then depend on a module loaded 90 lines later — and rules out `Alteration` itself, a value object with `private_class_method :new`.

**2. The `(?![a-z])` guard is per-alternative, and flats additionally take a chord-quality allowlist.** *(refines the story's settled note; decided 2026-07-26)*

Applied uniformly the guard is a false-negative machine — `F#m`, `A#m`, `C#maj7`, `F#dim` all silently unchanged, and `key_mapper.rb`'s own doc comment cites `F#m` as its motivating input. `#` cannot occur in an English word, so the guard is pure cost there. That fixes the sharp side but leaves an asymmetry: `F#m` converts while `Bbm` and `Ebmaj7` do not, because the flat side must keep its guard or `Above` breaks.

**That asymmetry is not acceptable — all three must convert.** Closed by giving the flat branch an escape hatch: match when followed by a non-lowercase character **or** by a lowercase chord quality. So the three branches are:

| branch | rule | why |
| --- | --- | --- |
| `##`, `#` | no guard | cannot occur in an English word |
| `bb`, `b` | `(?![a-z])` **or** `(?=m\|dim\|aug\|sus)` | needs the guard for `Above`; needs the allowlist for `Bbm` |
| `x` | `(?![a-z])` only | allowlist here costs `Axman`, `Axminster`, `Exmoor` and buys only `Cxm7`, which is not real notation |

`m` subsumes `maj`, `min`, `mix`, and `m7`, so the list is four entries, not a chord vocabulary. Uppercase suffixes (`BbM7`) already pass the plain guard for free.

Measured against `/usr/share/dict/words` (235,976 words, each capitalized, since the `(?<=[A-G])` lookbehind only fires on uppercase):

| design | must-convert failures | dictionary false positives |
| --- | --- | --- |
| guard only, uniform | 10 | 5 (pre-existing: `Ab`, `Abb`, `Ax`, `Ebb`, `Ex`) |
| + allowlist on flats **and** `x`, incl. mode words | 0 | 23 (+18: `Axman`, `Axminster`, `Exmoor`, `Ebionism`…) |
| + allowlist on flats only, incl. mode words | 0 | 12 (+7) |
| **+ chord qualities on flats only** ← chosen | **0** | **7 (+2: `Abmho`, `Ebbman`)** |

Mode words (`dor`, `phr`, `lyd`, `ion`…) are deliberately excluded: they cost five `Ebion*` false positives and buy nothing, because space-free mode syntax (`Ebdor`) is ABC input, which reaches `KEY_PATTERN` in step 8 rather than this utility. Prose writes "E♭ Dorian" with a space.

Residual cost: `Abmho` and `Ebbman`, both capitalized, both absent from any plausible music-theory corpus.

**2a. Altered extensions are in scope too** *(decided 2026-07-26)*

`Bbmaj7#11`, `C7b9`, `G7#5b9`, `Db7b9#11` must convert fully, not just their pitch-name accidental. These have no letter name to anchor to — the accidental is flanked by digits — so they need a second rule, and applied globally that rule is unsafe (`1.0b2`, `0x1b2f`, `revision 2b1` all convert).

The fix is to scope conversion to a **candidate chord token** — an uppercase letter name that doesn't continue a longer word or number — and run both rules only inside it. Beta versions, hex literals, and `Figure 2b` never open such a token, so the digit-flanked rule can't reach them.

| rule | must-convert failures | false positives (29-case adversarial list) |
| --- | --- | --- |
| letter-anchored only (previous plan) | 9 | 0 |
| + naive digit-flanked, applied globally | 0 | 5 (`1.0b2`, `0x1b2f`, `1b2c3d`, `version 3b7`, `revision 2b1`) |
| **+ digit-flanked, scoped to a chord token** ← chosen | **0** | **0** |

The token-scoped version leaves the dictionary baseline byte-identical (same 7 words), stays idempotent, preserves all-or-nothing (`C##` → `C𝄪`, no stray `#`), and is ReDoS-free: 2.6ms on `"A" + "b" * 40_000`, 2.7ms on 250KB of prose. Note this also *strengthens* prose safety — the token boundary is a second line of defense behind the per-family guards, not a replacement for them.

Scale degrees (`b7`) and Roman numerals (`♭VI`) still stay downstream, and fall out for free: neither opens with an uppercase letter name, so neither enters a token.

**3. No `♮` in either direction.**

`to_unicode` *cannot* emit it: natural's `ascii` is `""`, filtered out of the map, so no token could trigger it. `to_ascii` leaves a literal `♮` untouched, because mapping `♮` → `""` is **lossy** — `Spelling.get("C♮").to_s == "C♮"` and `Pitch.get("C♮4").to_s == "C♮4"`, so `to_unicode(to_ascii("C♮"))` would yield `"C"` and destroy information the gem models. ABC distinguishes them too (`=C` vs `C`). Consequence to document: `to_ascii` is "ASCII for *altering* accidentals," not "pure ASCII."

**4. `##` via YAML second record + longest-first sort + widened `representations`.**

All three are required; each alone is insufficient. Sorting rather than reordering the YAML is deliberate — reordering would silently change `Alteration.all` and `ALTERATION_IDENTIFIERS` ordering, whereas the sort touches only the regex.

**5. Forward anchored, reverse unanchored.**

Unicode glyphs are unambiguous, so the reverse direction must have no letter-anchor, or `♭VI` and `♭7` — exactly what bardtheory feeds it — stop converting and the downstream consolidation fails.

### Recommended public API

```ruby
# lib/head_music/utilities/accidentals.rb
module HeadMusic::Utilities; end

# Converts accidentals in a string between ASCII spellings and canonical Unicode
# glyphs. Safe to run over prose: conversion happens only inside a token that opens
# with an uppercase letter name, so "Above", "Bebop", and "1.0b2" are untouched
# while "Bb", "Ab7", and "Bbmaj7#11" convert.
#
# Maps are derived from Alteration lazily rather than at load time, so this file can
# be required with the other utilities, before rudiments. Eager derivation is not an
# option anywhere in the load sequence: Alteration.all instantiates
# Notation::MusicalSymbol, which is not required until much later.
class HeadMusic::Utilities::Accidentals
  # A candidate chord symbol: an uppercase letter name that doesn't continue a longer
  # word or number, plus the chord-ish characters that may follow. One quantifier over
  # a character class -- no nesting, so no ReDoS surface. This is what scopes the
  # extension rule below: "1.0b2" and "0x1B2F" never open a token, so they can't reach it.
  CHORD_TOKEN = /(?<![A-Za-z0-9])[A-G][A-Za-z0-9#]*/

  # "Bb" => "B♭", "C##" => "C𝄪", "Bbmaj7#11" => "B♭maj7♯11". Idempotent.
  def self.to_unicode(text)
    string = text.to_s
    return unicode_for.fetch(string) if unicode_for.key?(string)

    string.gsub(CHORD_TOKEN) do |token|
      token.gsub(ascii_matcher) { |match| unicode_for.fetch(match) }
    end
  end

  # "B♭" => "Bb", "C𝄪" => "Cx". Emits the spellings the gem's parsers accept.
  # Deliberately NOT letter-anchored: unicode glyphs are unambiguous, and "♭VI"
  # must convert. A natural sign is left as "♮" -- mapping it to "" would turn the
  # valid spelling "C♮" into the different spelling "C". Idempotent.
  def self.to_ascii(text)
    text.to_s.gsub(unicode_matcher) { |match| ascii_for.fetch(match) }
  end

  def self.unicode_for
    @unicode_for ||=
      altering_alterations.flat_map(&:musical_symbols)
        .reject { |symbol| symbol.ascii.to_s.empty? }
        .to_h { |symbol| [symbol.ascii, symbol.unicode] }
  end

  # One entry per alteration, using its primary #ascii, so "##" is never emitted.
  def self.ascii_for
    @ascii_for ||= altering_alterations.to_h { |alteration| [alteration.unicode, alteration.ascii] }
  end

  # Chord qualities that may follow a flat without a word boundary, so that "Bbm"
  # and "Ebmaj7" convert while "Above" does not. "m" subsumes "maj", "min", and
  # "m7"; uppercase forms like "BbM7" already clear the (?![a-z]) guard unaided.
  # Mode words are excluded on purpose -- space-free mode syntax ("Ebdor") is ABC
  # input, which KEY_PATTERN handles, and "ion" alone costs five false positives.
  CHORD_QUALITIES = %w[m dim aug sus].freeze

  # Applied only inside a CHORD_TOKEN. Longest-first so a double never half-converts.
  # No /i flag -- case-insensitivity would read "B7" as "♭7".
  #
  # Two anchor contexts. The first is the pitch name's own accidental, anchored to the
  # letter name, with a per-family guard: "#" cannot occur in an English word at all,
  # "b" can but is rescued by the chord-quality allowlist, and "x" takes the bare guard
  # because an allowlist there buys "Cxm7" and costs "Axminster"/"Exmoor". The second is
  # an altered extension ("7#11", "7b9"), which has no letter to anchor to and is instead
  # flanked by digits -- safe only because CHORD_TOKEN already established we are inside
  # a chord symbol.
  def self.ascii_matcher
    @ascii_matcher ||=
      /(?<=[A-G])(?:#{sharp_branch}|#{flat_branch}|#{double_sharp_branch})|#{extension_branch}/
  end

  def self.extension_branch
    "(?<=\\d)(?:#{longest_first(unicode_for.keys.grep(/[#b]/))})(?=\\d)"
  end

  def self.unicode_matcher
    @unicode_matcher ||= Regexp.union(ascii_for.keys)
  end

  def self.sharp_branch
    longest_first(spellings_matching(/#/))
  end

  def self.flat_branch
    "(?:#{longest_first(spellings_matching(/b/))})(?:(?![a-z])|(?=#{longest_first(CHORD_QUALITIES)}))"
  end

  def self.double_sharp_branch
    "(?:#{longest_first(spellings_matching(/x/))})(?![a-z])"
  end

  def self.spellings_matching(pattern)
    unicode_for.keys.grep(pattern)
  end

  def self.longest_first(spellings)
    Regexp.union(spellings.sort_by { |spelling| -spelling.length }).source
  end
  private_class_method :sharp_branch, :flat_branch, :double_sharp_branch,
    :extension_branch, :spellings_matching, :longest_first

  def self.altering_alterations
    HeadMusic::Rudiment::Alteration.all.reject(&:natural?)
  end
  private_class_method :altering_alterations
end
```

The bare-token fast path (`unicode_for.fetch`) handles `"b"` → `"♭"` and `"##"` → `"𝄪"` without widening the regex, because a context-free `b` in prose is exactly the false positive the lookbehind exists to prevent. `to_ascii(to_unicode("C##")) == "Cx"` — the normalizing round trip the story asks for.

**Why two levels of `gsub` rather than one flat pattern.** The altered-extension rule (`7#11`, `7b9`) can't anchor to a letter name — the accidental is flanked by digits. Applied globally that rule is unsafe: it converts `1.0b2` (a beta version), `0x1b2f` (hex), and `revision 2b1`. Scoping it inside `CHORD_TOKEN` removes the entire class of false positive, because none of those strings opens a token with an uppercase letter name. Measured: the naive digit-flanked rule produces 5 false positives on a 29-case adversarial list; the token-scoped version produces 0, and leaves the 236k-word dictionary baseline byte-identical at the same 7 words.

### Steps

**1. Characterization specs — land first, green on unmodified code**

- **ABC no-Unicode guard** (highest value; ABC consumers reject Unicode). Add across the existing round-trip examples in `abc/writer_spec.rb`, `key_mapper_spec.rb`, `pitch_writer_spec.rb`: `expect(described_class.abc_value(key_signature)).not_to match(/[♭♯♮𝄫𝄪]/)` and the equivalent for `writer.token(pitch)` and the whole document. No such guard exists today.
- **`key_signature_spec.rb`** — the hash key is private, so pin the observable: memoization identity (`.get("Bb major")` equals itself), `.get("Bb major") == .get("B♭ major")`, `.get("Bbb major").name == "B𝄫 major"`, `.get("Fx major").name == "F𝄪 major"`.
- **`scale_spec.rb`** — same shape, plus `.get("Bb4","major").pitch_names.first == "B♭4"`.
- **`dyad_spec.rb`** — pin **exact counts**: `all_spellings.size == 28`, `Dyad.new("C4","E4").enharmonic_respellings.size == 5`. Existing assertions are `be > 0` / `be_an(Array)`, so the coming growth passes silently.
- **`alteration_spec.rb`** — pin `Alteration.get(:double_sharp).ascii == "x"`, the invariant `PitchWriter` silently depends on.
- **`instrument_name_spec.rb`** — extend the existing `"in B♭"` (line 12) and `"in F♯"` (line 17).

**2. Add the utility**

`lib/head_music/utilities/accidentals.rb` + `require` at `lib/head_music.rb:57` + `spec/head_music/utilities/accidentals_spec.rb`. No consumers yet; independently mergeable. Include a spec that the utility works on a cold `require "head_music"` with no prior `Alteration` use.

**3. Widen `##`**

`alterations.yml`: second `symbols:` record under `double_sharp` (`ascii: "##"`, keeping the `x` record **first**). `alteration.rb:18`: append `.uniq.sort_by { |s| -s.length }` (the `.uniq` is load-bearing — the YAML record otherwise duplicates `𝄪`). `alteration.rb:56-59`: memoize and widen `representations` to span all `musical_symbols`, or the new row is inert and `Spelling.get("C##")` returns a bare `C` — worse than today's honest `nil`. The memoization is reported as a 10x win (200k calls: `get(nil)` 3.55s → 0.38s, `get("#")` 2.68s → 0.16s), and `get` runs on every parse. `alteration.rb:26-28`: align `self.symbols` with `SYMBOLS` or delete it — it currently disagrees with `symbol?` and `PATTERN` and has zero callers. Replace `alteration_spec.rb:101-102`'s literal-regex assertions with behavioral ones (`expect("C##"[PATTERN]).to eq "##"`).

**4. Fix `rudiment/note.rb:20`**

`PITCH_PATTERN = /([A-G])(#{Alteration::PATTERN.source}?)(-?\d+)?/i` binds the `?` to the final `x` branch only; it works today by accident (the group can match empty only via `x?`). Change to `((?:#{...})?)`. Keep exactly 3 capture groups (`note.rb:38` reads `match[5]`); `Regexp.union` adds none (it emits `(?-mix:…)`), so `register.rb:30-34` stays safe.

Verified: `"C##4".match(PITCH_PATTERN).captures` is currently `["C", "#", nil]` — it truncates at the first `#` and loses the register entirely. The longest-first sort in step 3 fixes this case on its own, but the `?` binding is wrong regardless and should be corrected while here.

**4a. Full list of `Alteration::PATTERN` consumers** (grep-verified; step 3 widens the pattern under all of them)

- `rudiment/spelling.rb:11` — `MATCHER`, embeds it with `/i`. The primary target.
- `rudiment/note.rb:20` — `PITCH_PATTERN`, the `?`-binding bug above.
- `rudiment/pitch/parser.rb:12` — `(#{Alteration::PATTERN.source})?`. The `?` is correctly *outside* the group here, so this one is already right; no change needed, but it's the counter-example that makes the `note.rb` form recognizable as a mistake.
- `rudiment/pitch.rb:126` — `Pitch#natural`, `to_s.gsub(PATTERN, "")`. Widening is a strict improvement: it currently strips `C##4` to `C4` only because `#` matches twice; with `##` in the union it strips as one token. Verified `Pitch.get("C#4").natural.to_s == "C4"` today.
- `rudiment/register.rb:30-34` — consumes `Spelling::MATCHER`'s captures positionally; group count must not change.

**5. `instrument_name.rb:46-48`**

`format_pitch_name` becomes `Accidentals.to_unicode(pitch_designation)`; delete the `tr` chain. Spec-only impact: no catalog instrument uses a double (`pitch_key` values are `a a_flat b_flat c d e_flat f g`).

**6. `key_signature.rb:21`**

`HashKey.for(Accidentals.to_unicode(identifier))`; delete both `gsub`s. Differential over 33 inputs — 27 identical, 6 changed, all improvements:

| identifier | old | new |
| --- | --- | --- |
| `"Bbb major"` | `:b_flatb_major` | `:b_double_flat_major` |
| `"Fx major"` / `"Cx minor"` | `:fx_major` / `:cx_minor` | `:f_double_sharp_major` / `:c_double_sharp_minor` |
| `"C## major"` | `:c_sharp_sharp_major` | `:c_double_sharp_major` |
| **`"C bebop"`** | **`:c_be_flatop`** | `:c_bebop` |
| `"bb major"` | `:b_flat_major` *(collides)* | `:bb_major` |

The first four *unify* `Fx`/`C##`/`F𝄪` onto one cache entry — correct, they are the same key signature.

**Correction found during implementation:** the `"C bebop"` → `:c_be_flatop` mangling is real in the gsub but **unreachable through the public API** — `bebop` is not a scale type this gem defines, so `KeySignature.get("C bebop")` raises in `ScaleType` before the hash key matters. The `blues_*` scale types that *do* exist are unaffected, because `(\w)[b♭]` requires a word character before the `b` and theirs is preceded by a space. The spec written for this pins the reachable case (`C blues_minor_pentatonic`) instead.

**7. `scale.rb:12-14`**

Collapse to `HashKey.for([root_pitch, scale_type].join(" "))`. **No utility call needed:** `Pitch#to_s` already emits Unicode and `HashKey` already desymbolizes it, so the whole chain is dead (`\w` doesn't even match the astral `𝄫`/`𝄪`). Measured: `:bflat4_major` → `:b_flat4_major`, `:fsharp4_minor` → `:f_sharp4_minor`, no collisions. Also **delete `SCALE_REGEX` (line 6)** — unreferenced in `lib/` and `spec/`, and its `[#b]?` is the same singles-only trap this story closes.

**8. `key_mapper.rb:7`**

`KEY_PATTERN = /\A([A-G])((?:#{Alteration::PATTERN.source})?)\s*([A-Za-z]*)/`. **The inner `(?:...)?` is load-bearing:** writing `(...)?` makes `match[2]` `nil` and raises `TypeError: no implicit conversion of nil into String` at line 91 for every *unaltered* key — it breaks `C`, `Ador`, `Cmaj`, `Dm`. No mode word begins with `b`, `#`, or `x`, so the widened group cannot eat one (`Bloc`/`Blocrian` checked).

**9. `key_mapper.rb:53`**

`Accidentals.to_ascii(spelling.to_s)`. Keep the double-altered `raise` at lines 47-49 **above** it; ABC `K:` genuinely cannot express doubles, and `to_ascii` would happily emit `Cx`.

**10. `hash_key.rb:32-40`**

Reorder doubles before singles and add `"##" => "_double_sharp"` *before* `"#" => "_sharp"` (today the line-38 `#` rule means any appended `##` rule can never fire). Do **not** add ASCII `b` → `_flat`; it would mangle `blues_major_pentatonic`, `bass_clarinet`, and every other key containing `b`. Tidying, not behavior — after step 6, `##` no longer reaches `HashKey` from `KeySignature`.

**11. Leave `pitch_writer.rb:52-57` alone**

Recorded here so it isn't mistaken for an oversight. `pitch.alteration&.ascii.to_s` is not a conversion chain; it is a lookup key into `ACCIDENTAL_FRAGMENTS.invert` (`{"#"=>"^","x"=>"^^","b"=>"_","bb"=>"__",""=>"="}`), and `#ascii` still returns `"x"` after the YAML change. Substituting `to_ascii` produces identical strings with more indirection.

**12. Record the `Dyad` expansion**

`dyad.rb:80` sets `ALTERATION_SIGNS[2] = "##"`, builds `"C##"` spellings that `Spelling.get` returns `nil` for, and `.compact`s them away, so double sharps are **absent from the gem's enharmonic universe today**. After step 3: `all_spellings` 28 → 35, `enharmonic_respellings` for C4/E4 5 → 8. Spec comments at `dyad_spec.rb:322` and `:420` name `C##` as an expected-but-missing equivalent, suggesting this is the latent intent. Update the step-1 counts; don't suppress it.

**13. Ship as a major version**

`bundle exec rubocop -a`, `bundle exec rake validate`, bump `lib/head_music/version.rb` from `17.5.0` to **`18.0.0`** (decided 2026-07-26 — this is a breaking release, not a feature release).

The `### Added` entry covers the utility and `##` support, but the CHANGELOG needs a **`### Changed` / `### Breaking`** section that names each behavior change a consumer could be pinned to:

- `Spelling.get("C##")` returns a `Spelling` instead of `nil`. Anything using that `nil` as a validation signal now silently accepts double sharps. Same for `Pitch.get`, `Note.get`, and ABC `K:` fields.
- `Alteration::PATTERN` and `SYMBOLS` gain `##` and reorder longest-first. Anything embedding them in its own regex changes behavior.
- `KeySignature` hash keys change for six inputs (step 6 table), including the `Fx`/`C##`/`F𝄪` unification onto one cache entry.
- `Scale` hash keys change (`:bflat4_major` → `:b_flat4_major`).
- `Dyad#all_spellings` grows 28 → 35 and `#enharmonic_respellings` grows correspondingly, as double sharps enter the enharmonic universe for the first time.
- `Scale::SCALE_REGEX` is removed (unreferenced, but public by Ruby's rules).
- `Alteration.symbols` is aligned or removed.

### Testing Strategy

**Prose corpus** — all verified against the three-branch matcher:

| Converts | | Left alone | |
| --- | --- | --- | --- |
| `F#m` → `F♯m` | `Bbm` → `B♭m` | `Above`, `Absence`, `Abbey` | `B7` (the `/i` trap) |
| `A#m` → `A♯m` | `Ebmaj7` → `E♭maj7` | `Bebop`, `ebb`, `back` | `DB`, `Text`, `Exit` |
| `C#maj7` → `C♯maj7` | `Abmin` → `A♭min` | `subbass`, `cabbage` | `## Heading` (Markdown) |
| `F#dim` → `F♯dim` | `Bbsus4`, `Ebdim7`, `Abaug` | `Bach`, `Debussy` | `C4 quarter`, `Gb` |
| `Ab7` → `A♭7` | `BbM7` → `B♭M7` | `Absurd`, `Abdomen`, `Abdicate` | `Ebbing`, `Abbot`, `Adagio` |
| `Bb`/`Bbb`/`Cx`/`C##` | bare `b`/`#`/`bb`/`##`/`x` | `Abstract`, `Aberrant`, `Ebony` | `Fabric`, `Dabble`, `Abundant` |
| `Bbmaj7#11` → `B♭maj7♯11` | `C7b9` → `C7♭9` | `1.0b2`, `0x1b2f`, `0x1B2F` | `version 3b7`, `revision 2b1` |
| `G7#5b9` → `G7♯5♭9` | `Db7b9#11` → `D♭7♭9♯11` | `Figure 2b`, `Chapter 7b` | `1b2c3d`, `Deadbeef`, `DEADBEEF` |

The `Absurd`/`Abdomen`/`Abdicate` column is not decoration — those are the near-misses the four-entry allowlist survives by one letter each (`sur` vs `sus`, `dom` vs `dim`, `dic` vs `dim`). Any future addition to `CHORD_QUALITIES` must be re-measured against the dictionary, not eyeballed.

**Dictionary sweep as a spec.** Guard the allowlist with a test that runs the matcher over `/usr/share/dict/words` (capitalized) and asserts the false-positive set is exactly `%w[Ab Abb Ax Ebb Ex Abmho Ebbman]` — five pre-existing, two added. This turns "we measured it once" into a regression test. Skip gracefully when the file is absent, since it is not present on all CI images.

Known limitations to pin honestly: **`Ebb and flow` → `E𝄫 and flow`**, **`Ex` → `E𝄪`**, and the two dictionary words above. `x` cannot leave the ASCII set without breaking round-trip idempotence; all are bounded by the uppercase lookbehind.

**Altered extensions are in scope** and must convert whole: `Bbmaj7#11` → `B♭maj7♯11`, not `B♭maj7#11`. Half-converting a chord symbol is the same failure mode as half-converting a double — it looks converted. Pin `G7#5b9` and `Db7b9#11` specifically, since they exercise the extension rule twice in one token.

**Hostile-input corpus for the token scope** — these must all survive untouched, and they are the reason the extension rule is token-scoped rather than global: `1.0b2`, `0x1b2f`, `0x1B2F`, `1b2c3d`, `version 3b7`, `revision 2b1`, `Figure 2b`, `Chapter 7b`, `Deadbeef`, `DEADBEEF`.

**Real-world symbols, all verified against the design:**

| input | output |
| --- | --- |
| `Bb/D` | `B♭/D` (slash chords split into two tokens; both sides convert) |
| `F#m7b5/Eb` | `F♯m7♭5/E♭` |
| `Bbmaj7#11/D` | `B♭maj7♯11/D` |
| `Ebmaj9#11` | `E♭maj9♯11` |
| `Ab13b9` | `A♭13♭9` |
| `Gb7sus4` | `G♭7sus4` |
| `C7alt` | `C7alt` (unchanged — nothing to convert) |

The single best regression case, because it exercises prose safety and both conversion rules in one line:

```ruby
Accidentals.to_unicode("Above the Bbm7 we play Ebmaj7.")
# => "Above the B♭m7 we play E♭maj7."
```

`Above` survives, `Bbm7` converts on the chord-quality allowlist, `Ebmaj7` likewise — and the word that breaks the naive implementation sits directly next to the chord that breaks the guard-only one.

Also required: idempotency both directions; all-or-nothing (`expect(to_unicode("C##")).not_to include("#")`); `to_ascii` round-trip over all 28 spellings reparsing to the identical `Spelling`; `Accidentals.ascii_for["𝄪"] == "x"` (guards the `musical_symbols.first` dependency); `Note.get("C4 quarter")`/`("C##4 quarter")`/`("Cx4 quarter")`; `Pitch.get("C##4").natural.to_s == "C4"`; `Spelling.get("CX")` still `nil`; a cold-require spec. Run the full suite after each step against the 6097-example baseline; coverage ≥90%.

**Checked, not a risk:** ReDoS — flat alternation of literals, no nesting, no quantifier over a group; `"A" + "b"*40_000` in 1.5ms, 245KB prose in 9ms. Astral handling is clean (Ruby strings are codepoint-based), with one trap: `𝄫`/`𝄪` are non-word chars, so `/𝄫\b/` **matches** `"C𝄫x"` — independent confirmation that `\b` was the wrong guard.

### Risks / watch out for

- **`KEY_PATTERN`'s inner `(?:...)?`** — get this wrong and every *unaltered* ABC key raises `TypeError`. The failure is in the common path, not the new one.
- **The uniform `(?![a-z])` guard** — stated as settled in the story; applied uniformly it silently refuses `F#m`, and guard-only (without the allowlist) silently refuses `Bbm` and `Ebmaj7`. Both failure modes are silent no-ops, which is exactly the "looks converted" trap the story warns about, one level up.
- **`CHORD_QUALITIES` is measured, not intuited.** `sus` clears `Absurd` by one letter and `dim` clears `Abdomen`/`Abdicate` by one. Adding an entry without re-running the dictionary sweep is how this regresses.
- **`CHORD_TOKEN` is load-bearing for safety, not just tidiness.** The extension rule is only safe *because* it runs inside the token. Anyone who later "simplifies" `to_unicode` into a single flat `gsub` reintroduces `1.0b2` → `1.0♭2` and hex corruption. The two-level `gsub` needs a comment saying so — it is written in the API sketch above; keep it.
- **`Regexp.union` is not longest-match.** It alternates in array order, so every branch builder sorts longest-first. `CHORD_TOKEN`'s trailing `[A-Za-z0-9#]*` deliberately excludes `b`-as-a-terminator concerns by including `b` in the alphanumeric class — verify the token still ends where you expect on `Bb/D` slash chords (it splits into two tokens, which is correct).
- **`representations` must widen with the YAML** — otherwise `Spelling.get("C##")` returns a bare `C`, silently.
- **`ascii_for` depends on `musical_symbols.first`.** Reorder the `double_sharp` YAML records and `to_ascii` starts emitting `C##`, which `Pitch.get` accepts but ABC's `ACCIDENTAL_FRAGMENTS` does not — a failure with no visible link to a YAML edit.
- **The `Dyad` growth is invisible to the suite.** Loose assertions mean it passes silently; it is the largest behavioral change in the story and the story never mentions it.
- **`##` becomes valid input everywhere** — `Pitch::Parser`, `Note`, `KeySignature`, ABC `K:` fields. Downstream code treating `Spelling.get("C##") == nil` as a validation signal now gets a spelling. This is the breaking-change surface, and the reason step 13 ships `18.0.0` rather than a minor bump.
- **Pre-existing, out of scope, do not accidentally "fix":** `KeySignature.get("D flat major")` and `("Db major")` share hash key `:d_flat_major` under both old and new schemes; the former raises `NoMethodError` if called *first* and returns D♭ major if called second. The characterization specs will lock this order-dependence in — flag it as known.
- **Downstream needs a release, not a path gem.** bardtheory's story is blocked on a published `18.0.0`, and must budget for the major-version upgrade rather than a drop-in bump. The unanchored reverse direction is what makes its consolidation possible; its `pivot_chord_service.rb:127` omits `𝄪` and is fixed for free. Roman-numeral (`♭VI`) and scale-degree (`♭7`) rules **must stay downstream** — head_music models neither. The audit found **17** independent implementations across the two repos, not the four or five the story estimates, plus a third direction (accidental → spoken words, 4 sites) that `Alteration#name` already serves with i18n — worth a follow-up story.

### Open questions

1. ~~**The `F#m` / `Bbm` asymmetry, and altered extensions.**~~ **RESOLVED 2026-07-26 — fully closed, nothing outstanding.** `F#m`, `Bbm`, and `Ebmaj7` convert via the four-entry `CHORD_QUALITIES` allowlist (decision 2); `Bbmaj7#11`, `C7b9`, and friends convert via the token-scoped extension rule (decision 2a). Both measured. Scale degrees and Roman numerals remain downstream, which the token scope enforces structurally rather than by convention.
2. **Should `KEY_PATTERN` accept doubles at all,** given `abc_value` raises on rendering them? Widening buys symmetric parse/render errors but lets a field other ABC tools reject through the front door. Planned: widen, for the single-source-of-truth goal.
3. **Residue detection in the gem?** `to_unicode("Bbbb")` returns the input unchanged — correct all-or-nothing, but *silently*, and silence is indistinguishable from "nothing to convert." Planned: keep the utility pure `String -> String`, leave detection downstream; a separate predicate is far cheaper than changing the return type.
4. **`Dyad`'s 28 → 35 expansion** — intended, or does `all_spellings` want a "practical spellings" filter? The spec comments suggest someone already wondered and settled for a loose assertion.
5. **`to_ascii` output is not pure ASCII** (retains `♮`). Acceptable, or add a separate affordance for `C♮` → `C`? `Pitch#natural` already does the pitch-object version.
