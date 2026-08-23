<!--
metadata:
  created_at:   2026-08-16T21:38:46-07:00
  activated_at: 2026-08-20T09:16:47-07:00
  planned_at:
  finished_at:
  updated_at:   2026-08-22T18:13:53-07:00
-->

# Extract the Harmonic Cores

AS a student submitting a species harmony exercise

I WANT the guide to weigh what it teaches above the general two-part craft it inherits,
and to weigh a prohibition above a preference

SO THAT the one rule that makes second species *second species* carries more of my
grade than the seven rules about two-part writing that every harmony guide shares

Follows [Re-tier the Guides](../done/re-tier-the-guides.md), which folded the equivalent
melodic demotion into its own scope and left the harmonic question open.

## Background

`Guides::SpeciesHarmony` holds three constants and a list-building helper.
`HARMONIC_GATES` is the two-item precondition added late in the re-tiering.
`HARMONIC_CORE` is seven guidelines about two-part writing in general —
contrary approach to perfection, no crossed or overlapping voices, consonant
downbeats, no parallel perfects on downbeats, prefer contrary motion, prefer
imperfect. `DIMINUTION_HARMONIC_CORE` adds two more for the species that set
several counterpoint notes against each cantus firmus note.

Every harmony guide splats the core wholesale, and the result is that the core
*is* the rubric. Recomputed from `items_by_tier` on this branch:

| Guide | primaries | from the cores | its own | secondaries |
| --- | ---: | ---: | ---: | ---: |
| `first_species_harmony` | 9 | 7 | 2 | 0 |
| `second_species_harmony` | 10 | 9 | 1 | 0 |
| `third_species_harmony` | 10 | 9 | 1 | 0 |
| `third_species_triple_meter_harmony` | 10 | 9 | 1 | 0 |
| `fourth_species_harmony` | 11 | 8 | 3 | 0 |
| `fifth_species_harmony` | 12 | 9 | 3 | 0 |
| `combined_first_second_third_species_harmony` | 8 | 7 | 1 | 0 |

Under a flat rubric, `SecondSpeciesHarmony` gives nine tenths of its grade to
rules it did not write and one tenth to `WeakBeatDissonanceTreatment` — the only
thing that makes it second species. The combined guide is worse: one eighth,
for a guide covering three species.

This is the same defect the melodic demotion addresses, and it is sharper here,
because the harmony cores are larger relative to what each guide adds.

## What re-tiering will and will not fix

Measured on this branch, before any change: a valid Fux first-species line
scores **1.000** against `ThirdSpeciesHarmony`, with every rubric item adherent
— including `ThirdSpeciesDissonanceTreatment`, which returns 1.0 because a
first-species line has no dissonances to treat. Across all 26 Fux first-species
voices the seven harmony guides span **0.973–0.982**, and `third_species_harmony`
(0.978) grades the line *higher* than `first_species_harmony` (0.976).

**Re-weighting cannot move a rubric whose items are all 1.0.** No decision below
changes that 1.000. That defect is
[Tell the Species Apart](../backlog/tell-the-species-apart.md). This story is the
weighting decision alone, and its measurements compare a line against *itself*
before and after, as the melodic story did (0.883 → 0.561).

## The decisions

Both open questions are settled. The reasoning is recorded here because the
numbers behind it are not obvious and the counter-arguments are real.

### Tier is the list; strength is the rule

The rubric gains a second axis, orthogonal to tier.

**Tier** stays what it is — the list a guide declares an item in, `gate`,
`primary`, or `secondary`. It cannot be a property of the item, for the reason
`Guides::Base` already gives: `ContourMelody` treats as background exactly what
`DiatonicMelody` teaches, and one frozen item cannot carry both.

**Strength** is `strong` or `weak`, and it *is* a property of the item, because
that conflict does not arise. `PreferContraryMotion` is a preference in every
guide that declares it; `NoParallelPerfectOnDownbeats` is a prohibition in all
of them. There is no guide in the tree that would need the same rule at a
different strength. It is declared on the Guideline class, defaults to `strong`,
and is overrideable at `GuideItem` construction for the tradition-dependent case
— `ApproachPerfectionContrarily` is prohibited in Fux and merely cautioned in
some later traditions.

