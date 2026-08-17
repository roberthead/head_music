<!--
metadata:
  created_at:   2026-08-12T16:05:34-07:00
  activated_at: 2026-08-16T17:14:51-07:00
  planned_at:   2026-08-16T17:41:08-07:00
  finished_at:  2026-08-16T20:27:14-07:00
  updated_at:   2026-08-16T20:27:14-07:00
-->

# First-Class Guide Items

AS a developer extending the style layer

I WANT a guide to declare its guidelines in three named tiers, each entry one kind of object that knows its guideline and its configuration

SO THAT a new per-entry attribute is one definition rather than two, a guide's editorial structure survives into what a consumer reads, and an entry can be asked a question without first asking what shape it is

Story 2 of the [Style Assessment Model](../epics/style-assessment-model.md).
[Story 1](../done/rename-annotation-to-guideline.md), renaming `Annotation` to
`Guideline`, has landed; this story uses the new names throughout.

## Background

A ruleset is a mixed array. Across the 23 registry entries — 17 guide classes
plus 6 contour configurations — there are 304 entries: 217 bare guideline
classes and 87 `Configured` wrappers. (Across the 17 classes alone it is 227;
the contour configurations are the only guides with two tiers, so any check
that iterates 17 rather than `Guide::ALL` misses the interesting case.) The analyze
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

`weight` disappears as a per-entry attribute. It has exactly two sources —
`Contoured.default_weight` = φ⁻¹, and `ContourMelody`'s `WEIGHTED_PEERS`, where
the inherited peers split φ⁻² between them. Those two numbers *are* the tier
scheme. Measured across `Guide::ALL`: 224 entries at `[1.0, gate: false]`, 14 at
`[1.0, gate: true]`, 60 at `[φ⁻²/10, false]`, and 6 at `[φ⁻¹, false]` — exactly
the migration mapping below.

Two corrections to earlier drafts of this story. There are no literal `gate:`
overrides, but **60 runtime entries do carry `weight:`**, generated by
`contour_melody.rb:23` across the six contour configurations — so a spec written
from "no explicit overrides" only passes after the grading switch. And
**φ⁻¹ + φ⁻² is not 1.0**: the gem derives `GOLDEN_RATIO_INVERSE = 1 / GOLDEN_RATIO`,
which lands one ULP short at `0.99999999999999989`. The budgets are normalized by
their own sum, so this does not change a grade — but see the plan, because naive
weighting does.

`contour_melody.rb`'s `GATES, WEIGHTED_PEERS = begin … end` block deletes
entirely, and `Contoured::DEFAULT_WEIGHT` leaves the guideline classes for the
grading arithmetic, where the ratio is about focus rather than about contour.
(The golden ratio itself stays in the guidelines — `contoured.rb:36` and
`mostly_conjunct.rb:9` use it for mark fitnesses, which is unrelated.)

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

Given each of the 23 registry entries and a fixed corpus of voices

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

## Learnings

### What the process caught

**The plan's most valuable output was finding that this story's own formula was
wrong.** The tier arithmetic as specified — scale each rubric weight by φ⁻¹/n,
divide the sum back out — drifts about one ULP on 388 of 2,622 rows, because
nearly every guide is all-primary and multiplying then dividing by the same
constant is exact in real arithmetic and lossy in binary. It would have failed
this story's own bit-identical test, and under any tolerance it would have
shipped unnoticed. Caught by measuring rather than reasoning, before a line was
written.

**"Five of seven steps done" was about 40% of the work.** The plan deliberately
front-loads the steps that keep the oracle empty, so the entire behavioral delta
lands in one small red window at step 6. Step count is a poor progress signal on
a plan shaped that way — a `finish` attempt partway through had to be refused.

**An agent refused to write a spec around a bug.** `Guide.get` still duck-checked
`respond_to?(:analyze)` after `analyze` was removed, so it silently returned nil
for a guide class. The agent fixing that spec file could have made its two
failures pass by asserting the broken behaviour; it said doing so "would encode
the bug as intended behavior" and reported it instead. The same hole existed in
`GuideAssessment`'s duck-check.

