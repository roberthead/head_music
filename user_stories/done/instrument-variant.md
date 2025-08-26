## Instrument Variant Refactoring

### Background
The current architecture conflates instrument catalog data with specific instrument instances. We need to separate these concerns to better represent how instruments are actually used in musical scores.

### Hierarchy
The refactored hierarchy will provide three levels of abstraction:
- **InstrumentFamily** (existing): Broad category like "saxophone" or "trumpet"
- **InstrumentType** (renamed from Instrument): Catalog entry with all possible variants (e.g., "trumpet" which can be in Bb, C, D, Eb)
- **Instrument** (new): Specific instance with selected variant (e.g., "Trumpet in C")

### User Stories

**STORY 1: Rename Instrument to InstrumentType**
AS a developer
WHEN I want to access instrument catalog data
I WANT to use InstrumentType.get("trumpet")
SO THAT it's clear I'm getting a type definition, not a specific instrument instance

**STORY 2: Create new Instrument class for specific variants**
AS a developer
WHEN I need a specific instrument for a score
I WANT to call Instrument.get("trumpet_in_c") or Instrument.get("trumpet", "in_c")
SO THAT I get a specific, usable instrument instance with proper transposition

**STORY 3: Instrument instances are sortable**
AS a developer
WHEN I have multiple Instrument instances in a score
I WANT them to sort properly by orchestral order and transposition
SO THAT "Trumpet in Eb" appears before "Trumpet in C" in the score

**STORY 4: Clear API for common use cases**
AS a developer
WHEN I create an Instrument without specifying a variant
I WANT to get the default variant automatically
SO THAT Instrument.get("clarinet") returns a Bb clarinet (the default)

**STORY 5: Instrument provides unified interface**
AS a developer
WHEN I have an Instrument instance
I WANT to access properties like name, transposition, clefs, and pitch_designation
SO THAT I don't need to navigate between instrument type and variant objects

### Implementation Notes

1. The Instrument class should:
   - Wrap both an InstrumentType and a specific Variant
   - Generate appropriate display names (e.g., "Clarinet in A")
   - Provide methods for transposition, clefs, staff schemes
   - Be directly usable in scores and parts

2. Factory methods should support:
   - `Instrument.get("trumpet_in_c")` - parse variant from name
   - `Instrument.get("trumpet", "in_c")` - explicit variant
   - `Instrument.get("trumpet")` - use default variant

3. ScoreOrder should work with Instrument instances directly

### Migration Path

1. Rename existing Instrument class to InstrumentType
2. Update all references to use InstrumentType where appropriate
3. Create new Instrument class for variant instances
4. Update ScoreOrder to work with new Instrument instances
5. Update documentation and tests