`GuideItem` delegates it; `GuideItemAssessment` stamps it alongside tier, for the
reason that class already gives for stamping tier — it is a frozen value object
meant to be persisted and compared without the analysis machinery.

### The arithmetic

- Tiers keep their budgets: primary φ⁻¹, secondary φ⁻². Fixed, so what a guide
  teaches cannot erode as inherited guidelines accumulate.
- Within a tier, `strong` weighs 2 and `weak` weighs 1, normalized by that
  tier's own total.
- Gates keep multiplying: `fitness = gate_factor × rubric_fitness`.

The alternative considered and rejected was a single global weighted mean over
weights of 4 / 2 / 2 / 1 (primary-strong / primary-weak / secondary-strong /
secondary-weak), with no tier budgets at all. It is the same 2:1 on both axes and
it behaves well on today's guides, but the collection ratio becomes a consequence
of how many items each tier happens to hold, and it erodes:

| inherited strong guidelines added | taught-rule share, global weights | with tier budgets |
| ---: | ---: | ---: |
| +0 | 0.200 | 0.206 |
| +2 | 0.167 | 0.206 |
| +4 | 0.143 | 0.206 |
| +8 | 0.111 | 0.206 |

Measured on the case that motivated the concern: `ContourMelody` declares
`primary: [Contoured.with(:arch)]` against `DiatonicMelody`'s eleven primaries as
secondary. Under global weights the taught rule holds **0.190** of the grade, and
a trough submitted for an arch scores **0.882** — worse than the 0.618 it scores
today. A ceiling on the secondary share was considered as a repair; the ceiling
value that preserves today's severity is φ⁻², at which point it binds on every
guide in the tree and the tier half of 4 / 2 / 2 / 1 is doing nothing the budget
was not already doing. So: keep the budgets, and let the weights carry strength.

### Empty tiers renormalize; a guide with no primary raises

`rubric_fitness` already divides by the actual weight sum rather than assuming
the budgets total 1, and that behavior is deliberate and stays:

| rubric | Σw | score |
| --- | ---: | ---: |
| primary only, one item at 0 | 0.618 | 0.0000 |
| primary only, three items, one at 0 | 0.618 | 0.6000 |
| secondary only, all adherent | 0.382 | 1.0000 |
| secondary only, one item at 0 | 0.382 | 0.3333 |
| both tiers, primary at 0 | 1.000 | 0.3820 |

A lone tier takes the full range. Note the second row: "a primary at 0 zeroes the
grade" holds when that item *is* the primary tier — true of the six contour
guides and no others — not when it is one primary among several.

A guide declaring **no primary items raises**, extending the `ArgumentError` that
`Base#normalize` already raises when every tier is empty. A guide that is all
background has no subject, and grading it 1.0 in silence is the same "nothing to
find fault in" confusion the epic already tracks. All 23 registered guides
declare at least one primary today, so this closes a door rather than fixing a
break.

### Both harmonic cores demote wholesale

As melody does. `HARMONIC_CORE` and `DIMINUTION_HARMONIC_CORE` go to
`secondary_items` together. The alternatives — demoting only `HARMONIC_CORE`, or
keeping the parallel-perfect prohibitions primary — are retired: they used tier
as a severity dial, which is now strength's job. Keeping `ConsonantDownbeats`
primary was only ever a way to say it outranks `PreferImperfect`, and strength
now says that directly.

### Marks and weights say different things

A mark's fitness positions the guideline between 0 and 1; the weight decides how
much of the rubric that number governs. Marks are internal to the item, weights
external to it — **and marks compound while weights do not.** With
`fitness_denominator` at its default of 1, an item's fitness is the bare product
of its mark fitnesses, so the factor sets both how bad one instance is and how
fast the item collapses on repeats.

`SMALL_PENALTY_FACTOR` (φ^-0.5 ≈ 0.786) therefore stays. Its two users differ:

- `MostlyConjunct` is soft all the way through and should say so with
  `strength :weak` and ordinary marks. This is a real behavioral change, not a
  relabeling: it marks *every* skip and leap once it trips, so six leaps put it
  at 0.786⁶ = 0.236 today and 0.618⁶ = 0.056 after. Measure it.
- `SecondSpeciesBreak` uses the full penalty for an unprepared dissonance on a
  break and the small penalty for breaking too often — two severities inside one
  guideline. Both collapse into one item fitness before any weight applies, so a
  weight cannot tell them apart. It keeps both factors and stays `strong`.

