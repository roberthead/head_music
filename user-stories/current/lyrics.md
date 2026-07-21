<!--
metadata:
  created_at:   2026-07-21T10:29:08-07:00
  activated_at: 2026-07-21T10:36:39-07:00
  planned_at:
  finished_at:
  updated_at:   2026-07-21T10:36:39-07:00
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

[to be filled in by /stories plan]
