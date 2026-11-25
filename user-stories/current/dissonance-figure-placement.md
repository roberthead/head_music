<!--
metadata:
  created_at:   2026-11-24T15:35:04-08:00
  activated_at: 2026-11-24T18:42:00-08:00
  planned_at:   2026-11-24T19:15:02-08:00
  finished_at:
  updated_at:   2026-11-25T13:29:59-08:00
-->

# Story: Place the Cambiata and Double Neighbor in the Bar

## Summary

AS a consumer of the gem grading third and fifth species counterpoint (BardTheory's exercises)
I WANT the nota cambiata and the double neighbor to be recognized only where the bar and the note values let them sound as those figures
SO THAT a leap from a dissonance is not excused by a shape that begins on the wrong beat or rests on a long dissonant note

## Acceptance Criteria

- **Placement, primary.** The dissonance guidelines (`ThirdSpeciesDissonanceTreatment`, `FloridDissonanceTreatment`, `FreeDissonanceTreatment`) recognize a double neighbor only where it begins on a downbeat, and a nota cambiata only where it begins on an accented beat. A figure placed elsewhere excuses nothing: each of its dissonant notes that is not a passing or neighbor tone in its own right earns the guideline's existing mark. No new string key is needed for this
- Placement is read from where the figure's dissonant notes fall, not from where its first note is attacked, so a first note tied over a barline does not move the figure. Fux's figure 87a, whose first note is attacked on beat 3 and tied into the bar that holds the dissonance on beat 2, stays a cambiata begun on a downbeat and earns no mark of either kind
- **Placement, secondary.** A new weak secondary guideline prefers the cambiata begun on a downbeat: a cambiata begun on the bar's other accented beat, whose dissonance is treated, earns one mark. It is in every harmony guide that recognizes the cambiata: third species, first three species, fifth species, and free species. It has a name, an instruction, and a violation message in en, and in en_GB wherever the spelling differs
- **Note values.** In `FloridDissonanceTreatment` and `FreeDissonanceTreatment`, the dissonant notes of a cambiata and of a double neighbor must be quarter notes. A half note or an eighth in that place leaves the dissonance untreated. The figure's consonant notes may take any value. `ThirdSpeciesDissonanceTreatment` reads placement only and no note values
- **The half note.** In the same two guidelines, a dissonance attacked as a half note or longer is treated only as a passing tone. A half-note neighbor tone, which the second species guide already marks, is marked in fifth species, first three species, and free species too
- Free species follows fifth species in all of the above, read in whichever voice carries the figure. A dissonance the other voice explains with a figure of its own is still unmarked
- **Messages.** The instruction and violation of the three dissonance guidelines say what they now ask: where each figure begins, that a dissonant half note may only pass, and, in the florid guideline, that a neighbor tone is accepted. Each guideline keeps one violation message and its existing keys, in en and en_GB
- Rhythm is read from positions and the meter, not from beat numbers
- Specs cover the double neighbor beginning on every beat of a 4/4 bar, with both neighbors dissonant and with one; the cambiata beginning on beats 1, 2, and 3 in all three guidelines, and on beat 4 in free species only, against a moving voice; a figure whose dissonant note is a half note and one whose dissonant note is an eighth; a half-note neighbor tone against a half-note passing tone; figure 87a's long first note; and a figure in the lower voice of a free species pair
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

- **A cambiata from beat 4 is specified in free species only** (Rob, 2026-11-24, at planning). The figure's second and fifth notes are the same pitch (C–B–G–A–B). Begun on beat 4, both lie in one bar over one cantus firmus note, so a dissonant second note makes the fifth dissonant and the shape is no cambiata. It exists only against a moving voice, where its dissonance is attacked on a downbeat and is marked already.

- **Third species reads placement only** (Rob, 2026-11-24, at planning). `ThirdSpeciesDissonanceTreatment` still accepts a double neighbor in eighths from the downbeat (`e/ f/ d/ e/ c2` over C) and a cambiata whose dissonance is a half note (`c'2 b2 | g a b2`). The third species melody guide marks both rhythms, and the harmony guides leave rhythm to the melody guides.

- **The existing messages are reworded in this story** (Rob, 2026-11-24, at planning). The florid violation, "Treat each dissonance as a passing tone, cambiata, or double neighbor on a weak beat.", leaves out the neighbor tone and would be the sentence a student reads beside a marked half-note neighbor. One message per guideline, no new keys.

## Implementation Plan

Planned on 2026-11-24 at `f68b35b0`.

`DissonanceFigures` keeps reading pitch shape and consonance. A new module, `HeadMusic::Style::Guideline::FigurePlacement`, reads where a figure's notes fall from their positions and the meter, and the three dissonance guidelines ask it before they accept a cambiata or a double neighbor. The florid and free guidelines also ask it for note values. A new weak secondary guideline, `BeginCambiataOnDownbeat`, follows the pattern of `ContinueAfterDoubleNeighbor`, the closest existing feature.

### How placement is read

A figure's beginning is found from a dissonant note by forward arithmetic: the **accented onset** of a note is the strong beat in its bar from which one of the note's own value reaches the note's position, or nil. In 4/4 a quarter note on beat 2 has the downbeat as its onset, one on beat 4 has beat 3, and one on beat 3 has none. A strong beat is `position.strong?`, so cut time reads the same way with no beat numbers.

- **Cambiata.** Placed when its dissonant second note has an accented onset. Begun on the downbeat when that onset is the downbeat.
- **Double neighbor.** Placed when its first neighbor's accented onset is the downbeat and its closing note is attacked in the same bar.
- The first note of either figure is never asked where it was attacked, which is what keeps figure 87a.

Subtracting from a position is not an option. `position.advance(subticks:)` with a negative number does not carry across a barline: a whole note on 3:1 gives `3:-3:000`, which still answers `strength` with 60.

### Measured before planning

A throwaway prototype of the rules below was loaded over the three guidelines, outside the repository.

- The eleven lines of the research table and seven more, in 4/4 and in 2/2, earn the marks the Decisions call for. `g e f d | e` is marked on F and D, `e2 f d | e` on F and D, `e f d2 | e` on F and D in third species (the return is in the next bar), `c'2 b2 | g a b2` on B in the florid and free guidelines only, `e2 f2 | e` on F in the florid and free guidelines only, and `e2 f2 | g` and the 87a shape on nothing. The marks in 2/2 are the marks in 4/4.
- Over the pinned corpus, 0 of 5,808 rows differ from `spec/fixtures/style/corpus_fitness.json`. With cambiata recognition switched off in the same prototype, twelve rows fall, all of them Fux's figures 55 and 87a, so the prototype was live.

### Steps

Four commits, one cause each, with the corpus snapshot regenerated and read after each of the first three.

1. **Placement.**
   - `lib/head_music/style/guideline/dissonance_figures.rb`: add `cambiatas`, the five notes of each cambiata whose second note is dissonant, and `double_neighbors_with(note)`, the double neighbors in which the note is a neighbor. `cambiata_dissonance?`, `double_neighbor_member?`, and `escape_tone?` do not change.
   - `lib/head_music/style/guideline/figure_placement.rb` (new), required from `lib/head_music.rb` after `dissonance_figures`: `accented_onset(note)`, `cambiata_placed?(dissonance)`, `cambiata_from_downbeat?(dissonance)`, `double_neighbor_placed?(figure)`, and `leaping_figure?(figures, note, quarter_dissonances:)`, which is true when the note is the dissonance of a placed cambiata or a neighbor of a placed double neighbor. It takes the figures as an argument so the free guideline can ask about either voice.
   - `lib/head_music/style/guidelines/third_species_dissonance_treatment.rb`: `recognized_figure?` becomes `super || neighbor_tone?(note) || leaping_figure?(dissonance_figures, note, quarter_dissonances: false)`.
   - `lib/head_music/style/guidelines/florid_dissonance_treatment.rb` and `free_dissonance_treatment.rb`: the same call in place of `cambiata_dissonance? || double_neighbor_member?`, still with `quarter_dissonances: false` in this commit.
   - `bundle exec rake style:snapshot_corpus_fitness`. Expected: no diff.
2. **Note values**, in the florid and free guidelines only.
   - `figure_placement.rb`: `quarter_note?(note)`, an untied quarter, and `half_note_or_longer?(note)`, by total duration. With `quarter_dissonances: true` a cambiata needs its dissonance to be a quarter note, and a double neighbor needs every dissonant neighbor to be one.
   - `dissonance_figures.rb`: `passing_run?(note)`, the one-direction half of `consonant_run?`, which is then written as `passing_run?` or a run that returns to its first pitch.
   - `florid_dissonance_treatment.rb`: after the downbeat test, `return passing_tone?(note) if half_note_or_longer?(note)`, and `quarter_dissonances: true`.
   - `free_dissonance_treatment.rb`: `return figures.passing_run?(note) if half_note_or_longer?(note)` first in `explained_by_figure?`, and `quarter_dissonances: true`. The rule reaches only a note that attacks the dissonance; a half note that is consonant when attacked and dissonant later is the suspension rule's, as now.
   - Snapshot again. Expected: no diff.
3. **The secondary guideline.**
   - `lib/head_music/style/guidelines/begin_cambiata_on_downbeat.rb` (new), required beside `continue_after_double_neighbor`. Includes `DissonanceFigureDetection` and `FigurePlacement`. `strength :weak, because:` Salzer and Schachter say only that the first quarter is in general the better beginning. One `Mark.for_all` over the five notes of each cambiata whose dissonance is a quarter note with an accented onset that is not the downbeat. No companion-voice guard: with no companion nothing is dissonant, so `cambiatas` is empty.
   - `dissonance_figure_detection.rb`: delegate `cambiatas`.
   - Guides, secondary tier, beside `ContinueAfterDoubleNeighbor`: `third_species_harmony.rb`, `first_three_species_harmony.rb`, `fifth_species_harmony.rb`, `free_species_harmony.rb`. Not `DIMINUTION_HARMONIC_CRAFT`, which reaches second species and triple meter.
   - `lib/head_music/locales/en.yml`: `begin_cambiata_on_downbeat` with a name ("Cambiata from the downbeat"), an instruction ("Begin a nota cambiata on the downbeat rather than on the bar's other accented beat."), and a default violation ("Begin the nota cambiata on the downbeat."). No en_GB entry: no word in the three is spelled differently.
   - `spec/head_music/style/guide_item_strings_spec.rb`: a row. `bundle exec rake style:snapshot_english`, and read the diff: only the new strings.
   - Snapshot the corpus. Expected, as with `ContinueAfterDoubleNeighbor`: the 576 gated rows of the four harmony guides and their four composites gain an item, some rise slightly, and none falls, since the corpus's two cambiatas both begin on a downbeat. Compute the counts and the largest rise from the diff.
4. **Messages.** Reword the three guidelines' strings in `lib/head_music/locales/en.yml` and `en_GB.yml` (neighbour, crotchet, minim), update their rows in `spec/head_music/style/guide_item_strings_spec.rb`, and regenerate `spec/fixtures/style/english_strings.yml`. No other locale carries these keys. The wording below is a draft for Rob to edit before the commit:

   | Guideline | String | Draft |
   | --- | --- | --- |
   | Third species | instruction | Reach every dissonance as a passing tone, a neighbor tone, a cambiata begun on an accented beat, or a double neighbor begun on the downbeat. |
   | Third species | violation | Treat each dissonance as a passing tone, a neighbor tone, a cambiata begun on an accented beat, or a double neighbor begun on the downbeat. |
   | Florid | instruction | Off the downbeat, reach every dissonance as a passing tone, a neighbor tone shorter than a half note, or a quarter note in a cambiata begun on an accented beat or in a double neighbor begun on the downbeat. |
   | Florid | violation | Treat each dissonance as a passing tone, a neighbor tone shorter than a half note, or a quarter note in a cambiata begun on an accented beat or in a double neighbor begun on the downbeat. |
   | Free | instruction | Explain every dissonance between the two voices: in either voice as a passing tone, a neighbor tone shorter than a half note, or a quarter note in a cambiata begun on an accented beat or in a double neighbor begun on the downbeat; or as a suspension prepared and resolved down by step. Attack no dissonance on a downbeat. |
   | Free | violation | unchanged: it says "a figure in either voice" and names none |

5. `CHANGELOG.md` under Unreleased, written from the captured diffs: a Changed entry naming each shape that passed and is now marked (the double neighbor off the downbeat, the cambiata begun on a weak beat, either figure with a half-note or eighth-note dissonance in the florid and free guidelines, the half-note neighbor tone in fifth species, first three species, and free species), the reworded messages, an Added entry for the guideline and the new `DissonanceFigures` methods, and the corpus shift.
6. Record in this story: Implementation Notes with the measuring commit beside each number, and a "BardTheory follow-up" list. Start from `grep -rl "cambiata\|double neighbor\|neighbor tone" ../bardtheory/db/seeds`: the dictionary entries (`d.yml`, `n.yml`, `t.yml`), the `the-cambiata`, `third-species-introduction`, and `florid-counterpoint` lessons, the two species guidelines lessons, and the third species, fifth species, combined, and free species exercises that name the figures.
7. `bundle exec rubocop -a`, then `bundle exec rake validate`, judged by its exit status.

### Data model changes

None.

### Tests

ABC lines over a held cantus firmus note, as in `continue_after_double_neighbor_spec.rb`. The harmonic intervals are written beside each negative line, and each breaks one clause.

`spec/support/dissonance_figure_placement.rb` (new): a shared example group run by the third species, florid, and free specs.

| Line | Expectation |
| --- | --- |
| double neighbor from beat 1, both neighbors dissonant; and with one | no mark |
| double neighbor from beat 2, both dissonant | both neighbors marked |
| double neighbor from beat 2, one dissonant | one mark |
| double neighbor from beat 3 and from beat 4, the downbeat neighbor consonant | the other neighbor marked |
| first neighbor on beat 2, second a half note, return on the next downbeat | marked: only the same-bar clause fails |
| cambiata from beat 1 | no mark |
| cambiata from beat 2 | the dissonance marked |
| cambiata from beat 3 | no mark |
| figure 87a's shape, first note attacked on beat 3 and tied over | no mark |
| one accepted and one refused line of each figure in 2/2 | as in 4/4 |

`florid_dissonance_treatment_spec.rb` and `free_dissonance_treatment_spec.rb`:

- a double neighbor from beat 3 whose downbeat neighbor is dissonant: both marked;
- `c'2 b2 | g a b2`, a cambiata with a half-note dissonance: marked here, and unmarked in the third species spec, so only the value clause fails;
- `e/ f/ d/ e/ c2`, a double neighbor in eighths from the downbeat: both neighbors marked;
- a double neighbor with one dissonant neighbor a quarter and the other an eighth: both marked;
- a consonant first note of any length, and a consonant neighbor: no mark;
- `e2 f2 | e`, marked, against `e2 f2 | g`, unmarked; a quarter-note neighbor, unmarked.

`free_dissonance_treatment_spec.rb` also: each figure in the lower voice of a pair, placed and misplaced; a cambiata from beat 4 against a moving voice, marked on the downbeat; and a leap in one voice against a placed cambiata in the other, unmarked.

`spec/head_music/style/guidelines/begin_cambiata_on_downbeat_spec.rb` (new): from the downbeat, none; from the other accented beat, one mark over five notes; from a weak beat, none, since the primary guideline marks it; figure 87a's shape, none; the shape with a consonant second note, none; a half-note dissonance, none; 2/2; the lower voice of a free pair; no companion, none.

`spec/head_music/style/guideline/dissonance_figures_spec.rb`: `cambiatas`, with and without a dissonant second note; `double_neighbors_with`; `passing_run?` against a neighbor run.

`third_species_dissonance_treatment_spec.rb` also: `e/ f/ d/ e/ c2` and `c'2 b2 | g a b2`, both unmarked, since third species reads no note values.

Guide specs: the guideline is in the secondary tier of the four guides and absent from second species and triple meter; `base_spec.rb`'s item lists and `guide_item_strings_spec.rb` gain it. `guide_item_strings_spec.rb` also pins the reworded violations.

The Fux fixture specs and `guide_corpus_fitness_spec.rb` pass against the regenerated snapshot.

Checked by deletion: remove each clause in turn (the accented onset, the downbeat for the double neighbor, the same bar, the quarter note, the half-note rule in each guideline, and the dissonant second note in `cambiatas`) and record the example that fails beside each.

### Risks and readings

- **A cambiata cannot begin on beat 4 against a whole-note cantus firmus.** Its second and fifth notes are the same pitch (C–B–G–A–B), and from beat 4 both lie in one bar over one cantus note, so a dissonant second note makes the fifth dissonant and the shape is no cambiata. The placement exists only against a moving voice, where its dissonance is attacked on a downbeat and is marked already. The specs criterion is amended to say so.
- **Third species reads no note values.** In `ThirdSpeciesDissonanceTreatment` a double neighbor in eighths from the downbeat and a cambiata with a half-note dissonance stay unmarked, as the prototype showed. The harmony guides leave rhythm to the melody guides (`species_harmony.rb`). Rob chose to leave it; the third species spec pins both lines as unmarked.
- **The secondary guideline asks for a quarter-note dissonance in every guide**, so it never adds a mark to a figure the primary guideline has refused for its note value.
- **One eighth or half note among two dissonant neighbors unseats the whole double neighbor** (Claude's reading). The quarter-note neighbor then leaps from or to a dissonance with no figure to excuse it, as in the Decision on misplaced figures.
- **Meters other than 4/4 and 2/2.** In 3/2 the meter calls only the downbeat strong, so a cambiata begun on the second or third half-note beat would be marked. No fixture is in 3/2. Pin 4/4 and 2/2 and record the rest.
- **A rest inside a figure does not break it**, as before. Placement is read from the dissonant note alone, so a rest before it changes nothing. That question stays with the eighteenth-century guide story.
- **The reworded messages are long.** The florid violation grows from 15 words to 36. BardTheory shows it beside a mark, so check how it reads there, and shorten the draft if Rob prefers a general sentence.
- **RubyCritic.** `free_dissonance_treatment.rb` is already 132 lines. Keep the new logic in `FigurePlacement` and check the file's grade before committing.
- **Release.** v24.0.0 is the last tag, and shapes it passed are marked after this story. Whether that makes the next release major is settled at release.

## Implementation Notes

Implemented on 2026-11-25. Each number carries the commit it was measured at.

### Commits

| Commit | Change |
| --- | --- |
| `d2c3167a` | Placement: `FigurePlacement`, `DissonanceFigures#cambiatas` and `#double_neighbors_with`, the three guidelines |
| `6edffe76` | Note values in the florid and free guidelines, and `#passing_run?` |
| `0a55d7b7` | `BeginCambiataOnDownbeat` in four guides, with its strings |
| `8b8fec0d` | Two examples that isolate a clause each |
| `5d71eac0` | `ConsonantRun`, extracted from `DissonanceFigures` |
| `14684f6e` | The third species instruction and violation |

### Measured

- **The probe table.** The plan's eighteen lines, in 4/4 and 2/2, against the three guidelines, captured at `cb36c943` before the first edit and again after each step. At `d2c3167a` the misplaced figures gain the marks the plan lists and nothing else moves. At `6edffe76` three lines gain marks in the florid and free guidelines only: the cambiata with a half-note dissonance, the double neighbor in eighths, and the half-note neighbor tone. The marks in 2/2 are the marks in 4/4 at every step.
- **The pinned corpus.** Regenerated at `d2c3167a` and at `6edffe76`: 0 of 5,808 rows differ. At `0a55d7b7`, 576 rows gain an item, the gated rows of `third_species_harmony`, `first_three_species_harmony`, `fifth_species_harmony`, `free_species_harmony`, and their four composites, 72 each. 224 of them rise, 28 in each guide, by at most 0.008920 (`third_species_triple_meter_examples-0-v1` under `third_species_harmony`, 0.839442 to 0.848362). 352 move in item count only. No row's fitness falls, and no row's message count or adherence changes, so no voice in the corpus is marked by the new guideline.
- **Fixtures.** The Fux fixture specs pass unchanged at every commit. No mark moved, primary or secondary.
- **Suite.** `rake validate` at `8b8fec0d`: 19,411 examples, 0 failures, no lint offenses, no vulnerabilities, and RubyCritic exit 1 for one file graded D. After `5d71eac0`, `rake rubycritic` exits 0 with no file below C.

### Checked by deletion

At `8b8fec0d`, each clause removed in turn against `spec/head_music/style/guidelines` and `spec/head_music/style/guideline`.

| Clause removed | Examples that fail |
| --- | --- |
| The accented onset, so a cambiata is placed anywhere | 8: "a nota cambiata is refused from beat 2" and its cut-time twin in all three guidelines, and the free guideline's lower-voice and leap-against-a-cambiata examples |
| The downbeat for the double neighbor | 1: third species, "refuses a double neighbor in eighth notes begun on beat 3" |
| The same bar for the double neighbor | 1: third species, "is refused where it returns in the next bar" |
| The quarter note for the cambiata | 2: "is refused where its dissonance is an eighth note", florid and free |
| The quarter notes for the double neighbor | 4: "is refused in eighth notes" and "where one dissonant neighbor is an eighth", florid and free |
| The half-note rule, florid | 1: "a dissonant half note is marked as a neighbor tone" |
| The half-note rule, free | 1: the same example in the free spec |
| The dissonant second note in `cambiatas` | 3: `#cambiatas` with a consonant second note, and two in the secondary guideline's spec |
| The secondary guideline's quarter note | 1: "a cambiata begun on beat 3 whose dissonance is an eighth note" |
| The secondary guideline's placement | 1: "the shape begun on beat 2" |
| The secondary guideline's downbeat | 3: the downbeat cambiata in 4/4 and 2/2, and figure 87a's shape |

Two clauses could not fail on the lines the plan gave, and each has a line of its own in `8b8fec0d`:

- **The double neighbor's downbeat.** In quarter notes the same-bar clause already refuses every double neighbor that begins after beat 3, since its return falls in the next bar. Only a figure in eighths begins after beat 3 and returns within the bar, and only third species accepts eighths, so the example is `e2 e/ f/ d/ e/ | c` there.
- **The cambiata's quarter note.** `c'2 b2 | g a b2` is refused by the half-note rule before the quarter-note clause is asked. A cambiata with an eighth-note dissonance, `e2 c'/ b/ g | a b3` over C and D, is refused by the quarter-note clause alone.

### Departures from the plan

- **`ConsonantRun`.** The plan watched `free_dissonance_treatment.rb` for RubyCritic and the file that fell was `dissonance_figures.rb`: flog 172.1 at `cb36c943`, 209.4 at `8b8fec0d` (D, cost 8.29), with `rake validate` exiting 1. The stepwise run of any length, which only the free guideline reads, moved to `HeadMusic::Style::Guideline::ConsonantRun` at `5d71eac0`: `dissonance_figures.rb` is C at 6.37 and `consonant_run.rb` B at 3.84. `consonant_run?` and `passing_run?` answer as before. `free_dissonance_treatment.rb` is C at 5.17.
- **`FreeDissonanceTreatment#after_dotted_quarter?` is gone.** Once a figure's dissonance must be a quarter note, no eighth can be one, so the rule for the eighth after a dotted quarter answers nothing the general rule does not. Its spec, "with a dissonant eighth after a dotted quarter", still passes.
- **`DissonanceFigures#dissonant?` and `#dissonant_among`** are public, beyond the two methods the plan listed. The note-value check has to tell a double neighbor's dissonant neighbors from its consonant ones.
- **The secondary guideline's half-note example is vacuous for its quarter-note clause.** An accented onset is read within the note's bar, so a half-note dissonance has the downbeat as its onset or none. The spec keeps the plan's line and adds the eighth-note line that the clause is for.
- **`guide_strings_spec.rb`'s registry canary** went from 77 items to 78.

### Open

- **`ContinueAfterDoubleNeighbor` still reads a double neighbor the dissonance guideline has refused.** `g e f d | e | g` over C, C, E earns two primary marks for F and D and a secondary mark for the leap that follows. Salzer and Schachter say a double neighbor off the downbeat "will cease to sound like the decoration of a single tone", which argues that the continuation advice no longer applies. Checked at `5d71eac0`; not changed, since no criterion asks for it and it is a different guideline's rule.
- **Meters other than 4/4 and 2/2** are not pinned, as the plan said.
- **The release bump** is still to be settled.

## BardTheory follow-up

Found with `grep -rli "cambiata\|double neighbor\|neighbor tone" ../bardtheory/db/seeds` on 2026-11-25.

- **Dictionary, `d.yml`, double neighbor.** Says the leap "is permitted even when both neighbors are dissonant" and nothing about where the figure begins. Add: it begins on the downbeat, and its neighbors are quarter notes.
- **Dictionary, `n.yml`, nota cambiata.** Add: it begins on an accented beat, better the downbeat, and its dissonance is a quarter note.
- **Dictionary, `n.yml`, neighbor tone.** Add: a dissonant half note may only pass, so a dissonant neighbor is a quarter note or shorter.
- **Dictionary, `t.yml`, third species.** Names the figures; check the sentence against the placement rule.
- **Lesson `the-cambiata`.** Has "When the figure starts on a downbeat, its fifth note is the downbeat of the next bar." Add the accented-beat rule, the preference for the downbeat with Salzer and Schachter's reason, and figure 87a's tied first note.
- **Lessons `third-species-introduction` and `third-species-guidelines`.** Both introduce the double neighbor by shape alone. Add that it begins on the downbeat.
- **Lesson `fifth-species-guidelines`.** Its neighbor tone bullet says "a weak part of the beat" and its cambiata bullet "permitted in quarter-note passages". Add the half-note rule and the quarter-note dissonance for both figures.
- **Lessons `florid-counterpoint` and `combining-first-second-third-species`.** The second says beats 2, 3, and 4 "may include passing tones and neighbor tones"; a half note in that guide may now only pass.
- **Lesson `the-neighbor-tone`.** Written for triple meter; add a pointer to the half-note rule where the mixed species are introduced.
- **Exercises.** `counterpoint-third-species-intro`, `third-species-davis-g-major-2`, `third-species-schoenberg-a-major`, and `third-species-schoenberg-eb-major` say dissonant weak beats "must be passing tones, neighbor tones, or part of a nota cambiata". `combined-123-davis-c-major-1`, `fifth-species-schoenberg-eb-major`, `free-species-c-major`, and `free-species-d-dorian` name neighbor tones on weak beats. Check each sentence, and each exercise's model answer, against the new marks.
- **The new guideline.** `BeginCambiataOnDownbeat` appears in the third species, first three species, fifth species, and free species exercises with its own name and message.
- **Displayed messages.** The third species violation is reworded and longer; check how it reads beside a mark.
