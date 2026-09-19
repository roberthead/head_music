<!--
metadata:
  created_at:   2026-09-18T15:24:10-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-09-18T15:24:10-07:00
-->

# Lower the Contour Floor

AS a student submitting a melody to a contour guide

I WANT a melody with the wrong shape to score worse than one that nearly has
the right shape

SO THAT a trough handed to `arch_contour_melody` is not graded as a near-miss
arch

Split out of [Require the Species Rhythm](../done/require-the-species-rhythm.md),
which inherited it from
[Extract the Harmonic Cores](../done/extract-the-harmonic-cores.md). It is
unrelated to species rhythm and is decided on its own terms.

## The defect

`Contoured` marks a mismatched contour at φ⁻²:

```ruby
def marks
  return if notes.empty? || matches_contour?
  Mark.for_all(notes, fitness: HeadMusic::GOLDEN_RATIO_INVERSE**2)
end
```

`ContourMelody` declares `primary: [Contoured.with(contour)]` and nothing else,
so that one item is the whole primary tier. A trough submitted for an arch scores
**0.618** today. Weighting can only interpolate between the guideline's own
fitness and 1, so even at 100% of the rubric the floor is **0.382**. No tier,
budget, cap, or weight reaches below it.

φ⁻² is the factor for a near miss. A trough is not a near-miss arch.

## Questions to settle

- Should `Contoured` distinguish a total mismatch from a near miss, and if so
  what makes a contour "nearly" right? A single misplaced peak, an arch whose
  climax is off-center, a wave with one turn too few?
- Should a total mismatch mark at 0, or should the contour be a gate so the
  whole grade scales?
- Does the ContourMelody rubric need a second primary item at all, or is the
  one-item tier the right shape and only its mark is wrong?

## Acceptance Criteria

- A trough submitted to `arch_contour_melody` scores materially below the 0.618
  it scores today.
- A near-miss arch still scores above a trough.
- The decision on mismatch versus near miss is stated in `Contoured`'s comment.

## Notes

The story `Improve Melodic Contour Guidelines` in `done/` is the most recent
work on `Contoured` and describes what the contour matcher currently considers
a match.

## Implementation Plan

[to be filled in by /stories plan]
