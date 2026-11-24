<!--
metadata:
  created_at:   2026-11-24T13:21:54-08:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-11-24T13:21:54-08:00
-->

# Story: Treat the Fifth Note of the Cambiata and Double Neighbor Alike

## Summary

AS a consumer of the gem grading third species counterpoint (BardTheory's exercises)
I WANT the nota cambiata and the double neighbor to be held to the same standard for the note that follows the figure
SO THAT the two leaping figures are judged by one consistent rule, and the lessons can state it once

## Acceptance Criteria

- The gem takes one position on the fifth note and applies it to both figures (see Open Questions for which)
- `HeadMusic::Style::Guideline::DissonanceFigures#cambiata_dissonance?` and `#double_neighbor_member?` both reflect that position
- Specs cover each figure followed by a step that continues in the same direction, a step that turns back, and a leap
- Existing fixtures of published third and fifth species examples still grade as they do now, or each change in a grade is explained in the story
- Guideline instructions in every locale (en, en_GB, de, es, fr, it, ru) say whether the figure is four notes or five
- CHANGELOG entry under Unreleased; if a figure that passed before can now be marked, the entry says so
- BardTheory's `the-cambiata`, `third-species-guidelines`, and `fifth-species-guidelines` lessons and its dictionary entries for the nota cambiata and double neighbor are listed as follow-up to bring into line

## Notes

Raised on 2026-11-24 while reviewing BardTheory's dictionary entries for the nota cambiata and the double neighbor.

Today the two figures are checked differently in `lib/head_music/style/guideline/dissonance_figures.rb`:

- **Nota cambiata** is a five-note figure. `cambiata_shape?` reads four intervals: a step, a leap of a third in the same direction, then two steps back in the opposite direction. Notes 1, 3, and 5 must be consonant. D–C–A–B–C passes; D–C–A–B–A is marked, because the fifth note turns back.
- **Double neighbor** is a four-note figure. `double_neighbor_figure?` reads three intervals: a step, a leap of a third, a step, ending on the starting pitch, with the first and last notes consonant. The fifth note is never examined, so C–D–B–C–D and C–D–B–C–B both pass.

The sources divide the same way for both figures:

- Open Music Theory (third-species chapter) calls the cambiata "a special five-note figure" with notes 1, 3, and 5 consonant, and says of the double neighbor that the step across the barline should continue in the direction of the step before it. That makes both figures five notes.
- Magnuson, *Sound Patterns*, gives the cambiata as "one step down, a 3rd down, two steps up" and calls the double neighbor "a five note figure."
- Other statements of the rule require only one step in the opposite direction after the cambiata's leap, and treat the double neighbor as four notes, leaving the fifth note free in both.

On 2026-11-24 BardTheory's lessons and dictionary were changed to describe the cambiata as five notes, matching what the gem scores now. They describe the double neighbor as four notes, which also matches.

### Open questions

- **Which way does the gem go?** Stricter: require the double neighbor's fifth note to continue by step in the direction of the fourth, as the cambiata's does. Looser: accept the four-note cambiata, with any well-behaved fifth note. The stricter choice can mark exercises that pass today; the looser one cannot.
- Does the answer differ between third species and fifth species (`FloridDissonanceTreatment`), where the figure sits among mixed note values?
- The gem requires the cambiata's third note to be consonant. Fux allows it to be dissonant; Jeppesen reportedly does not find that in Palestrina. Is that settled, or part of this story?
- Related: [escape-tone-recognition](escape-tone-recognition.md) adds a third figure in which a dissonance is left by a leap of a third. Whatever rule this story settles for the note after the leap should be considered there too.

## Implementation Plan

[to be filled in by /stories plan]