**The reviewer distrusted the baseline's provenance and re-derived it.** It
noticed `before.json`'s mtime predated its capture script, and that the script
named a class that does not exist at the merge-base — so the artifact might have
come from an intermediate commit. It built a worktree at the merge-base, ran the
original script there, and got the same hash. An artifact's timestamps and its
generator's contents are evidence about whether it means what it claims.

### What went wrong

**The hand-written edits were the least-reviewed thing in the diff.** Four
defects, none caught by their author: `except:` accumulating across calls rather
than applying per call, which would have silently dropped a guideline from a
rubric; `GuideItem` freezing itself but not its configuration; `assess` returning
an Array where the story specified a `GuideAssessment`; and a deep-freeze broad
enough to break lazily-memoizing rudiments. The same pattern appeared in story 1,
so it is a habit rather than an accident: delegated work gets scrutinised and
directly-authored work does not.

**Fifteen deleted examples each had a good reason and collectively left two
gaps.** Four agents removed coverage in parallel. Every deletion was individually
correct — the properties genuinely no longer existed — but nobody owned the
aggregate, and the tier arithmetic and the gate declaration ended up untested.
Auditing what *survived* found it. Delegated deletion needs a whole-diff audit,
not just per-deletion justification.

### Worth carrying forward

- **Deep-freezing is not uniformly safe here.** Rudiments memoize lazily, so
  freezing a `DiatonicInterval` breaks it at the first question. Freeze
  containers and strings; leave domain objects alone.
- **The oracle is scaffolding, not a regression test.** It proved the central
  claim and cannot be re-run from the repo. Either commit it as a rake task or
  accept that the bit-identical guarantee expires with the session that made it.
- **Bit-identical is the right bar for a refactor and the wrong one for a fix.**
  It locks in current behaviour including current bugs, which is exactly why
  story 4 abandons it for a before/after table.

## Review

Reviewed 2026-08-16 at `314b34e`, against
`git diff $(git merge-base main HEAD)...HEAD -- lib spec README.md references CHANGELOG.md`
— 116 files, +1272/-986 across seven commits. All findings are fixed in
`314b34e`; the verdicts below describe the reviewed state.

### Scenarios

Every scenario verified by running it, not by reading the diff.

| Scenario | Verdict | Evidence |
| --- | --- | --- |
| Bare guideline class becomes a guide item | ✅ | `GuideItem.wrap(ConsonantClimax)` → item, empty config |
| Configured guideline keeps its configuration | ✅ | Includes all three positional-argument overrides |
| Config carries no grading keys | ✅ | 0 of 304 declared items carry `:weight` or `:gate`; the readers do not exist |
| Tier comes from the list, not the item | ✅ | `DiatonicMelody.primary_items` and `ContourMelody`'s secondaries are **`object_id`-identical**; neither guide mutates the other |
| A guideline may appear in two lists with different config | ✅ | Constructed on a throwaway guide: gate 1.0, primary 0.5, overall 0.5 — as specified. No shipped guide does this yet |
| Same guideline and config in two lists is rejected | ✅ | Raised as designed |
| `except:` matches by guideline class | ✅ | One `SingableIntervals`, the configured one; the shared core keeps its bare class |
| A guide produces a guide assessment | ✅ | |
| An assessment reads from both halves | ✅ | Frozen; tier from the declaration, fitness from the analysis |
| Every guide grades exactly as it did before | ✅ | See below |

**No out-of-scope leakage.** Grepped for `violation_key`, `violation_values`,
`name_key`, `instruction_key`, and multi-voice work: zero hits. Re-tiering did
not leak either — gates across `Guide::ALL` are exactly the `MinimumThreshold`
subclasses, and secondaries appear only in the six contour configurations.

### The bit-identical claim, and its one weakness

The reviewer did not take the baseline on trust. It noticed that
`before.json`'s mtime predated the capture script's, and that the script
referenced `Style::GuideAssessment` — a class that does not exist at the
merge-base — so the artifact could have come from an intermediate commit. It
created a git worktree at the merge-base itself, ran the original script there,
and got the same md5 (`f0229df2088d67cba0971ebd7ca6682c`). The baseline is
genuinely pre-refactor, and the current tree matches it byte for byte: 2,622
rows, 23 guides, 34,656 item rows.

