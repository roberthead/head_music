# Instrument Inheritance Architecture

AS a developer

I WANT instruments to resolve attributes through composable parent-based inheritance with configurable options

SO THAT I can model the full complexity of instruments with a simple, familiar pattern

## Background

The current instrument architecture uses nested objects (GenericInstrument → Variant → StaffScheme → Staff) which conflates several independent concerns:

1. **Species defaults** - What a trumpet typically is
2. **Pitched identity** - This specific clarinet is in A
3. **Physical configuration** - Piccolo trumpet with A leadpipe installed
4. **Notation conventions** - British brass band uses treble clef for euphonium

This story addresses concerns 1-3 through parent-based inheritance. Notation (concern 4) is orthogonal and will be handled separately.

## The Inheritance Pattern

### Self-Referential Instrument

```
┌─────────────────────────────────────────────────────────┐
│  Instrument                                             │
│    belongs_to :parent (optional)                        │
│    has_many :instrument_configurations                  │
│                                                         │
│  Attributes resolve via parent chain:                   │
│    pitch_key || parent&.pitch_key                       │
└─────────────────────────────────────────────────────────┘
```

### Inheritance Examples

```
trumpet (no parent)
  ├── piccolo_trumpet (parent: trumpet, different range)
  ├── bass_trumpet (parent: trumpet, different range)
  └── pocket_trumpet (parent: trumpet, same attributes)

clarinet (no parent, pitch_key: b_flat)
  ├── clarinet_in_a (parent: clarinet, pitch_key: a)
  ├── clarinet_in_c (parent: clarinet, pitch_key: c)
  ├── clarinet_in_e_flat (parent: clarinet, pitch_key: e_flat)
  └── bass_clarinet (parent: clarinet, different range)
```

### Resolution Example

```ruby
clarinet = Instrument.get("clarinet")
clarinet.pitch_key        # => "b_flat"
clarinet.family_key       # => "clarinet"

clarinet_in_a = Instrument.get("clarinet_in_a")
clarinet_in_a.pitch_key   # => "a" (own attribute)
clarinet_in_a.family_key  # => "clarinet" (from parent)
clarinet_in_a.parent      # => clarinet
```

### Key Characteristics

1. **Simple**: One class, one relationship, familiar pattern
2. **Natural resolution**: `attribute || parent&.attribute`
3. **Arbitrary depth**: Can model instrument families at any level
4. **Data-driven**: YAML or database records, not code

## Core Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `name_key` | String | Primary identifier ("trumpet", "clarinet_in_a") |
| `alias_name_keys` | Array | Alternative names |
| `pitch_key` | String | The pitch designation ("b_flat", "a", "f") |
| `family_key` | String | Instrument family ("trumpet", "clarinet") |
| `orchestra_section_key` | String | Section ("brass", "woodwind", "strings") |
| `classification_keys` | Array | Hornbostel-Sachs style classifications |
| `default_clef_key` | String | Primary clef for this instrument |
| `range_low` | String | Lowest playable pitch |
| `range_high` | String | Highest playable pitch |

## Configuration System

Instruments can have configurable options that modify their attributes when selected.

### Structure

```ruby
class Instrument
  belongs_to :parent, class_name: "Instrument", optional: true
  has_many :instrument_configurations  # applies to self and descendants
end

class InstrumentConfiguration
  belongs_to :instrument
  has_many :instrument_configuration_options

  # name_key: "leadpipe", "mute", "crook", "extension", "attachment"
end

class InstrumentConfigurationOption
  belongs_to :instrument_configuration

  # name_key: "a_leadpipe", "straight_mute", "f_crook"
  # transposition_semitones: Integer (e.g., -1 for A leadpipe on Bb instrument)
  # lowest_pitch_semitones: Integer (e.g., -4 for C extension on double bass)
end
```

### Configuration Examples

| Instrument | Configuration | Options |
|------------|---------------|---------|
| Piccolo trumpet | `leadpipe` | `b_flat` (default), `a` (transposition: -1) |
| Bass trombone | `f_attachment` | `disengaged`, `engaged` (lowest_pitch: -6) |
| Double bass | `c_extension` | `without`, `with` (lowest_pitch: -4) |
| Natural horn | `crook` | `e_flat`, `f`, `g`, etc. (various transpositions) |
| Trumpet | `mute` | `open`, `straight`, `cup`, `harmon` |
| Guitar | `capo` | `fret_0` through `fret_12` (transposition: 0-12) |

