<!--
metadata:
  created_at:   2026-08-07T11:17:52-07:00
  activated_at: 2026-08-07T11:23:23-07:00
  planned_at:   2026-08-07T13:19:35-07:00
  finished_at:
  updated_at:   2026-08-07T15:54:54-07:00
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

This alone retires three of the four BardTheory hashes: guides become strings in exercise configuration, and `category_for(guide)` becomes `guide.category`. (Corrected during planning: `PENDING_GUIDE_CATEGORIES` survives regardless, since the category of a guide the gem does not have is unknowable *from the gem*. And `GUIDES_BY_SPECIES` is lesson-plan data that by this story's own rule belongs in the consumer's exercise rows — it becomes `guide_keys: [...]` plus `guides.group_by(&:category)` — rather than something `Guide.get` retires.)

### Configurable guides

A `Guides::Configured` wrapper mirroring `Annotation::Configured`: it holds a guide class plus options and responds to `analyze(voice)`, so `Style::Analysis` needs no change to accept it. (`Analysis` does gain one unrelated guard — see Decisions — but its analysis path is untouched.)

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
- `Guides::Configured` responds to `analyze(voice)` and is accepted by `Style::Analysis` without any change made to accommodate it — the existing `guide.analyze(voice)` call site already suffices.
- `Style::Analysis` rejects a guide that cannot answer `analyze` with a clear error naming the problem, rather than deferring to a `NoMethodError` on `nil`.
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

- ~~**Peer-weight timing is the main implementation subtlety.**~~ **Corrected during planning (2026-08-07).** This story originally assumed the peer-weight computation would have to move to resolution time and be memoized per option set. It does not. `contour_ruleset` partitions the frozen `DiatonicMelody::RULESET` and divides `CONTOUR_PEER_WEIGHT_BUDGET` across the peers, and **neither step depends on `contour` or `minimum_melodic_intervals`** — the motion gate is added *after* the partition, so it never enters the peer set. Verified empirically: `peers.length` is 10 and `peer_weight` is `phi^-2 / 10` for all six contours, and rulesets rebuilt from hoisted constants are element-for-element identical to the six shipped classes. The partition and weighting therefore stay at class-definition time as frozen constants, and no options-keyed cache is needed. The weighting invariant still must be preserved: `Contoured` at default weight `phi^-1` plus the peer budget `phi^-2` sums to 1, so a wrong contour on an otherwise perfect line grades exactly `phi^-1`.
- Check for direct constant references to the six contour classes in specs before removing them; the `melody_contour_guides` specs assert RULESET membership.
- Consider whether `moving_species_ruleset` and `diminution_ruleset` should also become resolution-time, or stay as class-definition-time builders. They take guideline lists rather than scalars, so they are a weaker case for this treatment.
- Guide `category` may want to be richer than `:melody | :harmony` eventually (rhythm, form). Modeling it as an open symbol rather than a boolean keeps that door open.

## Non-goals

- **Consumer-composed rulesets.** Letting an application assemble an arbitrary guideline list (`[[guideline_name, options], ...]`) would make any exercise authorable with no gem change, but it moves the coupling down to roughly sixty guideline names and their option shapes — a larger and more volatile surface than the guide layer — and it lets canonical Fux rulesets drift into application code. Revisit only if exercises appear whose rules correspond to no tradition.
- **Moving guides into consumer applications.** Treating `Guides::Base` and the guideline constants as a subclassing API for host apps couples them to gem internals and takes those rulesets out of the gem's test suite.
- **Grading reproducibility.** Pinning a submission's score to the ruleset it was graded against is a real concern — a gem bump currently regrades silently — but it belongs to the consumer's data model, not to this story. Exposing stable guide keys is a precondition for solving it there.

## Decisions

Resolved with the product owner (2026-08-07), closing the two open questions that blocked implementation:

- **Lookup lives at `HeadMusic::Style::Guide.get`**, spelled exactly as the acceptance criteria state. `Guides.get` is rejected as unnecessary — and it would be a module-level factory, which has no precedent here: 40 classes in the gem define `.get` and no module does. For the same reason `Style::Guide` is a **class**, matching `Tradition`, not the module the plan first proposed. It is never instantiated; `.get` returns a guide class or a `Guides::Configured`.
- **Clean break on the six removed contour classes.** No deprecated aliases, matching the `configurable-large-leap-recovery` precedent of replacing outright. This is a breaking change to the public API and **requires a major version bump: 18.0.0 → 19.0.0**. BardTheory's `MelodicAnalysisService::CONTOUR_GUIDES` breaks at `NameError` on upgrade and must move to guide keys in the same coordinated change.
- **`Style::Analysis` gains a guard.** A guide that cannot answer `analyze` must fail immediately and legibly, rather than reaching `nil.analyze` as a `NoMethodError` far from the bad key. `Guide.get` still returns `nil` on a miss (AC 2 is unchanged); the guard is what makes that miss diagnosable at the point of use. This is the one intended change to `Analysis`.
- **`DiatonicMelody` is a registry entry** with key `"diatonic_melody"`. It has its own ruleset and is a legitimate guide — a free diatonic melody with no contour target. Whether a consumer offers it for selection is the consumer's curriculum decision, not the gem's.
- **Vocabulary: this gem has guides, not exercises.** "Exercise" is BardTheory's domain term and must not leak into HeadMusic's names, comments, or specs. Where gem-side rationale needs to reference consumer impact, say so explicitly as consumer impact.
- **BardTheory migrates its stored configuration to guide keys.** `configuration.melody.target_contour` currently holds a bare contour name (`"arch"`), which is why `Guide.get("arch")` is deliberately a miss — a contour is not a guide key. The consumer migrates to `"arch_contour_melody"`. Note the surface is wider than a data migration: `target_contour` also flows through the TypeScript frontend (`TargetContour`, `melodySerialization.ts`, `exerciseDescriptor.ts`), so the consumer-side change spans seeds, stored rows, and frontend types. **Consequence for this story: the direct `ContourMelody.with(contour:)` path is a convenience, not the adoption path** — the registry lookup is what BardTheory will use.

## Implementation Plan

### Overview

Two composing additions, plus one correction to this story's stated premise.

