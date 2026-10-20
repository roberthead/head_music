<!--
metadata:
  created_at:   2026-09-18T15:24:10-07:00
  activated_at: 2026-10-19T09:05:05-07:00
  planned_at:   2026-10-19T21:23:40-07:00
  finished_at:
  updated_at:   2026-10-19T21:23:40-07:00
-->

# Grade Contour Misses by Degree

AS a student submitting a melody to a contour guide

I WANT a melody with the wrong contour to score worse than one that nearly has
the right contour

SO THAT a valley handed to `arch_contour_melody` is not graded as a near-miss
arch

Split out of [Require the Species Rhythm](../done/require-the-species-rhythm.md),
which inherited it from
[Extract the Harmonic Cores](../done/extract-the-harmonic-cores.md). It is
unrelated to species rhythm and is decided on its own terms.

## The defect

`Contoured` marks every mismatched contour at φ⁻², the factor for a near miss:

```ruby
def marks
  return if notes.empty? || matches_contour?

  HeadMusic::Style::Mark.for_all(notes, fitness: HeadMusic::GOLDEN_RATIO_INVERSE**2)
end
```

Graded against `arch_contour_melody` as of 2026-10-19:

| Melody | Contour mark | Guide grade |
| --- | --- | --- |
| Arch, centered climax | 1.0 | 0.994 |
| Arch, off-center climax (rises nine notes, falls three) | 1.0 | 0.991 |
| Valley | 0.382 | 0.612 |
| Ascending line (an arch missing its descent) | 0.382 | 0.605 |
| Wave | 0.382 | 0.568 |

A valley is not a near-miss arch, yet it marks the same as an arch missing a
leg.

## Shapes and directions

Four terms, used only in these senses:

- A **contour** is any of the six things a contour guide asks for: the
  `Contoured::CONTOURS` keys.
- A **shape** is what a melody does between its endpoints: arch, valley, and
  wave, read from the legs.
- A **direction** is where a melody ends up compared with where it began:
  ascending, descending, and level. Ascending and descending are read from the
  endpoints; static is the level direction, read from the range.
- A **leg** is one rise or one fall, the unit a shape is made of. It reverses
  only once the melody retraces `TREND_REVERSAL_SEMITONES` from its running
  extreme. `Contoured#trend_directions` finds the legs today.

Each shape requires a leg sequence:

| Contour | Required legs |
| --- | --- |
| arch | rise, fall |
| valley | fall, rise |
| wave | three or more alternating legs, starting with either |

Where the climax falls is not tested. An off-center climax is a full arch, as
it is today.

## Degree of miss

Align the required sequence with the actual legs wherever it fits best. Each
extra leg before or after the alignment is one degree of miss, and so is each
required leg that is missing. Against an arch:

| Actual legs | Extra | Missing | Degree |
| --- | --- | --- | --- |
| rise, fall | 0 | 0 | 0 |
| rise, fall, rise (C4 E4 G4 A4 G4 D4 B3 D4) | 1 | 0 | 1 |
| fall, rise, fall | 1 | 0 | 1 |
| rise (an ascending scale) | 0 | 1 | 1 |
| fall (a descending scale) | 0 | 1 | 1 |
| rise, fall, rise, fall (a wave) | 2 | 0 | 2 |
| fall, rise (a valley) | 1 | 1 | 2 |
| no legs | 0 | 2 | 2 |

Extra and missing legs weigh the same, so against an arch a valley ties a
four-leg wave. That is accepted, because one count is easy to explain to a
student.

Against a wave, a melody never has extra legs. Two legs is one degree, one leg
two, and none three.

The mark is φ⁻² per degree, φ⁻²ᵈ, so one degree costs what every mismatch costs
today. The mark never reaches 0, because the gem discounts a grade rather than
disqualifying it. With every secondary guideline adherent:

| Degree | Mark | Guide grade |
| --- | --- | --- |
| 0 | 1.0 | 1.0 |
| 1 | 0.382 | 0.618 |
| 2 | 0.146 | 0.472 |
| 3 | 0.056 | 0.416 |

## Ascending and descending are directions

An ascending melody starts at its lowest pitch and ends at its highest, and a
descending one the reverse, as today but with a tolerance. Legs play no part:
what happens between the endpoints is shape, not direction.
C4 D4 E4 C4 D4 E4 F4 D4 E4 G4 A4 is five legs (rise, fall, rise, fall, rise) and
a full ascending match.

