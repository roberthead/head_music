# Extract Staff Schemes to NotationStyle

AS a developer

I WANT staff schemes and notation conventions to live in a NotationStyle model

SO THAT notation concerns are separated from instrument definition and can vary independently

## Background

The current architecture embeds staff schemes (clefs, transposition conventions, number of staves) within instrument variants. This conflates two independent concerns:

1. **What the instrument is** - Its pitch, range, family, physical characteristics
2. **How it's notated** - Which clefs, transposed or concert pitch, regional conventions

These concerns are orthogonal. A French horn is the same instrument whether notated in treble clef (transposed) or bass clef (concert pitch). A euphonium in a British brass band uses treble clef transposed notation, while the same instrument in an orchestra uses bass clef at concert pitch. The notation choice depends on the **tradition or context**, not the instrument itself.

## Current State

Staff schemes are nested under variants in `instruments.yml`:

```yaml
french_horn:
  family_key: horn
  variants:
    default:
      pitch_designation: F
      staff_schemes:
        bass_clef:
          - clef: bass_clef
            sounding_transposition: 5
        default:
          - clef: treble_clef
            sounding_transposition: -7

euphonium:
  family_key: tuba
  variants:
    british_band:
      staff_schemes:
        default:
          - clef: treble_clef
            sounding_transposition: -14
    default:
      staff_schemes:
        default:
          - clef: bass_clef
            sounding_transposition: 0
```

Problems with current approach:
- Euphonium has two "variants" that are really notation conventions, not different instruments
- Adding a new notation style requires modifying every instrument's variant data
- Staff scheme choices are duplicated across variants that share the same options
- Sounding transposition (a notation concern) is mixed with pitch designation (an instrument property)

## Proposed State

Extract notation concerns to a separate NotationStyle model:

```yaml
# instruments.yml - now purely about the instrument
euphonium:
  family_key: tuba
  # No variants needed - there's only one euphonium

french_horn:
  family_key: horn
  default_pitched_variant: f
  pitched_variants:
    f:
      pitch_designation: F
```

```yaml
# notation_styles.yml - notation conventions by tradition
orchestral:
  name: "Orchestral"
  instrument_notations:
    french_horn:
      clef: treble
      transposition: written  # written pitch, not concert
    euphonium:
      clef: bass
      transposition: concert
    clarinet:
      clef: treble
      transposition: written

british_brass_band:
  name: "British Brass Band"
  instrument_notations:
    euphonium:
      clef: treble
      transposition: written
    tuba:
      clef: treble
      transposition: written

concert_pitch:
  name: "Concert Pitch Score"
  default_transposition: concert
  instrument_notations:
    french_horn:
      clef: bass
```

## User Stories

**STORY 1: Create NotationStyle class**

AS a developer
WHEN I need to specify how instruments should be notated
I WANT to use a NotationStyle object
SO THAT notation conventions are explicit and reusable

**STORY 2: NotationStyle defines instrument notation**

AS a developer
WHEN I have a NotationStyle and an Instrument
I WANT to query the appropriate clef and transposition convention
SO THAT I can notate the instrument correctly for that tradition

**STORY 3: Remove notation from Variant**

AS a developer
WHEN I define an instrument's pitched variants
I WANT to specify only pitch-related properties
SO THAT variants are purely about the instrument, not its notation

**STORY 4: Remove euphonium "variants"**

AS a developer
WHEN I look up a euphonium
I WANT a single instrument definition
SO THAT the british_band vs orchestral distinction is handled by NotationStyle

**STORY 5: InstrumentConfiguration uses NotationStyle**

AS a developer
WHEN I create an InstrumentConfiguration for a score
I WANT to specify the notation style
SO THAT the configuration knows how to notate the instrument

## Implementation Notes

1. Create `HeadMusic::Notation::NotationStyle` class
2. Create `notation_styles.yml` with common traditions (orchestral, british_brass_band, concert_pitch)
3. NotationStyle provides defaults that instruments can inherit
4. Sounding transposition is calculated from:
   - The instrument's pitch designation (e.g., Bb = -2 semitones from C)
   - The notation style's transposition convention (written vs concert)
   - The clef's octave displacement if any
5. Migration path: keep backward compatibility while new system is built

## Acceptance Criteria

- [ ] `HeadMusic::Notation::NotationStyle` class exists
- [ ] `notation_styles.yml` defines common notation traditions
- [ ] `NotationStyle.get(:orchestral)` returns appropriate style
- [ ] `notation_style.notation_for(instrument)` returns clef and transposition info
- [ ] Euphonium no longer has multiple variants
- [ ] Staff schemes removed from pitched variants
- [ ] `InstrumentConfiguration` accepts optional notation_style parameter
- [ ] All existing tests pass (with appropriate updates)
- [ ] New tests cover notation style functionality
- [ ] Maintains 90%+ test coverage

## Open Questions

1. **Percussion mappings** - Are drum kit staff mappings (bass drum on space 1, snare on line 3) part of NotationStyle or intrinsic to the instrument? Different publishers use different mappings, suggesting it's a notation concern.

2. **Grand staff instruments** - Piano always uses grand staff. Is this intrinsic to the instrument or still a notation choice? Perhaps instruments can declare a "minimum staff structure" that notation styles must respect.

3. **Default notation style** - What's the default if none is specified? Probably "orchestral" for most use cases.