**That evidence is not reproducible from the repo.** The oracle lives in a
session scratchpad and is not committed, so a reader of the commit history
cannot re-verify it. The suite covers the tier arithmetic in the abstract and
pins concrete numbers per guide, but nothing in it asserts that all 23 guides
grade identically to 19.0.0 across the corpus. Worth a committed rake task if
that guarantee is meant to survive.

### Findings, all fixed

**1. `GuideItem` froze itself but not its configuration.** Demonstrated, not
theoretical: the `LargeLeaps` item is shared by identity across `DiatonicMelody`
and all six contour guides, and its `recovery` array was mutable. Appending to
it corrupted every one of them at once and changed the `hash` of an object
reporting itself frozen — the property duplicate rejection and value equality
depend on. Now deep-frozen through containers and strings, but deliberately not
through rudiments: a config value can be a `DiatonicInterval`, and those memoize
lazily, so freezing one breaks it at the first question. That distinction was
found by the suite when the first, broader version failed.

**2. Duplicate rejection had no automated coverage.** The design's own guard
against declaring the same guideline and configuration in two tiers was
verified only by hand. `GuideItem` had no unit spec at all — `.wrap`, equality,
hashing, and immutability were exercised only incidentally. Added.

**3. Three comments described mechanisms that no longer exist** — `analyze`,
and `GuideItem#new(voice)` — in `guides/configured.rb` and twice in `guide.rb`.
The drift a green suite cannot catch.

**4. Declaring no tiers raised `NotImplementedError`**, a `ScriptError` that an
ordinary `rescue` does not catch, unlike the two `ArgumentError` guards beside
it. Now `ArgumentError`.

### Confirmed sound, with work behind the answers

- **The equal-weight normalization.** φ⁻¹/a == φ⁻²/b is unreachable for integer
  counts because φ is irrational; brute-forced to 200 with no floating-point
  coincidence. And a collision would be harmless anyway — equal weights *are* an
  unweighted mean.
- **Singleton declaration state.** Class-instance variables do not leak to
  subclasses; a subclass declaring nothing raises rather than inheriting.
- **The `assess` / `assess_items` split.** Only guides define `assess_items`, so
  the duck-check cannot admit a guideline. The two return genuinely different
  things.
- **`private_class_method :new`.** Nothing in `lib/` calls it outside
  `Guideline.assess`; the 13 spec sites using `send` are deliberate.

### Known, accepted

Two `ContourMelody` examples were deleted without a like-for-like successor:
one asserted the contour is the worst-scoring item on a given voice, the other
a specific gate haircut. Their mechanism is now covered generically, but that
concrete instance is pinned only by the oracle — which is not in the suite.

## Implementation Plan

Seven commits. Steps 1–5 keep the suite green and the oracle empty; only step 6
carries a behavioral delta, and it is small in file count *because* 1–5 went
first.

### Problem 1 — configured guides: a reader/writer split

The class-level DSL cannot express `ContourMelody`, whose entries vary by
configuration. Resolution: the macros **write**, and `items_by_tier` is the
single **reader** that a configured guide overrides with a keyword signature —
exactly what `Guides::Base.ruleset` does today at `base.rb:14-16`, so it is not
new machinery, and `method(:items_by_tier).parameters` keeps working as the
`.with` arity guard.

```ruby
class HeadMusic::Style::Guides::Base
  TIERS = %i[gate primary secondary].freeze

  class << self
    # Overloaded by arity: entries declare, no entries read.
    def gate_items(*entries, except: nil)
      entries.empty? && except.nil? ? items_by_tier[:gate] : declare(:gate, entries, except)
    end
    # primary_items, secondary_items identically

    # The one reader. A guide whose lists vary by configuration overrides this
    # with a keyword signature, so an unconfigured use raises instead of
    # grading against nothing at a plausible 1.0.
    def items_by_tier = @items_by_tier ||= normalize(declarations)

    def guide_items = items_by_tier.values.flatten.freeze

    protected

    # Wraps bare classes, applies except: per list, freezes, rejects the same
    # (guideline, config) in two tiers, and raises if all three are empty.
    # Shared by the macro path and by a configured guide's override.
    def normalize(tiers) = ...

    private

    # Per class on the singleton, never inherited: a subclass that omits a list
    # gets an empty list rather than its ancestor's.
    def declarations = @declarations ||= {}
  end
end
```

