<!--
metadata:
  created_at:   2026-11-08T08:10:10-08:00
  activated_at: 2026-11-12T10:46:47-05:00
  planned_at:   2026-11-12T11:48:18-05:00
  finished_at:
  updated_at:   2026-11-12T12:04:47-05:00
-->

# Banjo Notation Transpositions

AS a developer rendering or playing back banjo parts

I WANT head_music's banjo notation to reflect the conventions banjo music actually uses

SO THAT a written banjo part sounds at the right octave, whichever tradition it comes from

## Background

The default notation style (`lib/head_music/notation/notation_styles.yml`) writes
the banjo like the guitar: treble clef, `sounding_transposition: -12`. That is one
real convention, but banjo notation isn't settled:

- Some modern method books follow the guitar convention and write the banjo an
  octave above where it sounds.
- A lot of banjo music is written at sounding pitch.
- 19th-century classic-banjo notation had its own habits, including writing for
  a banjo tuned lower than today's open G and reading it as if it were in A,
  which made it a transposing instrument by something other than an octave.
- Bluegrass and old-time players mostly read tab, which has no octave question.

This came up while reviewing bardtheory's dictionary entry for the banjo. That
entry stated "written an octave above where it sounds" and was rewritten to avoid
the disputed claim.

## Acceptance Criteria

- Survey the banjo notation conventions above (and any others found), citing
  sources for each: method books, publishers, and references such as Gould's
  *Behind Bars*.
- Decide which convention the default notation style should use, and record why.
- Decide whether the other conventions deserve their own notation styles (for
  example, an at-pitch style or a classic-banjo style), alongside `german`,
  `italian`, and `british_brass_band`.
- Check that tenor and plectrum banjos, if they are added or already implied,
  get the same treatment.
- Any change to the default banjo transposition has specs covering sounding
  pitch for a written note.

## Notes

- Stringing: `lib/head_music/instruments/stringings.yml` (banjo, open G, G4
  short string).
- Alternate tunings: `lib/head_music/instruments/alternate_tunings.yml`.
- Capo options: `lib/head_music/instruments/instrument_configurations.yml`.

## Research

Gathered 2026-11-12. Items marked *verified* were checked against the source
directly; the rest come from a research agent and should be confirmed before a
spec or a CHANGELOG line rests on them.

### How the gem works today

- `notation_styles.yml` gives `banjo` a treble clef and `sounding_transposition:
  -12` (sounding = written + transposition). The stringing in `stringings.yml`
  (G4 D3 G3 B3 D4) is stated at sounding pitch, so the two agree.
- `Instrument#sounding_transposition` delegates to `StaffProfile`, which always
  resolves the **default** style. That value drives MusicXML `<transpose>`
  (transposed export only, `music_xml/attributes_writer.rb`), MEI transposition
  changes (`mei/timeline_changes.rb`), MIDI `sound_keys`, and
  `Content::Layout::Transposition` for written parts.
- Named styles (`german`, `italian`, `british_brass_band`, `concert_pitch`) are
  sparse overlays reachable only through `Instrument#notation(style:)`. No
  writer, reader, or layout path consumes a non-default style, so a new banjo
  style would be catalog data only unless that changes.
- Readers take transposition from the file (MusicXML `<transpose>`, MEI), not
  from the catalog, so an at-pitch banjo file already imports correctly.
- The catalog has only the 5-string `banjo`: no tenor, Irish tenor, or plectrum
  banjo.

### Banjo notation conventions

- **Treble clef, an octave above sounding, is the settled convention.**
  - Bradbury, *Modern Method for Banjo (Finger Style C Notation)*, 1920s
    (archive.org/details/bradburymodernmethodforbanjo): "though the music is
    written for it in the treble clef the notes actually sound one octave lower
    than written." *Verified.*
  - Joel Hooks, "A Notable Explanation," *ABF 5-Stringer* no. 219, American
    Banjo Fraternity, 2020
    (banjofraternity.org/wp-content/uploads/2023/07/ABF_5_Stringer_219.pdf):
    "Banjo music has always been written on the treble clef staff one octave
    above the frequency that it actually sounds."
  - Andrew Hugill, *Orchestra Manual*
    (andrewhugill.com/OrchestraManual/frets_banjo.html): "A banjo part is
    written an octave higher than sounding."
  - MuseScore `share/instruments/instruments.xml` (main): `banjo`,
    `tenor-banjo`, and `irish-tenor-banjo` all use `G8vb`, with strings at
    sounding pitch (5-string 67 50 55 59 62; tenor 48 55 62 69; Irish tenor
    43 50 57 64). *Verified.*
  - LilyPond's banjo example uses `\clef "treble_8"`.
