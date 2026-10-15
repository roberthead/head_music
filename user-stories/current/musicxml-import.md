<!--
metadata:
  created_at:   2026-09-24T18:58:30-07:00
  activated_at: 2026-10-15T07:55:48-07:00
  planned_at:   2026-10-15T08:22:45-07:00
  finished_at:
  updated_at:   2026-10-15T08:22:45-07:00
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
- [ ] UTF-8 with or without a BOM, UTF-16 with a BOM, and binary strings from `File.binread` parse. The DOCTYPE is never fetched; a document that declares entities, or whose text exceeds REXML's expansion limits, raises `ParseError`. A compressed `.mxl` raises `UnsupportedFeatureError` naming the follow-up
- [ ] A `<divisions>` change applies from its point onward, within its part. A `<backup>` before the start of its measure, a `<chord/>` with no note before it, or a `<staff>` number beyond `<staves>` raises `ParseError` naming the measure
- [ ] `<multiple-rest>` is skipped; `<measure-repeat>`, overfull measures, short measures in mid-piece that do not pair with an `implicit` neighbor, and compound meters such as 3+2/8 raise `UnsupportedFeatureError` naming the measure. Key, time, and clef changes in the middle of a bar are skipped
- [ ] Elements the reader does not use are skipped, not rejected, so that every real export imports. These include `<print>`, `<defaults>`, `<credit>`, `<identification>` beyond the creators, stems, noteheads, fingerings, bowings, `<technical>`, `<harmony>`, `<figured-bass>`, `<part-group>`, and MIDI instrument data
- [ ] `MusicXML::UnsupportedFeatureError` is raised only for valid content where skipping would corrupt the music. Examples are nested tuplets, as the prerequisite rules, and chord tones with different durations. Each names its measure

### Identity

- [ ] Reading inverts the writer: `<movement-title>` names the flow when present, and `<work-title>` otherwise; with both, the work title becomes the flow's `Work`
- [ ] With no `<work-title>` or `<movement-title>`, a `<credit>` whose `<credit-type>` is title names the flow, as many Sibelius exports carry the title only there
- [ ] `<creator type="composer">` becomes the flow's composer, as a composer `Credit` when the flow has a `Work`. Other creator types, including the arranger that the writer takes as an option, are skipped
- [ ] `<part-name>` becomes the name of the part's player, a `Player` with no project, as the kern reader does
- [ ] `<instrument-sound>` ids map to catalog instruments through a table the writer shares, and the writer writes `<score-instrument><instrument-sound>` from it; an unmapped id gives a nil instrument
- [ ] The writer resets `<transpose>` when an instrument change returns to concert pitch, writes clef changes after the first measure, and writes `clef-octave-change`
- [ ] **Breaking.** The writer's work title defaults to `flow.work.title`, so a flow read with a `Work` writes it back

### Parts, staves, and voices

- [ ] Each `<part>` becomes a part, in document order
- [ ] Within a part, each `<voice>` value becomes a voice, in order of first appearance; values are labels, not numbers, and a note with no `<voice>` is voice 1
- [ ] Parts with fewer measures than the first are padded with rests
- [ ] `<backup>` and `<forward>` move the voice cursor. A `<forward>` gap in a voice becomes a rest, and a voice that begins late or ends early is padded with rests, so every voice satisfies `Voice::Continuity`
- [ ] `<staves>` builds the part's staff system, braced as `StaffSystem.grand_staff` does, and `<staff>` assigns each voice to its staff
- [ ] A voice whose `<staff>` changes at a barline becomes a staff crossing (`Voice#assign_staff`). A change in the middle of a bar is skipped, and the voice stays on its staff, since the model crosses only at barlines
- [ ] `<clef>` sets each staff's clef, and a later clef at a barline becomes a clef change (`Staff#change_clef`)

### Notes and rhythms

- [ ] `<pitch>` (step, alter, octave) maps to pitches, and `<unpitched>` to an unpitched note event of the part's instrument, or an unpitched sound with no instrument when the part has none
- [ ] `<rest>` maps to rest events, and `<rest measure="yes">` to a rest filling its bar
- [ ] `<chord/>` adds a pitch to the note event before it
- [ ] `<type>`, `<dot>`, and `<time-modification>` give the written value and place the note. A `<duration>` within one division of it is exporter rounding and is ignored; a larger disagreement raises `ParseError` naming the measure. A note with no `<type>` takes its value from `<duration>` and `<divisions>`
- [ ] `<time-modification>` and `<tuplet>` map to tuplet values and groups, and `<grace>` to grace notes, as the prerequisite models them; a grace chord reads as one grace note with several pitches
- [ ] `<tie>`, falling back to `<tied>`, folds tied notes into one placement, including across barlines; where they disagree, `<tie>` wins, and `let-ring` and `continue` are skipped. A tie start with no matching stop is dropped and its note keeps its written value. A tie between different pitches raises `ParseError`
- [ ] Cue notes (`<cue/>`) read as rests of their length
- [ ] A first measure marked `implicit="yes"` is a pickup (bar 0), and a short final bar reads without error

### Timeline

- [ ] `<key>` `fifths` maps to the key signature and `mode` to its tonal context, including changes at later barlines
- [ ] `<time>` maps to the meter, including changes at later barlines
- [ ] `<sound tempo>` maps to a tempo change at its bar; a tempo in the middle of a bar is skipped, since the timeline changes only at downbeats
- [ ] Parts that disagree on the key at concert pitch keep the first part's, since the timeline holds one key
- [ ] `<transpose>` (`diatonic`, `chromatic`, `octave-change`) is honored, so a transposing part's pitches and key land in concert pitch, including after an instrument change. A numbered `<transpose>` applies to its staff only

### Markings and spans

