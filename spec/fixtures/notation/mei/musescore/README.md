# MuseScore 4 MEI exports

Each `<name>.musescore4.mei` here is MuseScore's MEI export of the committed MusicXML fixture `spec/fixtures/notation/music_xml/<name>.head_music.musicxml`, which is head_music's own render of a public-domain fixture. The music is the gem's and the encoding is MuseScore's. The table of names and sources is in `spec/fixtures/notation/music_xml/README.md`.

Regenerate every export with:

```bash
bundle exec rake mei:musescore_fixtures
```

The task converts each file with MuseScore Studio 4.7.5 (`mscore --version` prints `MuseScore4 4.7.5`), under a 120-second timeout:

```bash
"/Applications/MuseScore 4.app/Contents/MacOS/mscore" -o <name>.musescore4.mei <name>.head_music.musicxml
```

Set `MSCORE` to use another executable. The exit status is unreliable (often 134 "Abort trap: 6", with the file written), so the task judges a conversion by whether its output exists and is well-formed XML. A regeneration differs from the committed files in every `xml:id` and in the `<date isodate>`, even on the same day.

## What MuseScore changes

In every file, MuseScore:

- declares `meiversion="5.1+basic"` and adds two `<?xml-model?>` instructions for `mei-basic.rng`, one RELAX NG and one Schematron;
- gives measures, events, tuplets, endings, verses, and control events random `xml:id`s such as `n1fhyi8m`, names the section, staves, and layers by position (`s1`, and `m1s1` and `m1s1l1` for bar 1's staff and layer), and gives `<beam>`, `<graceGrp>`, `<staffGrp>`, and `<syl>` none;
- writes `<title type="main">` and a `<pubStmt><date isodate="…"/>` stamped with the moment of the conversion, and drops the gem's `<encodingDesc>`;
- adds a `<pgHead func="first">` to the `<scoreDef>`, repeating the title (and in `bach_invention_01` the composer) as `<rend>`s;
- opens the section with `<pb/>`, and writes `<sb/>` between measures wherever its own layout breaks a system (`speed_the_plough` once; `bach_invention_01` six times, with a second `<pb/>`);
- moves the meter and key from the `<scoreDef>` to every `<staffDef>`, drops `@key.mode` and `@midi.bpm`, and omits `@keysig` for C major;
- adds a `<label>` and an `<instrDef midi.instrnum>` to each `<staffDef>`, or to the `<staffGrp>` of a grand staff. A part with no name is labelled "Voice 1", "Voice 2", and so on;
- writes ties as `<tie startid endid>` control events at the end of the measure, never as `@tie`;
- writes accidentals as `<accid>` children, `<accid accid="s"/>` where one prints and `<accid accid.ges="s"/>` where the key or an earlier note in the bar supplies it, never as `@accid` attributes;
- writes articulations as `<artic>` children, never as `@artic`;
- wraps beamed notes in `<beam>` and marks them `type="mscore-beam-begin"` and `type="mscore-beam-mid"`, and an unbeamed rest among beams `type="mscore-beam-none"`;
- indents with three spaces and writes a space before `/>`.

File by file:

- **`triplets`:** each `<beam>` holds its `<tuplet>`, the reverse of the gem's nesting.
- **`speed_the_plough`:** the backward repeat's measure carries `type="mscore-repeat-2"`.
- **`two_verses`:** the pickup `<measure>` has no `@n` and no `type="upbeat"`, and bar 1 is `n="1"`. Every `<verse>` has `place="below"`.
- **`grace_notes_before_downbeat`:** grace notes sit in `<graceGrp>`, which carries `@grace` while the notes carry none. The grace values are the reverse of the gem's: MuseScore writes an unslashed grace as `grace="acc"` and the slashed one as `grace="unacc"`, where the gem writes `unacc` and `acc`. The tie from the last grace note is a `<tie>` control event.
- **`clef_changes`:** the octave treble clef is `dis="8" dis.place="below"`. A clef change is written inside the layer after the last note of the bar before it, at the same moment.
- **`key_and_meter_change`:** the change is a `<scoreDef keysig="2s" meter.count="3" meter.unit="4"/>` between measures.
- **`cross_staff_piano` and `piano_part_marks`:** the left hand is layer 2 of staff 1, with `@staff="2"` on its notes in bars 1 and 4 only, and staff 2 holds an `<mRest/>` in every bar (MuseScore's hidden voice 5 in its MusicXML).
- **`piano_part_marks`:** every `<dynam>` and `<hairpin>` names `staff="1"` and no layer, so the right hand's own marks cannot be told from the piano's. The right hand's crescendo from 2:3 is gone, and the two part hairpins have no `@endid` and no `@tstamp2`.
- **`bach_invention_01`:** the left hand is layer 1 of staff 2. The ornaments are `<mordent form="upper">` for the inverted mordent and `<mordent form="lower">` for the mordent.
- **`marked_dal_segno_al_coda`:**
  - the segno and coda signs become `<dir type="mscore-staff-text">` holding the SMuFL glyphs U+E047 and U+E048;
  - "To Coda" and "D.S. al Coda" are dropped;
  - the phrase mark becomes a second `<slur>`;
  - the note dynamics *sfz* and *fp* become `<dynam>` control events at their notes;
  - the trill is a `<trill startid>` with no end;
  - the turn gets `form="upper"`;
  - the crescendo ending on the final barline has no `@endid`.
- **`marked_da_capo_al_fine`:**
  - "Fine" and "D.C. al Fine" are dropped;
  - each `<ending>` has `@label` ("1.", "2.") and `type="mscore-ending-1"`, but no `@n`;
  - the second ending has `lendsym="none"`;
  - the repeat's measure carries `type="mscore-repeat-2"`.
- **`barline_styles`:** "Fine", "To Coda" and "D.C." are dropped. Each staff's rehearsal mark is its own `<reh>`, as in the source.
- **`clarinet_changes`:** the instrument changes are dropped. The whole staff is labelled "Clarinet", with `midi.instrnum="71"`.
- **`clarinet_changes_transposed`:** the staff gets `trans.diat="-1" trans.semi="-2"` once, at the start. The changes to the A clarinet and the flute come through only as `<scoreDef keysig>` changes (`3f`, then `0`), and the written pitches change with no new `@trans.*`. Read at concert pitch, bars 3 and 4 come out a semitone high and bars 5 and 6 a whole step low.