Give `Guides::Base` a `.ruleset` indirection, a `.with` factory, and class-level identity (`key`, `category`, `display_name`). Add `Guides::Configured` — the guide-layer twin of `Annotation::Configured`, quacking as a guide by responding to `analyze(voice)` instead of `new(voice)`, so `Style::Analysis` needs no change. Collapse the six contour subclasses into one `Guides::ContourMelody`. Add `HeadMusic::Style::Guide` — a lookup module over one explicit frozen registry whose entries are guide classes *and* the six preconfigured contour guides.

**The peer-weight premise in Notes was wrong, and the plan is safer for it.** `contour_ruleset`'s invariant-bearing work — `RULESET.partition(&:default_gate?)`, `peer_weight = phi^-2 / peers.length`, `peers.map { |r| r.with(weight: peer_weight) }` — reads only the frozen `DiatonicMelody::RULESET`. None of it depends on `contour` or `minimum_melodic_intervals`; the motion gate is added after the partition and never enters the peer set. Only the motion gate and the trailing `Contoured.with(contour)` are option-dependent. So the plan hoists the invariant part into frozen constants at class-definition time and leaves a three-element assembly at resolution time. Verified: for all six contours the rebuilt ruleset is element-for-element identical to today's, with `peers = 10` and `peer_weight = 0.03819660112501051`. This retires the "memoized per option set" requirement and every hazard an options-keyed cache carries.

### Steps

1. **`Guides::Base` — ruleset indirection, `.with`, and identity** — `lib/head_music/style/guides/base.rb`

   The `.ruleset` indirection is load-bearing safety. `Base.analyze` reads `self::RULESET`, and Ruby resolves `::` up the ancestor chain — so `ContourMelody < DiatonicMelody` with no own `RULESET` would make `Analysis.new(Guides::ContourMelody, voice)` silently grade against the plain diatonic ruleset: no contour rule, no motion gate, unweighted peers, plausible fitness, no exception. A method with a required keyword turns that into an `ArgumentError`.

   ```ruby
   class HeadMusic::Style::Guides::Base
     def self.analyze(voice)
       ruleset.map { |rule| rule.new(voice) }
     end

     # Indirection, not a constant read: guides whose ruleset varies by
     # configuration override this with a keyword signature, so an unconfigured
     # use raises instead of inheriting an ancestor's RULESET.
     def self.ruleset
       self::RULESET
     end

     # Pairs this guide with configuration: ContourMelody.with(contour: :arch).
     def self.with(**options)
       HeadMusic::Style::Guides::Configured.new(self, options)
     end

     def self.key
       HeadMusic::Utilities::Case.to_snake_case(name.split("::").last)
     end

     def self.category = nil

     def self.display_name = HeadMusic::Style::Guide.display_name_for(key)
   end
   ```

   Do **not** define `self.name` — `Module#name` is load-bearing at `spec/head_music/style/guides/base_spec.rb:26` and in `Annotation::Configured#name`. `Case.to_snake_case` produces the right key for every guide, including `SalzerSchachterCantusFirmus → "salzer_schachter_cantus_firmus"` (verified).

2. **Declare `category` on the two semantic markers** — `species_melody.rb`, `species_harmony.rb`

   `def self.category = :melody` / `= :harmony`. Ancestry derivation is fully correct: every one of the 23 concrete guides descends from exactly one marker, including `FuxCantusFirmus`, `SalzerSchachterCantusFirmus`, `DiatonicMelody`, and both combined-species guides. These classes already document themselves as *"a semantic marker distinguishing melody guides from harmony guides"* — this makes the existing marker addressable, which is why inheritance beats a per-guide declaration here despite the project's general delegation preference.

3. **`Guides::Configured`** — new file `lib/head_music/style/guides/configured.rb`

   ```ruby
   module HeadMusic::Style::Guides; end

   # A guide class paired with configuration. Quacks like a guide class to
   # Style::Analysis by responding to #analyze(voice), exactly as
   # Annotation::Configured quacks like a guideline class via #new(voice).
   class HeadMusic::Style::Guides::Configured
     attr_reader :guide_class, :options

     def initialize(guide_class, options)
       @guide_class = guide_class
       @options = options.dup.freeze
     end

     def analyze(voice) = ruleset.map { |rule| rule.new(voice) }

     def ruleset = @ruleset ||= guide_class.ruleset(**options)

     # Re-dispatches through the guide class so layering revalidates:
     # ContourMelody.with(contour: :arch).with(contour: :spiral) still raises.
     def with(**more) = guide_class.with(**options.merge(more))

     # Reverse lookup, not derivation. An ad-hoc configuration outside the
     # registry honestly has no key rather than claiming a key that resolves
     # to a different configuration.
     def key = HeadMusic::Style::Guide.key_for(self)

     def category = guide_class.category

     def display_name = key ? HeadMusic::Style::Guide.display_name_for(key) : guide_class.display_name

     def ==(other)
       other.is_a?(self.class) && guide_class == other.guide_class && options == other.options
     end
     alias_method :eql?, :==

     def hash = [guide_class, options].hash

     def name = guide_class.name
     alias_method :to_s, :name

     def inspect = "#{guide_class.name}.with(#{options.inspect})"
   end
   ```

   Four deliberate divergences from `Annotation::Configured`:

   - **Sibling, not nested** — `Guides` is a namespace module and `Base` is the base class, so `Guides::Configured` is the right shape.
   - **`#with` re-dispatches** through `guide_class.with` rather than constructing directly, closing the validation hole `Annotation::Configured#with` has today. Merge semantics unchanged, so AC 4 holds.
   - **`==`/`eql?`/`hash`** — `Annotation::Configured` defines none, which is why the contour specs need a custom matcher. Equality makes `key` reverse-lookup work and makes `Guide.get(g.key) == g` true.
   - **Options frozen at construction** — registry entries are process-global singletons; a consumer must not be able to mutate a shared guide's configuration.

   No `default_gate?`: guides are never ruleset members. `@ruleset` is the only mutable state, one frozen array per instance, written once during require (step 6). Nothing voice-derived may ever be memoized here.

