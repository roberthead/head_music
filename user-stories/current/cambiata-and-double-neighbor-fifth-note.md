<!--
metadata:
  created_at:   2026-11-24T13:21:54-08:00
  activated_at: 2026-11-24T15:36:48-08:00
  planned_at:   2026-11-24T15:39:53-08:00
  finished_at:
  updated_at:   2026-11-24T15:44:16-08:00
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
- The guideline is in every harmony guide that recognizes the double neighbor: third species, first three species, fifth species, and free species (`ThirdSpeciesHarmony`, `FirstThreeSpeciesHarmony`, `FifthSpeciesHarmony`, `FreeSpeciesHarmony`). Second species and triple meter do not recognize the figure and do not get it. It reads completed double neighbors, whose first and last notes are consonant, whatever the note values; the bare pitch shape without those consonances earns no mark
- Specs cover the double neighbor followed by a step that continues, a step that turns back, and a leap, with either neighbor first, and the cambiata followed by the same three, using Salzer & Schachter's Example 3-19 for the double neighbor
- The existing fixtures of published third and fifth species examples keep their primary marks. Any new secondary mark is listed in the story
- The new guideline has a name, an instruction, and a violation message in en and in en_GB, which spells "neighbour". The other locales translate only the note-value guidelines and fall back to English here, as they do for the existing dissonance guidelines
- The pinned corpus snapshot is regenerated. Any row whose fitness falls is listed in the story
- CHANGELOG entry under Unreleased, saying that a double neighbor left by a leap or a turn back now earns a secondary mark, and stating the shift in the pinned corpus
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

- **One rule wherever the double neighbor is recognized: third species, first three species, fifth species, and free species** (Rob, 2026-11-24). The first three species guide was added at planning: its harmony guide uses `FloridDissonanceTreatment`, so it accepts the figure, and a student moving from third species to the mixed exercise should not find the preference dropped. All three already share the cambiata predicate, and the new preference reads pitches, so a fifth note that is a half note or a tied note is judged as a quarter is. Salzer & Schachter's fifth species chapter does not restate the figures; it refers to "the principle … governing the nota cambiata and double neighbor of third species".

- **Where a figure may begin is a separate story** (Rob, 2026-11-24): [dissonance-figure-placement](../backlog/dissonance-figure-placement.md). The gem asks neither where a figure sits in the bar nor what note values carry it. That is a different rule, it would add primary marks in three guides, and it needs its own check against the fixtures. This story adds only a secondary mark.

- **The cambiata's third note must be consonant; that is settled** (Rob, 2026-11-24). Salzer & Schachter say so in third species (p. 62) and twice more for combined species, where a dissonant third note is their example of "an incorrect use of the cambiata". Open Music Theory agrees. Fux allowing a dissonant third note is a liberty with no other source in the tradition, and no fixture uses it.

- **The escape tone gets no rule for the note after it** (Rob, 2026-11-24). It decorates a step and is complete when it lands on a consonant note, which `escape_tone?` already requires. How a line continues after one belongs to the eighteenth-century guide. The double neighbor keeps its precedence there: a turned-back double neighbor is a double neighbor with a secondary mark, not two escape tones.

## Implementation Plan

Add one secondary, weak guideline, `ContinueAfterDoubleNeighbor`, to the four harmony guides that recognize the double neighbor. It asks `DissonanceFigures` for the completed double neighbors in the line and marks each one whose next note does not continue by step in the direction of the figure's last step. The figure predicates do not change. The closest existing feature is `PreferLongBeforeShort`: a weak secondary item sourced from Salzer & Schachter, whose CHANGELOG entry accounts for the shift in the pinned corpus.

The guideline belongs to the harmony guides, not the melody guides, because it must read real figures. A shape-only reading would mark three Fux lines that are not double neighbors: figure 55 bar 8 (A–G–B♭–A, then a fifth down), figure 82 bar 3, and figure 84b bar 3 all have the shape beginning on beat 2 with a dissonant first note. `double_neighbor_figure?` already requires the first and last notes to be consonant, which excludes all three.

### Steps

1. `lib/head_music/style/guideline/dissonance_figures.rb`
   - Public `double_neighbors`: the four notes of each completed double neighbor, in order, from every `start` where `double_neighbor_figure?(start)` holds.
   - No change to `cambiata_dissonance?`, `double_neighbor_member?`, or `escape_tone?`.
2. `lib/head_music/style/guidelines/dissonance_figure_detection.rb`: delegate `double_neighbors`.
3. `lib/head_music/style/guidelines/continue_after_double_neighbor.rb` (new), required from `lib/head_music.rb` beside the other guidelines.
   - Includes `DissonanceFigureDetection`.
   - `strength :weak, because:` Salzer and Schachter call the other continuations less good rather than wrong.
   - `marks`: none without a companion voice. For each double neighbor with a following note, compare the melodic interval from the fourth note to the fifth with the interval from the third to the fourth. Unless it is a step in the same direction, `Mark.for_all` the fourth and fifth notes.
   - A double neighbor that ends the line has no fifth note and earns no mark.
