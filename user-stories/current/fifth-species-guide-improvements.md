<!--
metadata:
  created_at:   2026-09-22T20:42:44-07:00
  activated_at: 2026-09-22T21:02:07-07:00
  planned_at:   2026-09-23T09:57:17-07:00
  finished_at:
  updated_at:   2026-09-23T09:57:17-07:00
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
they may corroborate a reading but cannot authorize a change here.

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
  florid and an empty bar left out. It marks every bar of the dominant
  texture when that texture holds more than one half of the bars from the
  voice's first bar to the bar before its last, with no denominator, the
  shape `SustainAcrossBarlines` uses; florid and empty bars are never the
  candidate. The principle is the survey's universal "no single species
  should dominate", with Salzer and Schachter's balance of textures behind
  it. Hansen Media's and Girton's consecutive-run measures are rejected by
  name for this guideline. The discount is bounded by the primary tier and
  the item's cost grows with each dominant bar; any threshold between 0.27
  and 0.80 grades the current corpus identically, and one half is chosen for
  its plain meaning.
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
- **The composite diagonal widens on the merits.** Measured on the
  prototype: Fux's fourth-species figure 73 falls from 0.929 to 0.826 on the
  `fifth_species` composite and to 0.696 on `fifth_species_melody`; figure
  55 to 0.795 and figure 33 to 0.815 on the composite; the first-species
  fixtures to 0.625 or below. The diagonal spec asserts every other species
  at 0.85 or below on the composite. All twelve Fux fifth-species fixtures
  are adherent to the new guideline. The liberties map gains no entry;
  85b's entry stays as a recorded verdict, and the spec asserts each named
  liberty is present in the fixtures and marked on that guide.
- **`AlwaysMove` knows the anticipation where the tradition sanctions it.**
  The shape is an unaccented quarter, approached by step from above, that
  repeats as the following accented note; Fux writes it in 86a, 87 upper,
  87a, and 88b, and Jeppesen names it (corroboration only). The species
  tradition's one sanction found so far is Ars Nova's: "in upper parts you
  can repeat a pitch as many as three times successively if necessary",
  while "avoid repeating a pitch in the lowest voice". The exemption is
  implemented for the shape above and no wider, and for the bass voice only
  if the plan's source trace in Salzer and Schachter or Open Music Theory
  finds a sanction; otherwise 87a and 88b keep their marks as liberties and
  are listed. A repeated half, or a quarter approached from below or by
  leap, stays marked, so 85b bar 9 keeps its mark. Every voice the change
  clears moves under every guide carrying `AlwaysMove`; no other voice moves.
- **Fux's N.B. is marked.** `PreferLongBeforeShort`, secondary and weak in
  `FifthSpeciesMelody`, marks a bar that opens with two quarters and closes
  with a longer note that does not tie forward, the shape Fux flags in figure
  88 bar 5 (`B A G2`) and answers with figure 89. Salzer and Schachter are
  the source, already in the survey: the half after two short notes
  "constitutes a static point in the discourse", and a half suspended into
  the next bar is the exception. ntoll.org's exception, that the shape is
  acceptable after a bar ending in two quarters, is recorded as a
  disagreement and not adopted, because Fux's N.B. sits on exactly such a
  bar. It is weak because Fux calls figure 89 better rather than 88 wrong.
  Figure 88a is the only corpus voice marked; nineteen Fux bars have the
  shape tied forward and are exempt. Adding a secondary item changes the
  item count on every gated row of the two fifth-species guides and
  redistributes secondary weight, so every voice with a secondary mark moves
  by a few thousandths, listed as one class.
- **`Diatonic` changes only on a species-tradition source.** The marks at
  issue are 86a 11:1, a raised seventh stepping up to the final mid-line;
  82 5:3, a dorian B-flat in a descending figure; and the five lydian
  B-flats in 85a and 85b. The surveys sanction the raised seventh only at
  the cadence, and say nothing of B-flat. The plan's source trace looks in
  Salzer and Schachter and Open Music Theory; an exemption is written only
  for a shape a source names, with the with-errors corpus lines that
  `Diatonic` exists to catch still failing it. Every mark without a source
  stays as a Fux liberty, pinned in `diatonic_spec.rb` so the verdict is
  recorded. Jeppesen's account of the same accidentals is corroboration,
  not authority.
- **`ConsonantClimax` keeps both marks as liberties.** Salzer and Schachter
  hold one climax, never repeated, which is stricter than the current rule,
  so no species-tradition source clears either shape. 84a's peak, the
  phrygian final at the top of the line's cadence, and 87 upper's peak,
  re-approached by leap within one bar, keep their marks. Both are pinned in
  `consonant_climax_spec.rb` as recorded verdicts. The guideline is
  unchanged.