- [ ] Articulations, ornaments, and note dynamics read back from `<notations>` as the writer writes them; others, such as fermatas, are skipped
- [ ] `<direction>` dynamics become dynamic events at their position, `<offset>` included: on the voice when `<voice>` is given, and on the part otherwise
- [ ] `<wedge>`s become hairpins, paired by number; an unterminated or mismatched wedge is dropped, as the other readers drop hairpins
- [ ] `<slur>`s become slurs, paired by number. A slur that starts or stops on a rest reads as a phrase mark, since a slur cannot sit on one, so the writer's phrase marks come back. An unmatched slur is dropped
- [ ] `<barline>` styles, repeats, and endings, `<rehearsal>`, `<segno>`, `<coda>`, and the Fine, To Coda, D.C., and D.S. words with their `<sound>` attributes become bar markings
- [ ] `<beam>`s read back as beam breaks where they differ from the default grouping, so the writer's beams round-trip

### Lyrics

- [ ] `<lyric number="N">` attaches a syllable to its note event as verse N, and `<syllabic>` `begin` and `middle` set `hyphen_after`. A `<lyric>` with no `number` is verse 1, and non-integer lyric numbers are ranked in order of first appearance

### Round trip and real files

- [ ] The Speed the Plough golden document, and every flow in the shared fixture modules (`ABCFixtures`, `LilyPondFixtures`, `MarkingFixtures`, `LayoutFixtures`, `NavigationFixtures`, `HairpinFixtures`, `TupletFixtures`), round-trip: rendered, parsed, and rendered again with the same writer options, they yield the same document. Where the reader moves a one-voice part's dynamics onto the part, reading is idempotent instead
- [ ] The ABC, LilyPond, and kern fixtures, rendered to MusicXML and parsed back, give flows equal to the ones that were rendered, compared field by field with any exclusions named
- [ ] The seeded generators in `spec/support` round-trip 100 seeds each through MusicXML, naming the seed on failure
- [ ] The gem's own public-domain fixtures, converted by MuseScore 4 (`mscore -o`), parse to the music that was rendered, with MuseScore's changes listed per file, and are committed under `spec/fixtures/notation/music_xml/`; with `MSCORE` set, a spec reconverts them and reports drift. Exports from another scorewriter, the MIT-licensed Sibelius and other files of the LilyPond MusicXML test suite, are committed beside them and parse end to end
- [ ] With `MUSICXML_CORPUS` pointing at a local folder of MusicXML files, every `.xml` and `.musicxml` file parses, or raises the error the spec names for it, and no error outside `HeadMusic::Notation::ParseError` escapes. The story records sweeps of the music21 corpus, the LilyPond MusicXML test suite, and OpenSheetMusicDisplay's test data
- [ ] A generated 500-bar, two-part, two-voice document with tuplets, ties, and grace notes reads in linear time; the spec counts calls rather than timing them, and every voice ends unrevised
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
- **Planning choices made without stopping to ask** (2026-10-15, while running the seven-story goal; Rob may revise any):
  - An unclosed tie is dropped rather than raised, under the skip policy, since Finale writes ties that open in a first ending and close in the second.
  - The writer's work title defaults to `flow.work.title`, **Breaking.** for flows with a `Work`, which the next major release allows; otherwise a read `Work` could not be written back.
  - A `<credit>` title names a flow with no other title.
  - The other-scorewriter fixtures come from the MIT-licensed LilyPond MusicXML test suite (a Sibelius export among them) rather than a Dorico GUI export, which needs Rob; a Dorico export can be added later beside them.
  - The plan's two review pauses (the title default, and the record contract before the fan-out) are not taken.

## Implementation Plan

### Overview

The reader is a two-phase pipeline in the existing `HeadMusic::Notation::MusicXML` namespace, using `*_reader` file names:

- **Phase one:** a `Parser` (REXML), a `Document` that regroups partwise and timewise measures, and a `ParsePreflight` with security and structure checks. Each part is then walked into exact Rational records.
- **Phase two:** a `BarMap` aligns bars across all parts, the timeline is applied, and only then are voices placed, padded and grouped. Kern's `FlowBuilder` follows the same pattern.
- **Markings:** they read through a registry of independent mark readers that run over the records once the voices are final.

Before any of this, the writer needs four fixes. The round-trip criteria cannot pass without them.

The core is sequential, because every core step edits the same note and voice files. The mark readers, plus MuseScore fixture generation, then fan out into five worktrees.

**Specialists:** product-manager, two developers (core pipeline; markings and test harness), and best-practices-engineer (REXML security, performance, patterns). ui-ux-designer and accessibility-specialist were skipped because the story has no user interface.

All paths are relative to `/Users/roberthead/github.com/roberthead/head_music`.

### Problems found in today's code (each verified)

- **The writer never resets `<transpose>`.** `attributes_writer.rb#transpose_lines` returns `[]` when the new instrument's transposition is zero. A clarinet that changes to flute therefore keeps the clarinet's transposition, and a correct reader would read the flute a tone low.
- **The writer writes clefs in the first measure only** (`attributes_writer.rb#first_measure_lines`). It writes only sign and line, so octave clefs lose `clef-octave-change`, and `Staff#change_clef` never reaches MusicXML.
- **The writer writes no `<sound tempo>`, no `<score-instrument>/<instrument-sound>`, and no title from `flow.work`.** `work_title` is only an option.
- **There is exactly one exact-string golden document**, at `spec/head_music/notation/music_xml/writer_spec.rb:202` (Speed the Plough). Every other writer spec checks XPath on flows built inline.
- **REXML 3.4.4 has these quirks:**
  - It expands entities lazily: a billion-laughs document parses, then raises a bare `RuntimeError` from `element.text`.
  - More than about 10,000 `&` in one text node also raises `RuntimeError`.
  - Elements carry no source line; only `REXML::ParseException#line` exists.
  - `Document.new("")` returns a nil root.
  - `head_music.gemspec:38` allows rexml 3.4.0–3.4.1, which are affected by CVE-2025-58767.
