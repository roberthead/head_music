<!--
metadata:
  created_at:   2026-08-12T16:05:34-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-08-16T15:24:07-07:00
-->

# First-Class Guide Items

AS a developer extending the style layer

I WANT a guide to declare its guidelines in three named tiers, each entry one kind of object that knows its guideline and its configuration

SO THAT a new per-entry attribute is one definition rather than two, a guide's editorial structure survives into what a consumer reads, and an entry can be asked a question without first asking what shape it is

Story 2 of the [Style Assessment Model](../epics/style-assessment-model.md).
Story 1 (renaming `Annotation` to `Guideline`) lands first; this story assumes
that rename is done and uses the new names throughout.

## Background

A ruleset is a mixed array. Across the seventeen registered guides there are 304
entries: 217 bare guideline classes and 87 `Configured` wrappers. The analyze
loop treats them uniformly by calling `#new(voice)` on each — which means
`Configured` exists to let an *instance* impersonate a *class*. Its own comment
says so: "Quacks like a class to the analyze loop."

That works, and it has a running cost. Every per-entry attribute must be defined
twice, once as a class-level default and once as a resolver on `Configured`:

```ruby
def self.default_gate?          # guideline.rb
  false
end

def default_gate?               # guideline/configured.rb
  options.fetch(:gate, guideline_class.default_gate?)
end
```

The two are not even the same question. On the class, `default_gate?` means *the
default for this guideline*. On `Configured`, it means *the resolved value for
this entry*. One name, two meanings, because one concept is spread across two
shapes.

Four consequences follow.

**Grading metadata rides along into the annotation.** `Configured#new` splats the
whole options hash into `Guideline.new(voice, **options)`, so a `gate:` or
`weight:` option reaches an object that then reads it back off itself. The result
of an analysis carries scheduling information it does not use.

**Set operations on rulesets match by identity and fail silently.**
`diatonic_melody.rb:7` reads:

```ruby
*(MELODIC_CORE - [HeadMusic::Style::Guidelines::SingableIntervals])
```

This works only because `MELODIC_CORE` holds bare classes. Configure
`SingableIntervals` inside `MELODIC_CORE` and the subtraction quietly removes
nothing, leaving `DiatonicMelody` grading against two conflicting interval rules
with a plausible fitness. Relatedly, `Configured` defines neither `==` nor
`hash`, unlike `Guides::Configured`, which defines both.

**A ruleset cannot be asked anything as a whole.** It is a frozen `Array`, so
`ContourMelody` reaches for `partition(&:default_gate?)` and every consumer that
wants a subset re-derives it.

**The editorial structure a guide already has is thrown away.** `ContourMelody`
partitions its inherited ruleset three ways — gates, deliberately down-weighted
peers, and `Contoured` at its own default — then concatenates them and returns a
flat list. A consumer that wants to *present* a guide gets twelve rules in
alphabetical accident, which is a correct rubric and unusable instructions.

## Current state

| Concern | Where it lives today |
| --- | --- |
| The guideline | A class in `Style::Guidelines`, subclassing `Style::Guideline` |
| Its configuration | An options hash on `Guideline::Configured`, or nothing at all for a bare class |
| Its weight and gate | The *same* options hash, resolved on the result instance |
| Whether it is the lesson or background | Nowhere. Computed at build time and discarded |
| The result of applying it | A `Guideline` instance, holding marks and a fitness |

## Scope

Three types, a declaration form for guides, and one change to the guide contract.

### Guide declaration: three ordered lists

`RULESET` is replaced by three declared lists. Tier stops being a per-entry
attribute and becomes the list an entry is declared in.

```ruby
class HeadMusic::Style::Guides::DiatonicMelody < HeadMusic::Style::Guides::SpeciesMelody
  gate_items    Guidelines::MinimumNotes.with(5)

  primary_items *SpeciesMelody::MELODIC_CORE, except: Guidelines::SingableIntervals
  primary_items Guidelines::SingableIntervals.with(ascending: SINGABLE_INTERVALS,
                                                   descending: SINGABLE_INTERVALS),
                Guidelines::ModerateDirectionChanges,
                Guidelines::PrepareOctaveLeaps,
                Guidelines::LargeLeaps.with(minimum: :perfect_fourth, recovery: [...]),
                Guidelines::MaximumNotes.with(32)
end
```

