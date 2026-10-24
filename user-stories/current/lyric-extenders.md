<!--
metadata:
  created_at:   2026-09-27T15:48:57-07:00
  activated_at: 2026-10-23T21:10:12-07:00
  planned_at:
  finished_at:
  updated_at:   2026-10-23T21:27:06-07:00
-->

# Story: Lyric Extenders

## Summary

AS a developer or researcher using HeadMusic

I WANT a syllable sung over several notes to keep its extender

SO THAT melismas survive import and can be written back

Split from [Spans Across Notes](../done/spans-across-notes.md).

## Background

| Concept | ABC | LilyPond | MusicXML | kern | MEI |
|---|---|---|---|---|---|
| Lyric extender (melisma) | `_` in `w:` | `__` | `<extend>` | `_` and `\|` in `**text` | `@con="u"` |

- kern's `LyricReader` skips `_` and `|` as melisma marks today, so a melisma reads as notes with no syllable.
- A `Syllable` holds `text`, `verse`, and `hyphen_after`, and nothing about extension.
- ABC and LilyPond cannot read lyrics at all yet (`w:` and `\new Lyrics` raise).

## Acceptance Criteria

- [ ] Each held note of a melisma carries an extend marker in its verse's slot, beside the note's syllables, and the melisma ends on the last marked note
- [ ] A marker needs a syllable or another marker before it in its verse, and it cannot sit on a rest
- [ ] Markers may follow a hyphenated syllable; the syllable's `hyphen_after` decides whether a hyphen or a line is drawn
- [ ] Code that reads sung words (MIDI lyric events, MusicXML `<syllabic>`, the style guides) never takes a marker for text
- [ ] Flow JSON writes a marker as `{"verse": 1, "extend": true}` in `syllables`, and reading checks each marker against what comes before it in the verse
- [ ] MusicXML writes and reads `<extend>`
- [ ] kern reads and writes `_` and `|` in `**text`
- [ ] MEI writes and reads `@con="u"`
- [ ] A reader whose format marks only where a line starts (MEI `@con="u"`, a bare MusicXML `<extend/>`) marks each following note with nothing in that verse, and stops at the next sung note or rest
- [ ] Round trips assert where each melisma ends

## Notes

- ABC `w:` and LilyPond `__` extenders wait for new stories that give those formats lyrics.
- The gem does not infer melismas from slurs; it keeps what the file says.

### Decisions

- **Mark the held notes, not the end.** A stored end position could point past the next syllable or onto a rest; a marker on each held note can only be checked against its neighbors, gets its verse from its slot, and matches kern's `_` and MusicXML's `<extend type="continue">`.
- **An explicit marker, not `"_"` as text.** Text formats and notation programs enter an extender as `_`, but MusicXML and MEI use structure, and a magic string would reach every consumer of syllable text unfiltered.
- **One marker for lines and hyphens.** The syllable that opens the melisma says which is drawn, so there is no separate `-` marker.
- **MEI cannot hold a hyphenated melisma.** Its single `@con` writes `"d"` there, and its reader gets the held notes back by the implied-end rule.

## Implementation Plan

[to be filled in by /stories plan]
