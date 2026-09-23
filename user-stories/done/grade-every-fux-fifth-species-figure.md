<!--
metadata:
  created_at:   2026-09-21T15:18:56-07:00
  activated_at: 2026-09-21T15:18:56-07:00
  planned_at:   2026-09-21T18:25:44-07:00
  finished_at:  2026-09-22T20:16:29-07:00
  updated_at:   2026-09-22T20:16:29-07:00
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
the other cantus firmi to a follow-up. This is that follow-up, narrowed to the
species whose rule is at risk.

## Background

Every fixture for the moving species sits on Fux's D dorian cantus with the
counterpoint above it. Fux wrote fifth species in all six modes, in each mode
once with the counterpoint above the cantus and once below. Mark Gotham's CC0
kern transcriptions of Gradus cover all but one of them:

| Figure | Mode | Counterpoint | Kern | In the corpus |
| --- | --- | --- | --- | --- |
| 82 | D dorian | above | gap_082 | yes |
| 83 | D dorian | below | gap_083 | no |
| 84a | E phrygian | above | gap_084a | no |
| 84b | E phrygian | below | gap_084b | no |
| 85a | F lydian | above | gap_085a | no |
| 85b | F lydian | below | gap_085b | no |
| 86a | G mixolydian | above | gap_086a | no |
| 86b | G mixolydian | below | gap_086b | no |
| 87 upper | A aeolian | above | none | no |
| 87a | A aeolian | below | gap_087a | no |
| 88a | C ionian | above | gap_088a | no |
| 88b | C ionian | below | gap_088b | no |

Eleven counterpoints are ungraded, five of them below the cantus. Three
first-species fixtures already put the counterpoint below, but no fixture of
a moving species does, so the florid dissonance and suspension rules have
never graded a published bass line.

### Fux's lines are evidence, not an oracle

Twentieth-century scholarship holds that Fux's guidelines contradict one
another at times and that his examples follow practices his rules do not
state. Fux acknowledges some of this himself: Aloysius's "small errors for
which you have yet had no rules", the N.B. markings, a manuscript correction
to a third-species penultimate bar that Mann footnotes, and the errata page of
the 1725 edition. Everyone who has graded the figures mechanically finds
marks. Samory, Mandanici, Canazza, and Peserico found four of nine general
rules broken across six of Fux's cantus firmi, including repeated arpeggios
against an absolute rule. Sprockeels, Wafflard, Van Roy, and Haddad scored
Fux's own lydian counterpoint at more than twice the cost of their solver's
best and concluded that "Fux establishes preferences but does not seem to
follow them closely". Wafflard records Fux breaking the fourth-species
syncopation rule "to avoid monotony" and drops one third-species penultimate
bar from the model "because of its inconsistency with the rest". McGill's
study guide to the Mann edition cites the second-species phrygian line's
c-f-c'-f' against Fux's own advice on successive skips.

- Ewing, John. *A Historical and Algorithmic Study of Fux's Approach to
  Counterpoint*. New College of Florida, 2009.
  <https://digitalcommons.ncf.edu/theses_etds/4097/>
- Samory, Mattia, Marcella Mandanici, Sergio Canazza, and Enoch Peserico.
  "The Counterpoint Game: Rules, Constraints and Computational Spaces."
  ICMC/SMC 2014.
  <https://www.icmc14-smc14.net/images/proceedings/PS3-B07-TheCounterpointGame.pdf>
- Sprockeels, Damien, Thibault Wafflard, Peter Van Roy, and Karim Haddad.
  "A Constraint Formalization of Fux's Counterpoint." JIM 2023.
  <https://jim2023.sciencesconf.org/data/pages/3_2_SPROCKEELS_ET_AL.pdf>
- Wafflard, Thibault. *A Constraint Programming Based Tool Formalizing Fux's
  Counterpoint*. UCLouvain, 2023.
  <https://webperso.info.ucl.ac.be/~pvr/WAFFLARD_46581700_2023.pdf>
- McGill, Scott. *Study Guide for Fux Gradus ad Parnassum*.
  <https://www.scribd.com/document/350328102/Study-Guide-for-Fux-Gradus-Ad-Parnassum>
