<!--
metadata:
  created_at:   2026-11-12T14:15:46-05:00
  activated_at: 2026-11-12T22:13:11-05:00
  planned_at:   2026-11-12T22:35:45-05:00
  finished_at:
  updated_at:   2026-11-13T08:12:28-05:00
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
- When no name resolves and the file's first `<transpose>` disagrees with the
  sound's instrument, the reader picks among that instrument and its catalog
  variants (`parent_key`) by sounding transposition. For example,
  `wind.reed.clarinet` with an A transposition reads as clarinet in A.
- The reader normalizes the instrument names other programs write before the
  catalog lookup: a leading key moves to the end ("C Clarinet" → clarinet in
  C), "b" and "#" after a key letter become ♭ and ♯ ("Trumpet in Bb"), and a
  trailing player number or numeral goes ("Violin 1", "Horn II"). A name
  whose key is the instrument's own resolves to that instrument ("Trumpet in
  B♭" → trumpet, "Horn in F" → French horn).
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
      a new `InstrumentNames` helper (`music_xml/instrument_names.rb`), which
      tries `Instrument.get` on the name as written, then on its normalized
      form:
      - strip a trailing player number or Roman numeral ("Violin 1",
        "Horn II");
      - move a leading key to the end ("C Clarinet", "Eb Trumpet" →
        "Clarinet in C", "Trumpet in E♭");
      - turn "b" or "#" after a key letter into ♭ or ♯ ("in Bb" → "in B♭");
      - when "X in K" still fails, try "X" and keep it only if its
        `pitch_key` is K ("Trumpet in B♭" → trumpet, "Horn in F" → French
        horn, but not "Trumpet in G" → trumpet).
   3. Resolve the sound through `InstrumentSounds.instrument`.
   4. Pick: the first resolved name that agrees with the sound, then the
      sound, then the first resolved name when there is no sound. A name
      agrees with the sound when they share a `family_key`. So "Irish tenor
      banjo" with `pluck.banjo.tenor` reads as irish_tenor_banjo, while a
      part named "Soprano" with `wind.reed.saxophone.soprano` reads as the
      saxophone, not the voice.
   5. When the sound decided it and the part's first `<transpose>` is
      present but disagrees with that instrument's `sounding_transposition`
      (chromatic plus 12 × octave-change), pick among the instrument and the
      catalog instruments whose `parent_key` is it, by that transposition.
      `wind.reed.clarinet` with chromatic -3 reads as clarinet_in_a; with no
      match it stays clarinet. An absent `<transpose>` leaves the sound's
      instrument alone, since a concert-pitch file carries none for any
      instrument. Find where `PartStaves` reads `<transpose>`
      (`part_staves.rb:21`) and share that reading rather than parse it twice.
   6. Nothing resolves: nil, as now.
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
- `identity_reader_spec.rb`, transposition: `wind.reed.clarinet` with
  chromatic -3 reads as clarinet_in_a, with no `<transpose>` as clarinet, and
  with a transposition no variant has as clarinet.
