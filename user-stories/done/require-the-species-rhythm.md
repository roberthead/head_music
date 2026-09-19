<!--
metadata:
  created_at:   2026-08-20T09:34:46-07:00
  activated_at: 2026-09-18T14:50:10-07:00
  planned_at:   2026-09-18T15:46:25-07:00
  finished_at:  2026-09-18T21:10:48-07:00
  updated_at:   2026-09-18T21:10:48-07:00
-->

# Require the Species Rhythm

AS a student submitting a species counterpoint exercise

I WANT every species guide to have at least one guideline that requires the
rhythm the species teaches

SO THAT a first-species line handed to a fourth-species guide loses credit for
never syncopating, rather than earning a near-perfect grade for breaking none of
the rules it had no opportunity to break

Split out of [Extract the Harmonic Cores](../done/extract-the-harmonic-cores.md),
which found this while measuring. Originally drafted as "Tell the Species
Apart"; narrowed on 2026-09-18 once the composites were measured.

## What was measured

The thirteen Fux first-species counterpoint voices, graded against each species
melody guide and each species composite (melody plus harmony), before any
change:

| Guide | Melody guide | Composite |
| --- | --- | --- |
| first_species | 0.997 | 0.990 |
| second_species | 0.563 | 0.746 |
| third_species | 0.563 | 0.746 |
| third_species_triple_meter | 0.563 | 0.746 |
| fourth_species | 0.986 | 0.988 |
| fifth_species | 0.561 | 0.745 |

The earlier draft measured only the harmony guides, where a first-species line
scores 1.000 against `ThirdSpeciesHarmony` because every dissonance-treatment
item passes vacuously. That is real but not the defect: a student's submission is
graded by the composite, and the melody primaries (`TwoPerBar`, `FourPerBar`,
`ThreePerBar`, `MixedRhythmicValues`) already discount a first-species line by a
quarter for second, third, triple-meter, and fifth species.

## The gap: fourth species

`FourthSpeciesMelody` declares one primary, `OneToOneWithTies`, which marks a
cantus firmus note only when zero or more than two counterpoint notes sound
against it. It never requires a tie. A plain first-species line passes it, so
the fourth-species composite grades that line at 0.988 -- indistinguishable from
first species -- when the entire lesson of fourth species is syncopation.

## Decisions

- **Species rhythm belongs to the melody guides.** The harmony guides teach
  dissonance treatment and do not check rhythm. This story does not add rhythm
  items or gates to any harmony guide, and `OneToOne` stays where it is in
  `FirstSpeciesHarmony`.
- **Primary tier, not a gate.** A student who submitted the wrong species still
  wrote a melody, and the craft rules still apply. The rhythm items stay
  primary, where a miss costs a share of the grade rather than all of it.
- **This is not species detection.** The gem does not need to take a melody and
  say which species it is. It needs each species guide to insist on its own
  rhythm.

## Scope

- Add `SustainAcrossBarlines` to `FourthSpeciesMelody`'s primary tier. It
  examines the downbeat of every bar strictly between the voice's first and
  last note bars and treats a bar as sustained when the note sounding at its
  downbeat began before that downbeat, whichever way the tie is notated. Up to
  25% of those bars (rounded down) may break the syncopation; each further
  break is one default-fitness mark.
- Record in `SpeciesHarmony`'s comment that harmony guides deliberately do not
  check rhythm, and where that check lives.
- Add a valid fourth-species example from Fux to `spec/spec_helper.rb`, so the
  new guideline has a line it must pass.
- Add second, third, and fifth species examples from Fux, and a constructed
  triple-meter line labeled as such, alongside the existing first-species sets.
  Wire them into `GuideGrading::PUBLISHED_SOURCES` so the corpus snapshot covers
  every species the registry has a composite for.
- Fixtures for species two through five are ABC text built by a new
  `FlowContext.from_abc`. Ties across the barline are written as Fux wrote
  them: the ABC parser now carries a tie over a bar line into one sustained
  placement, where it used to raise. One example per species on the D dorian
  cantus firmus in this story; the other cantus firmi are a follow-up.
- Pin the diagonal with a spec: for each species composite, its own fixture
  grades at least as high as a fixture of any other species.

## Out of scope

- Harmony-side rhythm checks, gates, or a "not applicable" outcome for
  guidelines with nothing to judge. The composite already answers the question
  those were meant to answer.
