<!--
metadata:
  created_at:   2026-11-15T14:57:30-05:00
  activated_at: 2026-11-15T16:00:12-05:00
  planned_at:   2026-11-15T19:54:14-05:00
  finished_at:
  updated_at:   2026-11-16T15:44:00-05:00
-->

# Story: Free Species Guide

## Summary

AS a consumer of the gem grading a student's two-voice composition (BardTheory's Unit 10 `free-counterpoint-passage` exercise)
I WANT a guide that grades two voices written in species technique with no given cantus firmus
SO THAT a student who composes both lines gets feedback on each line as a melody and on the two together as counterpoint

"Free species": no cantus firmus (no fixed song) is given. The student composes both lines, using the techniques of the species. The name is the gem's own; the guide's instruction text says so, and explains the contrast with a cantus firmus.

## Acceptance Criteria

### The guide

- A registered composite guide, `free_species`, made of a melody guide and a harmony guide, as the species composites are in `HeadMusic::Style::Guide`
- The guide grades either voice of a two-voice flow, and neither voice has to be marked `cantus_firmus?`. Assessing each voice in turn grades the whole passage
- Display names and instructions exist in English, and in British English wherever its note-value vocabulary differs, following the precedent of `fifth_species` and `mix_species_textures`; the other locales fall back to English until [free-species-translations](../backlog/free-species-translations.md). The instruction text says that no cantus firmus is given and both lines are composed
- The guide is configurable as a whole: `Guide.get("free_species").with(dotted_rhythms: true, bars: 8..12)` routes each option to the member guide that takes it, through a new `CompositeGuide#with`. An option no member takes raises `ArgumentError`, and a configured composite keeps the registered guide's display name and instruction. Its `key` is nil, as a `Configured` guide's is, so `Guide.get(key)` never hands back the unconfigured guide in its place
- Nothing disqualifies: every fault lowers the grade, never ends it. Each guideline is placed in a tier (gate, primary, secondary) with a reason, consistent with the tier policy `SpeciesHarmony` documents
- CHANGELOG entry under Unreleased

### Metric strength from the meter (shared change)

- `VoiceContext#downbeat_position?` means the first beat of the bar, read from the meter, not "the cantus firmus attacks here"
- A new `strong_beat_position?` uses `Content::Position#strong?`, so beats 1 and 3 in 4/4 are strong. It locates where a suspension resolves, not where dissonance is forbidden
- `HarmonicContext#motions` is measured between downbeats, not between cantus firmus attacks; `NoParallelPerfectAcrossBarline` finds the next downbeat from the meter
- The guidelines that read beats through `downbeat_position?` follow the meter with it: `FloridDissonanceTreatment`, `WeakBeatDissonanceTreatment`, `SecondSpeciesBreak`, and `NoParallelPerfectAcrossBarline` (whose next downbeat also comes from the meter)
- The guidelines that read `downbeat_harmonic_intervals` or `motions` follow it too: `ConsonantDownbeats`, `NoStrongBeatUnisons`, `NoParallelPerfectOnDownbeats`, `PreferImperfect`, `ApproachPerfectionContrarily`, and `PreferContraryMotion`. Together with the four above, these are the guidelines a snapshot change from step 1 can come from
- The species suspension rules (`SuspensionTreatment`, `EmbellishedSuspensionTreatment`) keep reading the cantus firmus. Free species judges suspensions with its own dissonance guideline, so moving them would add species risk for no gain
- No species grade of a counterpoint voice changes. A species cantus firmus attacks once per bar, on beat one, so the existing species specs pass unchanged and prove it. A spec that fails here is a finding to report, not a spec to update
- The pinned corpus snapshot (`spec/fixtures/style/corpus_fitness.json`) is expected to change only in rows where a harmony guide grades a cantus firmus against a florid line, or the synthetic corpus entries: there the companion is the moving line, so "downbeat" used to mean its every attack. Those rows are regenerated and the diff reviewed before committing; any changed row grading a counterpoint voice stops the work

### Dissonance

