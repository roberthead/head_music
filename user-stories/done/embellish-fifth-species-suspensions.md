<!--
metadata:
  created_at:   2026-09-18T17:00:05-07:00
  activated_at: 2026-09-19T08:36:41-07:00
  planned_at:   2026-09-20T13:36:21-07:00
  finished_at:  2026-09-21T08:34:18-07:00
  updated_at:   2026-09-21T08:34:18-07:00
-->

# Embellish Fifth Species Suspensions

AS a student submitting a florid counterpoint exercise

I WANT a suspension whose resolution is delayed or decorated the way Fux
allows to be graded as a suspension, not as a fault

SO THAT Fux's own fifth-species example grades higher on the fifth-species
composite than a fourth-species line does

Found by [Require the Species Rhythm](../done/require-the-species-rhythm.md)
when Fux's chapter five figure 82 became a fixture.

## The defect

`SuspensionTreatment` accepts one shape: the held note resolves down by step
to a consonance as its very next note. Fifth species relaxes that.
`references/fifth-species-counterpoint.md` section 3.4.5 lists five
embellishments, and the reference's own guideline map proposes an
`EmbellishedSuspensionTreatment` to cover them:

1. Anticipated resolution on beat 2, repeated on beat 3.
2. Anticipated resolution decorated with an eighth-note lower neighbor.
3. Escape tone: a consonant step up on beat 2, then the resolution.
4. A consonant leap on beat 2, then the resolution.
5. Delayed resolution: one intervening consonance, then the resolution (Fux).

Fux figure 82, bar 9, is type 5: E5 held over F4 (a seventh), then A4 (a
consonant third), then D5 (the resolution) on beat 3. `SuspensionTreatment`
marks it. Bar 8 (F5 over G4, resolved to E5 then decorated E5 D5 E5) passes,
because the first note after the suspension is the resolution.

Measured on the story branch:

| Voice | fifth_species_melody | fifth_species_harmony | fifth_species |
| --- | --- | --- | --- |
| Fux figure 82 (fifth species) | 0.970 | 0.819 | 0.891 |
| Fux figure 73 (fourth species) | 0.881 | 0.981 | 0.929 |

The melody diagonal holds. The composite diagonal fails only because of the
harmony side, and `spec/head_music/style/guide_species_diagonal_spec.rb`
carries that one cell as pending with this story named in the reason.

Other marks on figure 82's harmony are secondary and arguably Fux's own
choices rather than gaps: `AvoidCrossingVoices` (bar 2 dips below the
cantus), `PreferContraryMotion` (seven marks on a florid line), and
`StartOnPerfectConsonance`, which treats the counterpoint as the bass voice
because its lowest note ties the cantus firmus's lowest note. Worth a look
while here, but the suspension is the one that moves the grade.

## Decisions

- **A separate guideline, not a configured `SuspensionTreatment`.** Decided
  2026-09-20. `EmbellishedSuspensionTreatment`, the name the reference
  proposes, is declared by `FifthSpeciesHarmony` in place of
  `SuspensionTreatment`. Fourth species keeps the strict rule untouched:
  it has no room for an intervening note, so a leap between suspension and
  resolution there is a genuine fault.

- **The resolution must sound on beat 3.** Decided 2026-09-20 after weighing
  Fux's count rule ("delay by one note") against Girton's position rule
  ("on the third quarter note, however embellished"). The note sounding on
  the bar's second strong beat must be a descending step from the suspended
  pitch and consonant; whether it was attacked there or on beat 2 and held
  does not matter. So the embellishment fits in beat 2 as a quarter or an
  eighth pair, a resolution first sounding on beat 4 is marked, and an
  anticipated resolution abandoned on beat 3 is marked. In 3/4, where no
  second strong beat exists, and wherever the cantus note is attacked off the
  downbeat or does not last to that beat (as when a cantus firmus is graded
  against a florid line), the strict fourth-species rule applies. Notes
  attacked between the suspension and beat 3 are judged by
  `FloridDissonanceTreatment`, not by this guideline.

