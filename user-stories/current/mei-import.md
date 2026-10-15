<!--
metadata:
  created_at:   2026-09-24T18:58:30-07:00
  activated_at: 2026-10-15T14:21:10-07:00
  planned_at:   2026-10-15T14:45:59-07:00
  finished_at:
  updated_at:   2026-10-15T14:45:59-07:00
-->

# Story: MEI Import

## Summary

AS a developer or researcher using HeadMusic

I WANT to pass an MEI document and receive a `HeadMusic::Content::Flow`

SO THAT I can analyze the scholarly digital editions and early-music collections that are published in MEI

## Background

The [Music Encoding Initiative](https://music-encoding.org/) (MEI) is an XML format designed for scholarly editions. It keeps more meaning than MusicXML does:

- editorial markup (`<app>`, `<choice>`, `<supplied>`)
- sources and variants
- through its mensural module, early-music notation

Verovio renders MEI natively. Projects such as the Josquin Research Project, CRIM, and many library digitization efforts publish in it.

[MEI Export](mei-export.md) lands just before this story and describes the structure. This reader reads common music notation (CMN) MEI. It takes back everything that writer emits, and the usual ways other encoders write the same things. MEI often offers two forms for one thing:

- an attribute or a child element (`@key.sig` or `<keySig>`, `@tie` or `<tie>`, `@artic` or `<artic>`)
- a control event placed by note ids (`@startid`, `@endid`) or by beat (`@tstamp`, `@tstamp2`)

The reader takes both forms.

## Example

```ruby
flow = HeadMusic::Notation::MEI.parse(File.read("motet.mei"))
flow.name          # => from <mdiv label>, else the head <title>
flow.voices.length # => one per layer, as the part numbers them
```

## Acceptance Criteria

### Entry points and structure

- [ ] `HeadMusic::Notation::MEI.parse(string)` reads the one leaf `<mdiv>` in `mei/music/body` that holds a `<score>` or a single `<part>`. With several, it raises `MEI::ParseError` naming how many and pointing to `parse_book`. A `<score>` in `<meiHead>` (an `<incip>`) is never read
- [ ] `MEI.parse_book(string)` returns one flow per such `<mdiv>` in document order, descending nested `<mdiv>`s, `<music><group><music>`, and a `<meiCorpus>` root's `<mei>` documents. `Layout#to_mei` output reads back through `parse_book` as its flows, in order
- [ ] A `<parts>` encoding with one `<part>` reads as a score. Several `<part>`s raise `UnsupportedFeatureError`, since aligning them is new work no corpus file needs
- [ ] `@meiversion` is not checked, so `5.1+basic` (MuseScore) and `4.0.1` read alike. MEI 4 forms such as `@key.sig` are read beside MEI 5's
- [ ] The input guarantees of `MusicXML.parse` hold. UTF-8 with or without a BOM, UTF-16 with a BOM, and `File.binread` strings parse, and nothing is fetched. Declared entities, text past REXML's expansion limits, and nesting deeper than 256 elements raise `ParseError`
- [ ] Malformed XML, a missing `<music>`, a body with no `<score>` or `<part>`, a duplicate `xml:id`, and a `@startid`, `@endid`, or `@plist` naming no element raise `MEI::ParseError` naming the element. A reference into another file, or into a reading the editorial rule rejects, skips its control event
- [ ] No error outside `HeadMusic::Notation::ParseError` escapes. A table-driven spec covers every attribute the reader parses with hostile values
- [ ] These raise `MEI::UnsupportedFeatureError`:
  - mensural, neume, and tablature notation (`@notationtype`, `<mensur>`, `<ligature>`, `<neume>`, `<nc>`, `<tabGrp>`), for the whole document;
  - `<mRpt>`, `<mRpt2>`, `<beatRpt>`, `<halfmRpt>`, and `<multiRpt>`;
  - microtonal accidentals and `@keysig="mixed"`;
  - nested tuplets;
  - a `@dur` the model has no value for;
  - a mid-piece short measure that the next measure does not complete;
  - a later `<scoreDef>` that adds or removes staves.

  Each names its measure
- [ ] Elements the reader does not use are skipped, not rejected:
  - page and system layout: `<pgHead>`, `<pgFoot>`, `<sb>`, `<pb>`, facsimile and surface data;
  - markings the model does not hold: `<fing>`, `<harm>`, `<fb>`/`<f>`, `<pedal>`, `<octave>`, `<breath>`, `<bend>`, `<arpeg>`, `<gliss>`, `<lv>`;
  - text and annotation: `<anchoredText>`, `<annot>`, `<dir>` other than a repeat count, and `<tempo>` with text only;
  - `<expansion>`, and a `<barLine>` element inside a layer;
  - the visual attributes `@stem.*`, `@curvedir`, `@place`, and `@dur.ges`
- [ ] `XmlReading` and `ParsePreflight` move to `HeadMusic::Notation`, taking `error_class:`, a format name, and, for the preflight, `roots:`. `MusicXML::XmlReading` and `MusicXML::ParsePreflight` remain, and MusicXML's messages and specs are unchanged. **Breaking:** `BarMap`, `VoiceTrack`, `TieFolding`, `VoicePlacer`, and `ConcertTransposition` move from `MusicXML` to `Notation`

### Identity

- [ ] A flow is named by its `mdiv/@label`, else an enclosing `<music @label>`, else the first untyped or `type="main"` `titleStmt/title`
- [ ] A `Work` is built only from `workList/work`. Its composer `Credit` comes from `<composer>` (or its `<persName>`, whatever its `@role`) or from `persName[@role=composer]`. Without a `workList`, the composer becomes `flow.composer`. MEI Export writes `<workList>` for a flow with a `Work`
- [ ] A part's player is named by the `<label>` of a single-staff `<staffDef>` or of a multi-staff `<staffGrp>`. A group of single-staff parts labels none of them. The player is a `Player` with no project
- [ ] `<instrDef @label>` names the catalog instrument, falling back to a fixed table from `@midi.instrnum` (0-based) to `gm_program`. A `<staffDef>` change with a new `<instrDef>` is an instrument change at that bar. MEI Export writes `instrDef@label`

### Parts, staves, and voices

- [ ] Each `<staffDef>` becomes a staff. A `<staffGrp>` that carries its own `<label>` and holds several `<staffDef>`s is one multi-staff part, and so is one with `symbol="brace"` whose staves are unlabeled or share one label. Its `@symbol` sets the bracket. Every other staff is its own part
- [ ] Voice keys are decided per part. If no measure has one `layer/@n` holding notes on two of the part's staves, the layer number alone is the voice, as MEI Export numbers it. Otherwise the staff and layer number together are the voice, and a key with no notes anywhere is a placeholder that is not read. `layerDef/label` is the voice's role
- [ ] A layer whose notes all carry the same `@staff` sits on that staff for the bar, and a change at a barline is a staff crossing. Otherwise a single note's `@staff` is skipped
- [ ] A voice's leading and trailing bars of only `<mRest>` or `<mSpace>` are not placed. Such bars between its events, and missing layers, become bar-filling rests, and a short layer is padded. A bare `<staff n/>` places nothing. Every voice satisfies `Voice::Continuity`
- [ ] `<clef>`, or `staffDef@clef.*` with `@dis` and `@dis.place`, in a `<staffDef>` or at a barline sets the staff's clef or a clef change. A clef in the middle of a layer is skipped

### Notes and rhythms

- [ ] `<note>` `@pname`, `@oct`, `@dur`, and `@dots` map to pitches and rhythmic values, with `@pname.ges` and `@oct.ges` winning. `@dur` falls back to the enclosing `<chord>`, then `@dur.default`, and a note with none raises `ParseError`
- [ ] The sounding accidental is `@accid.ges` when present, and `@accid` otherwise, with child `<accid>` elements read as either. When neither is written, the key signature and earlier accidentals at that letter and octave in the bar on that staff, across its layers, decide it
- [ ] `<rest>`, `<space>`, `<mRest>`, and `<multiRest>` become rests of their length, and a `@cue` note is a rest. `<chord>` becomes a note event with several pitches
- [ ] Ties (`@tie`, or `<tie>` control events by ids or tstamps) fold across barlines when both ends are in one voice. An unclosed tie, `<lv>`, or a tie across voices is dropped, and the note keeps its written value. A tie on some pitches of a chord is skipped. A tie between pitches that share nothing raises `ParseError`
- [ ] `<tuplet>`, `<tupletSpan>` (by ids or `@plist`), and `@tuplet` `i`/`m`/`t` map to tuplet values and groups. A span over MEI Export's hidden per-bar tuplets is one group across the barline. `@grace` and `<graceGrp>` become grace notes
- [ ] `<beam>`, `<beamSpan>`, and `@beam` `i`/`m`/`t` read back as beam breaks where they differ from the default grouping
- [ ] `<bTrem>` reads as its note or chord, and `<fTrem>` reads its members in sequence at their own `@dur`. The tremolo itself is skipped
- [ ] A first measure with `type="upbeat"`, or one shorter than its meter at the start (`n="0"` without `@type` counts), is a pickup. A final measure with `metcon="false"` is a short final bar

### Timeline

- [ ] The key comes from `@keysig`, `@key.sig`, or `<keySig @sig>`, with `@key.mode`, `<keySig @mode>`, or `@key.pname` as tonal context. The meter comes from `@meter.count` and `@meter.unit`, or `<meterSig>`. Both are read on `<scoreDef>`, else on the first `<staffDef>`, at the opening and at later measures. `@meter.sym` with no count reads as 4/4 or 2/2, and a restatement makes no change. MEI Export writes `@key.mode`
- [ ] `scoreDef/@midi.bpm` is the opening tempo. A `<tempo>` with `@mm` (`@mm.unit`, `@mm.dots`) or `@midi.bpm` at a measure's start is a tempo change
- [ ] A `@tstamp` within 1/1000 beat of an onset in its layer, or else on its staff, takes that onset, and otherwise rounds to the tick. A `@tstamp2` beat one past the last bar's count is the final barline. Ids win when both are given, and a `@tstamp2` with no measure part is dropped when there are no ids
- [ ] `@trans.diat` and `@trans.semi` on a staff definition are honored from that bar onward, with 0/0 resetting, so transposing parts land in concert pitch

### Markings and spans

- [ ] `@artic` and `<artic>` become articulations, and `<trill>`, `<mordent>`, and `<turn>` become ornaments on their note
- [ ] `<dynam>` with a level becomes a dynamic event at its `@startid` or `@tstamp`, on the voice when it names a layer and on the part otherwise. A note dynamic such as *sfz* at a note becomes that note's dynamic. Text such as "cresc." is skipped
- [ ] `<hairpin>` becomes a hairpin from its start to its end, by id or by `@tstamp` and `@tstamp2`. A hairpin with no end is dropped
- [ ] `<slur>` and `@slur` `i`/`t` become slurs, and `<phrase>` a phrase mark. A tstamp-only slur resolves only when exactly one note starts at each end. One the voice refuses, such as a slur on a rest, is dropped
- [ ] Barline styles (`@left`, `@right`) and repeats become bar markings. So do `<ending>`, with passes from `@n` as `1`, `1-2`, or `1, 2`, else from `@label`; `<reh>`; a `<dir>` reading "×N", which sets a repeat's count; and `<repeatMark @func>` for coda, segno, D.C., and D.S. with al Fine and al Coda

### Lyrics and editorial markup

- [ ] `<verse n>/<syl>`, a bare `note/syl`, and `@syl` attach syllables to their notes as verse n, with a verse with no `@n` as verse 1. `@wordpos` `i` or `m`, or `@con="d"`, sets `hyphen_after`. Several `<syl>`s join with "‿", `<lb/>` is a space, and other `@con` values set nothing
- [ ] Editorial markup has a fixed rule, documented in the module. `<app>` takes `<lem>`, or else its first `<rdg>`. `<choice>` takes `<corr>`, `<reg>`, or `<expan>`, and `<subst>` takes its `<add>`. The contents of `<supplied>`, `<add>`, `<unclear>`, and `<restore>` are kept, and `<del>` is skipped. `@copyof` copies are expanded, and a cycle or runaway expansion raises `ParseError`

### Round trip and real files

- [ ] Every MEI Export golden parses back field by field to the flow that was rendered, with the exclusions named in the spec: tempo as quarter bpm, an authored whole-bar rest at a voice's edge, and tie spellings at barlines. Render, parse, and render again yields the same bytes
- [ ] The seeded generators in `spec/support` round-trip 100 seeds each through MEI, naming the seed on failure
- [ ] `Bach-JS_Herzliebster_Jesu_BWV244-46.mei` and `Bach-JS_Ein_feste_Burg.mei`, from music-encoding/sample-encodings MEI_5.1, are committed with the ECL-2.0 license and parse end to end. The spec checks bars, staves, key, and opening pitches
- [ ] MuseScore 4's MEI exports of the MusicXML fixtures are committed as `*.musescore4.mei` and parse to the music that was rendered, with MuseScore's changes listed per file. With `MSCORE` set, a spec reconverts them under a timeout
- [ ] With `MEI_CORPUS` naming local folders of MEI files, separated by `:`, every CMN file parses or raises the error the spec names for it. The story records sweeps of sample-encodings MEI_5.1, MEI_5.0, and MEI_4.0
- [ ] A generated 500-bar document reads in linear time, counted in calls rather than timed, with no XPath
- [ ] Maintains 90%+ test coverage

## Notes

- Parse with REXML, which is a runtime dependency of the gem (decided 2026-09-24).
- **Follow-up: mensural notation.** It is the most interesting long-term reason to read MEI here, since the species and Renaissance guides grade that repertoire. It is also a large model question, because of ligatures, proportions, and the absence of barlines.
- **Follow-up: a `reading:` option.** The editorial rule is fixed in v1. An option such as `parse(xml, reading: :sic)` is a natural follow-up once a caller needs it.
- **Waits on Timeline Expressions:** fermatas, tempo words, and `@meter.sym` wait on [Timeline Expressions](timeline-expressions.md).
- **Waits on Lyric Extenders:** `@con="u"` extenders wait on [Lyric Extenders](lyric-extenders.md).
- **Corpus:** clone `https://github.com/music-encoding/sample-encodings` (ECL-2.0) for the sweep. It holds 842 `.mei` files, 167 of them MEI 5.1. music21's three MEI test files are at `music21/mei/test/`.

## Decisions

- **Valid notation the model cannot hold is skipped, not raised** (decided 2026-09-26, as policy for every reader).
- **Mensural, neume, and tablature documents raise** (decided 2026-10-14), as the one exception to that policy. Skipping them would leave no music to read, so a flow would be worse than the error.
- **Editorial choices are fixed in v1** (decided 2026-10-14): `<lem>`, then `<corr>`, `<reg>`, and `<expan>`.
- **Repeats and endings are kept** (decided 2026-10-14), since the model now holds bar markings and `Flow#performance_order` plays them out. `<expansion>` lists are skipped, as kern skips its expansion lists.
- **Markings, spans, multi-staff parts, tuplets, and grace notes are in scope** (decided 2026-10-14). MEI Export writes them, and the round trip needs them back.
- **Planning choices adopted without stopping to ask** (2026-10-15, while running the seven-story goal; Rob may revise any). All of the planner's proposed story changes were adopted:
  - **Ties.** An unclosed tie is dropped rather than raised, matching MusicXML Import.
  - **Voices.** Voice keys are decided once per part: by layer number where no layer number appears on two staves in one bar, else by staff and layer.
  - **Staff crossings.** A layer takes the `@staff` that every note in the bar shares.
  - **Edge bars.** A voice's leading and trailing `<mRest>`-only bars are not placed, so tacet voices round-trip. The cost is that an authored whole-bar rest at a voice's edge reads back as absence.
  - **Single part.** A single `<part>` reads as a score, and several raise.
  - **`@copyof`.** It is expanded, with a cycle guard and an element budget.
  - **`Work`.** A `Work` comes only from `<workList>`.
  - **Tstamp snapping.** The tolerance is 1/1000 beat, since the corpus writes three decimals.
  - **Error handling.** There is no top-level `rescue StandardError`, since it would hide reader bugs.
  - **Writer additions.** MEI Export gains `instrDef@label`, `@key.mode`, and `<workList>`, because the golden round trip cannot pass without them: four SATB voices share GM program 52, and D dorian otherwise reads back as C major.

## Implementation Plan

### Overview

`HeadMusic::Notation::MEI.parse` and `parse_book` follow the MusicXML reader's two-phase shape:

- **Phase one:** a single walk over `<music>/<body>` puts each staff's layers into per-voice tracks. It also builds the `xml:id` index, resolves editorial markup and `@copyof` as it goes, and collects control events and `<scoreDef>`/`<staffDef>` changes.
- **Phase two:** the shared `BarMap`, tie folding, timeline, roster and `VoicePlacer` place the voices, and then a mark-reader registry applies markings from frozen records.

**Shared code moves first, and the writer gains three things.** `XmlReading`, `ParsePreflight` and the MusicXML reader core move into `HeadMusic::Notation`. The writer gains `instrDef@label`, `@key.mode` and `<workList>`; without them the golden round trip cannot pass.

**Specialists.** I consulted the product manager, the developer, and the best-practices engineer. The best-practices engineer was brought in for untrusted-XML security and REXML performance. The UI/UX designer and the accessibility specialist were skipped because the story has no UI.

All repository paths are relative to `/Users/roberthead/github.com/roberthead/head_music`.

**What I verified myself:**

- **MuseScore 4 exports MEI headlessly.** `"/Applications/MuseScore 4.app/Contents/MacOS/mscore" -o out.mei in.musicxml` works.
  - macOS has no `timeout`. `perl -e 'alarm 90; exec @ARGV' mscore …` works.
  - The exit status was 134 (Abort trap) on 2 of 3 runs, but the output was written every time.
  - The output declares `meiversion="5.1+basic"` and has random ids, `<pgHead>`, `<pb/>`/`<sb/>`, `<tie>` control events, child `<accid>`, `@accid.ges`, and a brace `<staffGrp>` carrying `<label>` and `<instrDef>`.
  - Probes are in `/private/tmp/claude-501/-Users-roberthead-github-com-roberthead-head-music/32cd5f96-66f9-4ba4-aa1b-0a3786f3fdb9/scratchpad/mei-import-plan/probe/` (`triplets.mei`, `cross_staff_piano.mei`, `bach_invention_01.mei`).
- **Corpus.** I cloned `https://github.com/music-encoding/sample-encodings` (ECL-2.0) into `/private/tmp/claude-501/-Users-roberthead-github-com-roberthead-head-music/32cd5f96-66f9-4ba4-aa1b-0a3786f3fdb9/scratchpad/mei-import-plan/corpus/sample-encodings`. It has 842 `.mei` files, 167 of them in `MEI_5.1`.
  - **Clone permanently:** `git clone --depth 1 https://github.com/music-encoding/sample-encodings ~/github.com/music-encoding/sample-encodings`.
  - Nothing else needs cloning. music21's three MEI test files (BSD-3, one of them UTF-16) are already at `~/github.com/cuthbertLab/music21/music21/mei/test/`.
- **Correction to my own brief.** MEI_5.1 uses `@keysig` in 130 files and `@key.sig` in none. MEI_4.0 is the reverse.
- **REXML 3.4.4 speed.** It parses and walks the largest file (Beethoven Op. 18/1: 2.7 MB, 35,667 elements) in 0.76 s of CPU time.
- **Developer citations I confirmed:**
  - `head_writer.rb:19-21`: the title is `@title || work&.title || name`.
  - `satb_chorale.mei` writes `midi.instrnum="52"` four times.
  - `fourth_species.mei` writes `keysig="0"` with no mode, although the source is D dorian (`spec/spec_helper.rb:375`).
  - `mei-CMN.rng` allows `att.labelled` on `instrDef`.
  - `voice_placer.rb:25` hard-codes `TupletReader`.
  - `part_reader.rb:17-21` defines `Reading`.
- **Best-practices claims I confirmed:**
  - `Pitch.get("C99999999")` returns C4.
  - `Pitch.get("C12")` returns nil.
  - REXML's `Elements#each` goes through `XPath::each` (rexml `element.rb:1957-1959`).

**Settled choices**, recorded for adoption; the reasons are in the steps and in Proposed story changes:

- Unclosed ties are dropped.
- Voice keys are decided once per part.
- A layer takes the `@staff` that every note in the bar shares.
- A voice's leading and trailing `<mRest>`-only bars are not placed.
- A single `<part>` reads as a score.
- `@copyof` is supported, with guards.
- A `Work` comes only from `<workList>`.
- Snapping uses a tstamp tolerance of 1/1000 beat.
- `<fTrem>` members are read in sequence.
- No top-level `rescue StandardError`.

### Steps

Each step is one commit. Run the touched specs, then `bundle exec rake` and `bundle exec rubocop -a`. Prove that each new spec fails on the old code by copying files aside, never with `stash`. Never assert console output. CHANGELOG lines go in commit bodies until step 17.

#### Shared base, on `story/mei-import` from `4a1ac50e`

Step 3 has no shared contract with steps 1–2 and touches only `mei/` writer files, so it can run in its own worktree from `4a1ac50e` while steps 1–2 run. Rebase it before step 4.

1. **Move `XmlReading` and `ParsePreflight` into `Notation`, add a depth cap, and iterate without XPath.**
   - New `lib/head_music/notation/xml_reading.rb`. `XmlReading.for(error_class, format:)` returns a module that can be included and also called directly.
     - The `format:` argument keeps MusicXML's messages exact. Today they are hard-coded at `music_xml/xml_reading.rb:31,35,47,62` and pinned by `parse_preflight_spec.rb:55` (`/expansion limits/`).
     - `MusicXML::XmlReading = Notation::XmlReading.for(MusicXML::ParseError, format: "MusicXML")`. Its 5 `include`s and 31 direct calls stay unchanged.
   - New `lib/head_music/notation/parse_preflight.rb`, called as `check!(xml, roots:, format:, error_class:, max_depth: 256)`. The depth check walks with an explicit stack, so a deep nest raises `ParseError` instead of `SystemStackError`.
     - `MusicXML::ParsePreflight` becomes a thin wrapper that keeps `ROOTS` (today at `music_xml/parse_preflight.rb:8`). Its messages at `:29,:34,:37` stay byte-identical (pinned by `parser_spec.rb:25,30`).
     - The best-practices engineer's probe: a recursive walk overflows at 20,000 levels, and `SystemStackError` is not a `StandardError`.
   - `first_child` and `children` (`music_xml/xml_reading.rb:50-59`) switch from `each_element` to `element.each { |child| … if child.is_a?(REXML::Element) }`. On the Beethoven file a walk drops from 0.407 s to 0.015 s, and a 10,000-deep nest from 3.1 s to 0.003 s.
   - Require both files in `lib/head_music/notation.rb` before `music_xml`.
   - Specs:
     - new `spec/head_music/notation/{xml_reading,parse_preflight}_spec.rb`, using a stub error class, with a 50,000-deep nest, a SYSTEM entity, `<xi:include>` and `<?xml-model?>` all kept inert;
     - `spec/head_music/notation/music_xml/{xml_reading,parse_preflight,parser}_spec.rb` pass unchanged.
   - Proof: a scratch dump script writes `MusicXML.parse(x).to_json` for every `spec/fixtures/notation/music_xml/**/*.musicxml` and every `MEIFixtures.every_fixture` render. Diff the dumps before and after, and break one line on purpose to show the diff catches it.
   - **Not breaking**, since both constants stay.

2. **Move the reader core into `Notation`.**
   - Moved classes:
     - `BarMap`, `VoiceTrack` and `TieFolding`;
     - `VoicePlacer`, gaining a `tuplet_reader:` keyword so it no longer hard-codes `TupletReader` at `voice_placer.rb:25`;
     - `ConcertTransposition`;
     - the spelling half of `pitch_reader.rb`, as `Notation::PitchSpelling`.
   - They raise through `reading.errors::ParseError` with `**reading.where(measure_index)`. `MusicXML::PartReader::Reading` (`part_reader.rb:17-21`) gains `where` (returning `{measure:, part:}`) and `errors`.
   - Update the callers in `music_xml/{flow_builder,part_reader,pitch_reader,mark_records,timeline_reader,part_roster}.rb`.
   - Specs: `spec/head_music/notation/music_xml/{bar_map,tie_folding,voice_placer,concert_transposition,pitch_reader}_spec.rb` change only their `describe` constant.
   - Proof: the same JSON dump diff, plus `MUSICXML_CORPUS` re-run against the existing manifest in `spec/head_music/notation/music_xml_corpus_spec.rb`.
   - CHANGELOG: **Breaking.** The five `MusicXML::` constants move.

3. **Writer additions the round trip needs** (worktree W0, three commits). After each one, run `bundle exec rake mei:golden_fixtures`, `MEI_SCHEMA=… mei_schema_spec`, and the gated `mei_muse_score_spec`.
   - **3a. `<instrDef label="name_key">`** wherever there is an instrument, with `midi.instrnum` only when there is a GM program.
     - Code: `ScoreDefWriter.instr_def_attributes` (`score_def_writer.rb:37-40`), which `timeline_changes.rb` also uses.
     - Reason: the SATB golden writes 52 for all four voices, and the transposed clarinet golden cannot re-render without the instrument.
     - Specs: `spec/head_music/notation/mei/{score_def_writer,timeline_changes}_spec.rb`.
   - **3b. `@key.mode`** on the opening `<scoreDef>` (`score_def_writer.rb:63-71`) and on key-change scoreDefs (`timeline_changes.rb:55-62`). It is nil outside MEI's `data.MODE`.
     - Reason: `fourth_species` (D dorian) otherwise reads back as C major.
   - **3c. `<workList><work><title/><composer><persName/></composer></work></workList>`** in `<meiHead>` (`head_writer.rb`).
     - Reason: the head `<title>` falls back to `flow.name` (`head_writer.rb:19-21`), so without a `<workList>` a flow with a `Work` cannot be told from one without.
     - Spec: `spec/head_music/notation/mei/head_writer_spec.rb`.
   - CHANGELOG: Added. All 13 goldens regenerate.

4. **Errors, entry points, parser, document, editorial markup, `@copyof`, id index, and typed values.**
   - `lib/head_music/notation/mei.rb`:
     - `parse` takes exactly one leaf `<mdiv>` holding a `<score>`, or a single `<part>`. Otherwise it raises `ParseError` naming the count and pointing to `parse_book`.
     - `parse_book` returns one flow per leaf `<mdiv>`, in document order.
     - `ParseError(message, line_number:, measure:, staff:, element:)`, shaped like `music_xml.rb:20-38`, where `element:` is the element's name and `xml:id`.
     - `UnsupportedFeatureError < ParseError`.
   - `mei/parser.rb`:
     - REXML and encoding rescues as in `music_xml/parser.rb:47-53`.
     - Roots `mei`, `meiCorpus` (each `<mei>` inside it) and `music`.
     - Never gate on `@meiversion`: `5.1`, `5.1+basic`, `4.0.1` and `5.1+anyStart` all occur.
   - `mei/document.rb`:
     - Searches only `music/body`. A `<score>` inside a head `<incip>` (22 sample files, including Herzliebster) is never read.
     - Descends nested `<mdiv>` and `<group>`.
     - Several `<part>`s raise `UnsupportedFeatureError`.
     - The notation-type check: `@notationtype` mensural, neume or tab, and `<mensur>`, `<ligature>`, `<neume>`, `<nc>`, `<tabGrp>`, raise `UnsupportedFeatureError`.
   - `mei/editorial.rb`: `Editorial.children(element)` gives an element's effective children, and every traversal (including the `<syl>` and `<title>` text) goes through it:
     - `<app>`: `<lem>`, else its first `<rdg>`;
     - `<choice>`: `<corr>`, `<reg>` or `<expan>`, else its first child;
     - `<subst>`: its `<add>`;
     - `<supplied>`, `<add>`, `<unclear>`, `<restore>`, `<damage>`: their contents;
     - `<del>`: nothing.
   - `@copyof` is expanded in the same helper, with:
     - a set of ids already being copied, so a cycle raises `ParseError`;
     - a total element budget of 4× the document's element count;
     - copies getting no index ids.
   - `mei/id_index.rb`:
     - Registered during the main walk; every reference is resolved after it.
     - Read the `"xml:id"` attribute.
     - Strip an optional `#`. A reference with a file part (`other.mei#x`) is unresolved, and its control is skipped.
     - A duplicate `xml:id` raises `ParseError`.
     - Ids inside rejected readings are recorded as `unchosen`, and a control naming one is dropped.
     - An id found nowhere raises `ParseError` naming the control and the id.
   - `mei/attribute_values.rb`: a declared table `READERS` maps attribute name to typed reader. Each reader:
     - matches a strict pattern, bounds the value, and raises `ParseError` naming the element and measure;
     - is the only place that calls `Integer()`, `Rational()`, `Pitch.get` or `Meter.get`.
     - `@dur` is read as a duration only on `note`, `rest`, `chord` and `space`, because legacy files put `@dur="0m+2.5"` on spans.
     - Bounds:
       - `@oct` 0..9, with the result's `midi_note_number` checked;
       - `@dots` ≤ 3 (as at `music_xml/note_reader.rb:12`);
       - `@num`/`@numbase` > 0;
       - `@meter.unit` a binary unit, `@meter.count` not additive (as at `music_xml/attributes_reader.rb:86-92`);
       - `@keysig` −7..7, with `mixed` unsupported;
       - `@tstamp` 0..count+1;
       - the measure part of `@tstamp2` no more than the bars left;
       - `@n` ranges parsed without `Range#to_a`.
   - No top-level `rescue StandardError`. It would turn reader bugs into manifest entries in the corpus sweep, and it still would not catch `SystemStackError` or hangs.
   - Specs (new, in `spec/head_music/notation/mei/`):
     - `parser_spec.rb`: line-numbered malformed XML, blank input, a BOM, and UTF-16 from music21's `notes_in_utf16.mei`;
     - `document_spec.rb`: incipit, `meiCorpus`, nested `mdiv`, `group`, a single `<part>`;
     - `editorial_spec.rb`, `copyof_spec.rb`, `id_index_spec.rb`;
     - `hostile_documents_spec.rb`, which enumerates `READERS` against a list of bad values and expects `ParseError`, `UnsupportedFeatureError` or a flow, never any other class.
   - Support: `spec/support/mei_documents.rb`, which wraps measure snippets into full documents, modeled on `music_xml_documents.rb`.

5. **Walking skeleton and identity.**
   - `mei/staff_groups.rb`: a nested `<staffGrp>` is one multi-staff part when either:
     - it carries its own `<label>` or `@label` and no `staffDef` in it has one (the writer at `score_def_writer.rb:78-88`, and MuseScore); or
     - its `@symbol="brace"` and its `staffDef` labels are all absent or all equal.
     Every other staff is its own part, and `@symbol` sets the bracket.
   - `mei/clef_reading.rb`: `<clef>`, or `staffDef@clef.*` (1,067 attribute-form clefs in the corpus), inverting `score_def_writer.rb:18-33`.
   - `mei/pitch_reading.rb` and `mei/accidental_reading.rb`:
     - pitch from `@pname.ges`/`@oct.ges`, else `@pname`/`@oct`;
     - accidental from `@accid.ges`, else `@accid`, else a child `<accid>`, else the key and earlier accidentals at that letter and octave on the staff in that bar, across its layers in onset order (the inverse of `accidental_plan.rb`);
     - a tie continuation takes its chain's pitch;
     - quarter tones raise `UnsupportedFeatureError`.
   - Durations invert `Durations::BY_UNIT_NAME` (`durations.rb:4-17`). The fallback chain is the enclosing `<chord>`, then `@dur.default`; with neither, `ParseError`.
   - `mei/identity_reader.rb`:
     - The name is `mdiv/@label`, else the `@label` of an enclosing `<music>`, else the first untyped or `type="main"` `titleStmt/title`.
     - A `Work` comes only from `workList/work`, with composer credits from `<composer>` text or its `<persName>` (whatever its `@role`), or from `respStmt/persName[@role=composer]`.
     - Without a `workList`, composers become `flow.composer`.
     - The player comes from the group or staffDef label.
     - The instrument comes from `instrDef@label`, else a fixed GM-program table, else nil.
   - Opening values:
     - the key from `@keysig`, `@key.sig` or `<keySig @sig>`, with `@key.mode`, `<keySig @mode>` or `@key.pname` as context through `KeyMapper.tonal_context`;
     - the meter from `@meter.count`/`@meter.unit` or `<meterSig>`, on `<scoreDef>` or else the first `<staffDef>` (MuseScore puts the meter only on staffDefs); `@meter.sym` alone means 4/4 or 2/2;
     - the tempo from `@midi.bpm`.
   - Specs: `reader_notes_spec.rb`, `staff_groups_spec.rb`, `accidental_reading_spec.rb`, `identity_reader_spec.rb`.

6. **Bars and timeline** (`mei/score_reader.rb`, `mei/timeline_reader.rb`).
   - **Pickups.** The first measure is a pickup when it has `type="upbeat"` or is shorter than its meter (Herzliebster: `n="0"` with no type). It is marked `implicit` before `BarMap`.
   - `metcon="false"` on the final measure is a short final bar. A short measure that the next one completes is one bar.
   - `<multiRest num>` expands into that many bars of rest.
   - **Raises `UnsupportedFeatureError`:**
     - `<mRpt>`, `<mRpt2>`, `<beatRpt>`, `<halfmRpt>`, `<multiRpt>`;
     - a later `<scoreDef>` that adds or removes staves.
   - **Later changes.** A `<scoreDef>` or `<staffDef>` before a measure can change the key, meter, clef, `trans.*`, or the instrument (a new `<instrDef>`). A restatement makes no change.
   - **Tempo.** A `<tempo>` at beat 1 with `@mm`/`@mm.unit`/`@mm.dots`, else `@midi.bpm`. A tempo with only text, or one in the middle of a bar, is skipped.
   - **Disagreement.** The first part's key wins.
   - Specs: `reader_bars_spec.rb`, `timeline_reader_spec.rb`.

7. **Voices and staves** (`mei/layer_reader.rb`, `mei/staff_state.rb`).
   - **Voice keys are decided once per part.**
     - If no measure has the same `layer/@n` holding notes on two of the part's staves, voices are keyed by `n`. That is the writer's numbering (`render_plan.rb:170-173`).
     - Otherwise they are keyed by staff and `n` (the corpus, MuseScore). A key with no notes anywhere in the part is dropped as a placeholder.
     - A `<layer>` with no `@n` is 1.
   - **Roles** come from `layerDef/label` (`score_def_writer.rb:114-120`).
   - **The staff a layer is on in a bar** is the enclosing `<staff>`, unless every note and chord in it carries the same `@staff` naming another staff of the part. Otherwise a single note's `@staff` is skipped. `VoicePlacer.assign_staves` then makes the crossings at barlines.
   - **Rests and fills:**
     - A bare `<staff n/>` places nothing.
     - A voice's leading and trailing bars holding only `<mRest>` or `<mSpace>` are not placed (the writer's tacet shape, `measure_writer.rb:72-77`).
     - Such bars between its events, and missing layers, become rests that fill the bar. A layer that ends short is padded.
     - `<space>` is a rest. A `@cue` note is a rest.
     - `<chord>` is one event. `<bTrem>` reads as its note or chord, and `<fTrem>` reads its members in sequence.
     - `@grace` and `<graceGrp>` become grace notes, with `acc` as slashed.
   - Specs: `reader_voices_spec.rb`, with a shared "music stays whole" matcher; `reader_staves_spec.rb`, on `cross_staff_piano.mei` and the MuseScore probe shape.

