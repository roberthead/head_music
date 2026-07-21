<!--
metadata:
  created_at:   2026-07-21T10:29:08-07:00
  activated_at: 2026-07-21T10:36:39-07:00
  planned_at:   2026-07-21T10:39:08-07:00
  finished_at:
  updated_at:   2026-07-21T15:47:55-07:00
-->

# Story: Lyrics

## Summary

AS a composer working with vocal music in head_music
I WANT to attach sung text (lyrics) to the notes of a voice
SO THAT compositions can carry multi-verse, hyphenated lyrics and export them to MusicXML

## Acceptance Criteria

- A `Placement` can carry sung text: at most one syllable per verse, keyed by verse number, with rests and un-texted placements carrying none.
- Multiple verses are supported (e.g. verse 1 "glo-", verse 2 "peace" on the same note).
- A syllable stores only the minimal linguistic fact — its text, its verse, and a `hyphen_after` boolean indicating the word continues onto the next sung note. The MusicXML `syllabic` value (single/begin/middle/end) is NOT stored.
- Melisma (one syllable held over several notes) is represented by absence: the held notes simply carry no syllable for that verse. No melisma flag is stored.
- Syllables round-trip losslessly through `Placement#to_h` and the composition hash deserializer.
- MusicXML export emits `<lyric number="N">` as the last child of `<note>`, on the lead note of a chord only and the attack of a tied chain only, deriving `<syllabic>` from the stored `hyphen_after` booleans of the syllable and its predecessor in the same verse.
- Lyric text is XML-escaped on export.
- Test coverage stays at or above the project's 90% minimum, with the MusicXML spec ladder covering: single-verse single word, hyphenated word (begin/middle/end derivation), melisma (gap emits no `<lyric>`), and multi-verse.

## Notes

Design decisions reached in discussion (2026-07-21):

