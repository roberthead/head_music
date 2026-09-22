<!--
metadata:
  created_at:   2026-09-21T15:18:56-07:00
  activated_at: 2026-09-21T15:18:56-07:00
  planned_at:   2026-09-21T18:25:44-07:00
  finished_at:
  updated_at:   2026-09-21T19:49:49-07:00
-->

# Grade Every Fux Fifth-Species Figure

AS a maintainer of the fifth-species guides
I WANT every two-voice fifth-species example in Gradus ad Parnassum graded by
the guides and pinned in the corpus snapshot
SO THAT the embellished-suspension rule is tested against Fux's own lines in
every mode and with the counterpoint below the cantus, not only against one
dorian figure and constructed shapes

Fast follow to
[Embellish Fifth Species Suspensions](../done/embellish-fifth-species-suspensions.md),
which shipped `EmbellishedSuspensionTreatment` with this risk on record: "The
corpus contains no voice with a beat-2 resolution followed by a different
beat-3 pitch, so the stricter rule is untested against real lines beyond the
fixtures." Both it and
[Require the Species Rhythm](../done/require-the-species-rhythm.md) deferred
"the other cantus firmi" to a follow-up. This is that follow-up, narrowed to
the species whose rule is at risk.

## The gap

Every species fixture sits on Fux's D dorian cantus with the counterpoint
above it. Fux wrote fifth species in all six modes, and in most of them twice,
once with the cantus below and once with it above. Mark Gotham's CC0 kern
transcriptions of Gradus enumerate the two-voice fifth-species figures:

| Figure | Mode | Cantus firmus | In the corpus today |
| --- | --- | --- | --- |
| 82 | D dorian | lower | yes |
| 83 | D dorian | upper | no |
| 84a | E phrygian | lower | no |
| 84b | E phrygian | upper | no |
| 85a | F lydian | lower | no |
| 85b | F lydian | upper | no |
| 86a | G mixolydian | lower | no |
| 86b | G mixolydian | upper | no |
| 87a | A aeolian | upper | no |
| 87 (upper counterpoint) | A aeolian | lower | no; not in Gotham's corpus, scan only |
| 88a | C ionian | lower | no |
| 88b | C ionian | upper | no |

Eleven counterpoints are ungraded. Five of them sit below the cantus.
Three of Fux's first-species fixtures do that, but none of the fixtures for
the moving species does, so the florid dissonance and suspension rules have
never graded a published bass counterpoint.

The decision the last story took, that an anticipated resolution must still
sound on beat 3, was made on pedagogy and constructed examples. Fux's other
florid lines are the evidence that was missing. If one of them is marked, the
story records why and decides whether the rule or the reading of Fux is wrong.

## Decisions

- **Relax the resolution rule.** Fux's figure 85b, bar 2, resolves a
  suspension on beat 2 as an eighth note and has moved to another consonance
  by beat 3; its mirror 85a holds the same suspension a half note. Fux wrote
  both, so beat 3 is the latest the resolution may arrive, not the moment it
  must sound. `EmbellishedSuspensionTreatment#resolved?` accepts the strict
  rule's answer or the beat-3 slot's. This reverses the beat-3 decision of
  Embellish Fifth Species Suspensions, on the evidence that story asked for.
  Decided 2026-09-21.
- **Include figure 87's upper counterpoint** from the scan alone, marked
  scan-only in its source. The story claims every figure, and the cost is one
  transcription without a kern check. Decided 2026-09-21.
- **Leave the cantus constants alone.** Fux's figure-88 cantus is
  `C D F E G F E D C`, which matches neither C ionian entry in
  `FUX_CANTUS_FIRMUS_EXAMPLES`, and the lydian figures sit an octave below
  that constant. Changing them would move corpus rows for no reason this story
  owns. Recorded as a follow-up.

## Acceptance Criteria