- Schulte, Sara Miller. *Gradus ad Parnassum: A Reader's Edition and
  Commentary*. Western Michigan University, 2017.
  <https://scholarworks.wmich.edu/masters_theses/1993/>
- Mann, Alfred, trans. *The Study of Counterpoint from Johann Joseph Fux's
  Gradus ad Parnassum*. Norton, 1965. The "small errors" passage is on page
  37 and the manuscript-correction footnote on page 54.

## What Fux's lines show

Grading the ten kern transcriptions ahead of the work, converted mechanically
to ABC, produced two marks, exposed one gap in the sources, and found the
cantus constants disagreeing with the scan. Each is settled here, and the
rest of the story is written to the settled state.

**Figure 85b, bar 2, is a liberty Fux took, and the mark stands.** F3 is
held from bar 1 under the cantus G3, resolves to E3 as an eighth on beat 2,
passes through D3, and sounds C3 on beat 3. This is the shape the last story
chose to mark, by requiring the resolution to sound on beat 3. Its mirror,
figure 85a, holds the same suspension a half note and is adherent. The strict
rule stays because only Fux sanctions the shape: the survey in
`references/fifth-species-counterpoint.md` quotes Girton's constraint that
the resolution sounds on beat 3 "whether or not the resolution is
anticipated", and none of its five embellishment types has the resolution
moved on by beat 3. 85b keeps its one primary mark and the fixture pins it.
The cost is proportionate: 0.916 on the composite and 0.850 on the harmony
guide, high marks for a line the guide is right to notice.

**Figure 86a, bar 12, is a transcription error in the kern.** The kern
re-strikes A4 on the downbeat over the cantus B3, an attacked seventh that
`FloridDissonanceTreatment` marks. The scan ties bars 11 and 12 across a
system break, where the kern drops ties. The fixture follows the scan, and
every repeated pitch across a bar line is checked the same way. The only
other one is 85b bars 9 to 10 (D3), which changes no verdict either way.

**Figure 87's upper counterpoint comes from the scan alone.** Gotham
transcribed only the lower one, 87a. The story claims every figure, and the
cost is one transcription without a kern check. Its source string says so.

**The cantus constants stay as they are.** Fux's figure-88 cantus is
`C D F E G F E D C`, which matches neither C ionian entry in
`FUX_CANTUS_FIRMUS_EXAMPLES`, and the lydian figures sit an octave below that
constant's F4. The fixtures follow the scan. Changing the constants would move
corpus rows for reasons this story does not own; they are a follow-up.

## Measured

The committed fixtures, graded at checkpoint 3. The ten kern-derived figures
reproduce the numbers measured before the work to three decimals. The
other-species maxima under the fifth-species guides come from the pinned
snapshot: 0.929 on the composite (figure 73, fourth species) and 0.881 on the
melody guide.

| Figure | composite | melody | harmony | primary marks |
| --- | --- | --- | --- | --- |
| 82 (pinned) | 0.953 | 0.970 | 0.937 | none |
| 83 | 0.994 | 0.989 | 1.000 | none |
| 84a | 0.959 | 0.966 | 0.951 | none |
| 84b | 1.000 | 1.000 | 1.000 | none |
| 85a | 0.986 | 0.988 | 0.984 | none |
| 85b | 0.916 | 0.987 | 0.850 | EmbellishedSuspensionTreatment on the note held from 1:3 |
| 86a | 0.959 | 0.977 | 0.941 | none (0.885 and FloridDissonanceTreatment 12:1 without the tie) |
| 86b | 0.986 | 0.989 | 0.984 | none |
| 87 upper | 0.985 | 0.971 | 1.000 | none (scan only) |
| 87a | 0.994 | 0.989 | 1.000 | none |
| 88a | 1.000 | 1.000 | 1.000 | none |
| 88b | 0.994 | 0.989 | 1.000 | none |

The melody diagonal holds for all eleven figures. The composite diagonal
fails for 85b alone, and only because of the one mark, so the spec excludes
that cell by name. No figure scores 1.000 on every guide, and none is
expected to.

### Snapshot movement at checkpoint 1