4. **`Guides::ContourMelody`; move the contour machinery off `DiatonicMelody`** — new file `lib/head_music/style/guides/contour_melody.rb`

   ```ruby
   # A free diatonic melody targeting a specific contour. Configured rather than
   # subclassed: ContourMelody.with(contour: :arch, minimum_melodic_intervals: 2).
   class HeadMusic::Style::Guides::ContourMelody < HeadMusic::Style::Guides::DiatonicMelody
     # The non-gate peers of a contour guide share phi^-2 of rubric weight, so that
     # with Contoured at its default weight of phi^-1 (and phi^-1 + phi^-2 = 1), a
     # wrong contour on an otherwise perfect line grades exactly phi^-1.
     PEER_WEIGHT_BUDGET = HeadMusic::GOLDEN_RATIO_INVERSE**2

     # Neither the partition nor the peer weight depends on configuration --
     # DiatonicMelody::RULESET is frozen -- so both stay at class-definition time.
     # Only the motion gate and the contour rule vary per option set, which is why
     # no options-keyed cache is needed.
     GATES, WEIGHTED_PEERS = begin
       gates, peers = HeadMusic::Style::Guides::DiatonicMelody::RULESET.partition(&:default_gate?)
       peer_weight = PEER_WEIGHT_BUDGET / peers.length
       [gates.freeze, peers.map { |rule| rule.with(weight: peer_weight) }.freeze]
     end

     # Normalizes eagerly so an invalid contour raises HERE, at configuration
     # time, rather than at analysis. Required keyword, so an omitted or
     # misspelled option name raises too.
     def self.with(contour:, minimum_melodic_intervals: nil)
       super(
         contour: HeadMusic::Style::Guidelines::Contoured.normalized_contour(contour),
         minimum_melodic_intervals: minimum_melodic_intervals
       )
     end

     # An optional motion gate excludes non-attempts; nil omits it, so a static
     # contour can legitimately repeat a single pitch.
     def self.ruleset(contour:, minimum_melodic_intervals: nil)
       motion_gate =
         minimum_melodic_intervals &&
         HeadMusic::Style::Guidelines::MinimumMelodicIntervals.with(minimum_melodic_intervals)
       [
         *GATES,
         motion_gate,
         *WEIGHTED_PEERS,
         HeadMusic::Style::Guidelines::Contoured.with(contour)
       ].compact.freeze
     end
   end
   ```

   Then **delete** `CONTOUR_PEER_WEIGHT_BUDGET` and `self.contour_ruleset` from `diatonic_melody.rb:25-46`, leaving it a plain ruleset guide. Nothing else references either. Delete the six lib files: `arch_`, `ascending_`, `descending_`, `static_`, `valley_`, `wave_contour_melody.rb`.

   Decisions embedded:

   - **`ContourMelody < DiatonicMelody`** preserves today's inheritance exactly, keeps `category` deriving through `SpeciesMelody`, and keeps `DiatonicMelody::RULESET` reachable.
   - **`.with` is keyword-only**, against the `Contoured`/`MinimumThreshold`/`MaximumNotes` positional-first precedent. The rule that makes this non-arbitrary: *positional only when the class has exactly one configuration axis.* That holds for all three existing overrides and predicts the guide-layer choice — two axes is this story's whole premise. It also lets a consumer splat exercise config directly, with Ruby supplying unknown-keyword rejection for free.
   - **Eager validation in `.with`** is what actually satisfies AC 7 / scenario 5. Resolution-time ruleset building would defer the `ArgumentError` to the first `analyze` — i.e. mid-grading, past authoring-time validation. A spec written as `expect { with(:bogus).analyze(voice) }` would pass while the AC silently did not hold; **the spec must contain no `analyze`**.

5. **`HeadMusic::Style::Guide` registry** — new file `lib/head_music/style/guide.rb`

   ```ruby
   # Lookup facade for the guides in HeadMusic::Style::Guides. A class with a
   # .get factory, matching Tradition and the gem's other 39 .get definers --
   # no module in the gem defines .get. Never instantiated; .get returns a guide
   # class or a Guides::Configured, either of which answers analyze(voice), key,
   # category, and display_name.
   class HeadMusic::Style::Guide
     GUIDE_CLASSES = [
       HeadMusic::Style::Guides::FuxCantusFirmus,
       HeadMusic::Style::Guides::SalzerSchachterCantusFirmus,
       HeadMusic::Style::Guides::DiatonicMelody,
       HeadMusic::Style::Guides::FirstSpeciesMelody,
       HeadMusic::Style::Guides::FirstSpeciesHarmony,
       # ... through FifthSpeciesHarmony: 10 melodic + 7 harmonic = 17
     ].freeze

     # The six preserved contour keys, literal and greppable. This table is the
     # reason the registry is an explicit list: no `inherited` hook or constant
     # scan can produce a registry entry that is an instance rather than a class.
     CONTOUR_CONFIGURATIONS = {
       "arch_contour_melody" => {contour: :arch, minimum_melodic_intervals: 2},
       "ascending_contour_melody" => {contour: :ascending, minimum_melodic_intervals: 1},
       "descending_contour_melody" => {contour: :descending, minimum_melodic_intervals: 1},
       "static_contour_melody" => {contour: :static},
       "valley_contour_melody" => {contour: :valley, minimum_melodic_intervals: 2},
       "wave_contour_melody" => {contour: :wave, minimum_melodic_intervals: 2}
     }.freeze

     REGISTRY = GUIDE_CLASSES.to_h { |klass| [klass.key, klass] }
       .merge(CONTOUR_CONFIGURATIONS.transform_values { |options|
         HeadMusic::Style::Guides::ContourMelody.with(**options)
       }).freeze

     ALL = REGISTRY.values.freeze

     # Resolve every ruleset during require, so nothing in the registry is
     # written to after load and concurrent lookups never race on the Configured
     # memo. Doubles as a load-time check that every entry resolves.
     ALL.each(&:ruleset)

     # A miss returns nil rather than falling back, unlike Tradition.get: a
     # substituted tradition changes a consonance default, but a substituted
     # guide would silently grade a voice against the wrong ruleset.
     def self.get(key)
       return key if key.respond_to?(:analyze)

       REGISTRY[key.to_s]
     end

     def self.get!(key)
       get(key) || raise(KeyError, "unknown style guide: #{key.inspect}")
     end

     def self.known?(key) = !get(key).nil?
     def self.all = ALL
     def self.keys = REGISTRY.keys
     def self.key_for(guide) = REGISTRY.key(guide)

     def self.display_name_for(key)
       I18n.translate(key, scope: "head_music.style.guides",
         default: key.to_s.tr("_", " ").split.map(&:capitalize).join(" "))
     end
   end
   ```

   **Registry population — explicit frozen list.** Weighed against the alternatives:

   | Option | Verdict |
   | --- | --- |
   | `inherited` hook | Rejected — structurally cannot see the six entries, which are `Configured` *instances*, not subclasses. Would also auto-register abstract bases and any consumer-defined subclass in the process. |
   | Derive from `Guides.constants` | Rejected — same instance problem, plus a live counterexample: `spec/head_music/style/analysis_spec.rb:3` defines `Guides::PermissiveGuide` at spec-load time, so registry contents would depend on spec load order. |
   | **Explicit frozen list** | **Chosen** — hybrid entries sit side by side, the six preserved keys are literal, and it mirrors `Tradition.get`'s explicit dispatch. Its one weakness, drift when a guide is added, is closed by the guard spec in step 8. |

   **Three things `get` must not do, all reachable-looking:** (a) `HeadMusic::Utilities::HashKey.for` — the house normalizer idiom, but its own comment warns it *"would grow without limit"* for dynamically generated identifiers, and these keys arrive from a database; use `Case.to_snake_case` if tolerant normalization is wanted, and leave a `# why` comment so the next reader does not "fix" it back. (b) `const_get` on the key — `Guides.const_get("Kernel")` succeeds, `"A::B"` traverses, and an invalid name raises `NameError`, violating nil-on-miss. (c) `send` dispatch on the key.

   `get` is idempotent (pass-through for anything answering `analyze`), matching `Spelling.get`/`Pitch.get`. **A null-object guide is rejected outright**: `Analysis#fitness` is `return 1.0 if annotations.empty?`, so a guide answering `analyze → []` would grade an unknown exercise as a *perfect score* — the worst possible failure in a grading product.