8. **Ties** (`mei/tie_controls.rb`).
   - `@tie` i/m/t and `<tie>` by ids or tstamps set tie starts and stops before the shared `TieFolding`.
   - Unclosed ties, `<lv>`, and ties whose ends are in different voices are dropped, with the note keeping its written value (as at `tie_folding.rb:8-14`).
   - A tie between pitches that share nothing raises.
   - Spec: `reader_ties_spec.rb`.

9. **Tuplets** (`mei/tuplet_reader.rb`, `mei/tuplet_spans.rb`).
   - A `<tuplet num numbase>` container scales its contents.
   - A `<tupletSpan>`, by ids or `@plist`, scales the events between its ends.
   - `@tuplet` i/m/t is read too: the corpus has 5,479, and the Beethoven quartet uses no containers at all.
   - A span absorbs the hidden per-bar tuplets it covers (`layer_containers.rb:71,83-93`).
   - A span placed only by tstamps is skipped; `BarMap` then raises on the overfull bar.
   - Nested containers raise `UnsupportedFeatureError`.
   - Spec: `reader_tuplets_spec.rb`, through `bracket_summary`.

10. **Concert pitch.**
    - `@trans.diat`/`@trans.semi` per staffDef go into the shared `ConcertTransposition`. A later staffDef replaces them, and 0/0 resets.
    - Spec: `reader_transposition_spec.rb` on `clarinet_changes_transposed.mei`.