The count-guideline change moved 362 of 4620 rows, every one under a first-,
second-, or third-species guide and none under a harmony guide or for a
counterpoint voice with notes. By class: the solo ladders and the
`against-empty` voices are now marked; every cantus-firmus corpus voice,
whose companion voice is empty, is now marked by Two/Three/FourPerBar under
the second- and third-species melody guides and composites; the cantus voices
of the species fixtures improve by a few thousandths where a florid companion
had charged them once per note; `against-cantus-4` improves where bars it
never reached are no longer marked. Two predictions missed. The with-errors
cantus examples moved with the other cantus voices rather than under
`OnePerBar`, since all their notes are whole notes, and the empty companion
voices did not move at all, because the minimum-notes gate stops their
assessment before the count guidelines run. The fixtures then added 660 rows
across six commits and moved none.

## Acceptance Criteria

- A fixture for each of figures 83, 84a, 84b, 85a, 85b, 86a, 86b, 87a, 88a,
  and 88b, in Mann's numbering, plus the upper counterpoint of figure 87. Each
  sits on Fux's cantus firmus for that mode, in the scan's register, with a
  `source` naming the figure. Pitches are read from the scan and confirmed
  against the kern, as for figures 33, 55, 73, and 82; figure 87's upper
  counterpoint is scan-only and its source says so. A disagreement between
  scan and kern is settled from the scan and listed under "Marks on Fux's
  lines" when it changes a grade. `V:cantus firmus` is the first voice in
  every fixture, including the counterpoint-below ones.
- The fixtures are in `PUBLISHED_SOURCES`, adding 660 rows to
  `corpus_fitness.json` and moving none. The cantus-firmus rows of the new
  fixtures are pinned but not asserted; the diagonal grades
  `counterpoint_voice` only.
- Fux's lines are graded as evidence, not as an oracle. No fixture is
  required to score 1.000, and no guideline is loosened to make a Fux line
  pass. Every primary mark on a Fux line is settled and listed under "Marks
  on Fux's lines" with figure, bar and beat, guideline, the notes involved,
  and how it was settled: a corrected reading of the scan, a liberty Fux
  took, or a named rule change. A rule change requires support from a source
  other than Fux, named in the story; a liberty keeps its mark and its cost.
  Under this standard 86a is adherent with its tie and 85b carries one
  `EmbellishedSuspensionTreatment` mark.
- `EmbellishedSuspensionTreatment` is unchanged. A spec context pins figure
  85b's bar-2 shape as marked, beside the existing figure 82 context, so the
  liberty is a recorded verdict rather than an accident of the corpus. No
  locale string changes.
- `guide_species_diagonal_spec` runs over all fifth-species fixtures with no
  change to its table. On `fifth_species_melody` and on `fifth_species`,
  every fifth-species fixture grades at least as high as any other-species
  fixture. A cell may be excluded only by name in the spec, never by loosening
  the comparison. The spec holds a map from guide key to excluded fixture
  sources, consulted where it takes the species minimum, with the liberty
  cited beside the entry. Figure 85b on `fifth_species` is its only entry.
- The counterpoint-below fixtures grade through the fifth-species harmony
  guide without error.
- `NoteCountPerBar`, the base of `OnePerBar`, `TwoPerBar`, `ThreePerBar`, and
  `FourPerBar`, counts middle bars over the voice's own span, as
  `SustainAcrossBarlines` does, and no longer returns early without a cantus
  firmus, so a solo voice no longer passes vacuously. An empty middle bar gets
  the bar-spanning mark `SustainAcrossBarlines` uses. A voice of two bars or
  fewer has no middle bars. The "without a cantus firmus voice" context in
  `note_count_per_bar_spec.rb` places notes in the solo voice and asserts the
  marks. This change lands first, in its own commit, with its snapshot
  movement explained by class.

## Notes

- Kern: `https://raw.githubusercontent.com/MarkGotham/species/HEAD/1x1/gap_NNN.krn`.
  Each file's header names the figure, species, modal final, and which voice
  is the cantus ("Cantus firmus: Upper" means the counterpoint is below).
  Kern to ABC at `L:1/4`: octaves `CC`, `C`, `c`, `cc` become `C,,`, `C,`,
  `C`, `c`; durations `1`, `2`, `4`, `8` become `4`, `2`, bare, `/2`; `[` becomes
  a trailing `-`; `#` and `-` become `^` and `_`, restated in every bar; the
  kern's `2/2` is written `M:4/4` to match the existing fixtures. Kern drops
  ties at system breaks.
