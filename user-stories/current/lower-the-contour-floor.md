<!--
metadata:
  created_at:   2026-09-18T15:24:10-07:00
  activated_at: 2026-10-19T09:05:05-07:00
  planned_at:
  finished_at:
  updated_at:   2026-10-19T09:37:09-07:00
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
| Trough | 0.382 | 0.612 |
| Ascending line (an arch missing its descent) | 0.382 | 0.605 |
| Wave | 0.382 | 0.568 |

A trough and an arch missing a leg get the same mark. φ⁻² is the factor for a
near miss, and a trough is not a near-miss arch.

## Why the mark alone cannot go far

`ContourMelody` declares `Contoured` as its only primary item, with
`DiatonicMelody`'s primaries as secondary. `GuideAssessment::TIER_BUDGETS` gives
the primary tier a fixed φ⁻¹ of the rubric and the secondary tier φ⁻², so with
clean secondaries a guide grades φ⁻¹ × m + φ⁻²:

- at today's m = φ⁻², that is **0.618**
- at m = 0, it is **0.382**

So lowering the mark can bring a total mismatch down to about 0.382 and no
further. A lower floor would need a change to the rubric's shape (a second
primary item, different tier budgets, or a non-compensatory mean), which is a
larger decision than the mark.

Making the contour a gate is not an option. A gate is a precondition: a voice
that fails one is unassessable and its rubric is never computed. And the gem
discounts a grade; it does not disqualify one.

## Near miss versus mismatch

A near miss is a melody one trend leg away from the target contour: a leg
missing, or one extra turn. For an arch (`ascending, descending`), that covers
an ascending-only or descending-only line and a three-leg line containing the
arch. A trough (`descending, ascending`) is two legs away and is a mismatch.

Where the climax falls is not part of the arch test. `arch?` checks only that
the trend directions are `ascending, descending`, so an off-center climax is a
full match, and this story keeps it one.

`ascending`, `descending`, and `static` are judged by endpoints and range rather
than by trend legs, so their near misses have to be defined separately.

## Questions to settle

- What is a near miss for `ascending`, `descending`, and `static`? Is there
  one at all, or is every mismatch for them a total mismatch?
- What does a total mismatch mark at: 0, or some factor between 0 and φ⁻²?
- Is a floor of about 0.382 for a total mismatch low enough, or does the
  ContourMelody rubric need a different shape?

## Acceptance Criteria

- A trough submitted to `arch_contour_melody` scores materially below 0.618,
  down to the 0.382 the rubric allows, unless the rubric's shape changes too.
- A near-miss arch (a missing leg or one extra turn) scores above a trough.
- `Contoured` defines a near miss for each of its six contours, or explicitly
  says that a contour has none.
- `Contoured`'s comment states the near miss versus mismatch decision.
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
