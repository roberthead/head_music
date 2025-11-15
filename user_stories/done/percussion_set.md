# Percussion Set Staff

As a composer or arranger

I want to create percussion set or drum kit parts in a score

So that I can notate multiple unpitched percussion instruments on a single staff

## Background

Individual percussion instruments (timpani, snare_drum, bass_drum, etc.) already exist in the codebase and use the `neutral_clef` (also known as percussion_clef). However, there's no way to represent a **percussion set** or **drum kit** where multiple unpitched instruments are notated on a single staff with each instrument assigned to a specific line or space.

This is distinct from a clef. The `neutral_clef` already exists in `HeadMusic::Rudiment::Clef`. What's needed is:
1. A new instrument definition for percussion sets (e.g., `drum_kit`, `percussion_set`)
2. A staff scheme that uses the `neutral_clef`
3. A percussion mapping system that defines which instruments appear on which staff lines/spaces

## Scenario: Create a standard drum kit staff

Given I am composing a piece with drum kit

When I create a drum_kit instrument

Then it should use the neutral_clef

And it should have a default percussion mapping for standard drum kit instruments

## Scenario: Map percussion instruments to staff positions

Given I have a drum_kit instrument

When I request the percussion mapping

Then I should see which line or space each percussion instrument occupies

Examples:
- Crash cymbal → line 5
- Hi-hat → line 4 (or space above)
- Snare drum → line 3 (center line)
- Bass drum → line 1 (or space below)
- Floor tom → line 2

## Scenario: Create custom percussion set configurations

Given I want to notate a non-standard percussion ensemble

When I define a custom percussion_set

Then I should be able to specify which percussion instruments map to which staff positions

And the system should use the neutral_clef for the staff

## Technical Notes

### Architecture

A percussion set is:
- **NOT a clef** - it uses the existing `neutral_clef`
- **An instrument** with a special staff scheme configuration
- **A mapping system** that assigns percussion instruments to staff positions

### Proposed Implementation

Add to `lib/head_music/instruments/instruments.yml`:

```yaml
drum_kit:
  family_key: percussion_set
  variants:
    default:
      staff_schemes:
        default:
          - clef: neutral_clef
            percussion_mapping:
              line_5: crash_cymbal
              space_4: ride_cymbal
              line_4: hi_hat
              space_3: high_tom
              line_3: snare_drum
              space_2: mid_tom
              line_2: floor_tom
              space_1: bass_drum
              line_1: bass_drum

percussion_set:
  family_key: percussion_set
  variants:
    default:
      staff_schemes:
        default:
          - clef: neutral_clef
```

### New Concepts to Implement

1. **Percussion mapping attribute** on `HeadMusic::Instruments::Staff`
2. **Percussion family or category** to identify instruments as unpitched/percussion
3. **Position resolution** to determine which line/space a percussion instrument should use

### Related Components

- `HeadMusic::Rudiment::Clef` - neutral_clef already exists (line 115-128 in clefs.yml)
- `HeadMusic::Instruments::Staff` - would need to handle percussion_mapping attribute
- `HeadMusic::Instruments::StaffScheme` - provides the staff configuration
- Individual percussion instruments (timpani, snare_drum, etc.) already exist

## Acceptance Criteria

- Can create a drum_kit instrument
- drum_kit uses neutral_clef by default
- Can query which percussion instrument is assigned to each staff position
- Can create custom percussion_set configurations with custom mappings
- Maintains 90%+ test coverage
- Follows existing HeadMusic patterns (factory methods, YAML data-driven)

## Implementation Plan

### Design Decisions

Based on research and discussion:

1. **Naming**: Use `instrument_mapping` (not `percussion_mapping`) for flexibility
2. **Mapping Format**: Use instrument keys (strings/symbols), not objects
3. **Validation**:
   - Mapped instruments must exist
   - No requirement that they be percussion instruments
   - Valid positions: `line_0` through `line_6`, `space_0` through `space_5`
4. **Flexibility**: Mappings are immutable (YAML-defined only) for now
5. **Stem Direction**: Rendering concern, not part of infrastructure
6. **Composite Instruments**: No special type needed - just regular instruments with `instrument_mapping`
7. **Family**: Use `drum_kit` family (not generic `percussion_set`)

### Standard Drum Kit Notation Mapping

Research shows there is no single universal standard, but most common convention:

