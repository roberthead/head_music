<!--
metadata:
  created_at:
  activated_at: 2026-07-05T10:26:49-07:00
  planned_at:
  finished_at:
  updated_at:   2026-07-05T10:50:05-07:00
-->

# Extract Staff Schemes to NotationStyle

AS a developer

I WANT staff schemes and notation conventions to live in a NotationStyle model

SO THAT notation concerns are separated from instrument definition and can vary independently

## Background

The current architecture embeds staff schemes (clefs, sounding transpositions, number of staves) directly in each instrument definition. This conflates two independent concerns:

1. **What the instrument is** — its pitch, range, family, physical characteristics
2. **How it's notated** — which clefs, transposed or concert pitch, regional conventions

These concerns are orthogonal. A French horn is the same instrument whether notated in treble clef (transposed) or bass clef (concert pitch). A euphonium in a British brass band uses treble-clef transposed notation, while the same instrument in an orchestra uses bass clef at concert pitch. The notation choice depends on the **tradition or context**, not the instrument itself.

`lib/head_music/instruments/instrument.rb` already flags this: its `staff_schemes` accessor carries the comment *"notation schemes (to be moved to NotationStyle later)."* This story does that move.

## Current State

Each instrument in `instruments.yml` carries a `staff_schemes` map. The `default` scheme is the everyday notation; additional named schemes encode alternative traditions:

```yaml
euphonium:
  family_key: tuba
  range_categories:
  - baritone
  staff_schemes:
    default:
    - clef: bass_clef
      sounding_transposition: 0
    british_band_default:      # this is a *tradition*, not a different instrument
    - clef: treble_clef
      sounding_transposition: -14

french_horn:
  family_key: horn
  pitch_key: f
  staff_schemes:
    default:
    - clef: treble_clef
      sounding_transposition: -7
    bass_clef:                 # concert-pitch alternative, again a notation choice
    - clef: bass_clef
      sounding_transposition: 5
```

(The `Variant` class and `Instrument#variants` are currently backward-compat shims — the YAML has no `variants:` key. Named `staff_schemes` are the real carriers of the notation conflation.)

Problems with the current approach:

- Named schemes like `british_band_default` and `bass_clef` describe **notation traditions**, yet they live inside the instrument as if they were properties of the instrument.
- Adding a new tradition (say, a concert-pitch score) means editing many instruments' scheme maps.
- The same scheme choice is duplicated across every instrument that shares it.
- `sounding_transposition` (a notation concern) is stored alongside `pitch_key` (an instrument property).

## Proposed State

Instrument definitions keep only what the instrument *is*. Notation conventions move into named notation styles, keyed by tradition.

```yaml
# instruments.yml — purely about the instrument
euphonium:
  family_key: tuba
  range_categories:
  - baritone
  # no staff_schemes — only one euphonium

french_horn:
  family_key: horn
  pitch_key: f
  # no staff_schemes
```

```yaml
# notation_styles.yml — notation conventions by tradition
#
# `default` is the fallback style and lists EVERY instrument. Named styles are
# sparse OVERLAYS: they list only the instruments whose notation differs, and
# any instrument they don't mention falls back to `default`.

default:
  name: "Default"
  instrument_notations:
    euphonium:
      clef: bass_clef
      sounding_transposition: 0
    french_horn:
      clef: treble_clef
      sounding_transposition: -7
    piano:                       # grand-staff structure lives in the default style
      staves:
      - clef: treble_clef
      - clef: bass_clef
    # ... every instrument appears here

british_brass_band:
  name: "British Brass Band"
  instrument_notations:          # overlay: only the differences
    euphonium:
      clef: treble_clef
      sounding_transposition: -14
    tuba:
      clef: treble_clef
      sounding_transposition: -14

concert_pitch:
  name: "Concert Pitch Score"
  instrument_notations:          # overlay: only the differences
    french_horn:
      clef: bass_clef
      sounding_transposition: 5
```

### Resolution model

Looking up an instrument's notation in a style resolves as an **overlay on `default`**:

1. If the named style lists the instrument, use its notation.
2. Otherwise, fall back to the instrument's entry in the `default` style.

So `british_brass_band.notation_for(:trombone)` yields the trombone's `default` notation (brass bands and orchestras notate trombone the same way), while `british_brass_band.notation_for(:euphonium)` yields the treble-clef, −14 override.

### Grand-staff and multi-staff instruments

