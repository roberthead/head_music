<!--
metadata:
  created_at:   2026-09-24T18:58:30-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-10-15T13:30:19-07:00
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
flow.name          # => from <meiHead> <title>
flow.voices.length # => one per staff layer
```

## Acceptance Criteria

### Entry points and structure

- [ ] `HeadMusic::Notation::MEI.parse(string)` returns a `HeadMusic::Content::Flow` from a document with one `<mdiv>`, and raises `MEI::ParseError` for one with several
- [ ] `MEI.parse_book(string)` returns one flow per `<mdiv>`, as `ABC.parse_book` does for a tune book
- [ ] MEI 5 is read, and MEI 4 where its elements are the same
- [ ] Malformed XML, a missing `<music>` or `<score>`, and a `@startid` or `@endid` that names no element raise `MEI::ParseError` naming the element
- [ ] Mensural, neume, and tablature notation (`@notationtype`, `<mensur>`, `<neume>`, `<tabGrp>`) raise `MEI::UnsupportedFeatureError` for the whole document
- [ ] Elements the reader does not use are skipped, not rejected. These include `<pgHead>`, `<sb>`, `<pb>`, facsimile and surface data, `<fing>`, `<harm>`, `<pedal>`, `<octave>`, `<breath>`, `<bend>`, and `<expansion>`

### Identity

- [ ] `<meiHead>` `<title>` names the flow, and the composer (`<composer>`, or `<persName role="composer">`) becomes a composer `Credit` on a `Work` titled from it, as kern import builds one

### Parts, staves, and voices

- [ ] Each `<staffDef>` becomes a staff. A `<staffGrp>` with `symbol="brace"` whose staves share one label becomes one multi-staff part. Every other staff becomes a part of its own
- [ ] A `<staffDef>` label becomes the name of its part's player, a `Player` with no project
- [ ] Each `<layer>` number on a staff becomes a voice. A layer that starts late or ends early is padded with rests, so every voice satisfies `Voice::Continuity`
- [ ] A layer that moves to another staff of its part at a barline becomes a staff crossing; `@staff` on a single note, a cross-staff note, is skipped
- [ ] `<clef>` in a `<staffDef>` or at a barline sets the staff's clef or a clef change

### Notes and rhythms

- [ ] `<note>` `@pname`, `@oct`, `@dur`, and `@dots` map to pitches and rhythmic values
- [ ] The sounding accidental is `@accid.ges` when present, and `@accid` otherwise, with child `<accid>` elements read as either. When neither is written, the key signature and earlier accidentals in the bar on that staff decide it
- [ ] `<rest>`, `<space>`, `<mRest>`, and `<multiRest>` become rests of their length. `<chord>` becomes a note event with several pitches
- [ ] Ties (`@tie`, or `<tie>` control events) fold into one placement, including across barlines; an unclosed tie or a tie between different pitches raises `ParseError`
- [ ] `<tuplet>` and `<tupletSpan>` map to tuplet values and groups, and `@grace` to grace notes
- [ ] `<beam>` and `<beamSpan>` read back as beam breaks where they differ from the default grouping
- [ ] The notes inside `<bTrem>` and `<fTrem>` are read and the tremolo is skipped
- [ ] A first measure with `type="upbeat"`, or one shorter than its meter at the start, is a pickup

### Timeline

- [ ] The key (`@key.sig`, `<keySig>`, with `@key.mode` or `@mode` as tonal context) and the meter (`@meter.count` and `@meter.unit`, or `<meterSig>`) map to the timeline, including `<scoreDef>` and `<staffDef>` changes at later measures
- [ ] `<tempo>` with `@midi.bpm` or `@mm` becomes a tempo change at its measure
- [ ] `@trans.diat` and `@trans.semi` on a staff definition are honored, so transposing parts land in concert pitch

### Markings and spans

- [ ] `@artic` and `<artic>` become articulations, and `<trill>`, `<mordent>`, and `<turn>` become ornaments on their note
- [ ] `<dynam>` with a level becomes a dynamic event at its `@startid` or `@tstamp`, on the voice when it names a layer and on the part otherwise. A note dynamic such as *sfz* at a note becomes that note's dynamic. Text such as "cresc." is skipped
- [ ] `<hairpin>` becomes a hairpin from its start to its end, by id or by `@tstamp` and `@tstamp2`
- [ ] `<slur>` becomes a slur, and `<phrase>` a phrase mark; one the voice refuses, such as a slur on a rest, is dropped
- [ ] Barline styles (`@left`, `@right`), repeats, `<ending>`, `<reh>`, and `<repeatMark>` become bar markings

### Lyrics and editorial markup

- [ ] `<verse n>/<syl>` attaches syllables to their notes as verse n, and `@wordpos` `i` or `m`, or `@con="d"`, sets `hyphen_after`
- [ ] Editorial markup has a fixed rule, documented in the module. `<app>` takes `<lem>`, or else its first `<rdg>`. `<choice>` takes `<corr>`, `<reg>`, or `<expan>`. The contents of `<supplied>`, `<add>`, `<unclear>`, and `<restore>` are kept, and `<del>` is skipped

### Round trip and real files

- [ ] Every golden document from MEI Export parses back to a flow equal to the one rendered, and render, then parse, then render yields the same document
- [ ] The seeded generators in `spec/support` round-trip 100 seeds each through MEI, naming the seed on failure
- [ ] At least one real CMN edition from a public MEI corpus, under a license that allows it, parses end to end and is committed as a fixture
- [ ] With `MEI_CORPUS` pointing at a local folder of MEI files, every CMN file parses, or raises the error the spec names for it
- [ ] Maintains 90%+ test coverage

## Notes

- Parse with REXML, which is a runtime dependency of the gem (decided 2026-09-24).
- **Follow-up: mensural notation.** It is the most interesting long-term reason to read MEI here, since the species and Renaissance guides grade that repertoire. It is also a large model question, because of ligatures, proportions, and the absence of barlines.
- **Follow-up: a `reading:` option.** The editorial rule is fixed in v1. An option such as `parse(xml, reading: :sic)` is a natural follow-up once a caller needs it.
- **Waits on Timeline Expressions:** fermatas, tempo words, and `@meter.sym` wait on [Timeline Expressions](timeline-expressions.md).
- **Waits on Lyric Extenders:** `@con="u"` extenders wait on [Lyric Extenders](lyric-extenders.md).
- **Shapes MEI Export writes** (decided in that story, 2026-10-15). This story's criteria should be revisited when it is planned:
  - keys are `@keysig` (MEI 5.1 rejects `@key.sig`), so read it as well as `@key.sig`;
  - a multi-staff part is a `<staffGrp>` carrying the player's `<label>`, rather than staves sharing one label;
  - `mdiv/@label` is the flow's name, `scoreDef/@midi.bpm` the opening tempo, and `layerDef/label` a voice's role;
  - instrument changes are `<staffDef>` changes with a new `<instrDef>`;
  - an ending's passes are its `@n`, as `1-2`;
  - a bare `<staff n/>` means no voice on that staff; a voice with nothing in a bar writes `<layer><mRest/></layer>`, as MusicXML writes a whole-measure rest;
  - a layer's number is the voice's index within its part, kept across staff crossings;
  - tstamps of triplet onsets are rounded to four decimal places, so snap them to the tick grid;
  - `XmlReading` and `ParsePreflight` still live in `music_xml/`; move them to `Notation` with an `error_class:` parameter.

## Decisions

- **Valid notation the model cannot hold is skipped, not raised** (decided 2026-09-26, as policy for every reader).
- **Mensural, neume, and tablature documents raise** (decided 2026-10-14), as the one exception to that policy. Skipping them would leave no music to read, so a flow would be worse than the error.
- **Editorial choices are fixed in v1** (decided 2026-10-14): `<lem>`, then `<corr>`, `<reg>`, and `<expan>`.
- **Repeats and endings are kept** (decided 2026-10-14), since the model now holds bar markings and `Flow#performance_order` plays them out. `<expansion>` lists are skipped, as kern skips its expansion lists.
- **Markings, spans, multi-staff parts, tuplets, and grace notes are in scope** (decided 2026-10-14). MEI Export writes them, and the round trip needs them back.

## Implementation Plan

[to be filled in by /stories plan]