- **`KeyMapper::MODE_NAMES_BY_SCALE_TYPE.invert` maps "major" to ionian and "minor" to aeolian**, because the last duplicate key wins.
- **`Meter.get("3+2/8")` quietly returns 3/8.**
- **`Position#normalize` walks one bar at a time** (`content/position.rb:128-137`). Building a position at bar 1600 from 1:1 makes 3,204 `meter_at` calls; building it from the bar's own start makes 3.
- **`Voice#place` before the last event bumps `revision`** (`voice.rb:67`), which clears every timing memo.
- **The local test corpora differ from what the brief said:**
  - The music21 corpus has 122 `.xml`, 1 `.musicxml` and 526 `.mxl` files.
  - None is score-timewise and none comes from MuseScore 4. About 27 of the `trecento/*.xml` files are UTF-16.
  - OpenSheetMusicDisplay's `test/data` (BSD-3) adds 279 files from MuseScore 1–4.7, Sibelius, Dorico 4, Finale and Noteflight.
  - The LilyPond MusicXML test suite (143 files, MIT) is at `~/github.com/cuthbertLab/music21/music21/musicxml/lilypondTestSuite/`.
- **MuseScore Studio 4.7.5 is installed and converts headlessly**, as is Dorico 6 (GUI only).
  - In `/private/tmp/claude-501/-Users-roberthead-github-com-roberthead-head-music/6579b744-7cf1-410f-8f79-7acf007bb139/scratchpad/story-planner-mscore/`, `mscore -o out.musicxml in.musicxml` converted the gem's Speed the Plough and Bach Invention 1 renders in about 1.3 s each.
  - The exit status is unreliable: 0 on one run, 134 ("Abort trap: 6") on another, with the output written both times. The harness must check that the output file exists, not the exit code.
  - MuseScore adds `<print>`, `<defaults>`, stems, and a `keyboard.piano.grand` `<instrument-sound>` to parts that had none.

### Model decisions

- **Entry and errors**, in `lib/head_music/notation/music_xml.rb`:
  - `self.parse(string)` returns `Parser.new(string).flow`.
  - `ParseError < HeadMusic::Notation::ParseError` takes `line_number:`, `measure:` and `part:`. The message gets "(line 3)" or "(measure 12 of part P1)" appended, following `kern.rb:17-27`.
  - `UnsupportedFeatureError < ParseError`.
  - Malformed XML names the line (from `ParseException#line`). Every other error names the measure's `number` attribute and the part id, since elements have no line.
- **File layout (new files in `lib/head_music/notation/music_xml/`):**
  - `parser.rb`, `xml_reading.rb`, `document.rb`, `parse_preflight.rb`, `part_reader.rb`, `attributes_reader.rb`, `note_reader.rb`, `pitch_reader.rb`, `clef_reader.rb`, `voice_track.rb`, `tie_folding.rb`, `bar_map.rb`, `timeline_reader.rb`, `part_roster.rb`, `voice_placer.rb`, `concert_transposition.rb`, `identity_reader.rb`, `flow_builder.rb`;
  - `mark_readers.rb` (the registry), then `marking_reader.rb`, `lyric_reader.rb`, `direction_reader.rb`, `slur_reader.rb`, `beam_reader.rb`, `barline_reader.rb`, `navigation_reader.rb`;
  - shared with the writer: `instrument_sounds.rb` with `instrument_sounds.yml`, and `marking_elements.rb`.
  - Nothing collides with a writer file. The read-side check is `ParsePreflight`, as LilyPond names it, because `Preflight` belongs to the writer.
  - Files that include a module when they are defined `require_relative` it first, as `xml_text` is required today.
  - `parser.rb` requires `rexml/document`; nothing in `lib` requires it today.
- **Exact time.**
  - Every duration is `Rational(duration, 4 * divisions)` of a whole note.
  - Numeric text is parsed with `Rational(text)`, since `<duration>` is `xs:decimal`. Its `ArgumentError`, and any zero or negative `<divisions>` or `<duration>`, become `ParseError`.
  - Floats are never used.
  - A later `<divisions>` applies from that point on, within its part.
- **Building positions.** A position is always `flow.position(bar, 1, 0).advance(subticks:)` from its own bar's start, never an offset from 1:1.
- **Buffered placement.** Events are buffered per voice and placed in position order once the part is read, as `kern/spine_voices.rb:56` does. Every voice therefore ends the read with `revision.zero?`.
- **Shared tables.**
  - The articulation, ornament and dynamic hashes move out of `MarkingWriter` into `MarkingElements`. Those values are unique, so the reader's frozen inverses are safe.
  - `KeyMapper` gains explicit frozen inverse tables. `Hash#invert` is never used on them.
  - `InstrumentSounds` maps W3C sound ids to catalog `name_key`s and back. The source is `/Applications/Dorico 6.app/Contents/Resources/musicxml/sounds.xml`; map about 60 ids, with `voice.male` and similar going to nil.
- **Mark-reader registry.**
  - `MARK_READERS` is a list of classes that each respond to `note(record)`, `direction(record)`, `barline(record)` and `apply(flow)`.
  - The core emits three kinds of record, in document order per part, each carrying its REXML element:
    - `NoteRecord`: part, voice, voice_event, grace_index, chord?, continuation?, bar_number, exact onset;
    - `DirectionRecord`: part, bar_number, cursor before `<offset>`, divisions in force;
    - `BarlineRecord`: part, bar_number, last?.
  - Mark readers collect during the walk and apply after the voices are final, since spans check their anchors when added (`voice.rb:113`).
  - No mark reader edits `note_reader.rb` or `flow_builder.rb`.