- Scan: `Fux_Gradus.pdf` under `~/Documents/Education/SOU/2017_04-06/MIIS 522/`
  (`counterpoint-proj-lit/lit research/books and papers/`). PDF page 36 holds
  figures 82 to 85, page 37 figures 86 to 89. Each figure is a three-stave
  system: counterpoint above, cantus, counterpoint below. Render with
  `pdftoppm -r 600` or higher and crop to read ties and accidentals.
- The ABC parser accepts `K:Ephr`, `K:Flyd`, `K:Gmix`, `K:Aaeo`, and `K:Cion`.
  Cantus firmi in the scan's register, one per key:
  `Ephr E4|C4|D4|C4|A,4|A4|G4|E4|F4|E4|]`,
  `Flyd F,4|G,4|A,4|F,4|D,4|E,4|F,4|C4|A,4|F,4|G,4|F,4|]`,
  `Gmix G,4|C4|B,4|G,4|C4|E4|D4|G4|E4|C4|D4|B,4|A,4|G,4|]`,
  `Aaeo A,4|C4|B,4|D4|C4|E4|F4|E4|D4|C4|B,4|A,4|]`,
  `Cion C4|D4|F4|E4|G4|F4|E4|D4|C4|]`. Phrygian, mixolydian, and aeolian match
  `fux_cantus_firmus_examples`; lydian is an octave lower, as first-species
  figures 13 and 14 already are.
- The fixtures name voices by role, so a counterpoint below the cantus is only
  lower pitches in the counterpoint voice. Guidelines that branch on
  `bass_voice?`, such as `StartOnPerfectConsonance`, already meet a bass
  counterpoint in the first-species fixtures; the florid guidelines do not.
- Fux's accidentals are written as accidentals: the raised leading tone in the
  penultimate bar, the lydian B-flats, and 86a's mid-line F-sharp. `Diatonic`
  charges them and melody scores still clear 0.966.
- Figure 84a earns three `ConsonantClimax` marks because the phrygian line
  opens on its peak. A modal artifact, pinned and not acted on. Figure 87's
  upper counterpoint earns two because its peak D5 sounds in bars 7 and 8.
- Second, third, and fourth species in the other modes are left out. Their
  rhythm guidelines already separate the species on the dorian diagonal and
  were not touched by the last story, so those fixtures would cost the same
  transcription per figure and answer no open question.

## Marks on Fux's lines

| Figure | bar:beat | guideline | notes involved | settled |
| --- | --- | --- | --- | --- |
| 85b | held from 1:3, resolves 2:2 | EmbellishedSuspensionTreatment | F3 under G3, E3 as an eighth, C3 on beat 3 | Fux liberty: the resolution has moved on by beat 3; no source other than Fux sanctions the shape, so the mark stands |
| 86a | 12:1 | FloridDissonanceTreatment | A4 over B3 | scan reading: the kern dropped the tie from bar 11 |

## Follow-ups

- `AlwaysMove` charges Fux's re-struck anticipated resolution in 86a bar 12,
  87a bar 8, the upper counterpoint of 87 bar 8, and 88b bar 7.
- The C ionian and lydian entries of `FUX_CANTUS_FIRMUS_EXAMPLES` disagree
  with Fux's printed figures.
- The composite diagonal's margin is thin for a structural reason. A
  fourth-species line scores high on the fifth-species guide because florid
  counterpoint contains suspensions, and nothing charges a fifth-species line
  for being all one rhythm. The survey's rule that no single species should
  dominate is the guideline that would separate them; it is the real fix for
  the fragility, and it belongs to its own story.
- Figure 88's N.B. at bar 5 of the upper voice: two quarters opening the bar
  with no ligature following, which Fux flags himself and answers with figure
  89 as "better". No guideline marks it. A guideline that marks what Fux
  flagged himself would be evidence of calibration, not dogmatism.
- Whether to report the dropped tie in `gap_086a.krn` upstream.
- Second through fourth species in the other modes.

## Implementation Plan

Four checkpoints, each a point to commit at, each with one cause for any
snapshot movement. Capture `bin/guide_grade_corpus.rb` output before and after
each checkpoint and join the two with `bin/guide_grade_table.rb` to attribute
every moved row.

