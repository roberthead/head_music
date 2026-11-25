<!--
metadata:
  created_at:   2026-11-24T15:35:04-08:00
  activated_at: 2026-11-24T18:42:00-08:00
  planned_at:
  finished_at:
  updated_at:   2026-11-24T19:01:09-08:00
-->

# Story: Place the Cambiata and Double Neighbor in the Bar

## Summary

AS a consumer of the gem grading third and fifth species counterpoint (BardTheory's exercises)
I WANT the nota cambiata and the double neighbor to be recognized only where the bar and the note values let them sound as those figures
SO THAT a leap from a dissonance is not excused by a shape that begins on the wrong beat or rests on a long dissonant note

## Acceptance Criteria

- **Placement, primary.** The dissonance guidelines (`ThirdSpeciesDissonanceTreatment`, `FloridDissonanceTreatment`, `FreeDissonanceTreatment`) recognize a double neighbor only where it begins on a downbeat, and a nota cambiata only where it begins on an accented beat. A figure placed elsewhere excuses nothing: each of its dissonant notes that is not a passing or neighbor tone in its own right earns the guideline's existing mark. No new string is needed for this
- Placement is read from where the figure's dissonant notes fall, not from where its first note is attacked, so a first note tied over a barline does not move the figure. Fux's figure 87a, whose first note is attacked on beat 3 and tied into the bar that holds the dissonance on beat 2, stays a cambiata begun on a downbeat and earns no mark of either kind
- **Placement, secondary.** A new weak secondary guideline prefers the cambiata begun on a downbeat: a cambiata begun on the bar's other accented beat, whose dissonance is treated, earns one mark. It is in every harmony guide that recognizes the cambiata: third species, first three species, fifth species, and free species. It has a name, an instruction, and a violation message in en, and in en_GB wherever the spelling differs
- **Note values.** In `FloridDissonanceTreatment` and `FreeDissonanceTreatment`, the dissonant notes of a cambiata and of a double neighbor must be quarter notes. A half note or an eighth in that place leaves the dissonance untreated. The figure's consonant notes may take any value
- **The half note.** In the same two guidelines, a dissonance attacked as a half note or longer is treated only as a passing tone. A half-note neighbor tone, which the second species guide already marks, is marked in fifth species, first three species, and free species too
- Free species follows fifth species in all of the above, read in whichever voice carries the figure. A dissonance the other voice explains with a figure of its own is still unmarked
- Rhythm is read from positions and the meter, not from beat numbers
- Specs cover each figure beginning on every beat of a 4/4 bar, with both neighbors dissonant and with one; a figure whose dissonant note is a half note and one whose dissonant note is an eighth; a half-note neighbor tone against a half-note passing tone; figure 87a's long first note; and a figure in the lower voice of a free species pair
- The existing fixtures of published third and fifth species examples keep their marks, primary and secondary. The research found nothing that should move; any row that does is explained in the story
- The pinned corpus snapshot is regenerated. Any row whose fitness falls is listed in the story
- CHANGELOG entry under Unreleased, naming each shape that passed before and is now marked, and stating the shift in the pinned corpus
- BardTheory's lessons and dictionary entries for the two figures and for the neighbor tone are listed as follow-up

## Notes

Raised on 2026-11-24 while settling [cambiata-and-double-neighbor-fifth-note](../done/cambiata-and-double-neighbor-fifth-note.md), and split from it because it is a different rule that would add primary marks.

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

### Research

Done on 2026-11-24 at `49966b99`, before planning.

**Current behavior.** Each figure was probed on every beat of a 4/4 bar against `ThirdSpeciesDissonanceTreatment`, `FloridDissonanceTreatment`, and `FreeDissonanceTreatment`. Both lines in the table above earn no mark, and so does every other placement, with one exception: where a neighbor lands dissonant on a downbeat, the florid and free guidelines mark it as an attacked downbeat dissonance. Over a held C unless a second note is given:

| Line | Shape | Third | Florid | Free |
| --- | --- | --- | --- | --- |
| `e f d e \| c4` | double neighbor from beat 1 | none | none | none |
| `g e f d \| e4` | double neighbor from beat 2 | none | none | none |
| `g g e f \| d e c2` | double neighbor from beat 3 | none | D on the downbeat | D on the downbeat |
| `e e g f \| a g e2` | double neighbor from beat 3, the downbeat neighbor consonant | none | none | none |
| `e e e g \| a f g2` | double neighbor from beat 4, the downbeat neighbor consonant | none | none | none |
| `c' b g a \| b4` over C, G | cambiata from beat 1 | none | none | none |
| `e c' b g \| a b d'2` over C, D | cambiata from beat 2 | none | none | none |
| `e2 c' b \| g a b2` over C, E | cambiata from beat 3 | none | none | none |
| `c'2 b2 \| g a b2` over C, E | cambiata with a half-note dissonance | none | none | none |
| `e/ f/ d/ e/ c2 z` | double neighbor in eighths | none | none | none |
| `e2 f2 \| e4` | half-note neighbor tone | none | none | none |

`WeakBeatDissonanceTreatment`, the second species guideline, accepts only a passing tone, so it already marks the half-note neighbor that the last row shows the mixed guides accepting.

**Fux's figure 87a does not begin on beat 3 in the sense Salzer & Schachter mean.** Its cambiata is A–G–E–F–G. The A is attacked on beat 3 of bar 1 and tied into bar 2, the dissonant G falls on beat 2, the leap lands on beat 3, and the fifth note is the downbeat of bar 3. Their objection to a beginning on the third quarter is that "the tone following the leap occurs on the first beat of the next measure", which 87a does not do. It is the downbeat form with a long first note. The story's original criterion said otherwise and is corrected.

**The pinned corpus.** Scanned for every dissonance that only a cambiata or a double neighbor excuses: two, both cambiatas, in Fux's figure 55 (bar 3, E–D–B–C–D) and figure 87a. In each the dissonance is a quarter note on beat 2. No voice holds a double neighbor with a dissonant neighbor. Of the attacked weak-beat dissonances in the third and fifth species fixtures, none is a half note or longer; the eighths are seven neighbor tones and three passing tones, all stepwise. So no decision below should move a published grade.

**Note values have a source.** Salzer & Schachter, fifth species, pp. 103–105:

- "every note value is governed by the procedures of the species to which it belongs. A half note, for example, must be consonant if it occurs on the first beat of the measure; if it appears on the second beat, it may be dissonant but only as a passing tone. A quarter note must also be consonant on the first quarter of the measure; dissonant passing and neighboring notes, etc., may appear on the rhythmically appropriate quarters."
- "Eighth notes present no problems of dissonance treatment. They appear only on the weak quarters, and the requirement for stepwise motion in itself guarantees correctness."
- "a leap from an eighth should never occur" (p. 103).

Their remark that "in composition, the nota cambiata is not restricted to even values" (p. 63) is about composition and the figure's rhythm as a whole; it sits beside a Busnois excerpt, not a species exercise.

Not checked: Open Music Theory's fifth species chapter, and any second source for the half-note rule.

### Decisions

- **A misplaced figure leaves its dissonance untreated; the mark is primary** (Rob, 2026-11-24). Salzer & Schachter say "must" for both placements, where they said "less good" for the double neighbor's exits, and they give the reason: off the downbeat the double neighbor "will cease to sound like the decoration of a single tone". The dissonance guidelines stop recognizing the figure there, so no new guideline or string is needed. In `g e f d | e` over C both F and D are marked: F leaps away, and D is reached by that leap, so neither is a neighbor tone on its own. Where one neighbor is consonant there is one mark.

- **A cambiata begun on the bar's second accented beat is a cambiata with a weak secondary mark** (Rob, 2026-11-24). Their rule is "an accented beat"; the preference for the first quarter is hedged with "in general", which is the weight the secondary tier carries and the weight given to the double neighbor's "less good" exits. Open Music Theory describes only the downbeat form. The preference needs a new guideline, on the pattern of `ContinueAfterDoubleNeighbor`.

- **The dissonant notes of both figures are quarter notes** (Rob, 2026-11-24). A dissonant half note may be only a passing tone, and an eighth may not be left by leap, so neither can be the note a cambiata or a double neighbor leaps from or to. The consonant notes stay free, which keeps figure 87a's long first note.

- **A dissonant half note is a passing tone, in this story** (Rob, 2026-11-24). The sentence that settles the figures' note values also refuses the half-note neighbor tone, which the fifth species and first three species guides accept and the second species guide marks. It is the same rule and the same code, and no published fixture holds an attacked dissonant half note. This is the story's first widening.

- **Free species follows fifth species in all of it** (Rob, 2026-11-24). The free species guide is "fifth species' treatment, with either voice able to explain a dissonance", and it already reads dissonance from note values for the eighth after a dotted quarter. No source treats two free voices separately; Salzer & Schachter's "combined species" is three voices with a cantus firmus, so this extends their fifth species rule rather than quoting one.

- **Placement is read from the dissonant notes** (Claude's reading, put to Rob with the figure 87a finding and not disputed). A cambiata begins on a downbeat when its dissonance falls on the weak beat after the downbeat, whenever its first note was attacked. The double neighbor is read the same way: its neighbors fall on the two beats after the downbeat and it returns within the bar. `e2 f d | e`, a half-note main tone with the neighbors on beats 3 and 4 and the return on the next downbeat, is therefore not a double neighbor begun on the downbeat. This last case was not put to Rob as its own question.

## Implementation Plan

[to be filled in by /stories plan]