### Reader rules

- **Document.**
  - A `PK` prefix means a compressed `.mxl`: `UnsupportedFeatureError` naming the follow-up.
  - A nil root raises `ParseError` "no root element". Any root other than `score-partwise` or `score-timewise` raises `ParseError` naming it.
  - UTF-8 with or without a BOM, UTF-16 with a BOM, and binary strings from `File.binread` all parse.
  - **Score-timewise:** each `<measure>/<part>` is appended to its part's list, with `number` and `implicit` taken from the outer `<measure>`. No elements are copied.
  - A `<part>` missing from `<part-list>` reads with no name. A part with no notes is skipped.
- **Security (`ParsePreflight`, before any text is read).**
  - Any doctype entity beyond `gt lt quot apos` raises `ParseError` "MusicXML input declares entities".
  - All text and attributes go through one `XmlReading` helper that turns REXML's `RuntimeError` into `ParseError`. That rescue sits only inside the helper.
  - The DTD is never fetched (verified offline).
- **Cursor and voices.**
  - **Two clocks.** The document cursor follows `<duration>`, `<backup>` and `<forward>`. Each `VoiceTrack` also keeps a model end, the exact sum of its written values.
  - **Placing a note.** Let `gap = cursor − end(v)`:
    - |gap| below one division means no gap; the note takes the model end. This absorbs exporter rounding such as Sibelius tuplets.
    - A larger positive gap becomes a rest. This covers `<forward>` gaps and voices that start late.
    - A larger negative gap raises `ParseError` "voice N overlaps itself".
  - **Backups and chords.** A `<backup>` before the start of the bar raises `ParseError`. A `<chord/>` note does not move the cursor.
  - **Voices.** A voice is keyed by its `<voice>` text, defaulting to "1", and voices are created in order of first appearance. The writer writes `<rest measure="yes">` with its voice in every silent bar, so first appearance restores the writer's order.
  - **Padding.** Every voice is padded from the first bar to the flow's end with rests split at barlines (`DottedDuration.rhythmic_value_for`). A tacet voice therefore comes back as rests.
  - **Unequal parts.** Parts with fewer measures are padded the same way; they do not raise.
- **Bars (`BarMap`, across all parts, before any position is built).**
  - A bar's length is the longest extent of any part's notes and forwards in it. Whole-measure rests don't count.
  - The first measure is bar 0 when `implicit="yes"`, otherwise bar 1. A short first bar is right-aligned either way.
  - A short measure followed by an `implicit="yes"` measure that completes it becomes one bar, as at a mid-bar repeat.
  - A short final bar is fine.
  - Any other short measure, an overfull measure, or a compound meter like `3+2/8` raises `UnsupportedFeatureError`: it is valid MusicXML, and skipping would corrupt the bar.
  - A whole-measure rest is `measure="yes"`, or any rest whose duration equals the meter whatever its `<type>`. It fills its bar, so the writer's short final bar and pickups read intact.
  - Bar numbers are sequential; the `number` attribute appears only in messages.
- **Rhythmic values.**
  - `<type>` plus the `<dot/>` count, with `TupletRatio.get([actual, normal])` from `<time-modification>`, gives the written value.
  - **Duration check.** `<duration>` must match `sounding × 4 × divisions` to within one division. A larger difference raises `ParseError` naming the measure.
  - **No `<type>`:** `rhythmic_value_for(fraction, tuplet:)`. A ratio is inferred, as kern does, when the fraction is not binary. If no value fits, `UnsupportedFeatureError`.
  - Cue notes become rests of their duration; their chord tones are dropped.
  - `<multiple-rest>` is skipped, since it only affects display. `<measure-repeat>` raises `UnsupportedFeatureError`, because reading it as rests would corrupt the music.
- **Tuplets.**
  - A `<tuplet type="start|stop" number>` records `(event, link index)` at each end. `group_tuplet` runs after placement, since `place` raises inside a group.
  - The link-start and link-end helpers move from `kern/tuplet_groups.rb` onto `TupletGroup`, so a bracket ending on the first piece of a tied note groups by link.
  - The unit is the first link's `<normal-type>`/`<normal-dot>` when present, otherwise that link's own value. This inverts `tuplet_marks.rb#mark_for`.
  - A `start` while a bracket is open in the same voice raises `UnsupportedFeatureError` "nested tuplets".
  - Leaving the run ungrouped, with the ratios kept:
    - a `<time-modification>` with no `<tuplet>`;
    - an unmatched start or stop;
    - an `ArgumentError` from `group_tuplet`, which is rescued.
  - Brackets across barlines need nothing special.
  - The writer brackets ungrouped runs too, so flow comparisons use `bracket_summary`.
- **Grace notes.**
  - A `<grace>` note queues in its track, and a `<grace>` with `<chord/>` adds a pitch to the last queued grace note.
  - The queue goes to the track's next main note via `add_grace_note(pitches, value, slashed:, tied:, articulations:)`. Articulations come from `MarkingElements`.
  - The value is `<type>` plus dots, or an eighth when there is no `<type>`.
  - The queue is dropped before a rest, before a tie's later link, and at the end of the part.
  - A last grace note's `<tie type="start">` on a pitch the main note shares gives `tied: true`, and it consumes the main note's stop. This inverts `GraceWriter.tied_into?`.
- **Chords.**
  - `<chord/>` joins the previous non-grace event in its track.
  - A different `<duration>` or written value raises `UnsupportedFeatureError`.
  - `<chord/>` on a rest, or with no previous note, raises `ParseError`.
