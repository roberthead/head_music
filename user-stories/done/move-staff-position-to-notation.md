# Move StaffPosition to Notation Module

AS a developer

I WANT StaffPosition in the HeadMusic::Notation module

SO THAT staff positioning logic lives with other visual notation concerns rather than instrument properties

## Background

`StaffPosition` represents positions on a 5-line musical staff (lines, spaces, and ledger lines). It's a pure visual notation concept with no connection to instrument acoustical properties.

Currently located in `HeadMusic::Instruments`, it has a TODO comment (line 5) suggesting it should move to a HeadMusic::Notation module.

The class:
- Maps integer indices to staff positions (even = lines, odd = spaces)
- Handles positions within the staff (0-8) and ledger lines above/below
- Provides named positions ("bottom line", "middle line", "top line", etc.)
- Has comprehensive test coverage (264 lines of tests)

This move resolves the TODO and establishes StaffPosition as the first concrete class in the Notation module.

## Scenario: Accessing staff positions for rendering

Given I need to position a note on a musical staff

When I use `HeadMusic::Notation::StaffPosition.new(4)`

Then I get the middle line staff position

And I can query whether it's a line or space

And I can get its display name

## Scenario: Using named staff positions

Given I need to reference a specific staff position

When I use `HeadMusic::Notation::StaffPosition.name_to_index("top line")`

Then I get the index 8

And I can create a StaffPosition from that index

## Scenario: Handling ledger lines

Given I need a position above or below the standard staff

When I create `HeadMusic::Notation::StaffPosition.new(10)`

Then I get "ledger line above staff"

And when I create `HeadMusic::Notation::StaffPosition.new(-2)`

Then I get "ledger line below staff"

## Technical Notes

### Current State

**Location:** `lib/head_music/instruments/staff_position.rb`
**Class:** `HeadMusic::Instruments::StaffPosition`
**Tests:** `spec/head_music/instruments/staff_position_spec.rb` (264 lines)
**Dependencies:** Used by `Clef` for pitch-to-staff mapping

### Proposed Changes

1. **Move file:**
   - From: `lib/head_music/instruments/staff_position.rb`
   - To: `lib/head_music/notation/staff_position.rb`

2. **Update class definition:**
   ```ruby
   # lib/head_music/notation/staff_position.rb
   module HeadMusic::Notation; end

   class HeadMusic::Notation::StaffPosition
     # Remove TODO comment about moving to Notation module
     # ... rest of class unchanged
   ```

3. **Move spec file:**
   - From: `spec/head_music/instruments/staff_position_spec.rb`
   - To: `spec/head_music/notation/staff_position_spec.rb`

4. **Update spec:**
   ```ruby
   describe HeadMusic::Notation::StaffPosition do
     # All tests remain unchanged except the describe statement
   ```

5. **Update references:**
   - `lib/head_music/rudiment/clef.rb` - Update StaffPosition references
   - `lib/head_music/notation.rb` - Add require for staff_position

6. **Update loading:**
   ```ruby
   # lib/head_music/notation.rb
   module HeadMusic::Notation; end

   require "head_music/notation/staff_position"
   ```

### Files to Update

- Move: `lib/head_music/instruments/staff_position.rb` → `lib/head_music/notation/staff_position.rb`
- Move: `spec/head_music/instruments/staff_position_spec.rb` → `spec/head_music/notation/staff_position_spec.rb`
- Update: `lib/head_music/notation.rb` (add require)
- Update: `lib/head_music/rudiment/clef.rb` (update references)
- Remove: `lib/head_music/instruments.rb` require for staff_position
- Update: CLAUDE.md (note StaffPosition location)

## Acceptance Criteria

- [ ] `HeadMusic::Notation::StaffPosition` class exists
- [ ] Original file `lib/head_music/instruments/staff_position.rb` removed
- [ ] Spec file at `spec/head_music/notation/staff_position_spec.rb`
- [ ] All 264 lines of existing tests pass unchanged (except describe statement)
- [ ] TODO comment removed from class
- [ ] All references in `Clef` updated and working
- [ ] `lib/head_music/notation.rb` requires staff_position
- [ ] `lib/head_music/instruments.rb` no longer requires staff_position
- [ ] All existing tests across entire codebase still pass
- [ ] Maintains 90%+ test coverage
- [ ] No deprecation warnings or breaking changes for internal usage

## Implementation Steps

1. Create `lib/head_music/notation/staff_position.rb` with updated module path
2. Copy class implementation, removing TODO comment
3. Create `spec/head_music/notation/staff_position_spec.rb`
4. Update describe statement in spec
5. Update `lib/head_music/notation.rb` to require staff_position
6. Update references in `lib/head_music/rudiment/clef.rb`
7. Remove require from `lib/head_music/instruments.rb`
8. Run tests: `bundle exec rspec spec/head_music/notation/staff_position_spec.rb`
9. Run tests: `bundle exec rspec spec/head_music/rudiment/clef_spec.rb`
10. Run full test suite: `bundle exec rspec`
11. Run linter: `bundle exec rubocop -a`
12. Delete original files after verifying everything works
13. Verify 90%+ coverage maintained