## Acceptance Criteria

- Fux figure 82 is adherent on the fifth-species suspension guideline.
- Fux figure 82 grades at least as high on `fifth_species` as any fixture of
  another species, and the pending example in the diagonal spec is removed.
- A fourth-species line with a leap between suspension and resolution is
  still marked by `FourthSpeciesHarmony`.
- Given a dissonant held-over counterpoint note that was consonant at its
  own start, when the note sounding on the third beat of the cantus firmus
  note's bar is one step below the suspended pitch and consonant with the
  cantus firmus, `EmbellishedSuspensionTreatment` produces no mark, whatever
  sounds between the suspension and that beat.
- Each of the five shapes in `references/fifth-species-counterpoint.md`
  section 3.4.5 has an adherent spec example: anticipated resolution,
  anticipated resolution with an eighth-note lower neighbor, escape tone
  stepping up on beat 2, consonant leap down on beat 2 and back to the
  resolution, and Fux's delayed resolution.
- A plain fourth-species suspension (half suspension, half resolution on
  beat 3) is adherent on `EmbellishedSuspensionTreatment`.
- Each of the following is one mark on the suspended note: an unprepared
  suspension; a suspension left by leap whose resolution pitch never sounds
  on beat 3; a suspension resolving upward by step; a resolution first
  sounding on beat 4; a suspension held through the bar; an anticipated
  resolution on beat 2 followed by a different pitch on beat 3.
- Bars 8, 9 and 10 of figure 82 each produce no mark, including the bars 8
  and 9 chain where the beat-3 resolution is tied over to become the next
  suspension.
- A dissonant quarter leapt to from a suspension is marked by
  `FloridDissonanceTreatment` and not by `EmbellishedSuspensionTreatment`.
- `FifthSpeciesHarmony` declares `EmbellishedSuspensionTreatment` and no
  longer declares `SuspensionTreatment`; `FourthSpeciesHarmony` still
  declares `SuspensionTreatment`.
- Regenerating `spec/fixtures/style/corpus_fitness.json` changes only figure
  82's `fifth_species_harmony` and `fifth_species` rows.
- `FloridDissonanceTreatment`'s English strings no longer promise to prepare
  and resolve tied suspensions, which that guideline never sees.

## Learnings

- **Explain the choice before asking for it.** The beat-3 question stalled
  as a one-line option until it was laid out as three concrete rules with
  the shapes each accepts and marks. The decision then took one exchange, and
  it was the right one: every source that describes the embellishments keeps
  the beat-3 framework.
- **Prototype the rule in memory before writing the plan.** A dozen lines
  run against the real guides confirmed the planner's numbers (0.937 and
  0.953 against 0.929) before anything was committed to the story. Numbers
  that go into a story should be re-measured, not relayed.
- **The corpus snapshot is a better reviewer than it looks.** The first
  regeneration moved eight rows, not two. The six extras were cantus firmus
  voices graded against their florid partner, and they exposed that the
  beat-3 slot only makes sense for a suspension over a downbeat that lasts
  to that beat. The guard was tightened twice: once on the count, then, after
  the code reviewer found a cantus of quarters slipping through, on the tick
  and on whether the cantus note still sounds there.
- **Trimming a promise from the strings means trimming the code that made
  it.** The unreachable suspension branch in `FloridDissonanceTreatment` had
  two specs reaching it through `send`, which is how dead code stays alive.
  One behavioral example replaced them.
- **Wording has a meter.** "On the third beat" was true in 4/4 and wrong in
  cut time. "Halfway through the bar" is what the code checks in every meter
  that has a second strong beat.
- **A subclass that overrides one private predicate is the right size.**
  Eighteen guidelines already do it; nothing shared by class name broke, and
  fourth species never noticed.

