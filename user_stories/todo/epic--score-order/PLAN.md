# Score-Order Epic: Product Manager notes

## Executive Summary

The score-order feature addresses a fundamental need in music composition software - automatically organizing instruments in standardized score orders based on ensemble type. This is critical for professional composers and arrangers who need their scores to follow industry conventions.

## Value Proposition

- **Saves time**: Composers won't need to manually reorder instruments
- **Ensures accuracy**: Follows established conventions automatically
- **Flexibility**: Supports multiple ensemble types (orchestral, band, chamber)
- **Professional output**: Scores will meet industry standards

## Priority Recommendations

### Phase 1: Orchestral Order (MVP)
- Most complex and widely used
- Clear, established conventions
- Highest value for professional users

### Phase 2: Band Support
- Different enough to showcase flexibility
- Strong user base in educational settings
- Notable percussion placement differences

### Phase 3: Chamber Ensembles
- More specialized use cases
- Could potentially be template-based

## Technical Implementation Approach

### Architecture Insights

The existing Instruments module already provides:
- `orchestra_section_key` (woodwind, brass, percussion, string, keyboard, voice)
- Instrument families with proper classification
- Good foundation but NO ordering logic yet

### Proposed Implementation

Create a standalone **`HeadMusic::Instruments::ScoreOrder`** class that:

1. **Defines ordering rules** for different ensemble types (orchestral, band, chamber)
2. **Works with instrument instances** directly (not tied to Composition module)
3. **Supports custom overrides** while maintaining sensible defaults
4. **Handles instrument abbreviations** through existing i18n system

### Key Design Decisions

- **Keep it simple**: No complex inheritance, just a straightforward ordering system
- **Data-driven approach**: Store ordering rules in YAML like existing instrument data
- **Flexible API**: Accept arrays of instrument names/objects, return ordered list
- **Support multiple sections**: Handle both full instruments and section groupings
- **Independence**: Not dependent on Content module (which is being rewritten)

## Acceptance Criteria

### Basic Functionality
- ✅ Can order an array of instruments by orchestral convention
- ✅ Can order an array of instruments by band convention
- ✅ Can order an array of instruments by chamber ensemble type
- ✅ Returns instruments in correct family/section groupings

### Flexibility
- ✅ Handles unknown instruments gracefully (append at end)
- ✅ Supports both instrument objects and string names as input
- ✅ Allows custom ordering overrides

### Integration
- ✅ Works independently of Content module
- ✅ Follows existing HeadMusic patterns (`.get()` factory method)
- ✅ Maintains 90%+ test coverage

### Performance
- ✅ Orders 100+ instruments in < 100ms
- ✅ Caches ordering rules efficiently

## MVP Scope

Start with orchestral ordering only:

```ruby
instruments = ["violin", "trumpet", "flute", "timpani", "cello"]
ordered = HeadMusic::Instruments::ScoreOrder.orchestral(instruments)
# => ["flute", "trumpet", "timpani", "violin", "cello"]
```

## Detailed Orchestral Order

Standard orchestral score order from top to bottom:

1. **Woodwinds**
   - Piccolo
   - Flutes (I, II, III)
   - Oboes (I, II, III)
   - English Horn
   - Clarinets (I, II, III)
   - Bass Clarinet
   - Bassoons (I, II, III)
   - Contrabassoon

2. **Brass**
   - Horns (I, II, III, IV)
   - Trumpets (I, II, III)
   - Trombones (I, II, III)
   - Tuba

3. **Percussion**
   - Timpani
   - Percussion (various)

4. **Keyboards & Harp**
   - Harp
   - Piano
   - Celesta
   - Organ

5. **Soloists** (if any)
   - Instrumental soloists
   - Vocal soloists

6. **Voices** (if any)
   - Soprano
   - Alto
   - Tenor
   - Bass

7. **Strings**
   - Violin I
   - Violin II
   - Viola
   - Cello
   - Double Bass

## Success Metrics

- Can correctly order any standard ensemble
- Supports custom overrides when needed
- Integrates smoothly with existing Instrument class
- Maintains 90%+ test coverage
- Performance: < 100ms for typical ensemble sizes

## Implementation Steps

1. Create `HeadMusic::Instruments::ScoreOrder` class
2. Define YAML structure for ordering rules
3. Implement orchestral ordering logic
4. Add comprehensive test coverage
5. Add band ordering support
6. Add chamber ensemble templates
7. Document API and usage examples
8. Consider future integration points with notation systems