The one-leg shape a scale has is left to its own guide, in
[Straight Contour](../backlog/straight-contour.md).

The endpoint test allows the same tolerance as the legs: the first note may sit
less than `TREND_REVERSAL_SEMITONES` above the lowest pitch, and the last less
than that below the highest. A wobble too small to make a leg is too small to
spoil a direction.

A melody that fails the test misses by one degree for each endpoint condition
it fails, marked at φ⁻²ᵈ like the shapes. Descending mirrors this:

| Melody against ascending | First near lowest | Last near highest | Degree |
| --- | --- | --- | --- |
| C4 up to C5 | ✓ | ✓ | 0 |
| C4 up to C5, ending on B4 | ✓ | ✓ | 0 |
| D4 C4 E4 G4 A4 G4 | ✓ | ✓ | 0 |
| C4 up to C5, ending on A4 | ✓ | ✗ | 1 |
| an arch from C4 back to C4 | ✓ | ✗ | 1 |
| C5 down to C4 | ✗ | ✗ | 2 |

## Static is unchanged

Static, the level direction, stays a range test (within a major third, without
directional endpoints), and a static mismatch keeps today's φ⁻² mark. Its
directional endpoints check stays strict: within a major third, the tolerance would call
nearly every melody directional, and C4 D4 E4 D4 would stop being static.

## The floor

`ContourMelody` declares `Contoured` as its only primary item, with
`DiatonicMelody`'s primaries as secondary. `GuideAssessment::TIER_BUDGETS` gives
the primary tier a fixed φ⁻¹ of the rubric and the secondary tier φ⁻², so with
every secondary adherent a guide grades φ⁻¹ × mark + φ⁻². As the degree grows,
the grade approaches 0.382 and never goes below it. That floor is accepted;
changing the rubric's shape is a separate decision.

The contour cannot be a gate. A gate is a precondition: a voice that fails one
is unassessable and its rubric is never computed.

## Acceptance Criteria

- Arch, valley, and wave mark at φ⁻²ᵈ by degree of miss from their required
  legs.
- With every secondary adherent, a valley submitted to `arch_contour_melody`
  marks at φ⁻⁴ and grades about 0.472, and a melody one degree from an arch
  marks at φ⁻² and grades about 0.618.
- Ascending and descending mark at φ⁻²ᵈ by the number of endpoint conditions
  failed, within the legs' tolerance and ignoring the legs themselves.
  C4 D4 E4 C4 D4 E4 F4 D4 E4 G4 A4 and D4 C4 E4 G4 A4 G4 are full ascending
  matches, and a descending scale marks at φ⁻⁴ against ascending.
- Static grades as it does today.
- A failure message names how the melody missed: the extra or missing legs for
  a shape, the failed endpoint for a direction.
- `Contoured`'s comment states that arch, valley, and wave are shapes graded by
  legs, ascending and descending are directions graded by endpoints, and
  static is the level direction graded by range.
- The pinned corpus grades (`spec/fixtures/style/corpus_fitness.json`) are
  regenerated with `rake style:snapshot_corpus_fitness`, and every changed row
  is reviewed as intended. 79 `arch_contour_melody` rows sit at exactly 0.618
  today. Arch, valley, wave, ascending, and descending rows may move; static
  rows must not.

## Notes

[Improve Melodic Contour Guidelines](../done/improve-melodic-contour-guidelines.md)
is the most recent work on `Contoured` and explains today's matcher.

`spec/head_music/style/guides/contour_melody_spec.rb` pins a wrong-contour
sawtooth "into the soft floor" at 0.3 to 0.55, which may need revisiting.

The code uses "direction" for legs: `Contoured#trend_directions` returns
`:ascending` and `:descending` per leg, and `TrendWalk` has a `direction`
field. Rename them to `legs`, returning `:rise` and `:fall`, so that direction
means only what this story means by it. Both are private to `Contoured`.

## Implementation Plan

### Overview

`Contoured` computes one memoized `degree` per contour and marks a miss as a
single `Mark.for_all` at φ⁻²ᵈ:

- **Shapes** (arch, valley, wave): extra legs plus missing legs.
- **Directions** (ascending, descending): failed endpoint conditions, each with
  the `TREND_REVERSAL_SEMITONES` tolerance.
- **Static**: keeps its strict range test, and a miss is degree 1.

The violation message comes from a closed set of keys, following
`ConsonantClimax`. Every key renders from `%{contour}` alone, so
`violation_values` stays `{}`.

