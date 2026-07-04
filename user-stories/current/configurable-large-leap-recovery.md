<!--
metadata:
  created_at:   2026-07-03T17:02:53-07:00
  activated_at: 2026-07-03T17:06:40-07:00
  planned_at:   2026-07-03T17:36:12-07:00
  finished_at:
  updated_at:   2026-07-03T17:58:11-07:00
-->

# Make Large-Leap Recovery Configurable

AS a counterpoint researcher

I WANT the large-leap recovery guideline to be configurable — the minimum qualifying interval and the permitted recovery modes — through the `Annotation.with(...)` factory

SO THAT different styles can express their own leap conventions from one guideline instead of hard-coded subclasses, and so that "how large is a large leap" is a per-style parameter rather than a fixed global

## Background

Leap-recovery rules currently exist as two classes: `Guidelines::RecoverLargeLeaps` (strict — a large leap must be answered by a step in the opposite direction, unless it spells a consonant triad) and its subclass `Guidelines::SingleLargeLeaps` (looser — a large leap is acceptable when answered by a step, a repetition, a triad spelling, or any change of direction; only a same-direction follow-up leap is flagged).

Both delegate "is this a large leap?" to `Analysis::DiatonicInterval::Category#large_leap?`, which is defined as `number > 3` — i.e. **a fourth or larger**. That threshold is the crux of this story.

**Motivating evidence.** While anchoring the modern cantus firmus guide to Salzer & Schachter, we tested swapping the strict `RecoverLargeLeaps` onto it. It flagged **four real published canti firmi** (three from Davis & Lybbert, one from Schoenberg) — every failure was an ordinary **fourth** continued by a same-direction step (e.g. `D–G–A`) or answered by a third. In the sourced pedagogy a fourth is a free, ordinary leap; only a **fifth or larger** (Fux: sixth/octave; Jeppesen: anything above a third) calls for opposite-direction-step recovery. So the fixed `number > 3` threshold conflates a modeling wart with a style rule, and it is why the looser `SingleLargeLeaps` had to be used as a workaround.

The minimum qualifying interval genuinely varies by style:

- **Fux** — recover the ascending minor sixth and the octave; the descending sixth is forbidden outright; recovery is often a third back into the leap.
- **Salzer & Schachter / modern corpus** — fourths are free; fifths are recovered or spell a consonant triad.
- **Jeppesen (16th-century)** — a leap larger than a *third* is answered by a step in the opposite direction; the sixth appears only as an ascending minor sixth.

## Current State

- `Guidelines::RecoverLargeLeaps` — base rule; `unrecovered_leap?` requires a direction change and a step after any `large_leap?`, with a consonant-triad exception.
- `Guidelines::SingleLargeLeaps < RecoverLargeLeaps` — overrides `unrecovered_leap?` to also accept repetition and any direction change; flags only a same-direction follow-up leap.
- Both use the shared `Category#large_leap? => number > 3`.
- Consumers: `FuxCantusFirmus` uses `RecoverLargeLeaps`; `SalzerSchachterCantusFirmus` and `DiatonicMelody` use `SingleLargeLeaps`.
- The configuration mechanism already exists: `Annotation.with(...)` returns an `Annotation::Configured` wrapper (see `MinimumNotes.with(8)`, `DirectionChanges`, etc.).

## Design direction

Collapse the two classes into one configurable guideline (following the pattern used for `MinimumNotes`/`MaximumNotes` and the direction-change family) and **replace `RecoverLargeLeaps` and `SingleLargeLeaps` outright**: delete both classes and their specs, and switch `FuxCantusFirmus`, `SalzerSchachterCantusFirmus`, and `DiatonicMelody` to the new guideline. No thin aliases are kept.

Configuration parameters:

