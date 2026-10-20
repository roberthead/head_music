<!--
metadata:
  created_at:   2026-10-19T20:59:00-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-10-19T21:11:10-07:00
-->

# Straight Contour

AS a student learning melodic shape

I WANT a guide for a line that moves in one direction without turning

SO THAT the shape an ascending scale has is taught as a shape, separately from
the direction it goes

Split out of
[Grade Contour Misses by Degree](../current/grade-contour-misses-by-degree.md),
which made ascending and descending pure directions. Until then, "ascending"
stood for both a direction (the endpoints) and a shape (a single rise).

## Background

A melody's contour has two separate descriptions:

- **Direction**: ascending or descending, from the endpoints, or level (static),
  from the range.
- **Shape**, from the legs (rises and falls): no legs, one leg
  (straight), two (arch or valley), or three or more (wave).

Arch, valley, and wave are shapes. Straight is the missing one-leg shape. It is
called straight rather than "direct", because counterpoint uses direct for
similar motion (direct fifths, and `PreferContraryMotion#direct_motions`), and
rather than "linear", which Schenkerian analysis uses for linear progressions.

## Acceptance Criteria

- `Contoured` accepts `:straight`, which requires a single leg in either
  direction.
- A straight contour grades by degree of miss like arch, valley, and wave: each
  extra leg is one degree, and a melody with no legs is one degree.
- `straight_contour_melody` is registered alongside the other contour guides.
- The `contours.straight` string and the guide's name exist in every locale
  (en, de, es, fr, it, ru), with en_GB inheriting.

## Questions to settle

- Is straight one guide for either direction, or should it combine with a
  direction (a straight ascent, a straight descent)?
- Should a straight melody have a minimum number of melodic intervals, as the
  ascending and descending guides do?

## Notes

Depends on the degree-of-miss grading from Grade Contour Misses by Degree.

## Implementation Plan

[to be filled in by /stories plan]