- **Ties.**
  - `<tie>` is used when present, otherwise `<tied>`. When the two disagree, `<tie>` wins. `let-ring` and `continue` are skipped.
  - **Folding:** one linear pass per track, in `TieFolding`. An event whose pitches all start ties joins the next main event whose pitches all stop ties on the same spellings, via `append_tied`. Chains cross barlines and keep their written spelling.
  - **Errors, per the criterion:** an unclosed tie, or a tie followed by a rest or the end of the part, raises `ParseError` naming the start's measure. A tie between different pitches does too (but see Proposed story changes).
  - Partial ties within a chord are skipped, so those notes are struck again.
- **Staves and crossings.**
  - **Staff system.** `<staves>N` gives `StaffSystem.new(staves:, bracket: :brace)`, as `grand_staff` builds it. One clef gives a one-staff system, as `kern/part_roster.rb` does.
  - **Crossings.** A voice's staff in a bar is the `<staff>` of its first event there.
    - The first bar assigns the opening staff.
    - A later bar on a different staff calls `assign_staff(bar, staff)`.
    - A change in the middle of a bar is skipped.
  - A `<staff>` number beyond `<staves>` raises `ParseError`.
  - **Clefs.** `<clef number>` at onset 0 calls `change_clef`; a clef in the middle of a bar is skipped. `ClefReader` maps sign, line and `clef-octave-change` to `Clef::RECORDS`; percussion, TAB and none give nil.
  - **Mid-bar `<attributes>`:** key, time and clef are skipped there, but `<divisions>` still applies.
- **Concert pitch.**
  - `ConcertTransposition` holds diatonic, chromatic and octave-change for each staff `number`, with an unnumbered one applying to all staves. A later `<transpose>` replaces it from its bar on.
  - The concert pitch is `Pitch.from_number_and_letter(midi + chromatic + 12·octave, written.natural_steps(diatonic + 7·octave).letter_name)`. Verified examples: D4 at (−1,−2) gives C4, and C5 at octave −1 gives B♭3.
  - Grace pitches and keys are transposed the same way. `<double>` is skipped.
  - Per-staff transpositions are converted rather than refused, since converting each staff's pitches needs no model change.
- **Timeline.**
  - **Key.** `<fifths>` with `<mode>` gives the key signature and tonal context, through `KeyMapper`'s explicit inverse. Without a mode, `Key.for_fifths`.
  - **Opening values.** The opening key must be a `KeySignature`, because `Flow.new(key_signature: Integer)` raises.
  - **Later changes** to key, meter and tempo are read at onset 0 of a bar, and applied only when they differ from what is in force.
  - The first part's key at concert pitch wins.
  - **Tempo.** `<sound tempo>` from any part, at onset 0 with no `<offset>`, becomes `Tempo.new("quarter", bpm)`; the first per bar wins. A tempo in the middle of a bar is skipped.
  - `key-step`/`key-alter` keys and per-staff `<key number>` are skipped.
- **Identity.** Identity runs before the core builds the flow, because `Flow.new` takes `name:` and `composer:`, and transposition and unpitched notes need each part's instrument.
  - **Titles.** `<movement-title>` names the flow, and a `<work-title>` alongside it becomes `Work.new(title:)`. A `<work-title>` alone names the flow, with no `Work`.
  - **Composers.** Each `<creator type="composer">` becomes a `Person`, added with `work.with_credit(person, :composer)` when there is a `Work`. Otherwise the names are joined with ", " as the composer string. Other creator types are skipped.
  - **Players.** `<part-name>` gives `Player.new(name:)` with no project.
  - **Instruments.** The first `<instrument-sound>` goes through `InstrumentSounds`, or gives nil.
- **Markings in `<notations>`** (`MarkingReader`):
  - The inverses come from `MarkingElements`, and `<strong-accent>` maps to marcato.
  - Markings are read only from the attack and combined across its chord notes.
  - An accent dynamic (sf, sfz, rfz, fp) in `<notations><dynamics>` sets `note_dynamic`, and the first one wins. A level there becomes a voice dynamic at the note.
  - Fermata, breath mark, caesura, `<technical>`, wavy-line, tremolo and unknown dynamics are skipped.
- **Directions** (`DirectionReader`):
  - **Onset.** `onset = cursor + Rational(offset, 4·divisions)`, clamped to the bar. `<offset>` counts even without `sound="yes"`, and the clamp handles the negative offsets Finale writes. In the last measure, an onset at or past the meter goes to `flow.final_barline_position`. Every other onset goes through `BarSplitter.position_at(flow, bar, onset)`.
  - **Owner.** The voice when `<voice>` resolves to one, otherwise the part.
  - **Dynamics.** Levels go to `place_dynamic`, and the first one wins on `ArgumentError`.
  - **Wedges** are paired per part by `number`, defaulting to "1", in document order:
    - a stop with nothing open is dropped;
    - a start on an open number replaces the earlier start;
    - wedges still open at the end are dropped;
    - `add_span` errors are rescued, as `kern/dynamic_placer.rb:108` does.
  - The prototype matched the writer's output on 215 flows.
- **Slurs** (`SlurReader`):
  - Paired per part by `number`.
  - A start on a grace note gives `from_grace: true`. A stop on a grace note ends on its main note.
  - Either end on a rest makes it a phrase mark. Unmatched, `continue`, cross-voice and refused slurs are dropped.
  - Known loss: a phrase mark between two notes comes back as a slur.
  - The prototype matched on 106 flows.
- **Bar markings** (`BarlineReader`, `NavigationReader`). Every part is read; for each field, the first value found wins.
  - **Barline styles.** `BarlineWriter::BAR_STYLES` is inverted. `light-heavy` on the last bar, or on a bar that ends a repeat, stays `:regular`. A left `light-light` without a repeat makes the previous bar `:double`.
  - **Repeats.** `forward` sets `starts_repeat`; `backward` sets `ends_repeat_after_num_plays = times || 2`.
  - **Endings.** Each ending runs from its `start` to its `stop` or `discontinue`. Its number list is split on commas and spaces, as in `"1, 2, 3"`.
  - **Navigation.** The `<sound>` attributes (`segno`, `coda`, `tocoda`, `fine`, `dacapo`, `dalsegno`) decide the kind. Words matter only when there is no `<sound>`, or to give a jump its target via `Jump.get(words)`.
  - `<rehearsal>` sets `rehearsal_mark`.
