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
