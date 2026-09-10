<!--
metadata:
  created_at:   2026-09-09T12:17:16-07:00
  activated_at: 2026-09-09T13:54:03-07:00
  planned_at:   2026-09-10T11:25:28-07:00
  finished_at:
  updated_at:   2026-09-10T11:25:28-07:00
-->

# Improve Melodic Contour Guidelines

AS a student writing a melody against a target contour

I WANT the arch and valley contours to describe the shape of the whole line

SO THAT a melody that rises a third, plunges a sixth, and climbs back is told it
is not an arch, rather than passing the exercise's one requirement at 100%

Found on bardtheory's "Compose a Melody with an Arch Contour" exercise on
2026-09-09, while walking through the new exercise rubrics.

## The defect

`Contoured#arch?` checks one thing: the highest pitch is neither the first nor
the last note (`endpoints_interior_to?`, `contoured.rb:58-70`). `valley?` is
the mirror. The comment says "rise then fall reduces to both endpoints sitting
below the climax." It does not: that admits any line whose peak is somewhere in
the middle, whatever happens on either side of it.

Measured against the gem on 2026-09-09:

| Melody | arch | valley | wave | trends |
| --- | --- | --- | --- | --- |
| C4 D4 E4 D4 B3 A3 G3 B3 C4 (the submission) | pass | pass | pass | up, down, up |
| C4 D4 E4 F4 G4 A4 G4 F4 E4 D4 C4 | pass | fail | fail | up, down |
| C4 D4 E4 D4 E4 F4 G4 F4 E4 D4 C4 (neighbor dip) | pass | fail | fail | up, down |
| G4 F4 E4 D4 C4 D4 E4 F4 G4 | fail | pass | fail | down, up |
| C4 E4 G4 F4 E4 D4 C4 B3 C4 | pass | pass | fail | up, down |

The first line satisfies three contours at once. Its peak E4 is interior, so
it is an arch; its lowest note G3 is interior, so it is a valley; it reverses
direction three times by more than a whole step, so it is a wave. Only the
arch row shows in the app, because that is what the exercise asked for.

The gem already has the right instrument. `trend_directions`
(`contoured.rb:92`) walks the line and records a direction change only once
the melody retraces `TREND_REVERSAL_SEMITONES` (3) from its running extreme,
so neighbor-note undulation is not a trend change. `wave?` uses it; `arch?`
and `valley?` do not.

## Acceptance Criteria

- `arch?` is true only when the trend directions are exactly ascending then
  descending, and the endpoint check still holds (a line cannot start or end on
  its peak).
- `valley?` is the mirror: exactly descending then ascending, endpoints above
  the trough.
- The submission above fails arch and valley and passes only wave.
- The three genuine arches and the valley in the table keep their verdicts,
  including the arch with a neighbor-note dip on the way up.
- Arch, valley, and wave are mutually exclusive for any melody with three or
  more notes; a spec states this over a set of shapes rather than one example.
- The registered contour guides (`arch_contour_melody` and the rest) and their
  `minimum_melodic_intervals` gates are unchanged.
- The violation sentence for arch and valley still reads correctly for the new
  failure: a student whose line waves is told to "rise to a single peak, then
  descend", or whatever the locale says today, and that sentence is not made
  worse.
- CHANGELOG entry under the next release, noting that some melodies previously
  graded as arch or valley now grade as wave.

## Notes

**Ending approach.** A closing step against the final trend (…D4 C4 B3 C4,
the 7→1 approach) is under the 3-semitone reversal threshold, so the arch still
reads as up-down. That is the intended behavior and a spec should pin it. The
threshold stays a constant.

**Check the corpus before changing the rule.** bardtheory's contour exercises
have stored submissions graded under the old predicate; a sweep of the pinned
melody corpus (or a handful of Fux lines used as free melodies) shows how many
verdicts flip. Record the count in the story.

**Release.** bardtheory pins `~> 20.0` but will be upgraded to `~> 21.1` to
land this (and the previous refactoring).

