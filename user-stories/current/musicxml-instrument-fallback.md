<!--
metadata:
  created_at:   2026-11-12T14:15:46-05:00
  activated_at: 2026-11-12T22:13:11-05:00
  planned_at:   2026-11-12T22:35:45-05:00
  finished_at:
  updated_at:   2026-11-12T22:35:45-05:00
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

### Research (2026-11-12)

How other tools identify an instrument, from their source and real exports:

- **MusicXML 4.0** says `<instrument-sound>` names a default timbre, not an
  instrument, and sets no precedence among `<instrument-sound>`,
  `<instrument-name>`, `<virtual-instrument>`, and `<part-name>`. A proposal to
  give sounds.xml parent and fallback entries was declined (w3c-cg/musicxml
  #364).
- **MuseScore** exports a coarse sound (`wind.reed.clarinet` for clarinet in C,
  `brass.trumpet` for E♭ trumpet, `pluck.banjo.tenor` for Irish tenor banjo)
  and carries the specific instrument in `<instrument-name>`, `<part-name>`,
  and `<transpose>`. Its importer scores templates by weight: track name 128,
  long name 64, sound ID 32 ("Not unique"), short name 16, MIDI program 8,
  then key trait, transposition, octave (`instrtemplate.cpp`,
  `combinedTemplateSearch`). The name beats the sound, and the file's
  `<transpose>` is reapplied. For Finale files it takes `<part-name>` instead
  of `<instrument-name>`.
- **Dorico 6.2** maps each instrument to a coarse sound in its bundled
  `instruments.xml` (clarinet in C → `wind.reed.clarinet`; E♭, E, F trumpets →
  `brass.trumpet`; every tom → `drum.tom-tom`). Its importer uses "a
  combination of the name of the part … and the sound ID" (Steinberg forum);
  precedence unverified.
- **Sibelius** writes generic sounds even where a specific one exists
  ("Trumpet in Bb" with `brass.trumpet`). **Finale** often writes a playback
  device as `<instrument-name>` ("SmartMusic SoftSynth", "Grand Piano") and
  wrong sounds; only `<part-name>` is reliable.
- **LilyPond** has no machine-readable identity: `instrumentName` is printed
  text, `midiInstrument` a GM name. **MEI** recommends a MARC or IAML code on
  `<perfRes>` in the header; `<instrDef>` is for MIDI. **kern** has 223 `*I`
  codes with no tenor banjo, ukulele sizes, or keyed clarinets and trumpets.
  **ABC** and **MNX** carry no instrument identity.

In head_music, a round trip of all 135 instruments: MEI 135, MusicXML 112,
MIDI 111, kern 7, LilyPond 0, ABC 0. LilyPond raises on its own transposed
output (story `lilypond-transposition-round-trip`).

Of the 23 instruments without a sound, two have an unclaimed standard ID
(soprillo `wind.reed.saxophone.sopranissimo`, maracas `rattle.maraca`). Irish
tenor banjo and hackbrett have IDs already claimed by tenor_banjo and
hammered_dulcimer. The rest have only a generic family ID, already claimed by
the general instrument (`wind.reed.clarinet` by clarinet), or none.

## Implementation Plan

Follow the other tools: write a `<score-instrument>` for every instrument,
with its name and the nearest standard sound, and read an instrument by name
first, with the sound as the check on the name. MEI's
`IdentityReader#instrument_of` (a label through `Instrument.get`, then a
coarser fallback) is the closest pattern.

### Steps

1. **Record the baseline.** Read every fixture under
   `spec/fixtures/notation/music_xml/` (44 files, including the LilyPond test
   suite) and note each part's instrument, so the change in reading can be
   listed in the CHANGELOG.
2. **Sounds the writer may use** (`lib/head_music/notation/music_xml/instrument_sounds.yml`
   and `instrument_sounds.rb`).
   - Map the two unclaimed standard IDs: `wind.reed.saxophone.sopranissimo` →
     soprillo, `rattle.maraca` → maracas.
   - Add a written-sound table for instruments that share an ID another
     instrument owns, listing what the writer emits for each:
     clarinet_in_c → `wind.reed.clarinet`, trumpet_in_e_flat →
     `brass.trumpet`, bass_trumpet_in_c and _in_e_flat →
     `brass.trumpet.bass`, bass_tuba_in_e_flat → `brass.tuba.bass`,
     tuba_in_c → `brass.tuba`, bugle_in_b_flat and _in_c → `brass.bugle`,
     irish_tenor_banjo → `pluck.banjo.tenor`, hackbrett →
     `pitched-percussion.hammer-dulcimer`, the four ukuleles →
     `pluck.ukulele`, the three toms → `drum.tom-tom`, cymbal →
     `metal.cymbal.crash`, the two big recorders →
     `wind.flutes.recorder.contrabass`. These follow MuseScore and Dorico
     where they agree. Synthesizer has no fitting ID and gets none.
   - `InstrumentSounds.sound` checks its own table, then the written-sound
     table. `InstrumentSounds.instrument` (sound → instrument) is unchanged,
     so `wind.reed.clarinet` alone still reads as clarinet.
3. **Writer** (`lib/head_music/notation/music_xml/writer.rb`,
   `score_instrument_lines`): write `<score-instrument>` with
   `<instrument-name>` for every part with an instrument, and
   `<instrument-sound>` only when there is one. `<instrument-name>` is the
   instrument's name in the current locale, as now.
4. **Reader** (`lib/head_music/notation/music_xml/identity_reader.rb`,
   `#instrument`), in order:
   1. Read the candidates: the first `<score-instrument>`'s
      `<instrument-name>` and `<instrument-sound>`, its
      `<virtual-instrument>`'s `<virtual-name>`, and the `<score-part>`'s
      `<part-name>`.
   2. Resolve each name (instrument-name, part-name, virtual-name) through
      `Instrument.get`, which takes keys, translated names, and aliases.
   3. Resolve the sound through `InstrumentSounds.instrument`.
   4. Pick: the first resolved name that agrees with the sound, then the
      sound, then the first resolved name when there is no sound. A name
      agrees with the sound when they share a `family_key`. So "Irish tenor
      banjo" with `pluck.banjo.tenor` reads as irish_tenor_banjo, while a
      part named "Soprano" with `wind.reed.saxophone.soprano` reads as the
      saxophone, not the voice.
   5. Nothing resolves: nil, as now.
5. **Docs.** Update the comments on `score_instrument_lines` and
   `InstrumentSounds`, and the CHANGELOG's Unreleased banjo entry, which
   says the Irish tenor banjo reads back with no instrument.
6. **CHANGELOG** under Unreleased, Changed: what is written and read now, and
   the fixtures whose parts read differently (from step 1).

### Data model changes

None. One new YAML section, or file, for the written sounds.

### Tests

- `instrument_sounds_spec.rb`:
  - every catalog instrument but synthesizer has a written sound;
  - every written sound is a W3C ID (checked against the IDs already in the
    table plus the new ones);
  - replace "writes no sound for the Irish tenor banjo" with what it now
    writes.
- `identity_reader_spec.rb`, one example each:
  - name with a matching sound;
  - name only;
  - sound only;
  - part-name only;
  - name in another family than the sound (the sound wins);
  - translated name;
  - nothing resolves (nil, no raise).
  The pinned rule for a disagreement is the "Irish tenor banjo" with
  `pluck.banjo.tenor` case and the "Soprano" with a saxophone sound case.
- A round-trip spec over `Instrument.all`, concert and `transposed: true`:
  same `name_key` and `sounding_transposition` for all 135.
- Writer spec: an instrument without a sound writes `<score-instrument>` with
  a name and no `<instrument-sound>`; the schema spec
  (`writer_schema_spec.rb`) still validates.

### Risks and open questions

- A file whose `<part-name>` happens to be an instrument name in the same
  family as the sound, but meant as a player label, now reads as that named
  instrument. The family check limits this.
- MuseScore's "C Clarinet" and Sibelius's "Trumpet in Bb" don't resolve by
  name, so they read as clarinet and trumpet, as today.
- Finale's `<instrument-name>` is often a playback device; the family check
  drops it when it names an instrument (e.g. "Grand Piano") against a
  different sound, but a wrong Finale sound still wins over a right
  part-name.
- Writing the name in the current locale means a German export names the
  instrument in German. head_music reads it back; other tools may not.
- Existing documents change: every part with a sound-less instrument now gets
  a `<score-instrument>`, and the 8 parent-sound instruments gain a sound.
