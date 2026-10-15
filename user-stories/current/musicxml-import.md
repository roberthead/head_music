<!--
metadata:
  created_at:   2026-09-24T18:58:30-07:00
  activated_at: 2026-10-15T07:55:48-07:00
  planned_at:
  finished_at:
  updated_at:   2026-10-15T07:55:48-07:00
-->

# Story: MusicXML Import

## Summary

AS a developer using HeadMusic

I WANT to pass a MusicXML document and receive a `HeadMusic::Content::Flow`

SO THAT I can analyze scores exported from MuseScore, Sibelius, Finale, Dorico, and the other scorewriters that speak the interchange format

## Background

MusicXML is the one format nearly every notation program exports, so this is the gem's widest door for real repertoire. The gem reads ABC, LilyPond, kern, and its own JSON, and writes MusicXML, but does not read it.

The MusicXML writer already writes most of what the model holds, so the reader has a precise target: everything the writer emits must read back. That now includes:

- multi-voice and multi-staff parts (`<backup>`, `<staves>`, `<staff>`), and notes that cross a barline written as tied notes
- `<transpose>` for transposing parts when rendered with `transposed: true`, and instrument changes mid-piece
- articulations, ornaments, and note dynamics in `<notations>`
- dynamic levels and hairpins as `<direction>`s with `<offset>`s, on a voice (with `<voice>` and `<staff>`) or on a part
- slurs and phrase marks, both as numbered `<slur>`s, since MusicXML has no phrase mark
- barline styles, repeats, endings, `<rehearsal>`, `<segno>`, `<coda>`, and the words and `<sound>` attributes for Fine, To Coda, D.C., and D.S.
- lyrics with `<syllabic>`
- `<work-title>`, `<movement-title>`, composer and arranger `<creator>`s, and `<part-name>`

This story follows the reader shape the other formats share: `HeadMusic::Notation::MusicXML.parse`, a document pass, a preflight that validates before building, and a flow builder. It builds on `REXML::Document`.

## Prerequisite

[Tuplets and Grace Notes](tuplets-and-grace-notes.md) lands first, so `<time-modification>`, `<tuplet>`, and `<grace>` read into the model from the start. That story's "MusicXML writes them" criterion gives this reader its target.

## Example

```ruby
flow = HeadMusic::Notation::MusicXML.parse(File.read("chorale.musicxml"))
flow               # => HeadMusic::Content::Flow
flow.meter.to_s    # => "4/4"
flow.voices.length # => 4
```

## Acceptance Criteria

### Entry point and structure

- [ ] `HeadMusic::Notation::MusicXML.parse(string)` returns a `HeadMusic::Content::Flow`
- [ ] `<score-partwise>` documents are read, and `<score-timewise>` documents are read by regrouping their measures into parts
- [ ] Malformed XML, a root that is neither, and a `<duration>` with no `<divisions>` in force raise `MusicXML::ParseError` naming the line or measure
- [ ] Elements the reader does not use are skipped, not rejected, so that every real export imports. These include `<print>`, `<defaults>`, `<credit>`, `<identification>` beyond the creators, stems, noteheads, fingerings, bowings, `<technical>`, `<harmony>`, `<figured-bass>`, `<part-group>`, and MIDI instrument data
- [ ] `MusicXML::UnsupportedFeatureError` is raised only for valid content where skipping would corrupt the music. Examples are nested tuplets, as the prerequisite rules, and chord tones with different durations. Each names its measure

### Identity

- [ ] Reading inverts the writer: `<movement-title>` names the flow when present, and `<work-title>` otherwise; with both, the work title becomes the flow's `Work`
- [ ] `<creator type="composer">` becomes the flow's composer, as a composer `Credit` when the flow has a `Work`. Other creator types, including the arranger that the writer takes as an option, are skipped
- [ ] `<part-name>` becomes the name of the part's player, a `Player` with no project, as the kern reader does
- [ ] `<instrument-sound>` maps to a catalog instrument where a mapping exists; otherwise the instrument is nil

### Parts, staves, and voices

- [ ] Each `<part>` becomes a part, in document order
- [ ] Within a part, each `<voice>` number becomes a voice, in order of first appearance; a note with no `<voice>` is voice 1
- [ ] `<backup>` and `<forward>` move the voice cursor. A `<forward>` gap in a voice becomes a rest, and a voice that begins late or ends early is padded with rests, so every voice satisfies `Voice::Continuity`
- [ ] `<staves>` builds the part's staff system, braced as `StaffSystem.grand_staff` does, and `<staff>` assigns each voice to its staff
- [ ] A voice whose `<staff>` changes at a barline becomes a staff crossing (`Voice#assign_staff`). A change in the middle of a bar is skipped, and the voice stays on its staff, since the model crosses only at barlines
- [ ] `<clef>` sets each staff's clef, and a later clef at a barline becomes a clef change (`Staff#change_clef`)

### Notes and rhythms