**Related.** bardtheory's `user-stories/done/exercise-specific-rubrics.md`
records the walkthrough that surfaced this, and its Scope Boundaries name a
follow-up gem story for exercise guidelines (EndOnScaleDegree, tendency-tone
resolutions). That story and this one both touch how a melody exercise's
primary requirement is judged.

**Decisions (2026-09-09).** Talked through before planning:

- Arch and valley become trend-based: trend directions exactly ascending then
  descending (or the mirror), plus the existing endpoint check.
- Ascending and descending keep their endpoint-only definitions. A line that
  goes up-down-up and ends on its peak is both ascending and a wave, and that
  is fine. Only arch, valley, and wave need to be mutually exclusive.
- Wave stays at three or more trends.
- The contour mark stays binary. No graded contour in this story.

## Implementation Plan

### Overview

Make `arch?` and `valley?` read the memoized `trend_directions` walk that
`wave?` already uses: an arch is exactly `[:ascending, :descending]`, a valley
exactly `[:descending, :ascending]`. Everything else (ascending, descending,
static, wave, the threshold constant, the registered guides, the locale
strings) is untouched. Two existing spec cases flip and are replaced, a
table-driven spec pins arch/valley/wave exclusivity, the corpus snapshot is
regenerated, and the flip count is recorded.

Measured during planning (2026-09-10) by patching the two predicates and
re-grading the pinned corpus: 79 of 4320 snapshot rows change, all under
`arch_contour_melody` (53) and `valley_contour_melody` (26). 70 are adherent
verdict flips, all true to false: 47 of 63 previously adherent arch rows and
23 of 26 valley rows. No wave row and no other guide moves. The other 9 changed
rows are already-failing voices whose fitness drops because the contour mark
now lands on top of other faults. Reproduce these numbers in step 4.

### Steps