- A fixture for each of figures 83, 84a, 84b, 85a, 85b, 86a, 86b, 87a, 88a,
  and 88b, in Mann's numbering, plus the upper counterpoint of figure 87,
  which Gotham did not transcribe. Each sits on Fux's cantus firmus for that
  mode with a `source` naming the figure. Pitches are taken from the scan and
  confirmed against the kern transcription, as for figures 33, 55, 73, and
  82; figure 87's upper counterpoint is scan-only and its source says so. Any
  disagreement between scan and kern is settled from the scan and noted in the
  story. `V:cantus firmus` stays the first voice in every fixture, including
  the counterpoint-below ones.
- The fixtures are in `PUBLISHED_SOURCES`, so every voice of every figure is
  in `corpus_fitness.json`. Each changed or added snapshot row of an existing
  fixture is explained. The cantus-firmus rows of the new fixtures are pinned
  but not asserted; the diagonal grades `counterpoint_voice` only.
- Every new counterpoint voice is adherent to both primary items of
  `FifthSpeciesHarmony`, `FloridDissonanceTreatment` and
  `EmbellishedSuspensionTreatment`, or each primary mark is listed under
  "Marks on Fux's lines" with figure, bar and beat, guideline, the notes
  involved, and one of three decisions: the transcription was wrong and the
  scan reading is given; the mark stands as a liberty Fux took; or the rule
  changes and the change is named. Known before transcription: 85b bar 2
  (`EmbellishedSuspensionTreatment`; the rule changes, see Decisions) and 86a
  bar 12 (a tie the kern drops at a system break; the scan prints it).
- `guide_species_diagonal_spec` runs over all fifth-species fixtures with no
  change to its table. On `fifth_species_melody` every fifth-species fixture
  grades at least as high as any other-species fixture. On `fifth_species` the
  same holds, or for each cell that does not the story records figure,
  guideline, and a decision. A cell may be excluded only by name in the spec,
  never by loosening the comparison.
- The counterpoint-below fixtures grade through the fifth-species harmony
  guide without error, and no guideline marks a bass counterpoint for a rule
  that applies only above the cantus.
- `NoteCountPerBar`, the base of `OnePerBar`, `TwoPerBar`, `ThreePerBar`, and
  `FourPerBar`, counts middle bars over the voice's own span, as
  `SustainAcrossBarlines` does, and no longer returns early without a cantus
  firmus, so a solo voice no longer passes vacuously. An empty middle bar gets
  the bar-spanning mark `SustainAcrossBarlines` uses. A voice of two bars or
  fewer has no middle bars. The "without a cantus firmus voice" context in
  `note_count_per_bar_spec.rb` is rewritten to assert the marks. Both earlier
  stories noted this as a small follow-up.
- Locale strings, `english_strings.yml`, and the guide-string canaries change
  only for `EmbellishedSuspensionTreatment`, whose sentence no longer says
  "halfway through the bar" once the rule relaxes. The new sentence is
  recorded under Decisions.

## Notes

- Kern sources: `https://raw.githubusercontent.com/MarkGotham/species/HEAD/1x1/gap_NNN.krn`
  (`gap_083.krn`, `gap_084a.krn`, and so on). Each carries a header naming the
  figure, species, modal final, and which voice is the cantus. The scan is
  `Fux_Gradus.pdf` under `~/Documents/Education/SOU/2017_04-06/MIIS 522/`
  (`counterpoint-proj-lit/lit research/books and papers/`); render at 600 dpi
  or better with `pdftoppm` to read ties and accidentals.
- The ABC parser accepts `K:Ephr`, `K:Flyd`, `K:Gmix`, `K:Aaeo`, and `K:Cion`
  (verified 2026-09-21). `dorian_species_abc` should become a general helper
  that takes the key and the cantus, with the dorian one delegating to it.
- Cantus pitches and register follow the scan, confirmed by the kern, so the
  intervals are Fux's. Phrygian, mixolydian, and aeolian match
  `fux_cantus_firmus_examples`; lydian is an octave lower, as first-species
  figures 13 and 14 already are; the figure-88 C ionian cantus matches
  neither existing entry. See Decisions.
