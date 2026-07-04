# EPIC: Notation Module

AS a developer

I WANT to organize notation-related features in a dedicated HeadMusic::Notation module

SO THAT I can clearly separate visual representation concerns from music theory, instrument properties, and musical content

## Vision

Music notation is about visual representation - how musical concepts appear on paper, screen, or other media. This is conceptually distinct from:
- **Music theory** (abstract concepts like pitch, interval, harmony)
- **Instrument properties** (range, transposition, acoustic characteristics)
- **Musical content** (compositions, temporal organization)

A dedicated Notation module provides a clear home for all visual representation concerns, making the codebase more organized and enabling future expansion into comprehensive music engraving capabilities.

## Background

Currently, notation-related code is scattered across multiple modules:
- **HeadMusic::Instruments** contains `StaffPosition`, `Staff`, `StaffMapping`, and `StaffScheme`
- **HeadMusic::Rudiment** contains `Clef`, `MusicalSymbol`, and notation aspects of `Alteration` and `RhythmicUnit`
- **HeadMusic::Content** has its own minimal `Staff` class

A TODO comment in `lib/head_music/instruments/staff_position.rb:5` suggests: "consider moving to a HeadMusic::Notation module"

This scattered organization makes it unclear where new notation features should live and conflates distinct concerns.

## Module Boundaries

### HeadMusic::Notation (visual representation)
- Staff positions, lines, spaces, ledger lines
- Musical symbols (ASCII, Unicode, HTML entities)
- Notehead shapes and placement on staff
- Stem direction and flags
- Clef symbols and their staff placement
- Accidental symbol placement
- Future: beaming, ties, slurs, articulations, dynamics

### HeadMusic::Rudiment (music theory)
- Abstract concepts: pitch, interval, scale, chord
- Duration concepts (without visual representation)
- Keys, meters (as musical concepts, not visual symbols)
- Core theory that notation represents visually

### HeadMusic::Instruments (instrument properties)
- Instrument families and classification
- Pitch ranges and transposition
- Playing techniques
- Score ordering
- References to default clef (but doesn't own clef rendering)

### HeadMusic::Content (musical content)
- Compositions, voices, bars
- Notes in context (pitch + duration + placement)
- Temporal organization
- Uses Notation for visual representation

## Scope

### Phase 1: Foundation & Core Moves (Current Focus)
- Establish module infrastructure
- Move `StaffPosition` from Instruments to Notation
- Move `MusicalSymbol` from Rudiment to Notation
- Move `StaffMapping` from Instruments to Notation

**User Stories:**
- [Notation Module Foundation](../backlog/notation-module-foundation.md)
- [Move StaffPosition to Notation](../backlog/move-staff-position-to-notation.md)
- [Move MusicalSymbol to Notation](../backlog/move-musical-symbol-to-notation.md)
- [Move StaffMapping to Notation](../backlog/move-staff-mapping-to-notation.md)

### Phase 2: Extract Notation Aspects (Future)
- Create `ClefPlacement` - extract visual clef positioning from `Rudiment::Clef`
- Create `AccidentalPlacement` - extract accidental display rules from `Rudiment::Alteration`
- Create `RhythmicNotation` - extract notehead, stem, flag logic from `Rudiment::RhythmicUnit`
- Refactor `StaffScheme` to `Notation::StaffSystem`

### Phase 3: Advanced Notation Features (Long-term Vision)
- Beaming (connecting note stems across beats)
- Stems (direction and length calculation)
- Ties (connecting same pitches across bars)
- Slurs (phrase markings)
- Articulations (staccato, accent, tenuto, etc.)
- Dynamics (forte, piano, crescendo, etc.)
- Tuplets (triplets, quintuplets, etc.)
- Barlines (single, double, repeat)
- Ornaments (trills, mordents, turns)
- Fermatas (pause markings)

### Beyond Western Staff Notation (Future Exploration)

The Notation module could eventually support multiple notation systems:

**Traditional notation systems:**
- Western staff notation (current focus)
- Tablature (tab) - finger positions for guitar, bass, lute
- Shaped note notation - different note head shapes for scale degrees
- Drum notation - modified staff notation for percussion

**Alphanumeric and shorthand systems:**
- Lead sheet notation - melody with chord symbols
- Nashville Number System - scale degrees instead of chord names
- Roman numeral analysis - functional harmony labels
- ABC notation - text-based system for folk music
- Figured bass - Baroque-era interval shorthand

**Digital/computer formats:**
- MIDI - note events with pitch, velocity, timing
- MusicXML - XML-based interchange format
- Lilypond - text-based music engraving
- MEI (Music Encoding Initiative) - scholarly encoding

## Success Criteria

**Module Organization:**
- Clear separation between theory (Rudiment), notation (Notation), instruments (Instruments), and content (Content)
- All visual representation concerns organized under `HeadMusic::Notation`
- Documentation clearly explains what belongs in each module

**Code Quality:**
- All moved classes maintain existing functionality
- 90%+ test coverage maintained throughout
- No breaking changes for internal usage
- All TODO comments resolved

**Extensibility:**
- Module designed for future expansion (beams, ties, dynamics, etc.)
- Support for multiple output formats (Unicode, MusicXML, SVG)
- Clear patterns established for adding new notation features

**Developer Experience:**
- Clear guidance in CLAUDE.md about where notation features belong
- Easy to find and use notation-related classes
- Logical organization that matches mental model of music notation
