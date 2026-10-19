<!--
metadata:
  created_at:   2026-09-18T15:24:10-07:00
  activated_at: 2026-10-19T09:05:05-07:00
  planned_at:
  finished_at:
  updated_at:   2026-10-19T13:11:52-07:00
-->

# Lower the Contour Floor

AS a student submitting a melody to a contour guide

I WANT a melody with the wrong shape to score worse than one that nearly has
the right shape

SO THAT a valley handed to `arch_contour_melody` is not graded as a near-miss
arch

Split out of [Require the Species Rhythm](../done/require-the-species-rhythm.md),
which inherited it from
[Extract the Harmonic Cores](../done/extract-the-harmonic-cores.md). It is
unrelated to species rhythm and is decided on its own terms.

## The defect

`Contoured` marks every mismatched contour at φ⁻²:

```ruby
def marks
  return if notes.empty? || matches_contour?

  HeadMusic::Style::Mark.for_all(notes, fitness: HeadMusic::GOLDEN_RATIO_INVERSE**2)
end
```

It has no notion of a near miss. Graded against `arch_contour_melody` as of
2026-10-19:

| Melody | `Contoured` | Guide grade |
| --- | --- | --- |
| Arch, centered climax | 1.0 | 0.994 |
| Arch, off-center climax (rises nine notes, falls three) | 1.0 | 0.991 |
| Valley | 0.382 | 0.612 |
| Ascending line (an arch missing its descent) | 0.382 | 0.605 |
| Wave | 0.382 | 0.568 |

A valley and an arch missing a leg get the same mark. φ⁻² is the factor for a
near miss, and a valley is not a near-miss arch.

## Contours as leg sequences

A leg is one trend of `Contoured#trend_directions`: a rise or a fall that only
reverses once the melody retraces `TREND_REVERSAL_SEMITONES` from its running
extreme. Every contour but static is described by the leg sequence it requires:

| Contour | Required legs |
| --- | --- |
| ascending | rise |
| descending | fall |
| arch | rise, fall |
| valley | fall, rise |
| wave | three or more alternating legs, starting with either |

## Degree of miss

Align the required sequence with the actual legs wherever it fits best. Each
extra leg before or after the alignment is one degree of miss, and so is each
required leg that is missing. Legs alternate, so the alignment is a small
calculation. For an arch:

| Actual legs | Extra | Missing | Degree |
| --- | --- | --- | --- |
| rise, fall | 0 | 0 | 0 |
| rise, fall, rise (C4 E4 G4 A4 G4 D4 B3 D4) | 1 | 0 | 1 |
| fall, rise, fall | 1 | 0 | 1 |
| rise (an ascending scale) | 0 | 1 | 1 |
| fall (a descending scale) | 0 | 1 | 1 |
| rise, fall, rise, fall (a wave) | 2 | 0 | 2 |
| fall, rise (a valley) | 1 | 1 | 2 |
| no legs | 0 | 2 | 2 |

Extra and missing legs weigh the same, so a valley ties a four-leg wave as an
arch. That is accepted: one count is easy to explain to a student.

A wave never has extra legs, since any length from three up matches. Two legs
is one degree, one leg two, and none three.

The mark is **φ⁻² per degree**, φ⁻²ᵈ. One degree costs exactly what every
mismatch costs today, which is the premise that φ⁻² is the factor for a near
miss. The mark never reaches 0, because the gem discounts a grade rather than
disqualifying it.

| Degree | Mark | Guide grade with clean secondaries |
| --- | --- | --- |
| 0 | 1.0 | 1.0 |
| 1 | 0.382 | 0.618 |
| 2 | 0.146 | 0.472 |
| 3 | 0.056 | 0.416 |

Where the climax falls stays outside the test. An off-center climax is a full
arch, as `arch?` judges it today.

## Ascending and descending keep their endpoint reading

The existing endpoint definitions, where the first note is the lowest and the
last is the highest (or the reverse), have enduring value. A single rise is a
perfect ascending contour, and so is a single fall for descending. A melody that
passes the endpoint test with more legs inside it, an ascending wave, is
acceptable and only a minor miss. C4 D4 E4 C4 D4 E4 F4 D4 E4 G4 A4 is five legs
(rise, fall, rise, fall, rise) and an ascending contour.

A minor miss is half a degree, φ⁻¹ (0.618, a guide grade of about 0.764),
however many legs it has. A melody that fails the endpoint test is graded by
its degree of miss from the single required leg.

## Static is unchanged

Static stays a range test (within a major third and without directional
endpoints), and a static mismatch keeps today's φ⁻² mark.

## The floor

`ContourMelody` declares `Contoured` as its only primary item, with
`DiatonicMelody`'s primaries as secondary. `GuideAssessment::TIER_BUDGETS` gives
the primary tier a fixed φ⁻¹ of the rubric and the secondary tier φ⁻², so with
clean secondaries a guide grades φ⁻¹ × m + φ⁻². As the degree grows the grade
approaches 0.382 and never goes below it. That floor is accepted; changing the
rubric's shape would regrade every guide and is a separate decision.

Making the contour a gate is not an option. A gate is a precondition: a voice
that fails one is unassessable and its rubric is never computed. And the gem
discounts a grade; it does not disqualify one.

## Acceptance Criteria

- A valley submitted to `arch_contour_melody` marks at φ⁻⁴ and grades about
  0.472, down from 0.618.
- A melody one degree from an arch (an extra leg before or after, or one leg
  missing) marks at φ⁻² and grades above a valley.
- Arch, valley, ascending, descending, and wave grade by degree of miss from
  their required legs at φ⁻²ᵈ.
- A melody that passes the ascending or descending endpoint test with more than
  one leg marks at φ⁻¹, and C4 D4 E4 C4 D4 E4 F4 D4 E4 G4 A4 is one.
- Static grades as it does today.
- Failure messages say how the melody missed, not only that it did.
- `Contoured`'s comment states the leg-sequence rule and why the endpoint
  reading survives for ascending and descending.
- The pinned corpus grades (`spec/fixtures/style/corpus_fitness.json`) are
  regenerated with `rake style:snapshot_corpus_fitness`, and the regrade is
  reviewed as intended rather than accepted wholesale. About 79
  `arch_contour_melody` rows sit at exactly 0.618 today, and the other five
  contour guides move too.

## Notes

The story `Improve Melodic Contour Guidelines` in `done/` is the most recent
work on `Contoured` and describes what the contour matcher currently considers
a match.

`spec/head_music/style/guides/contour_melody_spec.rb` pins a wrong-contour
sawtooth "into the soft floor" at 0.3 to 0.55, which may need revisiting.

## Implementation Plan

[to be filled in by /stories plan]