```yaml
instrument_mapping:
  space_0: hi_hat_pedal        # below staff
  line_1: bass_drum
  line_2: floor_tom
  line_3: snare_drum            # middle line - most consistent
  line_4: mid_tom
  space_4: high_tom
  line_5: ride_cymbal
  space_5: hi_hat               # above staff
  line_6: crash_cymbal          # first ledger line above
```

### Implementation Steps

#### 1. Add New Instrument Families
To `lib/head_music/instruments/instrument_families.yml`:
- `tom_tom` family
- `hi_hat` family
- `drum_kit` family

#### 2. Add New Individual Instruments
To `lib/head_music/instruments/instruments.yml`:
- `hi_hat` (family: hi_hat)
- `hi_hat_pedal` (family: hi_hat)
- `crash_cymbal` (family: cymbal)
- `ride_cymbal` (family: cymbal)
- `high_tom` (family: tom_tom)
- `mid_tom` (family: tom_tom)
- `floor_tom` (family: tom_tom)

Each with:
- Appropriate aliases
- `family_key` reference
- Single `default` variant
- `neutral_clef` staff scheme

#### 3. Add Composite Instrument
To `lib/head_music/instruments/instruments.yml`:
- `drum_kit` (alias: `drum_set`) with standard instrument_mapping

#### 4. Enhance Staff Class
To `lib/head_music/instruments/staff.rb`:
- Add `instrument_mapping` attribute (hash)
- Add `#instrument_for_position(position_key)` method
- Add `#position_for_instrument(instrument_name)` method
- Add `#components` method (derives instruments from mapping)
- Handle parsing `instrument_mapping` from YAML
- Validate:
  - Position keys match pattern (line_0-6, space_0-5)
  - Referenced instruments exist

#### 5. Tests
- Specs for all new instrument families
- Specs for all new individual instruments
- Specs for `Staff#instrument_mapping` functionality
- Specs for `drum_kit` composite instrument
- Maintain 90%+ code coverage

---

## Refactoring Notes (Post-Implementation)

After the initial implementation, the design was refactored to better model playing techniques as a first-class concept rather than treating them as separate instruments.

### Key Changes:

1. **Introduced `PlayingTechnique` class**
   - Playing techniques (pedal, stick, mallet, etc.) are now modeled as objects
   - Includes `HeadMusic::Named` for potential future i18n support
   - Common techniques defined: stick, pedal, mallet, hand, brush, rim_shot, cross_stick, open, closed, etc.

2. **Created `StaffMapping` class** (replaces simple hash-based approach)
   - Represents the mapping of an instrument + optional playing technique to a staff position
   - Uses `StaffPosition` with index-based positions (even = lines, odd = spaces)
   - Attributes: `staff_position`, `instrument_key`, `playing_technique_key`
   - Methods: `#instrument`, `#playing_technique`, `#position_index`, `#to_s`

3. **Removed `hi_hat_pedal` as separate instrument**
   - Hi-hat pedal is now correctly modeled as a playing technique of the hi-hat instrument
   - The hi-hat appears at two positions in drum_kit mapping:
     - Position -1 (space below staff): hi_hat with pedal technique
     - Position 9 (space above staff): hi_hat with stick technique

4. **Updated `Staff` class API**
   - `#mappings` → returns array of `StaffMapping` objects
   - `#mapping_for_position(index)` → get full mapping at position
   - `#instrument_for_position(index)` → get instrument at position
   - `#positions_for_instrument(key)` → returns all positions (handles multiple mappings)
   - `#components` → returns unique instruments

5. **Changed YAML format** from hash to array:
   ```yaml
   # Old format:
   instrument_mapping:
     line_3: snare_drum
     space_5: hi_hat

   # New format:
   mappings:
     - staff_position: 4        # index 4 = line 3
       instrument: snare_drum
     - staff_position: 9        # index 9 = space above staff
       instrument: hi_hat
       playing_technique: stick
   ```

6. **Added comprehensive YARD documentation**
   - All new classes and public methods documented
   - Examples provided for common use cases

### Benefits of Refactoring:

- **Semantic clarity**: Hi-hat pedal is a technique, not an instrument
- **Extensibility**: Easy to add new playing techniques (bow techniques for strings, breath techniques for winds, etc.)
- **Flexibility**: Instruments can appear at multiple positions with different techniques
- **Type safety**: StaffPosition validates position indices, StaffMapping provides structured access

### Test Results:

- **1040 examples, 0 failures** ✅
- **91.54% line coverage, 84.44% branch coverage** ✅
- All existing functionality preserved
- New tests verify multiple technique mappings
