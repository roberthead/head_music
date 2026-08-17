<!--
metadata:
  created_at:   2026-08-16T21:38:46-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-08-16T21:38:46-07:00
-->

# Extract the Harmonic Cores

AS a student submitting a species harmony exercise

I WANT the guide to weigh what it teaches above the general two-part craft it inherits

SO THAT a first-species line submitted against a third-species guide is told it is not third species, rather than given a diffusely good grade for keeping its voices uncrossed

Follows [Re-tier the Guides](re-tier-the-guides.md), which folded the equivalent
melodic demotion into its own scope and left the harmonic question open.

## Background

`Guides::SpeciesHarmony` holds two shared lists. `HARMONIC_CORE` is seven
guidelines about two-part writing in general — contrary approach to perfection,
no crossed or overlapping voices, consonant downbeats, no parallel perfects on
downbeats, prefer contrary motion, prefer imperfect. `DIMINUTION_HARMONIC_CORE`
adds two more for the species that set several counterpoint notes against each
cantus firmus note.

Every harmony guide splats the core wholesale, and the result is that the core
*is* the rubric:

| Guide | primaries | from the core | its own |
| --- | --- | --- | --- |
| `first_species_harmony` | 9 | 7 | 2 |
| `second_species_harmony` | 10 | 9 | 1 |
| `third_species_harmony` | 10 | 9 | 1 |
| `third_species_triple_meter_harmony` | 10 | 9 | 1 |
| `fourth_species_harmony` | 11 | 8 | 3 |
| `fifth_species_harmony` | 12 | 9 | 3 |
| `combined_first_second_third_species_harmony` | 8 | 7 | 1 |

Under a flat rubric, `SecondSpeciesHarmony` gives nine tenths of its grade to
rules it did not write and one tenth to `WeakBeatDissonanceTreatment` — the only
thing that makes it second species. The combined guide is worse: one twelfth.

This is the same defect the melodic demotion addresses, and it is sharper here,
because the harmony cores are larger relative to what each guide adds.

## Two things to explore, not one

The title says "extract" because there are two separable questions and the
answer to the second may change the first.

### 1. Should the cores be demoted to `secondary_items`?

The direct analogue of the melodic decision. A harmony guide teaches its
species; general two-part craft is background it inherits. Demoting would make
`WeakBeatDissonanceTreatment` carry φ⁻¹ of second species' rubric rather than a
tenth.

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
distinguishing harmony guides from melody guides," yet it also holds two
constants and a list-building helper. The melodic side has the same shape, and
the same question applies there.

Three guides reach around the helper. `FourthSpeciesHarmony` splats
`HARMONIC_CORE` and then names `NoStrongBeatUnisons` individually;
`FifthSpeciesHarmony` names both `NoParallelPerfectAcrossBarline` and
`NoStrongBeatUnisons`. Both are `DIMINUTION_HARMONIC_CORE` members reached
without `diminution_items`, so the constant is not the single source it appears
to be. `CombinedFirstSecondThirdSpeciesHarmony` omits the diminution core
entirely despite covering second and third species — recorded as a defect during
the re-tiering plan and still unfixed.

Whether the cores become their own objects, stay constants with a stricter
declaration form, or are simply used consistently is the second half of this
story.

## Scope

- Decide question 1 with measurements: what each harmony guide grades today for
  a set of exercises, and under each candidate answer. A valid first-species
  line assessed against `ThirdSpeciesHarmony` is the sharpest test case, as its
  melodic equivalent was.
- Decide question 2 and make the declarations consistent, so that a guide either
  uses a core or does not, rather than using it and then reaching into it.
- Fix `CombinedFirstSecondThirdSpeciesHarmony`'s missing diminution core, or
  record why its omission is correct.

## Acceptance Criteria

- Every harmony guide's tier assignment is deliberate and stated, with a
  measurement behind it.
- No guide splats a core and then names a member of another core individually.
- `CombinedFirstSecondThirdSpeciesHarmony` either declares the diminution core or
  carries a comment explaining why it does not.
- A before/after grade table for every harmony guide across the fixture corpus,
  in the same shape as the re-tiering story's.
- A valid first-species line scores materially lower against `ThirdSpeciesHarmony`
  than a valid third-species line does — or, if the chosen answer is to leave the
  cores primary, that outcome is recorded as accepted with its reasoning.

## Notes

Deliberately framed as an exploration. The melodic demotion was decided on one
measurement and folded into the re-tiering story mid-flight; the harmonic side
has a real counter-argument and more guides affected, so it gets its own story
and its own evidence rather than inheriting the melodic conclusion by symmetry.

The re-tiering story's plan also observed that `MOVING_MELODIC_CORE` is a second
inherited melodic core that the original out-of-scope note never named. If the
answer here is "split the core by what it is about," the melodic side likely
wants revisiting on the same grounds.

## Implementation Plan

[to be filled in by /stories plan]