## Review

Reviewed 2026-09-20 at commit `968b5fa` plus the uncommitted working tree,
which holds the whole implementation, by the product-manager (acceptance
verification) and code-reviewer agents. The two important code findings were
confirmed by hand. `bundle exec rake`: 8334 examples, 0 failures, 0 pending.
Rubocop clean.

### Acceptance criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Figure 82 adherent on the fifth-species suspension guideline | ✅ met | Spec "with Fux's fifth-species line" passes; the strict rule still marks bar 9 on the same voice. |
| 2 | Figure 82 at least as high as every other species on `fifth_species`; pending removed | ✅ met | Snapshot: 0.953 against 0.929 (fourth), 0.921 (second), 0.900 (third). No `pending` in the diagonal spec. |
| 3 | Fourth-species leap still marked | ✅ met | `fourth_species_harmony_spec.rb` "with a leap between suspension and resolution"; the guide file is not in the diff. |
| 4 | Step-down consonance sounding on beat 3 clears the suspension, whatever sounds between | ✅ met | `resolved?` inspects only the beat-3 note; pinned by the dissonant eighth-note neighbor and the leapt-to quarter examples, and by the held dotted-half example. |
| 5 | Five reference shapes each have an adherent example | ✅ met | All five contexts pass and match section 3.4.5. |
| 6 | Plain suspension adherent | ✅ met | "with a plain suspension resolving on beat three". |
| 7 | Six faults, one mark each | ✅ met | Six contexts, each `marks_count == 1`. |
| 8 | Figure 82 bars 8, 9, 10 unmarked, including the 8 to 9 chain | ✅ met | Probe found the three suspensions and each resolved; the chain's E5 is prepared at 8:3. |
| 9 | Dissonant leapt-to quarter marked by Florid, not Embellished | ✅ met | Guide spec example passes. |
| 10 | Rosters | ✅ met | Fifth species declares the new rule; fourth unchanged; pinned in three specs. |
| 11 | Corpus snapshot moves only figure 82's two rows | ✅ met | Two lines differ from `main`; all 154 `fourth_species_harmony` rows byte-identical; an in-memory regrade matches the file. |
| 12 | `FloridDissonanceTreatment` strings no longer promise tied suspensions | ⚠️ partial | `en.yml` trimmed, but `en_GB.yml` lines 123 and 125 still carry the clause, and the regenerated `english_strings.yml` now pins that stale British text. |

The product manager judged the downbeat guard a faithful extension of the
beat-3 decision rather than a scope change: Girton's frame has no "second
strong beat" for a suspension whose cantus attack is off the downbeat, so the
strict fallback is the same answer the decision already gives for 3/4. It
noted the guard also affects real input (a student cantus attacked mid-bar),
and that the Decisions section still mentions only the 3/4 fallback.

### Code review findings

**Important.**

1. **The beat-3 slot is used even when the cantus note has moved on before
   beat 3.** The guard `position.count == 1` ignores `tick`, so a cantus
   note at `2:1:480` gets the slot, and it never checks that the cantus note
   still sounds at the slot. Confirmed: with a cantus of quarters in bar 3,
   a D5 suspended over E4 and abandoned by leap is called clean, because C5
   on beat 3 is a step down relative to the A4 that arrived there. Fix:
   require `tick.zero?` and return the slot only when
   `resolution.within_placement?(cf_note)`.
2. **The off-downbeat fallback has no named example.** Only the corpus
   snapshot exercises it. A context with a cantus attacked mid-bar should
   pin it beside the 3/4 contexts. Also, the 3/4 "plain suspension" example
   passes under both rules; only the leap example proves `super` is reached.
3. **`FloridDissonanceTreatment`'s suspension branch is dead code.**
   `on_strong_beat?` requires the note to start on a cantus position, and
   `properly_treated_suspension?` then requires it to start before that
   position, so the branch always returns false and `resolved_by_step?` is
   never called. Trimming the string while leaving the code is the worst of
   both; delete the branch or keep the promise.
