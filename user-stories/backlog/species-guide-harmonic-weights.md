<!--
metadata:
  created_at:   2026-08-27T16:10:10-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-08-27T16:33:40-07:00
-->

# Species Guide Harmonic Weights

AS a student submitting a first species counterpoint exercise

I WANT the parallel-perfect prohibition to weigh what it is worth

SO THAT a line that runs in parallel octaves from end to end does not grade in
the eighties on the strength of rules it had no way to break

## The defect

Measured against `FirstSpeciesHarmony` on 2026-08-27, using Fux ch. 1 fig. 5 in
D dorian, which grades 1.0000 as published:

| Counterpoint | Grade |
| --- | --- |
| As published | 1.0000 |
| One parallel octave, at its cheapest placement | 0.9514 |
| The cantus firmus doubled an octave up throughout | 0.8300 |

The third row is not a counterpoint at all — it is one line sung twice — and
it earns a B.

It earns it honestly. The guide's two primaries hold 61.8% of the grade between
them, and a doubled line satisfies both perfectly: it is faithfully one note
against one (`OneToOne`), and it has no unisons in the middle
(`NoUnisonsInMiddle`). What it fails is four secondary items holding 0.2229
between them — `ApproachPerfectionContrarily`, `NoParallelPerfectOnDownbeats`
and `PreferContraryMotion` all pinned at 0.0081, and `PreferImperfect` at
0.6180. `NoParallelPerfectOnDownbeats` alone weighs 0.0637.

This is not a compensatory-mean problem. 78% of the weight sits on items the
doubled line genuinely satisfies; nothing was forgiven.

## The change

Promote `NoParallelPerfectOnDownbeats` to primary in `FirstSpeciesHarmony`, and
nowhere else. Measured, not projected:

| Counterpoint | Current | Promoted |
| --- | --- | --- |
| As published | 1.0000 | 1.0000 |
| One parallel octave | 0.9514 | 0.8921 |
| Doubled throughout | 0.8300 | 0.6674 |

The prohibition goes from 0.0637 to 0.2060; the two existing primaries drop from
0.3090 to 0.2060 each; the remaining secondaries absorb the vacated budget.

First species is where this belongs. The tier policy says a species guide is
about the dissonance treatment its rhythm makes possible, and two-part craft is
background — but first species has no dissonance treatment, and its two
primaries are rhythm-and-texture bookkeeping. Note-against-note consonance
handling is what the species is for, so the prohibition is its subject.

The promotion became expressible in one guide only at `5fbab86`, which replaced
the membership partition with direct tier declarations and left
`INHERITED_HARMONIC_CRAFT` as a policy the specs enforce. The place to record a
deliberate exception already exists.

## Why only first species

Promoting the same item in each harmony guide, measured 2026-08-27:

| Guide | Before | After | Budget taken from |
| --- | --- | --- | --- |
| `FirstSpeciesHarmony` | 0.0637 | 0.2060 | `NoUnisonsInMiddle`, `OneToOne` |
| `SecondSpeciesHarmony` | 0.0477 | 0.3090 | `WeakBeatDissonanceTreatment` |
| `ThirdSpeciesHarmony` | 0.0477 | 0.3090 | `ThirdSpeciesDissonanceTreatment` |
| `ThirdSpeciesTripleMeterHarmony` | 0.0477 | 0.3090 | `TripleMeterDissonanceTreatment` |
| `FirstThreeSpeciesHarmony` | 0.0477 | 0.3090 | `FloridDissonanceTreatment` |
| `FourthSpeciesHarmony` | 0.0477 | 0.2060 | `SecondSpeciesBreak`, `SuspensionTreatment` |
| `FifthSpeciesHarmony` | 0.0424 | 0.2060 | `FloridDissonanceTreatment`, `SuspensionTreatment` |

In the four single-primary guides the prohibition would weigh **exactly as much
as the dissonance treatment the guide exists to teach**. First species is the
mild case only because it already has two primaries to dilute.

Worse, in those guides the promotion can *raise* the grade of the line it is
meant to punish. A submission that already fails the taught rule loses almost
nothing when that rule's weight is halved, while the vacated budget flows to
secondaries it passes. Measured in `ThirdSpeciesHarmony`, the doubled-octave
line scores **0.2300 now and 0.2617 promoted** — its
`ThirdSpeciesDissonanceTreatment` is pinned at 0.0081, so halving that weight is
a net gain. The worse the dissonance treatment, the more the promotion pays.

First species cannot show this effect: its primaries are structural rules a
doubled line satisfies at 1.0, so there is nothing to rescue.

## What was ruled out

- **The arithmetic.** Three ways out were measured during
  [Extract the Harmonic Cores](../done/extract-the-harmonic-cores.md) and
  rejected: more weight only changes the exchange rate, a third tier subdivides
  a budget rather than changing the arithmetic on it, and the strength axis
  fixes the ordering and not the kind.
- **Disqualification.** Proposed in the retired *Disqualify, Don't Discount* and
  settled: a grade reports how well a submission did, not whether it is
  admissible.
- **Narrowing the overlap with `ApproachPerfectionContrarily`.** A parallel
  octave marks both, one mark each, costing 0.0486 between them on one
  violation. They say different things all the same — one is about approach
  motion to any perfect consonance, the other about consecutive perfects on
  downbeats — so the partial overlap stands and neither rule narrows.
- **How `PreferImperfect` marks.** It scored 0.6180 against a line of nothing
  but perfect consonances, which reads low for a total failure of the
  preference, and it may account for more of the 0.8300 than the tier does.
  Worth measuring here so the next story starts from a number; changing how a
  guideline marks is its own story.

## Scope

`FirstSpeciesHarmony`, the tier policy in `SpeciesHarmony`, and `base_spec`'s
enforcement of it. The other six harmony guides are measured and deliberately
unchanged.

Re-measure rather than quoting the figures above: `bin/guide_grade_corpus.rb`
grades the whole corpus through every guide, and `bin/guide_grade_table.rb`
derives its prose from its own data.

Out of scope: the grading arithmetic, how `PreferImperfect` marks, any veto or
disqualification mechanism, and the `No*` → `Avoid*` rename — each its own
change.

## Acceptance Criteria

- `NoParallelPerfectOnDownbeats` is primary in `FirstSpeciesHarmony` and
  secondary everywhere else.
- `INHERITED_HARMONIC_CRAFT` records the promotion as a named exception, and
  `base_spec`'s "the harmonic cores are background" group permits exactly that
  one and no other.
- A doubled-octave fixture is in the corpus. Only 5 of 114 corpus voices move
  under this change today, so nothing currently graded exercises it.
- What `PreferImperfect` contributes to the doubled-octave grade is written
  down, so the next story starts from a number.
- The corpus is captured before and after, and every grade that moves is
  accounted for — not merely observed to have moved.
- The grades document is regenerated from its own data rather than edited.

## Implementation Plan

[to be filled in by /stories plan]
