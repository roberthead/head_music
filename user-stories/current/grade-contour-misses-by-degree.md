<!--
metadata:
  created_at:   2026-09-18T15:24:10-07:00
  activated_at: 2026-10-19T09:05:05-07:00
  planned_at:   2026-10-19T21:23:40-07:00
  finished_at:
  updated_at:   2026-10-20T14:30:00-07:00
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
  wave. An arch and a valley are read as a direction to the turn and another
  back from it; a wave is read from the legs.
- A **direction** is where a melody ends up compared with where it began:
  ascending, descending, and level. Ascending and descending are read from the
  endpoints; static is the level direction, read from the range.
- A **leg** is one rise or one fall, the unit a shape is made of. It reverses
  only once the melody retraces `TREND_REVERSAL_SEMITONES` from its running
  extreme. `Contoured#trend_directions` finds the legs today.

An arch splits at its climax into two halves. The **rise** runs from the first
note to the first climax, and is graded as ascending. The **fall** runs from
the last climax to the last note, and is graded as descending. A valley is the
mirror, split at its nadir.

Each half is held to a stricter retrace than a direction: it fails once it
turns back half its net change, not all of it. A turn back that large makes a
second hump, and a second hump makes a wave. So Fux's D F E D G F A G F E D is
an arch, because its opening dip of a third is less than half its climb of a
fifth. C E G E C D E F D C is a wave, because its second hump of a fourth is
more than half its fall of a fifth.

A repeated climax is one turn only when the line stays within a whole step of
it in between. Where the climax falls is not tested, so an off-center climax is
a full arch, as before.

A wave needs three or more alternating legs, starting with either. It must also
not read as a single arch or valley, which keeps the three shapes mutually
exclusive.

## Degree of miss

Against an arch, the degree is the sum of the two halves' direction degrees,
plus one for a dip between repeated climaxes. A climax on an endpoint leaves
that half a single note, which misses by one degree on its own:

| Melody against an arch | Rise | Fall | Dip between climaxes | Degree |
| --- | --- | --- | --- | --- |
| C4 D4 E4 G4 E4 D4 C4 | 0 | 0 | — | 0 |
| C4 E4 G4 A4 G4 D4 B3 D4 | 0 | 1 | — | 1 |
| C4 D4 E4 D4 C4 D4 E4 F4 E4 D4 C4 | 1 | 0 | — | 1 |
| an ascending scale | 0 | 1 | — | 1 |
| a descending scale | 1 | 0 | — | 1 |
| C4 D4 G4 E4 G4 E4 D4 C4 | 0 | 0 | 1 | 1 |
| G4 E4 C4 D4 E4 G4 F4 D4 | 1 | 0 | 1 | 2 |
| C4 D4 C4 D4 C4 | 1 | 1 | — | 2 |
| G4 F4 E4 D4 C4 D4 E4 F4 (a valley) | 1 | 2 | — | 3 |

Against a wave, each missing leg is one degree: two legs is one degree, one leg
two, and none three. A melody with legs enough that reads as a single arch or
valley misses by one degree.

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
descending one the reverse, as today but with a tolerance. The legs' sequence
plays no part: what happens between the endpoints is shape, not direction.
C4 D4 E4 C4 D4 E4 F4 D4 E4 G4 A4 is five legs (rise, fall, rise, fall, rise) and
a full ascending match.

The one-leg shape a scale has is left to its own guide, in
[Straight Contour](../backlog/straight-contour.md).

The endpoint test allows the same tolerance as the legs: the first note may sit
less than `TREND_REVERSAL_SEMITONES` above the lowest pitch, and the last less
than that below the highest. A wobble too small to make a leg is too small to
spoil a direction.

The endpoints alone cannot tell a direction from a level melody: E4 D4 E4 F4
E4 F4 E4 D4 E4 starts near its lowest pitch and ends near its highest. So a
direction has a third condition, by the same rule as the tolerance: the
melody must end at least `TREND_REVERSAL_SEMITONES` higher than it began. A
change too small to make a leg is too small to make a direction.

