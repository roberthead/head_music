<!--
metadata:
  created_at:   2026-09-18T15:24:10-07:00
  activated_at: 2026-10-19T09:05:05-07:00
  planned_at:
  finished_at:
  updated_at:   2026-10-19T21:11:10-07:00
-->

# Grade Contour Misses by Degree

AS a student submitting a melody to a contour guide

I WANT a melody with the wrong contour to score worse than one that nearly has
the right contour

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

## Shapes and directions

Four terms, used only in these senses:

- A **contour** is any of the six things a contour guide asks for: the
  `Contoured::CONTOURS` keys.
- A **shape** is what a melody does between its endpoints: arch, valley, and
  wave, read from the legs.
- A **direction** is where a melody ends up compared with where it began:
  ascending, descending, and level. Ascending and descending are read from the
  endpoints; static is the level direction, read from the range.
- A **leg** is one rise or one fall, the unit a shape is made of. It reverses
  only once the melody retraces `TREND_REVERSAL_SEMITONES` from its running
  extreme. `Contoured#trend_directions` finds the legs today.

Each shape requires a leg sequence:

| Contour | Required legs |
| --- | --- |
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

## Ascending and descending are directions

An ascending melody starts at its lowest pitch and ends at its highest, and a
descending one the reverse, as today but with a tolerance. Legs play no part:
what happens between the endpoints is shape, not direction.
C4 D4 E4 C4 D4 E4 F4 D4 E4 G4 A4 is five legs (rise, fall, rise, fall, rise) and
a full ascending match.

The one-leg shape a scale has is left to its own guide, in
[Straight Contour](../backlog/straight-contour.md).

The endpoint test allows the same tolerance as the legs: the first note may sit
less than `TREND_REVERSAL_SEMITONES` above the lowest pitch, and the last less
than that below the highest. A wobble too small to make a leg is too small to
spoil a direction.

A melody that fails the test misses by one degree for each endpoint condition
it fails, marked at φ⁻²ᵈ like the shapes. Descending mirrors this:

| Melody against ascending | First near lowest | Last near highest | Degree |
| --- | --- | --- | --- |
| C4 up to C5 | ✓ | ✓ | 0 |
| C4 up to C5, ending on B4 | ✓ | ✓ | 0 |
| D4 C4 E4 G4 A4 G4 | ✓ | ✓ | 0 |
| C4 up to C5, ending on A4 | ✓ | ✗ | 1 |
| an arch from C4 back to C4 | ✓ | ✗ | 1 |
| C5 down to C4 | ✗ | ✗ | 2 |

## Static is unchanged

Static, the level direction, stays a range test (within a major third, without
directional endpoints), and a static mismatch keeps today's φ⁻² mark. Its directional
endpoints check stays strict: within a major third, the tolerance would call
nearly every melody directional, and C4 D4 E4 D4 would stop being static.

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

- Arch, valley, and wave mark at φ⁻²ᵈ by degree of miss from their required
  legs.
- With every secondary adherent, a valley submitted to `arch_contour_melody`
  marks at φ⁻⁴ and grades about 0.472, and a melody one degree from an arch
  marks at φ⁻² and grades about 0.618.
- Ascending and descending mark at φ⁻²ᵈ by the number of endpoint conditions
  failed, within the legs' tolerance and ignoring the legs themselves.
  C4 D4 E4 C4 D4 E4 F4 D4 E4 G4 A4 and D4 C4 E4 G4 A4 G4 are full ascending
  matches, and a descending scale marks at φ⁻⁴ against ascending.
- Static grades as it does today.
- A failure message names how the melody missed: the extra or missing legs for
  a shape, the failed endpoint for a direction.
- `Contoured`'s comment states that arch, valley, and wave are shapes graded by
  legs, ascending and descending are directions graded by endpoints, and
  static is the level direction graded by range.
- The pinned corpus grades (`spec/fixtures/style/corpus_fitness.json`) are
  regenerated with `rake style:snapshot_corpus_fitness`, and every changed row
  is reviewed as intended. 79 `arch_contour_melody` rows sit at exactly 0.618
  today. Arch, valley, wave, ascending, and descending rows may move; static
  rows must not.

## Notes

[Improve Melodic Contour Guidelines](../done/improve-melodic-contour-guidelines.md)
is the most recent work on `Contoured` and explains today's matcher.

`spec/head_music/style/guides/contour_melody_spec.rb` pins a wrong-contour
sawtooth "into the soft floor" at 0.3 to 0.55, which may need revisiting.

The code uses "direction" for legs: `Contoured#trend_directions` returns
`:ascending` and `:descending` per leg, and `TrendWalk` has a `direction`
field. Rename them to `legs`, returning `:rise` and `:fall`, so that direction
means only what this story means by it. Both are private to `Contoured`.

## Implementation Plan

[to be filled in by /stories plan]