11. **Mark records, registry, control anchors, and the core size spec.** This step freezes the contract.
    - Files: `mei/mark_records.rb`, `mei/mark_reader.rb`, `mei/mark_readers.rb` (stub readers), `mei/control_anchors.rb`.
    - **Control anchors:**
      - Ids win over tstamps.
      - A tstamp is an offset of `(tstamp − 1) / meter.unit` in its measure.
      - It snaps to the nearest onset within 1/1000 beat, looking first in the voice named by `@staff` + `@layer`, then on that staff. Otherwise it rounds to the tick through `BarSplitter.position_at`.
      - `@tstamp2` `"Nm+b"`, with `b` equal to count + 1 in the last bar, is `flow.final_barline_position` (`tstamp.rb:16-21`).
      - A `@tstamp2` with no measure part, or a span that ends before it starts, is dropped unless it has ids.
      - Every position is built from its own bar. `Position#normalize` (`content/position.rb:128-146`) walks one bar at a time.
      - Onsets are found by bisecting a sorted list per track and measure.
    - Spec `spec/head_music/notation/mei/flow_builder_size_spec.rb`, shaped like `music_xml/flow_builder_size_spec.rb`:
      - Generate MEI with 2 parts × 2 layers, triplets, `@tie` and `<tie>` across barlines, grace notes, slurs by id, `<dynam>` by tstamp, a `tupletSpan`, a `beamSpan @plist`, an `<app>` whose rejected reading a control names, and verses, at 250 and 500 bars.
      - `Position#initialize`, `Flow#meter_at` and `Voice#voice_event_preceding` grow at most 2.2×.
      - The reader makes zero calls to `REXML::XPath.match`/`.first` and to `REXML::Elements#each`.
      - Every voice ends with `revision.zero?`. No wall-clock assertions.

