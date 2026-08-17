<!--
metadata:
  created_at:   2026-08-16T00:00:00-07:00
  updated_at:   2026-08-16T00:00:00-07:00
-->

# Style Assessment Model

The domain model for guides, guidelines, and assessment, shared between the gem
and consuming applications. This epic is the target; the stories that reach it
are listed at the bottom.

## The five types

```
Guide ──▶ GuideItem ──▶ Guideline
  │            │             │
  ▼            └──────┬──────┘
GuideAssessment ──▶ GuideItemAssessment
```

### `Style::Guides::*` — a guide (a rubric)

What is being taught and graded. One class per guide, registered in
`Style::Guide`, which stays as it is today: a lookup facade with `.get`.

| Member | Notes |
| --- | --- |
| `gate_items` | Preconditions. Fitnesses multiply against the rest. |
| `primary_items` | What this guide is about. Share φ⁻¹ of rubric weight. |
| `secondary_items` | Background craft it inherits. Share φ⁻². |
| `guide_items` | The three concatenated, in that order, for display. |
| `name_key`, `instruction_key` | Templates, derived from `key` by convention. |
| `assess(voice)` | Returns a `GuideAssessment`. Replaces `analyze(voice)`. |
| `key`, `display_name`, `category` | Unchanged. |

**Tier is the list, not a field.** This is forced rather than chosen:
`MELODIC_CORE` is splatted into six guides and `HARMONIC_CORE` into four, so
those entries are the *same frozen objects* everywhere they appear — and
`ContourMelody` demotes exactly the items `DiatonicMelody` treats as its lesson.
One shared object cannot hold both standings. Making tier the slot is what lets
the cores stay shared.

It also makes composition read as a sentence. Today `contour_melody.rb`
partitions and recomputes weights:

```ruby
gates, peers = DiatonicMelody::RULESET.partition(&:default_gate?)
peer_weight = PEER_WEIGHT_BUDGET / peers.length
[gates.freeze, peers.map { |rule| rule.with(weight: peer_weight) }.freeze]
```

Under three lists that is "everything the parent guide taught becomes background
here," and the golden ratio never appears in a guide file again.

### `Style::GuideItem` — a guideline as used by one guide

The relationship. Replaces `Annotation::Configured` *and* the bare guideline
classes that currently sit alongside it in a ruleset — one entry type, not two.

| Member | Notes |
| --- | --- |
| `guideline` | A `Style::Guideline` subclass. |
| `config` | Hash handed to the guideline, e.g. `{minimum: 8}`, `{contour: :arch}`. Also the interpolation set for every template. |
| `name`, `instruction` | Rendered here, because every template is populated from `config`. |
| `assess(voice, tier)` | `guideline.assess(voice, self, tier)`. |
| `==` / `eql?` / `hash` | By guideline and config. |

Guideline plus configuration, and nothing else. No `tier` (it is the list), no
`with` on the item (it had one caller, the peer re-weighting that three lists
removes), no `guide` back-reference and no stored `position` (both are
persistence columns; an item genuinely has no owning guide, and position is its
index in whichever list holds it).

### Guide declaration

There is no `Ruleset` type. With three ordered lists declared per guide, the
collection needed only two of the four jobs such a type would have done —
coercing bare guideline classes into items, and subtracting by guideline rather
than by object identity. Both fit in the declaration itself:

```ruby
class DiatonicMelody < Guides::SpeciesMelody
  gate_items    Guidelines::MinimumNotes.with(5)
  primary_items *SpeciesMelody::MELODIC_CORE, except: Guidelines::SingableIntervals
  primary_items Guidelines::SingableIntervals.with(ascending: ..., descending: ...),
                Guidelines::MaximumNotes.with(32),
                ...
end
```

`gate_items(*entries, except: nil)` and its two siblings coerce, subtract by
guideline class, and freeze.

`except:` is why the subtraction cannot stay `Array#-`. Today
`diatonic_melody.rb:7` reads `MELODIC_CORE - [Guidelines::SingableIntervals]`,
which works only while the core holds bare classes; configure
`SingableIntervals` upstream and the subtraction silently removes nothing,
leaving the guide grading against two conflicting interval rules with a
plausible fitness. Matching by guideline cannot fail that way. Being applied
per-list also scopes it correctly for free: an `except:` on `primary_items`
cannot strip a gate copy of the same guideline.