- The `Contoured` floor, which is a separate problem with its own story:
  [Lower the Contour Floor](../backlog/lower-the-contour-floor.md).

## Acceptance Criteria

- Each valid Fux first-species fixture scores at most 0.75 on
  `fourth_species_melody` and at most 0.85 on the `fourth_species` composite,
  down from 0.986 and 0.988.
- The Fux fourth-species fixture is adherent on `SustainAcrossBarlines` and
  scores at least 0.95 on `fourth_species_melody`.
- Among fixtures with no expected messages, for each composite except
  `first_three_species`, every fixture of its own species grades at least as
  high on the composite, and on its melody guide, as every fixture of any other
  species. `first_three_species` is a union guide with no species of its own
  and is excluded by name in the spec. One exception is accepted: on the
  `fifth_species` composite, Fux figure 82 grades below figure 73 because
  `SuspensionTreatment` rejects the delayed resolution in its bar 9. That cell
  is pending in the diagonal spec and is closed by
  [Embellish Fifth Species Suspensions](../backlog/embellish-fifth-species-suspensions.md).
- The corpus contains valid example lines for every species the registry has a
  composite for, and the harmony row count in the pinned snapshot rises above
  the current 38.
- `SpeciesHarmony` states in its comment that species rhythm is checked by the
  melody guides.

## Notes

Fux gives worked examples for second, third, fourth, and fifth species in the
same chapter the first-species fixtures came from. Every Fux transcription is
labeled by figure number in the Mann translation. Triple-meter third species is
not in Fux, so that fixture is constructed; its source names the cantus firmus
it is built on and says it is not in Gradus.

## Learnings

- **Measure the composite before believing a harmony-only number.** The
  story arrived claiming every species guide was blind to species. Grading
  the first-species voices against the composites showed four of six were
  already discounting a wrong-species line by a quarter through their melody
  primaries. One probe script turned an epic into a one-guideline story.
- **Ask what the requirement is before designing detection.** Rob's reframing,
  that a guide only needs to insist on its own rhythm rather than identify a
  submission's species, dissolved the gate-versus-primary debate and the
  "not applicable" outcome idea in one sentence.
- **The source was on disk.** Mann's translation was a scanned PDF in Rob's
  documents. Reading it at up to 1200 dpi got the interval figures, and the
  kern transcriptions in MarkGotham/species, keyed by the same figure numbers,
  settled the one accidental the scan could not. Transcribing from memory
  would have produced misattributed fixtures.
- **A fixture format must not fight the guides.** The plan's overflow spelling
  for ties made dotted values that the fifth-species rhythm guideline marks.
  Teaching the ABC parser to carry a tie across a bar line was the smaller,
  truer change, but it had consequences the first pass missed: repeat tagging
  read bar numbers from placed notes, and the writer could not write what the
  parser now read. The review caught both; the lesson is that lifting a
  "not yet supported" guard means auditing every consumer of the state it
  protected.
- **The diagonal spec earns its cost.** It found nothing wrong with the
  rhythm work, and everything wrong with fifth-species suspensions. That is
  what a cross-species matrix is for. Keep it, and let a pending cell name
  the story that closes it.
- **Verify agent numbers, and your own.** The planner's locale claim was
  right and the brief's was wrong; the reviewer's timing was right and my
  "about two seconds" was not. Every number that went into the story was
  re-measured before it was written down.

## Review

Reviewed 2026-09-18 at commit `aeacd55` by the product-manager (acceptance
verification) and code-reviewer agents; the two high findings were confirmed
by hand. Nothing uncommitted. `bundle exec rake`: 8305 examples, 0 failures,
1 pending. Rubocop clean.