6. **Require ordering** — `lib/head_music.rb`

   In the guides block (currently 254–280): add `guides/configured` after `guides/base`; replace lines 261–266 with a single `guides/contour_melody`; append `require "head_music/style/guide"` **last**, after `fifth_species_harmony`, since `REGISTRY` names every guide constant at load. `contour_melody.rb` reads `DiatonicMelody::RULESET` at class-definition time, so it must stay after `diatonic_melody` — the same constraint the six deleted files had.

7. **Locale entries** — `lib/head_music/locales/en.yml`

   The computed default (`"first_species_harmony" → "First Species Harmony"`) is correct for ~22 of 24 keys. Add a `head_music.style.guides` scope with overrides **only** where derivation is wrong — `salzer_schachter_cantus_firmus` ("Salzer–Schachter Cantus Firmus"). `HeadMusic::Named` is not used: it is instance-oriented (`@localized_names`, `get_by_name` memoizing `new(name)`) and does not drop onto classes. English only for v1 — there is currently *zero* `style` content in any of the seven locale files and every guideline message is a hardcoded English string, so localizing headings above English feedback would be worse than consistent English. The `default:` makes adding translations purely additive later.

8. **Restructure `spec/head_music/style/guides/base_spec.rb` to enumerate the registry**

   Replace the `Guides.constants` derivation with `Guide.all` partitioned by `category`. **The counts stay sixteen and seven** — 10 surviving melodic classes + 6 configured contour entries = 16, harmonic unaffected at 7 — so "the six contour names survive as names" is pinned by an *unchanged* assertion, and the core-enforcement loop keeps covering all six contour rulesets via `guide.ruleset`.

   Without this, the collapse silently guts coverage: the current `const_defined?(:RULESET, false)` filter would drop `ContourMelody` (it has no own `RULESET`), the count would be "fixed" from 16 to 10, and the six "enforces the melodic core" examples would vanish looking like an expected consequence.

   ```ruby
   entries = HeadMusic::Style::Guide.all
   melodic_guides = entries.select { |entry| entry.category == :melody }
   harmonic_guides = entries.select { |entry| entry.category == :harmony }
   # "recognizes sixteen melodic guides" / "recognizes seven harmonic guides" -- unchanged

   # Guards the explicit registry list against drift when a guide class is added.
   it "registers every guide class that defines its own ruleset" do
     classes = guides.constants.map { |const| guides.const_get(const) }
       .select { |klass| klass.is_a?(Class) && klass.const_defined?(:RULESET, false) }
     registered = entries.map { |entry| entry.is_a?(Class) ? entry : entry.guide_class }.uniq
     expect(classes - registered).to be_empty
   end

   it "round-trips every registered key" do
     entries.each { |entry| expect(HeadMusic::Style::Guide.get(entry.key)).to eq entry }
   end
   ```

   Keep `enforced_by?` verbatim (it already handles `Annotation::Configured`) and keep the `const_defined?(:RULESET, false)` filter inside the drift guard — that filter is what excludes the spec-injected `PermissiveGuide`. Example names move from `guide.name.split("::").last` to `guide.key`, since a `Configured` has no distinct class name. This spec is the load-bearing justification for choosing an explicit registry; do not skip it.