A scratchpad prototype regraded the corpus. 269 contour rows changed, and no
row of `static_contour_melody` or of any non-contour guide changed.

### Steps

1. **Rename legs (refactor, no behavior change).**
   - Rename `trend_directions` to `legs`, returning `:rise` and `:fall`.
   - Change the struct to `TrendWalk = Struct.new(:legs, :leg, :high, :low, :extreme)`.
   - Rename `advance_trend`, `seek_trend`, `continue_trend`, `start_trend`, and
     `opposite_direction` to `advance_leg`, `seek_leg`, `continue_leg`,
     `start_leg`, and `opposite_leg`.
   - Compare `arch?` and `valley?` against `%i[rise fall]` and `%i[fall rise]`.
   - Nothing outside `contoured.rb` reaches these names. Rename any "trend"
     wording in spec descriptions too.
   - The corpus is unchanged.
2. **Grade shapes by degree.**
   - Add `REQUIRED_LEGS = {arch: %i[rise fall], valley: %i[fall rise]}`,
     `WAVE_LEGS = 3`, and `LegMiss = Data.define(:extra, :missing)`.
   - For a wave, `missing = max(0, 3 - legs.length)` and `extra = 0`.
   - For arch and valley, `matched` is 2 if
     `legs.each_cons(2).include?(required)`, otherwise
     `[legs.length, 1].min`. Then `extra = legs.length - matched` and
     `missing = 2 - matched`. This works because legs alternate: a single leg
     always matches one end of the pair, and three or more legs always contain
     it.
   - Add a memoized `degree`, used by `marks` and `violation_key`.
   - `marks` returns nothing when `notes.empty? || degree.zero?`, and otherwise
     `Mark.for_all(notes, fitness: HeadMusic::GOLDEN_RATIO_INVERSE**(2 * degree))`.
   - `fitness_denominator` defaults to 1, so `Guideline#fitness` is exactly
     φ⁻²ᵈ.
   - This reproduces every row of the story's arch table and the wave rule.
   - Regenerate the corpus in this commit. Expect about 70 arch, 89 valley,
     and 8 wave rows to change.
3. **Grade directions by tolerant endpoints, and keep static strict.**
   - Add a memoized `failed_endpoints`:
     - The extremes are `[low, high]` for ascending and `[high, low]` for
       descending, from `pitch_numbers.minmax`.
     - The result lists `:start` unless the first note is near the start
       extreme, and `:end` unless the last note is near the end extreme.
     - `near?(number, extreme)` is
       `(number - extreme).abs < TREND_REVERSAL_SEMITONES`.
   - The degree for a direction is `failed_endpoints.length`.
   - `directional_endpoints?` keeps the strict test inline, with its range
     guard and comment. The tolerant test never touches static.
   - Remove `ascending?`, `descending?`, `matches_contour?`, `arch?`,
     `valley?`, and `wave?`, which `degree` replaces.
   - Replace the class comment with a brief one stating the shape, direction,
     and level-by-range split and the φ⁻² cost per degree.
   - Regenerate the corpus. Expect about 46 ascending and 56 descending rows
     to change, about 10 of them rising.
4. **Failure messages name the miss.**
   - `self.violation_keys(config)` returns `super` plus the miss keys for the
     configured contour, and an instance `violation_key` picks one.
   - The instance method falls back to the default when
     `notes.empty? || degree.zero? || contour == :static`, because `.assess`
     calls it on adherent voices too.
   - Keys:
     - Directions: `ascending_start`, `ascending_end`,
       `ascending_start_and_end`, and the matching `descending_*` keys.
     - Shapes:
       - `reversed_legs`: both extra and missing legs, as for a valley against
         an arch.
       - `extra_legs`: extra legs only.
       - `missing_rise` or `missing_fall`: arch or valley missing exactly one
         leg.
       - `missing_legs`: otherwise, including a wave with too few legs.
     - Static keeps the default.
   - Templates interpolate only `%{contour}`. `guide_strings_spec` renders
     every declared key without `violation_values`, so a count or a leg name
     would not render.
   - Add the English strings under `guidelines.contoured.violations` in
     `en.yml`:
     - "a minor third" names the three-semitone leg threshold.
     - "within a whole step" names the endpoint tolerance.
     - No other locale has contour strings, so they fall back to English as
       today.
   - Regenerate `spec/fixtures/style/english_strings.yml` with
     `rake style:snapshot_english`.