#### Parallel worktrees, all from step 11's commit

Name that commit's hash in every prompt, because worktree agents branch from `main`. Make the worktrees by hand, since a sandbox hook intermittently refuses commands containing "git". Give each agent its own scratch folder, `scratchpad/mei-<name>/`. CHANGELOG lines go in commit bodies.

**The frozen contract** (`mei/mark_records.rb`):

- `EventRecord = Data(:part, :voice, :voice_event, :kind, :chord_member, :grace, :grace_index, :continuation, :bar_number, :onset, :measure, :staff, :element)`
  - One per `<note>`, `<chord>`, `<rest>`, `<mRest>` and `<space>`, in document order.
  - `kind` is one of `:note`, `:chord`, `:rest`, `:m_rest`, `:space`.
  - `voice_event` is nil for a dropped grace note.
- `Anchor = Data(:position, :voice, :voice_event, :grace_index, :record)`
- `ControlRecord = Data(:part, :voice, :bar_number, :measure, :element, :start, :finish, :plist)`
  - `start` and `finish` are already resolved Anchors.
  - `@staff` lists such as `"1 2"` use the first staff.
- `MeasureRecord = Data(:bar_number, :measure, :element, :last, :ending_passes, :mid_bar)`
- Hooks are `event`, `control`, `measure` and `apply(flow)`, registered in `MEI::MARK_READERS`, under the rules of `music_xml/mark_reader.rb:3-10`. Readers never touch the id index.