9. **Consolidate the six contour specs into one** — delete `spec/head_music/style/guides/{arch,ascending,descending,static,valley,wave}_contour_melody_spec.rb`; create `contour_melody_spec.rb`

   Rejected "keep six, repoint at `Guide.get(...)`": five would carry an identical copy of a RULESET block that is now one parameterized method, and `described_class` becomes unusable against the project convention. Current inventory: arch **26** examples (17 behavioral), static **11**, ascending/valley/wave **8**, descending **7** — 93 examples across these plus `base_spec`.

   - **`describe ".ruleset"`** — parameterized over a six-row table, absorbing every structural assertion from all six files: carries every diatonic guideline; `MinimumNotes.with(5)` passes through unchanged; the per-contour `MinimumMelodicIntervals` minimum **and, for `:static`, its absence** (`static_contour_melody_spec.rb:21-24` is the only spec pinning the `nil` branch, and its behavioral proof — an all-repeated-note line scoring `> 0.9` with every gate at 1.0 — must survive); `peers.length == 10`; every peer at `GOLDEN_RATIO_INVERSE**2 / 10`; `Contoured` present for the right contour; and `DiatonicMelody::RULESET` not mutated.
   - **`describe "contextual weights"`** — ported from `arch_contour_melody_spec.rb:48-70`, repointed at `Guide.get("arch_contour_melody").ruleset`.
   - **`describe "analysis"`** — **all six analysis blocks ported verbatim**, one `context` per contour, changing only the subject to `Analysis.new(Guide.get(key), voice)`. Non-negotiable behavior-equivalence evidence: `fitness == 1.0`; `≈ GOLDEN_RATIO_INVERSE` (the phi identity, `be_within(1e-6)` — the observed value is `0.6180339887498949`, one ULP above the constant); the 0.3–0.55 soft-floor band; empty-voice gate-to-zero; the `0.8 * rubric_mean` note-count haircut; the length-invariance pair; static's repeated-note cases; wave's trend-leg cases.
   - **Fail-fast (AC 7 / scenario 5)**, each with **no `analyze` in the block**: `ContourMelody.with(contour: :spiral)` → `ArgumentError`; `ContourMelody.with(contour: :arch).with(contour: :spiral)` → `ArgumentError` (pins the re-dispatch decision); `ContourMelody.with(contur: :arch)` → `ArgumentError`; bare `ContourMelody.analyze(voice)` → `ArgumentError` (pins the inherited-RULESET hazard closed).

10. **New specs for the registry and the wrapper**

    - `spec/head_music/style/guide_spec.rb` — `.get("first_species_harmony")` returns the class with `category == :harmony`; symbol keys resolve; `.get("does_not_exist")` returns `nil` and `not_to raise_error`; `.get!` raises naming the key; `.known?` both ways; `nil`/`""` are misses; `.get("ascending")` is a **miss** (a contour is not a guide key); idempotent pass-through; all six contour keys resolve to the right `ContourMelody` config; `.all`/`.keys` (uniqueness, length 23); `display_name_for` for a derived key and the Salzer–Schachter override; every entry's `category` is `:melody` or `:harmony`.
    - `spec/head_music/style/guides/configured_spec.rb` — `#analyze(voice)` returns annotations; `Analysis.new(configured, voice)` produces `annotations`/`fitness` (scenario 4); `#with` merges without dropping prior options; `#ruleset` memoizes (`be` identity); `#key` returns the registered key for a registry entry and **`nil`** for an ad-hoc `ContourMelody.with(contour: :wave, minimum_melodic_intervals: 3)`; `#==`; `#category`; `#name`/`#to_s`/`#inspect`; frozen options.

11. **`spec/spec_helper.rb`** — add a guide matcher alongside `configured`:

    ```ruby
    # Matcher for a guide wrapped by Guides::Base.with(...).
    def configured_guide(guide_class, **options)
      an_object_having_attributes(guide_class: guide_class, options: options)
    end
    ```

    The distinct reader name (`guide_class` vs `guideline_class`) is intentional — it prevents the guideline matcher from ever matching a guide entry.

12. **Guard `Style::Analysis` against a non-guide** — `lib/head_music/style/analysis.rb`

    The one intended change to `Analysis` (see Decisions). `Guide.get` returns `nil` on a miss, and today that `nil` travels to `annotations` before failing as `NoMethodError: undefined method 'analyze' for nil` — far from the bad key and possibly inside a view. Fail at construction, where the key is still in hand:

    ```ruby
    def initialize(guide, voice)
      unless guide.respond_to?(:analyze)
        raise ArgumentError, "guide must respond to #analyze (got #{guide.inspect})"
      end

      @guide = guide
      @voice = voice
    end
    ```

    Do **not** reach for `Guide.get!` here instead — `Analysis` accepts any object answering `analyze`, including a `Configured` and the spec-injected `Guides::PermissiveGuide`, so the duck-type check is the correct predicate and the registry is not `Analysis`'s concern. Spec in `spec/head_music/style/analysis_spec.rb`: `Analysis.new(nil, voice)` and `Analysis.new(Object.new, voice)` each raise `ArgumentError`; a guide class, a `Configured`, and `PermissiveGuide` each construct fine.

13. **Version bump — `lib/head_music/version.rb`: `18.0.0` → `19.0.0`.** Required, not optional: the clean break removes six public constants (see Decisions). Do this in the same commit as the removals so no released version ever has the classes missing without the major bump.

13. **CHANGELOG, README** — `CHANGELOG.md` `[Unreleased]`: **Added** the registry and metadata surface, `Guides::Configured`, `ContourMelody`; **Breaking** the six removed public classes, `guide.name` changing value for them (persist `key`, not `name`), `::RULESET` undefined on configured guides (use `#ruleset`), and the constant relocation `DiatonicMelody::CONTOUR_PEER_WEIGHT_BUDGET` → `ContourMelody::PEER_WEIGHT_BUDGET`. Include a **table of all 23 keys with categories** — roughly 25 lines and the single most useful artifact for the consumer — and an explicit upgrade line mapping each removed constant to its key, since that is what a consumer needs to migrate. Also touch up the now-stale prose at `CHANGELOG.md:135, 142, 151`. Add a six-line Style quick-start to `README.md`, which currently has no Style section. Then `bundle exec rubocop -a` and `bundle exec rake`.

### API & config decisions

| Surface | Returns |
| --- | --- |
| `Style::Guide.get(key)` | guide class, `Guides::Configured`, or `nil`; idempotent |
| `Style::Guide.get!(key)` / `.known?(key)` | raising variant / predicate |
| `Style::Guide.all` / `.keys` / `.key_for(guide)` | frozen entries / key strings / reverse lookup |
| `Guides::Base.with(**options)` / `.ruleset` / `.key` / `.category` / `.display_name` | — |
| `Guides::Configured#analyze/#ruleset/#with/#key/#category/#display_name/#==` | — |
| `Guides::ContourMelody.with(contour:, minimum_melodic_intervals:)` | `Guides::Configured` |