4. Guides: add the guideline to the secondary tier of
   - `lib/head_music/style/guides/third_species_harmony.rb`
   - `lib/head_music/style/guides/first_three_species_harmony.rb`
   - `lib/head_music/style/guides/fifth_species_harmony.rb`
   - `lib/head_music/style/guides/free_species_harmony.rb`
   It is not added to `DIMINUTION_HARMONIC_CRAFT`, which would carry it into second species and triple meter, where the figure is not recognized.
5. Strings
   - `lib/head_music/locales/en.yml`: `continue_after_double_neighbor` with a name, an instruction ("Leave a double neighbor by step, continuing in the direction of its last step.") and a default violation.
   - `lib/head_music/locales/en_GB.yml`: the same entry spelled "neighbour".
   - `spec/head_music/style/guide_item_strings_spec.rb`: a row for the new guideline.
   - `bundle exec rake style:snapshot_english` to regenerate `spec/fixtures/style/english_strings.yml`, and read the diff: only the new strings should appear.
6. `bundle exec rake style:snapshot_corpus_fitness`, and read the diff of `spec/fixtures/style/corpus_fitness.json`. Expected: the item count of every gated row of the changed guides and their composites rises by one, some grades rise slightly because the secondary tier's weight is shared among one more item, and no row falls unless it holds a real double neighbor with a poor continuation. List any row that falls in this story.
7. `CHANGELOG.md`, Added under Unreleased: the guideline, its source, its strength, the guides it joins, and the corpus shift in the form the `PreferLongBeforeShort` entry uses.
8. Add a "BardTheory follow-up" list to this story naming the lessons and dictionary entries to bring into line.

### Data model changes

None.

### Tests

`spec/head_music/style/guidelines/continue_after_double_neighbor_spec.rb` (new), with ABC lines over a held cantus firmus note, in the harness the third species dissonance spec uses:

| Line | Expectation |
| --- | --- |
| upper neighbor first, then a step on in the direction of the last step | no mark |
| lower neighbor first, then a step on | no mark |
| upper neighbor first, then a step that turns back | one mark, on the fourth and fifth notes |
| lower neighbor first, then a step that turns back | one mark |
| a leap after the figure | one mark |
| the fourth note repeated | one mark |
| the figure ends the line | no mark |
| the double neighbor shape with a dissonant first note (Fux figure 55 bar 8) | no mark: it is not a double neighbor |
| no companion voice | no mark |
| Salzer & Schachter Example 3-19 a, b, c, d | none, none, one, one |
| the figure in mixed note values, the fifth note a half note | judged as in quarters |

Each negative line fails for one reason only: write the harmonic intervals beside it and confirm that every other clause holds.

`spec/head_music/style/guideline/dissonance_figures_spec.rb`:

- `double_neighbors` returns the four notes of a completed figure, and nothing for a line without one or for a figure whose closing note is dissonant.
- The cambiata followed by a step on, a step that turns back, and a leap: true, false, false for the dissonant note. Add whichever of the three the file lacks.

Guide specs (`third_species_harmony_spec.rb`, `first_three_species_harmony_spec.rb`, `fifth_species_harmony_spec.rb`, `free_species_harmony_spec.rb`): the guideline is in the secondary tier. The second species and triple-meter harmony specs: it is absent.

The Fux fixtures: the existing diagonal and corpus specs pass unchanged apart from the regenerated snapshot, which shows that no primary mark moved.

Check the new examples by deleting each clause of the guideline in turn; each deletion should fail an example.

### Risks

- **Example 3-19 has to be transcribed from the scan.** It is on printed p. 62 (PDF p. 79), with the figure in a C clef. Render at 300 dpi and read the clef and pitches twice before pinning; a misread clef moves every note.
- **Free species.** `FreeDissonanceTreatment` builds its own figures for either voice and calls the companion `cantus_firmus`. Confirm that the mixin's `dissonant_with_cantus?` gives the same answer for the graded voice there, and pin it with a spec in which the lower voice carries the double neighbor.
- **The snapshot is a decision, not a refactor.** Regenerating it changes hundreds of rows by item count. Read the diff for any fall in fitness before accepting it.
- **A rest after the figure does not break it**, as with the other figure predicates. Whether a rest should break a figure is recorded on the eighteenth-century guide story and is not settled here.
- **RubyCritic.** The new guideline is small, but `rake validate` fails on a D or F file, so run it before committing.