| Worktree | Files owned (`lib/head_music/notation/mei/`, specs in `spec/head_music/notation/mei/`) | What it reads |
|---|---|---|
| 12a Markings | `artic_reader.rb`, `ornament_reader.rb`, `lyric_reader.rb` | Inverts `ArticAttributes` and `MarkingEvents` ornaments. Lyrics: `verse/syl`, bare `note/syl`, `@syl`; `@wordpos` i/m or `@con="d"` sets the hyphen; several `<syl>`s join with "‿"; `<lb/>` is a space; `@con` values `u`, `s`, `b`, `t` and `false` set nothing |
| 12b Dynamics | `dynam_reader.rb`, `hairpin_reader.rb` | Levels go to the voice with `@layer`, else to the part. A note dynamic at `@startid` (`marking_events.rb:104`). Text is skipped. Hairpins by ids or tstamps, ids winning; a hairpin with no end is dropped |
| 12c Curves | `slur_reader.rb`, `beam_reader.rb` | `<slur>` and `<phrase>`, plus `@slur` i/t (484 in the corpus). Tstamp-only spans resolve only when exactly one note starts there. Beams from `<beam>`, `<beamSpan plist>` and `@beam` (1,358) against `BeamGroups.group_start?`, as `music_xml/beam_reader.rb:51` does |
| 12d Bars | `barline_reader.rb`, `navigation_reader.rb` | `@left`/`@right`, including `rptboth`. `end` on the last bar stays regular (`bar_marks.rb:25-30`). `<ending n>` as `1`, `1-2` or `1, 2`, else digits in `@label`, else the order in the section. `<reh>`, `<repeatMark @func>`, and `<dir>` "×N" or "xN" (`navigation_events.rb:35`) |
| 12e Fixtures | the `mei:musescore_fixtures` task in `Rakefile`; `spec/fixtures/notation/mei/musescore/**`; `spec/fixtures/notation/mei/real/` | Runs `mscore -o <name>.musescore4.mei <name>.head_music.musicxml` over every MusicXML fixture under the perl alarm, checking that the output exists and ignoring the exit code. Copies `MEI_5.1/Music/Complete_examples/Bach-JS_Herzliebster_Jesu_BWV244-46.mei` and `Bach-JS_Ein_feste_Burg.mei` with the ECL-2.0 `LICENSE` and a `README.md` (both encodings say "public domain" in `useRestrict`) |