### Acceptance criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | First-species fixtures at most 0.75 on `fourth_species_melody` and 0.85 on the composite | ✅ met | Re-measured over the ten valid fixtures: melody 0.677 to 0.708, composite 0.800 to 0.842. Pinned in `guide_species_diagonal_spec.rb` and `fourth_species_melody_spec.rb`. |
| 2 | Fux fourth-species line adherent on `SustainAcrossBarlines`, at least 0.95 on the melody guide | ✅ met | Adherent with zero marks; melody guide 0.999. The line's one break (bar 6) is inside the two-bar allowance. |
| 3 | Own-species fixture grades at least as high as any other, on the composite and the melody guide | ⚠️ partially met | Melody guides hold for all six species. Composites hold for five. Fifth species fails: Fux figure 82 scores 0.891 against figure 73's 0.929, because `SuspensionTreatment` marks the delayed resolution in bar 9. That example is `pending` and the cause has its own story, [Embellish Fifth Species Suspensions](../backlog/embellish-fifth-species-suspensions.md). The criterion as written says "every", so the story cannot be closed against it unamended. |
| 4 | Corpus covers every species with a composite; harmony rows rise above 38 | ✅ met | The diagonal spec asserts the fixture table equals the composite keys minus `first_three_species`. For each of the seven harmony guides, assessable published-source rows went 38 to 48; total rows 4320 to 4620, no error rows; pre-existing rows moved only under the two fourth-species guides. |
| 5 | `SpeciesHarmony` says species rhythm is the melody guides' concern | ✅ met | `species_harmony.rb` lines 14 to 19. |

### Code review findings

**High: blocks finish.**

1. **Repeat flags land on the wrong bar when a tie is open at a bar line.**
   `parser.rb` still calls the repeat tagger after skipping the flush, and
   the tagger reads bar numbers from the voice's last placement, which now
   lags by one. Confirmed: `C2 D2-|:D2 E2:|G4|]` marks bar 1 as starting the
   repeat instead of bar 2. This turned a loud parse error into silently
   wrong structure. Fix by tagging from a bar counter the parser keeps
   itself, or by keeping the rejection when the bar line carries a repeat
   style. Related: `handle_volta` still rejects an open tie with "must be
   followed by a note", which now misleads.
2. **The writer emits an over-long bar for a tie that crosses a bar line.**
   `duration_writer.rb` collapses a tie chain into one multiplier, which was
   safe only while the parser could not produce a cross-bar tie. Confirmed:
   `C2 D2-|D2 E2|]` writes back as `C4 D8|E4|]` under `L:1/8`, a twelve-eighth
   bar. The story's "never round-trip these flows" risk is not enforced. Fix
   by splitting the value at the bar line and emitting `-`, or raising when a
   placement spans a bar boundary.

**Medium.**

3. **`SustainAcrossBarlines` forgives the earliest breaks and marks the later
   ones**, so which bars a student sees flagged is positional rather than
   musical. `SecondSpeciesBreak` handles the same tolerance with one mark
   spanning all break bars at the small penalty once the ratio is exceeded.
   Matching that shape would make the two rules consistent.
4. **Accidentals do not survive a tie across a bar line.** The second note is
   resolved after the bar's accidental reset, so `^D2-|D2` raises "must
   connect two notes of the same pitch". Confirmed. The fixtures repeat
   `_B` and `^c` to sidestep it. Most ABC tools carry the accidental; either
   do that or say so in the parser comment, which currently claims the reset
   cannot reach the tie.
5. **The `reject_open_tie` comment** still points at `handle_bar_line`, now
   the one terminator that does not call it.
6. **The diagonal spec is slow**: 27 seconds for 17 examples, because every
   example re-parses all six fixture sets and re-assesses them. Build the
   voices once and compute one fitness matrix per guide kind.
7. **Duplicate assertions** between `fourth_species_melody_spec.rb` and the
   `describe "fourth species"` block of the diagonal spec; the guideline
   adherence example belongs in `sustain_across_barlines_spec.rb`.

**Low.**

8. The `.sub` that swaps the cantus firmus for the 3/4 fixture is fragile; a
   `cantus_firmus:` keyword on `fux_dorian_abc` removes the coupling.
9. Every fixture is titled `T:Fux`, including the constructed line;
   `from_abc` also skips the flow-naming rule `from_params` applies.
10. The new require sits between `one_to_one_with_ties` and
    `prefer_contrary_motion` rather than after `suspension_treatment`.
11. The `SpeciesHarmony` comment enumerates melody primaries and is already
    incomplete (omits `FirstBarHalfNotes`, `AllowFifthSpeciesRhythmicValues`).
    The first sentence carries the why; the roster will rot.
12. Second- and third-species fixtures open on the downbeat with no rest,
    which matches figures 33 and 55 in Mann but differs from the fourth- and
    fifth-species fixtures; a one-line note would stop a future "fix".
13. Small spec issues: the `expected_messages` branch in `from_abc` is dead;
    one context places overlapping wholes at 10:3 and 11:1; the solo-voice
    context still builds an unused cantus firmus.

### Outcomes

