# MEI golden documents

Each `<name>.mei` here is head_music's own MEI 5.1 render of a shared fixture, made with `Flow#to_mei` or, for `clarinet_changes_transposed`, `Layout#to_mei` with a transposed layout. The documents embed `HeadMusic::VERSION`, so they are regenerated with each release.

The names and sources live in `spec/support/mei_fixtures.rb` (`MEIFixtures::RENDERS`). Regenerate every document with:

```bash
bundle exec rake mei:golden_fixtures
```

| Name | Source | What it carries |
| --- | --- | --- |
| `fourth_species` | `LilyPondFixtures.fourth_species` | Two voices, ties across barlines, voice roles |
| `satb_chorale` | `spec/fixtures/notation/kern/satb_chorale.krn` | Four parts, a pickup, ties, lyrics |
| `piano_splits` | `spec/fixtures/notation/kern/piano_splits.krn` | A grand staff, a right hand that splits into two layers, part dynamics |
| `articulations_ornaments_dynamics` | `spec/fixtures/notation/kern/articulations_ornaments_dynamics.krn` | Articulations, ornaments, note dynamics, levels, ties |
| `hairpins` | `spec/fixtures/notation/kern/hairpins.krn` | Hairpins |
| `marked_dal_segno_al_coda` | `MuseScoreFixtures.marked_dal_segno_al_coda` | Segno, To Coda, D.S. al Coda, coda, rehearsal marks, markings, a phrase mark, a hairpin ending on the final barline |
| `marked_da_capo_al_fine` | `MuseScoreFixtures.marked_da_capo_al_fine` | Repeats, first and second endings, Fine, D.C. al Fine |
| `piano_part_marks` | `MuseScoreFixtures.piano_part_marks` | A part's dynamics and hairpins beside a voice's |
| `cross_staff_piano` | `LilyPondFixtures.cross_staff_piano` | A left hand crossing to the treble staff and back |
| `triplets` | `TupletFixtures.triplets` | Triplet eighths and quarters |
| `grace_notes_before_downbeat` | `TupletFixtures.grace_notes_before_downbeat` | Slashed, tied, slurred, chorded, and articulated grace notes |
| `two_verses` | `MuseScoreFixtures.two_verses` | Two verses of lyrics, hyphens, melismas, a pickup |
| `clarinet_changes_transposed` | `MuseScoreFixtures.clarinet_changes`, through a transposed layout | Written pitch, three written keys, and `@trans.diat`/`@trans.semi` changing twice and then resetting |

## Validating against the schema

The MEI schema is not committed. Fetch release v5.1 (2025-01-22), asset `MEI_Schemata_v5.1.zip`, from:

```text
https://github.com/music-encoding/music-encoding/releases/download/v5.1/MEI_Schemata_v5.1.zip
```

Its sha256 is `2586509c350d67b16bdeaae8e8e33e626dee615df88d49c87058484bb6334877`. Extract `mei-CMN.rng`, and point `MEI_SCHEMA` at it:

```bash
MEI_SCHEMA=/path/to/mei-CMN.rng bundle exec rspec spec/head_music/notation/mei_schema_spec.rb
```

Ignore the `v6.0-0+featureFreeze` pre-release. A single document validates with:

```bash
xmllint --noout --relaxng /path/to/mei-CMN.rng spec/fixtures/notation/mei/two_verses.mei
```

## MuseScore and Verovio

`spec/head_music/notation/mei_muse_score_spec.rb` converts each document through MuseScore 4 when `MSCORE` is set, or `MUSESCORE_FIXTURES=1` with MuseScore 4 installed. MuseScore Studio 4.7.5 reads MEI only with `meiversion="5.1+basic"`, rejects a bare `<staff/>`, and crashes on a `<label>` inside `<layerDef>`, so the spec rewrites those before converting. It drops `@tie`, numbers an upbeat measure 1, makes a part of each staff in a braced group without a `<label>`, and ignores `@trans.*` on a `<staffDef>` after the opening.

`spec/head_music/notation/mei_verovio_spec.rb` engraves each document when a `verovio` executable is on the `PATH`, and is skipped otherwise.
