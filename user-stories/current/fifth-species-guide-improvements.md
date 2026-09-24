<!--
metadata:
  created_at:   2026-09-22T20:42:44-07:00
  activated_at: 2026-09-22T21:02:07-07:00
  planned_at:   2026-09-23T09:57:17-07:00
  finished_at:
  updated_at:   2026-09-24T09:45:40-07:00
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
supported by a source other than Fux. This story tightens that standard:
the source must come from the tradition the guides describe. Fux claims
Palestrina but represents eighteenth-century practice, and the guides descend
from him and his twentieth-century restatements, so Salzer and Schachter,
Schenker, Schoenberg, Gauldin's eighteenth-century book, Open Music Theory,
and the course sources the survey names are citable. Jeppesen, Schubert, and
Gauldin's sixteenth-century book describe Palestrina's tradition, which the
backlog keeps apart in
[Sixteenth-Century Style Guides](../backlog/sixteenth-century-style.md);
they may corroborate a reading but cannot authorize a change here. Salzer
and Schachter's *Counterpoint in Composition* is in hand as a scan, and its
two-part fifth-species chapter (pp. 101 to 110), its account of the modes
(pp. 9 to 10), and its cantus-firmus chapter (pp. 7 to 8) settle every
trace below; the pages are cited at each criterion.

| Figure | mark | guideline | shape |
| --- | --- | --- | --- |
| 86a 12:2, 87 upper 8:2, 87a 8:2, 88b 7:2 | AlwaysMove | quarter on beat 2 re-struck as the beat-3 half that ties forward into a suspension |
| 85b 9:3 | AlwaysMove | D3 repeated across the bar line, untied on the scan |
| 88a bar 5 | none | `B A G2`, two quarters opening the bar with an untied half; Fux marks it N.B. himself and offers figure 89 as better |
| 82 5:3 | Diatonic | B-flat in D dorian in the descending figure `d c _B G` |
| 86a 11:1 | Diatonic | raised leading tone mid-line, stepping up to the final |
| 85a 5:3 and 6:4, 85b 2:4, 4:3, and 6:4 | Diatonic | the lydian B-flat |
| 84a 1:3, 8:3, 10:1 | ConsonantClimax | the phrygian line above the cantus opens on its peak E5 and ends on it |
| 87 upper 7:1 and 7:3 | ConsonantClimax | peak D5 re-approached by leap within one bar, `d A d2-` |

`StepOutOfUnison` also marks seven of the twelve figures, which the assessment
had not noticed; it has a criterion below. `StartOnPerfectConsonance` on
figure 82 is noted and not settled here.

## Acceptance Criteria

- **Rhythmic mixture is a primary guideline of `FifthSpeciesMelody`.** A new
  guideline, `MixSpeciesTextures`, classifies each bar of the voice by the
  single-species texture it shows, whole note, halves, quarters and eighth
  pairs, or a bar entered by ligature, with a bar that mixes them counted as
  florid and an empty bar left out. It marks every bar of a run of more
  than two consecutive bars in one single-species texture, over the bars
  from the voice's first bar to the bar before its last, with no
  denominator, the shape `SustainAcrossBarlines` uses; a florid or empty
  bar ends a run. The rule is Salzer and Schachter's, pp. 101 to 102: "More
  than two, or at most, two-and-a-half measures of a single note value will
  destroy the rhythmic balance of the line", and "a mixture of note values
  should preponderate over single values unmixed". Hansen Media's limit of
  two consecutive bars with identical rhythm agrees; Girton's caution
  against rhythmic sequences is the same idea. The run limit is two bars,
  the strict end of Salzer and Schachter's range, so that a third bar in
  one texture is marked with the two before it. The discount is bounded by
  the primary tier and the item's cost grows with each bar in an over-long
  run.
- **It is strong.** The guideline takes the default strength, with no
  `strength :weak` declaration. The class comment answers `MostlyConjunct`'s
  precedent: a proportion of steps measures the character of a line that is
  already some species, while a proportion of one texture decides whether the
  line is fifth species at all, so failing it is failing the species, not a
  matter of taste.
- **It replaces `MixedRhythmicValues` in the primary tier**, since two rules
  charging the same fault would count it twice. `MixedRhythmicValues` is
  removed from the guide and deleted with its require, spec, `en.yml` entry,
  and survey rows; no other guide uses it. The new guideline's sentences
  avoid note-value nouns so `en.yml` is the only locale touched.
