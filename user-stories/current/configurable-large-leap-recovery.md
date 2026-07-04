<!--
metadata:
  created_at:   2026-07-03T17:02:53-07:00
  activated_at: 2026-07-03T17:06:40-07:00
  planned_at:
  finished_at:
  updated_at:   2026-07-03T17:19:57-07:00
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

## Sources

- Johann Joseph Fux, *Gradus ad Parnassum* (1725) — recovery of the ascending minor sixth and octave; descending sixth forbidden.
- Felix Salzer & Carl Schachter, *Counterpoint in Composition* (1969).
- Arnold Schoenberg, *Preliminary Exercises in Counterpoint* (1963).
- Ferdinand Davis & Donald Lybbert, *The Essentials of Counterpoint* (1969).
- Knud Jeppesen, *Counterpoint: The Polyphonic Vocal Style of the Sixteenth Century* (1931) — leap larger than a third answered by a step in the opposite direction.
