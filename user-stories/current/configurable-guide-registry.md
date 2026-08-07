<!--
metadata:
  created_at:   2026-08-07T11:17:52-07:00
  activated_at: 2026-08-07T11:23:23-07:00
  planned_at:
  finished_at:
  updated_at:   2026-08-07T11:23:23-07:00
-->

# Story: Configurable Guide Registry

## Summary

AS an application embedding HeadMusic to evaluate exercises

I WANT to look up a style guide by name and configure it with options, rather than referencing a Ruby constant for every variation

SO THAT new evaluated exercises can be authored from data without a gem release, and so that guide metadata lives in the theory library instead of being duplicated by every consumer

## Background

Guides are currently the only layer of the style system with no configurability and no lookup. `Guides::Base.analyze(voice)` maps a frozen `RULESET` constant, and every variation of a ruleset is a separate subclass referenced by constant.

The cost shows up in consumers. BardTheory, which grades student exercises through `HeadMusic::Style::Analysis`, has accumulated four hashes that exist only to work around the missing seam:

- `MelodicAnalysisService::CONTOUR_GUIDES` — a six-entry map from a config string to a constant, one per contour guide.
- `CounterpointAnalysisService::GUIDES_BY_SPECIES` — species number to a `[melody, harmony]` constant pair.
- `CounterpointAnalysisService::GUIDE_CATEGORIES` — a hardcoded `GuideClass => "melody" | "harmony"` map. This is metadata *about* HeadMusic's guides that HeadMusic does not expose, so the consumer reconstructs it by hand and must edit it whenever a guide is added.
- `CounterpointAnalysisService::PENDING_GUIDES_BY_SPECIES` and `PENDING_GUIDE_CATEGORIES` — a shadow registry of guides that do not exist in the gem yet, referenced by string and resolved through `const_defined?` guards. This is the clearest symptom: an exercise could not be authored until the gem shipped a matching class, so the consumer built a waiting room for guides it hopes will arrive.

Adding one guide today means a gem PR, a release, a version bump in the consumer, and edits to two or three hashes there.

**The prior decision this revisits.** The `melody-contour-guides` story (2026-07-05) deliberately put configurability at the guideline layer and kept guides as named classes, recording: *"contour is a single closed axis with six values — revisit guide-level `.with` only if a second orthogonal configuration axis appears."* That axis has since appeared. `Guides::DiatonicMelody.contour_ruleset` now takes `minimum_melodic_intervals:` alongside the contour key, and the six guides differ only in a symbol and an integer:

```ruby
RULESET = contour_ruleset(:arch, minimum_melodic_intervals: 2)
```

The deferral condition is met, so the decision is due for revisiting.

## Current State

- `Guides::Base.analyze(voice)` — a class method over `self::RULESET`; no instance state, no options, no name, no category.
- Ruleset builders parameterize at class-definition time only: `DiatonicMelody.contour_ruleset(contour_key, minimum_melodic_intervals:)`, `SpeciesMelody.moving_species_ruleset(*additional)`, `SpeciesHarmony.diminution_ruleset(*additional)`. The result is baked into a frozen constant; callers cannot vary it.
- No registry: guides are reachable only as constants or via `Guides.const_get(name)`.
- The guideline layer already solves the analogous problem. `Annotation.with(**options)` returns an `Annotation::Configured` that duck-types as a class by responding to `#new(voice)`, and `Contoured`, `MinimumThreshold`, and `MaximumNotes` override `.with` to accept a positional argument.
- The seam exists at the guide layer too: `Style::Analysis#initialize(guide, voice)` only ever calls `guide.analyze(voice)`, so any object responding to `analyze(voice)` already works — exactly parallel to how `Configured` satisfies `new(voice)`.

## Design direction

Two changes that compose. Neither alters how a ruleset is evaluated.

### Guide metadata and registry

Every guide gains identity: a `key` (snake_case of the demodulized class name by default), a `category` (`:melody` or `:harmony`), and a human-readable name suitable for the existing `Named`/i18n treatment.

A `HeadMusic::Style::Guide.get(key)` factory, matching the gem's established `.get()` idiom, resolves a key to a guide. A miss is a graceful lookup failure, not a `NameError`, so a consumer can ask for a guide that does not exist yet and get a usable answer.

This alone retires all four BardTheory hashes: guides become strings in exercise configuration, and `category_for(guide)` becomes `guide.category`.

### Configurable guides

A `Guides::Configured` wrapper mirroring `Annotation::Configured`: it holds a guide class plus options and responds to `analyze(voice)`, so `Style::Analysis` needs no change.

`Guides::Base.with(**options)` returns one. The six contour guides collapse into a single `ContourMelody`:

```ruby
ContourMelody.with(contour: :arch, minimum_melodic_intervals: 2)
```

