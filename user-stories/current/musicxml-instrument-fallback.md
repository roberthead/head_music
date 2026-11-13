<!--
metadata:
  created_at:   2026-11-12T14:15:46-05:00
  activated_at: 2026-11-12T22:13:11-05:00
  planned_at:
  finished_at:
  updated_at:   2026-11-12T22:13:11-05:00
-->

# Story: MusicXML Instrument Fallback

## Summary

AS a developer reading and writing MusicXML with head_music
I WANT a part's instrument to survive a round trip even when MusicXML has no standard sound for it
SO THAT a part for an Irish tenor banjo, a clarinet in C, or a trumpet in E♭ reads back as that instrument, with its transposition

## Acceptance Criteria

- Every catalog instrument survives a MusicXML write and read: the part reads
  back with the same instrument (`name_key`), whether or not the instrument
  has a standard `<instrument-sound>` ID.
- An instrument with a standard sound ID still writes and reads it as it does
  today. A more specific identification (such as the instrument's name) may be
  written alongside it, but the sound ID must not be dropped.
- A file from another program resolves an instrument from the identification it
  carries, in a stated order of preference. Candidates are
  `<instrument-sound>`, `<instrument-name>`, `<virtual-instrument>`, and
  `<part-name>`, read through the catalog's name lookup (which includes the
  translations).
- When nothing resolves, the part has no instrument, as now, and reading does
  not raise.
- Where the old and new answers differ (for example a file that says
  `pluck.banjo` but names an Irish tenor banjo), the rule for which one wins
  is decided and pinned in a spec.
- The CHANGELOG notes the change, including any part that used to read as one
  instrument and now reads as another.

## Notes

- Found in the banjo notation story's review (2026-11-12).
- The writer writes `<score-instrument>` only when
  `InstrumentSounds.sound` finds an ID (`lib/head_music/notation/music_xml/writer.rb`,
  `score_instrument_lines`). It writes `<instrument-name>` too, but only
  alongside a sound.
- The reader resolves an instrument only from `<instrument-sound>`
  (`lib/head_music/notation/music_xml/identity_reader.rb`, `#instrument`).
- 23 of 135 instruments have no sound ID today. The ones that transpose are
  in parentheses with their sounding transposition, and those lose it on a
  round trip: baritone_ukulele, bass_trumpet_in_c (-12),
  bass_trumpet_in_e_flat (-9), bass_tuba_in_e_flat, bass_ukulele,
  bugle_in_b_flat (-2), bugle_in_c, clarinet_in_c, concert_ukulele, cymbal,
  floor_tom, hackbrett, high_tom, irish_tenor_banjo (-12), maracas, mid_tom,
  pocket_ukulele, soprillo (10), sub_contrabass_recorder (-12),
  sub_great_bass_recorder, synthesizer, trumpet_in_e_flat (3), tuba_in_c.
- Several share a sound with a more general instrument, such as
  `clarinet_in_c` with `clarinet`, and the sound table maps each ID to only
  one instrument. Writing the general sound and naming the specific instrument
  may be the way through, but first check what MuseScore, Dorico, and Finale
  write for these instruments.
- Check whether MEI, kern, and LilyPond have the same gap. MEI writes the
  `name_key` as a label and is known to round-trip.

## Implementation Plan

[to be filled in by /stories plan]