- [ ] `<pitch>` (step, alter, octave) maps to pitches, and `<unpitched>` to an unpitched note event of the part's instrument
- [ ] `<rest>` maps to rest events, and `<rest measure="yes">` to a rest filling its bar
- [ ] `<chord/>` adds a pitch to the note event before it
- [ ] `<type>` and `<dot>` give the written value. A note with no `<type>` takes its value from `<duration>` and `<divisions>`. A `<duration>` that disagrees with the written value raises `ParseError` naming the measure
- [ ] `<time-modification>` and `<tuplet>` map to tuplet values and groups, and `<grace>` to grace notes, as the prerequisite models them
- [ ] `<tie>`, falling back to `<tied>` when only that is written, folds tied notes into one placement, including across barlines, as the ABC, LilyPond, and kern readers do; an unclosed tie or a tie between different pitches raises `ParseError`
- [ ] Cue notes (`<cue/>`) read as rests of their length
- [ ] A first measure marked `implicit="yes"` is a pickup (bar 0), and a short final bar reads without error

### Timeline

- [ ] `<key>` `fifths` maps to the key signature and `mode` to its tonal context, including changes at later barlines
- [ ] `<time>` maps to the meter, including changes at later barlines
- [ ] `<sound tempo>` maps to a tempo change at its bar; a tempo in the middle of a bar is skipped, since the timeline changes only at downbeats
- [ ] Parts that disagree on the key at concert pitch keep the first part's, since the timeline holds one key
- [ ] `<transpose>` (`diatonic`, `chromatic`, `octave-change`) is honored, so a transposing part's pitches and key land in concert pitch, including after an instrument change

### Markings and spans

- [ ] Articulations, ornaments, and note dynamics read back from `<notations>` as the writer writes them; others, such as fermatas, are skipped
- [ ] `<direction>` dynamics become dynamic events at their position, `<offset>` included: on the voice when `<voice>` is given, and on the part otherwise
- [ ] `<wedge>`s become hairpins, paired by number; an unterminated or mismatched wedge is dropped, as the other readers drop hairpins
- [ ] `<slur>`s become slurs, paired by number. A slur that starts or stops on a rest reads as a phrase mark, since a slur cannot sit on one, so the writer's phrase marks come back. An unmatched slur is dropped
- [ ] `<barline>` styles, repeats, and endings, `<rehearsal>`, `<segno>`, `<coda>`, and the Fine, To Coda, D.C., and D.S. words with their `<sound>` attributes become bar markings
- [ ] `<beam>`s read back as beam breaks where they differ from the default grouping, so the writer's beams round-trip

### Lyrics

- [ ] `<lyric number="N">` attaches a syllable to its note event as verse N, and `<syllabic>` `begin` and `middle` set `hyphen_after`

### Round trip and real files

- [ ] Every golden document in the MusicXML writer specs round-trips: render, then parse, then render again yields the same document
- [ ] The ABC, LilyPond, and kern fixtures, rendered to MusicXML and parsed back, give flows equal to the ones that were rendered, compared field by field with any exclusions named
- [ ] The seeded generators in `spec/support` round-trip 100 seeds each through MusicXML, naming the seed on failure
- [ ] A document exported from MuseScore 4, and one from another scorewriter, both of public-domain music encoded for this story, parse end to end and are committed as fixtures
- [ ] With `MUSICXML_CORPUS` pointing at a local folder of MusicXML files, every file parses, or raises the error the spec names for it
- [ ] Maintains 90%+ test coverage

## Notes

- **Follow-up: compressed `.mxl`.** It is a zip container. Stdlib `Zlib` can inflate its entries, but reading the zip directory and `META-INF/container.xml` is a separate concern from the MusicXML grammar.
- **Waits on other stories:**
  - Fermatas, tempo words, and the common- and cut-time symbols wait on [Timeline Expressions](timeline-expressions.md).
  - `<extend>` waits on [Lyric Extenders](lyric-extenders.md).
- **Skipped for model reasons:** `<part-group>` brackets have no model across parts. A `<staff>` change in the middle of a bar has no model either. Each criterion above says so.

## Decisions

- **XML parsing uses REXML** (decided 2026-09-24). `rexml` is a runtime dependency of the gem.
- **Import returns a `Flow`** (decided 2026-10-14). This follows the kern precedent: a part carries a `Player` with no project, and `Project#add_flow` adopts it. This settles the earlier open question about returning a `Project`.
- **Valid notation the model cannot hold is skipped, not raised** (decided 2026-09-26, as policy for every reader). `UnsupportedFeatureError` is kept for the few cases where skipping would leave wrong music.
- **Tuplets and grace notes are a prerequisite** (decided 2026-10-14), not a deferral. Skipping a tuplet would leave its bar short, and raising on it would refuse much of the real repertoire.
- **Markings, spans, bar markings, and multi-staff parts are in scope** (decided 2026-10-14). The writer emits all of them, so the golden round trip needs the reader to take them back.

## Implementation Plan

[to be filled in by /stories plan]