- **`minimum`** — the smallest interval that qualifies as a "large leap" needing recovery. Accepts anything `DiatonicInterval.get()` accepts: a symbol (`:perfect_fifth`) or a `DiatonicInterval` object. The guideline resolves the threshold itself; it must **not** depend on the shared `Category#large_leap?`.
- **Independent ascending / descending thresholds** — the qualifying interval is configurable per direction, so a style can treat the two directions asymmetrically (Fux forbids the descending sixth outright while permitting the ascending minor sixth). A single `minimum:` applies to both directions unless a direction-specific value overrides it.
- **`recovery`** — which resolutions count as acceptable: opposite-direction step (always), repetition, consonant-triad spelling, any change of direction, opposite-direction leap not exceeding the original.
- **Consecutive-leap limit** — a "no more than N leaps in a row" constraint lives in this guideline (not a separate one).

A sketch (exact API to be settled in implementation):

```ruby
# strict, fifth-or-larger
LargeLeaps.with(minimum: :perfect_fifth, recovery: [:opposite_step, :triad])
# looser modern rule, reproducing today's SingleLargeLeaps behavior
LargeLeaps.with(minimum: :perfect_fifth, recovery: [:opposite_step, :repetition, :triad, :direction_change])
# asymmetric, capped consecutive leaps (Fux-like): permit ascending m6, forbid descending 6th
LargeLeaps.with(ascending: :minor_seventh, descending: :major_sixth, maximum_consecutive_leaps: 2, recovery: [:opposite_step, :triad])
```

Do **not** change `Analysis::DiatonicInterval::Category#large_leap?`; other code (`Voice#large_leaps`, analysis) relies on it. Localize the threshold to the guideline.

## Scenario: Minimum qualifying interval is configurable

Given a melodic line containing an ascending fourth followed by a same-direction step

When it is analyzed by a large-leap guideline configured with a minimum of a perfect fifth

Then the fourth is not treated as a large leap and is not flagged

And when the same line is analyzed with a minimum of a perfect fourth

Then the fourth qualifies as a large leap and its recovery is evaluated

## Scenario: Recovery modes are configurable

Given a large leap answered by a note repetition

When it is analyzed with a recovery set that includes repetition

Then it is not flagged

And when it is analyzed with a strict recovery set that requires an opposite-direction step

Then it is flagged

## Scenario: Ascending and descending thresholds are independent

Given a guideline configured to permit the ascending minor sixth but forbid the descending sixth

When a melody containing an ascending minor sixth is analyzed

Then the ascending minor sixth is not flagged

And when a melody containing a descending sixth is analyzed

Then the descending sixth is flagged

## Scenario: Consecutive leaps are limited

Given a melodic line with three leaps in a row

When it is analyzed with a maximum of two consecutive leaps

Then the run of leaps is flagged

And when a line with only two leaps in a row is analyzed under the same limit

Then it is not flagged

## Scenario: Existing guides preserve current behavior

Given the Fux, Salzer & Schachter, and diatonic-melody guides

When they adopt the configurable large-leap guideline

Then each reproduces its current ruleset behavior via configuration

And the full style suite remains green, including the Davis & Lybbert and Schoenberg cantus firmus corpora

## Scenario: The shared large-leap predicate is untouched

Given the change

When I inspect `Analysis::DiatonicInterval::Category#large_leap?`

Then its definition is unchanged

And `Voice#large_leaps` and other analysis consumers behave as before

## Decisions

Resolving the open questions:

- **Interval configuration form** — accept anything `DiatonicInterval.get()` accepts: a symbol (`:perfect_fifth`) or a `DiatonicInterval` object.
- **Ascending vs. descending** — configurable independently, so a style can treat the two directions asymmetrically (Fux forbids the descending sixth while permitting the ascending minor sixth).
- **"No more than two leaps in a row"** — lives in this guideline, as a configurable consecutive-leap limit.
- **`RecoverLargeLeaps` / `SingleLargeLeaps`** — replaced outright. Both classes and their specs are removed and every consumer switches to the new configurable guideline; no thin aliases are kept.

## Implementation Plan

### Overview