- **`StepOutOfUnison` leaves `FifthSpeciesMelody`.** It marks seven of the
  twelve Fux figures: the opening unison left by leap in 83 and 86b, and
  internal unisons left by leap in 82 (twice), 84a, 85a, and 86a. The
  survey's line "step out of unisons" is unattributed and repeats equally
  unattributed lines in the second- and third-species surveys; Ars Nova
  says the unison "is acceptable at the beginning or end of the composition,
  and in passing within it if not accented", with no rule for leaving it.
  Unless the plan's trace finds a species-tradition source that applies the
  rule to florid lines, the guideline is removed for fifth species through
  the guide's `except:` seam, the seven marks vanish, and removing a
  secondary item moves every voice with a secondary mark by a few
  thousandths, listed as one class. If a source applies it, it stays and
  each mark is settled.
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
  guideline measures dominance share rather than consecutive identical bars;
  it is strong; `StepOutOfUnison` is removed from fifth species if no source
  applies it there; sources for the shared guides must come from the
  species tradition, so Jeppesen is corroboration only; his fifth-species
  examples and the dotted-half allowance they would need are moved to the
  sixteenth-century story, where his book is the primary source; the
  mixture guideline is calibrated on Fux's twelve lines and the survey's
  agreement, with Salzer and Schachter's fifth-species examples the right
  second author if the book comes to hand.
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
  not any one species, and count in the denominator but never as the
  candidate. Counting them as a texture would mark Fux's 87 upper, which is
  82 percent florid.
- Fux's N.B. on figure 88, in Mann's translation, is the one calibration
  point where the author marks his own line. A guideline that agrees with him
  there is evidence the guide is calibrated, not that it is dogmatic.
- Ars Nova's fifth-species instructions (in the survey's source list) also
  say "Dotted notes will not be used", which is why the dotted half stays
  marked here and belongs to the sixteenth-century story with Jeppesen.