A melody can also start and end near its extremes and still only wander
between them. A fourth condition, the retrace, catches it: the farthest the
melody falls back from its running high must be less than its net rise.
A4 D5 A4 B4 C5 G4 A4 D5 B4 C5 D5 A4 C5 D5 E5 B4 D5 A4 B4 C♯5 D5 falls back
seven semitones within a net rise of five. A retrace is measured only when the
melody rises a leg, since there is no net rise to compare it with otherwise.

A melody misses by one degree for each condition it fails, marked at φ⁻²ᵈ
like the shapes. Rising a leg and the retrace never both fail, so a direction
misses by at most three degrees. Descending mirrors this:

| Melody against ascending | First near lowest | Last near highest | Rises a leg | Retrace short of the rise | Degree |
| --- | --- | --- | --- | --- | --- |
| C4 up to C5 | ✓ | ✓ | ✓ | ✓ | 0 |
| C4 up to C5, ending on B4 | ✓ | ✓ | ✓ | ✓ | 0 |
| D4 C4 E4 G4 A4 G4 | ✓ | ✓ | ✓ | ✓ | 0 |
| C4 up to C5, ending on A4 | ✓ | ✗ | ✓ | ✓ | 1 |
| C4 E4 G4 E4 C4 D4 E4 F4 | ✓ | ✓ | ✓ | ✗ | 1 |
| E4 D4 E4 F4 E4 F4 E4 D4 E4 | ✓ | ✓ | ✗ | — | 1 |
| C4 D4 C4 D4 | ✓ | ✓ | ✗ | — | 1 |
| an arch from C4 back to C4 | ✓ | ✗ | ✗ | — | 2 |
| C5 down to C4 | ✗ | ✗ | ✗ | — | 3 |

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

- Arch and valley mark at φ⁻²ᵈ, where the degree is the sum of their two
  halves' direction degrees, each half at half the retrace, plus one for a dip
  between repeated climaxes. Wave marks at φ⁻²ᵈ by its missing legs, or at φ⁻²
  when it reads as a single arch or valley. D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4
  is an arch, and C4 E4 G4 E4 C4 D4 E4 F4 D4 C4 is a wave.
- With every secondary adherent, a valley submitted to `arch_contour_melody`
  marks at φ⁻⁶ and grades about 0.416, and a melody one degree from an arch
  marks at φ⁻² and grades about 0.618.
- Ascending and descending mark at φ⁻²ᵈ by the number of conditions failed
  (start near its extreme, end near its extreme, net change of at least a
  leg, and, given that net change, a retrace short of it), ignoring the
  legs' sequence. C4 E4 G4 E4 C4 D4 E4 F4 marks at φ⁻² against ascending.
  C4 D4 E4 C4 D4 E4 F4 D4 E4 G4 A4 and D4 C4 E4 G4 A4 G4 are full ascending
  matches.
  E4 D4 E4 F4 E4 F4 E4 D4 E4 and C4 D4 C4 D4 mark at φ⁻² against both
  ascending and descending, and a descending scale marks at φ⁻⁶ against
  ascending.
- A contour miss is one mark spanning the melody, at φ⁻²ᵈ.
- Static grades as it does today. It reads a strict endpoint test separate
  from the tolerant one, so C4 D4 E4 D4 and E4 D4 E4 F4 E4 F4 E4 D4 E4 stay
  static.
- `Contoured` picks its violation from a closed set of keys, each rendered
  from the contour alone, and declares every key a contour can produce in
  `violation_keys(config)`:
  - An arch or valley with its climax (or nadir) on the last note says to add
    a fall (or rise), and on the first note to add a rise (or fall).
  - An arch or valley whose rise or fall turns back says to rise or fall
    steadily.
  - An arch or valley whose rise and fall both miss says to rise and fall.
  - A wave with too few legs says to rise or fall by more than a step at
    least three times.
  - An arch or valley that dips between repeated climaxes says to rise and
    fall fewer times.
  - A wave that reads as a single arch or valley says to turn more than once.
  - A mirror shape (a valley against an arch) says to reverse the rise and
    fall.
  - A direction that fails to rise (or fall) a leg says so, and so does one
    that turns back as far as it moves. Otherwise it names the endpoint or
    endpoints that failed.
  - Static keeps today's sentence.