#### Coordinator, after cherry-picking

14. **Round trips.**
    - New `spec/support/mei_round_trip.rb` (`expect_mei_round_trip`, `expect_mei_idempotent`) and `spec/head_music/notation/mei_round_trip_spec.rb`.
    - Coverage:
      - every golden: field-by-field equality, and render → parse → render byte-identical;
      - `MEIFixtures.every_fixture`;
      - the fixture modules listed at `music_xml_round_trip_spec.rb:18-35`;
      - `TupletGenerator::SEEDS` and `HairpinGenerator::SEEDS` (both `1..100`), as `it "round-trips seed #{seed}"`;
      - `TUPLET_SEEDS=1..2000`, once by hand.
    - The transposed clarinet re-renders through a layout, as `MEIFixtures::RENDERS` builds it.
    - **Named exclusions:**
      - comments, source, origin;
      - tempo compared as quarter-note bpm;
      - an unauthored clef compared as the writer's fallback;
      - tie spellings at barlines compared by length;
      - beams and tuplets compared as rendered containers;
      - an authored whole-bar rest at a voice's start or end, which reads back as absence.
15. **Real files.**
    - `spec/head_music/notation/mei_real_files_spec.rb` compares each `*.musescore4.mei` with `MusicXML.parse` of its source, with a per-file list of what MuseScore changes. Regeneration is gated on `MSCORE`, with the alarm.
    - **Herzliebster:** title, `Work`, composer, 4 parts, bars 0..12, D major, 4/4, fermatas and `<sb>` skipped, incipit ignored.
    - **Ein feste Burg:** per-staff layers, lyrics, and slurs carrying both ids and tstamps.
    - music21's `test_file.mei` and `notes_in_utf{8,16}.mei`.