4. **"On the third beat" is 4/4-specific wording for a meter-generic rule.**
   Measured: the second strong count is 3 in 4/4 and 4/2, 2 in 2/2 and 2/4,
   4 in 6/8 and 12/8, and none in 3/4. In cut time, the historically normal
   notation for species, the student is told beat 3 while beat 2 is checked.
   Say "halfway through the bar" or "on the bar's second strong beat" in
   both strings.

**Low.**

5. The division-of-labor example asserts only one mark; asserting its
   position (`3:2:000`, the leapt-to F4) would close the gap with its name.
6. `item_assessment` takes `analysis` as a parameter though it is the
   subject in scope; `fourth_species_harmony_spec.rb` open-codes the same
   `detect` instead of reusing it.
7. The reference's `FloridDissonanceTreatment` row ends mid-phrase, and the
   new row should say that the intervening-note consonance that section
   3.4.5 requires for shapes 4 and 5 is `FloridDissonanceTreatment`'s half.
8. The Decisions section should record the off-downbeat fallback alongside
   the 3/4 one.
9. `en_GB.yml` still carries the tied-suspension clause (criterion 12).

### Outcomes

Each finding was confirmed by hand and fixed on 2026-09-20.

1. **Fixed.** `resolution_position` now requires the cantus note to be on
   the downbeat with no tick offset, and returns the slot only when it falls
   inside that cantus note. A cantus of quarters no longer lends its beat-3
   note to a different suspension.
2. **Fixed.** "with the cantus firmus moving before beat three" pins the
   fallback with a half-note cantus in bar 3.
3. **Fixed.** The dead suspension branch is gone: a strong-beat dissonance is
   simply a fault, and the class comment says why a held-over note never
   reaches this guideline. The two contexts that reached the deleted methods
   through `send` were replaced by one behavioral example.
4. **Fixed.** Both strings now say "halfway through the bar", which is the
   second strong beat in every meter that has one.
5. **Fixed.** The division-of-labor example asserts the mark at `3:2:000`.
6. **Fixed.** `item_assessment(guideline)` reads the subject; the fourth
   species spec uses the same helper.
7. **Fixed.** Both reference rows rewritten; the `FloridDissonanceTreatment`
   row now says it carries the intervening-note consonance for shapes 4 and 5.
8. **Fixed.** The beat-3 decision records the off-downbeat fallback.
9. **Fixed.** `en_GB.yml` trimmed and the English snapshot regenerated; the
   only remaining "tied suspension" strings belong to `ConsonantDownbeats`.

After the fixes: 8332 examples, 0 failures; the corpus snapshot still differs
from `main` in exactly figure 82\x27s two rows.

**Noted, pre-existing, not this story's.** A chord in the voice makes
`two_part?` false, so no suspension is detected in that bar; and a note held
across two downbeats can be collected twice by `dissonant_suspensions`. Both
are inherited from the parent unchanged.

## Implementation Notes

Implemented 2026-09-20, directly. The plan was followed as written, with one
addition the corpus snapshot forced.

- **The beat-3 slot applies only to a suspension over a downbeat.** The first
  snapshot regeneration moved eight rows, not two: the cantus firmus voices of
  the second, third, and fifth species fixtures, graded against their florid
  partner, dropped under `fifth_species_harmony`. With the roles swapped the
  "cantus" attacks mid-bar, so the beat-3 slot held the whole note itself and
  every such suspension was marked. `resolution_position` now returns nothing
  unless the cantus note is on count 1, which falls back to the strict rule
  there. The second regeneration moved exactly figure 82\x27s two rows.
- **Measured.** Figure 82: `fifth_species_harmony` 0.819 to 0.937,
  `fifth_species` 0.891 to 0.953, against figure 73\x27s 0.929. Every
  `fourth_species_harmony` row is byte-identical.