**Model: store the linguistic fact, derive the notation.** A note (`Placement`) is associated with at most one syllable per verse, and often none. `syllabic` (single/begin/middle/end) is derivable from a single `hyphen_after` boolean per syllable and is therefore NOT stored — storing it would be a denormalization that can go inconsistent, and it mixes a notation-rendering concern into the `Content` layer, which this codebase deliberately keeps separate from `Notation`. Melisma is likewise not stored; it is the absence of a syllable on a following placement (MusicXML's continuation-by-absence).

Lossless MusicXML *import* is explicitly NOT a goal, which is what frees us to derive `syllabic` on write rather than store it.

**`Syllable` value object** (`lib/head_music/content/syllable.rb`): immutable, `text` / `verse` / `hyphen_after`, with `to_h` / `from_h` / `==` / `hyphen_after?`.

**`Placement` changes** (mirror the existing `beam_break_before` side-metadata pattern):

- `syllables` — a hash keyed by verse number, at most one `Syllable` per verse (structural enforcement of the invariant).
- `sing(text, verse: 1, hyphen_after: false)` — assign; returns self for chaining.
- `syllable(verse = 1)`, `sung?`.
- `to_h` serializes syllables in verse order (alongside the `beam_break_before` line).
- `merge` keeps the existing placement's syllables and ignores the incoming one — a chord sings one syllable per verse; syllables attach to the note event, not to individual chord tones.

**Hash round-trip**: `HashDeserializer` restores syllables beside the `beam_break_before` restore; add a `values.placement_syllables` helper that validates (text present, verse a positive integer, no duplicate verse) the same way sounds/rhythmic values are validated on import.

**MusicXML output** (`music_xml/writer.rb`): `<lyric>` is the last child of `<note>`, after `<notations>`. Rides the lead note of a chord only and the attack (`!component.tie_stop`) only. Derive `syllabic` by comparing this syllable's `hyphen_after?` with the previous sung note's for the same verse:

| from prev? | to next? | syllabic |
|---|---|---|
| no | no | single |
| no | yes | begin |
| yes | yes | middle |
| yes | no | end |

Prefer precomputing a per-verse ordered list of sung placements once (O(n)) over re-walking the voice for each note. Text goes through the existing `escape` helper.

**Deferred (out of scope for this story):**

- ABC `w:` lyric-line parsing — stays an `:unsupported` token in the body lexer. The `Syllable` model is designed to receive it later (space / `-` / `_` / `*` alignment grammar → `Syllable`s).
- MusicXML `<extend/>` melisma extender line rendering.

## Implementation Plan

Derived from the design in Notes (verified against current code 2026-07-21). Six steps, built in dependency order with tests at each step so coverage never dips below 90%.

### Step 1 — `Syllable` value object

New file `lib/head_music/content/syllable.rb`. Immutable (`freeze` in initialize). Attributes `text`, `verse`, `hyphen_after`. Methods: `hyphen_after?`, `to_h` (omit `verse` when 1 and `hyphen_after` when false), `self.from_h`, `==` (by `to_h`). Require it from `lib/head_music.rb` alongside the other `content/` requires. Spec: `spec/head_music/content/syllable_spec.rb`.

### Step 2 — `Placement` sung-text API

Edit `lib/head_music/content/placement.rb` (mirror the `beam_break_before` side-metadata pattern):

- `syllables` — lazily-initialized hash keyed by verse number (`@syllables ||= {}`).
- `sing(text, verse: 1, hyphen_after: false)` — assigns a `Syllable`, returns `self`.
- `syllable(verse = 1)` — reader; `sung?` — `syllables.any?`.
- `to_h` — after the `beam_break_before` line, add `hash["syllables"] = syllables.keys.sort.map { |v| syllables[v].to_h }` unless empty.
- `merge` — keep the receiver's `@syllables`, ignore the incoming placement's (chords sing one syllable per verse); add a one-line comment.

Spec additions in `spec/head_music/content/placement_spec.rb`: assignment, multi-verse, `to_h` shape + ordering, rests carry none, merge keeps existing syllables.

### Step 3 — Hash round-trip

Edit `lib/head_music/content/composition/schema_values.rb`: add `placement_syllables(placement_hash, path)` — returns `[]` when key absent; else require an Array; validate each entry (Hash, non-empty `text` String, `verse` a positive Integer defaulting to 1, no duplicate verse) and build via `Syllable.from_h`, raising `ArgumentError` with path context like the sibling validators.

Edit `lib/head_music/content/composition/hash_deserializer.rb`: beside the `beam_break_before` restore in `build_voices`, add — when `placement_hash.key?("syllables")` — a loop calling `placement.sing(...)` for each validated syllable.

Specs: `schema_values_spec.rb` (valid + each rejection path) and a composition round-trip (`to_h` → `HashDeserializer#composition` preserves syllables).

### Step 4 — MusicXML `<lyric>` output

Edit `lib/head_music/notation/music_xml/writer.rb`:

- In `note_element_lines`, insert `*lyric_lines(placement, component, chord: chord)` after `notation_lines`, before `</note>`.
- `lyric_lines` — return `[]` when `chord`, `placement.rest?`, or `component.tie_stop`. Else, for each verse in `placement.syllables.keys.sort`, emit `<lyric number="N">` / `<syllabic>` / `<text>` (escaped) / `</lyric>`.
- `syllabic(placement, syllable)` — derive from `previous_syllable(placement, syllable.verse)&.hyphen_after?` and `syllable.hyphen_after?` per the truth table in Notes.
- `previous_syllable(placement, verse)` — memoized per `[voice, verse]`: `placement.voice.placements.select { |p| p.syllable(verse) }` (already position-sorted), return the entry before `placement` (nil if first/absent). Melisma gaps are skipped naturally since only sung placements are collected.

Spec ladder in `spec/head_music/notation/music_xml/writer_spec.rb` (or a focused lyric spec): single-verse single word (`single`), hyphenated word (`begin`/`middle`/`end`), melisma (held note emits no `<lyric>`), multi-verse (two `<lyric number>` on one note), chord lead-note-only, tie attack-only, XML escaping.

### Step 5 — Validation & coverage

Run `bundle exec rubocop -a`, then `bundle exec rake` (tests + coverage). Confirm ≥90% and that every new file/branch is exercised.

### Step 6 — Verify acceptance criteria

Walk each criterion against the code and tests; note any that need manual confirmation.

Out of scope (deferred, per Notes): ABC `w:` parsing and the MusicXML `<extend/>` melisma line.

## Review

Reviewed 2026-07-21 against commit `8a91b69` (plus a follow-up fix applied during review, see below). Full suite: 6097 examples, 0 failures; coverage 99.69% line / 97.74% branch. Reviewed by a product-manager agent (acceptance criteria) and a code-reviewer agent (quality), on a clean story branch.

### Acceptance criteria

| # | Criterion | Verdict | Evidence |
|---|---|---|---|
| 1 | ≤1 syllable per verse, keyed by verse; rests/un-texted carry none | ✅ met | `placement.rb` `syllables` verse-keyed hash structurally enforces it; default empty (`placement_spec.rb` "carries no syllables by default") |
| 2 | Multiple verses | ✅ met | `sing(..., verse:)`; `placement_spec.rb` multi-verse + `writer_spec.rb` one `<lyric>` per verse |
| 3 | Stores only text/verse/hyphen_after; `syllabic` not stored | ✅ met | `syllable.rb` exposes exactly those three; no `syllabic` field anywhere |
| 4 | Melisma by absence, no flag | ✅ met | no melisma field; `writer_spec.rb` two-note melisma emits one `<lyric>` |
| 5 | Round-trips through `to_h` + deserializer | ✅ met | `to_h` verse-ordered; `SchemaValues#placement_syllables` validates; `composition_serialization_spec.rb` end-to-end round trip |
| 6 | `<lyric number>` last child, lead/attack only, derived `syllabic` | ✅ met | `lyric_lines` last in `note_element_lines`, guards `chord \|\| rest? \|\| tie_stop`; derivation table covered by chord/tie/begin-middle-end specs |
| 7 | Text XML-escaped | ✅ met | `escape(...)` in `lyric_lines`; `writer_spec.rb` `"R&D <x>"` parses back intact |
| 8 | Coverage ≥90% + MusicXML spec ladder | ✅ met | 99.69% line; ladder (single/hyphenated/melisma/multi-verse) all present |

All eight met. Nothing blocks `finish`.

### Code review findings

1. **(Important — found and fixed during review) `sing` keyed `syllables` by the raw `verse` argument while `Syllable` coerces it via `Integer()`.** `sing("la", verse: "2")` stored under key `"2"` while `syllable(2)` looked up the integer and returned `nil`; mixing key types made `syllables.keys.sort` raise in both `to_h` and the writer. No internal caller triggered it (all pass integers), but it was a latent bug in the public API. **Fixed:** `sing` now keys by `syllable.verse` (the coerced value). Added regression tests in `placement_spec.rb` (string verse found by its integer; mixed-type verses sort without raising).

2. **(Minor — addressed) `previous_syllable` relied on an unstated invariant.** `Array#index` compares with `==`, which on `Placement` is position-only; it locates the right placement only because a voice holds one placement per position. Added a "why" comment documenting the dependency.

3. **(Minor — addressed) behavioral-assertion gaps.** Added `writer_spec.rb` tests for a hyphenated word straddling a melisma gap (begin/middle/end skipping an un-sung note) and for per-verse independent `syllabic` derivation.

4. **(Noted, not actioned) `hyphen_after` isn't validated on import** — any truthy JSON value becomes `true` via `Syllable`'s `!!`. Theoretical only (real JSON always sends a boolean); left as-is.

5. **(Noted, not actioned) layer asymmetry** — `Placement#sing` accepts any positive/`Integer()`-coercible verse, while import rejects `verse <= 0`. The public contract expects `verse >= 1`; no criterion requires validation at `sing`. Left as a known minor asymmetry.