- Dissonance follows fifth species: only the downbeat forbids an attacked dissonance, and beat 3 in 4/4 takes a passing tone as fifth species allows (Fux figures 82, 86a and 88a do). A dissonance attacked on the downbeat is a fault. A dissonance held into a strong beat (the downbeat, or beat 3 in 4/4) from a weaker one, or struck again there, is a suspension: prepared as a consonance, and resolved by the suspended voice's first note a step down and consonant with whatever the other voice sounds then, arriving by the second strong beat after the suspension (revised 2026-11-16: re-struck suspensions accepted, deadline loosened by one strong beat; upward resolution deferred to the first tonal stage). The notes between may decorate the resolution, as fifth species allows, and are judged by the rule for attacked dissonance. Any other attacked dissonance must be a passing tone, neighbor tone, nota cambiata, or double neighbor. The existing `DissonanceFigureDetection` is reused, not copied
- **Either voice can explain a dissonance.** A dissonance is properly treated when at least one voice that attacks into it does so as a recognized figure, or when it is a suspension in the held voice. When no voice explains it, every voice that attacked into it is marked, so the fault counts in both voices' grades
- **A passing or neighbor figure runs from consonance to consonance.** Its stepwise run may hold several dissonant notes in a row, but the notes that begin and end it must be consonant with whatever the other voice sounds at those moments. Shape alone does not explain a dissonance, so two lines stepping in parallel sevenths are marked. Free species only: the species guidelines keep judging figures by shape, since a held cantus firmus already makes the ends consonant there
- Specs pin: one voice moving against a held note; a suspension (the held voice owns it; the moving voice is not marked); simultaneous dissonant passing tones in both voices (no mark; Salzer & Schachter p. 330 list "dissonant passing tones in both species parts" as a basic situation); a leap into a chord tone against a passing tone in the other voice (no mark); a simultaneous dissonance neither voice explains (both marked); two dissonant passing tones in a row between consonances (no mark); parallel sevenths stepping through weak beats with no consonant end (marked)

### Motion

- Two-part craft carries over from `HARMONIC_CORE` and the diminution core: approach perfect consonances by contrary or oblique motion, prefer contrary motion and imperfect consonances, avoid crossing and overlapping, no parallel perfect consonances on downbeats or across the barline
- Parallel perfect consonances are also caught between consecutive moments within the bar, where in free species both voices can move from beat to beat. `NoParallelPerfectWithSyncopation` already compares every consecutive moment where either voice attacks, so it covers this as it stands (it is in `INHERITED_HARMONIC_CRAFT`); no new guideline
- Direct (hidden) motion into a perfect consonance is checked between downbeats only, as in fifth species. Checking it beat to beat is out of scope

### Rhythm and texture

- Note values are fifth species' (`AllowFifthSpeciesRhythmicValues`), with two differences: a whole note is allowed in any bar, and a `dotted_rhythms:` option (off by default) allows
  - a dotted note wherever the same rhythm written with a tie would pass (a dotted half, or a dotted whole in 3/2)
  - a dotted quarter followed by a single eighth that moves by step to the next note. If that eighth is dissonant, it must be a passing tone or neighbor tone; it is judged at its own position inside the beat. The harmony guide reads this from the rhythm, not from the option: an eighth after a dotted quarter takes only a passing or neighbor tone whether or not `dotted_rhythms:` is set, so the option stays the melody guide's alone
