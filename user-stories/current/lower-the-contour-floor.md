<!--
metadata:
  created_at:   2026-09-18T15:24:10-07:00
  activated_at: 2026-10-19T09:05:05-07:00
  planned_at:
  finished_at:
  updated_at:   2026-10-19T13:15:09-07:00
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

`Contoured` marks every mismatched contour at φ⁻², the factor for a near miss:

```ruby
def marks
  return if notes.empty? || matches_contour?

  HeadMusic::Style::Mark.for_all(notes, fitness: HeadMusic::GOLDEN_RATIO_INVERSE**2)
end
```

Graded against `arch_contour_melody` as of 2026-10-19:

| Melody | Contour mark | Guide grade |
| --- | --- | --- |
| Arch, centered climax | 1.0 | 0.994 |
| Arch, off-center climax (rises nine notes, falls three) | 1.0 | 0.991 |
| Valley | 0.382 | 0.612 |
| Ascending line (an arch missing its descent) | 0.382 | 0.605 |
| Wave | 0.382 | 0.568 |

A valley is not a near-miss arch, yet it marks the same as an arch missing a
leg.

## Contours as leg sequences

A leg is one entry of `Contoured#trend_directions`: a rise or a fall, which
reverses only once the melody retraces `TREND_REVERSAL_SEMITONES` from its
running extreme. Each contour but static requires a leg sequence:

| Contour | Required legs |
| --- | --- |
| ascending | rise (see below for the endpoint reading) |
| descending | fall (likewise) |
| arch | rise, fall |
| valley | fall, rise |
| wave | three or more alternating legs, starting with either |

Where the climax falls is not tested. An off-center climax is a full arch, as
it is today.

## Degree of miss

Align the required sequence with the actual legs wherever it fits best. Each
extra leg before or after the alignment is one degree of miss, and so is each
required leg that is missing. Against an arch:

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

Extra and missing legs weigh the same, so against an arch a valley ties a
four-leg wave. That is accepted, because one count is easy to explain to a
student.

Against a wave, a melody never has extra legs. Two legs is one degree, one leg
two, and none three.

The mark is φ⁻² per degree, φ⁻²ᵈ, so one degree costs what every mismatch costs
today. The mark never reaches 0, because the gem discounts a grade rather than
disqualifying it. With every secondary guideline adherent:

| Degree | Mark | Guide grade |
| --- | --- | --- |
| 0 | 1.0 | 1.0 |
| 1 | 0.382 | 0.618 |
| 2 | 0.146 | 0.472 |
| 3 | 0.056 | 0.416 |

## Ascending and descending keep their endpoint reading

Today an ascending melody starts on its lowest pitch and ends on its highest,
and a descending one the reverse. That reading has enduring value, so it
survives alongside the legs:

- A single rise (or fall) is a full match.
- A melody that passes the endpoint test with more than one leg is a minor miss,
  marked at φ⁻¹ (half a degree, a guide grade of about 0.764) however many legs
  it has. C4 D4 E4 C4 D4 E4 F4 D4 E4 G4 A4 is five legs (rise, fall, rise,
  fall, rise) and a minor miss.
- A melody that fails the endpoint test is graded by its degree of miss.

## Static is unchanged

Static stays a range test (within a major third, without directional
endpoints), and a static mismatch keeps today's φ⁻² mark.

## The floor

`ContourMelody` declares `Contoured` as its only primary item, with
`DiatonicMelody`'s primaries as secondary. `GuideAssessment::TIER_BUDGETS` gives
the primary tier a fixed φ⁻¹ of the rubric and the secondary tier φ⁻², so with
every secondary adherent a guide grades φ⁻¹ × mark + φ⁻². As the degree grows,
the grade approaches 0.382 and never goes below it. That floor is accepted;
changing the rubric's shape is a separate decision.

The contour cannot be a gate. A gate is a precondition: a voice that fails one
is unassessable and its rubric is never computed.

## Acceptance Criteria

- Arch, valley, ascending, descending, and wave mark at φ⁻²ᵈ by degree of miss
  from their required legs.
- With every secondary adherent, a valley submitted to `arch_contour_melody`
  marks at φ⁻⁴ and grades about 0.472, and a melody one degree from an arch
  marks at φ⁻² and grades about 0.618.
- C4 D4 E4 C4 D4 E4 F4 D4 E4 G4 A4 marks at φ⁻¹ against ascending, as does any
  melody passing the ascending or descending endpoint test with more than one
  leg.
- Static grades as it does today.
- A failure message names the extra or missing legs, not only the mismatch.
- `Contoured`'s comment states the leg-sequence rule and why the endpoint
  reading survives for ascending and descending.
- The pinned corpus grades (`spec/fixtures/style/corpus_fitness.json`) are
  regenerated with `rake style:snapshot_corpus_fitness`, and every changed row
  is reviewed as intended. 79 `arch_contour_melody` rows sit at exactly 0.618
  today, and the other five contour guides move too.

## Notes

[Improve Melodic Contour Guidelines](../done/improve-melodic-contour-guidelines.md)
is the most recent work on `Contoured` and explains today's matcher.

`spec/head_music/style/guides/contour_melody_spec.rb` pins a wrong-contour
sawtooth "into the soft floor" at 0.3 to 0.55, which may need revisiting.

## Implementation Plan

[to be filled in by /stories plan]