`gate_items(*entries, except: nil)` and its two siblings coerce bare guideline
classes into `GuideItem`s, subtract by guideline class, and freeze. Called more
than once, a list appends.

**Tier must be the list rather than a field, because the shared cores are shared
objects.** `MELODIC_CORE` is splatted into six guides and `HARMONIC_CORE` into
four, and `ContourMelody` demotes exactly the items `DiatonicMelody` treats as
its lesson. One frozen object cannot carry both standings. Making tier the slot
is what lets the cores stay shared.

`except:` is why the subtraction cannot stay `Array#-`: it matches by guideline
class, so it cannot silently remove nothing. Being applied per-list also scopes
it correctly for free — an `except:` on `primary_items` cannot strip a gate copy
of the same guideline.

A guide also gains `guide_items`, the three lists concatenated in gate → primary
→ secondary order, for consumers that want everything.

### `Style::GuideItem`

A guideline as used by a particular guide. Replaces `Guideline::Configured`
*and* the bare guideline classes beside it — one entry type, not two.

```ruby
class HeadMusic::Style::GuideItem
  attr_reader :guideline, :config

  def self.wrap(entry) = entry.is_a?(GuideItem) ? entry : new(entry)

  def assess(voice, tier) = guideline.assess(voice, self, tier)

  def ==(other) # by guideline and config; also eql? and hash
end
```

Guideline plus configuration, and nothing else. `Guideline.with` returns a
`GuideItem`, so all 87 configured entries keep their source verbatim —
including the three guidelines that override `.with` with a positional first
argument (`MinimumThreshold`, `MaximumNotes`, `Contoured`), all of which `super`
into it.

No `weight`, no `gate`, no `tier`, no `with` on the item, no `guide`
back-reference, no `position`. The reserved-key problem the earlier draft of this
story had to design around — partitioning `weight:` and `gate:` out of the
options hash by name — disappears with them: every key in `config` goes to the
guideline, because nothing else is in there.

### `Style::GuideItemAssessment`

One guide item applied to one voice. A frozen value object.

```ruby
class HeadMusic::Style::GuideItemAssessment
  attr_reader :voice, :guide_item, :tier, :marks, :fitness

  delegate :guideline, :config, to: :guide_item

  def adherent? = fitness == 1
  def start_position ... def end_position ...
end
```

`tier` is stamped at assess time from the list the item came out of, not read off
the item — a shared item has no single tier, but an assessment is per-analysis
and never shared.

`message` continues to come from the guideline's `#message` in this story;
`violation_key` and `violation_values` are story 3.

### `Style::Guideline.assess`

The one public analysis seam.

```ruby
class HeadMusic::Style::Guideline
  def self.with(**config) = HeadMusic::Style::GuideItem.new(self, config)

  def self.assess(voice, guide_item, tier)
    analyzer = new(voice, **guide_item.config)
    HeadMusic::Style::GuideItemAssessment.new(
      voice: voice, guide_item: guide_item, tier: tier,
      marks: analyzer.marks, fitness: analyzer.fitness, message: analyzer.message
    )
  end

  private_class_method :new
end
```

**Guideline bodies do not change.** The instance survives as a private analyzer,
because it is the analysis context and it is doing real work: `Contoured` threads
a `TrendWalk` through a five-method zigzag and memoizes `@trend_directions`;
`ConsonantClimax` memoizes two tonic intervals behind twenty-five predicates; the
base class memoizes `@other_voices`, `@cantus_firmus`, `@higher_voices`,
`@positions`. Making these class methods would either thread `voice` and `config`
through three hundred private methods or reintroduce a per-call context object —
which is the instance, unnamed. Keeping it and making it unreachable costs
nothing.

`Guideline#weight` and `#gate?` are removed, along with `self.default_weight`,
`self.default_gate?`, and `Contoured::DEFAULT_WEIGHT`.

### `Style::GuideAssessment`

Renames `Style::Analysis`. `analyze(voice)` becomes `assess(voice)` and returns
one of these rather than an array.

