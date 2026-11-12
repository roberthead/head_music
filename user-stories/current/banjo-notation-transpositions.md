<!--
metadata:
  created_at:   2026-11-08T08:10:10-08:00
  activated_at: 2026-11-12T10:46:47-05:00
  planned_at:
  finished_at:
  updated_at:   2026-11-12T11:45:39-05:00
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

[to be filled in by /stories plan]