**Declaration-time check: no duplicate `(guideline, config)` pair across the
three lists.** A guideline appearing twice is legal and intended — see below —
but the same guideline with the *same* config in two lists is double-counting.

### `Style::Guideline` — one rule of craft

The base class of the sixty-six classes in `Style::Guidelines`. Renames
`Style::Annotation`, so `Guidelines::ConsonantClimax < Style::Guideline` reads
the way it should.

```ruby
class HeadMusic::Style::Guideline
  # The 87 existing configured call sites, verbatim. Returns a GuideItem.
  def self.with(**config) = HeadMusic::Style::GuideItem.new(self, config)

  # The only public analysis seam. Instances never escape this method.
  def self.assess(voice, guide_item, tier)
    analyzer = new(voice, **guide_item.config)
    HeadMusic::Style::GuideItemAssessment.new(
      voice: voice, guide_item: guide_item, tier: tier,
      marks: analyzer.marks, fitness: analyzer.fitness,
      violation_key: analyzer.violation_key,
      violation_values: analyzer.violation_values
    )
  end

  private_class_method :new
end
```

**The instance survives as a private analyzer.** It is the analysis context, and
it is doing real work: `Contoured` threads a `TrendWalk` through a five-method
zigzag and memoizes `@trend_directions`; `ConsonantClimax` memoizes two tonic
intervals behind twenty-five predicates; the base class memoizes `@other_voices`,
`@cantus_firmus`, `@higher_voices`, `@positions`. Making these class methods
would either thread `voice` and `config` through three hundred private methods or
reintroduce a per-call context object — which is the instance, unnamed. Keeping
it and making it unreachable costs nothing and changes no guideline body.

**No `default_tier`, and no invariant restricting tier.** No guideline's tier is
intrinsic. Any rule can be a precondition or a graded expectation, and which one
it is, is the guide's editorial judgment — see the `MinimumNotes` case below.

### `Style::GuideItemAssessment` — one guide item applied to one voice

A frozen value object. No lazy recomputation, no live analysis machinery, so it
maps directly to a persisted row.

| Member | Notes |
| --- | --- |
| `voice` | Singular, matching the rest of the gem. |
| `guide_item` | Delegates `guideline` and `config`. |
| `tier` | Stamped at assess time, from the list the item came out of. |
| `marks` | Score positions; `start_position` and `end_position` derive from them. |
| `fitness` | `0..1` float. |
| `violation_key`, `violation_values` | `nil` when adherent. `message` renders them. |
| `adherent?` | `fitness == 1`. |

`tier` is stamped rather than read off the item because a shared item has no
single tier. Assessments are per-analysis and never shared, so there is no
ambiguity here.

**Why the assessment holds the violation and the guideline does not.** Which
violation fired is decided during analysis, and a guideline may have more than
one way to fail — `ConsonantClimax` can distinguish a climax dissonant with the
tonic from a climax that repeats three times. Today it has one `MESSAGE` for
both. This is a capability the refactor unlocks rather than a translation of
what exists.

**Why `violation_values` in addition to the config.** Every template is
populated from the item's `config`, which covers today's messages —
`"Write at least %{minimum} notes."`, `"Write a melody with the %{contour} contour."`
`violation_values` is merged *over* the config for what a template can only know
after analysis: the count actually found, the offending pitch, the bar where a
parallel fifth landed. It is empty for every guideline that exists today.

### `Style::GuideAssessment` — one guide applied to one voice

Renames `Style::Analysis`.

| Member | Notes |
| --- | --- |
| `guide`, `voice` | |
| `guide_item_assessments` | Replaces `annotations`. |
| `fitness`, `adherent?`, `messages` | Arithmetic below. |

## Grading

```
fitness = Π(gate fitnesses) × Σ(wᵢ · fᵢ) / Σ(wᵢ)

  where w = φ⁻¹ / count(primaries)    for :primary
          = φ⁻² / count(secondaries)  for :secondary

  φ⁻¹ + φ⁻² = 1, so rubric weights sum to 1 when both tiers are present
```