- **The composite diagonal widens on the merits.** Fux's fourth-species
  figure 73, whose eight ligature bars form two runs of four on either side
  of one untied bar, and every first-,
  second-, and third-species fixture, each a single run, fall to 0.85 or
  below on the `fifth_species` composite, and the diagonal spec asserts it
  for each other species. The dominance-share prototype measured figure 73
  at 0.826 with every dominant bar marked; the run limit marks the same
  eight bars of figure 73 and the plan re-measures the rest before the
  guideline is written, and reports if the target is not reached rather
  than reshaping the rule to reach it. Re-measured at the end of the story:
  figure 73 grades 0.827, figure 33 0.815, figure 55 0.796, the triple-meter
  line 0.608, and the first-species counterpoints at most 0.625, so the
  target is reached. All twelve Fux fifth-species fixtures are adherent to
  the new guideline, none holding a run longer than two bars. The liberties
  map gains no entry; 85b's entry stays as a recorded verdict, and the spec asserts each named
  liberty is present in the fixtures and marked on that guide.
- **`AlwaysMove` knows the anticipated resolution.** What Fux writes in
  86a bar 12, 87 upper bar 8, 87a bar 8, and 88b bar 7 is a suspension
  whose tone of resolution is anticipated as a quarter on beat 2 and struck
  again on beat 3. Salzer and Schachter name it among the decorations of
  the resolution (p. 104, "anticipation of tone of resolution", Example
  5-9), for either voice, so the exemption is exactly that shape: a
  weak-beat quarter that repeats as the beat-3 resolution of a suspension
  held from the previous bar, whether or not the beat-3 note ties forward.
  Nothing wider: a repeated half, a repetition not preceded by a
  suspension, or a quarter approached from below stays marked, so 85b bar 9
  keeps its mark. All four figures lose their `AlwaysMove` mark and move
  under every guide carrying `AlwaysMove`; no other voice moves. Ars Nova's
  allowance for repetition in upper parts and Jeppesen's anticipation are
  corroboration.
- **Fux's N.B. is marked.** `PreferLongBeforeShort`, secondary and weak in
  `FifthSpeciesMelody`, marks a bar that opens with two quarters and closes
  with a longer note that does not tie forward, the shape Fux flags in figure
  88 bar 5 (`B A G2`) and answers with figure 89. Salzer and Schachter are
  the source (p. 103, Examples 5-4 and 5-5): "Coming after the two short
  notes, the half note constitutes a static point; it blocks the flow from
  the two quarters rather than channeling it into the following measure",
  so "the rhythm of Example 5-4 must not be employed", while "two quarter
  notes may precede a half within the measure if the half is tied over into
  the following measure". ntoll.org's exception, that the shape is
  acceptable after a bar ending in two quarters, is recorded as a
  disagreement and not adopted, because Fux's N.B. sits on exactly such a
  bar. It is weak because Fux calls figure 89 better rather than 88 wrong,
  although Salzer and Schachter's "must not" would support strong; the
  story records the choice.
  Figure 88a is the only corpus voice marked; twenty-three Fux bars have the
  shape tied forward and are exempt. Adding a secondary item changes the
  item count on every gated row of the two fifth-species guides and
  redistributes secondary weight, so every voice with a secondary mark moves
  by a few thousandths, listed as one class.