- **`key` is a String** (it crosses the storage boundary and is compared to params); **`category` is a Symbol** (a gem-owned open enum — `:rhythm`/`:form` slot in later at no cost). `get` accepts either type.
- **`display_name`, never `name`.** `def self.name` on a guide class overrides `Module#name`, breaking `base_spec.rb:26`, RSpec output, and every exception message.
- **`ContourMelody.with(contour: :arch)` displays as "Arch Contour Melody"**, derived from `key` — otherwise the consumer's exercise-type dropdown shows six identical entries and the collapse leaks into the UI.
- **Removed (breaking):** the six `*ContourMelody` classes, `DiatonicMelody.contour_ruleset`, `DiatonicMelody::CONTOUR_PEER_WEIGHT_BUDGET`.
- **`Style::Analysis` changes in exactly one way** — a `respond_to?(:analyze)` guard in `#initialize` (step 12). Its analysis path is untouched: the existing `guide.analyze(voice)` call site is what already accepts a `Configured`. No guideline, no `Annotation`, no data model, no migrations in the gem.
- **`moving_species_ruleset` / `diminution_ruleset` stay class-definition-time builders.** They have no option-dependence to defer, and the only thing resolution-time would buy is letting a caller vary the *guideline list* — precisely the consumer-composed-rulesets non-goal approached from the other side. Record the revisit condition explicitly, as the contour story did: *revisit when a species guide must vary by a scalar parameter*, not merely by a different guideline list.

### Testing strategy

| Story scenario | Where |
| --- | --- |
| A guide is resolved by name | `guide_spec.rb` — class + `:harmony`; `nil` + `not_to raise_error` on a miss |
| A contour guide is configured rather than subclassed | `contour_melody_spec.rb` — six ported analysis blocks + parameterized `.ruleset` block |
| Contour guide keys survive the collapse | `guide_spec.rb` six-key loop; wave analysis context; `base_spec.rb` counts still 16/7 |
| A configured guide drops into Analysis unchanged | `configured_spec.rb`; `analysis.rb`'s analysis path untouched — only the guard is added |
| Analysis rejects a non-guide with a clear error | `analysis_spec.rb` — `nil` and `Object.new` raise `ArgumentError`; class, `Configured`, and `PermissiveGuide` all construct |
| An invalid configuration fails fast | `contour_melody_spec.rb` — bad contour at `.with`, on layered `.with`, unknown keyword, bare `.analyze`; **no `analyze` inside the raise blocks** |

**Regression sequence** (the method proven by `configurable-large-leap-recovery`):

1. Snapshot on `main` **before writing anything**: `bundle exec rspec spec/head_music/style --format documentation | tee before.txt`. The large-leap learnings record this being skipped and requiring a pristine-worktree fallback.
2. Land lib changes + spec restructure in one commit — `base_spec` cannot pass in an intermediate state.
3. Gate: `bundle exec rspec spec/head_music/style` → 0 failures.
4. `bundle exec rake` (90% floor, `maximum_coverage_drop 1.0`), `bundle exec rubocop -a`, `bundle exec rake validate`.
5. Diff before/after. Expect only renamed contour examples and **zero numeric deltas**.

**Baseline captured on this branch** (ABC `X:1 / M:4/4 / L:1/4 / K:C / CDEG|EDC2|`, 8 notes) — the equivalence target:

| guide | ruleset size | fitness | messages |
| --- | --- | --- | --- |
| Arch | 13 | `1.0` | `[]` |
| Ascending / Descending / Valley / Wave | 13 | `0.6180339887498949` | one contour message |
| Static | 12 | `0.6180339887498949` | one contour message |

**Coverage watch-list** — small new methods with no in-gem caller, each needing an example or the 90% floor bites (deleting six one-line files removes six *covered* lines, so the net is a coverage risk, not a cushion): `Base.category` nil branch, `Base.display_name`, `Guide.all`/`.keys`/`.key_for`/`.known?`/`.get!`, `display_name_for` both branches, `Configured#name`/`#to_s`/`#inspect`/`#display_name` fallback.

### Risks

1. **Six public classes disappear.** *Decided: clean break, no aliases, major bump 18.0.0 → 19.0.0 (see Decisions).* No in-gem references survive outside their own files and specs, but external consumers break at `NameError`. The residual risk is now coordination, not design: BardTheory's `CONTOUR_GUIDES` must move to guide keys in the same upgrade, and the CHANGELOG must map each removed constant to its replacement key (step 13) or the break is undiagnosable from the consumer side.
2. **The registry can drift** when a guide class is added and not registered. Mitigated *only* by the step-8 drift-guard spec.
3. **Peer-count coupling.** `peer_weight = phi^-2 / peers.length` silently reweights every contour guide if `DiatonicMelody::RULESET` gains or loses a non-gate rule. Pre-existing, but now one indirection further away. Mitigated by keeping the `peers.length == 10` assertion.
4. ~~**`Guide.get` returning `nil` flows into `Analysis.new(nil, voice)` → `NoMethodError`.**~~ *Closed by decision:* step 12 adds the `respond_to?(:analyze)` guard, and AC 3 was reworded so the criteria no longer read as freezing `Analysis`. `get!` and `known?` remain available for callers that would rather not construct an `Analysis` at all.
5. **`Style::Guide` vs `Style::Guides`** differ by one character. Low mechanical risk (all guide files use fully-qualified names; a typo yields `NameError`), but a live legibility hazard — see open questions.
6. **`Configured#with` re-dispatch is a deliberate divergence** from `Annotation::Configured#with`. Because `ContourMelody.with` has a restrictive keyword signature, layering an unrelated option raises. That *is* the fail-fast, but it is a behavioral difference between the two `Configured` classes a maintainer could trip over.
7. **This story overclaims that the change retires all four BardTheory hashes.** `PENDING_GUIDE_CATEGORIES` survives regardless — the category of a guide the gem does not have is unknowable *from the gem*. And `GUIDES_BY_SPECIES` is lesson-plan data that by this story's own rule belongs in the consumer's exercise rows (it becomes `guide_keys: [...]` plus `guides.group_by(&:category)`), not something `Guide.get` retires. Three of four, honestly.
8. **`spec/head_music/style/analysis_spec.rb:3` injects `Guides::PermissiveGuide`** into the namespace at spec-load time. It is why the drift guard must keep the `const_defined?(:RULESET, false)` filter, and why constant-scan registry derivation was rejected.

