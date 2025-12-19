# Rename Variant to PitchedVariant

AS a developer

I WANT the Variant class renamed to PitchedVariant

SO THAT the class name accurately reflects what it represents: a pitch-based variant of an instrument

## Prerequisites

This story depends on:
- **000-overlay-architecture.md** - Establishes the layer resolution system
- **001-instrument-configuration.md** - Extracts configurations from variants
- **002-notation-style.md** - Extracts staff schemes from variants

Once configurations and notation styles are extracted, PitchedVariant becomes purely about pitch selection, which populates the **instance layer** attributes.

## Background

Through analysis of the instrument data, we discovered that once notation concerns (staff schemes) and physical adjustments (modifications) are extracted, all remaining variants differ on exactly one dimension: **pitch designation**.

The current `Variant` class name is generic and doesn't communicate what kind of variation it represents. Renaming to `PitchedVariant` makes the concept self-documenting and aligns with the updated YAML structure using `pitched_variants` as the key.

## Current State

```ruby
# lib/head_music/instruments/variant.rb
class HeadMusic::Instruments::Variant
  attr_reader :key, :attributes

  def pitch_designation
    # ...
  end

  def staff_schemes  # This will be removed
    # ...
  end
end
```

```yaml
# instruments.yml
clarinet:
  variants:
    default:
      pitch_designation: Bb
      staff_schemes:  # Moving to NotationStyle
        default:
          - clef: treble_clef
            sounding_transposition: -2
    in_a:
      pitch_designation: A
      staff_schemes:
        default:
          - clef: treble_clef
            sounding_transposition: -3
```

## Proposed State

```ruby
# lib/head_music/instruments/pitched_variant.rb
class HeadMusic::Instruments::PitchedVariant
  attr_reader :key, :pitch_designation

  def initialize(key, attributes)
    @key = key.to_sym
    @pitch_designation = parse_pitch_designation(attributes["pitch_designation"])
  end

  # Staff schemes removed - now in NotationStyle
end
```

```yaml
# instruments.yml
clarinet:
  family_key: clarinet
  default_pitched_variant: b_flat
  pitched_variants:
    b_flat:
      pitch_designation: Bb
    a:
      pitch_designation: A
    c:
      pitch_designation: C
    d:
      pitch_designation: D
      aliases:
        - sopranino_clarinet
    e_flat:
      pitch_designation: Eb
      aliases:
        - sopranino_clarinet
```

## User Stories

**STORY 1: Rename Variant class to PitchedVariant**

AS a developer
WHEN I work with instrument pitch variants
I WANT the class named PitchedVariant
SO THAT the name clearly indicates what the class represents

**STORY 2: Update YAML structure**

AS a developer
WHEN I define instrument variants in YAML
I WANT to use `pitched_variants` and `default_pitched_variant` keys
SO THAT the data structure matches the domain concept

**STORY 3: Simplify PitchedVariant class**

AS a developer
WHEN I use a PitchedVariant
I WANT it to contain only pitch-related data
SO THAT the class has a single, clear responsibility

**STORY 4: Clean variant key names**

AS a developer
WHEN I reference a pitched variant
I WANT to use clean keys like `b_flat` instead of `in_b_flat`
SO THAT the "in" display prefix is a presentation concern, not identity

**STORY 5: Explicit default assignment**

AS a developer
WHEN I need to know the default pitched variant
I WANT an explicit `default_pitched_variant` field
SO THAT defaults are declared, not implicit in key names

## Implementation Notes

1. Rename `Variant` class to `PitchedVariant`
2. Rename `variant.rb` to `pitched_variant.rb`
3. Remove `staff_schemes` and `default_staff_scheme` methods (moved to NotationStyle)
4. Update YAML structure:
   - `variants` -> `pitched_variants`
   - Add `default_pitched_variant` field
   - Remove `default` as magic key name
   - Remove `in_` prefix from variant keys
5. Update `GenericInstrument` class to use new names
6. Update `Instrument` to use new names
7. Update all specs

## Migration Checklist

- [ ] Create `pitched_variant.rb` with new class
- [ ] Update `GenericInstrument` to load `pitched_variants` from YAML
- [ ] Update `Instrument#default_variant` to use `default_pitched_variant`
- [ ] Update `Instrument` references
- [ ] Update `instruments.yml` structure for all instruments
- [ ] Remove old `Variant` class
- [ ] Update all specs to use new names
- [ ] Update CLAUDE.md if needed

## Acceptance Criteria

- [ ] `HeadMusic::Instruments::PitchedVariant` class exists
- [ ] `HeadMusic::Instruments::Variant` class removed
- [ ] `instruments.yml` uses `pitched_variants` key
- [ ] `instruments.yml` uses `default_pitched_variant` for explicit defaults
- [ ] Variant keys are clean (`b_flat` not `in_b_flat`)
- [ ] PitchedVariant has no staff_scheme methods
- [ ] All existing functionality preserved
- [ ] All tests pass
- [ ] Maintains 90%+ test coverage

## Dependencies

This story should be implemented after:
- **000-overlay-architecture.md** (establishes layer resolution)
- **001-instrument-configuration.md** (extracts configurations)
- **002-notation-style.md** (extracts staff schemes)

Once those concerns are extracted, PitchedVariant becomes purely about pitch, making this rename meaningful.

## Relationship to Overlay Architecture

In the overlay pattern, selecting a pitched variant populates the **instance layer** with pitch-specific attributes:

```ruby
# GenericInstrument defines available pitched variants
clarinet = GenericInstrument.get("clarinet")
clarinet.pitched_variants  # => [:b_flat, :a, :c, :d, :e_flat]
clarinet.default_pitched_variant  # => :b_flat

# Selecting a variant populates instance layer attributes
clarinet_in_a = Instrument.new(
  prototype: clarinet,
  attributes: { pitch: "A", transposition: -3 }  # from pitched_variant :a
)

clarinet_in_a.pitch  # => "A" (from instance layer)
clarinet_in_a.family # => "clarinet" (falls through to prototype)
```