- **`Diatonic` stops charging the accidentals the modes require.** Salzer
  and Schachter, pp. 9 to 10 and 20, name four: in dorian and mixolydian
  "the seventh step is raised" when "functioning as a leading tone"; at a
  cadence in minor, "if the leading tone is preceded by the sixth degree of
  the scale, that tone must also be raised"; "in polyphonic textures the
  Lydian mode (on F) regularly employs B flat"; and in dorian the sixth
  step "occurs in variable form", with "the natural ... used in ascending
  lines and the flat ... in descent", as in mixolydian where "B flat
  frequently occurs in descending progressions". `Diatonic` exempts exactly
  those: a raised seventh that steps up to the tonic, wherever it occurs; a
  raised sixth that steps up to a raised seventh; the lowered fourth in
  lydian; and the lowered sixth in dorian or lowered third in mixolydian
  approached from above and left downward. The penultimate exemption is
  subsumed by the first. This clears 86a 11:1, 82 5:3, and the five lydian
  marks on 85a and 85b. Phrygian gets no B-flat exemption ("seldom uses B
  flat"). The with-errors corpus lines that `Diatonic` exists to catch
  still fail it, asserted by name, and any other corpus row the exemptions
  clear, such as B-flats in figures 55 and 73, is listed by class.
- **`ConsonantClimax` keeps both marks as liberties.** Salzer and
  Schachter are explicit: "The high point of a line should never be
  repeated" (p. 8) and, for the moving species, "the climax itself should
  not be repeated" even with a subsidiary high point planned (p. 42). No
  species-tradition source clears either shape. 84a's peak, the
  phrygian final at the top of the line's cadence, and 87 upper's peak,
  re-approached by leap within one bar, keep their marks. Both are pinned in
  `consonant_climax_spec.rb` as recorded verdicts. The guideline is
  unchanged.
- **`StepOutOfUnison` stays, and learns the opening and the tie.** It
  marks seven of the twelve Fux figures: the opening unison left by leap in
  83 and 86b, and internal unisons left by leap in 82 (twice), 84a, 85a,
  and 86a. Salzer and Schachter apply the rule to fifth species (p. 106):
  unisons "are permitted on the first beat only through suspension. They
  may occur elsewhere in the measure if tied over or followed by stepwise
  motion." The opening tone is outside that rule, since the lower
  counterpoint begins on "a unison or octave" (p. 40) and the second-species
  discussion excludes "the beginning and end of the exercise". So the
  guideline exempts the voice's first note and a unison that is tied over
  the bar line, which clears 83 and 86b and any tied interior unison the
  plan finds; every interior unison quitted by leap keeps its mark as a Fux
  liberty and is listed. Ars Nova's silence on leaving the unison is not a
  source against the rule. The exemption's movement is the cleared voices
  under every guide carrying `StepOutOfUnison`.
- **Every corpus movement has one cause.** Each guideline change lands in
  its own commit with its snapshot movement explained by class, fitness
  movement counted separately from item-count movement. A zero-movement
  extraction of the shared bar-span helpers may precede the mixture
  guideline, which otherwise lands first. No harmony grade moves. The
  story's "Marks on Fux's lines" table is filled from the committed
  fixtures, and the CHANGELOG has an entry per guideline change.

## Notes

- `StartOnPerfectConsonance` marks figure 82 and was not assessed in the
  last story. It needs its own source review and is deferred.
- Decisions taken 2026-09-22 and 2026-09-23 before planning: the mixture
  guideline is strong and replaces `MixedRhythmicValues`; sources for the
  shared guides must come from the species tradition, so Jeppesen is
  corroboration only, and his fifth-species examples and the dotted-half
  allowance they would need are moved to the sixteenth-century story; with
  Salzer and Schachter read, the mixture measure is their run limit rather
  than the dominance share first chosen, `StepOutOfUnison` stays because
  they apply it to fifth species, and the anticipated resolution and the
  modal accidentals are sourced rule changes rather than liberties.
- Salzer, Felix, and Carl Schachter. *Counterpoint in Composition: The
  Study of Voice Leading*. McGraw-Hill, 1969; Columbia Morningside edition,
  1989. Scan at `~/Documents/_music-study/counterpoint/Salzer-Schachter.pdf`,
  image only; PDF page is the printed page plus 17, and `tesseract` reads a
  200 dpi render. Passages used: the modes and their accidentals, pp. 9 to
  10; the climax and repetition of a single tone, pp. 7 to 8; the cadence
  and the raised sixth, p. 20; second-species unisons and the climax not
  repeated, pp. 40 to 42; fifth species, pp. 101 to 107, with the run limit
  and "preponderate" on pp. 101 to 102, the static point on p. 103, the
  decorations of the resolution on p. 104, unisons on p. 106, and the whole
  note "confined to the last measure" on p. 101. Their fifth-species
  examples, pp. 101 to 110, are the right second author for the mixture
  guideline's calibration, and a follow-up.
- Three-voice fifth species is out of scope.
- Second through fourth species on the other cantus firmi are out of scope,
  for the reason the last story gave: their rhythm guidelines already
  separate the species and the fixtures would answer no open question.
- The threshold precedent: `MostlyConjunct`, `PreferContraryMotion`, and
  `PreferImperfect` declare `strength :weak` because a proportion measures
  character. The mixture rule is the one proportion that defines the species,
  which is the argument for keeping it strong.
- Bar classification meets Fux's mixed bars, a half followed by two
  quarters, or a quarter and an eighth pair and a quarter. Those are florid,
  not any one species, and a florid bar ends a run rather than extending
  one. Treating florid as a texture of its own would mark Fux's 87 upper,
  which is 82 percent florid.
- Fux's N.B. on figure 88, in Mann's translation, is the one calibration
  point where the author marks his own line. A guideline that agrees with him
  there is evidence the guide is calibrated, not that it is dogmatic.
- Ars Nova's fifth-species instructions (in the survey's source list) also
  say "Dotted notes will not be used", which is why the dotted half stays
  marked here and belongs to the sixteenth-century story with Jeppesen.