- **The diagonal spec has no pending example.** 8334 examples, 0 failures.
- **`FloridDissonanceTreatment`\x27s strings** lost the clause about tied
  suspensions, and the reference\x27s guideline map now lists
  `EmbellishedSuspensionTreatment` as implemented.

## Implementation Plan

Planned 2026-09-20 with the story-planner (product-manager and developer).
The measured outcome was re-verified with an in-memory prototype before the
plan was written: figure 82 is adherent, `fifth_species_harmony` goes from
0.819 to 0.937 and the composite from 0.891 to 0.953, against figure 73's
0.929, so the diagonal holds with no other rule change.

### Overview

Add `EmbellishedSuspensionTreatment` as a subclass of `SuspensionTreatment`
that overrides only the private `resolved?` predicate: the resolution is the
note *sounding* on the bar's second strong beat (beat 3 in 4/4), it must be a
descending step from the suspended pitch and consonant there, and whatever
is attacked between the suspension and that beat is left to
`FloridDissonanceTreatment`. Swap it into `FifthSpeciesHarmony`'s primary
tier, leave fourth species untouched, regenerate both snapshots last.

### Decisions settled

- **Subclass, override `resolved?`.** Eighteen guidelines already override a
  private method of a parent. Nothing is shared by class name: the wording
  template key is memoized per class, so the subclass gets its own
  `embellished_suspension_treatment` i18n key, and guide item equality
  distinguishes the two classes. A mixin would move six methods for one
  consumer.
- **The resolution must sound on beat 3 (Girton).** `Position#strong?` is
  true for count 3 in 4/4 and false for 2 and 4. `resolution_position` is
  the first count after 1 in the cantus note's bar that is strong; with none
  (3/4) fall back to `super`, the strict shape. Trade-off: an anticipated
  resolution whose beat 3 moves to some other consonance is marked. Girton's
  structural framing is the only formulation that accepts all five shapes
  with one position check and no note counting.
- **Identify the resolution by what sounds, not what is attacked.**
  `voice.note_at(resolution_position)`, so a dotted-half resolution begun on
  beat 2 counts, and a suspension held through the bar returns itself, fails
  the step test, and is marked. `MelodicInterval#step?` so D5 to C#5 counts.
- **Intervening notes are not this guideline's business.** The developer's
  prototype checked each for consonance or neighbor shape; the product
  manager argued that duplicates `FloridDissonanceTreatment`, which already
  judges every attacked note at its start and marks a dissonant beat-2
  quarter reached by leap. The plan takes that: it honours the existing
  split, avoids a double discount, and lets a dissonant eighth-note lower
  neighbor through without a special case. Beat-3 landing bounds the
  embellishment to a quarter or an eighth pair, which answers the open
  question. The division is pinned at guide level in step 6.
- **Chained suspensions** (figure 82 bars 8 and 9): the beat-3 E5 tied into
  bar 9 is checked as preparation at 8:3, where it is consonant.
- **Specs are copied, not shared.** The two rules disagree on exactly the
  shape a shared group would pin. `suspension_treatment_spec.rb` is untouched.

### Steps

1. **Create the guideline.**
   `lib/head_music/style/guidelines/embellished_suspension_treatment.rb`:
   `class EmbellishedSuspensionTreatment < SuspensionTreatment`, private
   `resolved?(cp_note, cf_note)`, `resolution_position(cf_note)`.

   ```ruby
   def resolved?(cp_note, cf_note)
     position = resolution_position(cf_note)
     return super unless position

     resolution = voice.note_at(position)
     return false unless resolution

     melodic = HeadMusic::Analysis::MelodicInterval.new(cp_note, resolution)
     melodic.step? && melodic.descending? && consonant_at?(position)
   end

   def resolution_position(cf_note)
     bar = cf_note.position.bar_number
     (2..cf_note.position.meter.counts_per_bar)
       .map { |count| HeadMusic::Content::Position.new(flow, "#{bar}:#{count}") }
       .detect(&:strong?)
   end
   ```

   One brief comment on why beat 3, one saying intervening notes are
   `FloridDissonanceTreatment`'s job so nobody adds the check back.

