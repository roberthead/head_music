# Notation Module Foundation

AS a developer

I WANT a dedicated HeadMusic::Notation module structure

SO THAT I have a clear, organized place for notation-related features separate from music theory, instrument properties, and musical content

## Background

The HeadMusic gem currently organizes code into four main modules:
- **Rudiment** - Abstract music theory concepts (pitch, interval, scale, chord)
- **Instruments** - Instrument properties (range, transposition, families)
- **Content** - Musical compositions and temporal organization
- **Analysis** - Music analysis tools

However, there's no dedicated module for visual notation or representational concerns. Notation-related code is scattered across Instruments and Rudiment, making it unclear where notation features should live.

A TODO comment in `lib/head_music/instruments/staff_position.rb:5` suggests creating a HeadMusic::Notation module. Before moving any classes, we need the foundational infrastructure in place.

## Scenario: Loading the notation module

Given the HeadMusic gem is loaded

When I require 'head_music'

Then the HeadMusic::Notation module should be available

And it should not break any existing functionality

## Scenario: Documenting module boundaries

Given a developer wants to add notation features

When they consult CLAUDE.md

Then they should see clear guidance on what belongs in Notation vs Rudiment vs Instruments vs Content

## Technical Notes

### Module Boundaries

**HeadMusic::Notation** (visual representation):
- Staff positions, lines, spaces, ledger lines
- Musical symbols (ASCII, Unicode, HTML entities)
- Clef placement and rendering
- Notehead shapes, stems, flags, beams
- Accidental placement rules
- Future: ties, slurs, articulations, dynamics

**HeadMusic::Rudiment** (music theory):
- Abstract concepts: pitch, interval, scale, chord
- Duration concepts (without visual representation)
- Keys, meters (as musical concepts)

**HeadMusic::Instruments** (instrument properties):
- Instrument families and classification
- Pitch ranges and transposition
- Playing techniques
- Score ordering

**HeadMusic::Content** (musical content):
- Compositions, voices, bars
- Notes in context (pitch + duration + placement)
- Temporal organization

### Implementation

Create minimal module infrastructure:

**File: `lib/head_music/notation.rb`**
```ruby
# A module for visual music notation
module HeadMusic::Notation; end

# Load notation classes
# (Initially empty - classes will be added in subsequent stories)
```

**Update: `lib/head_music.rb`**
```ruby
# Add after Content module loading:
require "head_music/notation"
```

**Update: `CLAUDE.md`**
Add section documenting the Notation module and its boundaries.

## Acceptance Criteria

- [ ] `lib/head_music/notation/` directory exists
- [ ] `lib/head_music/notation.rb` file exists and defines module
- [ ] `lib/head_music.rb` requires the notation module
- [ ] `HeadMusic::Notation` module is accessible after requiring 'head_music'
- [ ] All existing tests pass without modification
- [ ] Maintains 90%+ test coverage
- [ ] CLAUDE.md updated with Notation module boundaries
- [ ] No existing functionality broken

## Implementation Notes

This is pure infrastructure - no classes are moved or created yet. This provides the foundation for subsequent stories that will move StaffPosition, MusicalSymbol, and StaffMapping into the Notation module.