The two mechanisms compose, and that is what makes this safe: **registry entries may be either a guide class or a preconfigured guide.** `Guide.get("arch_contour_melody")` continues to resolve, returning `ContourMelody.with(contour: :arch, minimum_melodic_intervals: 2)`. The six contour names survive as names even though they stop being classes, so consumers referring to them by key are unaffected.

### What stays a class

The species and cantus firmus guides remain named classes. `FirstSpeciesHarmony` is a citation of Fux, not a lesson plan — it should be a stable, spec'd, referenceable thing in the theory library, and it should be hard to change casually. The distinction this story draws: **a ruleset attributable to a published tradition is a class; a ruleset that encodes a pedagogical choice is a configuration.** Contour targets are the latter.

## Acceptance Criteria

- Every guide exposes `key`, `category`, and a display name; `category` returns `:melody` or `:harmony` for all existing guides.
- `HeadMusic::Style::Guide.get(key)` resolves a guide by string or symbol key; an unknown key returns `nil` rather than raising.
- `Guides::Configured` responds to `analyze(voice)` and is accepted by `Style::Analysis` with no change to `Analysis`.
- `Guides::Base.with(**options)` returns a `Guides::Configured`; layering `.with` merges options without dropping prior ones, matching `Annotation::Configured#with`.
- A single `ContourMelody` guide replaces the six contour subclasses, configured by `contour:` and `minimum_melodic_intervals:`.
- All six contour keys remain resolvable through `Guide.get`, each producing a ruleset identical to today's corresponding class.
- An invalid contour key raises at configuration time, preserving the current fail-fast behavior of `Contoured.with`.
- The species, cantus firmus, and combined-species guides remain named classes and keep their current keys.
- Existing style specs pass unchanged in behavior; coverage stays at or above 90% and rubocop is clean.

## Scenario: A guide is resolved by name

Given the key `"first_species_harmony"`

When it is passed to `HeadMusic::Style::Guide.get`

Then the `FirstSpeciesHarmony` guide is returned

And its `category` is `:harmony`

And when an unrecognized key is passed

Then `nil` is returned and no exception is raised

## Scenario: A contour guide is configured rather than subclassed

Given `ContourMelody.with(contour: :arch, minimum_melodic_intervals: 2)`

When a melody is analyzed against it

Then the annotations and fitness match those produced by the current `ArchContourMelody` class

## Scenario: Contour guide keys survive the collapse

Given the key `"wave_contour_melody"`

When it is passed to `HeadMusic::Style::Guide.get`

Then a configured `ContourMelody` for the wave contour is returned

And analyzing a melody against it matches the current `WaveContourMelody` behavior

## Scenario: A configured guide drops into Analysis unchanged

Given a configured guide and a voice

When `HeadMusic::Style::Analysis.new(guide, voice)` is constructed

Then `#annotations` and `#fitness` behave exactly as they do for a guide class

## Scenario: An invalid configuration fails fast

Given a contour key not in `Contoured::CONTOURS`

When a contour guide is configured with it

Then an `ArgumentError` is raised at configuration time

## Notes

- **Peer-weight timing is the main implementation subtlety.** `DiatonicMelody.contour_ruleset` partitions `RULESET` into gates and peers and divides `CONTOUR_PEER_WEIGHT_BUDGET` across the peers at class-definition time. Under a configured guide the ruleset is not known until options are supplied, so that computation moves to resolution time and should be memoized per option set. The weighting invariant must be preserved: `Contoured` at its default weight of `phi^-1` plus the peer budget of `phi^-2` sums to 1, so a wrong contour on an otherwise perfect line grades exactly `phi^-1`.
- Check for direct constant references to the six contour classes in specs before removing them; the `melody_contour_guides` specs assert RULESET membership.
- Consider whether `moving_species_ruleset` and `diminution_ruleset` should also become resolution-time, or stay as class-definition-time builders. They take guideline lists rather than scalars, so they are a weaker case for this treatment.
- Guide `category` may want to be richer than `:melody | :harmony` eventually (rhythm, form). Modeling it as an open symbol rather than a boolean keeps that door open.

## Non-goals

- **Consumer-composed rulesets.** Letting an application assemble an arbitrary guideline list (`[[guideline_name, options], ...]`) would make any exercise authorable with no gem change, but it moves the coupling down to roughly sixty guideline names and their option shapes — a larger and more volatile surface than the guide layer — and it lets canonical Fux rulesets drift into application code. Revisit only if exercises appear whose rules correspond to no tradition.
- **Moving guides into consumer applications.** Treating `Guides::Base` and the guideline constants as a subclassing API for host apps couples them to gem internals and takes those rulesets out of the gem's test suite.
- **Grading reproducibility.** Pinning a submission's score to the ruleset it was graded against is a real concern — a gem bump currently regrades silently — but it belongs to the consumer's data model, not to this story. Exposing stable guide keys is a precondition for solving it there.

## Implementation Plan

[to be filled in by /stories plan]
