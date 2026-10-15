# MusicXML fixtures

Real-file fixtures for the MusicXML reader. Every file here is public-domain music or MIT-licensed test material.

## MuseScore 4 conversions

Each `<name>.head_music.musicxml` is head_music's own render of a public-domain fixture, made with `HeadMusic::Notation::MusicXML.render`. Each `<name>.musescore4.musicxml` beside it is MuseScore's serialization of that render. MuseScore read the render and wrote it back out, so the music is the gem's and the encoding is MuseScore's.

The flows and the list of names live in `spec/support/musescore.rb` (`MuseScoreFixtures::RENDERS`). Regenerate everything with:

```bash
bundle exec rake music_xml:musescore_fixtures
```

The task converts each render with MuseScore Studio 4.7.5 (`mscore --version` prints `MuseScore4 4.7.5`):

```bash
"/Applications/MuseScore 4.app/Contents/MacOS/mscore" -o <name>.musescore4.musicxml <name>.head_music.musicxml
```

Set `MSCORE` to use another executable. The exit status is unreliable (0 on one run, 134 "Abort trap: 6" on the next, with the file written both times), so the task judges a conversion by whether its output exists and is well-formed XML. MuseScore stamps `<encoding-date>` with the day of the conversion, so a regeneration on another day differs in that line alone.

| Name | Source | What it gives MuseScore |
| --- | --- | --- |
| `speed_the_plough` | `ABCFixtures::SPEED_THE_PLOUGH` | Repeats, beams, a sharp key |
| `bach_invention_01` | `spec/fixtures/notation/lily_pond/bach_invention_01.ly` | A grand staff, two voices, ornaments, thirty-second notes, chords |
| `cross_staff_piano` | `LilyPondFixtures.cross_staff_piano` | A left hand crossing to the treble staff and back |
| `piano_part_marks` | `MarkingFixtures.grand_staff_piano_with_dynamics` plus part hairpins | Part dynamics and hairpins on a grand staff, with a right-hand level and hairpin |
| `marked_dal_segno_al_coda` | `NavigationFixtures.dal_segno_al_coda` plus marks | Segno, To Coda, D.S. al Coda, coda, rehearsal marks, articulations, ornaments, note dynamics, levels, slurs, a phrase mark, hairpins, one ending on the final barline |
| `marked_da_capo_al_fine` | `NavigationFixtures.da_capo_al_fine` plus marks | A repeat with first and second endings, Fine, D.C. al Fine, levels, hairpins, a slur, an accent |
| `barline_styles` | `LilyPondFixtures.barline_styles` | Dashed, dotted, and final barlines, Fine, To Coda, D.C., two parts |
| `key_and_meter_change` | `LilyPondFixtures.key_and_meter_change` | A key and meter change, two parts |
| `clef_changes` | `MuseScoreFixtures.clef_changes` | An octave treble clef, and a cello moving into tenor clef and back |
| `triplets` | `TupletFixtures.triplets` | Triplet eighths and quarters |
| `grace_notes_before_downbeat` | `TupletFixtures.grace_notes_before_downbeat` | Slashed, tied, slurred, chorded, and articulated grace notes |
| `two_verses` | `MuseScoreFixtures.two_verses` | New Britain ("Amazing Grace", words by John Newton, 1779): two verses, hyphens, melismas, a pickup |
| `clarinet_changes` | `MuseScoreFixtures.clarinet_changes`, at concert pitch | A B-flat clarinet that changes to an A clarinet, then a flute |
| `clarinet_changes_transposed` | the same, through a transposed layout | Written pitch, three written keys, and `<transpose>` changing twice and then resetting |

### What MuseScore changes

In every file, MuseScore adds:

- `<defaults>`, `<credit>` and `<print>` layout;
- `<encoding-date>`, with `MuseScore Studio 4.7.5` as the software;
- `width` and `default-x`/`default-y` attributes;
- a `<midi-instrument>` for each part;
- `<stem>` on every note;
- `<voice>1</voice>` on the notes of a one-voice part, where the gem writes none.

It also re-indents closing tags. `<divisions>`, pitches, durations, ties, grace notes, tuplets, lyrics, clefs, keys, meters, endings, repeats, and barline styles come through unchanged, except as listed below:

