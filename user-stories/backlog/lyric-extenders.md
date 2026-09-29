<!--
metadata:
  created_at:   2026-09-27T15:48:57-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-09-27T15:48:57-07:00
-->

# Story: Lyric Extenders

## Summary

AS a developer or researcher using HeadMusic

I WANT a syllable sung over several notes to keep its extender

SO THAT melismas survive import and can be written back

Split from [Spans Across Notes](../done/spans-across-notes.md).

## Background

| Concept | ABC | LilyPond | MusicXML | kern |
|---|---|---|---|---|
| Lyric extender (melisma) | `_` in `w:` | `__` | `<extend>` | `_` and `\|` in `**text` |

- kern's `LyricReader` skips `_` and `|` as melisma marks today, so a melisma reads as notes with no syllable.
- A `Syllable` holds `text`, `verse`, and `hyphen_after`, and nothing about extension.
- ABC and LilyPond cannot read lyrics at all yet (`w:` and `\new Lyrics` raise).

## Acceptance Criteria

- [ ] Decide first: store the melisma's end, as `Syllable#extends_to` or as an extender span with a verse, or derive it from the notes after a syllable that carry none
- [ ] Flow JSON keeps extenders, reading syllables in an order that is safe for them
- [ ] MusicXML writes `<extend>`
- [ ] kern reads and writes `_` and `|` in `**text`
- [ ] Round trips assert where each melisma ends

## Notes

- ABC `w:` and LilyPond `__` extenders wait for new stories that give those formats lyrics.
- The gem does not infer melismas from slurs; it keeps what the file says.

## Implementation Plan

[to be filled in by /stories plan]