- `trend_directions` and `TrendWalk#direction` are renamed to legs, returning
  `:rise` and `:fall`.
- `Contoured`'s comment states that arch and valley are shapes graded as a
  direction to the turn and back, wave is a shape graded by legs, ascending
  and descending are directions graded by endpoints and headway, and static is
  the level direction graded by range.
- The pinned corpus grades (`spec/fixtures/style/corpus_fitness.json`) are
  regenerated with `rake style:snapshot_corpus_fitness`, and every changed row
  is reviewed as intended. 79 `arch_contour_melody` rows sit at exactly 0.618
  today. Arch, valley, wave, ascending, and descending rows may move; static
  rows must not. Some ascending and descending rows rise, where an endpoint
  sits within a whole step of its extreme, and each one is reviewed.
- The pinned English strings (`spec/fixtures/style/english_strings.yml`) are
  regenerated with `rake style:snapshot_english`, and the new contour
  sentences are reviewed.
- The sawtooth in `contour_melody_spec.rb` is re-pinned at its new grade,
  about 0.48. Its sevenths are small beside its climb of nearly two octaves,
  so it reads as an arch missing its fall, one degree off, and its broken
  secondaries take it below a near-miss arch.
- `contoured_spec.rb`'s descending example against `CDED|EFG2|` moves from
  φ⁻² to φ⁻⁶, since it fails all three conditions.

## Notes

[Improve Melodic Contour Guidelines](../done/improve-melodic-contour-guidelines.md)
is the most recent work on `Contoured` and explains today's matcher.

The code uses "direction" for legs: `Contoured#trend_directions` returns
`:ascending` and `:descending` per leg, and `TrendWalk` has a `direction`
field. The rename criterion above fixes that, so that direction means only
what this story means by it. Both are private to `Contoured`.

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
       extreme, `:end` unless the last note is near the end extreme, and
       `:rise` (or `:fall`) unless the last note is at least
       `TREND_REVERSAL_SEMITONES` beyond the first in the contour's direction.
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
     - Directions: `ascending_rise` when the net rise fails, since that is
       the direction itself. Otherwise `ascending_start`, `ascending_end`, or
       `ascending_start_and_end`. The `descending_*` keys mirror these, with
       `descending_fall`.
     - Shapes:
       - `reversed_legs`: both extra and missing legs, as for a valley against
         an arch.
       - `extra_legs`: extra legs only.
       - `missing_rise` or `missing_fall`: arch or valley missing exactly one
         leg.
       - `missing_legs`: arch or valley with no legs.
       - `too_few_legs`: any wave miss.
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
  all too_few_legs. The existing whole-step undulation example becomes φ⁻⁶.
- **Ascending:**

  | Melody | Degree | Key |
  | --- | --- | --- |
  | `CDEF\|GABc\|` | 0 | adherent |
  | `CDEF\|GABc\|B4\|` | 0 | adherent |
  | `DCEG\|AG2\|` | 0 | adherent |
  | `CDEC\|DEFD\|EGA2\|` | 0 | adherent |
  | `CDEF\|GABc\|A4\|` | 1 | ascending_end |
  | `EDEF\|EFED\|E4\|` | 1 | ascending_rise |
  | `CDCD\|C4\|` | 1 | ascending_rise |
  | `CDEG\|EDC2\|` | 2 | ascending_rise |
  | `cBAG\|FEDC\|` | 3 | ascending_rise |