Staff structure (how many staves, and each staff's clef) is a notation-style concern and lives in `default`. Piano's two-staff treble/bass layout is defined in the `default` style's `piano` entry, alongside single-staff instruments' single clef. A named style may override it, but in practice most inherit the default structure.

## User Stories

**STORY 1: Create NotationStyle class**

AS a developer
WHEN I need to specify how instruments should be notated
I WANT to use a NotationStyle object loaded from `notation_styles.yml`
SO THAT notation conventions are explicit, named, and reusable

**STORY 2: NotationStyle resolves an instrument's notation (overlay on default)**

AS a developer
WHEN I have a NotationStyle and an Instrument
I WANT to query the clef, sounding transposition, and staff structure, falling back to the `default` style when the named style doesn't override the instrument
SO THAT I can notate the instrument correctly for that tradition without repeating shared conventions

**STORY 3: Remove staff_schemes from instrument definitions**

AS a developer
WHEN I read an instrument definition
I WANT it to contain only instrument facts (family, pitch, range), with no `staff_schemes`
SO THAT the instrument model is purely about the instrument, not its notation

**STORY 4: Collapse euphonium's duplicate scheme**

AS a developer
WHEN I look up a euphonium
I WANT a single instrument definition, with its brass-band notation living in the `british_brass_band` style
SO THAT the orchestral-vs-brass-band distinction is a notation choice, not two instrument entries

**STORY 5: Instrument is notated through a NotationStyle**

AS a developer
WHEN I place an instrument in a score
I WANT to specify (or default) the notation style that governs its clef, transposition, and staves
SO THAT the configuration knows how to notate the instrument

## Implementation Notes

1. Create `HeadMusic::Notation::NotationStyle`, loaded from a new `notation_styles.yml`, with a `.get(key)` factory (e.g. `NotationStyle.get(:orchestral)`), following the gem's existing `Named` / `.get` conventions.
2. `notation_style.notation_for(instrument)` returns the resolved notation (clef, sounding transposition, staves), applying the overlay-on-`default` rule from the Resolution model above.
3. Seed `notation_styles.yml` by migrating every instrument's current `default` staff scheme into the `default` notation style, and each named scheme (e.g. `british_band_default`, french horn `bass_clef`) into the appropriate named style as a sparse overlay.
4. `default` is the fallback when no style is specified.
5. Sounding transposition for a notation context derives from the instrument's pitch (e.g. F horn) and the style's convention (written vs concert), plus any clef octave displacement — preserve the numbers currently encoded in `sounding_transposition`.
6. Provide a way to notate an instrument through a chosen style (e.g. `instrument.with_notation_style(style)` or an equivalent parameter where instruments are placed), defaulting to `default`.
7. Keep `Instrument#staff_schemes` (and the `Variant` shim) working during migration for backward compatibility; remove or deprecate once callers move to NotationStyle.

## Acceptance Criteria

- [ ] `HeadMusic::Notation::NotationStyle` class exists with a `.get` factory
- [ ] `notation_styles.yml` defines a `default` style plus common traditions (`british_brass_band`, `concert_pitch`, orchestral)
- [ ] The `default` style contains an entry for every instrument
- [ ] Named styles are sparse overlays — they list only overriding instruments
- [ ] `notation_style.notation_for(instrument)` returns clef, sounding transposition, and staves, falling back to `default` for instruments the style doesn't override
- [ ] Grand-staff / multi-staff structure (e.g. piano) is defined in the `default` style
- [ ] Instrument definitions no longer carry `staff_schemes` (or they are clearly deprecated during migration)
- [ ] Euphonium is a single instrument; its brass-band notation lives in `british_brass_band`
- [ ] An instrument can be notated through a chosen notation style, defaulting to `default`
- [ ] All existing tests pass (with appropriate updates)
- [ ] New tests cover style lookup, overlay resolution, default fallback, and grand-staff structure
- [ ] Maintains 90%+ test coverage

## Resolved Decisions

- **Named-style resolution** — Named styles are **sparse overlays on `default`**. A style lists only the instruments whose notation differs; unlisted instruments fall back to the `default` style.
- **Default style** — There is a `default` notation style that lists **every** instrument. It is the fallback when no style is specified. (This supersedes the earlier idea of "orchestral" being the default.)
- **Grand-staff instruments** — Staff structure is defined **in the `default` notation style**, not declared on the instrument. Piano's grand staff is a notation-style concern like any other.
- **Self-contained** — NotationStyle is described on its own terms. There is no dependency on a separate overlay-architecture story (the previously referenced `000-overlay-architecture.md` does not exist).

## Out of Scope / Follow-ups

- **Percussion staff mappings** — Drum-kit and percussion staff mappings (e.g. bass drum on space 1, snare on line 3) **are** a notation concern and ultimately belong in NotationStyle, since publishers differ. Migrating them is deferred to its own follow-up story; this story focuses on clef, sounding transposition, and staff structure for pitched instruments.
- **Multi-key pitched variants** — Instruments that come in several keys (e.g. clarinet in B♭/A/E♭) are an instrument-model concern distinct from notation and are out of scope here.