5. **CHANGELOG and corpus review.**
   - Add a **Breaking.** entry under Unreleased, `### Changed`. It covers the
     degree grading, the shape and direction readings, the tolerance, the
     valley-against-arch example (0.618 to about 0.472), and the new messages.

### Testing Strategy

`contoured_spec.rb` asserts, for each example, the mark (`eq` φ⁻²ᵈ), a single
mark, and the chosen violation key. The melodies are ABC:

- **Arch:**

  | Melody | Degree | Key |
  | --- | --- | --- |
  | `CDEG\|EDC2\|` | 0 | adherent |
  | `CEGA\|GDB,D\|` | 1 | extra_legs |
  | `GECD\|EGFD\|` | 1 | extra_legs |
  | `CDEF\|G4\|` | 1 | missing_fall |
  | `GFED\|C4\|` | 1 | missing_rise |
  | `CDED\|CDEF\|EDC2\|` | 2 | extra_legs |
  | `GFED\|CDEF\|` | 2 | reversed_legs |
  | `CDCD\|C4\|` | 2 | missing_legs |

- **Valley:** `CDEG|EDC2|` is degree 2 (reversed_legs), and `CDEF|G4|` is
  degree 1 (missing_fall).
- **Wave:** `CDEG|EDC2|`, `CDEF|G4|`, and `CDCD|C4|` are degrees 1, 2, and 3,
  all missing_legs. The existing whole-step undulation example becomes φ⁻⁶.
- **Ascending:**

  | Melody | Degree | Key |
  | --- | --- | --- |
  | `CDEF\|GABc\|` | 0 | adherent |
  | `CDEF\|GABc\|B4\|` | 0 | adherent |
  | `DCEG\|AG2\|` | 0 | adherent |
  | `CDEC\|DEFD\|EGA2\|` | 0 | adherent |
  | `CDEF\|GABc\|A4\|` | 1 | ascending_end |
  | `CDEG\|EDC2\|` | 1 | ascending_end |
  | `cBAG\|FEDC\|` | 2 | ascending_start_and_end |

- **Descending:** mirrors ascending. The existing `CDED|EFG2|` example moves
  from φ⁻² to φ⁻⁴.
- **Static:**
  - `EEEE|E4|` and `CDED|C4|` stay static. The second pins why static's
    endpoint test stays strict.
- **Edge cases:**
  - An empty voice is adherent.
  - The chosen key is in `described_class.violation_keys(contour: ...)`.

`contour_melody_spec.rb`:

- **Valley against an arch:** `GFED|CDEF|` against `arch_contour_melody` with
  clean secondaries. Contoured marks `eq` φ⁻⁴, and the grade is
  `be_within(1e-6).of(φ⁻¹·φ⁻⁴ + φ⁻²)`, about 0.4721.
- **One degree:** `G4|F4|E4|D4|C4|` still grades exactly φ⁻¹. Reword its
  comment to say this holds for a one-degree miss.
- **Full ascending matches:** `CDEC|DEFD|EGA2|` and `DCEG|AG2|` grade 1.0
  against `ascending_contour_melody`.
- **Descending scale against ascending:** Contoured marks `eq` φ⁻⁴. Don't pin
  the grade, because ModerateDirectionChanges also fails there.
- **Sawtooth:** it is a three-degree miss, so it falls to about 0.281. Re-pin it
  `be_between(0.25, φ⁻²)`, with a one-line comment that its broken secondaries
  take it below the contour floor.
- **Messages:** examples that `not_to include(contour_message)` would pass
  vacuously once the messages change. Replace them with the Contoured
  assessment being adherent.

Corpus review, per grading commit:

1. Snapshot before the change with `bin/guide_grade_corpus.rb`.
2. Regenerate with `rake style:snapshot_corpus_fitness`.
3. Compare the two snapshots by guide. The only changed guides should be the
   five non-static contour guides.
4. List the rows whose `adherent` or `message_count` changed, and review the
   rows that rise.

Finish with `bundle exec rubocop -a` and `bundle exec rake validate`.

### Risks

- Some ascending and descending corpus rows rise because of the tolerance. They
  are the only grades in this story that go up, so review each one.
- Downstream consumers that match `"Write a melody with the arch contour."`
  stop matching for misses. That is why the CHANGELOG entry is marked
  **Breaking.**
- The prototype's corpus counts are estimates. Recheck them during
  implementation.
