# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HeadMusic is a Ruby gem for Western music theory. It provides a comprehensive toolkit for working with pitches, scales, intervals, chords, and musical analysis. The gem supports internationalization with translations in 7 languages.

## Development Commands

### Essential Commands

```bash
# Install dependencies
bin/setup

# Run tests with coverage
bundle exec rake

# Run tests without coverage
bundle exec rspec

# Run a specific test file
bundle exec rspec spec/head_music/rudiments/pitch_spec.rb

# Run linting
bundle exec rubocop

# Run all quality checks (tests, linting, security)
bundle exec rake quality

# Open interactive console with gem loaded
bin/console
# or
bundle exec rake console

# Generate documentation
bundle exec rake doc

# Check documentation coverage
bundle exec rake doc_stats
```

### Git Etiquette

**IMPORTANT: Do not make a commit unless I explicitly ask you to.** Wait for explicit instruction before running `git commit`.

When composing git commit messages, follow best-practices. However, do not mention yourself (claude) or list yourself as a co-author.

This project uses a rebase flow and `main` as the mainline branch.

### Code Style, Linting, and Formatting

The project uses Standard Ruby for style enforcement. Always run linting after editing and before committing.

```bash
bundle exec rubocop -a
```

Always strip trailing whitespace from all lines being added or edited. Always include a blank line at the end of each file.

Do not use an assignment inside a condition.

### Testing

Tests are written in RSpec and located in the `/spec` directory, mirroring the `/lib` structure. The project requires 90% code coverage minimum.

## Architecture

### Module Structure

The codebase follows a domain-driven design with clear module boundaries:

1. **HeadMusic::Rudiment** - Core music theory elements
  - Abstract concepts: pitch, interval, scale, chord, key
  - Duration concepts (without visual representation)
  - Factory methods: `.get()` for most rudiments

2. **HeadMusic::Notation** - Visual music notation and representation
  - Staff positions, lines, spaces, ledger lines
  - Musical symbols (ASCII, Unicode, HTML entities)
  - Clef placement and rendering
  - Notehead shapes, stems, flags, beams
  - Accidental placement rules
  - Future: ties, slurs, articulations, dynamics

3. **HeadMusic::Instruments** - Instrument definitions
  - Instrument families and classification
  - Pitch ranges and transposition
  - Playing techniques
  - Score ordering

4. **HeadMusic::Content** - Musical composition representation
  - Compositions, voices, bars, positions
  - Notes in context (pitch + duration + placement)
  - Temporal organization

5. **HeadMusic::Analysis** - Musical analysis tools
  - Intervals, chords, motion analysis
  - Harmonic and melodic analysis
  - Pitch class sets and collections

6. **HeadMusic::Style** - Composition rules and guidelines
  - Counterpoint rules
  - Voice leading guidelines
  - Style analysis

### Key Design Patterns

- **Factory Pattern**: Most musical objects use `.get()` factory methods
- **Value Objects**: Immutable objects for musical concepts
- **Named Mixin**: Provides internationalization support
- **Delegation**: Extensive use of delegation for clean APIs

### Entry Points

- Main file: `lib/head_music.rb`
- Module loading order is important and defined in the main file
- Constants like GOLDEN_RATIO are defined at the top level

## Important Implementation Details

### Internationalization

The gem supports multiple languages through the HeadMusic::Named mixin:
- Translations in `lib/head_music/locales/`
- Languages: en, de, es, fr, it, ja, nl
- Use `I18n.locale = :de` to change language

### Testing Patterns

- Use `described_class` instead of hardcoding class names
- Test files must end with `_spec.rb`
- Shared examples in `spec/support/`
- `composition_context.rb` provides test utilities

### Documentation Philosophy

This project deliberately deprioritizes formal documentation in favor of clear, comprehensive tests.

- **Tests serve as documentation**: RSpec specs demonstrate how to use the code
- **Comments explain "why", not "what"**: Only add comments when the implementation is surprising or non-obvious
- **No YARD documentation required**: The code should be self-explanatory through clear naming and test examples
- Documentation tools like `rake doc` and `rake doc_stats` exist but low coverage is intentional

### Code Style

- Ruby 3.3.0+ features are allowed
- Follow Standard Ruby style guide
- Prefer delegation over inheritance
- Always run `bundle exec rubocop -a` after editing ruby code

## Common Development Tasks

### Adding a New Musical Concept

1. Create the class in the appropriate module
2. Include `HeadMusic::Named` if it needs internationalization
3. Add factory method `.get()` if appropriate
4. Create corresponding spec file
5. Add translations to locale files if using Named

### Modifying Existing Classes

1. Check for dependent classes that might be affected
2. Run tests for the specific module: `bundle exec rspec spec/head_music/[module_name]`
3. Ensure translations are updated if names change

## Music theory and concepts

Please refer to MUSIC_THEORY.md for music theory domain knowledge.
