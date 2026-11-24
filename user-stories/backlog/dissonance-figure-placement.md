<!--
metadata:
  created_at:   2026-11-24T15:35:04-08:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-11-24T15:35:04-08:00
-->

# Story: Place the Cambiata and Double Neighbor in the Bar

## Summary

AS a consumer of the gem grading third and fifth species counterpoint (BardTheory's exercises)
I WANT the nota cambiata and the double neighbor to be recognized only where the bar and the note values let them sound as those figures
SO THAT a leap from a dissonance is not excused by a shape that begins on the wrong beat or rests on a long dissonant note

## Acceptance Criteria

- The gem takes a position on where each figure may begin (see Open Questions) and the guides that recognize the figures apply it
- The gem takes a position on the note values that may carry a figure's dissonant notes in fifth species and free species
- Specs cover each figure beginning on every beat of a 4/4 bar, and a figure whose dissonant note is longer than a quarter
- Existing fixtures of published third and fifth species examples still grade as they do now, or each change in a grade is explained in the story. Fux's figure 87a begins a cambiata on beat 3
- CHANGELOG entry under Unreleased; a figure that passed before and is now marked is named there
- BardTheory's lessons and dictionary entries for the two figures are listed as follow-up

## Notes

Raised on 2026-11-24 while settling [cambiata-and-double-neighbor-fifth-note](cambiata-and-double-neighbor-fifth-note.md), and split from it because it is a different rule that would add primary marks.

`HeadMusic::Style::Guideline::DissonanceFigures` is given notes, melodic intervals, and a dissonance test, and no meter. Its figure predicates read pitch shape alone. Checked on 2026-11-24 over a held C:

| Line | Guideline | Result |
| --- | --- | --- |
| `g e f d \| e`, a double neighbor beginning on beat 2 | `ThirdSpeciesDissonanceTreatment` | no mark |
| `e f2 d \| e`, the upper neighbor a dissonant half note on beat 2 | `FloridDissonanceTreatment` | no mark |

Salzer & Schachter, *Counterpoint in Composition*:

- Double neighbor (p. 62): "This idiom must begin on the first beat of the measure. Otherwise, it will cease to sound like the decoration of a single tone."
- Nota cambiata (p. 63): "The cambiata idiom must begin on an accented beat. In general, the first quarter of the measure forms a better beginning than does the third." Begun on the third quarter, the tone after the leap falls on a downbeat and "the ear therefore tends to register the first three tones as representing a stepwise motion within a fourth with one passing tone omitted".
- "In composition, the nota cambiata is not restricted to even values" (p. 63), which bears on fifth species and free species.

Open Music Theory describes the double neighbor by beats 1 to 4 and the cambiata as running "from downbeat to downbeat", without stating either as a rule.

The escape tone story decided that accent is the calling guideline's question, since `DissonanceFigures` has no meter. The same split probably applies here: the predicates keep reading shape, and the guidelines ask about position.

### Open questions

- Is a cambiata begun on beat 3 accepted outright, as Fux's figure 87a and Salzer & Schachter's "accented beat" allow, or given a secondary mark for "a better beginning" on beat 1?
- Is a misplaced figure a primary mark (the dissonance is untreated) or a secondary one?
- Which note values may the dissonant notes take in fifth species? A source is needed beyond the one remark above.
- Does free species, where either voice may carry the figure, follow fifth species?

## Implementation Plan

[to be filled in by /stories plan]