`ContourMelody` becomes one override, with no lambdas and no callable entry type:

```ruby
def self.items_by_tier(contour:, minimum_melodic_intervals: nil)
  normalize(
    gate: [*DiatonicMelody.gate_items,
           (Guidelines::MinimumMelodicIntervals.with(minimum_melodic_intervals) if minimum_melodic_intervals)],
    primary: [Guidelines::Contoured.with(contour)],
    secondary: DiatonicMelody.primary_items
  )
end
```

`DiatonicMelody.gate_items` returns the **same frozen `GuideItem` objects**
DiatonicMelody grades, which satisfies the shared-items scenario by
construction. `ContourMelody.gate_items` with no args raises
`missing keyword: :contour` — preserve the `/requires configuration/` message
that `contour_melody_spec.rb:158` asserts.

**Cost:** two declaration shapes at the guide layer — macros for 17 classes, a
method override for 1. Accepted because it is one class. Rejected: deferred
lambdas in lists (adds a callable entry type to every list's contract for one
guide) and late-bound config on `GuideItem` (puts unresolvable state inside the
value object).

**Load-time warm-up** (`guide.rb:53`): `ALL.each(&:ruleset)` → `ALL.each(&:guide_items)`,
which is *wider* — it also applies every `except:`, runs the duplicate check, and
rejects a guide declaring nothing. `guide_spec.rb:115`'s
`instance_variable_defined?(:@ruleset)` → `:@items_by_tier`.

### Problem 2 — the oracle, and a float trap that would have broken it

**The baseline is captured**: 2,622 rows · 23 guides · 34,656 item rows, md5
`f0229df2088d67cba0971ebd7ca6682c`, byte-identical across two runs. A SimpleCov
stub avoids the `coverage/.last_run.json` poisoning rather than cleaning up
after it.

**The story's formula, implemented naively, fails its own acceptance test.**
`Σ((φ⁻¹/n)·fᵢ) / Σ(φ⁻¹/n)` accumulates rounding that `Σfᵢ/n` does not — measured
at 388 of 2,622 rows drifting ≤1.15 ULP, and independently at 2067/5000 on
synthetic input. 22 of 23 entries are all-primary, so it hits nearly everything.
The contour guides are unaffected, since φ⁻²/10 is the same expression as today's
`PEER_WEIGHT_BUDGET / peers.length`.

Do not loosen the test — **normalize the weights**. A weighted mean is invariant
under positive rescaling, so an all-equal weight vector *is* an unweighted mean
and must be computed as one. Verified: 0/5000 mismatch normalized.

```ruby
TIER_BUDGETS = {primary: HeadMusic::GOLDEN_RATIO_INVERSE,
                secondary: HeadMusic::GOLDEN_RATIO_INVERSE**2}.freeze

# A rubric whose weights are all equal is an unweighted mean, computed as one:
# scaling by phi^-1/n and dividing it back out is exact in real arithmetic and
# lossy in binary, and 22 of the 23 registry entries are all-primary.
def rubric_weights
  counts = rubric.group_by(&:tier).transform_values(&:size)
  raw = rubric.map { |a| TIER_BUDGETS.fetch(a.tier) / counts[a.tier] }
  raw.uniq.one? ? Array.new(raw.size, 1.0) : raw
end
```

Deriving `counts` from the rubric also dodges `φ⁻¹/0 → Infinity` for a guide with
zero primaries.

**Schema.** `guide`/`corpus`/`voice`, guide `fitness` (`.round(12)`), `adherent`,
sorted `messages`, and per-item `tier/ShortName/config_sig` + `fitness` +
`marks_count` are compared **exactly**. `weight` is **absent from both files** —
it is replaced, not preserved, and synthesizing it would prove nothing the
fitness column does not. The before-script *derives* tier and asserts the
derivation, so an unclassifiable entry aborts the capture: `gate?` → `:gate`
(assert weight 1.0); explicit `weight:` → `:secondary` (assert φ⁻²/10); else
`:primary` (assert ∈ {1.0, φ⁻¹}). `config_signature` strips `:weight`/`:gate`,
which is what makes the two sides comparable.