- The survey in `references/fifth-species-counterpoint.md` section 6.3 lists
  `RhythmicVariety` and `PreferLongBeforeShort` as proposed enhancements;
  `RhythmicVariety` lands as `MixSpeciesTextures` with the run limit and
  `PreferLongBeforeShort` lands by name.

## Marks on Fux's lines

Every melodic mark left on the twelve counterpoints after this story, read
from the committed fixtures, with its verdict. The harmony marks, including
`StartOnPerfectConsonance` on 82 and 85b's `EmbellishedSuspensionTreatment`,
are outside this story. Grades are on the `fifth_species` composite, before
this story and after it.

| Figure | before | after | melodic marks remaining | verdict |
| --- | --- | --- | --- | --- |
| 82 | 0.953 | 0.954 | `StepOutOfUnison` 3:3, 4:2 | Fux's liberty: interior unisons left by leap (S&S p. 106) |
| 83 | 0.994 | 1.000 | none | the opening unison is exempt |
| 84a | 0.959 | 0.959 | `ConsonantClimax` 1:3, 8:3, 10:1; `StepOutOfUnison` 8:2 | Fux's liberties: the peak repeated (S&S pp. 8, 42), an interior unison left by leap |
| 84b | 1.000 | 1.000 | none | |
| 85a | 0.986 | 0.986 | `StepOutOfUnison` 3:2 | Fux's liberty |
| 85b | 0.916 | 0.917 | `AlwaysMove` 9:3 | Fux's liberty: a half repeated across the bar line, untied on the scan |
| 86a | 0.959 | 0.965 | `StepOutOfUnison` 8:2 | Fux's liberty |
| 86b | 0.986 | 0.992 | none | the opening unison is exempt |
| 87 upper | 0.985 | 0.991 | `ConsonantClimax` 7:1, 7:3 | Fux's liberty: the peak re-approached by leap within one bar |
| 87a | 0.994 | 1.000 | none | |
| 88a | 1.000 | 0.997 | `PreferLongBeforeShort` 5:1 | Fux's own N.B.; he offers figure 89 as better |
| 88b | 0.994 | 1.000 | none | |

The rule changes cleared `AlwaysMove` on 86a, 87 upper, 87a, and 88b;
`Diatonic` on 82, 85a, 85b, and 86a; and `StepOutOfUnison` on 83 and 86b.

## Corpus movement

Each checkpoint was captured before and after with `bin/guide_grade_corpus.rb`
and joined with `bin/guide_grade_table.rb`.

0. `BarSpan` extraction: none; the captures are byte-identical.
1. `MixSpeciesTextures`: 175 rows, all on `fifth_species_melody` and the
   `fifth_species` composite. Every one-texture voice falls: every cantus
   firmus, every first-species counterpoint, the solo and against-empty
   lines, figures 33, 55, and 73, and the triple-meter counterpoint and
   cantus. Two three-bar solo lines rise on the melody guide and lose their
   message on both guides, since two body bars cannot hold an over-long run.
   No other message or item count moves.
2. `AlwaysMove`: 56 rows, figures 86a, 87 upper, 87a, and 88b under the 14
   guides that carry it, each up and one message fewer.
3. `PreferLongBeforeShort`: 250 rows on the two fifth-species guides gain one
   item. Figure 88a falls, to 0.995 on the melody guide; 176 rows rise by at
   most 0.005 as the secondary tier's weight is shared by one more item; 72
   move in item count only.
4. `Diatonic`: 138 rows, six counterpoints (82, 85a, 85b, 86a, 73, and 55)
   under the 23 guides that carry it; none falls.
5. `ConsonantClimax`: none.
6. `StepOutOfUnison`: 120 rows, ten voices under the 12 guides that carry
   it, each an opening unison left by leap: counterpoints 83 and 86b, the
   cantus firmi of 83, 86b, 87a, figure 55, and two first-species figures,
   and the two against-cantus lines; none falls.

Implementation surfaced one correction to the classification as planned: a
note that fills its bar is whole-note texture however it is notated, so the
triple-meter cantus's dotted wholes count. Classifying by notation first had
let that cantus rise.

## Review

Reviewed 2026-09-24 at commit `131dcd0`, the eight commits from `267299a` on.
A product-manager agent verified the criteria; it checked out every commit
that touches `lib/` and ran the snapshot and diagonal specs at each. A
code-reviewer agent reviewed `lib/` and `spec/`. Every example under
`spec/head_music/style` passes and rubocop is clean.

