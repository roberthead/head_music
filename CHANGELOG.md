# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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