- `instrument_names_spec.rb`: "C Clarinet", "Eb Trumpet", "Trumpet in Bb",
  "Clarinet in B♭", "Horn in F", "Violin 1", "Horn II", a name that is
  already a catalog name, "Trumpet in G" (nil), and a non-name ("SmartMusic
  SoftSynth", nil).
- A round-trip spec over `Instrument.all`, concert and `transposed: true`:
  same `name_key` and `sounding_transposition` for all 135.
- Writer spec: an instrument without a sound writes `<score-instrument>` with
  a name and no `<instrument-sound>`; the schema spec
  (`writer_schema_spec.rb`) still validates.

### Risks and open questions

- A file whose `<part-name>` happens to be an instrument name in the same
  family as the sound, but meant as a player label, now reads as that named
  instrument. The family check limits this.
- The normalizer handles English only. A German "B-Klarinette" or Italian
  "Clarinetto in Do" resolves only if the catalog's translations already
  carry that form.
- Stripping a trailing numeral could turn a real name into another ("Violin
  II" is fine, but check that no catalog name ends in a number or numeral).
- Finale's `<instrument-name>` is often a playback device; the family check
  drops it when it names an instrument (e.g. "Grand Piano") against a
  different sound, but a wrong Finale sound still wins over a right
  part-name.
- ~~Writing the name in the current locale means a German export names the
  instrument in German.~~ Not so: `Named#name` defaults to en_US, so
  `<instrument-name>` is English in every locale (review finding 4).
- Existing documents change: every part with a sound-less instrument now gets
  a `<score-instrument>`, and the 8 parent-sound instruments gain a sound.

### Implementation notes

- **Names count only within a `<score-instrument>`.** head_music writes a
  part with no instrument under its voice's role, so its own
  `barline_styles` fixture has a part named "Bass" and no instrument. Read
  by part name, it came back as the bass voice. The writer now writes a
  `<score-instrument>` for every instrument, so a part without one has none.
- **`drum.tom-tom` belongs to no instrument**, so the written-sound table is
  `shared_instrument_sounds.yml`: a sound another instrument owns, or none
  does.
- **`Instrument.all` was fixed on the way** (its own commit). It listed every
  cached instance, so the name lookups in the new specs added duplicates and
  instruments with no `name_key` to it.
- **Fixture baseline:** all 51 parts in the 44 MusicXML fixtures read the same
  instrument before and after.
- **Schema:** documents with a sound-less, a shared-sound, and a transposed
  instrument validate against the MusicXML 4.0 XSD, as does
  `writer_schema_spec.rb` with `MUSICXML_XSD` set.

## Review

2026-11-13, at `aa0478f5`. An independent agent read the branch, and each finding
below was reproduced before being recorded.

| Criterion | Verdict | Evidence |
|---|---|---|
| Every catalog instrument round-trips | ✅ | `shared_instrument_sounds.yml`, `writer.rb:97-108`; `identity_reader_spec.rb:181-197` (all 135, concert and transposed) |
| Standard sounds still written and read | ✅ | `writer.rb:101,104`; `writer_spec.rb:2115-2133` |
| Stated order of preference | ✅ | `identity_reader.rb:50-71`; `identity_reader_spec.rb:106-136`; CHANGELOG |
| Nothing resolves: no instrument, no raise | ✅ | `identity_reader_spec.rb:138-144` |
| Disagreement rule pinned | ✅ | `identity_reader_spec.rb:106-112` (Irish tenor banjo, Soprano) |
| Transposition picks a variant | ✅ | `identity_reader.rb:77-92`; `identity_reader_spec.rb:146-158` |
| Names in other programs' forms | ⚠️ | `instrument_names_spec.rb` covers every example in the criterion; see finding 2 |
| CHANGELOG | ✅ | All 44 fixtures read the same instruments on main and on the branch |

### Findings

1. **A key-less name overrides `<transpose>`** (medium). The variant pick
   runs only when no name resolves, so part-name "Trumpet" with
   `brass.trumpet` and a +3 transposition reads as `trumpet`, not
   `trumpet_in_e_flat`; "Clarinet" with -3 reads as `clarinet`, not
   `clarinet_in_a`. This matches the criterion's wording, but MuseScore
   reapplies `<transpose>` in this case. Fix: also pick by transposition when
   the winning name is the sound's own instrument.
2. **Normalizer gaps** (low).
   - "English Horn in F", "Cor anglais in F", and "Oboe d'amore in A" read as
     nil, because `in_own_key` compares the key with `pitch_key`, which
     `cor_anglais` and `oboe_d_amore` lack. Comparing with
     `sounding_transposition` would cover them.
   - "Trumpet in B-flat" and "B flat" read as nil.
   - No false matches were found.
3. **An unmapped sound skips the family check** (low). Part-name "Soprano"
   with `wind.reed.saxophone`, which is not in the table, reads as
   `soprano_voice`.
4. **The German round-trip spec tests English** (low). `Named#name` defaults
   to en_US, so `<instrument-name>` is always English whatever the locale.
   The spec at `identity_reader_spec.rb:199-202` passes on English input, and
   the plan's locale risk does not apply. Retitle or drop the spec, and the
   plan's risk.
5. **The name cache grows with every name read** (low, predates the branch).
   `get_by_name` caches an instance for each name looked up, valid or not,
   and the reader now looks up every part and instrument name a file carries.
6. **Transposition is read narrowly** (low). Only staff 1 or an unnumbered
   `<transpose>` in measure 1's first `<attributes>` counts.
7. **Comment length** (minor). The comment on `IdentityReader#instrument` runs
   six lines.

Nothing blocks `finish`. Findings 1 and 4 are worth fixing first.
