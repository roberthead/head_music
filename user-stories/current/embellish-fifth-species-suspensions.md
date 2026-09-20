<!--
metadata:
  created_at:   2026-09-18T17:00:05-07:00
  activated_at: 2026-09-19T08:36:41-07:00
  planned_at:   2026-09-20T13:36:21-07:00
  finished_at:
  updated_at:   2026-09-20T14:56:58-07:00
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
  second strong beat exists, the strict fourth-species rule applies. Notes
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
