# Instrument Configuration Model

AS a developer

I WANT to model physical configurations of instruments (such as swapping a leadpipe on a piccolo trumpet, adding an extension to a double bass, or engaging a valve on a bass trombone)

SO THAT I can distinguish between different instruments versus configurations of a single instrument

## Background

The current Variant model conflates two distinct concepts:

1. **Pitched variants** - Different instruments a player owns separately (e.g., Clarinet in A vs Clarinet in B♭)
2. **Configurations** - Physical setup choices on a single instrument (e.g., piccolo trumpet with alternate leadpipe)

For a piccolo trumpet, swapping the leadpipe from B♭ to A is not choosing a different instrument—it's configuring the same horn differently. This distinction matters for:
- Accurate modeling of instrument ownership and selection
- Proper representation in educational and reference contexts
- Future features around instrument setup and preparation

## Examples of Configurations

| Instrument | Configuration | Effect |
|------------|--------------|--------|
| Piccolo trumpet | A leadpipe (vs default B♭) | Changes key from B♭ to A |
| Double bass | C extension | Extends range down to C1 |
| Bass trombone | F attachment engaged | Extends range, changes partials |
| Horn | Stopping valve | Raises pitch by semitone when engaged |
| C trumpet | D slide | Changes key from C to D |
| Natural horn | F crook (vs E♭ crook) | Changes key |

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

Introduce a Configuration concept that represents physical setup choices:

```yaml
piccolo_trumpet:
  family_key: trumpet
  default_pitched_variant: b_flat
  pitched_variants:
    b_flat:
      pitch_designation: Bb
    a:
      pitch_designation: A
  configurations:
    alternate_leadpipe:
      switches_to_variant: a
      description: "A leadpipe"

bass_trombone:
  family_key: trombone
  configurations:
    f_attachment:
      description: "F attachment engaged"
      extends_range_down: 6  # semitones

double_bass:
  family_key: double_bass
  configurations:
    c_extension:
      description: "C extension"
      extends_range_down: 4  # semitones (E1 to C1)
```

## User Stories

**STORY 1: Create Configuration class**

AS a developer
WHEN I need to represent a physical configuration of an instrument
I WANT to use a Configuration object
SO THAT I can distinguish configurations from variant selection

**STORY 2: Link configurations to pitched variants**

AS a developer
WHEN a configuration changes the instrument's pitch (like a leadpipe swap)
I WANT the configuration to reference which pitched variant it produces
SO THAT the relationship between configuration and resulting pitch is clear

**STORY 3: Query available configurations**

AS a developer
WHEN I have a GenericInstrument instance
I WANT to query its available configurations
SO THAT I can present setup options to users

**STORY 4: Model range-extending configurations**

AS a developer
WHEN a configuration extends the instrument's range (like a bass trombone F attachment)
I WANT to specify the range extension
SO THAT range calculations account for the configuration

## Implementation Notes

1. Create `HeadMusic::Instruments::Configuration` class
2. Configurations are defined at the GenericInstrument level
3. A configuration may optionally:
   - Reference a pitched variant it switches to
   - Specify range extensions (up or down)
   - Provide a description
4. Configurations represent physical setup, not transient states (see story 004 for tunings, capos, mutes)

## Acceptance Criteria

- [ ] `HeadMusic::Instruments::Configuration` class exists
- [ ] Piccolo trumpet models leadpipe swap as a configuration
- [ ] `GenericInstrument#configurations` returns available configurations
- [ ] Configurations can reference the pitched variant they produce
- [ ] Configurations can specify range extensions
- [ ] All existing tests pass
- [ ] New tests cover configuration functionality
- [ ] Maintains 90%+ test coverage
