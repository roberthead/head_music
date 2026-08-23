<!--
metadata:
  created_at:   2026-08-16T21:38:46-07:00
  activated_at: 2026-08-20T09:16:47-07:00
  planned_at:   2026-08-22T18:41:07-07:00
  finished_at:
  updated_at:   2026-08-22T18:41:07-07:00
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
| `combined_first_second_third_species_harmony` | 8 → 10 | 0.125 → **0.618** | 0.125 → **0.048** | 0.125 → **0.032** |
| `fifth_species_harmony` | 12 | 0.083 → **0.309** | 0.083 → **0.042** | 0.083 → **0.021** |

Two rows depend on decisions taken elsewhere in this story, and the arithmetic
does not work without them. `combined_first_second_third_species_harmony` gains
the diminution core it is missing, so it grades 10 items rather than 8 — its
preference column stays 0.032 only because the two added items are both strong.
And **`NoParallelPerfectWithSyncopation` demotes with the cores**, though it is a
member of neither constant: it is the same prohibition as the other three,
specialized for syncopation, and leaving it primary would give it φ⁻¹ of fourth
and fifth species by itself. Demoting only the two constants gives
`fourth_species_harmony` 0.206 / 0.055 / 0.027 and `fifth_species_harmony`
0.206 / 0.048 / 0.024, neither of which is the table above.

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
- Demote `HARMONIC_CORE`, `DIMINUTION_HARMONIC_CORE`, and
  `NoParallelPerfectWithSyncopation` to `secondary_items`. The last is in neither
  constant and is declared only by the two syncopated species; see the note under
  the cost table for why it belongs with the others.
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

**Known limit of the corpus.** It holds 142 entries and grades 23 guides, for
3266 rows. Of those, 994 are harmony rows and only **266 are assessable** — 38
entries × 7 harmony guides — and every one is first-species or ladder material,
because there are no second, third, fourth, or fifth species fixtures anywhere in
`spec/`. So this story cannot compare a first-species line against a
*third-species* line. It compares each line against itself, before and after.
Adding the missing species fixtures belongs to
[Tell the Species Apart](../backlog/tell-the-species-apart.md), which needs them
to do its own job.

Two denominators live in that number and must not be conflated, which is how the
re-tiering story mislabelled its own row count. **266** assessable harmony rows
across 38 entries; of those, **252** come from published fixtures (36 voices) and
**14** from two synthetic ladder-against-cantus voices.

The corpus is a regression check, not a decision procedure. Measured on this
branch, only four guidelines ever fail across the 252 fixture rows:

| guideline | fixture rows failing (of 252) | synthetic rows failing (of 14) |
| --- | ---: | ---: |
| `ApproachPerfectionContrarily` | 14 | 14 |
| `PreferContraryMotion` | 14 | 14 |
| `AvoidCrossingVoices` | 14 | 7 |
| `AvoidOverlappingVoices` | 14 | 0 |
| `ConsonantDownbeats` | 0 | 14 |
| `NoParallelPerfectOnDownbeats` | 0 | 14 |
| `NoStrongBeatUnisons` | 0 | 10 |
| `NoParallelPerfectWithSyncopation` | 0 | 4 |

**No published fixture line fails a parallel-perfect prohibition or a dissonant
downbeat.** The only rows that exercise those are the two synthetic ladders,
which fail nearly everything at once, so a before/after delta on them cannot be
attributed to any single rule. The decisions above therefore rest on the
constructed cases in this document, not on corpus means, which differ between
candidate weightings by about 0.005.

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
- A before/after grade table for **all 23 registry entries**, not only the seven
  harmony guides — strength re-grades the melody guides too, and the corpus
  script already covers all 23. In the same shape as the re-tiering story's, with
  both corpus denominators stated in the document rather than left implicit.
- Every harmony guide holds the same set of guidelines after the change as
  before, with none lost or gained — rewriting seven guides through a
  partitioner can drop a rule and still produce a plausible number.
- An all-strong rubric grades bit-identically to today, pinning that the strength
  axis is inert until a guideline declares `:weak`.
- `MostlyConjunct`'s own fitness change is reported separately from its rubric
  weight change, since the two move in the same direction and would otherwise be
  indistinguishable — and separately again for the three guides where it is
  primary (`fux_cantus_firmus`, `salzer_schachter_cantus_firmus`,
  `diatonic_melody`) versus the 13 where it is secondary, because a weak item
  entering a previously uniform tier re-weights every sibling in those three.