`weight` disappears as a per-item attribute. In all of `lib/` it has exactly two
non-default sources — `Contoured.default_weight` = φ⁻¹, and `ContourMelody`'s
`WEIGHTED_PEERS`, where the inherited peers split φ⁻² between them. Every other
entry across all seventeen guides is `1.0`, and there are no explicit `gate:` or
`weight:` overrides anywhere. Those two numbers *are* the tier scheme.

The substitution should be bit-identical, and that must be proven rather than
assumed:

- `ContourMelody` has one primary (`Contoured`, at φ⁻¹) and *n* secondaries (at
  φ⁻²/n each) — exactly its current hand-computed numbers.
- Every other guide is all-primary. Rubric fitness is `Σ(wᵢfᵢ) / Σwᵢ`, so equal
  weights of φ⁻¹/n give the same mean as equal weights of 1.0.

The golden ratio moves off a guideline class — where it sits awkwardly, "for
reasons belonging to the guideline" — onto the grading arithmetic, where it is
about focus rather than about contour.

## Gates mean "not yet assessable"

The three tiers answer two different questions:

- **`:gate`** — *is this voice assessable by this guide at all?* A two-note
  melody is not a failed cantus firmus; it is not a cantus firmus. Grading its
  climax is meaningless, so a gate scales the whole grade.
- **`:primary` / `:secondary`** — *is this voice adherent?* A real quality
  judgment, traded off by weight.

**A guideline may therefore appear twice in one guide, with different config.**
`MinimumNotes.with(3)` as a gate asks whether anything is here to assess;
`MinimumNotes.with(8)` as a primary is Fux's prescription that a cantus firmus
run eight to fourteen notes. Same guideline, same fitness formula
(`actual_count / minimum`, a proportion that reads correctly either way),
different consequence.

Today the two meanings are jammed into one tier, and the seam shows:

| Guide | Entry | Today | Means |
| --- | --- | --- | --- |
| `ContourMelody` | `MinimumMelodicIntervals.with(1..2)` | gate | "did they attempt a melody" — the source comment says *"excludes non-attempts"* |
| `DiatonicMelody` | `MinimumNotes.with(5)` | gate | borderline |
| `FuxCantusFirmus` | `MinimumNotes.with(8)` | gate | a stylistic prescription |
| `FuxCantusFirmus` | `MaximumNotes.with(14)` | rubric, weight 1.0 | *the same prescription* |

The last two rows are two halves of one rule with wildly different force,
because one inherits `MinimumThreshold` and the other inherits `Annotation`.
Re-tiering fixes that, and is deliberately its own story, because it changes
grades.

## Internationalization

Three customer-facing strings, stored as keys and looked up. English is the
default and the fallback; the other six locales fall back until translated.

**All three keys name templates, and all three are populated from the
`GuideItem`'s `config`.** A guideline's name is not a fixed string any more than
its violation is: `MinimumNotes` is "minimum of eight notes" in one guide and
"minimum of three" in another. The template is the guideline's; the values are
the item's.

```yaml
head_music:
  style:
    guides:
      first_species_melody:
        name: "First Species Melody"
        instruction: "Write a melody in first species."
    guidelines:
      minimum_notes:
        name: "Minimum of %{minimum} notes"
        instruction: "Write at least %{minimum} notes."
        violations:
          too_few: "Write at least %{minimum} notes."
      contoured:
        name: "%{contour} contour"
        instruction: "Write a melody with the %{contour} contour."
        violations:
          wrong_contour: "Write a melody with the %{contour} contour."
```

Rendering, in one place:

```ruby
class HeadMusic::Style::GuideItem
  def name        = render(guideline.name_key)
  def instruction = render(guideline.instruction_key)

  private

  def render(key, **extra)
    I18n.t(key, **interpolations.merge(extra))
  end

  # Numbers humanize so that "at least eight notes" survives, and the humanize
  # gem takes a locale, so it survives translation too.
  def interpolations
    config.transform_values { |value| value.is_a?(Integer) ? value.humanize : value }
  end
end
```

`GuideItemAssessment#message` is the same call with `violation_key` and
`violation_values` merged over the item's interpolations.

