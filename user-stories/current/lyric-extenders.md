<!--
metadata:
  created_at:   2026-09-27T15:48:57-07:00
  activated_at: 2026-10-23T21:10:12-07:00
  planned_at:
  finished_at:
  updated_at:   2026-10-27T21:01:26-07:00
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

## Acceptance Criteria

- [ ] Each held note of a melisma carries an extend marker in its verse's slot, in place of a syllable, and the melisma ends on the last marked note
- [ ] The voice event just before a marker has a syllable or a marker in that verse, and a marker cannot sit on a rest
- [ ] Markers may follow a hyphenated syllable; the syllable's `hyphen_after` decides whether a hyphen or a line is drawn
- [ ] Code that reads sung words (MIDI lyric events, the MIDI and notation preflight checks, MusicXML `<syllabic>`) never takes a marker for text
- [ ] Flow JSON writes a marker as `{"verse": 1, "extend": true}` in `syllables`, and reading checks each marker against the voice event before it
- [ ] MusicXML writes `<extend>` with the melisma's end marked, and reads it
- [ ] kern reads `_` and `|` in `**text` as markers, and writes the one Humdrum uses for a held note
- [ ] MEI writes and reads `@con="u"`, and writes `"d"` on a hyphenated melisma, since `@con` holds one value
- [ ] A reader whose format marks only where a line starts (MEI `@con="u"`, a bare MusicXML `<extend/>`) marks each following note with nothing in that verse, and stops at the next sung note or rest
- [ ] Round trips assert where each melisma ends

## Notes

- ABC `w:` and LilyPond `__` extenders wait for new stories that give those formats lyrics; neither format reads lyrics yet (`w:` and `\new Lyrics` raise).
- The gem does not infer melismas from slurs; it keeps what the file says. The implied-end rule is no exception: the file says a line starts, and the rule only places its end.
- Open for the plan: what distinguishes kern's `_` from `|`, checked against a Humdrum source, with Verovio as an oracle.

### Decisions

- **Mark the held notes, not the end.** A stored end position could point past the next syllable or onto a rest; a marker on each held note can only be checked against its neighbors, gets its verse from its slot, and matches kern's `_` and MusicXML's `<extend type="continue">`.
- **An explicit marker, not `"_"` as text.** Text formats and notation programs enter an extender as `_`, but MusicXML and MEI use structure, and a magic string would reach every consumer of syllable text unfiltered.
- **One marker for lines and hyphens.** The syllable that opens the melisma already says which is drawn, so a separate `-` marker would only repeat it.

## Implementation Plan

[to be filled in by /stories plan]