- The first-species measurement names the corpus entry it was taken from, so the
  number can be re-derived from the committed grade table rather than trusted.
- For at least one valid first-species line, the change in its grade against
  `SecondSpeciesHarmony` and `ThirdSpeciesHarmony` is reported and explained —
  including the expected result that a line adherent on every item stays at
  1.000 regardless of tiering, which is what motivates the follow-up story.
- The decision on `StartOnPerfectConsonance` and `StepOutOfUnison` is recorded,
  whether or not they move.
- `GuideItemAssessment#strength` defaults rather than being required, so the
  three existing direct-construction sites and any external consumer keep
  working; the addition is noted in `CHANGELOG.md`, and `README.md`'s lines
  describing the φ⁻¹/φ⁻² split and the assessment surface are brought current.

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

Seven steps, ordered so that each is independently committable and so that the
one change to a guideline's own fitness is measured apart from the changes to
rubric weight. Steps 1 and 2 move no grade and one grade respectively; step 4 is
where the numbers in "What this costs" actually land.

### 0. Capture the baseline before touching anything

The merge-base is the tip of `main`, and every commit on this branch touches only
`user-stories/`. So the "before" tree is the current working tree — no worktree,
no stash, no checkout.

```
bundle exec ruby bin/guide_grade_corpus.rb tmp/c0.json
```

`bin/guide_grade_corpus.rb` restores `coverage/.last_run.json` on exit, so the
coverage baseline survives the run. The script is run, never edited.

**Five captures, four single-cause deltas.** Steps 1, 2, 3 and 4 each end with a
capture, so every delta has exactly one cause. Three captures would not do: the
strength classification and the demotion land on the *same seven harmony guides*,
so a by-guide attribution rule cannot separate them — which is precisely the
defect that mislabelled 205 rows in the re-tiering story. Four deltas make the
attribution arithmetic rather than editorial.

### 1. The strength axis — numerically inert, committable alone

New `lib/head_music/style/guideline/strength.rb`, mirroring `guideline/wording.rb`
and extended alongside it. A class macro, `strength :weak, because: "…"`, where
`because:` is **required for `:weak` and rejected for `:strong`** — that makes
"every weak declaration carries a reason" true by construction rather than
asserted by a spec.

- **Not inherited.** Per-class ivar, `:strong` fallback, no superclass walk.
  `WeakBeatDissonanceTreatment` bases `ThirdSpeciesDissonanceTreatment` and
  `TripleMeterDissonanceTreatment`, which are the *taught rule* of their guides,
  and `MinimumThreshold` bases both a gate and a rubric item. An inheriting macro
  turns one careless declaration on a shared analysis base into a silent demotion
  of several taught rules. This matches `declarations`' own documented choice in
  `Guides::Base` — "never inherited: a subclass that omits a list gets an empty
  one." Cost: `ModerateDirectionChanges` and `FrequentDirectionChanges` each
  declare their own line, which this story's weak list already treats separately.
- **Validated once**, via `Strength.normalized(value)` raising `ArgumentError`
  naming the guideline and the allowed values, called from both the macro and
  `GuideItem#initialize` — the belt-and-braces shape `Contoured` already uses and
  documents. Both run at class-body evaluation, so a typo fails on `require`.
  Read the units table with `fetch`, so anything slipping past normalization
  raises `KeyError` rather than multiplying by `nil`.
- **Strength never enters `config`.** `Guideline.with(strength: nil, **options)`
  passes it as a separate keyword. This must live there because
  `MinimumThreshold.with`, `MaximumNotes.with`, and `Contoured.with` all `super`
  into it. Inside `config` it would be splatted into the analyzer, returned as an
  I18n interpolation value, and — worst — change item equality, so an overridden
  `ApproachPerfectionContrarily` would fall out of the core-membership partition
  and be graded as a taught rule at full primary weight.
- `GuideItem#initialize(guideline, config = {}, strength: nil)` resolves
  `strength || guideline.strength` **eagerly, before `freeze`**. A lazily
  memoizing `Guideline.strength` would write a class ivar during grading,
  reopening the race that `Guide::ALL.each(&:guide_items)` exists to close.