1. **Rewrite the two predicates** in `lib/head_music/style/guidelines/contoured.rb`.

   ```ruby
   def arch?
     trend_directions == %i[ascending descending]
   end

   def valley?
     trend_directions == %i[descending ascending]
   end
   ```

   Delete the comment above `arch?` ("The climax is the maximum by
   definition..."). It states the reasoning the story identifies as wrong, and
   the reversal threshold is already explained above `trend_directions`.

   Delete `endpoints_interior_to?` and its comment. The endpoint check is
   redundant once the trends are exactly two: the first ascending trend fires
   on a pitch at least 3 semitones above the seek-phase low, and the seek phase
   would have started a descending trend first if any earlier pitch sat 3 or
   more below the first note, so the peak exceeds the first note. The
   descending leg's extreme sits at least 3 below the peak, so any return to
   the peak starts a third trend, and the last note is below it. Two notes
   yield at most one trend, so the `notes.length >= 3` guard is implied. The
   "climax at the last note" and "nadir at the last note" contexts keep the
   endpoint claim pinned. Keeping the guard is harmless but a comment would
   then have to say it is redundant, or the next reader preserves it as
   load-bearing.

2. **Update `spec/head_music/style/guidelines/contoured_spec.rb`.** All ABC
   strings below were run against the walk with the spec's existing header
   (`X:1 M:4/4 L:1/4 K:C`); trends and verdicts are as stated.

   Arch context. Keep "with a single interior climax" (`CDEG|EDC2|`) and "with
   the climax at the last note" (`CDEF|G4|`). Change "with a repeated interior
   climax" from `CDGE|GEDC|` to `CDEG|GEDC|` (C4 D4 E4 G4 G4 E4 D4 C4, trends
   up/down): the old melody's G to E dip is 3 semitones and now reads as four
   trends. The adjacent repeat keeps the sibling "leaves climax multiplicity to
   ConsonantClimax" example true. Add:

   | Context | ABC | Pitches | Trends | Expect |
   | --- | --- | --- | --- | --- |
   | with a long rise and fall | `CDEF\|GAGF\|EDC2\|` | C4 D4 E4 F4 G4 A4 G4 F4 E4 D4 C4 | up, down | adherent |
   | with a neighbor-note dip on the way up | `CDED\|EFGF\|EDC2\|` | C4 D4 E4 D4 E4 F4 G4 F4 E4 D4 C4 | up, down | adherent |
   | with a closing step against the descent | `CEGF\|EDCB,\|C4\|` | C4 E4 G4 F4 E4 D4 C4 B3 C4 | up, down | adherent; pins the ending-approach note |
   | with a rise, a plunge, and a climb back | `CDED\|B,A,G,B,\|C4\|` | C4 D4 E4 D4 B3 A3 G3 B3 C4 | up, down, up | not adherent; fitness `GOLDEN_RATIO_INVERSE**2`; `marks_count` 1 |

   Valley context. Keep "with an interior nadir" (`GFEC|DEFG|`) and "with the
   nadir at the last note" (`GFED|C4|`). Change "with a repeated interior nadir"
   from `cAEG|EGAc|` to `GFEC|CDEG|` (trends down/up; ConsonantClimax still not
   adherent, so the sibling example stands). Add:

   | Context | ABC | Trends | Expect |
   | --- | --- | --- | --- |
   | with a fall and rise between the same pitch | `GFED\|CDEF\|G4\|` | down, up | adherent |
   | with a rise, a plunge, and a climb back | `CDED\|B,A,G,B,\|C4\|` | up, down, up | not adherent |
   | with an arch whose close dips below its opening | `CEGF\|EDCB,\|C4\|` | up, down | not adherent (passes valley today; this is the regression pin) |

   Wave context. Add "with a rise, a plunge, and a climb back"
   (`CDED|B,A,G,B,|C4|`), adherent. Existing wave examples are unaffected.

   Exclusivity. Add a table-driven block asserting the exact set of matching
   contours rather than "at most one": the exact set also documents the rows
   that match none of the three. One context per shape gives a named failure.
   Do not add `:static` to the select; `EDEF|EFED|E4|` and `CEC2|` are both
   static and arch before and after, and the criterion scopes exclusivity to
   arch, valley, and wave.

   ```ruby
   describe "arch, valley, and wave" do
     shapes = {
       "a three-note arch" => ["CEC2|", :arch],
       "a long rise and fall" => ["CDEF|GAGF|EDC2|", :arch],
       "an arch with a neighbor-note dip on the way up" => ["CDED|EFGF|EDC2|", :arch],
       "an arch with a closing step against the descent" => ["CEGF|EDCB,|C4|", :arch],
       "an arch with a repeated climax" => ["CDEG|GEDC|", :arch],
       "a three-note valley" => ["ECE2|", :valley],
       "a valley" => ["GFED|CDEF|G4|", :valley],
       "a valley with a repeated nadir" => ["GFEC|CDEG|", :valley],
       "a rise, a plunge, and a climb back" => ["CDED|B,A,G,B,|C4|", :wave],
       "a three-leg wave" => ["CDED|CDE2|", :wave],
       "a wave of minor thirds" => ["DFDF|D4|", :wave],
       "a four-leg wave with a single peak" => ["CDED|CDEF|EDC2|", :wave],
       "a repeated climax a third apart" => ["CDGE|GEDC|", :wave],
       "undulation below the trend threshold" => ["CDCD|C4|", nil],
       "a line climaxing on its last note" => ["CDEF|G4|", nil]
     }

     shapes.each do |description, (shape, expected)|
       context "with #{description}" do
         let(:melody) { shape }
         let(:matching_contours) do
           %i[arch valley wave].select { |key| assess(described_class, voice, contour: key).adherent? }
         end

         it { expect(matching_contours).to eq Array(expected) }
       end
     end
   end
   ```

   Under the current code this table fails on the minor-third wave, the
   four-leg wave, the repeated climax a third apart, the sub-threshold
   undulation, and the submission, which is the defect made visible.

