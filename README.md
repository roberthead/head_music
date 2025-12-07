# HeadMusic

[![CI](https://github.com/roberthead/head_music/workflows/CI/badge.svg)](https://github.com/roberthead/head_music/actions)
[![Security](https://github.com/roberthead/head_music/workflows/Security/badge.svg)](https://github.com/roberthead/head_music/actions)
[![Gem Version](https://badge.fury.io/rb/head_music.svg)](https://badge.fury.io/rb/head_music)
[![Documentation](https://img.shields.io/badge/docs-yard-blue.svg)](https://rubydoc.info/gems/head_music)

The **head_music** Ruby gem provides a toolkit for working with Western music theory. Model and manipulate the fundamental elements of music including pitches, scales, key signatures, intervals, and chords.

## Features

- **Western Music Theory Fundamentals**: Work with pitches, scales, intervals, chords, and key signatures
- **Musical Analysis**: Analyze harmonic progressions, voice leading, and counterpoint
- **Style Analysis**: Rules for species counterpoint and voice leading
- **Internationalization**: Support for multiple languages (English, French, German, Italian, Russian, Spanish)
- **Instrument Modeling**: Extensive database of musical instruments with ranges and properties

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'head_music'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install head_music

## Quick Start

```ruby
require 'head_music'

# Work with pitches and intervals
pitch = HeadMusic::Rudiment::Pitch.get('C4')
higher_pitch = HeadMusic::Rudiment::Pitch.get('E4')
interval = HeadMusic::Analysis::DiatonicInterval.new(pitch, higher_pitch)
puts interval.name  # => "major third"

# Create scales
scale = HeadMusic::Rudiment::Scale.get('C', :major)
puts scale.pitches.map(&:to_s)  # => ["C4", "D4", "E4", "F4", "G4", "A4", "B4"]

# Analyze chords
pitches = %w[C4 E4 G4].map { |p| HeadMusic::Rudiment::Pitch.get(p) }
chord = HeadMusic::Analysis::PitchSet.new(pitches)
puts chord.major_triad?  # => true
```

## Documentation

- **API Documentation**: [rubydoc.info/gems/head_music](https://rubydoc.info/gems/head_music)
- **Contributing Guide**: [CONTRIBUTING.md](CONTRIBUTING.md)
- **Changelog**: [CHANGELOG.md](CHANGELOG.md)

## Requirements

- Ruby 3.3.0 or higher
- ActiveSupport 7.0+

## Development

After checking out the repo, run `bin/setup` to install dependencies.

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run tests with coverage
bundle exec rake

# Run quality checks (tests + linting + security)
bundle exec rake quality
```

### Code Quality

```bash
# Run linting
bundle exec rubocop

# Run security audit
bundle exec rake bundle:audit:check

# Generate documentation
bundle exec rake doc
```

### Available Rake Tasks

- `rake spec` - Run tests
- `rake quality` - Run tests, linting, and security audit
- `rake doc` - Generate YARD documentation
- `rake doc_stats` - Show documentation coverage statistics
- `rake coverage` - Open coverage report in browser

### Releasing a New Version

1. Update the version number in `lib/head_music/version.rb`
2. Commit the version change: `git commit -am "Bump version to X.Y.Z"`
3. Push to main: `git push origin main`
4. Release the gem:

```bash
bundle exec rake release
```

This will:
- Build the gem
- Create and push a git tag (e.g., `vX.Y.Z`)
- Push the gem to RubyGems

The git tag push also triggers a GitHub Actions workflow that creates a GitHub Release with auto-generated release notes.

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## Project Structure

```
lib/head_music/
├── analysis/          # Musical analysis tools (intervals, chords, etc.)
├── content/           # Musical content (compositions, voices, notes)
├── instruments/       # Instrument definitions and properties
├── rudiment/          # Basic music theory elements (pitches, scales, etc.)
└── style/             # Style analysis and composition rules
```

## Code of Conduct

This project is intended to be a safe, welcoming space for collaboration. Contributors are expected to adhere to our [Code of Conduct](CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Support

- **Issues**: [GitHub Issues](https://github.com/roberthead/head_music/issues)
- **Discussions**: [GitHub Discussions](https://github.com/roberthead/head_music/discussions)
- **Security**: For security issues, please email [robert.head@gmail.com](mailto:robert.head@gmail.com)