The constant keeps its name and gains a comment saying which question it answers.

## What this costs

Recorded rather than glossed, because the story's own Background argued the
other way. Share of the grade, before → after:

| guide | items | taught rule | inherited prohibition | preference |
| --- | ---: | ---: | ---: | ---: |
| `first_species_harmony` | 9 | 0.111 → **0.309** | 0.111 → **0.064** | 0.111 → **0.032** |
| `second_species_harmony` | 10 | 0.100 → **0.618** | 0.100 → **0.048** | 0.100 → **0.024** |
| `third_species_harmony` | 10 | 0.100 → **0.618** | 0.100 → **0.048** | 0.100 → **0.024** |
| `third_species_triple_meter_harmony` | 10 | 0.100 → **0.618** | 0.100 → **0.048** | 0.100 → **0.024** |
| `fourth_species_harmony` | 11 | 0.091 → **0.309** | 0.091 → **0.048** | 0.091 → **0.024** |
| `combined_first_second_third_species_harmony` | 8 | 0.125 → **0.618** | 0.125 → **0.064** | 0.125 → **0.032** |
| `fifth_species_harmony` | 12 | 0.083 → **0.309** | 0.083 → **0.042** | 0.083 → **0.021** |

And the resulting grades, `second_species_harmony`, one violation at φ⁻¹:

| violated | before | after |
| --- | ---: | ---: |
| `WeakBeatDissonanceTreatment` *(taught)* | 0.9618 | **0.7639** |
| `NoParallelPerfectOnDownbeats` | 0.9618 | **0.9818** |
| `ConsonantDownbeats` | 0.9618 | **0.9818** |
| `PreferContraryMotion` | 0.9618 | **0.9909** |

**A parallel octave costs about half what it costs today.** That is the
counter-argument this story recorded on activation — "parallel fifths are not
background in a counterpoint exercise" — and demotion does not answer it; it
concedes it. What strength buys is that the prohibition now costs twice a
preference instead of the same, and the taught rule costs thirteen times either.
The judgment being made is that a student who breaks the lesson has not done the
assignment, while a student who writes one parallel octave has done the
assignment imperfectly.

If that judgment is wrong, the lever is `NoParallelPerfectOnDownbeats`'s own
mark or a third strength, not the tier. That is deliberately not this story.

## Scope

- Add the strength axis: `Guideline.strength` defaulting to `:strong`,
  `GuideItem` override and delegation, `GuideItemAssessment` stamping,
  `GuideAssessment#rubric_weights` honoring it.
- Classify every guideline. The proposed weak set is a starting point, not a
  finding: `PreferContraryMotion`, `PreferImperfect`, `MostlyConjunct`,
  `LimitOctaveLeaps`, `ModerateDirectionChanges`, `FrequentDirectionChanges`,
  `PrepareOctaveLeaps`, `LargeLeaps`. Everything else is `strong` by default,
  and each weak call needs a one-line reason.
- Demote `HARMONIC_CORE` and `DIMINUTION_HARMONIC_CORE` to `secondary_items`.
- Raise when a guide declares no primary items.
- Convert `MostlyConjunct` to `strength :weak` with ordinary marks, and measure
  the change to its own fitness separately from the rubric change.
- Make the declarations consistent. `SpeciesMelody.species_items` **partitions
  entries by membership** in `INHERITED_MELODIC_CRAFT` rather than trusting the
  call site, because "guides do not declare the cores the same way — some splat
  the constant, some name its members — and a hand-named inherited guideline must
  still be demoted." Today `FourthSpeciesHarmony` splats `HARMONIC_CORE` and then
  names `NoStrongBeatUnisons` individually, and `FifthSpeciesHarmony` names both
  `NoParallelPerfectAcrossBarline` and `NoStrongBeatUnisons` — all
  `DIMINUTION_HARMONIC_CORE` members reached without `diminution_items`. Adopt
  the partitioner, or make every guide use the helper.
- Fix `CombinedFirstSecondThirdSpeciesHarmony`'s missing diminution core, or
  record why its omission is correct.