2. **Register the require** in `lib/head_music.rb` after
   `florid_dissonance_treatment`, which follows both `suspension_treatment`
   and `dissonance_figure_detection`.

3. **Add the English strings** in `lib/head_music/locales/en.yml`,
   alphabetically between `direction_changes` and
   `end_on_perfect_consonance`:
   - name: "Embellished suspension treatment"
   - instruction: "Prepare every suspension as a consonance, then resolve it
     downward by step on the third beat, however the resolution is delayed
     or decorated."
   - violations.default: "Prepare each suspension as a consonance and resolve
     it downward by step on the third beat, however the resolution is
     delayed or decorated."

   No en_GB entry: no note value is named and "neighbor" is avoided.

   In the same file, drop the "prepare and resolve every tied suspension"
   clause from `florid_dissonance_treatment`'s instruction and violation
   strings; that guideline judges notes at their start and never sees a
   held-over note. Update its row in `guide_item_strings_spec.rb`.

4. **Swap the guide.** `lib/head_music/style/guides/fifth_species_harmony.rb`:
   `primary_items(FloridDissonanceTreatment, EmbellishedSuspensionTreatment)`.
   `fourth_species_harmony.rb` untouched.

5. **Guideline spec**
   `spec/head_music/style/guidelines/embellished_suspension_treatment_spec.rb`.
   Build voices from ABC with `dorian_species_abc` over a short cantus
   `D4|F4|E4|D4|]`, counterpoint in L:1/4:

   | Example | ABC | Expectation |
   | --- | --- | --- |
   | no suspensions | `z2 A2\|A2 c2\|c2 B2\|A4\|]` | adherent |
   | plain suspension resolving on beat 3 | `z2 A2\|A2 d2-\|d2 c2\|A4\|]` | adherent |
   | anticipated on beat 2, repeated on beat 3 | `z2 A2\|A2 d2-\|d c c2\|A4\|]` | adherent |
   | anticipated on beat 2, held through beat 3 | `z2 A2\|A2 d2-\|d c3\|A4\|]` | adherent |
   | anticipated with an eighth-note lower neighbor | `z2 A2\|A2 d2-\|d c/2 B/2 c2\|A4\|]` | adherent |
   | dissonant eighth-note lower neighbor | `z2 F2\|F2 A2-\|A G/2 F/2 G2\|A4\|]` | adherent |
   | escape tone stepping up on beat 2 | `z2 A2\|A2 d2-\|d e c2\|A4\|]` | adherent |
   | consonant leap on beat 2 before the resolution | `z2 A2\|A2 d2-\|d B c2\|A4\|]` | adherent |
   | delayed by one consonant note | `z2 A2\|A2 d2-\|d G c2\|A4\|]` | adherent |
   | Fux figure 82 | `fux_fifth_species_examples.first.counterpoint_voice` | adherent |
   | leaps away and never resolves | `z2 A2\|A2 d2-\|d2 B2\|A4\|]` | fitness `PENALTY_FACTOR`, one mark |
   | resolution lands on beat 4 | `z2 A2\|A2 d2-\|d G G c\|A4\|]` | one mark |
   | anticipated resolution not held on beat 3 | `z2 A2\|A2 d2-\|d c B2\|A4\|]` | one mark |
   | unprepared | `z2 G2-\|G2 F2\|E2 c2\|A4\|]` | one mark |
   | resolves by ascending step | `z2 A2\|A2 d2-\|d2 e2\|A4\|]` | one mark |
   | held through the bar | `z2 A2\|A2 d2-\|d4\|A4\|]` | one mark |
   | triple meter (the `super` fallback) | `meter: "3/4"`, one plain and one leaping suspension | strict behaviour |
   | without a cantus firmus | mirror `suspension_treatment_spec.rb` | adherent, no marks |