- The fixtures name voices by role (`V:cantus firmus`, `V:counterpoint`), so
  a counterpoint below the cantus is only lower pitches in the counterpoint
  voice. The guidelines that branch on `bass_voice?`, such as
  `StartOnPerfectConsonance`, already meet a bass counterpoint in the
  first-species fixtures; the florid guidelines do not.
- Each two-voice fixture adds 60 snapshot rows, so expect 660 new rows in
  `corpus_fitness.json`. That diff is mechanical. The count-guideline change
  is committed alone, before any fixture, and moves rows only under the
  first-, second-, third-, and triple-meter-third-species melody guides and
  composites, for voices with no companion notes (solo ladders,
  `against-empty`, every cantus-firmus corpus voice, the with-errors examples)
  and for `against-cantus-1/2/4`, which improve because bars the voice never
  reached are no longer marked. Movement is explained by class. Adding the
  fixtures moves no existing row.
- Second, third, and fourth species in the other modes are not in this story.
  Their rhythm guidelines already separate the species on the dorian diagonal
  and were not changed by the last story, so those fixtures would cost the
  same transcription per figure and answer no open question. They can follow
  once the fifth-species figures show whether the other modes surprise us.
- The raised leading tone Fux writes in the penultimate bar is an accidental
  in the ABC, as `^c` is in figure 82. `Diatonic` also charges the lydian
  B-flats and 86a's mid-line F-sharp; melody scores still clear 0.966, so no
  action.

## Measured

| Figure | melody | harmony | composite | other-species max | primary marks |
| --- | --- | --- | --- | --- | --- |
| _filled from the committed fixtures at checkpoint D_ | | | | | |

## Marks on Fux's lines

| Figure | bar:beat | guideline | notes involved | decision |
| --- | --- | --- | --- | --- |
| 85b | 2:1 to 2:2 | EmbellishedSuspensionTreatment | F3 over G, resolves E3 as an eighth, C3 on beat 3 | rule changes; see Decisions |
| 86a | 12:1 | FloridDissonanceTreatment (kern only) | A4 over B3 | transcription: the scan ties bars 11 to 12 |

## Follow-ups

- `AlwaysMove` charges Fux's re-struck anticipated resolution in 86a bar 12,
  87a bar 8, and 88b bar 7.
- The two cantus constants that disagree with Fux's printed figures.
- Figure 88's N.B. at bar 5 of the upper voice, which Fux flags himself and
  no guideline marks.

## Implementation Plan

Planned 2026-09-21 with product-manager and developer input. Every number
below was re-measured in this session from kern-derived ABC (figure 86a with
its dropped tie restored); the other-species maxima come from the pinned
snapshot: 0.929 on `fifth_species` (figure 73) and 0.881 on
`fifth_species_melody`.

### Measured before transcription

| Figure | fifth_species | melody | harmony | Primary marks |
| --- | --- | --- | --- | --- |
| 82 (pinned) | 0.953 | 0.970 | 0.937 | none |
| 83 | 0.994 | 0.989 | 1.000 | none |
| 84a | 0.959 | 0.966 | 0.951 | none |
| 84b | 1.000 | 1.000 | 1.000 | none |
| 85a | 0.986 | 0.988 | 0.984 | none |
| 85b | 0.916 | 0.987 | 0.850 | EmbellishedSuspensionTreatment 1:3 to 2:2 |
| 86a (tie restored) | 0.959 | 0.977 | 0.941 | none; without the tie 0.885, FloridDissonanceTreatment 12:1 |
| 86b | 0.986 | 0.989 | 0.984 | none |
| 87a | 0.994 | 0.989 | 1.000 | none |
| 88a | 1.000 | 1.000 | 1.000 | none |
| 88b | 0.994 | 0.989 | 1.000 | none |

The melody diagonal holds for all ten. The composite diagonal fails for 85b
alone, and only because of the one mark.