- **A part without a sound:** it gets a `keyboard.piano.grand` `<instrument-sound>` and a `<score-instrument>`. In `clef_changes` this means the instrumentless tenor part, and in `barline_styles` and `key_and_meter_change` both parts.
- **C major:** MuseScore drops `<mode>major</mode>` from a key of no sharps or flats. It keeps the mode of every other key.
- **Dynamics:** every level gets a `<sound dynamics="…"/>`. Note dynamics (`sfz`, `fp`), which the gem writes in the note's `<notations>`, become `<direction>` dynamics before the note.
- **Navigation:** MuseScore drops every navigation `<sound>` attribute (`segno`, `coda`, `tocoda`, `dalsegno`, `dacapo`, `fine`). The `<segno/>` and `<coda/>` symbols become `<words>` in the Leland Text font holding the SMuFL glyphs U+E047 and U+E048. "To Coda", "D.S. al Coda", "Fine", "D.C." and "D.C. al Fine" stay as words.
- **Hairpins:** a wedge the gem stops on a downbeat comes back as a stop after the last note of the bar before (`marked_dal_segno_al_coda` bar 1, `marked_da_capo_al_fine` bars 4 and 6). That is the same moment, written at the end of the earlier bar.
- **Grand staff:** in `cross_staff_piano` and `piano_part_marks`, MuseScore adds a hidden whole-measure rest (`print-object="no"`) in voice 5 on staff 2 to every bar, because the left hand is the only voice there and it crosses. In `bach_invention_01` the left hand, voice 2, is renumbered voice 5, MuseScore's first voice on a second staff, and `<accidental>` is added wherever an accidental prints.
- **Direction ownership (`piano_part_marks`):** MuseScore drops `<voice>` from every direction and gives every direction `<staff>1</staff>`. As a result, the right hand's own mf and crescendo can no longer be told apart from the piano's part dynamics and hairpins.
- **Direction placement (`piano_part_marks`):** a direction in the middle of a held note, which the gem writes before the note with `<offset>2</offset>`, comes back after the note (or after the bar's `<backup>` and the left hand) with `<offset>-2</offset>`. The moment is the same. The right hand's crescendo stop moves from bar 3's downbeat to the end of bar 2, and it now comes before its own start in document order: stop number 2 is written at the end of bar 2, and then the crescendo number 2 starts at offset -2.
- **Grace notes:** sixteenth-note grace notes get `<beam>`s.
- **Transposition (`clarinet_changes_transposed`):** MuseScore keeps the written pitches and all three written keys, but only the first `<transpose>` (B-flat, -1/-2). The A clarinet's -2/-3 and the flute's reset to 0/0 are dropped, so read at concert pitch, bars 3-4 sound a semitone high and bars 5-6 a tone low. The gem writes no `<instrument-change>` in either rendering.

`spec/fixtures/notation/lily_pond/tuplets_and_grace_notes.ly` was tried and left out. Its one-note tuplet groups (`\tuplet 3/2 { c4 }`) come back from MuseScore padded with tuplet rests, which overfills bars 1 and 3 (945 and 1050 divisions in an 840-division bar). That changes the music rather than its encoding.

## Timewise conversions

`speed_the_plough.timewise.musicxml` and `key_and_meter_change.timewise.musicxml` are the head_music renders converted to `<score-timewise>` with the XSLT that ships with Dorico 6. The rake task runs:

```bash
xsltproc --nonet --novalid "/Applications/Dorico 6.app/Contents/Resources/musicxml/parttime.xsl" <name>.head_music.musicxml > <name>.timewise.musicxml
```

## LilyPond MusicXML test suite

`lilypond_test_suite/` holds 14 files copied unchanged, trailing whitespace included, from the LilyPond MusicXML test suite as distributed with music21. The local copy is `~/github.com/cuthbertLab/music21/music21/musicxml/lilypondTestSuite/`, forked from the suite at <https://github.com/cuthbertLab/musicxmlTestSuite>, which in turn comes from <http://lilypond.org/doc/v2.18/input/regression/musicxml/collated-files>. music21 states that the suite "is licensed under the MIT license ... and copyrighted by the Lilypond project". The suite ships no license file, so `lilypond_test_suite/LICENSE` gives the MIT text with that attribution.

- 31a Directions
- 32a Notations
- 33c Spanners: slurs
- 41g Part with no id
- 42b Multiple voices with a mid-measure clef change
- 45b Repeat with alternatives
- 45c Repeat multiple times
- 46a Barlines
- 46c Mid-measure clef
- 61a Lyrics
- 61b Multiple lyrics
- 61g Lyrics with name and number
- 61j Lyric elisions
- 99a Sibelius 5 export, ignoring beaming: the other-scorewriter fixture