Applied 2026-09-18 after the review, at the user's direction. Criterion 3 was
amended to name the fifth-species exception.

1. **Fixed.** `VoiceState#completed_bar_number` and `entered_bar_number` now
   count from where the last note ends, including a pending tied note, so
   repeats and voltas after a tied bar line tag the right bar. Counting from
   the end also corrects a note longer than its bar, which was miscounted
   before this story. `handle_volta` keeps a tied note pending like
   `handle_bar_line`. Three parser specs cover repeat, volta, and accidental.
2. **Fixed.** The writer splits a placement at each bar line it crosses and
   ties the pieces, so `z2 ^F2-|F4-|F2 E2` writes back as
   `z4 ^F4-|^F8-|^F4 E4` and re-parses to the same placements. In-bar tie
   chains still collapse to one multiplier.
3. **Fixed, but not the sibling's shape.** Once breaks exceed the allowance,
   every bar entered without a ligature is marked, so the flagged bars no
   longer depend on where the free ones fell. `SecondSpeciesBreak`'s single
   small-penalty mark was not copied: a lone mark at φ^-1/2 would grade a
   first-species line near 0.93 on the fourth-species melody guide and undo
   criterion 1. A first-species line now takes nine marks rather than seven.
4. **Fixed.** A tie carries its pitch across the bar line: the note after
   the line fuses onto the pending note when its letters and octaves match,
   so `^D2-|D2` is one D-sharp. The parser comment says so.
5. **Fixed.** The `reject_open_tie` comment names bar lines and voltas as
   the non-terminators and no longer cross-references `handle_bar_line`.
6. **Fixed.** The diagonal spec parses the fixtures once at load and grades
   each guide once into a memoized matrix; the examples read cells. It runs
   in about thirteen seconds, down from twenty; what remains is the cost of
   the composite assessments themselves.
7. **Fixed.** The fourth-species melody thresholds live only in
   `fourth_species_melody_spec.rb`, the guideline adherence example moved to
   `sustain_across_barlines_spec.rb`, and the diagonal spec keeps only the
   composite threshold.
8. **Fixed.** `dorian_species_abc` takes the cantus firmus from the params;
   the 3/4 fixture passes its own, with no substitution.
9. **Fixed.** The ABC title is the fixture's `source`, so the constructed
   line is no longer titled "Fux". `from_abc` takes the flow's name from the
   header rather than re-deriving it.
10. **Fixed.** The require sits after `suspension_treatment`.
11. **Fixed.** The `SpeciesHarmony` comment keeps the why and drops the
    roster of melody primaries.
12. **Fixed.** The fixture comment records that figures 33 and 55 open on the
    downbeat as printed, and that the notes were checked against the kern
    transcriptions.
13. **Fixed.** The dead `expected_messages` branch is gone; the
    whole-on-beat-three example ends with a half so nothing overlaps; the
    solo-voice example sits outside the cantus firmus context.

**Not taken.** A different Fux fifth-species figure was not substituted for
figure 82. Every fifth-species figure in Gradus uses embellished suspensions
somewhere, and the D dorian one keeps the comparison on rhythm rather than
cantus; the gap is the harmony guide's, and it now has a story.

**Also noted by the product manager.** A different Fux fifth-species figure
without a delayed resolution might have closed the fifth-species cell, at
the cost of the shared-cantus comparison; the Implementation Notes do not
say why that trade was not taken. The transcriptions' provenance is not
verifiable from the repository; spot-check figure 55 bar 8 (`_B A G _B`) and
figure 82 bar 8 (`f e/2 d/2 e2-`) against the kern if the source labels
matter.

## Implementation Notes

Implemented 2026-09-18, directly rather than through agents.

- **Transcriptions were checked against two sources.** Mann's translation
  is on disk as a scan, read at up to 1200 dpi for the interval figures and
  accidentals, and every line was then confirmed against the Humdrum kern
  files in MarkGotham/species, which are keyed by the same figure numbers.
  Figure 55 bar 8 ends on B-flat, which only the kern made certain.
- **The ABC parser learned ties across bar lines** instead of the fixtures
  spelling a tied note as an overflowing whole. The overflow spelling turned
  a half tied to a quarter into a dotted half, which
  `AllowFifthSpeciesRhythmicValues` marks, so it could not carry the fifth
  species fixture. The change is one guard in `handle_bar_line`: a pending
  tied note is left pending across the bar rather than flushed.
