# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [17.5.0] - 2026-07-21

### Added

- Sung text (lyrics) can be attached to the notes of a voice. `HeadMusic::Content::Placement#sing(text, verse:, hyphen_after:)` assigns a syllable to a placement, keyed by verse so a note carries at most one syllable per verse and any number of verses (`glo` on verse 1, `peace` on verse 2 of the same note). A new immutable `HeadMusic::Content::Syllable` value object stores only the minimal linguistic fact — `text`, `verse`, and a `hyphen_after` boolean marking that the word continues onto the next sung note; the MusicXML `syllabic` value (`single`/`begin`/`middle`/`end`) is derived at render time rather than stored, and a melisma is represented by the absence of a syllable on the held notes rather than a stored flag. Syllables serialize through `Placement#to_h` and round-trip through the composition hash deserializer, validated at the import boundary by `Composition::SchemaValues` (non-empty text, a positive-integer verse, and no duplicate verse per placement).
- The MusicXML writer emits a `<lyric number="N">` element as the last child of each `<note>`, on the lead note of a chord only and the attack of a tied chain only, deriving `<syllabic>` from the `hyphen_after` booleans of the syllable and its predecessor in the same verse and XML-escaping the text. Held notes of a melisma carry no `<lyric>`, matching MusicXML's continuation-by-absence. ABC `w:` lyric-line input and the MusicXML `<extend/>` melisma line remain out of scope for a future release.

## [17.4.0] - 2026-07-20

### Changed

- Internal refactoring for clarity and maintainability, with no changes to public behavior or output. Complex classes were split along their natural seams by extracting focused collaborators and value objects, each with its own spec: `MusicXML::Preflight` and `MusicXML::RenderPlan` from the MusicXML `Writer`; `Instruments::InstrumentName`, `InstrumentCatalog`, and `StaffProfile` from `Instrument`; `Analysis::ChordAnalysis` from `PitchCollection`; `Content::SoundResolver` from `Placement`; `Time::SmpteConverter` and `MusicalTimeConverter` from `Conductor`; `Composition::SchemaValues` from `HashDeserializer`; `Pitch::NaturalStep` from `Pitch`; `Voice::MelodicLine` from `Voice`; `Dyad::ChordImplication` from `Dyad`; and `ABC::Preflight` plus per-voice note-assembly moved onto `ABC::VoiceState` in the ABC parser.
- Shared value-object equality was consolidated into a `ValueEquality` mixin, and duplication was reduced across the style guides, notation writers, and rudiments.
- Nested classes that had outgrown their host files were given their own files without changing their constant paths: `Named::Locale` and `Named::LocalizedName`, `Voice::MelodicNotePair`, `Spelling::EnharmonicEquivalence`, and `Style::Annotation::Configured`.

## [17.3.0] - 2026-07-19

### Added

- The MusicXML writer emits `<beam>` elements so exported notation renders with correct beaming rather than relying on renderer-side auto-beaming (which mis-groups compound meters). Default beam groups are derived from the meter at render time — the dotted-quarter pulse for compound meters (6/8, 9/8, 12/8), the beat for simple quarter meters, and the whole bar for 3/8 — via a new `HeadMusic::Rudiment::Meter#beam_group_unit`. Grouping resolves at the notated-note level, so a tied chain beams correctly across its own noteheads, and secondary beams (sixteenths and finer) render with begin/continue/end runs plus forward/backward partial-beam hooks.
- The ABC interpreter captures authored beam grouping from inter-note spacing: adjacent notes beam together and a space breaks the beam, honored verbatim (even across a beat). This is carried on a new tri-state `HeadMusic::Content::Placement#beam_break_before` flag (`nil` = meter default, `true` = break, `false` = join) that overrides the default on output, serializes through `to_h`/`from_h`, and survives an ABC parse → render → parse round trip (the writer suppresses the space within an authored group).

## [17.2.0] - 2026-07-19

### Added

- The ABC interpreter reads explicit ties (`-`) between notes. `E3-E2` fuses into one sounding note whose rhythmic value carries the authored split (`dotted quarter tied to quarter`), overriding the resolver's greedy decomposition, and tie chains (`C2-C2-C2`) nest into a single value. A tie between notes of different pitches, a dangling tie, or a tie to a rest raises `ParseError`; a tie across a barline raises `ParseError` ("Ties across barlines are not yet supported") pending a future release.

## [17.1.0] - 2026-07-18

### Changed

