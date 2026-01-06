# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [11.0.0] - 2026-01-05

### Changed
- **BREAKING**: Widened ActiveSupport dependency from `~> 7.0` to `>= 7.0, < 10` to support Rails 8.x
- Improved I18n initialization to be non-destructive:
  - No longer overwrites `I18n.default_locale` (allows Rails apps to control their default)
  - Adds HeadMusic locales to `available_locales` instead of replacing them
  - Only sets fallbacks if not already configured by the application
- Updated CI workflow to test against both ActiveSupport 7.x and 8.x

### Fixed
- Fixed compatibility issue with Rails 8.1.x applications

## [10.0.0] - 2025-12-01

### Changed
- Internal release for testing

## [9.0.0] - 2025-10-24

### Added
- Added `HeadMusic::Rudiment::Pitch::Parser` for strict pitch parsing
- Added `HeadMusic::Rudiment::RhythmicValue::Parser` for rhythmic value parsing
- Both parsers provide standardized `.parse()` class method API

### Changed
- `Pitch.from_name` now uses `Pitch::Parser` internally
- `RhythmicValue.get` now uses `RhythmicValue::Parser` internally
- `Note.get` now parses "pitch rhythmic_value" strings inline without Parse module

### Removed
- **BREAKING**: Removed `HeadMusic::Parse::Pitch` class
- **BREAKING**: Removed `HeadMusic::Parse::RhythmicValue` class
- **BREAKING**: Removed `HeadMusic::Parse::RhythmicElement` class
- **BREAKING**: Removed entire `HeadMusic::Parse` module

### Migration Guide

If you were using the removed Parse classes, migrate as follows:

```ruby
# Before (v8.x)
parser = HeadMusic::Parse::Pitch.new("C#4")
pitch = parser.pitch

# After (v9.x)
pitch = HeadMusic::Rudiment::Pitch.get("C#4")
# or for strict parsing:
pitch = HeadMusic::Rudiment::Pitch::Parser.parse("C#4")
```

```ruby
# Before (v8.x)
parser = HeadMusic::Parse::RhythmicValue.new("dotted quarter")
value = parser.rhythmic_value

# After (v9.x)
value = HeadMusic::Rudiment::RhythmicValue.get("dotted quarter")
# or for strict parsing:
value = HeadMusic::Rudiment::RhythmicValue::Parser.parse("dotted quarter")
```

```ruby
# Before (v8.x)
parser = HeadMusic::Parse::RhythmicElement.new("F#4 dotted-quarter")
note = parser.note

# After (v9.x)
note = HeadMusic::Rudiment::Note.get("F#4 dotted-quarter")
```

## [8.2.1] - 2025-06-21

### Added
- Added missing modern instruments to all locales (ukulele family, electronic instruments, world instruments)
- Added pitched/unpitched instrument classifications to all non-English locales
- Added new instrument families: bass_drum, tambourine, and celesta

### Changed
- Improved instrument family classifications (added fretted/unfretted, valve categorizations)
- Removed incorrect percussion classification from harpsichord and clavichord

### Fixed
- Fixed Russian translation errors (tritone and perfect_unison)

## [8.2.0] - 2025-06-20

### Added
- Added comprehensive GitHub Actions CI/CD workflows (test matrix, security scanning, automated releases)
- Added security tooling with bundler-audit for vulnerability scanning
- Added YARD documentation generation with kramdown support
- Added SimpleCov coverage tracking with 90% threshold and branch coverage
- Added Dependabot configuration for automated dependency updates
- Added inclusive CONTRIBUTING.md with comprehensive contribution guidelines
- Added complete CHANGELOG.md tracking version history
- Added GitHub issue templates (bug reports, feature requests) and PR template
- Added gemspec metadata fields for better gem documentation and security
- Added rubygems_mfa_required for enhanced security

### Changed
- Standardized Ruby version requirement to 3.3.0 across all configuration files
- Updated and organized development dependencies (removed deprecated codeclimate-test-reporter)
- Enhanced .gitignore with modern patterns and restored Gemfile.lock tracking
- Improved RuboCop configuration (increased MultipleMemoizedHelpers max to 12)
- Enhanced Rakefile with quality, documentation, and coverage tasks

### Removed
- Removed outdated Travis CI and CircleCI configurations (replaced with GitHub Actions)

## [8.1.1] - 2024-12-20

### Changed
- Tweaked gemspec summary

## [8.1.0] - 2024-12-20

### Added
- Enhanced solmization support

### Changed
- Code cleanup and improvements
- Improved spec coverage
- Refactored melodic intervals to separate pitch and note concerns

## [8.0.2] - 2024-12-19

### Fixed
- RuboCop style fixes