1. **Count guidelines over the voice's own span.**
   `lib/head_music/style/guidelines/note_count_per_bar.rb`: replace the
   no-cantus early return with `return [] if notes.empty?`; make
   `middle_bars` the exclusive range between the voice's first and last bar,
   as in `SustainAcrossBarlines#middle_bar_numbers`; have `mark_bar` mark an
   empty bar with a bar-spanning `Mark.new(downbeat, next downbeat)` and drop
   the cantus-note fallback, since the defect belongs to the graded voice.
   The rule lives in the base class, so `ThreePerBar` is covered. In
   `note_count_per_bar_spec.rb`, invert "without a cantus firmus voice" to
   place notes in the solo voice and assert marks (an empty voice still
   returns none), pin the span mark for an empty bar, and add contexts for a
   voice that starts after or ends before the cantus.
   This lands first because of the new fixtures' cantus rows. When a cantus
   voice is graded, the guideline's cantus lookup falls back to the
   counterpoint voice, so middle bars are enumerated once per companion note
   rather than once per bar. Pinning 330 cantus rows computed that way and
   moving them later would put two causes in one snapshot change.
   Own span is the rule: a voice whose first note is in bar 3 treats bar 3
   as its first bar. Whether a voice covers the whole cantus is another
   guideline's question.
   Expected movement, by class: whole-note voices with no companion notes
   (solo ladders, `against-empty`, every cantus-firmus corpus voice) now
   marked by Two/Three/FourPerBar under the second- and third-species melody
   guides and composites; the with-errors cantus examples now marked by
   `OnePerBar`; the empty counterpoint voice of every cantus-firmus fixture
   loses the marks it placed on the cantus's notes, and the minimum-notes
   gate keeps failing it; the cantus voices of the species fixtures improve
   wherever a florid companion charged them once per note (figure 82's
   cantus carries 23 TwoPerBar marks over 9 middle bars today);
   `against-cantus-1/2/4` improved on `first_species_melody`, because bars
   the voice never reached are no longer marked. A row moving under a
   harmony guide, or for a non-empty counterpoint voice with a cantus, is a
   defect.

2. **Key-aware species helper.** Snapshot byte-identical.
   `spec/spec_helper.rb`: `FUX_CANTUS_FIRMUS_ABC` keyed by ABC key, and
   `dorian_species_abc` reads `key:` (default `Ddor`) for its `K:` line and
   for the cantus default. The helper already accepts a `cantus_firmus:`
   override, so this is a two-line change. Rename it to `species_abc`, with
   `dorian_species_examples` to `species_examples`, and update the three
   caller files; no delegating aliases.

3. **Transcribe and pin the figures.** One commit per mode pair. Order 83,
   84a/b, 85a/b, 86a/b, 87a and 87 upper, 88a/b. Read each figure from the
   scan, convert the kern mechanically, and reconcile; every repeated pitch
   across a bar line is checked on the scan. Append the entries after figure
   82 with `source: "Fux chapter five figure NN"` and `key:`;
   `PUBLISHED_SOURCES` already lists the accessor. Grade every new
   counterpoint with the two primary harmony items and the three
   fifth-species guides before pinning, and replace the Measured table with
   the committed numbers. Add a spec context pinning 85b's bar-2 mark beside
   the existing figure 82 context, and add the exclusion map to the diagonal
   spec with 85b on `fifth_species` as its entry. Regenerate: 660 rows added,
   none moved. If any other diagonal cell fails, dump the per-item
   assessments, re-read the scan for a dropped tie, and ask whether a
   guideline is charging bass position or mode rather than species. A mark
   that survives that review is a liberty and is listed, not fixed. Never
   loosen the comparison or drop a fixture.

4. **Wrap up.** Fill "Marks on Fux's lines" from the committed fixtures,
   record the moved-row classes from step 1, and add the CHANGELOG entry.

### Testing

`bundle exec rubocop -a` and `bundle exec rake` at every checkpoint, with
`bundle exec rspec <file>` on the guideline specs and the diagonal spec in
between. Guideline behavior is asserted in guideline specs, corpus movement in
the snapshot, species separation in the diagonal. No stdout assertions.

### Risks