- **Lyrics** (`LyricReader`):
  - **Verse.** `number` is the verse. If any number in the part is not an integer, verses are ranked by first appearance, since `Syllable` calls `Integer(verse)`. A missing number is verse 1.
  - `hyphen_after` is set when `<syllabic>` is `begin` or `middle`.
  - `<elision>` joins its text pieces with the elision's text, or "‿" when it is empty.
  - `<extend>` is skipped, as are lyrics on rests, grace notes and continuations, and a second syllable for the same verse.
- **Beams** (`BeamReader`):
  - The default break comes from `(onset % beam_group_unit).zero?`.
  - Set `beam_break_before = true` where beam level 1 breaks against that default, and `false` where it joins across it; otherwise leave it nil.
  - Comparisons use the rendered `<beam>` sequence, not the flags.
  - The prototype matched on 138 flows.

### Steps

Each step is one commit. Run the touched specs, then `bundle exec rake` and `bundle exec rubocop -a`. Check new specs against the old code by copying files aside, never with `stash`. Do not assert console output.

#### Shared base (sequential, on `story/musicxml-import`)

1. **Shared helpers and the REXML floor.**
   - Move `tuplet_ratio` and `rest_value` from `kern/duration_reader.rb` into `DottedDuration`, with kern delegating to them.
   - Move kern's link-start and link-end helpers onto `TupletGroup`.
   - Raise the gemspec to `"rexml", "~> 3.4", ">= 3.4.2"`. CHANGELOG: Security.
   - Files: `lib/head_music/notation/dotted_duration.rb`, `lib/head_music/content/tuplet_group.rb`, `lib/head_music/notation/kern/{duration_reader,tuplet_groups}.rb`, `head_music.gemspec`, plus specs. The kern suite must stay green.
2. **Writer: transposition reset, clef changes, octave clefs.**
   - When an instrument change changes the transposition, write `<transpose>` with diatonic 0 and chromatic 0.
   - Write `<clef number>` in later measures for `Staff#change_clef`, and write `clef-octave-change`.
   - CHANGELOG: Fixed.
   - Files: `lib/head_music/notation/music_xml/{attributes_writer,render_plan}.rb`, `spec/head_music/notation/music_xml/writer_spec.rb`, `render_plan_transposition_spec.rb`.
3. **Writer: shared tables and identity.**
   - New `instrument_sounds.{rb,yml}`; the writer writes `<score-instrument><instrument-sound>` from it.
   - New `marking_elements.rb`, extracted from `marking_writer.rb`.
   - Explicit inverse tables in `key_mapper.rb`, with a spec that every mode the writer writes maps back to the same mode.
   - `work_title` defaults to `flow.work&.title`. That is **Breaking.**, because kern-imported flows render differently.
   - The golden document must stay unchanged.
   - The work title defaults to `flow.work&.title` (**Breaking.**), as decided below.
4. **Errors, Parser, Document, ParsePreflight.**
   - Files: `music_xml.rb` (`parse` and the errors), `parser.rb`, `xml_reading.rb`, `document.rb`, `parse_preflight.rb`.
   - Specs in `spec/head_music/notation/music_xml/`:
     - `parser_spec.rb`: malformed XML names line 3; blank input; a nil root; the wrong root; `.mxl`; UTF-16 and BOM input.
     - `document_spec.rb`: timewise regrouping; a part missing from the part-list.
     - `parse_preflight_spec.rb`, for security:
       - billion laughs in text and in an attribute;
       - quadratic blowup;
       - a SYSTEM entity, whose file is never read;
       - 20,000 `&`;
       - the real partwise DOCTYPE with an unroutable SYSTEM URL parses offline.
5. **Walking skeleton and identity.**
   - Files: `part_reader`, `attributes_reader`, `note_reader`, `pitch_reader`, `voice_track`, `bar_map`, `timeline_reader` (opening values only), `part_roster`, `voice_placer`, `flow_builder`, `identity_reader`, plus `instrument_sounds` lookups.
   - Covers one voice of pitches and rests; type, dots and divisions; the one-division duration check; "no `<divisions>` in force" naming the measure; titles, `Work`, composer `Credit`, `Player`, and instruments.
   - Specs: `reader_notes_spec.rb`, `identity_reader_spec.rb`.
6. **Bars and timeline.**
   - Covers pickups, the short final bar, split measures, overfull and short-mid-piece errors, whole-measure rests, divisions changes, key, mode, meter and tempo changes, the first part's key winning, and mid-bar `<attributes>` being skipped.
   - Specs: `bar_map_spec.rb`, `reader_timeline_spec.rb`.
7. **Voices.**
   - Covers `<backup>` and `<forward>`, voice order, padding (including parts with fewer measures), chords, cue notes, `<unpitched>` (`UnpitchedSound.get(nil)` when unmapped), `<multiple-rest>` and `<measure-repeat>`.
   - Spec: `reader_voices_spec.rb`, with a shared "music stays whole" matcher: each bar sums to its length and `first_gap` is nil.
8. **Ties.** `tie_folding.rb`; spec `reader_ties_spec.rb`.
9. **Tuplets.** Spec: `reader_tuplets_spec.rb`, with `TupletFixtures` rendered and parsed and compared through `bracket_summary`.
10. **Grace notes.** Spec: `reader_grace_notes_spec.rb`.
11. **Staves, crossings, clefs.**
    - `clef_reader.rb`.
    - Spec: `reader_staves_spec.rb` on `LilyPondFixtures` `cross_staff_piano`, `choir_on_two_staves` and `tie_into_staff_crossing`, plus a mid-bar change being skipped.
