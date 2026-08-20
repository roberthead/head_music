<!--
metadata:
  created_at:   2026-08-16T21:38:46-07:00
  activated_at: 2026-08-20T09:16:47-07:00
  planned_at:
  finished_at:
  updated_at:   2026-08-20T09:34:46-07:00
-->

# Extract the Harmonic Cores

AS a student submitting a species harmony exercise

I WANT the guide to weigh what it teaches above the general two-part craft it inherits

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

**Re-weighting cannot move a rubric whose items are all 1.0.** No candidate
answer below changes that 1.000. The guides' inability to say "this is not third
species" is the "no fault found vs. nothing to find fault in" confusion the
re-tiering story logged as an epic theme, and it is a missing-guideline problem:
`FirstSpeciesHarmony` has `OneToOne`, so a constructed third-species line scores
0.847 there with `OneToOne` firing at 0.0, while the diminution guides have no
species-identifying counterpart and so can reject nothing.

That defect is [Tell the Species Apart](../backlog/tell-the-species-apart.md).
This story is the weighting decision alone, and its measurements compare a line
against *itself* before and after, as the melodic story did (0.883 → 0.561).

## Two things to explore, not one

The title says "extract" because there are two separable questions and the
answer to the second may change the first.

### 1. Should the cores be demoted to `secondary_items`?

The direct analogue of the melodic decision, which chose to demote **wholesale**:
`MELODIC_CORE` and `MOVING_MELODIC_CORE` were unioned into
`INHERITED_MELODIC_CRAFT` and moved to `secondary_items` together, rather than
split by subject.

A harmony guide teaches its species; general two-part craft is background it
inherits. Demoting would make `WeakBeatDissonanceTreatment` carry φ⁻¹ of second
species' rubric rather than a tenth.

The counter-argument deserves a hearing, and it is stronger here than for
melody: parallel fifths are not *background* in a counterpoint exercise. A
student who writes flawless second-species rhythm over parallel octaves has not
done well, and a demotion says they mostly have. Melodic craft is plausibly
background to a rhythm lesson; harmonic craft may be the point of counterpoint
regardless of species.

Possible answers, and this story should pick one with measurements behind it:

- demote both cores wholesale, as melody does
- demote `HARMONIC_CORE` but keep `DIMINUTION_HARMONIC_CORE` primary, since the
  diminution rules exist precisely because of the species
- split `HARMONIC_CORE` itself — the parallel-perfect and consonance rules stay
  primary, the preference rules (`PreferContraryMotion`, `PreferImperfect`)
  become secondary
- leave them primary and accept that harmony guides grade differently from
  melody guides, stating why

### 2. Should the cores live on `SpeciesHarmony` at all?

`SpeciesHarmony` is described in its own comment as "a semantic marker
distinguishing harmony guides from melody guides," yet it also holds three
constants and a list-building helper.

The melodic side has since answered its half of this, and differently than the
original framing expected. `SpeciesMelody.species_items` **partitions entries by
membership** in `INHERITED_MELODIC_CRAFT` rather than trusting the call site to
declare the right tier, precisely because "guides do not declare the cores the
same way — some splat the constant, some name its members — and a hand-named
inherited guideline must still be demoted."

So the harmonic question is no longer "stop the guides reaching around the
helper." It is whether to adopt the same partitioner (tolerating hand-naming and
tiering correctly anyway), or to make the declarations uniform, or both. Today
`FourthSpeciesHarmony` splats `HARMONIC_CORE` and then names `NoStrongBeatUnisons`
individually; `FifthSpeciesHarmony` names both `NoParallelPerfectAcrossBarline`
and `NoStrongBeatUnisons`. Both are `DIMINUTION_HARMONIC_CORE` members reached
without `diminution_items`, so under a call-site-trusting scheme they would be
mis-tiered, and under a partitioning scheme they would not.

`CombinedFirstSecondThirdSpeciesHarmony` omits the diminution core entirely
despite covering second and third species — recorded as a defect during the
re-tiering plan and still unfixed.

## Scope

- Decide question 1 with measurements: what each harmony guide grades today, and
  under each candidate answer, for the corpus material that can actually be
  assessed harmonically.
- Decide question 2 and make the declarations consistent — either by adopting a
  membership partitioner like the melodic side's, or by making every guide use
  the helper.
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

## Acceptance Criteria

- Every harmony guide's tier assignment is deliberate and stated, with a
  measurement behind it.
- The declaration form is consistent: either no guide splats a core and then
  names a member of another core individually, or the tiering is decided by
  membership so that doing so is harmless.
- `CombinedFirstSecondThirdSpeciesHarmony` either declares the diminution core or
  carries a comment explaining why it does not.
- A before/after grade table for every harmony guide across the assessable
  corpus, in the same shape as the re-tiering story's, with the 38-row limit
  stated in the document rather than left implicit.
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
outcome is unreachable by tiering — see "What re-tiering will and will not fix"
— so the goal was narrowed to the weighting question and the identification
defect was split out.

## Implementation Plan

[to be filled in by /stories plan]
