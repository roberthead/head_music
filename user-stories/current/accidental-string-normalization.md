<!--
metadata:
  created_at:   2026-07-26T18:56:39-07:00
  activated_at: 2026-07-26T19:28:59-07:00
  planned_at:
  finished_at:
  updated_at:   2026-07-26T19:28:59-07:00
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

## Implementation Plan

[to be filled in by /stories plan]