- **Written at sounding pitch: no source found.** The Background's claim that
  "a lot of banjo music is written at sounding pitch" is unsupported so far.
- **Classic-banjo A notation versus C notation** (Hooks, quoting the primary
  sources):
  - The interval pattern is gCGBD, with the "pitch" named for the 4th (bass)
    string. That string moved from G (c. 1855) through A and B♭ to C (from
    c. 1885), with some players tuning to D (c. 1890–1910).
  - A notation kept printing the music as if in A after players had tuned to C.
    Stewart, 1887: "no Banjo is tuned in the pitch in which its music is
    noted." A written A sounds as C, a minor third up, less an octave: a major
    sixth down, **-9 semitones**, like an A clarinet. That figure is derived;
    no source states it.
  - C notation ("English System," "Universal Notation") is the ordinary
    octave-down transposition.
  - The Guild of Banjoists, Mandolinists and Guitarists adopted C notation on
    26 March 1907, though publishers ignored the ruling. Agnew's *20th Century
    Method* (1901) was the first all-C American method. A notation had faded by
    the early 1920s.
- **Tenor banjo (CGDA):** Mel Bay, *Complete Tenor Banjo Method* (1986):
  "these instruments actually sound an octave lower than written in treble
  clef." **Irish tenor (GDAE):** rests on MuseScore alone. **Plectrum (CGBD):**
  no source found.
- **Tab:** Peghead Nation, *Music Notation Guide*: "Dobro and banjo music has no
  notation, only tab."
- **Not checked:** Gould's *Behind Bars*, Adler, Kennan, Read, Sibelius,
  Dorico's definitions, and the octave notes in the Scruggs, Seeger, Mel Bay
  5-string, and Hal Leonard methods.

### Implications for planning

- Keep `-12` as the default and pin it with specs.
- Drop the at-pitch style unless a source turns up.
- A classic-banjo A-notation style at -9 is the only alternative with
  evidence, but it would be inert data unless named styles start reaching
  output.
- Tenor and Irish tenor banjos at -12 are well supported; plectrum banjo has
  the least support.

## Implementation Plan

Keep the 5-string banjo's default at treble clef, sounding an octave down, and
pin it with specs; the research found no convention that argues for changing it.
Add the tenor and Irish tenor banjos as separate instruments in the banjo family,
following the ukulele family's pattern (`tenor_ukulele` beside `ukulele`). Fix
the banjo's existing alternate tunings, which produce wrong pitches today.

### Steps

