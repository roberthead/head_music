## User Story: Load Playing Techniques from YAML Data File

**As a** client of the HeadMusic gem

**I want** access to a comprehensive catalog of playing techniques across all instrument families

**So that** I can notate and work with playing techniques for strings, winds, harp, keyboard, and percussion—not just drum kit techniques

### Background

The current `PlayingTechnique` class uses a hardcoded `TECHNIQUES` constant containing only 14 percussion-focused techniques (stick, pedal, mallet, hand, brush, rim_shot, cross_stick, open, closed, damped, let_ring, choked, bow, bell).

A new `playing_techniques.yml` data file has been created with 50+ techniques organized by scope (common, strings, winds, percussion, harp, keyboard), including:

- **Common techniques**: legato, marcato, vibrato, con sordino, naturale, ordinario
- **String/wind techniques**: harmonics, bowing techniques
- **Percussion techniques**: rim shots, cross sticks, dead strokes, motor on/off
- **Harp techniques**: près de la table
- **Rich metadata**: origin language, meaning, notation variants

The YAML-driven approach aligns with how other HeadMusic components work (instruments, clefs, scales, etc.) and enables future extensibility.

### Acceptance Criteria

- [ ] `PlayingTechnique.all` returns techniques loaded from `playing_techniques.yml`
- [ ] The `TECHNIQUES` constant is removed
- [ ] Each technique retains access to its metadata (scopes, origin, meaning, notations)
- [ ] `PlayingTechnique.get(identifier)` continues to work for any technique in the YAML
- [ ] New accessor methods for metadata: `#scopes`, `#origin`, `#meaning`, `#notations`
- [ ] Techniques can be filtered by scope (e.g., `PlayingTechnique.for_scope(:strings)`)
- [ ] Existing specs pass; new specs cover the expanded technique catalog
- [ ] Maintains 90%+ test coverage

### Technical Notes

- Follow the existing YAML-loading pattern used by `Instrument`, `Clef`, and other data-driven classes
- The `HeadMusic::Named` mixin is already included, enabling future i18n support
- Consider caching loaded techniques for performance (consistent with other HeadMusic patterns)