### Configuration Resolution

- `instrument.instrument_configurations` walks parent chain, collects all
- No configuration selected = base instrument attributes unchanged
- Configuration selection lives in composition context (Part/Voice), not on Instrument
- A Part specifies target characteristics; configuration selection is derived/validated

```ruby
# The instrument defines what CAN be configured
piccolo_trumpet = Instrument.get("piccolo_trumpet")
piccolo_trumpet.instrument_configurations  # => [leadpipe config from parent chain]

# A Part specifies what characteristics are needed
part.instrument           # => piccolo_trumpet
part.target_pitch_key     # => "a"
part.effective_transposition  # resolved via configuration options
```

## User Stories

### STORY 1: Implement parent-based attribute resolution

AS a developer
WHEN I access an attribute on an Instrument
I WANT it resolved through the parent chain
SO THAT child instruments inherit from parents

**Acceptance criteria:**
- `instrument.pitch_key` returns own value or walks parent chain
- All core attributes support parent chain resolution
- Returns nil if no instrument in chain provides the attribute

### STORY 2: Implement configuration inheritance

AS a developer
WHEN I query an instrument's available configurations
I WANT to get configurations from the entire parent chain
SO THAT child instruments inherit configurable options

**Acceptance criteria:**
- `instrument.instrument_configurations` collects from self and all ancestors
- Configurations defined on parent apply to all descendants
- Child can define additional configurations

### STORY 3: Model configuration options with effects

AS a developer
WHEN I define configuration options
I WANT to specify their effects on instrument attributes
SO THAT transposition and range changes are calculable

**Acceptance criteria:**
- `InstrumentConfigurationOption` has `transposition_semitones` attribute
- `InstrumentConfigurationOption` has `lowest_pitch_semitones` attribute
- Effects are integers representing semitone adjustments

### STORY 4: Migrate existing instrument data

AS a developer
WHEN I use the existing `Instrument.get()` API
I WANT it to work with the new inheritance architecture
SO THAT existing code continues to function

**Acceptance criteria:**
- `Instrument.get("trumpet")` returns instrument with no parent
- `Instrument.get("clarinet_in_a")` returns instrument with parent: clarinet
- All existing tests pass

### STORY 5: Remove Variant class

AS a developer
WHEN pitched variants are modeled as child instruments
I WANT to remove the separate Variant class
SO THAT the model is simplified

**Acceptance criteria:**
- `Variant` class removed
- All pitched variants are now `Instrument` records with parents
- YAML structure updated to reflect inheritance

## Migration Strategy

1. **Phase 1**: Add `parent` relationship to Instrument class
2. **Phase 2**: Implement parent chain attribute resolution
3. **Phase 3**: Migrate YAML data to parent-based structure
4. **Phase 4**: Create InstrumentConfiguration and InstrumentConfigurationOption classes
5. **Phase 5**: Remove Variant class and update GenericInstrument
6. **Phase 6**: Update all specs

## Acceptance Criteria

- [x] `Instrument` class has `belongs_to :parent` relationship
- [x] Attributes resolve through parent chain
- [ ] `Instrument#instrument_configurations` collects from ancestor chain
- [ ] `InstrumentConfiguration` class exists with `name_key`
- [ ] `InstrumentConfigurationOption` class exists with effect attributes
- [x] `Variant` class removed
- [x] YAML structure uses parent-based inheritance
- [x] `Instrument.get()` API preserved for backward compatibility
- [x] All existing tests pass
- [ ] New tests cover inheritance and configuration
- [x] Maintains 90%+ test coverage

## Deferred

- **Tunings**: String instruments need individual string modeling before alternate tunings can be represented
- **Notation**: Clef and transposition display conventions are orthogonal; see 002-notation-style.md

## Open Questions

1. **Multiple staves**: Piano needs two staves (grand staff). Is this an attribute on the instrument, or a notation concern?

2. **Configuration selection in composition**: How does a Part specify which configuration options are selected? Options:
   - Part stores selected options directly
   - Part stores target attributes, system validates/suggests configurations
   - Both (target attributes preferred, explicit selection as override)