### Findings that shape the plan

- **Figure 85b, bar 2** (confirmed on the scan): F3 held over the cantus G,
  resolves to E3 as an eighth on beat 2, passes through D3, and sounds C3 on
  beat 3. This is the shape the last story chose to mark ("resolution must
  sound on beat 3"). Its mirror 85a holds the same suspension a half note
  and is adherent. Fux wrote both.
- **Figure 86a, bars 11 to 12**: the kern has no tie on the repeated A, but
  the scan prints a tie stub into bar 12 across the system break. Kern drops
  ties at system breaks; every cross-bar pitch repetition is checked on the
  scan. The other one is 85b bars 9 to 10 (D3), which does not move a
  decision either way.
- **Figure 87** prints an upper counterpoint as well as the lower one Gotham
  transcribed as 87a. There is no `gap_087b.krn`. Including it means one
  scan-only transcription.
- **Figure 88's N.B.**: Fux flags bar 5 of the upper voice himself (two
  quarters opening the bar without a following ligature) and gives figure 89
  as "better". No guideline marks it today. Record, do not act.
- Fux's figure-88 cantus is `C D F E G F E D C`, which matches neither
  C ionian entry in `FUX_CANTUS_FIRMUS_EXAMPLES`; the lydian cantus in the
  figures is F3-based where the constant is F4-based. The constants are left
  alone; recorded as a follow-up.

### Steps

Each checkpoint is a point to commit at; each snapshot regeneration has one
cause. Capture `bin/guide_grade_corpus.rb` output before and after each
checkpoint and join with `bin/guide_grade_table.rb` to attribute movement.

1. **Count guidelines over the voice's own span** (checkpoint A).
   `lib/head_music/style/guidelines/note_count_per_bar.rb`: replace the
   no-cantus early return with `return [] if notes.empty?`; `middle_bars`
   becomes the exclusive range between the voice's first and last bar, as in
   `SustainAcrossBarlines#middle_bar_numbers`; `mark_bar` marks an empty bar
   with a bar-spanning `Mark.new(downbeat, next downbeat)` and drops the
   cantus-note fallback, because the defect belongs to the graded voice.
   Covers `ThreePerBar` too, since the rule lives in the base class. In
   `note_count_per_bar_spec.rb` invert "without a cantus firmus voice" to
   assert marks on a solo voice, pin the span mark for an empty bar, add
   contexts for a voice that starts after or ends before the cantus. Expected
   snapshot movement, by class: whole-note voices with no companion now
   marked by Two/Three/FourPerBar under the second- and third-species melody
   guides and composites (solo ladders, `against-empty`, every cantus-firmus
   corpus voice); the with-errors cantus examples now marked by `OnePerBar`;
   `against-cantus-1/2/4` improve on `first_species_melody` because bars the
   voice never reached are no longer marked. Any row moving under a harmony
   guide, or for a counterpoint voice with a cantus, is a defect.

2. **Key-aware species helper** (checkpoint B, snapshot byte-identical).
   `spec/spec_helper.rb`: `FUX_CANTUS_FIRMUS_ABC` keyed by ABC key
   (`Ddor`, `Ephr`, `Flyd`, `Gmix`, `Aaeo`, `Cion`); `species_abc(params)`
   takes `key:` (default `Ddor`) and looks the cantus up by key;
   `dorian_species_abc` and `dorian_species_examples` delegate, since
   guideline specs call them directly. `V:cantus firmus` stays the first
   voice in every fixture so `v0`/`v1` keep their meaning. Cantus strings, in
   the scan's register:
   `Ephr E4|C4|D4|C4|A,4|A4|G4|E4|F4|E4|]`,
   `Flyd F,4|G,4|A,4|F,4|D,4|E,4|F,4|C4|A,4|F,4|G,4|F,4|]`,
   `Gmix G,4|C4|B,4|G,4|C4|E4|D4|G4|E4|C4|D4|B,4|A,4|G,4|]`,
   `Aaeo A,4|C4|B,4|D4|C4|E4|F4|E4|D4|C4|B,4|A,4|]`,
   `Cion C4|D4|F4|E4|G4|F4|E4|D4|C4|]`.