- Consider whether `StartOnPerfectConsonance` and `StepOutOfUnison` — harmonic
  rules currently living in `MOVING_MELODIC_CORE`, where they score a free 1.0
  for a solo voice — should move to the harmonic cores while those cores are
  open. Recorded as a defect by the re-tiering story.

## Measurement

The tooling from the re-tiering story still works and should be reused:

```
bundle exec ruby bin/guide_grade_corpus.rb before.json   # at the merge-base
bundle exec ruby bin/guide_grade_corpus.rb after.json    # here
bundle exec ruby bin/guide_grade_table.rb before.json after.json \
  user-stories/current/extract-the-harmonic-cores.grades.md
```

**Known limit of the corpus.** Of its 142 entries, only 38 yield an assessable
harmony grade, and every one of them is first-species or ladder material — there
are no second, third, fourth, or fifth species fixtures anywhere in `spec/`. So
this story cannot compare a first-species line against a *third-species* line.
It compares each line against itself, before and after. Adding the missing
species fixtures belongs to
[Tell the Species Apart](../backlog/tell-the-species-apart.md), which needs them
to do its own job.

The corpus is a regression check, not a decision procedure: of its 252 assessable
rows only 35 fail anything, and **none of them fails a hard prohibition**. The
decisions above rest on the constructed cases in this document, not on corpus
means, which differ between candidates by about 0.005.

## Acceptance Criteria

- Every guideline carries an explicit or defaulted strength, and every `:weak`
  declaration carries a one-line reason.
- A strong guideline weighs exactly twice a weak one within the same tier, shown
  by a spec that asserts the ratio rather than a fixture grade.
- The tier budgets are unchanged and still φ⁻¹ / φ⁻², with the design comment on
  `TIER_BUDGETS` rewritten to describe both axes.
- A rubric of one tier renormalizes to the full range, covered for both tiers.
- A guide declaring no primary items raises `ArgumentError` at declaration time,
  naming the guide.
- `CombinedFirstSecondThirdSpeciesHarmony` either declares the diminution core or
  carries a comment explaining why it does not.
- The declaration form is consistent: either no guide splats a core and then
  names a member of another core individually, or the tiering is decided by
  membership so that doing so is harmless.
- A before/after grade table for every harmony guide across the assessable
  corpus, in the same shape as the re-tiering story's, with the 38-row limit
  stated in the document rather than left implicit.
- `MostlyConjunct`'s own fitness change is reported separately from its rubric
  weight change, since the two move in the same direction and would otherwise be
  indistinguishable.
- For at least one valid first-species line, the change in its grade against
  `SecondSpeciesHarmony` and `ThirdSpeciesHarmony` is reported and explained —
  including the expected result that a line adherent on every item stays at
  1.000 regardless of tiering, which is what motivates the follow-up story.
- The decision on `StartOnPerfectConsonance` and `StepOutOfUnison` is recorded,
  whether or not they move.

## Notes

Deliberately framed as an exploration. The melodic demotion was decided on one
measurement and folded into the re-tiering story mid-flight; the harmonic side
has a real counter-argument and more guides affected, so it gets its own story
and its own evidence rather than inheriting the melodic conclusion by symmetry.

The original framing of this story aimed at making a first-species line score
badly against a third-species guide. Measurement on activation showed that
outcome is unreachable by tiering — see "What re-tiering will and will not fix" —
so the goal was narrowed to the weighting question and the identification defect
was split out.

The strength axis is the larger half of this story and its blast radius is every
guide, not only the harmonic ones: the melody guides are already re-tiered, so
they get re-graded the moment strength lands. It is kept here because demoting
the harmonic cores without it is measurably worse — a demoted prohibition would
weigh 0.042 rather than 0.048, the same as a preference. If the harmonic change
needs to land narrow, the axis splits out cleanly and this story depends on it.

Two things this story deliberately does not fix, both already on record:

- The rubric stays **compensatory** — excellence elsewhere always buys back a
  violation. See [Disqualify, Don't Discount](../backlog/disqualify-dont-discount.md).
- A wrong answer cannot score worse than the guideline's own mark, whatever the
  weighting. `Contoured` marks a mismatched contour at φ⁻², so a trough submitted
  for an arch floors at 0.382 even at 100% weight. See
  [Tell the Species Apart](../backlog/tell-the-species-apart.md).

## Implementation Plan

[to be filled in by /stories plan]