16. **Corpus and scale.**
    - `spec/head_music/notation/mei_corpus_spec.rb`, gated on `MEI_CORPUS` (colon-separated folders):
      - A manifest maps a path or glob to `[error class, message regex]`, with a guard that every key still matches a file.
      - It asserts that nothing outside `HeadMusic::Notation::ParseError` escapes, and runs "music stays whole" on every flow.
    - Sweep MEI_5.1, MEI_5.0, MEI_4.0 and music21's files, and record the results in the story.
    - A full-reader TracePoint ratio at N and 4N bars must stay under 4.5. Record a CPU-time note for the Beethoven quartet.
17. **Adversarial review, then record and fold.**
    - A hostile-document review of `MEI.parse`.
    - Tick the criteria and record the decisions.
    - Fold the CHANGELOG, with step 2 marked **Breaking.**, and steps 3a–c and the reader as Added.

### Testing Strategy

- **Hostile values from step 4 on.**
  - The table-driven `hostile_documents_spec.rb` covers every `READERS` attribute with `["", " ", "-1", "0", "99999999", "1e400", "1_0", "+3", "NaN", "x"*1000]`.
  - Named cases:
    - `@oct="99999999"`, `@pname="h"`, `@dots="1000000"`;
    - `@num="0"`, `@numbase="0"`;
    - `@meter.unit="0"` and `"3"`, `@meter.count="3+2"`;
    - `@tstamp2="99999999m+1"`, `@n="1-1000000000"`;
    - `@keysig="mixed"` and `"99s"`, `@trans.semi="99999999"`;
    - a note with no `@pname`, an empty `<chord>`;
    - a duplicate `xml:id`, a self-referencing span, an id in a rejected reading;
    - a `@copyof` cycle and a `@copyof` blowup;
    - a 100,000-id `@plist`, a 50,000-deep nest;
    - billion laughs in an attribute and in `<title>`.