- **Strength participates in neither `==` nor `hash`.** `reject_duplicates` asks
  one question — is this rule graded twice — and strength cannot change the
  answer. If strength entered equality, declaring a rule primary-strong and
  secondary-weak would slip past the guard and double-count. Comment the
  omission, or someone will "fix" it. Extend `inspect` to show strength only when
  it differs from the guideline's declaration.
- `GuideItemAssessment` gains `attr_reader :strength`, keyword-defaulted to
  `guide_item.strength` so the three existing direct-construction sites in specs
  keep working. The comment must give the right reason, which is *not* the tier
  comment's "an item has no single standing" — that is false for strength. It is:
  a persisted assessment records the strength in force when it was graded, so
  re-classifying a guideline later cannot silently rewrite old grades.
- `GuideAssessment#rubric_weights` returns `[assessment, weight]` **pairs**, built
  by mapping over `rubric` so order is preserved by construction. Delete the
  `each_with_index` parallel-array pairing, which is correct today only by
  coincidence of ordering — the natural `group_by(&:tier)` refactor mis-pairs
  silently, with no exception and no failing test, and a swapped weight still
  lands in [0, 1].
- Compute `budget * units / total_units`, **numerator first**. Splitting the
  division first introduces an ulp of drift and silently loses the equal-weights
  collapse.
- The `raw.uniq.one?` collapse **survives verbatim**. A uniform-strength tier
  yields `budget × 2 / 2n` for every item, still all equal, so the branch still
  fires and the two specs asserting exact means stay exact. What changes is its
  reach: it stops firing whenever a tier mixes strengths.
- Rewrite the `TIER_BUDGETS` comment for both axes. It must carry the erosion
  argument — why budgets are fixed rather than derived from item counts — state
  that strength never crosses a tier boundary, and note that gates multiply
  regardless of strength.

At the end of this step nothing declares `:weak`, every tier is uniform-strength,
and **no grade in the tree moves.** That is what makes it committable alone —
and it is checkable, not merely asserted: capture `tmp/c1.json` and require that
**zero rows differ from `c0`.** An axis whose every value defaults must be a
provable no-op.

### 2. `MostlyConjunct`'s own marks — measured in isolation

Drop `fitness: HeadMusic::SMALL_PENALTY_FACTOR` so each skip and leap marks at
the default. Add the `SMALL_PENALTY_FACTOR` comment naming the question a weight
cannot answer. Do not otherwise touch `SecondSpeciesBreak`.

Capture `tmp/c2.json`. Because step 1 moved no grade, **`c1 → c2` is the mark
change alone.**

Report its three effects separately, because they are easy to confuse with the
demotion, which never touches these guides. `MostlyConjunct` is primary in
`fux_cantus_firmus`, `salzer_schachter_cantus_firmus`, and `diatonic_melody`, and
secondary in 13 others. Beyond its own fitness and its own weight, a weak item
entering a previously uniform tier re-normalizes *every sibling's* weight in
those three guides — which are the most-specced in the tree. Add a direct
item-level figure (0.236 → 0.056 on a fixed six-leap voice), since the corpus
records guide fitness only.

### 3. The classification pass

Add `strength :weak, because: "…"` to eight guidelines in eight files:
`prefer_contrary_motion`, `prefer_imperfect`, `mostly_conjunct`,
`limit_octave_leaps`, `moderate_direction_changes`, `frequent_direction_changes`,
`prepare_octave_leaps`, `large_leaps`.

**Do not add `strength :strong` to the rest.** It is the default; 55 lines of
noise would bury the eight that matter.

There are **63** `Guideline` subclasses, of which **56** are declared by a
registered guide. The seven undeclared are six abstract bases plus
`EndOnPerfectConsonance`, which is concrete and orphaned — note it, leave it.

Commit the full 56-row classification table into this document. That table, not a
spec, is the artifact demonstrating every guideline was considered; a sweep spec
asserting the weak set would be a pure change-detector whose only failure mode is
"someone made a decision." Budget this as judgment work: 56 calls with no oracle,
defended only by the table and the grade diff.

Capture `tmp/c3.json`. **`c2 → c3` is the strength re-weighting alone**, and it
moves melody guides only — the harmony guides are still all-primary and
all-strong at this point, so their rows must be identical to `c2`.

### 4. Demote the cores

