<!--
metadata:
  created_at:   2026-11-24T13:21:54-08:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-11-24T15:35:04-08:00
-->

# Story: Settle the Fifth Note of the Cambiata and Double Neighbor

## Summary

AS a consumer of the gem grading third species counterpoint (BardTheory's exercises)
I WANT the gem to say what the note after a nota cambiata and after a double neighbor should do
SO THAT each figure is judged as its sources judge it, and the lessons can state the shared shape once

## Acceptance Criteria

- The nota cambiata stays a five-note figure, and its dissonance treatment stays a primary matter: `HeadMusic::Style::Guideline::DissonanceFigures#cambiata_dissonance?` is unchanged, with notes 1, 3, and 5 consonant
- The double neighbor stays a four-note figure for dissonance treatment: `#double_neighbor_member?` is unchanged, and the fifth note never makes a neighbor an untreated dissonance
- A new secondary guideline prefers that the note after a double neighbor continue by step in the direction of the figure's last step. C–D–B–C–D earns no mark; C–D–B–C–B (a step that turns back) and C–D–B–C–E (a leap) each earn one. A double neighbor that ends the line earns none
- The guideline is in the third species, fifth species, and free species guides, and reads the pitch shape whatever the note values
- Specs cover the double neighbor followed by a step that continues, a step that turns back, and a leap, with either neighbor first, and the cambiata followed by the same three, using Salzer & Schachter's Example 3-19 for the double neighbor
- The existing fixtures of published third and fifth species examples keep their primary marks. Any new secondary mark is listed in the story
- The new guideline has an instruction in every locale (en, en_GB, de, es, fr, it, ru), and the existing dissonance instructions are checked for whether they should say that the cambiata is five notes
- CHANGELOG entry under Unreleased, saying that a double neighbor left by a leap or a turn back now earns a secondary mark
- BardTheory's `the-cambiata`, `third-species-guidelines`, and `fifth-species-guidelines` lessons and its dictionary entries for the nota cambiata and double neighbor are listed as follow-up: the double neighbor entries gain the preferred continuation, and the lessons can state the shared shape (after the leap, two steps the other way)

## Notes

Raised on 2026-11-24 while reviewing BardTheory's dictionary entries for the nota cambiata and the double neighbor.

Today the two figures are checked differently in `lib/head_music/style/guideline/dissonance_figures.rb`:

- **Nota cambiata** is a five-note figure. `cambiata_shape?` reads four intervals: a step, a leap of a third in the same direction, then two steps back in the opposite direction. Notes 1, 3, and 5 must be consonant. D–C–A–B–C passes; D–C–A–B–A is marked, because the fifth note turns back.
- **Double neighbor** is a four-note figure. `double_neighbor_figure?` reads three intervals: a step, a leap of a third, a step, ending on the starting pitch, with the first and last notes consonant. The fifth note is never examined, so C–D–B–C–D and C–D–B–C–B both pass.

The story was first written on the premise that the sources divide the same way for both figures. They do not. The two sources from the species tradition treat the figures differently, and the gem's two predicates already match them:

- **Salzer & Schachter, *Counterpoint in Composition*, pp. 59–63.**
  - The cambiata "arises from the decoration of a two-note figure formed by the first and last tones", two interlocking motions that "converge upon the fifth and final tone of the idiom". "The third tone of this figure must be consonant since it forms the beginning of the second, subsidiary melodic progression. The fifth tone, the goal of the two motions, will naturally be consonant." Where the tone after the leap starts no such progression, the figure is a different idiom, the skipped passing tone.
  - The double neighbor is "the four-note group consisting of main tone, upper neighbor, lower neighbor, and main tone". It "carries with it a danger of becoming a static area, detached from the line as a whole. That danger is minimized if we follow the last tone by a stepwise progression continuing the preceding melodic direction." Example 3-19 labels the two continuing forms "good", and a leap away (c) and a change of direction (d) "less good". Of (d): "we hear a descending stepwise motion embellished by échappées (or incomplete neighboring notes) rather than a stationary tone prolonged by upper and lower neighbors."
- **Open Music Theory**, "Composing a third-species counterpoint" (the openmusictheory.github.io edition; the Pressbooks chapter refused an automated fetch). The cambiata "is a five-note figure that outlines a step progression from downbeat to downbeat", and its "first, third, and fifth notes must be consonant with the cantus". For the double neighbor, "the direction between beats 3 and 4 should be the same as between beat 4 and the following downbeat. That motion across the barline should also be stepwise."
- Magnuson, *Sound Patterns*, gives the cambiata as "one step down, a 3rd down, two steps up" and calls the double neighbor "a five note figure". Not re-read for this story.

The fixtures agree as far as they go. Both cambiatas in the Fux fixtures (figure 55 bar 3, E–D–B–C–D, and figure 87a, A–G–E–F–G) are five-note forms with a consonant third note. No Fux fixture holds a double neighbor with a dissonant neighbor, which fits Salzer & Schachter's note that the figure's exclusion from textbooks "begins with Fux". So no fixture's grade moves, and the double neighbor's examples must come from Salzer & Schachter.

On 2026-11-24 BardTheory's lessons and dictionary were changed to describe the cambiata as five notes and the double neighbor as four, which matches the gem before and after this story.

### Decisions

- **Neither stricter nor looser: the cambiata keeps its five notes, and the double neighbor's fifth note becomes a secondary preference** (Rob, 2026-11-24).
  - The looser cambiata has no support in the species tradition. Its fifth note is the figure's goal, so without it the dissonance is unexplained.
  - The double neighbor's dissonances are explained by its fourth note. A poor fifth note is not an untreated dissonance, so the primary guideline should not mark it, and its message would be wrong if it did.
  - "Less good" and "should" are a discount. The gem's secondary tier carries that weight.
  - The strongest case for a primary mark is Salzer & Schachter's reading of the turned-back form as échappées, a figure the species guides refuse. They still grade it "less good", not wrong.
  - The lessons can state one shape for both: after the leap, two steps the other way. In the cambiata the second step completes the figure; in the double neighbor it is how the line should leave.

- **One rule in third species, fifth species, and free species** (Rob, 2026-11-24). All three already share the cambiata predicate, and the new preference reads pitches, so a fifth note that is a half note or a tied note is judged as a quarter is. Salzer & Schachter's fifth species chapter does not restate the figures; it refers to "the principle … governing the nota cambiata and double neighbor of third species".

- **Where a figure may begin is a separate story** (Rob, 2026-11-24): [dissonance-figure-placement](dissonance-figure-placement.md). The gem asks neither where a figure sits in the bar nor what note values carry it. That is a different rule, it would add primary marks in three guides, and it needs its own check against the fixtures. This story adds only a secondary mark.

- **The cambiata's third note must be consonant; that is settled** (Rob, 2026-11-24). Salzer & Schachter say so in third species (p. 62) and twice more for combined species, where a dissonant third note is their example of "an incorrect use of the cambiata". Open Music Theory agrees. Fux allowing a dissonant third note is a liberty with no other source in the tradition, and no fixture uses it.

- **The escape tone gets no rule for the note after it** (Rob, 2026-11-24). It decorates a step and is complete when it lands on a consonant note, which `escape_tone?` already requires. How a line continues after one belongs to the eighteenth-century guide. The double neighbor keeps its precedence there: a turned-back double neighbor is a double neighbor with a secondary mark, not two escape tones.

## Implementation Plan

[to be filled in by /stories plan]