- **Descending:** mirrors ascending. `EDEF|EFED|E4|` is degree 1 there too.
  The existing `CDED|EFG2|` example moves from φ⁻² to φ⁻⁶.
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
- **Descending scale against ascending:** Contoured marks `eq` φ⁻⁶. Don't pin
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
- The prototype's corpus counts are estimates made before the net-rise
  condition was added. Recheck them during implementation.

## Review

Reviewed 2026-10-19 at commit `c8dab07b`, with a clean working tree.

### Acceptance criteria

- ✅ **Shapes by degree.** Arch, valley, and wave mark at φ⁻²ᵈ
  (`contoured.rb:77-86, 128-137`). Every row of the arch table and the wave
  rule was reproduced.
- ✅ **Valley and one-degree grades.** A valley against an arch marks φ⁻⁴ and
  grades 0.4721 (`contour_melody_spec.rb:216-232`). A one-degree miss marks φ⁻²
  and grades 0.618.
- ✅ **Directions by three conditions.** All the named melodies grade as stated,
  and a descending scale against ascending marks φ⁻⁶ (`contoured.rb:90-101`).
- ✅ **One mark per miss.** A single `Mark.for_all` (`contoured.rb:63`), asserted
  for every miss in the spec helper.
- ✅ **Static unchanged.** The strict test stays in `directional_endpoints?`.
  C4 D4 E4 D4 and E4 D4 E4 F4 E4 F4 E4 D4 E4 stay static, and no
  `static_contour_melody` corpus row moved.
- ✅ **Closed key set.** 16 keys (13 at review, plus `too_few_legs` and the two
  retrace keys), each rendering from `%{contour}` alone. A 2000-melody random
  sweep at review showed the declared and producible keys match exactly.
- ✅ **Legs rename.** No `trend_directions` remains.
- ✅ **Class comment.** States the shape, direction, and level split
  (`contoured.rb:7-9`).
- ⚠️ **Corpus regenerated and reviewed.** 387 rows changed (arch 70, valley 89,
  wave 8, ascending 104, descending 116), all in the five non-static contour
  guides. Of the 79 arch rows at 0.618, 20 stay, 47 drop to 0.472, 5 to 0.416,
  and 7 drop lower, none below the 0.382 floor. Nine rows rose, eight ascending
  and one descending, each from the endpoint tolerance. Confirming those nine
  are intended needs a human. The plan's estimate of about 269 changed rows was
  made before the net-rise condition was added.
- ✅ **English strings regenerated.** The snapshot only adds lines.
- ✅ **Sawtooth re-pinned.** It grades 0.281.
- ✅ **`CDED|EFG2|` against descending.** It moves to φ⁻⁶.

### Code review findings

1. **The `missing_legs` message misleads for a wave (important).** "Rise and
   fall by at least a minor third" is told to an arch submitted to
   `wave_contour_melody`, which already rises and falls a fifth. What it lacks
   is one more leg. Suggested wording: "rise and fall more times, each by at
   least a minor third." Then re-snapshot the English strings.
   **Resolved:** the wave now has its own key, `too_few_legs`: "rise or fall
   by more than a step at least three times." Arch and valley keep
   `missing_legs`, because "three times" would be wrong for them.
2. **Ambiguous "one" in a comment (minor).** In `contoured.rb:89`, "too small
   to make one" reads as a leg. Say "a direction". **Resolved.**
3. **Dangling phrase in a spec comment (minor).** In
   `contour_melody_spec.rb:254`, "Three legs too many, its broken
   secondaries…" does not attach grammatically. **Resolved:** it now
   says the sawtooth has three legs too many for an arch.
4. **Zero-leg degree not pinned (test gap).** The single-note and two-note
   examples for arch, valley, and wave only assert `not_to be_adherent`. Pin
   φ⁻⁴ and φ⁻⁶. **Resolved:** fitness and key are pinned for both.
5. **Single notes fail directions (not in the story).** A single note now marks
   φ⁻² against ascending and descending, where it used to be adherent. This
   follows from the net-rise rule, and it is pinned. **Accepted** as
   intended.