3. **Decide the 85b rule** (checkpoint C; decided, see Decisions).
   If the rule relaxes: `EmbellishedSuspensionTreatment#resolved?` becomes
   `super || slot_resolved?(cp_note, cf_note)`, with the current body moved
   to `slot_resolved?`. Measured: exactly one existing expectation flips,
   "when the anticipated resolution is not held on beat three" (line 98),
   which becomes adherent; rename it to describe the accepted shape and add
   the mirror that still marks (a beat-2 step down that then leaps). The
   `en.yml` strings say "halfway through the bar", which would no longer
   describe the rule; reword in every locale that carries the key, run
   `rake style:snapshot_english`, update the literal in
   `guide_item_strings_spec.rb`, record the sentence here. Expect no
   snapshot movement, since figure 82 has no beat-2 resolution.
   If the rule stays: 85b is excluded from the composite diagonal by name
   with a `pending` naming the figure and reason, and a follow-up story is
   filed. That defeats this story's purpose, which is the argument against it.

4. **Transcribe and pin the figures** (checkpoint D, one commit per mode
   pair). Order 83, 84a/b, 85a/b, 86a/b, 87a, then figure 87's upper
   counterpoint from the scan alone, then 88a/b. Scan pages: PDF page 36
   holds figures 82 to 85, page 37 figures 86 to 89; render with
   `pdftoppm -r 600` or higher and crop. Kern is the check; the scratchpad's
   `kern2abc.rb` converts it mechanically for comparison. Kern to ABC at
   `L:1/4`: `CC` to `C,,`, `C` to `C,`, `c` to `C`, `cc` to `c`; `1` to `4`,
   `2` to `2`, `4` bare, `8` to `/2`; `[` to a
   trailing `-`; accidentals restated in every bar. Append the entries after
   figure 82 with `source: "Fux chapter five figure NN"` and `key:`;
   `PUBLISHED_SOURCES` already lists the accessor. Grade every new
   counterpoint before pinning with the two primary harmony items and the
   three fifth-species guides, and fill the tables above from the committed
   fixtures. Add a spec context pinning 85b adherent (or the named `pending`
   if step 3 was declined). Regenerate: expect 660 rows added, none moved.
   Run the diagonal spec; if a cell still fails, dump per-item assessments,
   re-read the scan for a dropped tie, ask whether a guideline is charging
   bass position or mode rather than species,
   and otherwise record an open question. Never loosen the comparison or drop
   a fixture.

5. **Wrap up** (checkpoint E). Fill the tables, the scan-versus-kern notes,
   the moved-row classes, the decisions, and the follow-ups: `AlwaysMove`
   charges Fux's re-struck anticipated resolution in 86a bar 12, 87a bar 8,
   and 88b bar 7; the two cantus constants; figure 88's N.B. CHANGELOG entry.

### Testing

`bundle exec rubocop -a` and `bundle exec rake` at every checkpoint;
`bundle exec rspec <file>` for the guideline specs and the diagonal spec in
between. Guideline behavior is asserted in guideline specs, corpus movement
in the snapshot, species separation in the diagonal. No stdout assertions.

### Risks

- The diagonal margin is 0.024 (figure 82 at 0.953 against figure 73 at
  0.929). A transcription slip in any below-cantus figure can breach it; the
  kern's dropped ties are the known failure mode.
- Relaxing the rule reverses a recorded pedagogical decision. The new framing
  is that beat 3 is the latest the resolution may arrive, not the moment it
  must sound.
- 84a earns three `ConsonantClimax` marks because the phrygian line opens on
  its peak; a modal artifact, pinned and not acted on. `Diatonic` charges the
  lydian B-flats and 86a's mid-line F-sharp; melody scores still clear 0.966.