- The composite margin is 0.024: figure 82 at 0.953 against figure 73 at
  0.929. A transcription slip in any below-cantus figure can breach it, and
  the kern's dropped ties are the known failure mode. A second liberty would
  breach it too, and would be a second named exclusion, not a rule change.
- Named exclusions can accumulate until the diagonal asserts little. One is
  expected. More than one means the composite is not separating species, and
  the fix is the rhythm-mixture follow-up, not another exclusion.

## Review

Reviewed 2026-09-22 at ff8b76b, working tree clean. Full suite 8337 examples,
0 failures, 99.74% line coverage; rubocop clean on the nine changed Ruby
files. Product-manager verification and code review ran as agents; every
finding below was checked against the files before it was recorded.

### Acceptance criteria

| Criterion | Verdict | Evidence |
| --- | --- | --- |
| Eleven fixtures, on Fux's cantus in the scan's register, `V:cantus firmus` first, read from the scan and confirmed against the kern, 87 upper marked scan-only | ⚠️ met on every repo-checkable point; the scan reading needs a human spot-check | `spec/spec_helper.rb` entries after figure 82, each with `source` and `key`; `species_abc` emits the cantus voice first. A mechanical kern-to-ABC rerun matches all ten kern figures bar for bar, with the one intended exception at 86a bar 11 (tie). Figure 87 upper has no kern and rests on the transcription in the story; the scratchpad crops support the 86a tie. |
| In `PUBLISHED_SOURCES`, 660 rows added, none moved; cantus rows pinned, diagonal grades `counterpoint_voice` only | ✅ met | Row counts by commit: 4620 at merge-base and after 475492d and 4600a2e; 4680 after 6214d7a; 5280 after 8b08b38. The six fixture commits changed no existing row. `guide_species_diagonal_spec.rb` assesses `context.counterpoint_voice`. |
| Evidence, not oracle: no loosening, every primary mark settled and listed, 86a adherent with its tie, 85b one mark | ✅ met | The only `lib/` change tightens `NoteCountPerBar`. Grading all twelve fixtures on the two primary harmony items finds one non-adherent item, 85b at `1:3:000 to 2:2:000`; 86a without the tie reproduces the story's 0.885 and the `12:1` mark. Both are in "Marks on Fux's lines". |
| `EmbellishedSuspensionTreatment` unchanged, 85b context beside figure 82's, no locale changes | ✅ met | Diff of the guideline and `lib/head_music/locales` is empty. `embellished_suspension_treatment_spec.rb` "with Fux's lydian line below the cantus" asserts the one mark code. |
| Diagonal spec: table unchanged, exclusion by name only, map keyed by guide and consulted at the species minimum, 85b on `fifth_species` the only entry | ✅ met | `fixtures_by_species` untouched. `liberties` has one entry, cited in the comment above it, applied only on the `own` side. Melody minimum 0.966 against 0.881; composite minimum without 85b 0.953 against 0.929. |
| Counterpoint-below fixtures grade through the harmony guide without error | ✅ met | Snapshot rows for the six below-cantus voices on `fifth_species_harmony`: 1.000, 1.000, 0.850, 0.984, 1.000, 1.000; no error, no failed gate. |
| `NoteCountPerBar` over the voice's own span, no early return, span mark for an empty bar, two bars or fewer no middle bars, solo context asserts marks, lands first in its own commit with movement by class | ✅ met | `note_count_per_bar.rb` `middle_bars`, `downbeat_of`, and `mark_bar` mirror `SustainAcrossBarlines`. Spec contexts cover no notes, two bars, late start, early end, and the empty-bar span. Commit 475492d is the first code commit and the only one touching `lib/`; the story's "Snapshot movement at checkpoint 1" gives the classes. |

### Code review findings

1. **CHANGELOG count is off by one.** The fifth-species Added entry ends
   "the other ten grade between 0.953 and 1.000". Twelve fixtures less 85b
   is eleven. Fixed.
2. **CHANGELOG overstates the no-movement claim.** The `NoteCountPerBar`
   Changed entry ends "No harmony grade and no counterpoint with notes
   moves." The four-note ladder `against-cantus-4` moved on eight rows at
   475492d, for example 0.705 to 0.941 on `first_species_melody`, because
   bars it never reached are no longer marked. The story's own movement
   subsection records this class; the CHANGELOG sentence should say no
   counterpoint that runs the length of its cantus moves, and name the short
   counterpoint as the fourth class. Fixed.
