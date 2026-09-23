<!--
metadata:
  created_at:   2026-09-22T20:42:44-07:00
  activated_at: 2026-09-22T21:02:07-07:00
  planned_at:
  finished_at:
  updated_at:   2026-09-22T21:02:07-07:00
-->

# Story: Fifth Species Guide Improvements

## Summary

AS a maintainer of the fifth-species guides
I WANT the guides to express the character of the species, rhythmic mixture,
and to stop charging florid idioms that the pedagogy permits
SO THAT a fifth-species grade measures what a teacher of the species would
measure, and the composite separates fifth species from fourth on the merits
rather than by a thin margin

## Background

[Grade Every Fux Fifth-Species Figure](../done/grade-every-fux-fifth-species-figure.md)
graded every two-voice fifth-species figure in Gradus. Its verdict on the
guides: the dissonance discipline is expressed accurately and with evidence,
eleven of twelve figures clearing both primary harmony items; the character
of the species, mixture, is expressed only by implication. Fux defines fifth
species by the free use of the other four, and every source in
`references/fifth-species-counterpoint.md` agrees that no single species
should dominate. Nothing in the guides charges a line for being all one
rhythm. `MixedRhythmicValues`, primary in `FifthSpeciesMelody`, asks only for
three distinct durations and places one mark when it fails, which is why
Fux's fourth-species figure 73 still grades 0.929 on the `fifth_species`
composite, 0.024 below his own dorian fifth-species figure.

The same grading exposed calibration gaps in the general melodic rules, which
do not yet know the florid idioms. Every mark below is on a Fux line, and
under the standard the last story set, each is settled one of three ways: a
corrected reading, a liberty Fux took that keeps its mark, or a rule change
supported by a source other than Fux.

| Figure | mark | guideline | shape |
| --- | --- | --- | --- |
| 86a 12:2, 87 upper 8:2, 87a 8:2, 88b 7:2 | AlwaysMove | quarter on beat 2 re-struck as the beat-3 half that ties forward into a suspension |
| 85b 9:3 | AlwaysMove | D3 repeated across the bar line, untied on the scan |
| 88a bar 5 | none | `B A G2`, two quarters opening the bar with an untied half; Fux marks it N.B. himself and offers figure 89 as better |
| 82 5:3, 86a 11:1 | Diatonic | raised leading tone mid-line, stepping up to the final |
| 85a 5:3 and 6:4, 85b 2:4, 4:3, and 6:4 | Diatonic | the lydian B-flat |
| 84a 1:3, 8:3, 10:1 | ConsonantClimax | the phrygian line above the cantus opens on its peak E5 and ends on it |
| 87 upper 7:1 and 7:3 | ConsonantClimax | peak D5 re-approached by leap within one bar, `d A d2-` |

`StepOutOfUnison` also marks seven of the twelve figures, which the assessment
had not noticed; it has a criterion below. `StartOnPerfectConsonance` on
figure 82 is noted and not settled here.

## Acceptance Criteria

- **Rhythmic mixture is a primary guideline of `FifthSpeciesMelody`.** A new
  guideline charges a line in which one species dominates. It classifies each
  bar by the species texture it shows, whole note, halves, quarters and eighth
  pairs, or a bar entered by ligature, with a bar that mixes them counting as
  florid, and marks the line when one texture holds more than a stated share
  of the bars. The share and the way it is measured are named in the story,
  with a source other than Fux; the survey's "no single species should
  dominate" is the principle, and Hansen Media's limit of two consecutive bars
  with identical rhythm and Girton's caution against rhythmic sequences are
  the candidate measures. The mark is proportionate, as a discount and not a
  veto, and its cost grows with how far the line is from mixed.
- **It is strong.** The guideline takes the default strength, with no
  `strength :weak` declaration. The plan must answer `MostlyConjunct`'s
  precedent that a proportion threshold measures character rather than
  finding a fault: mixture is what makes a line fifth species at all, so a
  line without it has failed the species, not a matter of taste.
- **It replaces `MixedRhythmicValues` in the primary tier**, since two rules
  charging the same fault would count it twice. `MixedRhythmicValues` is
  removed from the guide and deleted if no other guide uses it, with the
  locale strings and the species survey's guideline table updated.
- **The composite diagonal widens on the merits.** Fux's fourth-species
  figure 73 and every first-, second-, and third-species fixture fall
  materially on `fifth_species_melody` and on the `fifth_species` composite;
  the target is the discount the fourth-species composite gives a
  first-species line, 0.85 or below. All twelve Fux fifth-species fixtures
  are adherent to the new guideline. If one is not, it is settled under the
  evidence-not-oracle standard and listed under "Marks on Fux's lines". The
  liberties map in `guide_species_diagonal_spec` keeps figure 85b as its only
  entry.