- The survey in `references/fifth-species-counterpoint.md` section 6.3 lists
  `RhythmicVariety` and `PreferLongBeforeShort` as proposed enhancements;
  `RhythmicVariety` lands as `MixSpeciesTextures` with the share measure and
  `PreferLongBeforeShort` lands by name.

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
   `BarSpan`; `MAXIMUM_TEXTURE_SHARE = 0.5`, readable through
   `options.fetch(:maximum_texture_share)` as `SustainAcrossBarlines` exposes
   its ratio. Span is `body_bar_numbers`: the first bar is texture the author
   chose (Fux's half-rest entry is half-note texture) and the final bar is a
   whole note by the other primary's rule. Classify a bar with
   `held = voice.note_at(downbeat)` and a tail when `held.position < downbeat`
   (a tie across the bar line is one placement): no attacks and no tail is
   `empty`, excluded from numerator and denominator (it is
   `NoRestsAfterNote`'s fault, and letting it dilute dominance would reward
   rests); a tail through the whole bar with no attacks is `whole`; a tail
   ending at beat 3 followed only by halves is `ligature`; any other tail is
   `florid`; with no tail, all wholes `whole`, all undotted halves `half`,
   all quarters or eighths `quarter`, anything else including a dotted half
   `florid`. Rests never appear in `notes`, so `z2 A2-` is a half bar; triple
   meter needs no special case. Dominance: the single-species texture with the
   largest count when `count / body bars > 1/2` (5 of 10 passes, 6 of 11
   marks). Marks: every bar of the dominant texture once, via `mark_bar`;
   denominator 1, so cost is `0.618^n` and grows with the dominant bars; as
   one of two strong primaries the item holds 0.309 of the melody grade,
   which bounds the discount. Strength default; the class comment carries the
   answer to `MostlyConjunct`'s precedent. Guide:
   `primary_items(AllowFifthSpeciesRhythmicValues, MixSpeciesTextures)`.
   Delete `mixed_rhythmic_values.rb`, its spec, its require, and its `en.yml`
   entry. Locale: `guidelines.mix_species_textures` in `en.yml` only, worded
   without note-value nouns ("Mix the textures of the first four species so
   that no one of them fills most of the bars."). Specs in
   `mix_species_textures_spec.rb`: no notes; one-bar voice; every Fux
   fifth-species figure adherent; figure 73 with its eight ligature bars
   marked by code; figure 55; a first-species line with every body bar
   marked; a tie-in followed by quarters is florid; a dotted half is florid;
   an empty middle bar excluded; a whole held across a bar line; the
   triple-meter line; a solo voice; exactly half adherent; one more than
   half marked; a configured share. `fifth_species_melody_spec.rb` pins the
   primary tier through `items_by_tier`; `guide_item_strings_spec.rb` swaps
   the row; the diagonal spec adds `<= 0.85` on the composite for each other
   species beside the fourth-species assertion. Survey: 3.7 records the
   measure and the rejected run measures; 6.1 and 6.2 replace the stale
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

2. **`AlwaysMove` knows the anticipation.** First the source trace, recorded
   in the story: Ars Nova sanctions repetition in upper parts and forbids it
   in the lowest voice; check Salzer and Schachter's fifth-species chapter
   and Open Music Theory's fifth-species page for the anticipation or for
   repetition in the bass. Then in `marks`, reject a unison pair when the
   first note is an undotted quarter on a weak beat (`position.weak?`), the
   second is on a strong beat, and `voice.note_preceding(first.position)`
   steps down into it (`note_preceding` returns the tied placement when the
   approach is a tie-in, so `A G G2-` in 86a qualifies). Apply the exemption
   in every voice if the trace found a bass sanction; otherwise only when
   the voice is not the bass, and list 87a and 88b under "Marks on Fux's
   lines" as liberties. Strings unchanged. Specs: anticipation adherent;
   repeated half marked; quarter approached from below marked; by leap
   marked; repeated quarter from beat 1 to 2 marked; the Fux figures through
   `fux_fifth_species_example` with the verdict the trace settled; 85b keeps
   its 9:3 mark. Survey 3.8 records the exemption and its source. CHANGELOG
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

4. **`Diatonic`, by source.** Trace first: the surveys sanction the raised
   seventh at the cadence only, and no species-tradition source in the
   repository names the mid-line raised seventh or B-flat. Check Salzer and
   Schachter and Open Music Theory. For each shape a source names, add one
   predicate (`raised_seventh_to_tonic?` for a sharpened degree 7 whose next
   note is the tonic a semitone above, comparing the alteration through the
   seam the existing `== "#"` uses; `lowered_fourth_in_lydian?` for
   `key_signature.scale_type.name == :lydian` and degree 4 lowered), and
   fold the penultimate exemption into the first if it is adopted. For each
   shape without a source, no change: pin the mark in `diatonic_spec.rb`
   through `fux_fifth_species_example` and list it as a liberty. In every
   case the with-errors line `fux_cantus_firmus_examples_with_errors-3-v0`
   keeps its mid-line F-sharps, asserted by name. Survey 3.8 records the
   outcome. CHANGELOG Changed entry only if the guideline changes. Movement,
   if any: the cleared counterpoints under every gated guide carrying
   `Diatonic` (all melody guides including `diatonic_melody`, the
   cantus-firmus guides, `first_three_species_melody`, composites); any row
   moving down means a sharpened penultimate that is not a raised seventh to
   the tonic, expected none.

5. **`ConsonantClimax` pinned.** No guideline change. Add contexts to
   `consonant_climax_spec.rb` through `fux_fifth_species_example`: 84a marked
   three times, 87 upper marked twice, each named a liberty in the example
   description. Survey 3.8 records Salzer and Schachter's "never repeated"
   beside the verdict. No movement; no CHANGELOG entry.

6. **`StepOutOfUnison` leaves `FifthSpeciesMelody`.** Trace: the survey's
   line 346 and the second- and third-species surveys' lines are
   unattributed; Ars Nova permits the unaccented passing unison without a
   rule for leaving it; check Salzer and Schachter. Absent a source, remove
   through the documented seam,
   `secondary_items(*MOVING_MELODIC_CRAFT, PreferLongBeforeShort, except: StepOutOfUnison)`,
   which matches by guideline after wrapping (precedent `diatonic_melody.rb`)
   and survives the cores becoming `GuideItem`s. Update the comment in
   `species_melody.rb` and the guide spec's include to `not_to include`.
   `FirstSpeciesMelody` names the rule by hand and is untouched. Survey 3.11
   attributes the line and records the removal. CHANGELOG Changed entry.
   Movement, the two fifth-species guides only: `item_count` -1 on every
   gated row; `message_count` -1 on the seven Fux figures and any ladder it
   marked; fitness nudged on every gated row with secondary marks (units 31
   to 29). The distinct item set is unchanged, so no `snapshot_english`.

7. **Wrap-up.** Fill "Marks on Fux's lines" from the committed fixtures
   with each verdict; record each checkpoint's movement by class from the
   joined captures; reconcile the CHANGELOG against the captures; write the
   source-trace outcomes for steps 2, 4, and 6 into the story.

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

- The item-level "proportionate discount" and the 0.85 target pull against
  each other: only the steep shape (every dominant bar marked, no
  denominator) reaches the target. The proportionality lives in the mark
  count and the primary weight, and the criteria now say so.
- Steps 2, 4, and 6 each begin with a source trace whose outcome the plan
  cannot know. Each has a default that needs no source: the exemption
  restricted to upper voices, no `Diatonic` change, removal. A trace that
  finds a source widens the step and is recorded in the story.
- Secondary-weight redistribution at steps 3 and 6 touches nearly every
  gated row on the two fifth-species guides; keep them separate and
  adjacent and attribute each as one class.
- Jeppesen's book sits in the working notes and is easy to reach for. A
  Jeppesen citation may corroborate a reading; it may not be the source of
  a change.
