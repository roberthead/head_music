<!--
metadata:
  created_at:   2026-09-24T18:58:30-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-09-24T19:23:10-07:00
-->

# Story: MusicXML Import

## Summary

AS a developer using HeadMusic

I WANT to pass a MusicXML document and receive a `HeadMusic::Content::Flow`

SO THAT I can analyze scores exported from MuseScore, Sibelius, Finale, Dorico, and the other scorewriters that speak the interchange format

## Background

The gem already renders MusicXML (see [MusicXML Export](../done/music-xml-export.md)), but reads only ABC, LilyPond, and its own JSON. MusicXML is the one format nearly every notation program exports, so this is the gem's widest door for real repertoire.

This story mirrors the [LilyPond Interpreter](../done/lilypond-interpreter.md): a `parse` entry point on the existing `HeadMusic::Notation::MusicXML` module, which fails before building on anything outside the supported subset.

## Example

```ruby
flow = HeadMusic::Notation::MusicXML.parse(File.read("chorale.musicxml"))
flow            # => HeadMusic::Content::Flow
flow.meter.to_s # => "4/4"
flow.voices.length # => 4
```

## Acceptance Criteria

- [ ] `HeadMusic::Notation::MusicXML.parse(string)` returns a `HeadMusic::Content::Flow`
- [ ] `<score-partwise>` documents are read; `<score-timewise>` either is read or raises `UnsupportedFeatureError`
- [ ] `<work-title>` / `<movement-title>` and `<creator type="composer">` map to the flow's identity
- [ ] Each `<part>` becomes a part; multiple `<voice>` numbers within a part become separate voices
- [ ] `<pitch>` (step, alter, octave), `<rest>`, `<chord/>`, `<duration>` with `<divisions>`, `<type>`, and `<dot>` map to placements with the right pitches and rhythmic values
- [ ] `<key>` (fifths and mode), `<time>`, and mid-piece `<attributes>` changes map to the flow's timeline
- [ ] Ties (`<tie>`) fold into tied values as they do for ABC and LilyPond
- [ ] `<transpose>` is honored so that a transposing part's pitches land in concert pitch
- [ ] `<lyric>` syllables attach to placements
- [ ] `<backup>` and `<forward>` are handled well enough to read multi-voice parts correctly
- [ ] Malformed XML raises `MusicXML::ParseError`; valid constructs outside the subset raise `MusicXML::UnsupportedFeatureError`
- [ ] Every golden fixture from the MusicXML writer specs round-trips: render → parse → render yields the same document
- [ ] At least one document exported by MuseScore parses end to end
- [ ] Maintains 90%+ test coverage

## Notes

- Compressed `.mxl` (a zip container) is a natural follow-up; this story reads uncompressed XML strings.
- Layout, engraving, and presentation elements (`<print>`, `<defaults>`, `<credit>`, stem and beam directions) should be skipped, not rejected — nearly every real export carries them.
- Probably out of scope for v1: tuplets, grace notes, repeats and endings, multi-staff parts (piano), dynamics, and articulations. Decide during planning which of these must be skipped silently and which must raise.

## Decisions

- **XML parsing uses REXML.** `rexml` is a runtime dependency of the gem (decided 2026-09-24), so the reader builds on `REXML::Document` rather than a hand-rolled parser.

## Open Questions

1. A multi-part score with players — should `parse` return a `Flow`, or should a companion entry point return a `Project` with players and a layout?

## Implementation Plan

[to be filled in by /stories plan]
