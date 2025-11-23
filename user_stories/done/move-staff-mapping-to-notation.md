# Move StaffMapping to Notation Module

AS a developer

I WANT StaffMapping in the HeadMusic::Notation module

SO THAT percussion notation mapping logic lives with visual notation concerns rather than instrument properties

## Background

`StaffMapping` maps percussion instruments (and playing techniques) to specific positions on a staff. For example, in a standard drum kit staff:
- Bass drum → space below staff
- Snare drum → space 2
- Hi-hat → space 4
- Ride cymbal → top line

This is purely about visual notation - where on the staff each drum appears - not about the acoustic properties of the instruments themselves. The drum's sound (pitch range, timbre) is an instrument property, but where it appears on a staff is a notation convention.

Currently located in `HeadMusic::Instruments`, this class should move to `HeadMusic::Notation` to properly separate visual layout concerns from instrument acoustics.

## Scenario: Mapping drums to staff positions

Given a drum kit with a snare drum

When I need to notate the snare on a staff

Then StaffMapping tells me it appears on space 2

And I can use that position for rendering

## Scenario: Getting all mappings for an instrument

Given a drum kit instrument

When I access its staff mapping

Then I get all the drum-to-position mappings for that kit

And each mapping includes the instrument, playing technique, and staff position

## Scenario: Supporting different percussion notation schemes

Given different percussion instruments use different staff conventions

When I create a StaffMapping for a specific scheme (e.g., "standard drum kit")

Then instruments are mapped to their conventional positions for that notation style

## Technical Notes

### Current State

**Location:** `lib/head_music/instruments/staff_mapping.rb`
**Class:** `HeadMusic::Instruments::StaffMapping`
**Tests:** `spec/head_music/instruments/staff_mapping_spec.rb`
**Used by:**
- `lib/head_music/instruments/staff.rb`
- `lib/head_music/instruments/staff_scheme.rb`
- Percussion instrument configurations

### Proposed Changes

1. **Move file:**
   - From: `lib/head_music/instruments/staff_mapping.rb`
   - To: `lib/head_music/notation/staff_mapping.rb`

2. **Update class definition:**
   ```ruby
   # lib/head_music/notation/staff_mapping.rb
   module HeadMusic::Notation; end

   class HeadMusic::Notation::StaffMapping
     attr_reader :instrument, :playing_technique, :staff_position

     def initialize(instrument:, playing_technique: nil, staff_position:)
       @instrument = instrument
       @playing_technique = playing_technique
       @staff_position = HeadMusic::Notation::StaffPosition.new(staff_position)
     end

     # ... rest of class unchanged
   end
   ```

3. **Move spec file:**
   - From: `spec/head_music/instruments/staff_mapping_spec.rb`
   - To: `spec/head_music/notation/staff_mapping_spec.rb`

4. **Update spec:**
   ```ruby
   describe HeadMusic::Notation::StaffMapping do
     # All tests remain unchanged except the describe statement
   ```

5. **Update references:**
   - `lib/head_music/instruments/staff.rb` - Update StaffMapping references
   - `lib/head_music/instruments/staff_scheme.rb` - Update StaffMapping references
   - Instrument YAML files if they reference the class directly

6. **Update loading:**
   ```ruby
   # lib/head_music/notation.rb
   module HeadMusic::Notation; end

   require "head_music/notation/staff_position"
   require "head_music/notation/musical_symbol"
   require "head_music/notation/staff_mapping"
   ```

### Files to Update

- Move: `lib/head_music/instruments/staff_mapping.rb` → `lib/head_music/notation/staff_mapping.rb`
- Move: `spec/head_music/instruments/staff_mapping_spec.rb` → `spec/head_music/notation/staff_mapping_spec.rb`
- Update: `lib/head_music/notation.rb` (add require)
- Update: `lib/head_music/instruments/staff.rb` (update references)
- Update: `lib/head_music/instruments/staff_scheme.rb` (update references)
- Remove: `lib/head_music/instruments.rb` require for staff_mapping

### Dependencies

This story depends on `StaffPosition` already being in the Notation module, since `StaffMapping` uses `StaffPosition`. Recommended to complete the "Move StaffPosition to Notation" story first.

## Acceptance Criteria

- [ ] `HeadMusic::Notation::StaffMapping` class exists
- [ ] Original file `lib/head_music/instruments/staff_mapping.rb` removed
- [ ] Spec file at `spec/head_music/notation/staff_mapping_spec.rb`
- [ ] All existing StaffMapping tests pass
- [ ] StaffMapping correctly references `Notation::StaffPosition`
- [ ] References in `Instruments::Staff` updated and working
- [ ] References in `Instruments::StaffScheme` updated and working
- [ ] `lib/head_music/notation.rb` requires staff_mapping
- [ ] `lib/head_music/instruments.rb` no longer requires staff_mapping
- [ ] All percussion instrument tests still pass
- [ ] All existing tests across entire codebase still pass
- [ ] Maintains 90%+ test coverage
- [ ] No deprecation warnings or breaking changes for internal usage

## Implementation Steps

1. Verify `StaffPosition` is already in `HeadMusic::Notation`
2. Create `lib/head_music/notation/staff_mapping.rb` with updated module path
3. Update StaffPosition reference to use `Notation::StaffPosition`
4. Copy rest of class implementation unchanged
5. Create `spec/head_music/notation/staff_mapping_spec.rb`
6. Update describe statement in spec
7. Update `lib/head_music/notation.rb` to require staff_mapping
8. Update references in `lib/head_music/instruments/staff.rb`
9. Update references in `lib/head_music/instruments/staff_scheme.rb`
10. Remove require from `lib/head_music/instruments.rb`
11. Run tests: `bundle exec rspec spec/head_music/notation/staff_mapping_spec.rb`
12. Run tests: `bundle exec rspec spec/head_music/instruments/staff_spec.rb`
13. Run tests: `bundle exec rspec spec/head_music/instruments/staff_scheme_spec.rb`
14. Run percussion-related tests
15. Run full test suite: `bundle exec rspec`
16. Run linter: `bundle exec rubocop -a`
17. Delete original files after verifying everything works
18. Verify 90%+ coverage maintained