- **Fifth species is the one cell the diagonal does not yet close.** The
  melody diagonal holds for every species. On the composite, Fux's florid
  line (0.891) loses to his fourth-species line (0.929) because
  `SuspensionTreatment` marks the delayed resolution in bar 9, a fifth-species
  idiom the reference documents. That example is pending in the diagonal
  spec and the gap has its own story,
  [Embellish Fifth Species Suspensions](../backlog/embellish-fifth-species-suspensions.md).
- **Snapshot movement matches the plan.** Rows 4320 to 4620, no errors,
  pre-existing rows changed only under `fourth_species_melody` and
  `fourth_species`, and distinct published voices a harmony guide can assess
  rose from 38 to 48.
- **Only `en.yml` carries the new strings.** The other locales hold entries
  only for sentences that name note values and fall back to English.

## Implementation Plan

Planned 2026-09-18 with the story-planner (product-manager and developer).
No UI, so no designer or accessibility review.

### Overview

Add one primary guideline, `SustainAcrossBarlines`, to `FourthSpeciesMelody`.
It uses the held-into-the-downbeat predicate `SuspensionTreatment` already
relies on (the note sounding at a downbeat began before it) and tolerates
breaks up to the 25% ratio `SecondSpeciesBreak` allows. Add one Fux example
per species (two through five) plus a constructed 3/4 line as ABC text through
a new `FlowContext.from_abc`, wire them into the corpus, pin the species
diagonal in one spec, and regenerate both snapshots once at the end.

The developer prototyped the guideline against the real guides: Fux figure 5
(first species) drops from 0.982 to 0.683 on `fourth_species_melody` and from
0.991 to 0.827 on the `fourth_species` composite. A syncopated line scores 1.0
on the guideline whether written as a whole note on beat 3 or as
`"half tied to half"`.

### Steps

1. **Add the `SustainAcrossBarlines` guideline.**
   `lib/head_music/style/guidelines/sustain_across_barlines.rb`, required in
   `lib/head_music.rb` directly after `one_to_one_with_ties`.
   - Name: "sustain" is already the gem's phrase in the `one_to_one_with_ties`
     strings. `TieAcrossBarlines` names notation the analysis ignores
     (references/fourth-species-counterpoint.md section 6);
     `SuspendIntoDownbeats` implies dissonance, and a tied consonance is
     legitimate fourth species.
   - Rule: examine the downbeat of every middle bar of the voice's own span
     (bars strictly between the voice's first and last note bars). A bar is
     sustained when `voice.note_at(downbeat)` exists and began before the
     downbeat. Bar 1 (half rest, entry on beat 3) and the final bar (whole
     note) are never examined; bar 2 is, so the beat-3 entry must hold into
     it. Two independent halves at `k:3` and `k+1:1` are a re-attack and count
     as a break.
   - Tolerance: `MAX_BREAK_RATIO = 0.25`, overridable through
     `options[:max_break_ratio]` as `SecondSpeciesBreak` does. The first
     `(middle_bars.length * ratio).floor` unsustained bars are free; each
     further one is a default-fitness mark. On the 11-bar Fux cantus that is 9
     middle bars, 2 free: a first-species line takes 7 marks
     (0.618^7 = 0.034), a fourth-species line with up to two breaks is
     adherent.
   - Mark target: the counterpoint notes in that bar, or a bar-spanning mark
     from `b:1` to `b+1:1` when the bar is empty (the shape
     `Guideline#no_placements_mark` uses), so no cantus firmus is needed.
   - Voice-span middle bars rather than `NoteCountPerBar`'s cantus-firmus
     middle bars, so a solo first-species line is graded too instead of
     passing vacuously. The count guidelines keep their vacuous solo pass; see
     Risks.
   - Sketch:

     ```ruby
     def marks
       return [] if notes.empty?
       excess_breaks.map { |bar_number| mark_bar(bar_number) }
     end

     def excess_breaks
       breaks = middle_bar_numbers.reject { |bar| sustained_into?(bar) }
       breaks.drop((middle_bar_numbers.length * max_break_ratio).floor)
     end

     def sustained_into?(bar_number)
       downbeat = HeadMusic::Content::Position.new(flow, "#{bar_number}:1")
       held = voice.note_at(downbeat)
       held && held.position < downbeat
     end
     ```

2. **Declare it primary in fourth species.**
   `lib/head_music/style/guides/fourth_species_melody.rb`:
   `primary_items(OneToOneWithTies, SustainAcrossBarlines)`. `OneToOneWithTies`
   stays; it catches empty bars and three-plus notes per bar, which the new
   guideline ignores.

3. **Add the English strings.** `lib/head_music/locales/en.yml`, under
   `head_music.style.guidelines.sustain_across_barlines`, alphabetically after
   `suspension_treatment`:
   - name: "Sustained across the barline"
   - instruction: "Begin each note on the weak beat and hold it across the
     barline into the next downbeat, breaking the syncopation only rarely."
   - violations.default: "Sustain a note across the barline into most
     downbeats, breaking the syncopation only rarely."

   Only `en.yml` is needed. Verified: de, es, fr, it, and ru carry six
   guideline keys and en_GB ten, only for sentences that name note values, and
   every locale falls back to en. The strings above avoid whole/half vocabulary
   so the note-vocabulary sweep in `guide_strings_spec.rb` passes without an
   en_GB entry. If the wording changes to name a note value, en_GB needs a
   minim/semibreve entry.

4. **Record the rhythm decision in `SpeciesHarmony`.**
   `lib/head_music/style/guides/species_harmony.rb`, one or two sentences in
   the existing comment near `HARMONIC_GATES`: the rhythm a species teaches is
   checked by its melody guide's primaries (`OnePerBar`, `TwoPerBar`,
   `SustainAcrossBarlines`, and so on); a harmony guide judges the dissonance
   treatment that rhythm makes possible, never the rhythm itself.