### Acceptance criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Mixture is a primary guideline | ✅ | `mix_species_textures.rb` marks every bar of a run of more than two in one texture; the primary tier is pinned in `fifth_species_melody_spec.rb` |
| 2 | It is strong | ✅ | no `strength` call; the class comment answers `MostlyConjunct`'s precedent |
| 3 | It replaces `MixedRhythmicValues` | ✅ | class, spec, require, and `en.yml` entry deleted; `en.yml` is the only locale in the diff |
| 4 | The diagonal widens on the merits | ✅ | `guide_species_diagonal_spec.rb` asserts ≤ 0.85 for each other species; figure 73 0.827 at HEAD; all twelve Fux figures adherent; the liberties map is unchanged |
| 5 | `AlwaysMove` knows the anticipated resolution | ✅ | 86a, 87 upper, 87a, 88b clear; 85b keeps `9:3:000 to 10:2:000`; 56 rows, none down |
| 6 | Fux's N.B. is marked | ⚠️ | code, tier, and 88a's only mark all match; the criterion's count of "nineteen" tied-forward bars is 23 by the rule's own conditions |
| 7 | `Diatonic` stops charging the modal accidentals | ✅ | 82, 85a, 85b, 86a clear; the chromatic-error cantus keeps three marks; figure 55 keeps its three ascending B-flats |
| 8 | `ConsonantClimax` keeps both marks | ✅ | guideline not in the diff; 84a and 87 upper pinned by code |
| 9 | `StepOutOfUnison` learns the opening and the tie | ✅ | 83 and 86b clear; 82 (twice), 84a, 85a, 86a pinned |
| 10 | Every corpus movement has one cause | ⚠️ | one cause per commit, each commit's snapshot matching its code, and no harmony guide moving; the recorded numbers drift slightly (findings 3 and 4) |

### Code review findings

1. **`MixSpeciesTextures` calls a lone note a whole-note bar wherever it
   starts** (`mix_species_textures.rb:72`, important). The test checks only
   that the note reaches the bar line, so a half after a half rest, `z2 A2`,
   is classified `:whole`. Verified: `z2 A2|A4|G4|...` is marked as a
   three-bar whole-note run when only two bars are whole notes, and every
   Fux entry after a half rest classifies as `:whole` rather than `:half`.
   Fix: also require the note to start on the downbeat, and add the
   second-species-opening spec. The corpus may move slightly.
2. **A comment on `long_runs` contradicts the code**
   (`mix_species_textures.rb:31-32`). It says neither the first nor the last
   bar is counted, but `body_bar_numbers` includes the first bar, as the plan
   intended and the specs assert. Reword it to say only the last bar is left
   out.
3. **The re-measured grades were taken at the mixture commit, not at
   HEAD.** Figure 73 0.826, figure 55 0.795, and the triple-meter line 0.607
   in criterion 4 and the CHANGELOG are the values after `703b66a`; later
   commits nudged them to 0.827, 0.796, and 0.608. Label them or restate them.
4. **The mixture commit moved 175 rows, not 173.** Two composite rows,
   `solo-ascending-3` and `solo-repeated-3` on `fifth_species`, lost a message
   without a fitness change. "Two three-bar solo lines rise" is true on the
   melody guide only. Fix in the CHANGELOG and in "Corpus movement".
5. **The criterion's tied-forward count** (criterion 6) is 23, not nineteen.
6. **Stale plan text.** Risks still says figure 73 "is one run of eight
   ligature bars"; it is two runs of four.