- The MusicXML writer renders chord placements as stacked notes rather than raising `RenderError`: a chord emits one `<note>` per pitched sound, ordered low to high, with `<chord/>` on all but the lowest note, all sharing the placement's rhythmic value. Tied chords emit a full chord stack per tie-link. The writer still raises `RenderError` for placements containing unpitched sounds (percussion rendering lands in a future release).

## [17.0.0] - 2026-07-18

### Added

- `HeadMusic::Rudiment::UnpitchedSound` — an unpitched sound (a drum hit, a clap, a percussive knock), backed by the instruments catalog. `.get(nil)` returns the generic instrument-less sound; `.get(name_or_alias_or_instrument)` resolves through the catalog (aliases canonicalize to the instrument's name key), and pitched instruments are valid hit surfaces — a knock on a violin body is unpitched.
- Placements hold sounds: `HeadMusic::Content::Placement#sounds` is the source of truth (pitched and unpitched, mixed within one placement allowed), with `#pitches` as the pitched subset. `Voice#place` accepts pitches, unpitched sounds, instruments, or mixed arrays.
- New placement predicates: `sounded?` (any sound), `pitched?` (any pitched sound), `pitched_note?`, and `unpitched_note?`.

### Changed

- **Breaking**: serialization schema is now version 3. Placement hashes carry a `"sounds"` array instead of the `"pitches"` key — pitched sounds serialize as pitch strings (unchanged), unpitched sounds as `{"unpitched" => name_key}` objects (`null` name key for the generic sound) — and `Composition.from_h` no longer accepts schema version 2 hashes. Persisted v2 data (e.g. in a jsonb column) must be migrated by renaming each placement's `"pitches"` key to `"sounds"`; the pitch strings themselves are unchanged.
- **Breaking**: `Placement#note?` now means exactly one sound of any kind, so chords are no longer `note?`; `Placement#chord?` counts pitched sounds (two or more).
- **Breaking**: `Voice#place` raises `ArgumentError` on an unparseable value instead of quietly placing a rest.
- The ABC and MusicXML writers raise `RenderError` when asked to render an unpitched sound (unpitched rendering lands in a future release).

## [16.0.0] - 2026-07-17

### Added

- Chords in the content model: `HeadMusic::Content::Placement` holds a `pitches` array (empty for a rest, two or more for a chord) and derives `#pitch` as the highest pitch, so melodic analysis follows the top line. `Placement#chord?` distinguishes chords. `Voice#place` accepts a single pitch or an array of pitches; a chord is one rhythmic event.
- `Voice#place` merges a placement at an already-occupied position into the existing placement when the rhythmic value matches (the pitch union is duplicate-free, so re-placing a pitch is idempotent), and raises `ArgumentError` when it does not. A position within a voice holds at most one placement, enforcing structurally that simultaneous pitches with distinct durations belong in separate voices.

### Changed

- **Breaking**: serialization schema is now version 2. Placement hashes carry a `"pitches"` array instead of the singular `"pitch"` key (rests serialize as `"pitches" => []`), and `Composition.from_h` no longer accepts schema version 1 hashes.
- **Breaking**: `Placement#pitch` is a derived reader (highest of `pitches`, `nil` for a rest) rather than a stored attribute, and `Placement#note?` returns a boolean rather than the pitch object.
- The ABC and MusicXML writers raise `RenderError` when asked to render a chord placement (chord rendering lands in a future release) rather than silently emitting only the top pitch.

## [15.2.0] - 2026-07-16

### Added

- `HeadMusic::Content::Composition#to_h` / `.from_h` — lossless, JSON-safe hash serialization of a composition (schema_version 1). The hash captures name, key signature, meter, composer, origin, voices with roles and ordered placements (tick-precise positions, rhythmic values including ties, exact pitch spellings, rests as `null`), sparse per-bar state (mid-piece key and meter changes, repeat and volta structure), and comments. `from_h` rebuilds through the public builder API and raises `ArgumentError` with path context on malformed input; unknown keys are ignored so the format can evolve additively.
- `HeadMusic::Content::Composition#to_json` / `.from_json` — thin delegates over `to_h`/`from_h`.
- `#to_h` on `Content::Voice`, `Content::Placement`, `Content::Bar`, and `Content::Comment`.

**Schema v1 is a compatibility surface**: hashes persisted by downstream apps (e.g. in a jsonb column) must keep loading. Additive optional keys are fine within version 1; any change to existing keys' shape or meaning requires a `schema_version` bump.

### Fixed

- `RhythmicValue.get` now parses tied value strings ("half tied to eighth", including chained ties), so tied durations round-trip through `#to_s`.
- `Bar#key_signature=` and `Bar#meter=` coerce strings via `KeySignature.get` / `Meter.get`, so `change_meter(4, "6/8")` no longer stores a raw String.
- `Voice` placement ordering is now stable: notes placed at the same position (chords) keep their insertion order.
- `Composition#change_key_signature` / `#change_meter` no longer raise for a bar earlier than the first placement (e.g. a pickup bar).

## [15.1.0] - 2026-07-07

### Added

- `HeadMusic::Content::Composition.to_musicxml` for MusicXML export
- `HeadMusic::Content::Composition.to_abc` for ABC Notation export. ABC can round-trip to and from Composition.

## [15.0.0] - 2026-07-06

### Added

- `HeadMusic::Style::Guidelines::MinimumMelodicIntervals` — a sufficiency gate on the number of moving melodic intervals, so a line that never (or barely) moves reads as a non-attempt rather than a flawed melody (`MinimumMelodicIntervals.with(2)`). The contour guides use it; `StaticContourMelody` omits it so a repeated single pitch remains a legitimate static contour.
- `weight:` and `gate:` options on `Annotation.with` — any ruleset entry can now carry a rubric weight or be marked as a gate, and `Configured#with` layers options so presets compose (e.g. `MinimumNotes.with(5).with(gate: true)`)

### Changed

- **Breaking:** `Analysis#fitness` is now a gated weighted rubric instead of an unweighted geometric mean: the product of the gate fitnesses multiplies a weighted arithmetic mean of the remaining (rubric) rules. Every fitness value shifts numerically; downstream consumers that compare grades against stored thresholds must recalibrate.
- Non-attempts now grade zero: sufficiency guidelines (`MinimumNotes`, `MinimumMelodicIntervals`) act as graded gate multipliers, so an empty or insufficient line scales the whole grade down to 0 instead of averaging against the other rules.
- Contour guides weight `Contoured` at the inverse golden ratio (φ⁻¹ ≈ 0.618) with their ten rubric peers sharing φ⁻² evenly, so a wrong-contour but otherwise perfect line grades exactly ~0.618 (`HeadMusic::GOLDEN_RATIO_INVERSE`)
- `Diatonic` and `MaximumNotes` are rate-normalized (fitness raised to 1/note-count), so grades are length-invariant: the same violation rate scores the same in an eight-note line as in a sixteen-note line
- Broken-but-real work now lands on a deliberate soft floor (roughly 0.3–0.55): rate-normalized rules bottom out near φ⁻¹ and the arithmetic mean averages them, so a gate-passing melody that breaks most of the rubric grades substantially below perfect without collapsing toward the gated zero of a non-attempt

## [14.0.0] - 2026-07-05

### Added

- `HeadMusic::Style::Guidelines::Contoured` — configurable guideline judging a melody against a chosen contour (`Contoured.with(:arch)` and five other keys: `ascending`, `descending`, `valley`, `wave`, `static`). Predicates are trend-based rather than strictly monotonic; a wrong contour receives a single mark spanning the melody. Unknown contour keys raise `ArgumentError` at guide-definition time.
- Six contour guides subclassing `Guides::DiatonicMelody`, each appending the configured `Contoured` guideline to the inherited ruleset: `ArchContourMelody`, `AscendingContourMelody`, `DescendingContourMelody`, `StaticContourMelody`, `ValleyContourMelody`, `WaveContourMelody`
- Contour judgments deliberately complement `ConsonantClimax`: an arch requires only an interior climax pitch level, leaving climax uniqueness and consonance to the existing guideline

## [13.0.0] - 2026-07-05

### Added

- `HeadMusic::Notation::NotationStyle` — named notation traditions (`british_brass_band`, `german`, `italian`, `concert_pitch`) resolved as sparse overlays on a `default` style, backed by `notation_styles.yml`, with `.get`/`.default` factories and `#notation_for`
- `HeadMusic::Notation::InstrumentNotation` — the resolved notation value object (clef, sounding transposition, staves, and recorded register/clef alternatives) with value equality
- `Instrument#notation(style:)` — notate an instrument through a chosen notation style, defaulting to `default`

### Changed

- Notation concerns (clef, sounding transposition, staff structure) now live in `NotationStyle` instead of on the instrument. `Instrument`'s notation methods (`default_staves`, `default_clefs`, `sounding_transposition`, etc.) delegate to the default style and resolve to the same values as before.
- `Instrument#staff_schemes` now returns only the instrument's default scheme; named schemes (brass-band, German/Italian bass clarinet, and register/clef alternatives) have moved into notation styles.

### Removed

- `staff_schemes` data from `instruments.yml` and the internal `staff_schemes` plumbing on `Instrument`. Per-instrument notation conventions are now expressed as notation styles. (Breaking change — hence the major version bump.)

## [12.6.0] - 2026-07-03

### Added

- `DiatonicMelody` guide: a free diatonic melody not bound to cantus firmus start/end constraints (note-count range configurable, defaulting to 5–24)
- Configurable guidelines — a guideline can now carry configuration into a `RULESET` via `Annotation.with(...)` (wrapped in `Annotation::Configured`):
  - `MinimumNotes` / `MaximumNotes` — configurable note-count floor and ceiling (`AtLeastEightNotes` / `UpToFourteenNotes` retained as named defaults)
  - `NoteCountPerBar` — configurable `count` and `rhythmic_value` (unifies `OnePerBar`, `TwoPerBar`, `ThreePerBar`, `FourPerBar`)
  - `DirectionChanges` — configurable `maximum_notes_per_direction` (unifies `ModerateDirectionChanges` and `FrequentDirectionChanges`)
  - Configurable thresholds on `SingableRange`, `MostlyConjunct`, `LimitOctaveLeaps`, and `SecondSpeciesBreak`

### Changed

- Extracted `HeadMusic::Style::Guides::Base` for shared guide analysis behavior; `SpeciesMelody` and `SpeciesHarmony` now inherit from it
- Hoisted the guidelines common to every guide into `MELODIC_CORE` / `HARMONIC_CORE` constants on the species base classes
- `SingableRange`'s message now reflects the configured range
- Renamed the `quality` rake task to `validate`

## [12.5.0] - 2026-04-08

### Changed

- Improved fifth-species counterpoint guidelines
- Code quality improvements

### Removed

- Combined 2+3+4 species guides and their guidelines

## [12.4.0] - 2026-04-06

### Added

- Fifth-species (florid) counterpoint guides
- Standard and alternate instrument tunings

### Fixed

- Ukulele family stringings, tunings, and range data

## [12.3.0] - 2026-02-25

### Added

- Fourth-species counterpoint guides

### Changed

- Code quality pass

## [12.2.0] - 2026-02-24

### Changed

- Improved guidelines for first-bar entry

## [12.1.0] - 2026-02-24

### Changed

- Refactored species guidelines into separate first-bar, middle-bar, and final-bar rules
- Unified `FinalBarWholeNote` and `FinalBarDottedHalfNote` into `NoteFillsFinalBar`

## [12.0.1] - 2026-02-23

### Changed

- Renamed triple-meter guides

## [12.0.0] - 2026-02-21

### Added

- Third-species 3:1 guidelines
- Allow a descending minor sixth as a singable interval

### Changed

- Extracted shared base classes for guides and step-to-final-note guidelines
- Refactored third-species dissonance handling and other files to reduce code smells

## [11.8.0] - 2026-02-16

### Added

- `ThirdSpeciesMelody` and `ThirdSpeciesHarmony` guides
- `ThirdSpeciesDissonanceTreatment` guideline
- `FourToOne` guideline
- Third-species counterpoint reference document

## [11.7.0] - 2026-02-13

### Added

- Parallel-perfect check for first species

### Changed

- `Analysis#fitness` now uses the geometric mean

## [11.6.1] - 2026-02-12

### Added

- Additional test coverage for the two-to-one guideline

### Fixed

- Accept an implied rest in the first bar of second-species counterpoint

## [11.6.0] - 2026-02-10

### Added
- Second-species counterpoint style guides: `SecondSpeciesMelody` and `SecondSpeciesHarmony`
- New guidelines for second-species counterpoint:
  - `TwoToOne` — enforces two half notes per cantus firmus whole note (with optional half-rest opening)
  - `WeakBeatDissonanceTreatment` — dissonant weak beats must be passing tones
  - `NoParallelPerfectOnDownbeats` — forbids parallel perfect consonances on consecutive downbeats
  - `NoParallelPerfectAcrossBarline` — forbids parallel perfect consonances from weak beat to following downbeat
  - `NoStrongBeatUnisons` — forbids unisons on interior downbeats
- Pedagogical reference document for second-species counterpoint (`references/second-species-counterpoint.md`)

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