- `name_key` and `instruction_key` derive from the class key by convention, the
  way `Guide.display_name_for` already derives display names. A guideline
  declares one only to override.
- **Gates are not instructions.** `MinimumNotes.with(3)` renders "Write at least
  three notes," which is a precondition, not the lesson. A consumer showing a
  guide reads `primary_items` as the lesson and `secondary_items` as background;
  the three lists make that a one-line choice.
- **A guide's templates have no config to draw on.** `ContourMelody.with(contour: :arch)`
  reaches the registry under its own key (`arch_contour_melody`), so its name is
  a plain string. Guide templates take an empty interpolation set unless a use
  for one appears.
- A template referencing a key absent from `config` raises
  `I18n::MissingInterpolationArgument` at render, not at declaration. Worth a
  load-time check in the same spirit as `Guide::ALL.each(&:ruleset)`.
- `head_music.style.guides` is currently a flat key → display-name map with one
  entry (`salzer_schachter_cantus_firmus`) and everything else derived. Nesting
  it under `name:` is a one-line change to that entry.

## What is deliberately absent

- **`weight`.** Replaced by tier.
- **`tier` on `GuideItem`.** It is the list.
- **`Ruleset`.** The three declared lists plus `except:` cover its surviving jobs.
- **`GuideItem#with`.** Its only caller was the peer re-weighting that three
  lists remove.
- **`guide` and `position` on `GuideItem`.** Persistence columns.
- **Multi-voice assessments.** `voice` is singular throughout, matching the rest
  of the gem. Harmonic guidelines reach other voices through
  `voice.composition.voices` as they do today.
- **A name for the `Guideline` instance.** It is private to `Guideline.assess`.

## Mapping from today

| Today | Becomes |
| --- | --- |
| `Style::Annotation` (as base class) | `Style::Guideline` |
| `Style::Annotation` (as result) | `Style::GuideItemAssessment` |
| `Style::Annotation::Configured` | `Style::GuideItem` |
| A bare guideline class in a ruleset | `Style::GuideItem` with empty config |
| `RULESET` (frozen `Array`) | `gate_items` / `primary_items` / `secondary_items` |
| `Style::Analysis` | `Style::GuideAssessment` |
| `Analysis#annotations` | `GuideAssessment#guide_item_assessments` |
| `Guide.analyze(voice)` | `Guide.assess(voice)` |
| `rule.new(voice)` | `guide_item.assess(voice, tier)` |
| `MESSAGE` / `#message` | `violation_key` + `violation_values` |
| `default_gate?` / `default_weight` | the list the item is declared in |
| `Style::Mark` | unchanged |

## Stories

Sequenced so that each step is verifiable on its own.

1. ✅ **[Rename `Annotation` to `Guideline`](../done/rename-annotation-to-guideline.md).**
   Sixty-three guideline classes and their specs, plus
   `Annotation::Configured` → `Guideline::Configured` and dropping the
   `annotation_messages` alias. No behavior change, suite green. Mechanical, and
   it makes story 2's diff readable.
2. **[First-class guide items](../current/first-class-guide-items.md).** `GuideItem`, the three declared lists,
   `Guideline.assess`, `GuideItemAssessment`, `GuideAssessment`, and tier-derived
   weights. Guide fitness bit-identical — a cheap and total test. Breaking to a
   public seam; lands as 20.0. Retires `guideline-tiers.md` from the backlog.
3. **[Guideline strings into i18n](../backlog/guideline-strings-into-i18n.md).**
   Forty-five `MESSAGE` constants, nine dynamic `#message` overrides, and one
   literal English sentence living in a guide file become templates plus English
   locale entries, alongside `name_key` and `instruction_key`. Depends on 2,
   because every template is populated from a `GuideItem`'s config.
4. **[Re-tier the guides](../backlog/re-tier-the-guides.md).** An editorial pass
   deciding, per entry, precondition or expectation — and gates short-circuit, so
   an unassessable voice is reported as such rather than scaled. Deliberately
   *not* bit-identical; gets a before/after fitness table instead. Fixes an empty
   voice scoring 1.000 against thirteen guides, and a crash in the harmony guides.

Stories 3 and 4 are independent of each other, and **4 runs before 3** — it fixes
live scoring defects, and 3 does not.
