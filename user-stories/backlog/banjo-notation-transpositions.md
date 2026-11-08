<!--
metadata:
  created_at:   2026-11-08T08:10:10-08:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-11-08T08:10:10-08:00
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

## Implementation Plan

[to be filled in by /stories plan]