7. **A mislabeled spec example** (`diatonic_spec.rb`, "marks a phrygian
   lowered fourth"). B-flat in E phrygian is the lowered fifth. The behavior
   is right; only the name is wrong.
8. **`Diatonic#raised_sixth_to_raised_seventh?` does not require the raised
   seventh to reach the tonic** (minor). In A aeolian, `F# G# E` marks the
   G-sharp but passes the F-sharp. Requiring `raised_seventh_to_tonic?` of the
   following note would bind the pair, as Salzer and Schachter's cadence does.
9. **A vacuous spec** (minor). `PreferLongBeforeShort`'s triple-meter example
   has no half in the bar, so it passes on the missing half, not the meter.
10. **The CHANGELOG links the story under `done/`**, which resolves only
    after `/stories finish`. Expected; no change needed.

Nothing fails a criterion, but finding 1 is a real misclassification in the
story's central guideline and should be fixed before `finish`. Findings 2 to
9 are small.

### Resolution

Findings 1 to 9 were fixed on 2026-09-24, and none moved a corpus grade.

- 1 and 2: `d97b89b`. A bar is whole-note texture only when its note starts
  on the downbeat, so Fux's half-rest entries now read as half-note bars; two
  specs pin the second-species opening. The comment now says only the last
  bar is left out.
- 7 and 8: `13989db`. The raised sixth is exempt only when its raised seventh
  reaches the tonic; the phrygian spec is renamed for the lowered fifth.
- 9: `76bcf62`. The spec's vacuity hid a real gap: the rule found the static
  point by beat number, so it missed two quarters and a whole in 3/2. It now
  reads the notes' positions, and the triple-meter specs are 3/2 bars marked,
  and adherent when tied forward.
- 3 to 6: the story and CHANGELOG restate the grades at the end of the story
  (figure 73 0.827, figure 55 0.796, the triple-meter line 0.608, first
  species at most 0.625), count 175 rows for the mixture commit, count
  twenty-three tied-forward bars, and describe figure 73 as two runs of four.

## Implementation Plan

Eight checkpoints, each a commit with one cause of snapshot movement. Before
touching `lib/` at a checkpoint, capture
`bundle exec ruby bin/guide_grade_corpus.rb tmp/cN-before.json`; after,
capture `tmp/cN-after.json` and join with
`bundle exec ruby bin/guide_grade_table.rb tmp/cN.md "<cause>:tmp/cN-before.json:tmp/cN-after.json"`.
Regenerate with `bundle exec rake style:snapshot_corpus_fitness`, run
`bundle exec rake style:snapshot_english` only when the distinct item set
changes (checkpoints 1 and 3), then `bundle exec rubocop -a` and
`bundle exec rake`. Write each CHANGELOG entry and the story's movement
paragraph from `tmp/cN.md`, counting fitness movement separately from
item-count-only movement.

0. **Extract `BarSpan` (snapshot byte-identical).** A module
   `HeadMusic::Style::Guideline::BarSpan` with `first_bar_number`,
   `last_bar_number`, `middle_bar_numbers`, `body_bar_numbers` (first through
   the bar before the last, for checkpoint 1), `downbeat_of`, `notes_in_bar`,
   and `mark_bar` (placements, or the empty-span mark). Include it in
   `SustainAcrossBarlines` and `NoteCountPerBar` and delete their duplicated
   copies; require it in `lib/head_music.rb` beside `guideline/melodic_context`.
   The last story's review asked for this. Prove zero movement with an
   empty capture diff.

1. **`MixSpeciesTextures` replaces `MixedRhythmicValues`.** Class includes
   `BarSpan`; `MAXIMUM_RUN = 2`, readable through `options.fetch(:maximum_run)`
   as `SustainAcrossBarlines` exposes its ratio. First re-measure: grade the
   corpus with the run limit before writing specs, and record figure 73,
   figures 33 and 55, the triple-meter line, and the first-species maximum
   on the composite in the story; if figure 73 does not reach 0.85, stop and
   report rather than reshape the rule. Span is `body_bar_numbers`: the
   first bar is texture the author chose (Fux's half-rest entry is half-note
   texture) and the final bar is a whole note by the other primary's rule.
   Classify a bar with
   `held = voice.note_at(downbeat)` and a tail when `held.position < downbeat`
   (a tie across the bar line is one placement): no attacks and no tail is
   `empty`, which ends a run without counting toward one (the rest is
   `NoRestsAfterNote`'s fault); a tail through the whole bar with no attacks
   is `whole`; a tail
   ending at beat 3 followed only by halves is `ligature`; any other tail is
   `florid`; with no tail, all wholes `whole`, all undotted halves `half`,
   all quarters or eighths `quarter`, anything else including a dotted half
   `florid`. Rests never appear in `notes`, so `z2 A2-` is a half bar; triple
   meter needs no special case. Runs: walk the body bars and collect maximal
   runs of one single-species texture; a florid or empty bar ends a run.
   Marks: every bar of a run longer than `MAXIMUM_RUN`, via `mark_bar`;
   denominator 1, so cost is `0.618^n` and grows with the bars in over-long
   runs; as one of two strong primaries the item holds 0.309 of the melody
   grade, which bounds the discount. Strength default; the class comment carries the
   answer to `MostlyConjunct`'s precedent. Guide:
   `primary_items(AllowFifthSpeciesRhythmicValues, MixSpeciesTextures)`.
   Delete `mixed_rhythmic_values.rb`, its spec, its require, and its `en.yml`
   entry. Locale: `guidelines.mix_species_textures` in `en.yml` only, worded
   without note-value nouns ("Mix the textures of the first four species;
   no one of them may run on for more than two bars."). Specs in
   `mix_species_textures_spec.rb`: no notes; one-bar voice; every Fux
   fifth-species figure adherent; figure 73 with its eight ligature bars
   marked by code; figure 55; a first-species line with every body bar
   marked; a tie-in followed by quarters is florid; a dotted half is florid;
   an empty middle bar ends a run; a whole held across a bar line; the
   triple-meter line; a solo voice; a run of exactly two adherent; a run of
   three marked in full; two runs separated by one florid bar adherent; a
   configured run limit. `fifth_species_melody_spec.rb` pins the
   primary tier through `items_by_tier`; `guide_item_strings_spec.rb` swaps
   the row; the diagonal spec adds `<= 0.85` on the composite for each other
   species beside the fourth-species assertion. Survey: 3.7 records the
   measure with Salzer and Schachter pp. 101 to 102; 6.1 and 6.2 replace the stale
   primary block and row; 6.3 marks `RhythmicVariety` landed; 6.4 moves the
   item to hard. CHANGELOG Added and Removed entries, and the Unreleased
   lead names four stories. Movement, the two fifth-species guides only:
   `item_count` and `message_count` unchanged everywhere; fitness down on
   every gated one-texture voice (solo and repeated ladders, `against-empty`,
   `against-cantus`, every cantus-firmus voice, every first-species
   counterpoint, the with-errors lines, figures 33, 55, 73, the triple-meter
   counterpoint); unchanged for the twelve Fux fifth-species counterpoints
   and every gated-out voice; no harmony guide. A row whose `message_count`
   moves is a voice one rule marked and the other passed; expect none.

2. **`AlwaysMove` knows the anticipated resolution.** In `marks`, reject a
   unison pair when the first note is an undotted quarter on beat 2, the
   second is on beat 3, and the note sounding at the bar's downbeat
   (`voice.note_at(downbeat)`) began before the bar, that is, a suspension
   held from the previous bar, from which the beat-2 quarter descends by
   step. Source: Salzer and Schachter p. 104. No register condition and no
   tie-forward condition. Strings unchanged. Specs: anticipated resolution
   adherent, tied forward or not; repeated half marked; repeated quarter
   with no suspension before it marked; quarter approached from below
   marked; repeated quarter from beat 1 to 2 marked; the four Fux figures
   adherent through `fux_fifth_species_example`; 85b keeps its 9:3 mark.
   Survey 3.8 records the exemption and its source. CHANGELOG
   Changed entry. Movement: the cleared counterpoints under every gated
   guide carrying `AlwaysMove` (both cantus-firmus guides,
   `first_three_species_melody`, every moving-species melody guide, their
   composites), fitness up and `message_count` down one; nothing else, since
   the triple-meter 6:3 is approached from below.

3. **`PreferLongBeforeShort`, secondary and weak, in `FifthSpeciesMelody`.**
   Class includes `BarSpan`; `strength :weak, because:` Fux calls figure 89
   better rather than 88 wrong. For every bar the voice attacks notes in,
   mark the first three attacks when the first is an undotted quarter on the
   downbeat, the second an undotted quarter on beat 2, the third at least a
   half, and the third's `next_position` is the next downbeat (a tied-forward
   note is one placement reaching past the bar line, so it is exempt by
   construction). A bar entered by a tie has no downbeat attack and is
   exempt, which is why 85b bar 9 does not trip it. Denominator 1. Guide:
   `secondary_items(*MOVING_MELODIC_CRAFT, PreferLongBeforeShort)`, not in
   the shared core, since only a florid line shows the shape. Locale in
   `en.yml` only, without note-value nouns ("Put the longer note before the
   shorter ones unless it ties forward."). Specs: Fux 88a one mark at
   `5:1:000 to 6:1:000`; every other Fux figure adherent; tied forward
   adherent; bar entered by tie adherent; triple-meter bar adherent;
   declares weak. Guide spec include and tier assertions; strings table row;
   `snapshot_english`. Survey 3.14 records adoption with Salzer and
   Schachter and ntoll.org's exception as a disagreement not adopted; 6.3
   marks it landed; 6.4 keeps it soft. CHANGELOG Added entry with 88a's new
   number. Movement, the two fifth-species guides only: `item_count` +1 on
   every gated row; fitness down on 88a; fitness nudged on every gated row
   with any secondary mark, because the secondary tier's units go from 30 to
   31; rows adherent on every secondary (84b) move in `item_count` only.

4. **`Diatonic` exempts the modal accidentals.** Four predicates, each one
   sentence of Salzer and Schachter (pp. 9 to 10 and 20): `raised_seventh_to_tonic?`,
   a sharpened degree 7 whose next note is the tonic a semitone above
   (compare the alteration through the seam the existing `== "#"` uses);
   `raised_sixth_to_raised_seventh?`, a sharpened degree 6 whose next note
   is a sharpened degree 7; `lowered_fourth_in_lydian?`, degree 4 flattened
   when `key_signature.scale_type.name == :lydian`; and
   `lowered_in_descent?`, a flattened degree 6 in dorian or degree 3 in
   mixolydian whose preceding note is higher and whose next note is lower.
   The penultimate exemption is subsumed by the first and dropped. Re-measure
   before writing specs: list every corpus row the predicates clear, and
   confirm the with-errors line `fux_cantus_firmus_examples_with_errors-3-v0`
   keeps its mid-line F-sharps. Specs in `diatonic_spec.rb`: raised seventh
   stepping up mid-line adherent; raised seventh not stepping to the tonic
   marked; raised sixth to raised seventh adherent; raised sixth alone
   marked; lydian B-flat adherent; dorian B-flat in descent adherent and
   in ascent marked; phrygian B-flat marked; Fux 82, 85a, 85b, 86a adherent
   through `fux_fifth_species_example`; the with-errors line still marked by
   name. Survey 3.8 records the four exemptions with the pages. CHANGELOG
   Changed entry. Movement: the cleared voices under every gated guide
   carrying `Diatonic` (all melody guides including `diatonic_melody`, the
   cantus-firmus guides, `first_three_species_melody`, composites), listed
   by class from the capture; any row moving down means a sharpened
   penultimate that is not a raised seventh to the tonic, expected none.

5. **`ConsonantClimax` pinned.** No guideline change. Add contexts to
   `consonant_climax_spec.rb` through `fux_fifth_species_example`: 84a marked
   three times, 87 upper marked twice, each named a liberty in the example
   description. Survey 3.8 records the verdict with Salzer and Schachter
   pp. 8 and 42. No movement; no CHANGELOG entry.

6. **`StepOutOfUnison` exempts the opening note and the tie.** In
   `leaps_following_unisons`, skip a unison whose note is the voice's first
   note, and one whose note is held across the next bar line (a placement
   whose `next_position` is past the next downbeat). Source: Salzer and
   Schachter p. 106, with p. 40 for the opening. The rule stays in the
   shared moving core, since the source states it for every moving species.
   Re-measure: list which of the seven Fux marks remain (expected: the
   interior unisons in 82, 84a, 85a, and 86a unless tied) and pin each
   remaining one in `step_out_of_unison_spec.rb` through
   `fux_fifth_species_example` as a liberty. Specs: opening unison left by
   leap adherent; tied-over unison adherent; interior unison left by leap
   marked; left by step adherent. Survey 3.11 attributes the line to Salzer
   and Schachter and records the two exemptions. CHANGELOG Changed entry.
   Movement: the cleared voices under every gated guide carrying
   `StepOutOfUnison`; the item set is unchanged, so no `snapshot_english`.

7. **Wrap-up.** Fill "Marks on Fux's lines" from the committed fixtures
   with each verdict; record each checkpoint's movement by class from the
   joined captures; reconcile the CHANGELOG against the captures; record
   the re-measured numbers from steps 1, 4, and 6 in the criteria.

### Testing

Guideline behavior in guideline specs, with hand-built voices and
`fux_fifth_species_example`; guide membership and tier in the guide specs
through `items_by_tier`; sentences in `guide_item_strings_spec.rb` and
`english_strings.yml`; species separation in the diagonal, with the new
0.85 assertions; end-to-end grades in the corpus snapshot. Per checkpoint:
capture, join, regenerate, `bundle exec rspec` on the touched specs and the
diagonal, then `bundle exec rubocop -a` and `bundle exec rake` at the 90
percent floor. No stdout assertions.

### Risks

- The run limit was chosen from the source after the dominance share was
  measured, so its grades are not yet known. Figure 73 is two runs of four
  ligature bars and the lower species are single runs, so the shape of the
  result is the same as the share prototype's, but the number is not
  proven until step 1 measures it. If figure 73 stays above 0.85, the plan
  stops and reports; the rule is not reshaped to hit a number.
- The Diatonic exemptions may clear rows beyond the fifth-species figures,
  such as descending B-flats in figures 55 and 73. That is one class under
  one cause and is listed, not avoided.
- Secondary-weight redistribution at step 3 touches nearly every gated
  row on the two fifth-species guides; attribute it as one class, separate
  from 88a's own mark.
- Jeppesen's book sits in the working notes and is easy to reach for. A
  Jeppesen citation may corroborate a reading; it may not be the source of
  a change.