- **`AlwaysMove` knows the anticipation.** A quarter on the weak beat that
  repeats as the following strong-beat note, when that note ties forward into
  a suspension, is not a repeated note. The exemption is exactly this shape
  and no wider; a repeated pitch across a bar line, as in 85b bar 9, stays
  marked. The source is named in the story and is not Fux; Jeppesen's
  portamento, the weak-beat quarter that anticipates the note before a
  syncopation, is the candidate. The four figures listed above lose their
  `AlwaysMove` mark and their melody grades rise accordingly; no other corpus
  row moves under `AlwaysMove`.
- **Fux's N.B. is marked.** A guideline marks a bar that opens with two
  quarters and closes with a half that does not tie forward, the shape Fux
  flags in figure 88 bar 5 and answers with figure 89. Salzer and Schachter's
  rule that half notes precede quarter notes unless the half is suspended
  forward is the source; ntoll.org's exception, that the shape is acceptable
  after a bar ending in two quarters, is recorded as a disagreement and not
  adopted, because Fux's own N.B. sits on exactly such a bar. The guideline
  is secondary and weak, since Fux calls figure 89 better rather than 88
  wrong. Figure 88a's grade drops by the one mark and the story records the
  new number; every other fixture that trips it is listed.
- **`Diatonic` stops charging the pedagogy's own accidentals.** A raised
  seventh degree that steps up to the final is not charged wherever it occurs
  in the line, not only at the penultimate note, and B-flat in F lydian is not
  charged. Every other chromatic note remains charged. The sources are named
  in the story and are not Fux; Jeppesen on the lydian B-flat and on the
  raised leading tone at inner cadences is the candidate. The marks on 82,
  85a, 85b, and 86a listed above are removed; the with-errors corpus lines
  that `Diatonic` exists to catch still fail it, and the spec says which.
- **`ConsonantClimax` is settled for the two florid shapes.** Each of 84a's
  peak, which is the phrygian final an octave above the cantus and so the top
  of the line's cadence, and 87 upper's peak, re-approached by leap within a
  single bar, is settled as a rule change with a named non-Fux source or as
  a liberty that keeps its mark. The story records the decision and the
  reasoning for each; neither is fixed by widening the guideline's tolerance
  in general.
- **A fifth-species line by Jeppesen is a fixture.** At least one two-voice
  florid example from Jeppesen's *Counterpoint* joins the corpus under its
  own source name, sits on its own cantus firmus, and is pinned. It grades on
  the fifth-species diagonal like the Fux figures, so the new mixture
  guideline is calibrated against more than one book, and the same book that
  sources the `AlwaysMove` and `Diatonic` changes supplies a line they are
  tested on.
- **`StepOutOfUnison` is removed from `FifthSpeciesMelody` unless a source
  other than Fux applies it to florid lines.** It marks seven of the twelve
  Fux figures: the opening unison left by leap in 83 and 86b, and internal
  unisons left by leap in 82 (twice), 84a, 85a, and 86a. The fifth-species
  survey carries one unattributed line, "step out of unisons", and the rule
  otherwise comes from first species. The plan traces that line to a source.
  If none applies it to fifth species, the guideline leaves the guide by
  subtracting it from the moving melodic craft for fifth species only, the
  seven marks vanish, and the story records the movement. If one does, the
  rule stays and each of the seven marks is settled as a liberty or a
  corrected reading.
- **Every corpus movement has one cause.** Each guideline change lands in its
  own commit with its snapshot movement explained by class; the mixture
  guideline lands first. No harmony grade moves. The story's "Marks on Fux's
  lines" table is filled from the committed fixtures, and the CHANGELOG has
  an entry per guideline change.

## Notes

- `StartOnPerfectConsonance` marks figure 82 and was not assessed in the
  last story. It is a separate calibration question unless the plan finds it
  cheap to settle here.
- Decisions taken 2026-09-22 before planning: the mixture guideline measures
  dominance share rather than consecutive identical bars; it is strong;
  `StepOutOfUnison` is removed from fifth species if no source applies it
  there; the non-Fux fixture comes from Jeppesen.
- Three-voice fifth species is out of scope.
- Second through fourth species on the other cantus firmi are out of scope,
  for the reason the last story gave: their rhythm guidelines already
  separate the species and the fixtures would answer no open question.
- The threshold precedent: `MostlyConjunct`, `PreferContraryMotion`, and
  `PreferImperfect` declare `strength :weak` because a proportion measures
  character. The mixture rule is the one proportion that defines the species,
  which is the argument for keeping it strong. If the plan cannot make that
  argument hold, the story should say so before the guideline is written.
- Bar classification will meet Fux's mixed bars, a half followed by two
  quarters, or a quarter and an eighth pair and a quarter. Those are florid,
  not any one species, and should count toward mixture rather than against it.
- Fux's N.B. on figure 88, in Mann's translation, is the one calibration
  point where the author marks his own line. A guideline that agrees with him
  there is evidence the guide is calibrated, not that it is dogmatic.
- The survey in `references/fifth-species-counterpoint.md` section 6.3 lists
  `RhythmicVariety` and `PreferLongBeforeShort` as proposed enhancements;
  this story is where they land or are rejected by name.

## Implementation Plan

[to be filled in by /stories plan]