Lift the partitioner into `Guides::Base` as a shared `tier_by_membership` helper
so the two marker bases are not copy-paste, and name the harmony entry point
`species_items`, so `SecondSpeciesHarmony` reads character-for-character parallel
with `FourthSpeciesMelody`.

**Partition on `guideline`, not on raw entry identity.** Normalize both sides
through `GuideItem.wrap` and compare `.guideline`.
`INHERITED_MELODIC_CRAFT.include?(entry)` works today only because no species
guide passes a *configured* core member through — the moment one does, or the
moment `ApproachPerfectionContrarily.with(strength: …)` is used, the entry
silently becomes a taught rule at full primary weight. This is the same failure
`except:` was already fixed for.

`INHERITED_HARMONIC_CRAFT` is `HARMONIC_CORE + DIMINUTION_HARMONIC_CORE +
NoParallelPerfectWithSyncopation`, the last added without putting it in a splat
constant. Convert `primary_items(` → `species_items(` in all seven harmony
guides; that is what makes `FourthSpeciesHarmony`'s hand-named
`NoStrongBeatUnisons` and `FifthSpeciesHarmony`'s hand-named pair demote
correctly *without* editing those call sites, satisfying the second branch of the
declaration-consistency criterion.

`CombinedFirstSecondThirdSpeciesHarmony` gains the diminution core. The omission
is not defensible: it covers second and third species, both diminution species,
and its melody counterpart does declare the moving-melodic guidelines.

Watch one trap: `reject_duplicates` compares across tiers, and `species_items`
calls `secondary_items` and `primary_items` separately, so a guideline named
twice — once splatted, once by hand — now lands in two tiers and raises. No guide
does this today, but it is the failure a careless conversion produces.

Capture `tmp/c4.json`. **`c3 → c4` is the demotion alone.**

### 5. Raise when a guide declares no primary

In `Guides::Base.normalize`, immediately **after** the all-tiers-empty raise, so
`SpeciesMelody`/`SpeciesHarmony` keep their current message and `base_spec`'s
`concrete_guide_class?` keeps rescuing correctly.

Correct the criterion's wording: this is not "declaration time" in general.
`items_by_tier` memoizes lazily; registered guides hit it at `require` only
because `Guide::ALL` resolves eagerly, and the six contour entries earlier still
via `Configured#initialize`. An unregistered subclass raises on first assessment.

Verify in three layers: the gem failing to load is the real guard; a spec over
`Guide::ALL` naming the failing key; and a spec declaring a throwaway
gate-plus-secondary subclass, using `stub_const` to give it a name — an anonymous
class would produce a message with an empty name, which is a latent hole in the
existing raise too. Include the configuration in the message, since the class
name alone cannot distinguish six contour configurations.

`ContourMelody` is safe: its keyword `items_by_tier` always passes a primary. Do
not try to verify via `ContourMelody.guide_items`, which raises
`missing keyword: :contour` by design.

Open question to settle here: **is a gate-only guide still legal?** It is today —
`normalize` objects only when all three tiers are empty. This rule makes it
illegal. Say so, or exempt it.

### 6. Record the `StartOnPerfectConsonance` / `StepOutOfUnison` decision

Recommendation: **neither moves**, recorded in a comment on `MOVING_MELODIC_CORE`
in `guides/species_melody.rb` — the constant a future reader will be looking at
when the question recurs — as well as here, since the criterion asks for more
than this document.

`StartOnPerfectConsonance` is not harmonic despite its name — it measures the
interval from the key's **tonic**, not from the companion voice, so it scores a
solo voice legitimately. `StepOutOfUnison` genuinely is harmonic and does score a
free 1.0 for a solo voice, but that free-1.0 defect belongs to
[Tell the Species Apart](../backlog/tell-the-species-apart.md). Moving it also
costs six assertions across the melody specs and would lift
`SecondSpeciesHarmony`'s fixture grade back over 0.7, hiding this story's one
honest regression.

If this is overridden: `FirstSpeciesMelody` and
`CombinedFirstSecondThirdSpeciesMelody` name them by hand rather than splatting,
so they would lose them entirely rather than have them demoted.

### 7. Measure, then update the joiner, then report