5. **Add `FlowContext.from_abc`.** `spec/flow_context.rb`. Builds the flow with
   `HeadMusic::Notation::ABC.parse(params[:abc])` and passes `source:` and
   `expected_messages:` through as `from_params` does. `from_params` is
   untouched, so no existing corpus row moves for fixture reasons.
   - Verified against the parser: `V:cantus firmus` declared first yields a
     role matching `Voice#cantus_firmus?` and keeps v0/v1 row labels; `K:Ddor`
     resolves the tonic; `M:3/4` sets the meter; a whole note after a half
     rest is placed at `1:3` and sounds through `2:1`, and the next whole note
     lands at `2:3`. That is the representation
     `fourth_species_melody_spec.rb` already uses.
   - Fallback if the overflow-whole spelling is judged too opaque: a
     `counterpoint_sequence: [[:half, nil], ["half tied to half", "A4"], ...]`
     key placed with `voice.place(voice.next_position, ...)`, also verified.
     Decide before step 6.

6. **Transcribe the fixtures and wire the corpus.**
   `spec/spec_helper.rb` directly after `FUX_FIRST_SPECIES_EXAMPLES`, keeping
   every species beside the cantus firmi Fux reuses:
   `FUX_SECOND_SPECIES_EXAMPLES`, `FUX_THIRD_SPECIES_EXAMPLES`,
   `FUX_FOURTH_SPECIES_EXAMPLES`, `FUX_FIFTH_SPECIES_EXAMPLES`, and
   `THIRD_SPECIES_TRIPLE_METER_EXAMPLES`, each `{source:, abc:}` built with
   `from_abc`, with unmemoized accessor methods like
   `fux_first_species_examples`.
   - One example per species, counterpoint above the D dorian cantus
     `D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4` (the first exercise of each Fux
     chapter), `source: "Fux chapter N figure M"` in Mann's numbering. Holding
     the cantus constant makes the diagonal compare rhythm rather than cantus.
     Each two-voice fixture adds 60 snapshot rows. The other cantus firmi are
     a follow-up.
   - Constructed line: `source: "Constructed triple-meter third species on
     Fux's D dorian cantus firmus; not in Gradus"`, `M:3/4`, final bar `d3`.
   - ABC notes (`L:1/4`): second species halves `d2 c2|`; fourth species entry
     `z2 A4|d4|`, ending `...|^c2|d4|]` (the penultimate bar's text holds only
     the beat-3 half because the previous whole already covers its downbeat);
     fifth species eighths as `A/2` or `L:1/8` for that fixture. ABC octave
     marks are required (`d` is D5, `A,` is A3).
   - Add the five accessor names to `GuideGrading::PUBLISHED_SOURCES`
     (`spec/support/guide_grading.rb`).