1. **Fix the banjo's alternate tunings** (own commit, `Fixed` in CHANGELOG).
   `lib/head_music/instruments/alternate_tunings.yml` applies the offsets in
   stringing course order (g4 D3 G3 B3 D4), but the current values read as if
   written for a different order, so `double_c` produces F4 C3 G3 A3 D4 rather
   than G4 C3 G3 C4 D4. Correct them against LilyPond 2.26's
   `string-tunings-init.ly`:
   - `double_c`: `[0, -2, 0, 1, 0]`, giving gCGCD.
   - `sawmill`: `[0, 0, 0, 1, 0]`, giving gDGCD (LilyPond's `banjo-modal-tuning`).
   - `open_d`: `[-1, 0, -1, -2, 0]`, giving f#DF#AD. This deliberately differs
     from LilyPond's aDF#AD (see Decisions).
   - Add `c_tuning`: `[0, -2, 0, 0, 0]`, giving gCGBD (`banjo-c-tuning`), the
     classic-banjo tuning from the research.

   Fix the YAML header comment too: "first element = lowest course" is wrong for
   the banjo, whose first course is the short G4 string. It should say "first
   element = first course in the stringing".
2. **Pin the default banjo transposition.** No data change.
   - `spec/head_music/content/layout/transposition_spec.rb`: banjo's written D4
     sounds as D3, and sounding G3 is written G4.
   - `spec/head_music/instruments/instrument_spec.rb`: banjo is
     `transposing_at_the_octave?` with treble clef.
3. **Add `tenor_banjo` and `irish_tenor_banjo` as separate instruments**
   (`Added` in CHANGELOG). Each one needs an entry in:
   - `lib/head_music/instruments/instruments.yml`: `family_key: banjo`,
     `gm_program: 106`. The tenor banjo also gets `range_categories: [tenor]`.
   - `lib/head_music/instruments/stringings.yml`: tenor C3 G3 D4 A4; Irish
     tenor G2 D3 A3 E4.
   - `lib/head_music/notation/notation_styles.yml` (default): treble clef,
     `sounding_transposition: -12`.
   - `lib/head_music/notation/music_xml/instrument_sounds.yml`:
     `pluck.banjo.tenor: tenor_banjo`. MusicXML's `sounds.xml` has no Irish
     tenor ID, and each sound names one instrument. Check what the writer does
     for an instrument without a sound and pin that behavior.
   - Locales:

     | Locale | `tenor_banjo` | `irish_tenor_banjo` |
     | --- | --- | --- |
     | en | tenor banjo | Irish tenor banjo |
     | de | Tenorbanjo | irisches Tenorbanjo |
     | es | banjo tenor | banjo tenor irlandés |
     | fr | banjo ténor | banjo ténor irlandais |
     | it | banjo tenore | banjo tenore irlandese |
     | ru | тенор-банджо | ирландское тенор-банджо |

   - `spec/fixtures/notation/legacy_default_notation.json`: add both entries,
     since the equivalence spec requires one per instrument.
4. **Keep the `## Decisions` section current** if implementation changes
   anything recorded there.
5. Run `bundle exec rubocop -a` and `bundle exec rake validate`.

### Data model changes

There are new `tenor_banjo` and `irish_tenor_banjo` catalog entries across the
instrument YAML files, and the banjo tuning data is corrected. There are no
schema or class changes.

### Tests

- `alternate_tuning_spec.rb`: `apply_to` pitches for every banjo tuning, each
  checked against LilyPond's tuning definitions. `open_d` is the exception: it
  deliberately keeps f# where LilyPond has a.
- `stringing_spec.rb`: standard pitches for both new instruments.
- `transposition_spec.rb`: written-to-sounding for all three banjos.
- `instrument_spec.rb`: `Instrument.get("tenor banjo")` and
  `Instrument.get("Irish tenor banjo")` resolve to distinct instruments in the
  banjo family, and both transpose at the octave. Also cover the German name
  lookup.
- MusicXML: `pluck.banjo.tenor` imports as `tenor_banjo`, and an Irish tenor
  banjo part round-trips by its part name, or by whatever the writer does
  without a sound ID.

### Risks and open questions

- **Behavior change.** The `double_c`, `sawmill`, and `open_d` fixes change
  output for anyone already using them. It is a bug fix, but it belongs in
  CHANGELOG under `Fixed` with the old and new pitches.
- **Irish tenor in MusicXML.** It has no MusicXML sound ID, so an Irish tenor
  banjo part may read back as `tenor_banjo` or `banjo` unless its part name
  carries it.
- **Unchecked references.** Gould and the other orchestration references were
  not checked. The default stands on Bradbury, Hooks, Hugill, MuseScore, and
  LilyPond.

## Decisions

Recorded 2026-11-12.

- **Default convention: treble clef, sounding an octave below written (-12),
  unchanged.** Every source found writes the banjo this way: Bradbury, Hooks
  (ABF), Hugill, Mel Bay's tenor method, MuseScore, and LilyPond. No source
  writes it at sounding pitch.
- **No at-pitch style.** No convention to model was found.
- **No classic-banjo A-notation style.**
  - The convention died out by the early 1920s.
  - Its -9 transposition is derived rather than sourced.
  - A named style changes no output today; only `Instrument#notation(style:)`
    can look it up.

  The instrument's classic gCGBD tuning is covered instead by the banjo's new
  `c_tuning` alternate tuning.
- **Tenor and Irish tenor banjos are separate instruments, both at -12.**
  - The Irish tenor banjo has four strings and no drone, is tuned GDAE, and is
    played differently, so it is not just a tuning of another banjo.
  - The tenor banjo's octave-down writing is sourced (Mel Bay, *Complete Tenor
    Banjo Method*). The Irish tenor's rests on MuseScore.
- **No plectrum banjo.** No source was found for its notation, and MuseScore and
  Dorico don't include one.
- **Open D is f#DF#AD**, the common teaching form, rather than LilyPond's aDF#AD.
