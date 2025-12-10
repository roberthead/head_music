# Instrument Modification Model

AS a developer

I WANT to model physical alterations, adjustments, or special configurations made to instruments (such as swapping a leadpipe on a piccolo trumpet to change the key from Bb to A)

SO THAT I can distinguish between different instruments versus adjustments made to a single instrument

## Background

The current Variant model conflates two distinct concepts:

1. **Pitched variants** - Different instruments a player owns separately (e.g., Clarinet in A vs Clarinet in Bb)
2. **Modifications** - Adjustments to a single physical instrument (e.g., piccolo trumpet with alternate leadpipe)

For a piccolo trumpet, swapping the leadpipe from Bb to A is not choosing a different instrument—it's configuring the same horn differently. This distinction matters for:
- Accurate modeling of instrument ownership and selection
- Proper representation in educational and reference contexts
- Future features around instrument setup and preparation

## Current State

The piccolo trumpet in `instruments.yml` models the leadpipe swap as a variant:

```yaml
piccolo_trumpet:
  family_key: trumpet
  variants:
    alternate_leadpipe:
      pitch_designation: A
      staff_schemes:
        default:
          - clef: treble_clef
            sounding_transposition: 9
    default:
      pitch_designation: Bb
      staff_schemes:
        default:
          - clef: treble_clef
            sounding_transposition: 10
```

## Proposed State

Introduce a Modification concept that represents adjustments to a single instrument:

```yaml
piccolo_trumpet:
  family_key: trumpet
  default_pitched_variant: b_flat
  pitched_variants:
    b_flat:
      pitch_designation: Bb
    a:
      pitch_designation: A
  modifications:
    alternate_leadpipe:
      switches_to_variant: a
      description: "Swap to A leadpipe"
```

## User Stories

**STORY 1: Create Modification class**

AS a developer
WHEN I need to represent a physical adjustment to an instrument
I WANT to use a Modification object
SO THAT I can distinguish adjustments from variant selection

**STORY 2: Link modifications to pitched variants**

AS a developer
WHEN a modification changes the instrument's pitch (like a leadpipe swap)
I WANT the modification to reference which pitched variant it produces
SO THAT the relationship between adjustment and resulting pitch is clear

**STORY 3: Query available modifications**

AS a developer
WHEN I have an Instrument instance
I WANT to query its available modifications
SO THAT I can present setup options to users

## Implementation Notes

1. Create `HeadMusic::Instruments::Modification` class
2. Modifications are defined at the instrument level, not the variant level
3. A modification may optionally reference a pitched variant it switches to
4. Modifications could later support other adjustments (mutes, scordatura, capo position)

## Acceptance Criteria

- [ ] `HeadMusic::Instruments::Modification` class exists
- [ ] Piccolo trumpet models leadpipe swap as a modification
- [ ] `Instrument#modifications` returns available modifications
- [ ] Modifications can reference the pitched variant they produce
- [ ] All existing tests pass
- [ ] New tests cover modification functionality
- [ ] Maintains 90%+ test coverage

## Future Considerations

Other potential modifications to model in the future:
- Mutes (some affect pitch, like stopping mute on horn)
- Scordatura tuning for strings
- Capo position for fretted instruments
- Crooks for natural horn