Because the story makes duplicates legal, key items on `(tier, guideline, config)`
— today no guide has two entries of one guideline class, so story 1's sort by
class name would be ambiguous here.

**Check the run's `rows=2622 guides=23 items=34656` line before trusting a silent
diff — two empty files also diff clean.**

### Steps

1. **`Guideline::Configured` → `Style::GuideItem`** *(green, oracle empty)*
   `git mv` to `lib/head_music/style/guide_item.rb`; top-level class;
   `guideline_class`→`guideline`, `options`→`config`; add `.wrap` and
   `==`/`eql?`/`hash` (copy `guides/configured.rb:45-52`). **Keep `#new(voice)`,
   `#with`, `#default_gate?` as scaffolding** — that is what keeps it green.
   Touches `guideline.rb:36-38`, `lib/head_music.rb:186`, `spec_helper.rb:36-41`,
   12 `configured(...)` sites, 6 `Guideline::Configured` references.
2. **`Style::Analysis` → `Style::GuideAssessment`** *(green)* — two `git mv`s at
   >95% similarity. **Keep `#annotations`**; its return type does not change until
   step 5. 25 `Analysis.new` sites across 20 spec files, plus `README.md:65`.
3. **Three-list DSL replaces `RULESET`** *(green, oracle empty — biggest spec diff)*
   Grading still reads `gate?`/`weight` off instances and `secondary_items` still
   carries `weight: φ⁻²/10` in config; that is what keeps the oracle empty.
   All 17 guide classes, `base.rb`, `guides/configured.rb`, `guide.rb:53`,
   `species_melody.rb:35-37`, `species_harmony.rb:29-31`, `diatonic_melody.rb:7`
   (`except:`'s only caller), `contour_melody.rb`. **229 `RULESET` refs across 20
   spec files.** Add an `item(klass)` matcher beside `configured`.
   `base_spec.rb:23-28,35-40` uses `const_defined?(:RULESET, false)` to enumerate
   real guides and needs a new predicate.
4. **Add the assess seam beside the old one** *(green, additive only)*
   `guide_item_assessment.rb` (frozen; lift `flattened_marks` from
   `guideline.rb:71-77,97-99`; **temporary `weight`/`gate?` readers** so step 6 is
   pure mechanics), `Guideline.assess`, `GuideItem#assess`, `Base#assess`,
   `Configured#assess`, `GuideAssessment#guide_item_assessments`. `new` is not yet
   private. Gate: a cross-check asserting `guide.assess(voice).fitness` equals the
   `Analysis`-path fitness across all 2,622 rows.
5. **Migrate guideline specs onto the assess seam** *(green file-by-file)*
   **75 `described_class.new` sites across 57 of 58 guideline spec files** — the
   story never mentions these. Add a `spec/support` helper so each is one line:
   `subject { assess(described_class, voice, minimum: minimum) }`. Move
   `spec_helper.rb:58-74` (`marks_count`, `first_mark`, `first_mark_code`,
   `marks_array` — ~50 refs across 16 files) from reopening `Guideline` to
   reopening `GuideItemAssessment`. Two need judgment, not substitution:
   `contoured_spec.rb:52-59` (deliberately builds an invalid contour) and
   `note_fills_final_bar_spec.rb:28` (uses a `let`, not `described_class`).
6. **Close the old seam, grade by tier** *(⚠️ riskiest — the only red window)*
   Delete `analyze` (×3), `#annotations`, `GuideItem#new`/`#with`/`#default_gate?`,
   `Guideline#weight`/`#gate?`/`.default_weight`/`.default_gate?`/`DEFAULT_WEIGHT`,
   `Contoured::DEFAULT_WEIGHT`, `MinimumThreshold.default_gate?`,
   `PEER_WEIGHT_BUDGET`, the scaffolding readers. Add `private_class_method :new`.
   Rewrite grading with the normalized weights above.
   **The `respond_to?(:analyze)` duck-check breaks**: after the rename,
   `Guideline#assess`, `GuideItem#assess`, and a guide's `assess` are three arities
   under one name, so `Guide.get(Guidelines::ConsonantClimax)` would pass through
   and fail deep inside grading — the exact failure `guide.rb:56-58` and
   `analysis.rb:8-10` exist to prevent. Check the type, not the method.
   Red window ~10 files.
7. **Docs and changelog** *(green)* — `README.md:55-80`,
   `references/third-species-counterpoint.md:550-580`,
   `references/fifth-species-counterpoint.md:432,454` (both still teach
   `RULESET = [...]`), `CHANGELOG.md`, and retire
   `user-stories/backlog/guideline-tiers.md`.

### Commit granularity

One commit per step. Folding 1–2 into 3 drops those files below git's 50% rename
threshold and the reviewer loses the "same object" signal. 4 is additive, so the
new design reads without deletion noise. 5 is 58 spec files and zero lib change —
the reviewer only checks that no assertion moved. **Do not split 6**: separating
the deletions from the grading switch leaves an intermediate where
`GuideItemAssessment` answers `weight` that nothing calls, which passes
`git bisect` and misleads. Confirm with `git diff -M --summary HEAD~7..HEAD`
(expect 4 renames).

### Harder than the story implies

1. **The spec migration is the bulk of the work** — 75 `new` sites and 229
   `RULESET` references, neither mentioned in the story. Sequencing step 5 before
   `new` goes private is the difference between a ~10-file and a ~70-file red
   window.
2. **A guide with three empty lists would silently grade 1.0.** Today
   `self::RULESET` raises `NameError`, which is what `base.rb:11-16`'s indirection
   exists for. On this axis the DSL is *less* safe than the constant unless
   `normalize` raises.
3. **`contour_melody_spec.rb:284-298` duplicates the grading formula by hand**
   from `weight`/`gate?` and asserts `fitness == 0.8 × rubric_mean`. It will fail
   against a correct implementation and must be rewritten, not migrated.
4. **`contour_melody_spec.rb:20-24`** asserts non-mutation by checking no entry
   carries `weight:` — vacuous once tier replaces weight. Rewrite as "the same
   `GuideItem`s appear in both lists", with `eq` not `equal`.
5. **`config` needs deep-freezing.** `diatonic_melody.rb:16`'s `recovery: %i[...]`
   is an unfrozen array inside a hash used as an equality key, and
   `fux_cantus_firmus.rb:18` nests a hash. `[guideline, config].hash` is otherwise
   correct — Ruby recurses structurally.
6. **`private_class_method :new` is a signpost, not enforcement** — `allocate`,
   `send(:new)`, and a subclass redefining `new` all reopen it. The real guarantee
   is that `Base.assess` no longer calls `new`.
7. **Eager assess moves the harmony-guide crash earlier.** `cantus_firmus` is nil
   for a solo voice (`guideline.rb:116-118`) and `downbeat_harmonic_intervals` then
   raises. Today that fires on `fitness`; afterward on `assess`. Story 4 fixes the
   underlying gap.
8. **Performance improves ~3×.** Only `large_leaps.rb:27` memoizes `marks`, so
   `fitness` + `adherent?` + `messages` recompute every guideline's marks three
   times today. One regression: `message` is now computed for adherent items too;
   story 3 removes it.
9. **`:message` is a live config key** (`fux_cantus_firmus.rb:16`). "Every key in
   config goes to the guideline" is true; "config is purely behavioral" is not. It
   will collide with story 3's interpolation set.

### Decisions taken

- **`GuideItemAssessment` keeps `voice`.** The planner recommended dropping it as
  un-persistable. Overruled: the whiteboard model has `GuideItemAssessment > voice`
  explicitly, and in a persisted model that is a foreign key, not an embedded
  object. Holding a reference to an entity does not stop the assessment being a
  frozen value.
- **`assess` raises for a guide with three empty lists** — restores the loudness
  `self::RULESET`'s `NameError` provided.
- **`tier` is a required argument to `Guideline.assess`**, making the declaration
  the single source of truth. The `:primary` noise on 75 spec lines is hidden by
  the `spec/support` helper.
- **No version bump here.** `version.rb` stays `19.0.0`; bumping now would make
  `[Unreleased]` span two majors while the 19.0.0 heading is still missing. The
  release-notes ticket owns both.
