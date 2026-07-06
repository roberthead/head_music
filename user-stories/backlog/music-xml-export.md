<!--
metadata:
  created_at:   2026-07-06T15:41:38-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-07-06T15:41:38-07:00
-->

# Story: MusicXML Export

## Summary

AS a developer using HeadMusic

I WANT to render a `HeadMusic::Content::Composition` as a MusicXML document

SO THAT I can hand my compositions to notation editors, engravers, and playback tools that speak the industry-standard interchange format

## Background

[MusicXML](https://www.w3.org/2021/06/musicxml40/) is the de-facto interchange format for Western music notation, readable by Finale, Sibelius, MuseScore, Dorico, and most other scorewriters. It encodes a score as XML: a `<score-partwise>` document with `<part-list>`, one `<part>` per voice, `<measure>` elements, and `<note>` elements carrying `<pitch>` (step/octave/alter), `<duration>`, `<type>`, plus per-measure `<attributes>` for key, time signature, clef, and divisions.

This story renders *outward* (HeadMusic objects → MusicXML text). It is the complement of the inward notation-interpreter stories under the [Notation Module epic](../epics/notation-module.md) — the [ABC Notation interpreter](../done/) and [LilyPond interpreter](lilypond-interpreter.md) both read text *into* the object model via `HeadMusic::Notation::<Format>.parse`. Export is the reverse trip.

`HeadMusic::Content::Composition` already carries everything a basic score needs: `name`, `composer`, `key_signature`, `meter`, `voices` (each with placements of pitched, durationed notes across bars), and per-bar key/meter changes. This story turns that model into a valid MusicXML string.

## Example

```ruby
composition = HeadMusic::Content::Composition.new(
  name: "Exercise",
  key_signature: "G major",
  meter: "4/4"
)
voice = composition.add_voice(role: "Cantus firmus")
# ... voice.place(...) some notes ...

xml = composition.to_musicxml
xml            # => String of well-formed <score-partwise> MusicXML
```

## Acceptance Criteria

- `HeadMusic::Content::Composition#to_musicxml` returns a String containing a well-formed, schema-valid `<score-partwise>` MusicXML document (correct DOCTYPE/version).
- The document carries the composition's identity: `<work-title>` from `name` and `<creator type="composer">` from `composer` when present.
- Each voice becomes a `<part>` (with a matching `<part-list>`/`<score-part>` entry), and each bar becomes a `<measure>`.
- Pitched notes render `<pitch>` with correct `<step>`, `<octave>`, and `<alter>`; each note carries a `<duration>`, `<type>`, and correct `<divisions>`.
- Rests render as `<rest>` notes with the right duration.
- The first measure's `<attributes>` emit the key signature (fifths), time signature (`<beats>`/`<beat-type>`), and a sensible default clef; mid-piece key/meter changes emit new `<attributes>` on the bar where they occur.
- Round-tripping through a MusicXML reader (e.g. MuseScore or an XML-schema validator) accepts the output without errors.
- Specs cover: a single-voice diatonic example, an example with accidentals, an example with rests, a multi-voice example, and a mid-piece key/meter change.

## Notes

**Entry-point shape — a design question for planning.** The user's framing is `Composition#to_musicxml`. To mirror the Notation module's inward pattern (`HeadMusic::Notation::ABC.parse`), the actual rendering likely belongs in a `HeadMusic::Notation::MusicXML` renderer, with `Composition#to_musicxml` as a thin convenience that delegates to it (e.g. `HeadMusic::Notation::MusicXML.render(self)` / `MusicXML::Renderer.new(self).to_s`). Confirm this split during planning so the export code lives in the Notation module rather than bloating `Composition`.

**Scope.** Start with the subset the object model already expresses cleanly: pitch (step/octave/alter), duration/type, rests, key & time signatures, per-bar key/meter changes, one part per voice, work title and composer. Explicitly out of scope for a first cut (candidates for follow-up stories): beaming, ties/slurs, tuplets, dynamics, articulations, lyrics, multiple staves per part, and MusicXML *import* (the inward direction).

**Open questions for planning.**
- How is `<divisions>` chosen from the model's duration representation, and how do note durations map to `<type>` + `<dot>`?
- Default clef selection — fixed treble, or derived from voice range / instrument if available?
- XML generation approach: Ruby stdlib (`REXML`/`Builder`) vs. hand-built strings — prefer a dependency-free stdlib path if practical.
- `score-partwise` vs. `score-timewise` — `score-partwise` is the near-universal choice; confirm.

## Implementation Plan

[to be filled in by /stories plan]
