<!--
metadata:
  created_at:   2026-09-09T12:17:16-07:00
  activated_at: 2026-09-09T13:54:03-07:00
  planned_at:
  finished_at:
  updated_at:   2026-09-10T11:14:17-07:00
-->

# Improve Melodic Contour Guidelines

AS a student writing a melody against a target contour

I WANT the arch and valley contours to describe the shape of the whole line

SO THAT a melody that rises a third, plunges a sixth, and climbs back is told it
is not an arch, rather than passing the exercise's one requirement at 100%

Found on bardtheory's "Compose a Melody with an Arch Contour" exercise on
2026-09-09, while walking through the new exercise rubrics.

## The defect

`Contoured#arch?` checks one thing: the highest pitch is neither the first nor
the last note (`endpoints_interior_to?`, `contoured.rb:58-70`). `valley?` is
the mirror. The comment says "rise then fall reduces to both endpoints sitting
below the climax." It does not: that admits any line whose peak is somewhere in
the middle, whatever happens on either side of it.

Measured against the gem on 2026-09-09:

| Melody | arch | valley | wave | trends |
| --- | --- | --- | --- | --- |
| C4 D4 E4 D4 B3 A3 G3 B3 C4 (the submission) | pass | pass | pass | up, down, up |
| C4 D4 E4 F4 G4 A4 G4 F4 E4 D4 C4 | pass | fail | fail | up, down |
| C4 D4 E4 D4 E4 F4 G4 F4 E4 D4 C4 (neighbor dip) | pass | fail | fail | up, down |
| G4 F4 E4 D4 C4 D4 E4 F4 G4 | fail | pass | fail | down, up |
| C4 E4 G4 F4 E4 D4 C4 B3 C4 | pass | pass | fail | up, down |

The first line satisfies three contours at once. Its peak E4 is interior, so
it is an arch; its lowest note G3 is interior, so it is a valley; it reverses
direction three times by more than a whole step, so it is a wave. Only the
arch row shows in the app, because that is what the exercise asked for.

The gem already has the right instrument. `trend_directions`
(`contoured.rb:92`) walks the line and records a direction change only once
the melody retraces `TREND_REVERSAL_SEMITONES` (3) from its running extreme,
so neighbor-note undulation is not a trend change. `wave?` uses it; `arch?`
and `valley?` do not.

## Acceptance Criteria

- `arch?` is true only when the trend directions are exactly ascending then
  descending, and the endpoint check still holds (a line cannot start or end on
  its peak).
- `valley?` is the mirror: exactly descending then ascending, endpoints above
  the trough.
- The submission above fails arch and valley and passes only wave.
- The three genuine arches and the valley in the table keep their verdicts,
  including the arch with a neighbor-note dip on the way up.
- Arch, valley, and wave are mutually exclusive for any melody with three or
  more notes; a spec states this over a set of shapes rather than one example.
- The registered contour guides (`arch_contour_melody` and the rest) and their
  `minimum_melodic_intervals` gates are unchanged.
- The violation sentence for arch and valley still reads correctly for the new
  failure: a student whose line waves is told to "rise to a single peak, then
  descend", or whatever the locale says today, and that sentence is not made
  worse.
- CHANGELOG entry under the next release, noting that some melodies previously
  graded as arch or valley now grade as wave.

## Notes

**Ending approach.** A closing step against the final trend (…D4 C4 B3 C4,
the 7→1 approach) is under the 3-semitone reversal threshold, so the arch still
reads as up-down. That is the intended behavior and a spec should pin it. The
threshold stays a constant.

**Check the corpus before changing the rule.** bardtheory's contour exercises
have stored submissions graded under the old predicate; a sweep of the pinned
melody corpus (or a handful of Fux lines used as free melodies) shows how many
verdicts flip. Record the count in the story.

**Release.** bardtheory pins `~> 20.0` but will be upgraded to `~> 21.1` to
land this (and the previous refactoring).

**Related.** bardtheory's `user-stories/done/exercise-specific-rubrics.md`
records the walkthrough that surfaced this, and its Scope Boundaries name a
follow-up gem story for exercise guidelines (EndOnScaleDegree, tendency-tone
resolutions). That story and this one both touch how a melody exercise's
primary requirement is judged.

**Decisions (2026-09-09).** Talked through before planning:

- Arch and valley become trend-based: trend directions exactly ascending then
  descending (or the mirror), plus the existing endpoint check.
- Ascending and descending keep their endpoint-only definitions. A line that
  goes up-down-up and ends on its peak is both ascending and a wave, and that
  is fine. Only arch, valley, and wave need to be mutually exclusive.
- Wave stays at three or more trends.
- The contour mark stays binary. No graded contour in this story.

## Implementation Plan

[to be filled in by /stories plan]