7. **Write the specs and bump the canaries.**
   - `spec/head_music/style/guidelines/sustain_across_barlines_spec.rb`,
     modeled on `one_to_one_with_ties_spec.rb`; cases under Testing.
   - `spec/head_music/style/guides/fourth_species_melody_spec.rb`: add the
     `include SustainAcrossBarlines` specify and two fitness contexts.
   - `spec/head_music/style/guide_species_diagonal_spec.rb`: a literal table
     from composite key to fixture method for the six species composites.
     Assert `table.keys.sort == (COMPOSITE_MEMBERS.keys - ["first_three_species"]).sort`
     so a new composite fails here until it has a fixture. Use valid fixtures
     only (`reject { |context| context.expected_messages.any? }`; three
     first-species entries carry deliberate errors). Grade `counterpoint_voice`
     only. Per fixture, not mean: for each composite,
     `own.map(fitness).min >= others.map(fitness).max`, asserted for the
     composite and again for the melody guide. About 90 composite grades.
   - Canaries: `spec/head_music/style/guide_strings_spec.rb` items 67 to 68;
     add a `SustainAcrossBarlines` row next to `OneToOneWithTies` in
     `spec/head_music/style/guide_item_strings_spec.rb`.

8. **Regenerate both snapshots once, then lint and run.**
   `bundle exec rake style:snapshot_english`, then
   `bundle exec rake style:snapshot_corpus_fitness`. Review the JSON diff:
   pre-existing rows should move only under `fourth_species_melody` and
   `fourth_species` (solo rows included, by design of step 1); rows go 4320 to
   4620 (5 fixtures x 2 voices x 30 guides); assessable harmony rows from
   published sources go 38 to 48; no row may carry an `error` key. Then
   `bundle exec rubocop -a` and `bundle exec rake`.

### Testing

- Guideline spec: empty voice and solo voice do not raise; Fux figure 5
  first-species line takes 7 marks, fitness within 0.001 of 0.618^7;
  whole-on-beat-3 line adherent; `"half tied to half"` line adherent (both
  representations count); two untied halves in one bar count as a break; three
  breaks in nine middle bars yield exactly one mark; `max_break_ratio: 0` marks
  every break; a two-bar voice has no middle bars and no marks; an empty bar
  inside the span is a break and is marked without raising.
- Guide spec: the first Fux first-species counterpoint grades below 0.75 on
  `FourthSpeciesMelody` (measured 0.683); the Fux fourth-species counterpoint
  grades above 0.95 and is adherent on the guideline itself.
- Diagonal spec as in step 7. The constructed triple-meter line must clear
  `ThreePerBar` and `TripleMeterDissonanceTreatment` on its own composite or
  the diagonal says so.
- Corpus spec needs no code change; the regenerated baseline is the assertion.
- Never assert on stdout.

### Risks

- **Transcription accuracy is the critical path.** A sloppy improvised
  second-species line scored 0.678 on `second_species` against 0.748 for the
  first-species line, which would fail the diagonal. Expect a round of
  correcting transcriptions; the diagonal is doing its job. Mann's figure
  numbers for the chapter two through five D dorian examples must be confirmed
  while transcribing.
- **Break tolerance.** 25% of middle bars (chosen) versus one per line. Both
  give identical results for a first-species line; the ratio reuses
  `SecondSpeciesBreak`'s constant and scales with length. If Fux's example
  contains three breaks, revisit the ratio or the example.
- **Overflow whole notes rely on parser leniency.** The ABC parser does not
  validate bar fill; if it ever does, the fourth-species fixture should switch
  to the `counterpoint_sequence` fallback. Never round-trip these flows through
  `to_abc`. The fixture's source string should say the whole notes stand for
  tied halves.
- **Voice-span versus cantus-firmus middle bars.** `OnePerBar`, `TwoPerBar`,
  and `FourPerBar` still pass a solo voice vacuously while the new guideline
  does not. Making the count guidelines use the voice's span is a small
  follow-up.
- **Resolution timing is unchecked.** A downbeat note held from the previous
  bar that ends before beat 3 passes the new guideline; where a suspension
  resolves is dissonance treatment on the harmony side. Whether
  `FourthSpeciesHarmony` already requires resolution on beat 3 was not
  confirmed.
- **`first_three_species`** has no species of its own and is excluded from the
  diagonal by name.
- **Contour floor story** shares only `corpus_fitness.json`; whichever lands
  second regenerates after rebasing.