6. **Guide specs and rosters.**
   - `fifth_species_harmony_spec.rb`: include `EmbellishedSuspensionTreatment`,
     not `SuspensionTreatment`. Add "with Fux figure 82": the embellished item
     is adherent. Add "with a dissonant quarter leapt to from a suspension"
     (`z2 A2|A2 d2-|d F c2|A4|]`): the embellished item is adherent and
     `FloridDissonanceTreatment` has one mark. This pins the division of labor.
   - `fourth_species_harmony_spec.rb`: add "with a leap between suspension and
     resolution" (`z2 A2|A2 d2-|d B c2|A4|]`): `SuspensionTreatment` has one
     mark.
   - `base_spec.rb`: the fifth_species_harmony roster swaps
     `SuspensionTreatment` for `EmbellishedSuspensionTreatment`, sorted.
   - `guide_species_diagonal_spec.rb`: delete the comment block and the
     `pending` line.
   - `guide_item_strings_spec.rb`: add the `EmbellishedSuspensionTreatment`
     row after `EndOnTonic`. `guide_strings_spec.rb`: items 68 to 69.

7. **Lint and run the non-snapshot suite.** `bundle exec rubocop -a`, then
   `bundle exec rspec spec/head_music/style`; only the two snapshot specs
   should be red.

8. **Regenerate both snapshots once, last.** `rake style:snapshot_english`,
   then `rake style:snapshot_corpus_fitness`. The corpus diff must touch only
   figure 82's `fifth_species_harmony` (0.819 to 0.937) and `fifth_species`
   (0.891 to 0.953) rows; every `fourth_species_harmony` row must be
   byte-identical. Any other changed row means the beat-3 rule bit a corpus
   voice it should not have. Then `bundle exec rake` for coverage.

9. **Close the paperwork.** Update the guideline-map row in section 6 of
   `references/fifth-species-counterpoint.md` so the reference and the code
   agree, and answer the story's open question.

### Testing

- The guideline spec is the documentation: five embellished shapes plus the
  plain shape adherent, six violation shapes marked, figure 82 adherent, no
  cantus firmus safe.
- Highest-value edges: the dotted-half anticipation (resolution sounding but
  not attacked on beat 3), the dissonant eighth-note neighbor (proves the
  guideline ignores intervening notes), the bars 8 and 9 chain in figure
  82, and the 3/4 fallback, the only caller of `super`.
- Guide-level specs pin the roster swap, the fourth-species regression, and
  the division of labor on a dissonant intervening quarter.
- The diagonal spec becomes the acceptance test once its `pending` is
  removed; the corpus snapshot diff is the guard that nothing else moved.

### Risks

- **Beat-3 strictness.** An anticipated resolution whose beat 3 moves to a
  different consonance is marked. If that proves too strict, drop the
  strong-beat search and accept the first later descending-step consonance,
  at the cost of also accepting beat-4 resolutions.
- **The split means a dissonant leapt-to quarter on beat 2 is marked once,
  by `FloridDissonanceTreatment`.** The developer preferred an in-guideline
  consonance check, which would double-mark that note the way
  `ConsonantDownbeats` and `FloridDissonanceTreatment` already double-mark an
  attacked downbeat dissonance. Reversible in one line.
- **Stale string, fixed here.** `FloridDissonanceTreatment`'s instruction in
  `en.yml` said it would "prepare and resolve every tied suspension", which
  is unreachable: a held note never starts on a cantus position. Step 3
  rewrites it.
- The corpus contains no voice with a beat-2 resolution followed by a
  different beat-3 pitch, so the stricter rule is untested against real
  lines beyond the fixtures.
