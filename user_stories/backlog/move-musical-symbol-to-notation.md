# Move MusicalSymbol to Notation Module

AS a developer

I WANT MusicalSymbol in the HeadMusic::Notation module

SO THAT symbol representation logic (ASCII, Unicode, HTML) lives with other visual notation concerns rather than abstract music theory

## Background

`MusicalSymbol` is a container class that holds multiple representations of a musical symbol:
- ASCII representation (plain text, e.g., "#" for sharp)
- Unicode representation (musical symbols, e.g., "♯" for sharp)
- HTML entity representation (e.g., "&sharp;" for sharp)

It's currently located in `HeadMusic::Rudiment`, but it's purely about visual presentation, not music theory. Symbols are how we visually represent musical concepts, making this a notation concern.

The class is used by:
- `Clef` - for clef symbols (treble, bass, alto, etc.)
- `Alteration` - for accidental symbols (sharp, flat, natural, etc.)

Moving it to Notation clarifies that this is about rendering and display, separate from the theoretical concepts themselves.

## Scenario: Getting symbol representations

Given a sharp accidental

When I access its musical symbol

Then I can get the ASCII representation "#"

And I can get the Unicode representation "♯"

And I can get the HTML entity "&sharp;"

## Scenario: Using symbols for text output

Given I need to display a clef in plain text

When I use the clef's MusicalSymbol

Then I get the appropriate ASCII character representation

## Scenario: Using symbols for web display

Given I need to display an accidental on a web page

When I use the alteration's MusicalSymbol

Then I can choose between Unicode (for modern browsers) or HTML entity (for compatibility)

## Technical Notes

### Current State

**Location:** `lib/head_music/rudiment/musical_symbol.rb`
**Class:** `HeadMusic::Rudiment::MusicalSymbol`
**Tests:** `spec/head_music/rudiment/musical_symbol_spec.rb`
**Used by:**
- `lib/head_music/rudiment/clef.rb`
- `lib/head_music/rudiment/alteration.rb`

### Proposed Changes

1. **Move file:**
   - From: `lib/head_music/rudiment/musical_symbol.rb`
   - To: `lib/head_music/notation/musical_symbol.rb`

2. **Update class definition:**
   ```ruby
   # lib/head_music/notation/musical_symbol.rb
   module HeadMusic::Notation; end

   class HeadMusic::Notation::MusicalSymbol
     attr_reader :ascii, :unicode, :html_entity

     def initialize(ascii: nil, unicode: nil, html_entity: nil)
       @ascii = ascii
       @unicode = unicode
       @html_entity = html_entity
     end

     def to_s
       unicode || ascii
     end
   end
   ```

3. **Move spec file:**
   - From: `spec/head_music/rudiment/musical_symbol_spec.rb`
   - To: `spec/head_music/notation/musical_symbol_spec.rb`

4. **Update spec:**
   ```ruby
   describe HeadMusic::Notation::MusicalSymbol do
     # All tests remain unchanged except the describe statement
   ```

5. **Update references in Clef:**
   ```ruby
   # lib/head_music/rudiment/clef.rb
   # Update MusicalSymbol references to use HeadMusic::Notation::MusicalSymbol
   ```

6. **Update references in Alteration:**
   ```ruby
   # lib/head_music/rudiment/alteration.rb
   # Update MusicalSymbol references to use HeadMusic::Notation::MusicalSymbol
   ```

7. **Update loading:**
   ```ruby
   # lib/head_music/notation.rb
   module HeadMusic::Notation; end

   require "head_music/notation/staff_position"
   require "head_music/notation/musical_symbol"
   ```

### Files to Update

- Move: `lib/head_music/rudiment/musical_symbol.rb` → `lib/head_music/notation/musical_symbol.rb`
- Move: `spec/head_music/rudiment/musical_symbol_spec.rb` → `spec/head_music/notation/musical_symbol_spec.rb`
- Update: `lib/head_music/notation.rb` (add require)
- Update: `lib/head_music/rudiment/clef.rb` (update MusicalSymbol references)
- Update: `lib/head_music/rudiment/alteration.rb` (update MusicalSymbol references)
- Remove: `lib/head_music/rudiment.rb` require for musical_symbol

## Acceptance Criteria

- [ ] `HeadMusic::Notation::MusicalSymbol` class exists
- [ ] Original file `lib/head_music/rudiment/musical_symbol.rb` removed
- [ ] Spec file at `spec/head_music/notation/musical_symbol_spec.rb`
- [ ] All existing MusicalSymbol tests pass
- [ ] `Clef` references to MusicalSymbol updated and working
- [ ] `Alteration` references to MusicalSymbol updated and working
- [ ] `lib/head_music/notation.rb` requires musical_symbol
- [ ] `lib/head_music/rudiment.rb` no longer requires musical_symbol
- [ ] All Clef tests pass
- [ ] All Alteration tests pass
- [ ] All existing tests across entire codebase still pass
- [ ] Maintains 90%+ test coverage
- [ ] No deprecation warnings or breaking changes for internal usage

## Implementation Steps

1. Create `lib/head_music/notation/musical_symbol.rb` with updated module path
2. Copy class implementation unchanged
3. Create `spec/head_music/notation/musical_symbol_spec.rb`
4. Update describe statement in spec
5. Update `lib/head_music/notation.rb` to require musical_symbol
6. Update references in `lib/head_music/rudiment/clef.rb`
7. Update references in `lib/head_music/rudiment/alteration.rb`
8. Remove require from `lib/head_music/rudiment.rb`
9. Run tests: `bundle exec rspec spec/head_music/notation/musical_symbol_spec.rb`
10. Run tests: `bundle exec rspec spec/head_music/rudiment/clef_spec.rb`
11. Run tests: `bundle exec rspec spec/head_music/rudiment/alteration_spec.rb`
12. Run full test suite: `bundle exec rspec`
13. Run linter: `bundle exec rubocop -a`
14. Delete original files after verifying everything works
15. Verify 90%+ coverage maintained