Replace `RecoverLargeLeaps` (strict, Fux) and `SingleLargeLeaps` (loose, S&S + DiatonicMelody) with a single configurable guideline `HeadMusic::Style::Guidelines::LargeLeaps < HeadMusic::Style::Annotation`. Configuration flows through the existing `Annotation.with(**options)` → `Configured` mechanism (no override needed). Leap-size thresholds compare by **diatonic number** (not semitones) so the default reproduces `Category#large_leap?` exactly and that frozen method is never touched. Recovery modes are a set of symbols dispatched to private predicates; a per-direction "forbidden outright" ceiling and a `maximum_consecutive_leaps` cap are added. All three guides are reconfigured to reproduce today's behavior (Fux gaining the one intended new rule: descending sixth forbidden), and the 4-corpora regression guard must stay green.

### Steps

1. **Create the new guideline** — `lib/head_music/style/guidelines/large_leaps.rb`
   - Class `HeadMusic::Style::Guidelines::LargeLeaps < HeadMusic::Style::Annotation`. Name subsumes both classes and matches pluralized-noun guideline naming (`SingleLargeLeaps`, `LimitOctaveLeaps`).
   - **Do not override `self.with`** — the base `self.with(**options)` already threads keywords through `Configured` into `initialize(voice, **options)`. Five options make positional a non-starter; keyword-only is self-documenting.
   - Centralize defaults in one frozen constant merged once, lazily:
     ```ruby
     DEFAULTS = {
       minimum: :perfect_fourth,
       descending: nil,          # per-direction override hash or nil
       ascending: nil,
       recovery: %i[consonant_triad any_step repetition opposite_leap_within],
       maximum_consecutive_leaps: nil,
       message: "Recover leaps by step, repetition, opposite direction, or spelling triad."
     }.freeze
     ```
     `config = @config ||= DEFAULTS.merge(options)`; expose thin private readers. `message` reads `config.fetch(:message)` (overrides base `Annotation#message`) — load-bearing, see Testing.

2. **Localize the qualifying-leap test by diatonic number** (same file)
   - Normalize each threshold once: `HeadMusic::Analysis::DiatonicInterval.get(minimum).number`, memoized. Reach the number via `pair.diatonic_interval.number`.
   - `qualifies?(pair)` = `pair.diatonic_interval.number >= threshold_number(pair.direction)`. Default `minimum: :perfect_fourth` → `number >= 4` → identical to `large_leap?` (`number > 3`). `Category#large_leap?` is never called or modified.
   - **Semitones-vs-number: number, deliberately.** `DiatonicInterval#<=>` compares by semitones, which diverges at altered intervals (aug-4 = 6 st but number 4). Number preserves current classification. A semitone gate (e.g. "forbid the tritone") would be a *separate* option — do not overload `minimum`.