3. **Stale comment above `FUX_CANTUS_FIRMUS_ABC`.** The paragraph that
   introduced the diminution-species fixtures still says they are each set
   above the D dorian cantus and that "only 73 and 82 enter after a half
   rest", and the two new comment lines run on from it with no separation.
   Both claims are now false for the fifth-species entries. Rewrite the
   paragraph and separate the constant's own comment. Fixed.
4. **`NoteCountPerBar` duplicates three methods of `SustainAcrossBarlines`.**
   `middle_bars`, `downbeat_of`, and `mark_bar` are the same code, and
   `mark_bar` is identical apart from one local name. A small shared module
   would carry the span concept once; flay duplication moves the RubyCritic
   score. Optional here; the story asked for the same rule, not shared code.
5. **The C ionian entry of `FUX_CANTUS_FIRMUS_EXAMPLES` disagrees with the
   new map.** Line 86 reads C E F E G F E D C; the map and the scan read
   C D F E G F E D C, and the D is what makes 88a's and 88b's tied C a
   seventh. Already listed under Follow-ups; the two now sit in one file
   with nothing saying which is authoritative.
6. **`liberties` is keyed by guide and reads as keyed by species.** The
   melody check gets no exclusion, which is correct today. A stale liberty
   would never fail on its own; the 85b context in the embellished-suspension
   spec is what keeps it honest. An assertion that each named liberty is
   present and marked would make that explicit. Optional.
7. **Snapshot movement is counted by any field.** The story's 362 rows at
   checkpoint 1 counts every row whose record changed; 201 changed in
   fitness and the other 161 only in message or item counts. Worth one
   clause in the movement subsection.
8. **Minor.** Two comments in `note_count_per_bar_spec.rb` restate their
   example names. `fux_fifth_species_example` re-parses every fixture per
   call and returns nil on a miss. Figure 87 upper's source string carries
   its provenance, which the acceptance criteria require, so it stands.
   The `AlwaysMove` marks on the re-struck anticipations are already a
   follow-up.

Findings 1 to 3 were fixed after the review; nothing blocks `finish`.

## Learnings

- **Grading the figures before planning paid for itself.** Converting the
  kern mechanically and grading all ten figures ahead of the work meant the
  plan was written to a settled state, every mark was decided before a line
  of code changed, and the committed numbers reproduced the pre-measured
  ones to three decimals. The scholarship review did the same for policy:
  deciding that a Fux line is evidence rather than an oracle before the
  first mark appeared kept the one liberty from turning into a rule change.
- **One cause per snapshot change is worth a checkpoint of its own.** Landing
  the count-guideline rewrite first, with its 362 rows explained by class,
  left the six fixture commits with nothing to explain: 660 rows added,
  none moved. The before-and-after captures made each attribution a diff
  rather than an argument.
- **Grading is a transcription check.** Figure 87's upper voice was first
  written an octave too low and eight voice-crossing marks said so at once.
  Every repeated pitch across a bar line was checked on the scan because the
  kern drops ties at system breaks, and that check found the one dropped
  tie that changed a verdict.
- **Predictions of snapshot movement miss on gates and rhythm.** The plan
  expected the with-errors cantus examples to move under `OnePerBar` and the
  empty companion voices to move; whole-note voices never trip a one-per-bar
  rule, and the minimum-notes gate stops an empty voice before any count
  guideline runs. Predict movement after reading the gates.
- **Count movement by fitness and say so.** "362 rows moved" counted any
  changed field; 201 changed in fitness. Wording in the CHANGELOG then
  drifted from the measured classes to the plan's prediction and claimed
  no counterpoint with notes moved when the short ladder had. Write the
  CHANGELOG from the captured diff, not from the plan.
- **A comment that enumerates fixtures rots when fixtures are added.** The
  paragraph above the diminution fixtures listed which figures enter after
  a half rest and which cantus they sit on, and eleven new entries made
  both claims false without any test noticing. Review caught it; the
  reviewer's other catches were the same kind, prose that summarised code.
- **Copying `SustainAcrossBarlines`'s span methods was the plan's choice**,
  and it left three identical methods in two guidelines. The next guideline
  that needs the voice's own span should extract the module instead.