```ruby
class HeadMusic::Style::GuideAssessment
  attr_reader :guide, :voice

  def guide_item_assessments ...   # replaces #annotations
  def fitness ...
  def adherent? ...
  def messages ...
end
```

`Analysis#annotations` is removed rather than kept as a delegating reader — a
consumer that wants the old shape should say so explicitly.

### Grading: tier replaces weight

```
fitness = Π(gate fitnesses) × Σ(wᵢ · fᵢ) / Σ(wᵢ)

  where w = φ⁻¹ / count(primaries)    for :primary
          = φ⁻² / count(secondaries)  for :secondary
```

`weight` disappears as a per-entry attribute. In all of `lib/` it has exactly two
non-default sources — `Contoured.default_weight` = φ⁻¹, and `ContourMelody`'s
`WEIGHTED_PEERS`, where the inherited peers split φ⁻² between them. Every other
entry across all seventeen guides is `1.0`, and there are no explicit `gate:` or
`weight:` overrides anywhere in `lib/`. Those two numbers *are* the tier scheme,
and φ⁻¹ + φ⁻² = 1.

`contour_melody.rb`'s `GATES, WEIGHTED_PEERS = begin … end` block deletes
entirely, and the golden ratio leaves the guideline classes for the grading
arithmetic, where it is about focus rather than about contour.

**This is a breaking change to a public seam, and lands as 20.0.**

## Migration mapping

Mechanical, because there are no explicit overrides to interpret:

- **`gate_items`** — the entries whose guideline is a `MinimumThreshold`
  subclass (`MinimumNotes`, `MinimumMelodicIntervals`). These are exactly
  today's gates.
- **`secondary_items`** — only `ContourMelody`'s demoted peers.
- **`primary_items`** — everything else.

Deciding whether that split is *right* is story 4, deliberately not this one.

## Scenarios

### Scenario: A bare guideline class in a declaration becomes a guide item

Given a guide declaring `primary_items Guidelines::ConsonantClimax`

When I read the entry

Then it is a `Style::GuideItem` whose guideline is `ConsonantClimax` and whose config is empty

### Scenario: A configured guideline keeps its configuration

Given `Guidelines::MinimumNotes.with(8)`

When I read the resulting guide item

Then it is a `Style::GuideItem`, and the assessment it produces measures against a minimum of eight

And the three guidelines that take a positional first argument still configure the same way

### Scenario: Config carries no grading keys

Given any guide item

When it assesses a voice

Then every key in `config` is passed to the guideline, because grading information is not in there

And the guideline answers neither `weight` nor `gate?`

### Scenario: Tier comes from the list, not the item

Given the shared `MELODIC_CORE`, declared as primaries by `DiatonicMelody` and as secondaries by `ContourMelody`

When each guide assesses a voice

Then the same `GuideItem` objects produce assessments tiered `:primary` in one and `:secondary` in the other

And `MELODIC_CORE` is unchanged, and neither guide is affected by the other

### Scenario: A guideline may appear in two lists with different configuration

Given a guide declaring `MinimumNotes.with(3)` as a gate and `MinimumNotes.with(8)` as a primary

When it assesses a voice of four notes

Then the gate passes with a fitness of 1.0, and the primary contributes a fitness of 0.5 to the rubric

### Scenario: The same guideline and config in two lists is rejected

Given a guide declaring `MinimumNotes.with(8)` in both `gate_items` and `primary_items`

When the guide class loads

Then it raises, naming the duplicated guideline, because that is double-counting rather than a two-question split

### Scenario: Removing a guideline from an inherited list matches by class

Given `SingableIntervals` configured with explicit interval lists inside a shared core

When a guide declares `primary_items *CORE, except: Guidelines::SingableIntervals`

Then the entry is removed, because `except:` matches the guideline rather than the configuration

And an `except:` on one list does not disturb a copy of the same guideline in another

### Scenario: A guide produces a guide assessment

Given any registered guide and a voice

When I call `assess`

Then I receive a `GuideAssessment` holding one `GuideItemAssessment` per guide item, each holding its item, its tier, and what it found

### Scenario: An assessment reads from both halves

Given a guide item assessment

