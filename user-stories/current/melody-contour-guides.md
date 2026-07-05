<!--
metadata:
  created_at:   2026-07-05T13:55:34-07:00
  activated_at: 2026-07-05T16:12:05-07:00
  planned_at:
  finished_at:
  updated_at:   2026-07-05T16:12:05-07:00
-->

# Story: Melody Contour Guides

## Summary

AS a composer or student using HeadMusic to evaluate melodies
I WANT style guides that assess whether a diatonic melody follows a specified contour (ascending, descending, arch, valley, wave, or static)
SO THAT I can shape melodic writing toward an intended overall gesture and get actionable feedback when the melody doesn't match

## Acceptance Criteria

- A configurable guideline `HeadMusic::Style::Guidelines::Contoured` exists, configured via `Contoured.with(:arch)` (and the other five contour keys)
- `Contoured.with` raises an error for a key not in `CONTOURS`, so a typo fails at guide-definition time
- A melody matching the configured contour receives no marks (adherent, fitness 1.0)
- A melody not matching the configured contour receives a single mark spanning all notes (one violation, one penalty — no per-note compounding) with the message "Write a melody with the {contour} contour."
- Contour predicates are trend-based, not strictly monotonic — local direction changes are allowed; existing guidelines (e.g., `ModerateDirectionChanges`) already police local motion:
  - **Ascending**: the lowest pitch occurs at (or tied with) the first note and the highest pitch at the last note — the line departs its floor and arrives at its ceiling
  - **Descending**: mirror of ascending — highest pitch at the first note, lowest pitch at the last note
  - **Arch**: a single climax (highest pitch) in the interior (not the first or last note), with a net rise before it and a net fall after it
  - **Valley**: mirror of arch — a single nadir (lowest pitch) in the interior, with a net fall before it and a net rise after it
  - **Wave**: at least 3 direction changes at the trend level (rise–fall–rise or fall–rise–fall), distinguishing repeated undulation from a single-turn arch or valley
  - **Static**: total range no larger than a major third, and the endpoints must not sit at the extremes in a way that implies another contour (must not start at the lowest pitch and end at the highest, nor start at the highest and end at the lowest)
- Six guides exist as subclasses of `HeadMusic::Style::Guides::DiatonicMelody` — `AscendingContourMelody`, `DescendingContourMelody`, `ArchContourMelody`, `ValleyContourMelody`, `WaveContourMelody`, `StaticContourMelody` — each appending the appropriately configured `Contoured` guideline to the inherited RULESET
- The arch predicate complements rather than duplicates `ConsonantClimax` (contour judges shape; climax consonance/uniqueness stays with `ConsonantClimax` — no double-flagging of the same defect)
- Specs cover adherent and non-adherent melodies for each contour (using ABC notation per the existing spec convention), coverage stays ≥ 90%, rubocop clean

## Notes

- Sketch in progress at `lib/head_music/style/guidelines/contoured.rb`; stub guide at `lib/head_music/style/guides/arch_contour_melody.rb`
- Design decision (2026-07-05): configurability lives at the guideline layer (matching the `MinimumNotes.with` / `LargeLeaps.with` pattern); guides remain named classes because guides are the gem's pedagogical vocabulary and contour is a single closed axis with six values — revisit guide-level `.with` only if a second orthogonal configuration axis appears
- Guide naming follows the existing stub's convention: `{Contour}ContourMelody`
- Mark semantics: `Annotation#fitness` is the product of mark fitnesses, so one spanning mark applies the penalty once; per-note marks would compound `PENALTY_FACTOR` per note and crush fitness on long melodies
- `references/third-species-counterpoint.md:310` is the only contour mention in the references ("The line should have an overall arch or wave shape")

## Implementation Plan

[to be filled in by /stories plan]