No correctness bugs were found. After the fixes, `spec/head_music/style` passes
(2033 examples) and rubocop is clean.

### Follow-up: the retrace condition

After the review, two rising rows read as waves rather than ascents.
`fux_second_species_examples-0-v1` and
`third_species_triple_meter_examples-0-v1` each fall back seven semitones within
a net rise of five. A fourth direction condition, the retrace, now costs a
degree when the melody turns back from its running extreme as far as its net
change. It is measured only when the net change is at least a leg. It adds the
`ascending_retrace` and `descending_retrace` keys, which outrank the endpoint
keys.

- **Corpus:** 12 more rows changed, 11 ascending and 1 descending, and none
  rose. The two wave-like rows fell back to 0.601 and 0.567. The other ten were
  already misses and lost one more degree: each plunges below its start or ends
  by falling back.
- **Borderline rows:** both still match.
  `fux_cantus_firmus_examples_with_errors-13-v0` turns back 6 within a net fall
  of 7, and `fux_fifth_species_examples-3-v1` 10 within a net rise of 12.
- **Rising rows:** seven of the nine rows that rose at review stand.
- **Spec change:** the descending `start_and_end` example became
  `GAcB|AGFE|DCB,A,|C2|`, because the old one, `GAcB|AGFE|DCE2|`, also retraces.
- **RubyCritic:** the review missed that `rake validate` was failing. The
  degree grading had pushed `contoured.rb` from a C (about 139 flog) to a D
  (about 258). `Contoured::ShapeReading` and `Contoured::DirectionReading` now
  hold the two readings, about 120 and 70 flog. They were extracted in their own
  commit with grades unchanged, before the retrace was added.

### Follow-up: arch and valley as climax halves

Legs counted a third the same as an octave, so a small dip turned an arch into
a wave. Only 11 of 37 cantus firmi read as arches. Arch and valley are now
split at the turn, each half graded as a direction whose retrace may reach only
half its net change. `Contoured::TurnReading` reads them, and
`Contoured::WaveReading` (formerly `ShapeReading`) keeps the leg walk for waves.
A wave that reads as a single arch or valley now misses by one degree, which
keeps the three shapes mutually exclusive.

- **Retrace share:** half was chosen over the full net change, under which
  C E G E C D E F D C read as an arch, and over half for directions too, which
  would have failed the E3 A3 D3 … E4 line.
- **Corpus:** 214 rows changed, all arch, valley, or wave.
  - 29 melodies now pass arch and fail wave: the Fux and Clendinning cantus
    firmi and the cantus voices of the species examples.
  - `fux_fifth_species_examples-5-v1` moved from wave to valley.
  - 84 valley rows fell, mostly arches, which now miss a valley by three
    degrees rather than two.
- **Grades:**
  - A valley against an arch marks φ⁻⁶ and grades about 0.416.
  - The sawtooth reads as an arch missing its fall and grades 0.483.
- **New keys:** `unsteady_rise`, `unsteady_fall`, and `single_turn`.
  `extra_legs` now means a dip between repeated climaxes.

### Follow-up: naming each half's flaw

A corpus check found the `missing_legs` message misleading. It told 36 arch and
valley rows to "rise and fall by at least a minor third", though most were
fifth-species lines that rise and fall an octave or more. The key fired whenever
both halves failed, whatever their flaws. A half that fails is now "missing" its
leg when its net change is under a minor third, and "unsteady" otherwise, and
two failing halves are named by both flaws.

- **New keys:** `unsteady_legs`, `missing_rise_and_unsteady_fall`, and
  `unsteady_rise_and_missing_fall`, making 22 miss keys in all. A 3000-melody
  random sweep showed the declared and producible arch and valley keys match
  exactly.
- **Single-half rows:** a rise or fall of under a minor third is now "missing",
  not "unsteady". D4 F4 E4 against an arch, for example, is told to add a fall
  rather than to fall steadily.
- **Corpus:** 41 arch and valley rows changed key, and no grade moved.