When I read `fitness` and `tier`

Then fitness comes from the analysis and tier from the list the item was declared in

And the assessment is frozen, holding values rather than recomputing them

### Scenario: Every guide grades exactly as it did before

Given each of the seventeen registered guides and a fixed corpus of voices

When each assesses each voice

Then the fitness, the adherence, and the messages match the values recorded before the refactor, entry for entry

## Design notes

**A guide item is the relationship, and that is the whole point.** A guideline
class knows how to find a fault; it cannot know how much that fault matters
here, because "here" is a guide it has never heard of. Every attribute that
answers *in this guide* belongs outside the guideline. The two-definition tax was
the cost of having no object for that category.

**Tier is the list because the items are shared.** A `tier` field would be wrong
rather than merely redundant: the cores are the same frozen objects in every
guide that splats them, and `ContourMelody` demotes exactly what `DiatonicMelody`
teaches. Either tier lives outside the item or the cores must be duplicated per
guide, which is what the cores exist to avoid.

**No `Ruleset` type.** Of the four jobs such a type would do, three-lists removes
two: the gate/primary/secondary partition is the declaration itself, and
`assess` is a `map`. What survives — coercing bare classes and subtracting by
guideline — fits in the declaration form, which is less machinery for the same
protection.

**Rejected: a back-reference from the result to its item.** The smaller change:
`GuideItem#assess` builds the guideline instance and hands it the item, and the
instance delegates. Rejected because it keeps the result transitively aware of
grading, makes its interface depend on how it was constructed, and produces
something that cannot be frozen or serialized — which matters, because a
consuming application persists these.

**Rejected: `def self.fitness(voice, config)` on the guideline.** Pure class
methods would thread `voice` and `config` through three hundred private methods,
destroy the memoization those methods rely on, and lose the template-method
inheritance `MinimumThreshold` and `NoParallelPerfect` use. A float also cannot
carry marks or which violation fired, and fitness is derived from marks, so two
entry points would compute them twice. `assess` returning the whole assessment is
the same seam without those costs.

**Bit-identical fitness is the test.** Every guide's grade must come out
unchanged, which is cheap and total. That is why re-tiering (story 4) and the
i18n move (story 3) are deliberately elsewhere: a story that changes shape and
meaning at once can only be checked by reading it.

## Out of scope

- **Re-tiering the guides.** Story 4. This story preserves today's tiers exactly:
  gates stay gates.
- **`violation_key` and `violation_values`.** Story 3. `message` still comes from
  the guideline here.
- **`name_key`, `instruction_key`, and template rendering.** Story 3.
- **Multi-voice assessments.** `voice` stays singular.

## Resolved questions

- **One item type, or keep the class/wrapper duck type?** One. The duck type
  costs a second definition per attribute and gives `default_gate?` two meanings
  under one name.
- **Tier as a field or as the list?** The list. A field on a shared item cannot
  express `ContourMelody`'s demotion.
- **Does a `Ruleset` type survive?** No. Three declared lists plus `except:`
  cover its surviving jobs.
- **Where do `weight` and `gate` live?** Nowhere. Tier replaces both.
- **Does `Guideline` keep a class-level `default_tier`?** No. No guideline's tier
  is intrinsic; it is the guide's editorial judgment.
- **Back-reference or value object?** Value object. `GuideItemAssessment` holds
  what was found and what it was found against, and recomputes nothing.
- **Does `Guideline` keep `#new(voice)` as the seam?** No. `assess` replaces it,
  and `new` becomes private. The break is what 20.0 is for.
- **Does `Analysis#annotations` survive?** No. A clean break, with
  `guide_item_assessments` as the only reader. (`Analysis#messages` survives
  under `GuideAssessment`; its `annotation_messages` alias is dropped in story
  1.)
- **A DSL or plain constants for the three lists?** A DSL. It gives `except:`,
  coercion, appending, and the duplicate check one home, and it avoids the
  constant-lookup trap `Guides::Base.ruleset`'s indirection exists to defend
  against — a subclass that omits a list would otherwise silently inherit its
  ancestor's.

## Open questions

None outstanding.

## Implementation Plan

[to be filled in by /stories plan]