12. **Concert pitch.**
    - `concert_transposition.rb`.
    - Spec: `reader_transposition_spec.rb` on the `LayoutFixtures` trio and the clarinet project with its instrument changes, rendered with `transposed: true`; also numbered `<transpose>`.
13. **Mark-reader registry, records, and the core size check.**
    - `mark_readers.rb` with stub readers, and the `NoteRecord`, `DirectionRecord` and `BarlineRecord` emission.
    - `spec/support/music_xml_documents.rb`, which wraps measure snippets into full documents.
    - **Size spec**, `reader_size_spec.rb`:
      - Generate a partwise document directly: 2 parts × 2 voices with backups, triplet groups, ties across barlines and a grace note per bar, at 250 and 500 bars.
      - Assert that calls to `Position.new`, `flow.meter_at` and `voice_event_preceding` grow by at most 2.2× from 250 to 500 bars.
      - Assert every voice ends with `revision.zero?`.
      - Do not assert wall-clock time.

#### Parallel worktrees, all from the commit after step 13

Record that commit's hash in each prompt, because worktree agents branch from `main`. Give each agent its own scratch folder under the scratchpad (`mx-marks/`, `mx-directions/`, `mx-curves/`, `mx-bars/`, `mx-fixtures/`). CHANGELOG lines go in commit bodies until step 25.

| Worktree | Steps | Files owned |
|---|---|---|
| Markings | 14–15 | `music_xml/{marking_reader,lyric_reader}.rb` and their specs |
| Directions | 16 | `music_xml/direction_reader.rb` and its spec |
| Curves | 17–18 | `music_xml/{slur_reader,beam_reader}.rb` and their specs |
| Bars | 19–20 | `music_xml/{barline_reader,navigation_reader}.rb` and their specs (`NavigationFixtures`) |
| Fixtures | 21 | `spec/fixtures/notation/music_xml/**`, the `music_xml:musescore_fixtures` task in `Rakefile`, `spec/support/musescore.rb` |

14. **`MarkingReader`.** Articulations, ornaments and note dynamics on chords; skipped kinds.
15. **`LyricReader`.** Verses, syllabic, elisions; string verse numbers.
16. **`DirectionReader`.**
    - Cases: offsets, including negative ones; `<voice>` versus part ownership; accents in directions; wedge renumbering; unterminated wedges; a hairpin ending at the final barline after a short final bar; onsets inside septuplets.
17. **`SlurReader`.** Phrase marks on rests, `from_grace`, grace stops, unmatched slurs.
18. **`BeamReader`.** Defaults set no flags; forced breaks round-trip; `TupletGenerator` beam overrides.
19. **`BarlineReader`.** Styles, repeats, endings with number lists, last-bar `light-heavy`.
20. **`NavigationReader`.** Sound attributes win over words; To Coda versus coda; jump targets.
21. **MuseScore fixtures.** This can't be checked against the reader yet; step 23 does that.
    - **Task.** The Rakefile task renders a fixed list of gem fixtures with `MusicXML.render`, runs `"/Applications/MuseScore 4.app/Contents/MacOS/mscore" -o <name>.musescore4.musicxml <rendered>`, and checks that the output exists, ignoring the exit code. It commits both the render and MuseScore's output.
    - **The list.** The flows give MuseScore every feature the writer emits:
      - `ABCFixtures::SPEED_THE_PLOUGH`;
      - `bach_invention_01.ly`;
      - `LilyPondFixtures.cross_staff_piano`;
      - a merged marking, hairpin and navigation flow;
      - `TupletFixtures` triplets plus grace notes before the downbeat;
      - a two-verse lyric fixture;
      - a transposing clarinet part with an instrument change.
    - **Timewise fixtures.** Generate them with `xsltproc "/Applications/Dorico 6.app/Contents/Resources/musicxml/parttime.xsl"` from two rendered fixtures.
    - **LilyPond-suite fixtures.** Copy these, with an MIT `LICENSE`: 31a, 32a, 33c, 41g, 42b, 45b, 45c, 46a, 46c, 61a, 61b, 61g, 61j and 99a.

#### Coordinator, after cherry-picking

22. **Integration round trips.**
    - New `spec/support/music_xml_round_trip.rb`, modeled on `kern_round_trip.rb`. `expect_musicxml_round_trip(flow)` compares field by field and checks that reading is idempotent (`parse(render(r)).to_h == r.to_h`).
    - **Named exclusions:**
      - voice roles, comments, source;
      - the `Work` beyond its title;
      - instruments without a sound id;
      - `beam_break_before` values (beams are compared as rendered `<beam>`s instead);
      - phrase marks between two notes;
      - groups compared as brackets;
      - a tacet voice coming back as rests;
      - authored fallback clefs;
      - tie spellings at barlines, compared by length;
      - tempo, until Timeline Expressions writes it;
      - voice dynamics in a one-voice part, which come back on the part and use only the idempotent check.
    - New `spec/head_music/notation/music_xml_round_trip_spec.rb` checks that render, parse, render is byte-identical for:
      - the golden document, plus a new example in `writer_spec.rb`;
      - every fixture module: `ABCFixtures`, `LilyPondFixtures`, the `.krn` and `.ly` files, `MarkingFixtures`, `NavigationFixtures`, `HairpinFixtures`, `TupletFixtures` and `LayoutFixtures`, the last also with `transposed: true`.
    - **Seeds.** `TupletGenerator::SEEDS` and `HairpinGenerator::SEEDS`, each as `it "round-trips seed #{seed}"`. Run `TUPLET_SEEDS=1..2000` once by hand.
    - This step catches reader/writer and reader/reader mismatches that the worktrees could not see.