### Open questions

- **Locale coverage at release**: English with computed fallback (recommended, and what the plan does), or all seven locales up front?

## Review

Reviewed 2026-08-07 at commit `7e2ce56`. Nothing uncommitted. Test evidence, run independently of the implementing agents: full suite `bundle exec rake` → **6443 examples, 0 failures**, line coverage **99.70%**, branch **97.75%**; style subtree 1100 → **1206 examples**; `bundle exec rubocop` → 486 files, **no offenses**.

Ruleset equivalence against the merge-base `b1cef76` was verified out-of-band by two independent methods: dumping all 77 ruleset entries as `[guideline_class, sorted_options]` rows and diffing (identical), and comparing 126 rows of `(fitness to 15 decimals, adherent?, sorted messages)` across 6 guides × 20 melodies plus an empty voice (identical).

### Acceptance criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Every guide exposes `key`, `category`, display name | ✅ met | `guides/base.rb:23-35`; markers at `species_melody.rb:40-42`, `species_harmony.rb:34-36`; pinned by `guide_spec.rb:80-82` (categories are exactly `%i[melody harmony]`) and `base_spec.rb:30-32` |
| 2 | `Guide.get` resolves string or symbol; unknown → `nil` | ✅ met | `guide.rb:62-66` — plain hash lookup, no `const_get`, no `HashKey.for`; `guide_spec.rb:7-33` covers string, symbol, miss, `nil`, `""` |
| 3 | `Configured` accepted by `Analysis` with no accommodating change | ✅ met | `configured.rb:15-17`; the `analysis.rb` diff is *only* the guard — call site at `:26` untouched, no `is_a?` branch anywhere |
| 4 | `Analysis` rejects a non-guide with a clear error | ✅ met | `analysis.rb:11-18`; `analysis_spec.rb:77-96` — `nil` and `Object.new` raise; class, `Configured`, and `PermissiveGuide` still construct |
| 5 | `Base.with` returns `Configured`; layering merges | ✅ met | `base.rb:19-21`, `configured.rb:25-27`, `configured_spec.rb:65-75`. See finding 3 — merge semantics match `Annotation::Configured` but strictness does not |
| 6 | One `ContourMelody` replaces the six subclasses | ✅ met | `contour_melody.rb`; six lib files deleted; `grep` for the six constants, `contour_ruleset`, and `CONTOUR_PEER_WEIGHT_BUDGET` across `lib/`, `spec/`, `README.md` → zero hits |
| 7 | Six contour keys resolve, rulesets identical to the old classes | ✅ met | Verified against `b1cef76` by the two out-of-band diffs above. **The specs pin equivalence in substance, not by snapshot** — carried-over literal values (sizes 13/13/13/12/13/13, `peers.length == 10`, peer weight `phi^-2/10`, static's absent motion gate) rather than a committed byte-comparison |
| 8 | Invalid contour raises at configuration time | ✅ met | `contour_melody.rb:22-27` normalizes *before* `super`. Trap checked: all four raise examples (`contour_melody_spec.rb:119-134`) assert on `.with` alone with **no `analyze`**. Eagerness independently proven — after a successful `.with`, `@ruleset` is not yet set, so the raise cannot be coming from ruleset construction |
| 9 | Species / cantus firmus / combined guides stay classes with current keys | ✅ met | All 22 non-contour guide files unchanged but for `category` on the two markers; `guide.rb:10-28`; drift guard at `base_spec.rb:23-28`. See finding 5 for a durability gap |
| 10 | Specs pass unchanged in behavior; coverage ≥ 90%; rubocop clean | ✅ met | Figures above. Only pre-existing specs modified are `base_spec.rb` (restructured, counts still 16/7) and `analysis_spec.rb` (additive) |

All five `## Scenario:` blocks verified ✅. All six `## Decisions` honored. No `## Non-goals` crept in — no API accepts a guideline list, no guides moved to consumers, no ruleset versioning added.

### Code review findings

Findings 1–3 were **fixed at commit `7e2ce56`+1** (see "Fixes applied" below). Findings 4–11 remain advisory and are not blocking.

**Blocking — fixed**

1. **The `::RULESET` constant hole is still open** — `contour_melody.rb:3`. `Base.ruleset` closes the *method* path but not the *constant* path. Because `ContourMelody < DiatonicMelody`, Ruby's constant lookup still resolves `ContourMelody::RULESET` to `DiatonicMelody::RULESET` — the same frozen 11-entry array object, with no `Contoured` rule, no motion gate, and unweighted peers. Confirmed at runtime: `ContourMelody::RULESET.equal?(DiatonicMelody::RULESET) # => true`. This is exactly the silent wrong-ruleset failure the indirection was introduced to prevent, and it is reachable: `described_class::RULESET` is the established reading idiom in this repo (`fifth_species_harmony_spec.rb:6` and others), the six deleted contour specs all used it, and `CHANGELOG.md:33` currently claims "a configured guide has no `::RULESET` constant" — true of the `Configured` instance, false of the guide class, and the false case is the one that silently returns data.
   **Fix, verified:** change the superclass to `SpeciesMelody`. `ContourMelody` already references `DiatonicMelody::RULESET` fully-qualified when building `GATES`/`WEIGHTED_PEERS`, and takes `category` from `SpeciesMelody`, so the `DiatonicMelody` parent buys nothing but the hole. A probe class with an identical body under `SpeciesMelody` produces a byte-identical 13-entry ruleset, keeps `category == :melody`, and makes `RULESET` raise `NameError`. Add a regression next to `contour_melody_spec.rb:143`: `expect { described_class::RULESET }.to raise_error(NameError)`. Correct `CHANGELOG.md:33` once the claim is actually true.

**Important — both fixed**

2. **An unconfigured `ContourMelody` passes the `Analysis` guard** — `guide.rb:63`, `analysis.rb:12`. `Guide.get` passes through anything answering `analyze`, and `ContourMelody` inherits `Base.analyze`, so `Analysis.new(Guides::ContourMelody, voice)` is accepted and fails later at `annotations` with `ArgumentError: missing keyword: :contour` — naming neither the guide nor the fix. Now that the six subclasses are gone, naming the shared class instead of a key is the likeliest consumer mistake, and it is the one the guard waves through. Suggest overriding `self.analyze` on `ContourMelody` to raise with a message naming `.with(...)` and `Guide.get("arch_contour_melody")`.

3. **`Guide.known?` answers "does this quack?" rather than "is this registered?"** — `guide.rb:72-74`. `known?(Guides::ContourMelody)` and `known?` of an ad-hoc configuration both return `true` while `key_for` returns `nil`. The string path — the consumer's actual path — is correct, so this is a latent trap, not a live bug. Fix: `REGISTRY.key?(key.to_s) || !key_for(key).nil?`.

**Advisory**

4. **Registry entries are not frozen.** `guide.rb:45-52` — `REGISTRY.freeze` and `ALL.freeze` are shallow; the six `Configured` instances are `frozen? => false`. No reachable mutation path exists (no writers, `#with` returns a new object, `options` and rulesets are frozen), but since `ALL.each(&:ruleset)` already warms the memo, the entries could be frozen immediately after, making the comment's immutability claim enforced rather than conventional.

5. **The 17 class-derived key strings are not pinned literally.** Keys cross the storage boundary but are derived from class names, and only 3 of 17 appear as literals in any spec. A class rename would silently invalidate a consumer's stored keys with a green suite. One example asserting `Guide.keys` against an explicit 23-string array closes it and doubles as documentation. *Highest-value addition of the advisory set.*

6. **The load-time pre-warm has no test.** Deleting `ALL.each(&:ruleset)` at `guide.rb:52` leaves the suite green, so the thread-safety claim in its comment is unpinned.

7. **`Base.with` validates nothing**, unlike `ContourMelody.with`. `FuxCantusFirmus.with(bogus: 1)` constructs and fails only at `#ruleset` with `wrong number of arguments`. Inconsistent with the fail-fast the story establishes.

8. **`display_name` is asserted for 7 of 23 entries**, and registry-wide uniqueness — the property that stops six identical dropdown entries — is only asserted indirectly per-contour.

9. **Spec nits.** `base_spec.rb:30-32`'s round-trip is near-tautological for `Configured` entries (`REGISTRY[REGISTRY.key(v)] == v`); `guide_spec.rb:151-155` is named "distinctly from its siblings" but never compares siblings; `base_spec.rb:84-88`'s `.with` example only checks the returned class.

10. **README overstates equivalence** at `README.md:71-76`: "either spelling works" holds only because the options match exactly. Dropping `minimum_melodic_intervals: 2` yields a different guide with no motion gate, `key == nil`, and `display_name == "Contour Melody"`.

11. **Plan step 13's promised 23-key CHANGELOG table is missing** — only the 6-row removal→key migration table shipped. Story-text commitment, not an acceptance criterion.

### Verified and explicitly fine

- **Thread safety.** All six `Configured` registry entries have `@ruleset` set at require time, so no entry memoizes lazily after load. `REGISTRY`, `ALL`, `options`, `GATES`, `WEIGHTED_PEERS`, and every returned ruleset are frozen.
- **`Base.ruleset` on every method path** — `.analyze`, direct `.ruleset`, `Configured#ruleset`/`#analyze`/`#with`, and `Configured.new` bypassing `.with` all raise for an unconfigured `ContourMelody`. Only the constant path (finding 1) is silent.
- **`Configured#key` reverse lookup.** `Hash#key` compares by `==`, and guide *classes* never match a `Configured`, so no false positives. `==`/`eql?`/`hash` are mutually consistent. `nil` from `key` propagates only into `display_name`, which handles it at `configured.rb:41`.
- **Spec consolidation lost nothing.** All six deleted spec files were diffed assertion by assertion against `contour_melody_spec.rb`. No assertion weakened; three arch-only assertions are now parameterized across all six contours — a net strengthening.
- **i18n.** `en.yml` nests `style:` correctly under `head_music:`, single occurrence, no duplicate-key shadowing. Under `I18n.locale = :de` the override still resolves via fallback, so the other six locale files lacking the scope is not a defect.

### Fixes applied

Findings 1, 2, and 3 were fixed after review. Suite after: **6450 examples, 0 failures** (was 6443 — seven new regression examples), line coverage **99.70%**, rubocop clean across 486 files. Ruleset equivalence re-verified against `b1cef76` *after* the inheritance change — 77 rows, identical — since changing a superclass could plausibly have moved the rulesets.

| Finding | Outcome | Change |
| --- | --- | --- |
| 1 — `::RULESET` constant hole | fixed | `ContourMelody` now descends from `SpeciesMelody`, not `DiatonicMelody` (`contour_melody.rb:10`), with a comment explaining that the parent existed only to leak the constant. `ContourMelody::RULESET` now raises `NameError`; `category` is still `:melody`; the ruleset is reached fully-qualified as before. Pinned by a `describe "::RULESET"` block asserting both the `NameError` and that `DiatonicMelody` is absent from the ancestors. `CHANGELOG.md` corrected — its claim that a configured guide has no `::RULESET` was true of the instance but false of the class, and is now true of both. |
| 2 — unconfigured class reaches `Analysis` | fixed | `ContourMelody.analyze` overridden to raise `ArgumentError` naming both `.with(contour:, minimum_melodic_intervals:)` and `Guide.get("arch_contour_melody")`. The `Analysis` guard cannot catch this case — the class legitimately answers `analyze` — so this is the backstop, pinned by three examples including one that drives it through `Analysis#annotations`. |
| 3 — `known?` answered "does this quack?" | fixed | Now `REGISTRY.key?(key.to_s) \|\| !key_for(key).nil?` (`guide.rb:72-78`), so `known?` and `key_for` can no longer disagree about the same object. Four examples pin it: a registered key, a registered guide object, an ad-hoc configuration, and the bare `ContourMelody` class. |

Findings 4–11 are recorded above and left open deliberately: none is a correctness defect, and the highest-value one (5 — pinning the 17 class-derived key strings literally) is worth doing as its own change rather than folded into a review fix.