3. **Confirm the untouched specs stay green.** No edits expected.
   `spec/head_music/style/guides/contour_melody_spec.rb` pins keys, gates, and
   item counts, none of which move, and its analysis melodies are all up/down
   or down/up under the new rule. `spec/fixtures/style/english_strings.yml`
   is unchanged: the violation sentence stays "Write a melody with the
   %{contour} contour." and remains correct for a waving line. The
   `arch_contour_melody` instruction ("rises to a single peak and falls back")
   is now literally true rather than aspirational. No locale change.

4. **Regenerate the corpus snapshot and record the flip count.**

   - `bundle exec rspec spec/head_music/style/guide_corpus_fitness_spec.rb`
     first; expect the single `rows == baseline` failure.
   - `bundle exec rake style:snapshot_corpus_fitness`.
   - Count. Every flip is true to false and the snapshot is one row per line:

     ```bash
     git diff -U0 spec/fixtures/style/corpus_fitness.json | grep '^-{' | grep -c '"arch_contour_melody".*"adherent":true'    # expect 47
     git diff -U0 spec/fixtures/style/corpus_fitness.json | grep '^-{' | grep -c '"valley_contour_melody".*"adherent":true'  # expect 23
     git diff -U0 spec/fixtures/style/corpus_fitness.json | grep '^[-+]{' | grep -vE '"(arch|valley)_contour_melody"' | wc -l  # expect 0
     ```

   - Rerun the corpus spec; green.
   - Extend the "Check the corpus" paragraph under Notes with the measured
     counts.

5. **CHANGELOG entry** under `## [Unreleased]`:

   ```markdown
   ### Changed

   - **`Style::Guidelines::Contoured` judges arch and valley by the whole line.** An arch is now a melody whose trend directions are exactly ascending then descending, one rise past the reversal threshold and one fall, and a valley is the mirror. Before, an interior climax alone made an arch, so a line that rose a third, plunged a sixth, and climbed back passed arch, valley, and wave at once. Arch, valley, and wave are now mutually exclusive. Neighbor-note motion stays under the threshold, so an arch with a passing dip on the way up, or a 7-1 step at the close, still reads as an arch. **Some melodies previously graded as arch or valley now grade as wave**: in the pinned corpus, 47 of 63 arch verdicts and 23 of 26 valley verdicts flip, most of them published cantus firmi that rise and fall more than once. `ascending`, `descending`, `static`, and `wave` are unchanged, as are the registered contour guides and their gates.
   ```

   Leave the historical 20.x entry that describes the interior-climax rule as
   it is.

### Verification

- `bundle exec rspec spec/head_music/style/guidelines/contoured_spec.rb spec/head_music/style/guides/contour_melody_spec.rb spec/head_music/style/guide_strings_spec.rb`
- `bundle exec rspec spec/head_music/style/guide_corpus_fitness_spec.rb` (red before the snapshot, green after)
- `bundle exec rubocop -a`
- `bundle exec rake` for the full suite with coverage. Deleting
  `endpoints_interior_to?` removes lines rather than adding uncovered ones.

### Risks and Open Questions

- **Endpoint check: drop (planned) or keep.** The 2026-09-09 decision said
  "plus the existing endpoint check". Both the planner and a scratch
  verification found it redundant given the walk. The plan drops it to avoid
  a dead guard that reads as load-bearing. Keeping it would guard against a
  future change to the walk, at the cost of a check no spec can make fire.
- **Severity, not correctness.** 47 of 63 corpus arch verdicts flip,
  including Fux's own cantus firmi: with the threshold at 3 semitones, any
  line with two minor-third-or-larger reversals is a wave, so the arch
  exercise gets markedly stricter for a student writing a textbook-shaped
  line. The threshold stays a constant per the story; this is the number to
  see before committing to it.
- **Static overlaps arch and valley** (`EDEF|EFED|E4|`, `CEC2|`), unchanged
  by this work and outside the criteria.
- **CHANGELOG numbers** are accurate for the pinned corpus and will drift if
  the corpus changes. Keep them or make the entry qualitative.