23. **Real files.**
    - **MuseScore specs.** `spec/head_music/notation/music_xml/real_files_spec.rb` parses each `*.musescore4.musicxml` and compares it with the parse of its own head_music render through `music_xml_round_trip.rb`. Record a per-file list of MuseScore's changes, such as the added piano sound, re-spelled rests, or a different divisions value.
    - **Gated regeneration.** With `MSCORE=path` set, or when the binary exists and `MUSESCORE_FIXTURES=1`, the spec reconverts into a tmp folder and checks that the reader gives the same flow as the committed fixture. That catches MuseScore version drift.
    - **The other scorewriter.** The MIT LilyPond-suite files, including the Sibelius export `99a`, stand as the other scorewriter. A Dorico export may be added later.
    - **Other fixtures.** Specs for the LilyPond-suite and timewise fixtures.
    - **Schema check.** `reader_fixture_schema_spec.rb`, gated on `MUSICXML_XSD`, runs `/usr/bin/xmllint --noout --schema` over the documents in `music_xml_documents.rb` and the scorewriter exports, leaving out deliberately malformed documents by name.
24. **Corpus and scale.**
    - **Corpus spec.** `spec/head_music/notation/music_xml_corpus_spec.rb`, modeled on `kern_corpus_spec.rb`:
      - Globs `**/*.{xml,musicxml}` under `MUSICXML_CORPUS`, sorted.
      - Keeps a manifest of `relative path => [error class, message regex]`, with a guard that every key still exists.
      - Asserts that no error escapes outside `HeadMusic::Notation::ParseError`, and runs the "music stays whole" matcher on every parsed flow.
    - **Sweeps by hand, recorded in the story:**
      - the 123 music21 `.xml`/`.musicxml` files;
      - its 526 `.mxl` files, unzipped into a scratch folder;
      - the 143 LilyPond-suite files;
      - OSMD `test/data` (279 files).
    - **Full-reader scaling spec.** Build N-bar and 4N-bar flows with a slur, hairpin, dynamic, lyrics and beamed eighths in every bar. Count `HeadMusic` and REXML calls with `TracePoint` and assert the 4N/N ratio is under 4.5. Time with CPU time, not wall time, and parse the 1.26 MB `trecento/PMFC_12_9-Gloria` once by hand.
25. **Record and fold.** Tick the criteria, record the decisions and any honest rewording in the story, and fold the CHANGELOG lines into Unreleased, marking the work-title default **Breaking.** if it was adopted.

### Testing Strategy

- **Unit specs per reader**, using `music_xml_documents.rb` snippets for the edge cases the writer never emits:
  - negative offsets;
  - string voices;
  - `<tied>` without `<tie>`;
  - a split repeat measure;
  - per-staff `<transpose>`;
  - UTF-16 input.
- **Music stays whole.** Every skip point gets a spec asserting bar sums and a nil `first_gap`: mid-bar staff changes, mid-bar tempo, cue notes, forward gaps, late or early voices, fermatas, `print-object="no"` notes, and a backup after a voice ended inside a tuplet.
- **Round trips.**
  - Byte-identical render, parse, render for every fixture flow and 100 seeds per generator, with the seed in the example name.
  - A field-by-field comparison with named exclusions, plus idempotence.
- **Real files.** Committed MuseScore Studio 4.7.5 exports of the gem's own public-domain fixtures; the MIT LilyPond-suite files; timewise conversions; and a gated MuseScore regeneration check.
- **Corpus.** The gated `MUSICXML_CORPUS` spec with a manifest, swept over music21, the LilyPond suite and OSMD.
- **Scale.** Count operations at two sizes (step 13 for the core, step 24 for the full reader), plus the `revision.zero?` guard. Never assert wall-clock time.
- **Security.** Every billion-laughs variant raises `ParseError` quickly. No `RuntimeError` escapes.

### Risks & Open Questions

- **Unclosed ties and the skip policy.** The story's tie criterion raises on unclosed ties, but Finale writes ties that start in a first ending and close in the second. The corpus may refuse real files on this. The product manager recommends dropping the tie instead (see Proposed story changes). The plan raises, as the story says, and switching is one branch in `tie_folding.rb`.
- **Writer changes in steps 2–3.** The transposition reset is a correctness fix, so it is required. Clef changes, octave clefs and `<instrument-sound>` are additions that leave the golden document unchanged. Defaulting `work_title` to `flow.work.title` is **Breaking.**; it was chosen so that a read `Work` writes back.
- **MuseScore's exit status is unreliable** (0 or 134). Its output also changes between versions, so the committed fixture is the reference, and the gated regeneration only reports drift.
- **Exporter rounding beyond one division** still raises `ParseError`. The corpus sweep will show whether old Finale files with small divisions trip on it.
- **Short measures in the middle of a piece** that don't pair with an `implicit` neighbor raise `UnsupportedFeatureError`, and so do overfull ones. kern uses `ParseError` for overfull bars; the plan uses `UnsupportedFeatureError` because the input is valid MusicXML.
- **Bar markings take the first value from any part**, so a stray rehearsal mark in one part wins.
- **A short first bar without `implicit="yes"`** is right-aligned as bar 1, not renumbered to bar 0.
- **The contract between core and mark readers is fixed at step 13.** If the record fields change after the fan-out, every worktree has to be reworked.
- **Rejecting declared entities** uses `ParseError`. The alternative, `UnsupportedFeatureError`, was considered: the input is valid XML, but no export declares entities.
- **Out of scope:** the follow-on stories, once this lands.
  - Timeline Expressions should add MusicXML tempo reading and writing.
  - MEI Import should reuse `xml_reading.rb` and the security preflight rather than copying them.