### Changed
- Improved RuboCop configuration

## [8.0.0] - 2024-12-19

### Changed
- Major reorganization: moved specs into folders
- Organized models into modules for better structure
- **BREAKING**: Module structure changes may require updates to require statements

## [7.0.5] - 2024-01-20

### Changed
- Upgraded to Ruby 3.3.0
- Improvements to Spanish translations of recorder

## [7.0.4] - 2024-01-15

### Added
- Rudiment translations
- Instrument classification translations
- Interval translations

## [7.0.3] - 2024-01-10

### Added
- Russian instrument translations using Cyrillic characters
- Spanish translations for instruments

### Changed
- Uncapitalized languages in Italian and Spanish translations
- Spanish translation corrections and improvements
- Translation file cleanup

## [7.0.2] - 2023-12-15

### Changed
- Various improvements and bug fixes

## [7.0.1] - 2023-12-10

### Changed
- Minor improvements and bug fixes

## [7.0.0] - 2023-12-01

### Changed
- Major version bump indicating significant changes
- **BREAKING**: Check upgrade guide for migration instructions

## [6.0.1] - 2023-11-15

### Fixed
- Bug fixes and improvements

## [6.0.0] - 2023-11-01

### Changed
- Major architectural improvements
- **BREAKING**: API changes may require code updates

## [5.0.0] - 2023-10-15

### Changed
- Significant refactoring of core components
- **BREAKING**: Check documentation for new API

## [4.0.1] - 2023-09-20

### Fixed
- Minor bug fixes

## [4.0.0] - 2023-09-15

### Added
- Expanded instrument support
- Instrument data improvements

### Changed
- Enhanced Instrument class functionality

## [3.0.1] - 2023-08-20

### Fixed
- Minor improvements and fixes

## [3.0.0] - 2023-08-15

### Changed
- Major version update with architectural improvements
- **BREAKING**: Significant API changes

## [2.0.0] - 2023-07-01

### Changed
- Major refactoring of core functionality
- **BREAKING**: API redesign

## [1.0.0] - 2023-06-01

### Added
- First stable release
- Complete music theory rudiments implementation
- Comprehensive scale and interval support
- Basic composition and voice handling

## [0.29.0] - 2023-05-15

### Added
- Additional music theory features
- Improved documentation

## [0.28.0] - 2023-05-01

### Changed
- Performance improvements
- Code organization enhancements

## Earlier versions

For changes in versions prior to 0.28.0, please refer to the git history.

[Unreleased]: https://github.com/roberthead/head_music/compare/v8.2.0...HEAD
[8.2.0]: https://github.com/roberthead/head_music/compare/v8.1.1...v8.2.0
[8.1.1]: https://github.com/roberthead/head_music/compare/v8.1.0...v8.1.1
[8.1.0]: https://github.com/roberthead/head_music/compare/v8.0.2...v8.1.0
[8.0.2]: https://github.com/roberthead/head_music/compare/v8.0.0...v8.0.2
[8.0.0]: https://github.com/roberthead/head_music/compare/v7.0.5...v8.0.0
[7.0.5]: https://github.com/roberthead/head_music/compare/v7.0.4...v7.0.5
[7.0.4]: https://github.com/roberthead/head_music/compare/v7.0.3...v7.0.4
[7.0.3]: https://github.com/roberthead/head_music/compare/v7.0.2...v7.0.3
[7.0.2]: https://github.com/roberthead/head_music/compare/v7.0.1...v7.0.2
[7.0.1]: https://github.com/roberthead/head_music/compare/v7.0.0...v7.0.1
[7.0.0]: https://github.com/roberthead/head_music/compare/v6.0.1...v7.0.0
[6.0.1]: https://github.com/roberthead/head_music/compare/v6.0.0...v6.0.1
[6.0.0]: https://github.com/roberthead/head_music/compare/v5.0.0...v6.0.0
[5.0.0]: https://github.com/roberthead/head_music/compare/v4.0.1...v5.0.0
[4.0.1]: https://github.com/roberthead/head_music/compare/v4.0.0...v4.0.1
[4.0.0]: https://github.com/roberthead/head_music/compare/v3.0.1...v4.0.0
[3.0.1]: https://github.com/roberthead/head_music/compare/v3.0.0...v3.0.1
[3.0.0]: https://github.com/roberthead/head_music/compare/v2.0.0...v3.0.0
[2.0.0]: https://github.com/roberthead/head_music/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/roberthead/head_music/compare/v0.29.0...v1.0.0
[0.29.0]: https://github.com/roberthead/head_music/compare/v0.28.0...v0.29.0
[0.28.0]: https://github.com/roberthead/head_music/releases/tag/v0.28.0