3. **Model recovery modes as a symbol set dispatched to predicates** (same file)
   - `recovered?(first, second, third)` = `recovery.any? { |mode| send("recovered_by_#{mode}?", ...) }`.
   - **Distinguish `:opposite_step` (strict, Fux) from `:any_step` (loose).** Conflating them breaks the loose guides.
     - `recovered_by_consonant_triad?` → `first.spells_consonant_triad_with?(second) || second.spells_consonant_triad_with?(third)`
     - `recovered_by_opposite_step?` → `direction_changed?(first, second) && second.step?`
     - `recovered_by_any_step?` → `second.step?`
     - `recovered_by_repetition?` → `second.repetition?`
     - `recovered_by_opposite_leap?` → `direction_changed?(first, second) && second.leap?` (current unbounded loose behavior)
     - `recovered_by_opposite_leap_within?` → adds `second.diatonic_interval.number <= first.diatonic_interval.number` (the story's "not exceeding original" mode; in no default — unit-test directly)
   - Keep `direction_changed?` copied from the old class. No lambda registry / mode hierarchy.

4. **Express "forbidden outright" as a per-direction ceiling** (same file)
   - `ascending`/`descending` accept `{minimum:, forbidden:}` (or a bare interval as shorthand for `{minimum:}`); `nil` falls back to top-level `minimum` with no ceiling.
   - `forbidden?(pair)` = a ceiling exists for the pair's direction and `pair.diatonic_interval.number >= ceiling_number`. Flagged regardless of recovery.
   - `unrecovered_leap?(first, second, third)`: `return false unless qualifies?(first)`; `return true if forbidden?(first)`; `!recovered?(first, second, third)`. Read direction from the note-pair (`MelodicInterval#ascending?/descending?`).

5. **Recovery-mark scan — preserve `each_cons(3)` and end-of-line behavior; memoize** (same file)
   - `marks = @marks ||= recovery_marks + consecutive_leap_marks`. Base `fitness`/`start_position`/`end_position` each call `marks`; memoize (immutable `melodic_note_pairs`, `[]` truthy).
   - `recovery_marks`: `melodic_note_pairs.each_cons(3).map { |a,b,c| Mark.for_all((a.notes + b.notes).uniq) if unrecovered_leap?(a,b,c) }.compact`. Same shape as the old class — the property that a large leap in the **last two** melodic intervals is never evaluated is preserved byte-for-byte. Do not "fix" it; corpus expectations depend on it.

6. **Consecutive-leap cap as an independent `chunk`-based scan** (same file)
   - Return `[]` when `maximum_consecutive_leaps` is nil. Otherwise group with `chunk` (not a manual counter — avoids the end-of-array-not-flushed bug):
     ```ruby
     melodic_note_pairs.chunk { |p| counts_as_run_member?(p) }
       .select { |member, _run| member }.map { |_m, run| run }
       .select { |run| run.length > cap }
       .map { |run| Mark.for_all(run.flat_map(&:notes).uniq) }
     ```
   - `counts_as_run_member?` counts only *qualifying* leaps (`qualifies?`), not every `leap?` — else a `max: 2` cap trips on an innocent three-thirds arpeggiation. A step/repetition resets the run. **(Confirm — see Risks.)**
   - With `cap: nil` in all three current guides this yields `[]`; output stays byte-identical.

7. **Reconfigure the three consumer guides**
   - `lib/head_music/style/guides/fux_cantus_firmus.rb` — replace `RecoverLargeLeaps` with:
     ```ruby
     HeadMusic::Style::Guidelines::LargeLeaps.with(
       message: "Recover large leaps by step in the opposite direction.",
       minimum: :perfect_fourth,
       descending: {minimum: :perfect_fourth, forbidden: :minor_sixth},
       recovery: %i[consonant_triad opposite_step]
     )
     ```
     Reproduces `RecoverLargeLeaps` exactly, plus the intended descending-sixth ceiling (m6/M6 both number 6). Message preserved — asserted in the corpus fixture.
   - `lib/head_music/style/guides/salzer_schachter_cantus_firmus.rb` and `lib/head_music/style/guides/diatonic_melody.rb` — replace `SingleLargeLeaps` with the explicit loose config (defaults would also suffice):
     ```ruby
     HeadMusic::Style::Guidelines::LargeLeaps.with(
       minimum: :perfect_fourth,
       recovery: %i[consonant_triad any_step repetition opposite_leap_within]
     )
     ```

8. **Delete the old classes and wire up requires**
   - Delete `recover_large_leaps.rb`, `single_large_leaps.rb`, and their two spec files.
   - In `lib/head_music.rb`: remove the two `require` lines; add `require "head_music/style/guidelines/large_leaps"` in the alphabetical slot. No aliases.

9. **Update RULESET-membership guide specs** — deleting the classes breaks these independently of behavior. Update the `configured(...)`/membership assertions in `fux_cantus_firmus_spec.rb`, `salzer_schachter_cantus_firmus_spec.rb`, and `diatonic_melody_spec.rb` to the new `LargeLeaps` configs. The Fux error fixture in `spec/spec_helper.rb` is unaffected because `message:` preserves its asserted string.

### API & config decisions

- Reuse `Annotation.with`/`Configured` + `config.fetch`; no new config object, no `self.with` override. Keyword-only options: `minimum`, `ascending`, `descending`, `recovery`, `maximum_consecutive_leaps`, `message`.
- Defaults reproduce loose behavior — one frozen `DEFAULTS` merged once, normalized once.
- `message` varies by config and is a regression contract, not cosmetic.
- Absolute size caps (octaves) stay in `LimitOctaveLeaps`/`PrepareOctaveLeaps` (already in `MELODIC_CORE`) — do not duplicate here or you double-flag.

### Testing strategy

New spec `spec/head_music/style/guidelines/large_leaps_spec.rb`, using the voice idiom from the deleted specs. Cases mapped to acceptance scenarios:

- **(a) minimum configurable** — unrecovered ascending fourth adherent at `minimum: :perfect_fifth`, flagged at `:perfect_fourth`; add an augmented-fourth variant to lock the number-not-semitones decision.
- **(b) recovery modes** — large leap + repeated note adherent with `:repetition` in the set, flagged without.
- **(c) independent asc/desc** — ascending m6 recovered by opposite step adherent (Fux config); descending sixth flagged (ceiling); descending fifth recovered still adherent.
- **(d) consecutive-leap cap** — three qualifying leaps flagged at `max: 2`; two adherent; a run broken by a step adherent.
- **(e) drop-in equivalence** — port every scenario from the two deleted specs under the loose config, plus the Fux F-lydian triad example under the strict config.
- **(f) `Category#large_leap?` untouched** — assert `Category.new(4).large_leap?` true, `Category.new(3)` false.
- Cover `:opposite_leap_within` directly (in no default → otherwise uncovered against the 90% floor). Degenerate: < 3 note-pairs → no marks, no error.

Regression sequence:

1. **Before** snapshot on `main`: `bundle exec rspec spec/head_music/style --format documentation | tee before.txt`.
2. Land guideline + consumer swaps + membership specs in one commit (the corpora guard can't pass in an intermediate state).
3. **Gate — 0 failures:** `bundle exec rspec spec/head_music/style` (exercises `salzer_schachter_cantus_firmus_spec.rb` against all four corpora — D&L and Schoenberg use fourths freely).
4. `bundle exec rake` (90% floor), `bundle exec rubocop -a`, `bundle exec rake validate`.
5. Diff before/after docs for the three guides — expect zero behavioral deltas except the intended Fux descending-sixth ceiling.

### Resolved sign-off & residual risks

Resolved with the product owner:

1. **Descending "forbidden" threshold = ≥ a sixth** (`forbidden: :minor_sixth`, which also catches descending 7ths/octaves). Hand-checked: no Fux cantus firmus contains a descending interval ≥ a sixth, so the Fux corpus is unaffected.
2. **Consecutive-leap cap counts only *qualifying* leaps** (≥ threshold), grouped over note-pairs; a run longer than the cap marks the notes of the run.
3. **"Forbidden" is un-redeemable** — a forbidden-direction leap is flagged regardless of any recovery (Step 4 as written).
4. **Opposite-leap recovery is bounded** (`:opposite_leap_within`) on the loose guides, replacing the unbounded `:opposite_leap` — correctness is preferred over strict behavior preservation. If bounding newly flags a Davis & Lybbert / Schoenberg / Clendinning cantus firmus, that fixture's expectation is updated to reflect the flag, and the specific canti firmi affected are reported for confirmation (not silently reclassified).
5. **No-options default reproduces the corrected (bounded) loose behavior.**

Residual risks / edge cases:

- **End-of-line `each_cons(3)` blind spot:** a large leap into the final/penultimate note is never evaluated (preserved intentionally). Documented, not fixed.
- **Augmented-fourth vs perfect-fifth at a threshold:** number-based comparison classifies an augmented fourth as number 4; locked by a dedicated test.
- **Bounding on the S&S guide asserts a stricter rule than Salzer & Schachter may themselves hold** — accepted under the correctness-first decision; any newly-flagged corpus lines are eyeballed to confirm they read as genuine faults.

## Sources

- Johann Joseph Fux, *Gradus ad Parnassum* (1725) — recovery of the ascending minor sixth and octave; descending sixth forbidden.
- Felix Salzer & Carl Schachter, *Counterpoint in Composition* (1969).
- Arnold Schoenberg, *Preliminary Exercises in Counterpoint* (1963).
- Ferdinand Davis & Donald Lybbert, *The Essentials of Counterpoint* (1969).
- Knud Jeppesen, *Counterpoint: The Polyphonic Vocal Style of the Sixteenth Century* (1931) — leap larger than a third answered by a step in the opposite direction.