- Each voice may keep one texture as long as it likes; the fifth-species rule that each line mix textures (`MixSpeciesTextures`) does not apply per voice
- A new harmony guideline (working name `IndependentTextures`) marks stretches where both voices share the same texture for more than `maximum_run:` bars, default 2 (Salzer & Schachter's figure for one line, pp. 101-102). It reuses `MixSpeciesTextures`'s classification of a bar's texture
- A staggered entry (one voice resting while the other begins) is allowed and is not a fault

### Cadence

- Each voice steps into its last note in either direction (`StepToFinalNote` in the melody guide, not `StepUpToFinalNote`), and ends on the tonic
- A new harmony guideline (working name `ClausulaVera`) requires the two-part cadence: the leading tone and the second degree in the next-to-last position, moving to the tonic by contrary step, into an octave or unison. Either voice may carry the leading tone. It is a primary item
- The lower approach to the final is a half step: raised in Dorian, Mixolydian, Aeolian, and minor, as written in Ionian, Lydian, and major. Phrygian is the exception: the 7th degree rises a whole step while the other voice falls the half step 2→1. An unraised seventh at a cadence that needs the raise is marked by `ClausulaVera` (Salzer & Schachter p. 20); `Diatonic` keeps only permitting the raise
- The guideline takes `.with(forms:)`, defaulting to the clausula vera, so the eighteenth-century guide can reuse it with the authentic cadence (5→1 in the bass). This story implements only the clausula vera form; the structure for a second form is specced, not built

### Length

- A new `BarCount.with(range)` guideline, one item for both limits, so every way of writing a limit weighs the same
- The guide takes `bars:` and passes it through: an Integer means exactly that many bars (`bars: 8`), a Range sets the limits (`8..12`, `8..` for at least eight, `..12` for at most twelve, and `8...12` excluding twelve, as Ruby reads them). Unset by default, so the guide is neutral about length unless an exercise asks
- Bars are counted from the first entry of either voice to the last note, so a staggered entry does not count as missing bars
- A passage outside the range loses grade in proportion to how far outside it is: a short one marks every note with fitness actual ÷ minimum, as `MinimumNotes` does; a long one marks the notes in the bars past the limit, scored by their share of the notes, as `MaximumNotes` does
- `BarCount` is a secondary item: length is an exercise's requirement rather than what the guide teaches, so setting `bars:` never changes the weight of the dissonance, cadence, and texture rules

### Verification

- The free species guidelines accept Fux's fifth species: on every Fux fifth-species example, in both voices, `FreeDissonanceTreatment`, `ClausulaVera`, `IndependentTextures`, and `AllowFreeSpeciesRhythmicValues` leave no marks. A fifth-species exercise is valid free species, with the cantus firmus as a voice that keeps to whole notes. Any exception (figure 85b, and fixtures with expected messages) is excluded by name with its reason, never by loosening the comparison. The inherited craft is not asserted here: Fux's lines already draw marks from it under `fifth_species`, and the species specs cover it
- Specs grade written faults with the expected marks: an unprepared downbeat dissonance, beat-to-beat parallel fifths, both voices in quarters for three bars, a cadence with both voices stepping the same way

## Notes

### Decisions from pre-planning (2026-11-15)

1. **Metric strength:** read from the meter in the shared contexts, for every guide (not a separate context, not a per-guide strategy). Beat 3 in 4/4 counts as strong, as `Position#strong?` says, but only for where a suspension resolves; for dissonance, only the downbeat is strong, as in fifth species (revised in planning review).
2. **Dissonance ownership:** either voice can explain a dissonance; unexplained ones mark every voice that attacked into it.
3. **Style:** species-derived ("free species"), not eighteenth-century. Eighteenth-century free counterpoint is its own backlog story: [eighteenth-century-two-voice-counterpoint-guide](../backlog/eighteenth-century-two-voice-counterpoint-guide.md).
4. **Dotted rhythms:** an option, off by default, allowing tie-equivalent dots and a dotted quarter plus stepwise eighth.
5. **Cadence:** a dedicated, primary, configurable cadence guideline requiring the clausula vera. Salzer & Schachter require both the leading tone and the second degree in the next-to-last measure of two-part writing (p. 20), and their combined-species chapter defers cadences to that rule (p. 333). The 5→1 bass appears only with a third voice (pp. 33-34). Kennan's eighteenth-century practice puts the dominant in root position, so 5→1 belongs to that guide.
6. **Texture:** moves from each voice to the pair (`IndependentTextures`); whole notes anywhere.
7. **Length:** configurable `bars:`, unset by default.
8. **Name:** "Free Species". Salzer & Schachter's "combined species" means two different species against a cantus firmus in three voices (pp. 330-331), so that name would mislead.

### Decisions from planning (2026-11-15)

1. Reuse `NoParallelPerfectWithSyncopation` for beat-to-beat parallels; no new guideline.
2. The species suspension rules stay on the cantus firmus.
3. Decorated suspension resolutions are allowed, as in fifth species, judged by a free-species rule: the resolution is what the suspended voice sounds on the next strong beat, against whatever the other voice sounds then. Suspensions over beat 3 resolve on the next downbeat (revised in planning review).
4. `CompositeGuide#with` configures the composite as a whole.
5. `bars: 8` means exactly eight; `8..` means at least eight. One secondary `BarCount` guideline holds the limit (planning review), so how a limit is written does not change the weight of anything else.
6. Strings follow the English-first precedent; translations are their own story.
7. Fux's fifth-species examples are the corpus for the new guidelines only; the inherited craft already marks some of Fux's lines under `fifth_species` (revised in planning review).
8. Hidden octaves and fifths between beats are not checked, matching fifth species.
9. A passing or neighbor figure explains a dissonance only when its stepwise run begins and ends on consonances against the other voice (planning review).

### Scope

- Two voices only. Three- and four-voice counterpoint (BardTheory Units 12 and 14) needs every pair of voices checked and is a separate change to the harmony context.
- Inherited fifth-species craft that marks Fux's own lines: [fifth-species-published-examples](../backlog/fifth-species-published-examples.md).
- No imitation or sequence: [free-species-with-imitation-guide](../backlog/free-species-with-imitation-guide.md) and [free-species-with-sequence-guide](../backlog/free-species-with-sequence-guide.md) build on this guide.
- BardTheory can't place a note inside a beat yet, so students can't use the dotted-quarter-and-eighth rhythm until its editor supports subdivisions. The gem supports it regardless.

### Sources

- Salzer & Schachter, *Counterpoint in Composition* (scan on disk): two-part cadence p. 20; three-part cadence pp. 33-34; fifth-species texture pp. 101-102; combined species pp. 330-333.
- Kennan, *Counterpoint*, 3rd ed., "Principles of Two-Voice Counterpoint," pp. 27-28: the contrast case for the cadence.
- `references/fifth-species-counterpoint.md`: cross-source comparison of florid dissonance treatment.

### Downstream

BardTheory's backlog story `unit-10-composition-exercises` waits on this guide and needs it released to RubyGems. An exercise that sets `bars:` or `dotted_rhythms:` must store those options beside the key `free_species` and call `.with` again when it grades, since a configured composite has no key of its own.

## Implementation Plan

### Approach

First move metric strength onto the meter in the shared contexts, with the species suite as the proof that nothing regrades. Then build the free species rules as new guidelines on extracted pieces of the fifth-species ones (figure detection, bar texture), and assemble them into a melody guide and a harmony guide registered as the `free_species` composite, the way `fifth_species` is. Configuration (`dotted_rhythms:`, `bars:`) follows `ContourMelody`'s keyword-signature pattern, routed through a new `CompositeGuide#with`.

### Steps

1. **Meter-based downbeats (shared).**
   - `lib/head_music/style/guideline/voice_context.rb`: `downbeat_position?` asks whether the position is the first beat of its bar; add `strong_beat_position?` delegating to `Position#strong?`; drop `cantus_firmus_positions` once nothing reads it.
   - `lib/head_music/style/guideline/harmonic_context.rb`: `downbeat_harmonic_intervals` walks the bar downbeats across the flow's span instead of the cantus firmus attacks.
   - `lib/head_music/style/guidelines/no_parallel_perfect_across_barline.rb`: `next_downbeat_interval` takes the next bar's downbeat.
   - Run the whole species suite before any other change lands. Every existing spec must pass untouched, except the corpus snapshot rows described in the acceptance criteria; a failure is reported, not edited. Regenerate the snapshot with `rake style:snapshot_corpus_fitness` and show the diff before committing.
2. **ConsonantDownbeats excuses a suspension in either voice.** `guidelines/consonant_downbeats.rb`: `tied_suspension?` asks whether any voice sounding at the downbeat began earlier, not only the graded one. Species-neutral, since a cantus firmus attacks every downbeat. It keeps `HARMONIC_CORE` whole for the free guide, which `base_spec` requires.
3. **Extract figure detection into an object.** A new `HeadMusic::Style::Guideline::DissonanceFigures`, built from a line's notes, its melodic intervals, and a dissonance test, answers `passing_tone?`, `neighbor_tone?`, `cambiata_dissonance?`, `double_neighbor_member?`. `guidelines/dissonance_figure_detection.rb` delegates to one built from the graded voice, so the species guidelines are unchanged. The search for a bar's next strong beat in `guidelines/embellished_suspension_treatment.rb` (`resolution_position`) moves to a shared helper both use; `EmbellishedSuspensionTreatment` keeps its rule, including its fallback when the cantus note does not last to that beat, so fifth species is unchanged.
4. **`FreeDissonanceTreatment`** (new, primary in the harmony guide). At each moment the two voices form a dissonance:
   - a strong beat (downbeat or beat 3) with a voice held over: that voice owns it as a suspension. Prepared: consonant where it was attacked. Resolved: the note it sounds on the next strong beat (`strong_beat_position?`) is a step below the suspended pitch and consonant with the other voice there, whether attacked on that beat or anticipated and held. The other voice may move meanwhile. If improper, mark the held voice
   - downbeat, both voices attacking: unexplained; mark the attackers
   - an eighth after a dotted quarter in the same voice: explained only as a passing or neighbor tone in its own line, read from the rhythm with no option
   - any other moment, beat 3 in 4/4 included: explained when any attacking voice's note is a figure in its own line, using a `DissonanceFigures` per voice; otherwise mark the attackers. For passing and neighbor tones, walk the stepwise run out from the note in both directions to the nearest notes consonant with the other voice; the figure holds only when those ends exist, the run between them keeps one direction (passing) or returns to its starting pitch (neighbor), and every step is a step. This check belongs to `FreeDissonanceTreatment`, not `DissonanceFigures`, so the species guidelines are unchanged
   - The graded voice gets the marks that fall on its notes.
5. **`IndependentTextures`** (new, primary). Extract the bar-texture classification from `guidelines/mix_species_textures.rb` into a reusable object taking a voice (`MixSpeciesTextures` keeps its behavior through it). The new guideline marks runs of more than `maximum_run:` (default 2) bars where both voices share a single-species texture.
6. **`AllowFreeSpeciesRhythmicValues`** (new subclass of `AllowFifthSpeciesRhythmicValues`, primary in the melody guide): no whole-note restriction; with `dotted_rhythms: true`, no mark for a dotted note whose tied spelling would pass, and no unpaired-eighth mark for an eighth after a dotted quarter that steps to the next note. That eighth still counts toward the bar's eighth-note limit.
7. **`ClausulaVera`** (new, primary): the final notes form an octave or unison on the tonic; the last notes before them are the step below the final (a half step below, except in Phrygian, where it is the whole step from the 7th degree; mark the cadence when a needed raise is missing) and the second degree, sounding together, each stepping to the tonic in contrary motion. Either voice may carry either. `.with(forms:)` defaults to `[:clausula_vera]`; any other form raises `ArgumentError` naming what is not yet supported.
8. **`BarCount`** (new): `BarCount.with(range)`, counting bars from the first note of either voice to the last note of either. Below the range, mark every note with fitness actual ÷ minimum (the `MinimumThreshold` pattern); above it, mark the graded voice's notes in the bars past the limit, with the voice's note count as the fitness denominator (the `MaximumNotes` pattern). `template_values` gives the range's ends for the strings, with a wording for each of exact, at least, at most, and between.
9. **The guides.**
   - `lib/head_music/style/guides/free_species_melody.rb`: `items_by_tier(dotted_rhythms: false)`: gate `MELODIC_GATES`; primary `AllowFreeSpeciesRhythmicValues`; secondary `MOVING_MELODIC_CRAFT` except `StepUpToFinalNote`, plus `StepToFinalNote` and `PreferLongBeforeShort`.
   - `lib/head_music/style/guides/free_species_harmony.rb`: `items_by_tier(bars: nil)`: gate `HARMONIC_GATES`; primary `FreeDissonanceTreatment`, `ClausulaVera`, `IndependentTextures`; secondary `INHERITED_HARMONIC_CRAFT`, plus `BarCount.with(range)` when `bars:` is set (an Integer `n` becomes `n..n`).
   - `lib/head_music/style/guide.rb`: add both to `GUIDE_CLASSES` and `"free_species" => %w[free_species_melody free_species_harmony]` to `COMPOSITE_MEMBERS`.
   - `lib/head_music.rb`: require the new files in dependency order (guideline extractions before their users, guides before `style/guide`).
10. **`CompositeGuide#with`.** `lib/head_music/style/guides/composite_guide.rb`: routes each option to the members whose `items_by_tier` takes that keyword, raises `ArgumentError` for an option no member takes, and returns a new composite that keeps the registered one's display name and instruction (an unregistered composite otherwise falls back to "Free Species Melody + Free Species Harmony"). `key` stays nil, the reverse lookup it is today. The registered key it was configured from is kept for display only and takes no part in `==` or `hash`, so `Guide.key_for` and the registry are unaffected.
11. **Strings.** `lib/head_music/locales/en.yml`: guide instructions for `free_species`, `free_species_melody`, `free_species_harmony` (the `free_species` text explains that no cantus firmus is given and the name is the gem's own) and names, instructions and violations for the five new guidelines, including configured variants. British English where its note-value vocabulary differs; the other locales fall back to English until the translations story. `Template.verify!` covers the registered entries at load.
12. **CHANGELOG** under Unreleased: the guide, the configuration, and the meter change as a note even though it changes no grades.

### Data model changes

None.

### Tests

- `spec/head_music/style/guideline/voice_context_spec.rb` (new): `downbeat_position?` and `strong_beat_position?` in 4/4, 3/2 and 2/2, against a cantus firmus that moves, and against none.
- Behavior-preserving extractions (steps 3 and 5) are proven by the existing specs for `FloridDissonanceTreatment`, `WeakBeatDissonanceTreatment`, `EmbellishedSuspensionTreatment`, and `MixSpeciesTextures`, plus direct specs of the extracted objects.
- One spec per new guideline under `spec/head_music/style/guidelines/`, built with `HeadMusic::Notation::ABC.parse`, covering the cases in the acceptance criteria: the five dissonance-ownership cases, the suspension owned by the held voice, a passing tone on beat 3 in 4/4 unmarked, a downbeat suspension resolving on beat 3 with decoration while the other voice moves, a beat-3 suspension resolving on the next downbeat, a resolution dissonant with the moved voice (marked); textures (quarters against quarters for three bars marked, quarters against whole notes not); dotted rhythms on and off; a dissonant eighth after a dotted quarter as a passing tone (no mark) and as a cambiata (marked), with the option on and off; the cadence with the leading tone in either voice, an unraised seventh in Dorian (marked), Phrygian's whole step 7→1 against 2→1 (no mark), in minor, with both voices stepping the same way, and with 5→1; bars as Integer, Range, endless, beginless, and exclusive Range, counted from a staggered entry, with marks and fitness for short and long passages, and an assertion that a guide configured with `bars: 8..` and one with `bars: 8..12` grade a passage of the right length but with a dissonance fault the same.
- `spec/head_music/style/guides/free_species_melody_spec.rb`, `free_species_harmony_spec.rb`: membership by tier, and graded passages.
- `spec/head_music/style/guides/composite_guide_spec.rb`: `#with` routing, the unknown-option error, display name and instruction of a configured composite, its nil `key`, and equality that ignores where it was configured from.
- `spec/head_music/style/guides/base_spec.rb`: melodic and harmonic guide counts (17 and 8), and an entry in "the harmony guides hold the rules they held" for `free_species_harmony`.
- `guide_strings_spec.rb` and `guide_item_strings_spec.rb` pick up the new strings; the exact English is pinned in the latter.
- `spec/head_music/style/guides/free_species_corpus_spec.rb` (new): the four new guidelines leave no marks on either voice of any Fux fifth-species example, with named exclusions and reasons, on the pattern of `guide_species_diagonal_spec.rb`'s liberties.

### Risks and open questions

- **Species regrading from step 1.** The premise is that every species cantus firmus attacks once per bar, on beat one. If any fixture breaks it, stop and report before adjusting anything. The snapshot rows grading a cantus firmus against a florid line are the known exception. Registering the three new guides also adds snapshot rows, regenerated in step 9.
- **The leading tone in modes.** `ClausulaVera` requires the half step that `Diatonic` only permits (`raised_seventh_to_tonic?`); read the mode the same way `Diatonic` does (`key_signature.scale_type.name`) so the two agree on which degrees are raised.
- **Figure detection on the other voice.** `DissonanceFigures` for the companion line uses the same symmetric dissonance test, but the cambiata and double neighbor check consonance of surrounding notes against "the cantus"; with two moving voices that means against whatever the graded voice sounds at those positions. Pin this with a spec.
- **Double marking at downbeats.** A downbeat dissonance is marked by both `ConsonantDownbeats` (secondary) and `FreeDissonanceTreatment` (primary), as in fifth species today with `FloridDissonanceTreatment`. Accepted precedent, not new.
- **Load order.** `Guide` builds the registry at require time, and `CompositeGuide` must not read the registry while it is being built (see its comments). `#with` must respect that.

## Review

Reviewed 2026-11-16 at `7737eabf`. Suite: 19,249 examples, 0 failures (`rake spec:without_coverage`); rubocop clean; tree clean.

### Acceptance criteria

| Area | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| The guide | Registered composite `free_species` | ✅ | `lib/head_music/style/guide.rb:26-27,57`; `composite_guide_spec.rb` |
| The guide | Grades either voice, no `cantus_firmus?` | ✅ | `guideline/voice_context.rb:18`; `free_species_harmony_spec.rb:54-57`, `free_species_melody_spec.rb:32-33` |
| The guide | English and British strings; others fall back | ⚠️ | `en.yml:1067` says no cantus firmus is given. en_GB now has `free_dissonance_treatment` (finding 1, resolved). The note-value strings were also translated into de, es, fr, it, ru rather than left to fall back |
| The guide | `CompositeGuide#with` routes, raises, keeps name, nil key | ✅ | `guides/composite_guide.rb:78-86,143`; `composite_guide_spec.rb:153-198` |
| The guide | Nothing disqualifies; tiers with reasons | ✅ | `guides/free_species_harmony.rb:3-28`, `guides/free_species_melody.rb:3-26`; their specs |
| The guide | CHANGELOG under Unreleased | ✅ | `CHANGELOG.md:14-21,25` |
| Meter | `downbeat_position?` from the meter | ✅ | `voice_context.rb:29-31`; `voice_context_spec.rb` |
| Meter | `strong_beat_position?` via `Position#strong?` | ✅ | `voice_context.rb:33-35`; `voice_context_spec.rb` |
| Meter | Motions and next downbeat from the meter | ✅ | `harmonic_context.rb:16`, `no_parallel_perfect_across_barline.rb` |
| Meter | The ten dependent guidelines follow | ✅ | All read through the shared contexts; `cantus_firmus_positions` removed |
| Meter | Suspension rules stay on the cantus firmus | ✅ | `embellished_suspension_treatment.rb` only swaps in the shared next-strong-beat helper |
| Meter | No species grade of a counterpoint voice changes | ✅ | Species specs untouched and passing |
| Meter | Snapshot changes only in permitted rows | ✅ | 528 rows added (3 guides × 176 entries); 192 changed, all `-v0` cantus firmus rows against florid lines; no `v1` or synthetic row changed |
| Dissonance | Fifth-species rule, suspensions, loosened deadline | ✅ | `free_dissonance_treatment.rb:38-80`; `free_dissonance_treatment_spec.rb` |
| Dissonance | Either voice explains; else both marked | ✅ | `free_dissonance_treatment.rb:38-47`; spec "neither voice explains" |
| Dissonance | Figures run consonance to consonance, free species only | ✅ | `consonant_run?` at `free_dissonance_treatment.rb:101`; `DissonanceFigures` stays shape-only |
| Dissonance | The seven pinned cases | ✅ | `free_dissonance_treatment_spec.rb` |
| Motion | Two-part craft carries over | ✅ | `INHERITED_HARMONIC_CRAFT` in the secondary tier |
| Motion | Beat-to-beat parallels | ✅ | `NoParallelPerfectWithSyncopation`; `free_species_harmony_spec.rb:72-75` |
| Motion | Direct motion between downbeats only | ✅ | Reads `motions` |
| Rhythm | Note values and `dotted_rhythms:` | ✅ | `allow_free_species_rhythmic_values.rb:36,56,71`, `free_dissonance_treatment.rb:115`; their specs |
| Rhythm | No `MixSpeciesTextures` per voice | ✅ | `free_species_melody_spec.rb:19` |
| Rhythm | `IndependentTextures` reusing bar texture | ✅ | `independent_textures.rb:31-37`, `guideline/bar_texture.rb`; `independent_textures_spec.rb` |
| Rhythm | Staggered entry allowed | ✅ | `free_species_harmony_spec.rb:97-100` |
| Cadence | `StepToFinalNote`, end on tonic | ✅ | `free_species_melody.rb`; `free_species_melody_spec.rb:14,40` |
| Cadence | `ClausulaVera` primary, either voice | ✅ | `clausula_vera_spec.rb` |
| Cadence | Half step; Phrygian 7→1 whole step against 2→1 half step | ✅ | `clausula_vera.rb` `approach_interval_contracts_by_half_step?`; `clausula_vera_spec.rb` Phrygian and minor tenth contexts (finding 2, resolved) |
| Cadence | `.with(forms:)` | ✅ | `clausula_vera.rb:265-272`; spec |
| Length | `BarCount`, Integer and every Range, staggered entry, fitness | ✅ | `bar_count.rb:79,83,96`; `bar_count_spec.rb:26-79` |
| Length | Secondary; `bars:` changes no other weight | ✅ | `free_species_harmony_spec.rb:37-47,108-111` |
| Verification | Four new guidelines leave Fux's fifth species unmarked | ✅ | `free_species_harmony_corpus_spec.rb`; no exclusion is needed now that 85b passes |
| Verification | Written faults graded | ✅ | `free_species_harmony_spec.rb:63-91` |

### Findings

1. **Resolved: en_GB spells "neighbor" in the free dissonance strings.** Fixed by adding the en_GB entry. `en.yml:896-900` has no en_GB counterpart, so British English reads "neighbor tone… double neighbor" while `florid_dissonance_treatment` reads "neighbour" (`en_GB.yml:129-149`). Outside the criterion's note-value scope, but against the en_GB file's own convention (`en_GB.yml:89`). Small fix: add the entry.
2. **Resolved: `ClausulaVera` does not check the falling 2→1 step's size in Phrygian.** It now requires a minor third (or tenth), or a major sixth (or thirteenth), just before the octave or unison, in every mode. `lower_approach_half_step?` (`clausula_vera.rb:96-99`) measures only the rising voice. In E Phrygian, F♯→E against D→E passes as a clausula vera. `Diatonic` still marks the F♯, so the grade drops, but not from the cadence rule the criterion names.
3. **Resolved: a figure's stepwise run can cross a rest.** A rest now breaks the run in `FreeDissonanceTreatment`, so a dissonance entered from silence is marked; the species guides' figure detection is unchanged. `consonant_run?` reads `voice.notes`, so `c z d e` explains the dissonant D as a passing tone. `NoRestsAfterNote` in the melody guide marks the rest, so this is mostly covered.

Observation, not a defect: with meter-based downbeats, a perfect fifth tied over a barline in both voices is marked as parallel fifths on downbeats, as a re-struck fifth already is. Only free species can produce it.

Nothing blocks `finish`. All three findings are resolved.