All five captures are already on disk by this point — `c0` through `c4`, taken at
the end of steps 0 through 4. **Only now** edit `bin/guide_grade_table.rb`. It cannot run unmodified — its
`DEMOTED`/`SPLIT` lists and its hardcoded title belong to the re-tiering story,
and it would mislabel every harmony move as "gate added." It is a post-processor
over two JSON files, not an instrument that runs on either side, so editing it
after both captures exist cannot influence them. Derive the title from the output
path; replace the buckets with demoted / reweighted / mark-softened / gated. Say
in the Measurement section that the joiner is story-specific by design.

Four joins, not one, each with a single cause: `c0 → c1` (must be empty),
`c1 → c2` (`MostlyConjunct`'s marks), `c2 → c3` (strength re-weighting, melody
guides only), `c3 → c4` (the harmonic demotion). All into
`extract-the-harmonic-cores.grades.md`, which becomes the artifact that makes
"reported separately" achievable rather than editorial.

Also update `CHANGELOG.md` and `README.md`, whose lines documenting the φ⁻¹/φ⁻²
split and the `tier` surface both become incomplete.

### Testing strategy

**Exactly one existing spec breaks**, verified by running the change over the
full suite: `spec/head_music/style/guides/second_species_harmony_spec.rb:38`,
`be > 0.7`, where the fixture goes **0.8236 → 0.6979**. The fixture fails the
taught rule at φ⁻¹, which now carries 0.618 of the rubric, so its ceiling is
0.618 × 0.618 + 0.382 = 0.7639. This is the story working. Fix it as two
expectations plus a comment carrying that derivation, so the number is not a
goalpost someone quietly moved.

New specs:

- The 2:1 ratio asserted **as a ratio**, on a mixed-strength tier: one strong and
  one weak, strong-fails → 1/3, weak-fails → 2/3, asserting
  `(1 − strong_fails) == 2 × (1 − weak_fails)`. It must be mixed-strength, or the
  equal-weights collapse hands it `[1.0, 1.0]` and the assertion passes
  vacuously. Reuse the existing graded-stub helper with a strength argument.
- Single-tier renormalization for **both** tiers, using rows 2 (→ 0.6000) and 4
  (→ 0.3333) of the edge-case table. These are the load-bearing pair, because a
  count-based rubric gives 0.667 for both. Assert the score, never Σw — the
  collapse means row 1's actual Σw is 1.0, not 0.618.
- Strength declaration, default, validation, and non-inheritance pinned
  explicitly; `GuideItem` delegation and override; `GuideItemAssessment` stamping
  and freezing; the no-primary raise naming the guide; a `base_spec` loop
  asserting no harmony guide declares a core member as primary; and the
  set-preservation check named in the acceptance criteria.
- Do not assert exact `eq` on a mixed-strength rubric — use `be_within(1e-12)`.
  The existing exact-`eq` examples are uniform-strength and stay exact.

**Coverage.** Currently 100% line and branch, so the 90% floor has headroom. The
exposure is the new methods and the new raise branch; branch coverage is on, so
both arms of the strength fallback, the validation, and the empty-primary check
each need a direct example. Run `bundle exec rake` for the gate —
`maximum_coverage_drop` compares against `coverage/.last_run.json`, so a targeted
run right after a full one will trip it.

**A green suite proves very little here.** Nothing grades a voice against a
non-matching guide, so hundreds of grades can move with the suite green. The
grade table is the real check.

### Open questions carried into implementation

- Is a gate-only guide still legal once no-primary raises? (step 5)
- `MinimumNotes` is a gate in both gate constants *and* a primary rubric item in
  `DiatonicMelody`. One class, one strength, two roles — and strength is inert on
  gates, since `gate_factor` never consults a weight. State that in the comment
  so a `:weak` gate declaration is not written expecting an effect.
- The `second_species_harmony` fixture, labelled well-formed, fails four
  guidelines, one at 0.382. Loosen the threshold with a derivation comment
  (planned), or repair the fixture? Repair is the better spec but changes what
  the example demonstrates.
- `MixedRhythmicValues` is aspirationally worded and sits in `FifthSpeciesMelody`'s
  primary tier — a candidate ninth weak guideline. Flagged, not adopted.
- Does `diminution_items` survive the partitioner? Once tiering is by membership
  the helper only concatenates. Keeping it preserves symmetry with the melodic
  side; dropping it removes a helper with no remaining job.
- The `ApproachPerfectionContrarily` override ships with spec coverage and no
  production caller until a tradition needs it. Build the seam anyway, since the
  partitioner fix it forces is worth having regardless.