- **"Music stays whole"** at every skip point:
  - a mid-bar clef or tempo;
  - single-note `@staff`, and placeholder layers;
  - `<fermata>`, `<harm>`, `<fb>`, `<pedal>`, `<octave>`, `<arpeg>`, `<gliss>`, `<anchoredText>`;
  - late and early layers.
- **Round trips:** the goldens, every fixture, and 100 seeds per generator, plus idempotence.
- **Real files:** the MuseScore exports, the two Bach editions and music21's files. **Corpus:** the gated manifest.
- **Scale:** call counts at two sizes, zero XPath, and `revision.zero?`. Never wall-clock time.
- **Regression proof for the moves:** the JSON dump diff of MusicXML parsing, and a re-run of `MUSICXML_CORPUS`.

### Risks & Open Questions

All settled with a recommendation:

- **Writer changes 3a–c alter all 13 goldens, and MuseScore's import might choke on `instrDef@label`.** If it does, its spec strips the attribute, as it already strips layer labels. The product manager preferred a GM table plus an exclusion over `@label`. I chose `@label` because a GM program cannot tell SATB voices apart (all 52) and the transposed clarinet cannot re-render without it. The GM table stays as the fallback for foreign files.
- **Moving the core (step 2) risks the finished MusicXML reader.** The dump diff and the corpus re-run come before any MEI code.
- **`<parts>`.** The developer said raise, the product manager said read. All three corpus files hold one `<part>`, so a single part reads as a score, and several raise `UnsupportedFeatureError`, since aligning them is new machinery.
- **Leading and trailing `<mRest>` bars.** The developer's alternative, padding and comparing runs of rest, would leave tacet voices unequal to the flow that was rendered. I chose not placing them. The cost is that an authored whole-bar rest at a voice's edge reads back as absence. That is named as an exclusion, and bytes re-render identically either way.
- **Tstamp tolerance.** The product manager proposed 0.0001; I chose 1/1000 beat. The writer's rounding error is 0.00005, but the corpus has 1,197 three-decimal tstamps.
- **The voice-key and `staffGrp` rules may misread foreign layouts.** Known gap: a multi-staff part with a `bracket` and no label reads as separate parts. The corpus manifest pins any misreads.
- **A `tupletSpan` placed only by tstamps** leaves its values unscaled. `BarMap` refuses the bar, and the corpus has one such span.
- **`@copyof` expansion is new attack surface.** The cycle set and the element budget are tested in step 4. If it proves costly, the fallback is `UnsupportedFeatureError` for the whole document. Silent skipping is not an option, because it yields empty bars.
- **MuseScore's exit code is 134 on most runs, and it may hang.** Check that the output exists, and keep the 90 s alarm.
- **A second session on the same repo** caused trouble in MEI Export. Check for peer sessions before resuming a fan-out.
- **Dependent stories** need MEI read lines; see the last two items below.
