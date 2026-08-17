<!--
metadata:
  created_at:   2026-08-16T00:00:00-07:00
  activated_at: 2026-08-16T20:45:18-07:00
  planned_at:   2026-08-16T21:22:40-07:00
  finished_at:
  updated_at:   2026-08-16T21:22:40-07:00
-->

# Re-tier the Guides

AS a student submitting an exercise

I WANT a guide to tell me whether it can assess my work before it tells me how good my work is

SO THAT an empty voice does not score 1.0, a four-note attempt is not graded as a failed cantus firmus, and a soloed voice does not crash the harmony guides

Story 4 of the [Style Assessment Model](../epics/style-assessment-model.md).
Depends on story 2, which gives every guide three tiers to declare into.
Independent of story 3.

**This story deliberately changes grades.** Stories 1 through 3 are shape
changes verified by bit-identical fitness. This one is the editorial pass those
stories were kept clean to enable, and it gets a before/after table instead.

## Background

Story 2 preserved today's tiers exactly: gates are the entries whose guideline
subclasses `MinimumThreshold`, because those are the only guidelines with
`default_gate?` returning true, and there are no explicit overrides anywhere in
`lib/`. That was the right migration and it inherits three defects.

### Thirteen of the seventeen guides have no gate at all

Only `FuxCantusFirmus`, `SalzerSchachterCantusFirmus`, `DiatonicMelody`, and the
six `ContourMelody` configurations declare a `MinimumNotes` or
`MinimumMelodicIntervals`. Every species melody and harmony guide has nothing.

Measured against the current implementation:

| Guide | empty | 1 note | 2 notes | 4 notes |
| --- | --- | --- | --- | --- |
| `FirstSpeciesMelody` | **1.000** | **1.000** | 0.949 | 0.975 |
| `SecondSpeciesMelody` | **1.000** | 0.978 | 0.933 | 0.955 |
| `FifthSpeciesMelody` | **1.000** | **1.000** | 0.910 | 0.910 |
| `DiatonicMelody` | 0.000 | 0.200 | 0.385 | 0.800 |
| `FuxCantusFirmus` | 0.000 | 0.125 | 0.231 | 0.500 |
| `ArchContourMelody` | 0.000 | 0.000 | 0.121 | 0.800 |

An empty voice is a perfect first-species melody. Writing one note scores 1.000
and writing four scores 0.975 — **a one-note melody outranks a four-note one**,
because every guideline that finds nothing to complain about returns a fitness of
1.0, and a voice with nothing in it gives none of them anything to find.

### The harmony guides raise on a voice with no companion

```
FirstSpeciesHarmony  → NoMethodError: undefined method `notes' for nil
FourthSpeciesHarmony → NoMethodError: undefined method `notes' for nil
```

`Guideline#downbeat_harmonic_intervals` reaches `cantus_firmus.notes`, and
`cantus_firmus` is nil when the composition has no other voice. "Is there a
second voice to be in harmony with" is the definitional precondition of a harmony
guide, and it is not asked.

### One prescription, split across two tiers

`FuxCantusFirmus` declares that a cantus firmus runs eight to fourteen notes:

```ruby
Guidelines::MinimumNotes.with(8),   # a gate — scales the entire grade
Guidelines::MaximumNotes.with(14),  # one rubric item among twelve
```

Two halves of one rule with wildly different force, because `MinimumNotes`
inherits `MinimumThreshold` and `MaximumNotes` inherits the base class. That is
why a four-note attempt grades 0.500: its climax, its leaps, and its ending are
all halved for a fault that has nothing to do with any of them.

## Scope

An editorial pass over the seventeen guides, and one behavioral decision that
makes the pass mean something.

### Gates short-circuit

Today a gate multiplies. If gates answer *is this assessable*, a failed gate
should stop the assessment rather than scale it:

```ruby
class HeadMusic::Style::GuideAssessment
  def assessable? = gate_assessments.all?(&:adherent?)

  def fitness
    return gate_fitness unless assessable?
    gate_fitness * rubric_fitness
  end

  # Not computed when the gates do not pass.
  def rubric_assessments ...
end
```

This is what fixes the crash: a harmony guide whose "has a companion voice" gate
fails never reaches `downbeat_harmonic_intervals`. It also removes the incoherence
of reporting that a two-note voice has an excellent melodic contour.

Consumers gain `assessable?` and must handle `rubric_assessments` being empty.
`fitness` still returns a number in `0..1`, so the grading contract is unchanged
for anything that passes its gates.

### Every guide declares its preconditions

At minimum:

- **Melody guides** — `MinimumNotes.with(3)`. Three notes is where a contour
  becomes possible at all, and it is distinct from any stylistic minimum.
- **Harmony guides** — a companion voice exists, and it has notes. This needs a
  new guideline; `HasCantusFirmus` or `AccompaniesAnotherVoice`.
- **Moving-species guides** — arguably a minimum of melodic intervals, the way
  `ContourMelody` already gates on "did they attempt to move."

### Thresholds split in two where they carry two meanings

`FuxCantusFirmus` becomes:

```ruby
gate_items    Guidelines::MinimumNotes.with(3)      # is this a melody
primary_items Guidelines::MinimumNotes.with(8),     # is it a cantus firmus
              Guidelines::MaximumNotes.with(14)
```

Same guideline twice, different config, different question — legal and intended
under story 2, which rejects only a duplicate `(guideline, config)` pair.
`MinimumNotes`'s fitness is `actual_count / minimum`, a proportion that reads
correctly as either a scaling factor or a rubric score.

### Every entry gets a tier decision

For each of the ~304 entries: precondition, lesson, or background. The
`secondary_items` tier is currently used by exactly one guide
(`ContourMelody`'s demoted peers) and is almost certainly under-used — the
species guides inherit `MELODIC_CORE` wholesale while teaching something specific
about rhythm, and what they inherit is background by definition.

This is judgment, not derivation. It should be done per guide, with the
before/after fitness table regenerated after each, and it is the reason this
story is separate.

## Acceptance Criteria

- Every registered guide declares at least one gate.
- No guide raises for a voice with no notes, one note, or no companion voice; each
  returns a fitness and reports `assessable? == false`.
- An empty voice scores 0.0 against every guide.
- Among *unassessable* voices of a given guide, fitness is non-decreasing in
  notes — an *n*-note prefix never outscores an *n+1*-note prefix. This is not
  claimed across the gate boundary: once a voice is assessable, fitness is a
  quality judgment and a longer melody may legitimately be worse.
- No unassessable voice scores 1.0.
- `FuxCantusFirmus` grades a four-note voice as unassessable rather than 0.500.
- A guide whose gates pass grades exactly as it did before this story, so the
  change is confined to the degenerate range.
- The before/after fitness table is committed with the story, covering every
  guide against a fixed corpus of degenerate and valid voices.
- CHANGELOG documents the grading change for each affected guide.

## Scenarios

### Scenario: An empty voice is unassessable rather than perfect

Given `FirstSpeciesMelody` and a voice with no notes

When I assess

Then `assessable?` is false, `fitness` is 0.0, and no rubric assessment was computed

### Scenario: A harmony guide with no companion voice does not crash

Given `FirstSpeciesHarmony` and a lone voice

When I assess

Then `assessable?` is false and nothing raises

### Scenario: A short attempt is short, not bad

Given `FuxCantusFirmus` and a musically flawless four-note melody

When I assess

Then it is reported as too short for the form, and its climax and leaps are not penalized for its length

### Scenario: The gate and the prescription ask different questions

Given `FuxCantusFirmus` declaring `MinimumNotes.with(3)` as a gate and `MinimumNotes.with(8)` as a primary

When I assess a six-note melody

Then the gate passes, and the primary contributes a fitness of 0.75 to the rubric

### Scenario: A valid exercise grades as it always did

Given each registered guide and its known-good example voices

When I assess

Then the fitness matches the value recorded before this story

### Scenario: Unassessable fitness is monotonic

Given any melody guide and voices of one and two notes, both below its gate

When I assess each

Then both report `assessable? == false`, neither scores 1.0, and the two-note voice scores no lower than the one-note voice

## Design notes

**Why an empty voice currently scores 1.0.** `Guideline#fitness` returns 1.0 when
there are no marks, and a guideline with nothing to examine produces no marks.
That default is right for a guideline — "I found no fault" — and wrong as a
grade, because "no fault found" and "nothing to find fault in" are different
claims. The gate tier is where that difference belongs; no amount of fixing
individual guidelines would express it, because each one is answering its own
question correctly.

**Why short-circuiting rather than continuing to multiply.** Multiplying gives a
number, and the number is a blend of two incompatible claims. A student told
their four-note fragment scores 0.500 will reasonably ask which half was wrong.
`assessable? == false` is answerable: none of it was wrong, there was not enough
of it to judge.

**Why this is not a bug fix.** Each defect above is individually small and could
be patched — a nil guard here, a `MinimumNotes` there. Doing so would rebuild the
gate concept guide by guide in an ad-hoc way. The tiers exist precisely to hold
this distinction once; this story is spending them.

## Resolved questions

- **How low is a melody gate?** Three notes. Two makes an interval; three is
  where a contour becomes possible, which is what the melodic guidelines are
  looking for. `ContourMelody`'s existing 1–2 melodic-interval gate is the same
  range.
- **Does a partially-failing gate exist?** `MinimumNotes.with(3)` on a one-note
  voice yields 0.333, not 0. Any non-adherent gate stops the assessment, and the
  gate fitness becomes the reported grade — so a one-note voice scores 0.333 and
  reports `assessable? == false`. This keeps the degenerate range monotonic
  without inventing a second kind of gate.

## Out of scope

- **Promoting the species guides' inherited core to `secondary_items`.** Every
  species guide teaches something specific about rhythm and inherits
  `MELODIC_CORE` wholesale, so what it inherits is background by definition.
  Demoting it would make the species guides read correctly as instructions and
  would change their grades again. A separate editorial pass, deliberately not
  bundled with fixing the degenerate range.

## Implementation Plan

Six commits. A failed gate **stops** the assessment rather than scaling it, by
short-circuiting in `assess_items` — which is where the rubric is built, and
therefore where the harmony crash happens. Then the missing preconditions get
declared.

### `GuideAssessment#fitness` does not change

The most surprising claim in the plan, and it holds. Once `assess_items`
short-circuits: when gates pass, every gate fitness is exactly `1`, so
`gate_factor` is bit-exactly `1.0`; when a gate fails, the rubric list is empty,
`rubric_fitness` returns `1.0` at its own guard, and `fitness` collapses to the
gate product. Verified by diffing the ladder with and against a rewritten
`fitness` — identical.

### ⚠️ Blocking decision: the story contradicts itself on `FuxCantusFirmus`

**Scope** (line 129) says `gate MinimumNotes(3)` + `primary MinimumNotes(8)`.
The **acceptance criterion** (line 162) says a four-note voice must be
*unassessable* rather than 0.500. Both cannot hold: with a 3-note gate, four
notes passes and is assessable — measured **0.897, assessable**.

Keeping `MinimumNotes.with(8)` as the gate gives exactly **0.500, unassessable**,
the stated target, and short-circuiting alone already satisfies the scenario "a
short attempt is short, not bad" — the climax and leaps are not penalised
*because they are never computed*. The asymmetry with `MaximumNotes(14)` then
reads as justified: four notes has nothing to judge; fifteen has a climax, leaps
and an ending and is simply too long.

Measured cost of the split against the real fixture corpus: 14 of 21 exercises
shift and 9 existing examples break, the largest being "Fux C with too few
notes" (7 notes) moving 0.858 → 0.974. All seven valid Fux exemplars stay 1.000.

**Recommendation: keep the 8-note gate, drop the split.** The middle option is
`gate 5 / primary 8` — one example breaks, four notes unassessable at 0.800.
The same reasoning applies to `DiatonicMelody`: keep its 5-note gate, because
moving it propagates through `contour_melody.rb:52,54` to all six contour
entries and costs 8 structural examples.

### Recommended tiering

| Guides | Gate |
| --- | --- |
| `FuxCantusFirmus`, `SalzerSchachterCantusFirmus` | `MinimumNotes.with(8)` — unchanged |
| `DiatonicMelody` | `MinimumNotes.with(5)` — unchanged |
| 6 contour configurations | unchanged (inherited + motion gate) |
| 7 species **melody** guides | `MinimumNotes.with(3)` — **new** |
| 7 species **harmony** guides | `SetAgainstAnotherVoice`, `MinimumNotes.with(3)` — **new** |

Nothing is demoted; no rubric changes. Under this design the **entire existing
suite passes unchanged (6462/0)** — a stronger claim than a tolerance table,
because it says the editorial pass touched only the degenerate range.

### Steps

**1. Extract the assess loop and short-circuit it** *(green)*

```ruby
module HeadMusic::Style::Guides::Assessment
  RUBRIC_TIERS = %i[primary secondary].freeze

  def self.assess_items(voice, items_by_tier)
    gates = items_by_tier[:gate].map { |item| item.assess(voice, :gate) }
    return gates unless gates.all?(&:adherent?)

    gates + RUBRIC_TIERS.flat_map do |tier|
      items_by_tier[tier].map { |item| item.assess(voice, tier) }
    end
  end
end
```

All gates are assessed even when an earlier one fails, so a consumer sees *which*
preconditions are unmet — `contour_melody_spec.rb:248-257` already depends on
this. `base.rb:45-49` and `configured.rb:19-23`, today duplicates, both delegate
to it. Add `GuideAssessment#assessable?`; leave `fitness` alone. Do **not** add
`gate_assessments`/`rubric_assessments` — `guide_item_assessments.select(&:gate?)`
already works, and a downstream app persists one collection.

`assess_items` keeps **arity 1**, so `PermissiveGuide`/`GradedStubGuide` and both
`respond_to?(:assess_items)` duck-checks are unaffected.

**2. Add `SetAgainstAnotherVoice`** *(green, additive)*

Named for what it checks: `Guideline#cantus_firmus` is
`other_voices.detect(&:cantus_firmus?) || other_voices.first`, so it returns
*any* companion — `HasCantusFirmus` would be a lie.

**The `placements.empty?` branch is load-bearing.** `Mark.for_all([])` returns
`[]`, and no marks means `fitness == 1.0` — that is *the* mechanism behind an
empty voice scoring 1.0, so calling `for_all` unconditionally would produce a
gate that passes on exactly the input it exists to catch. Move
`no_placements_mark` up from `minimum_threshold.rb` to `Guideline`; "the voice is
empty, so mark bar 1" is not threshold-specific.

**3. Gate the seven melody guides** *(green)*

`SpeciesMelody::MELODIC_GATES = [MinimumNotes.with(3)].freeze`, **splatted into
each subclass**.

⚠️ **It must be a splatted constant, not a `gate_items` call on the base class.**
`declarations` is a per-class singleton ivar, so `gate_items` in `SpeciesMelody`
leaves every subclass with `[]` — **and does not raise**, because `normalize`
only raises when all three lists are empty and the subclass has primaries. The
suite stays green with every melody guide still scoring 1.0 on an empty voice.
Verified directly. This is the single most likely way to implement this story
wrong.

**4. Gate the seven harmony guides** *(⚠️ riskiest)*

`SpeciesHarmony::HARMONIC_GATES = [SetAgainstAnotherVoice, MinimumNotes.with(3)].freeze`.
Turns seven `NoMethodError`s into grades.

The companion gate **alone is not enough**: measured, a 3-note counterpoint
against an *empty* companion scores 1.000 on all seven, and a 0-note counterpoint
against a real 8-note cantus firmus scores 0.891–1.000. `MinimumNotes.with(3)`
closes both. The minimum does **not** vary per species — the gate asks "is there
anything here to judge," not "is this the right density"; `FourPerBar` and the
dissonance guidelines answer density as rubric items.

Require ordering bites: `Guide::ALL.each(&:guide_items)` resolves at load, so
`set_against_another_voice` must be required before `guides/species_harmony`.

**5. Property specs and the committed table**

Property block over `Guide.all` in `guide_spec.rb`: every entry declares ≥1 gate;
an empty voice grades 0.0 and reports `assessable? == false`; no guide raises on
a solo voice of 0/1/8 notes; no unassessable voice grades 1.0; fitness is
non-decreasing over the 0..8 unassessable prefix. Cheap, total, and it **survives
the session** — which story 2's oracle did not.

**6. Docs and CHANGELOG.**

⚠️ `[Unreleased]` currently asserts *"Grading is unchanged for every registered
guide… byte-identical to 19.0.0."* Both stories land in the same 20.0.0, so that
line must be **amended**, not appended to.

### The before/after artifact

**A committed script under `bin/`, not a rake task.** The "before" column must be
produced by code that runs at the **merge-base**, where `assessable?` does not
exist and the harmony guides raise — a rake task defined on this branch cannot
run there. Story 2's reviewer had to build a merge-base worktree to re-derive its
oracle; this makes that reproducible from the start. Precedent:
`bin/check_instrument_consistency.rb`.

`bin/guide_grade_corpus.rb` runs unmodified on both sides, so it asks only what
both answer: `assessment.respond_to?(:assessable?) ? assessment.assessable? : nil`.

**Corpus:** ascending ladder (solo, 0–8 notes); repeated-note ladder (exercises
`MinimumMelodicIntervals`); the ladder against the harmony guides; counterpoint
of 0/1/2/4/8 against an empty companion; the same against a real 8-note cantus
firmus; the 23 valid exercises; the 34 broken ones.

**Columns:** `corpus · voice · notes · guide · fitness_before · fitness_after ·
delta · assessable_after · failed_gates · adherent_before · adherent_after ·
message_count`. `failed_gates` is what makes the table readable — it answers "why
did this drop," which is what a student sees.

**Location:** `re-tier-the-guides.grades.md` beside the story, moving to `done/`
with it. The story body gets only the 23×5 degenerate summary.

### Contract change

When a gate fails, `guide_item_assessments` holds the gate assessments **only**;
`assessable?` is false; `fitness` is Π(gate fitnesses); `adherent?` is false;
`messages` holds the failing gates' messages. The consumer break is semantic, not
signature: `assess_items` now returns a variable-length list, so a downstream app
upserting rows keyed by `(guide_item, tier)` must not read a missing row as "rule
deleted." That is a CHANGELOG line.

**Monotonicity is structural, not coincidental.** `MinimumNotes` fitness is
exactly `notes.length / minimum`; `MinimumMelodicIntervals` is
`moving_intervals.length / minimum`, and extending a prefix never removes a
moving interval; `SetAgainstAnotherVoice` is length-independent. A product of
non-decreasing non-negative functions is non-decreasing.

### Commit granularity

One per step. Step 1 alone is the whole mechanism touching no guide file — a
reviewer reads ~40 lines and can verify `fitness` did not change. Step 2 alone is
additive, and its spec is the only evidence the guideline is correct before any
guide depends on it. Steps 3 and 4 stay separate so `git bisect` on a harmony
regression does not land on a melody commit. Step 5 alone, because the story's
evidence must be reviewable *as* evidence — a table in the same commit as the
code that produced it invites reading it as a description of the diff rather than
a measurement of it.

### Open questions

1. **`FuxCantusFirmus`: keep the 8-note gate, or split it?** Blocking; see above.
2. **`DiatonicMelody`: keep the 5-note gate?** Recommending yes, on blast radius.
3. **The `MELODIC_CORE` → `secondary_items` demotion this story defers is more
   coupled than the story admits.** A valid *first*-species line scores 0.883
   against `ThirdSpeciesMelody` today — diffusely "pretty good" for something
   that is not third species — and 0.561 with the cores demoted. The diffuse
   grade is *caused* by the flat rubric. Deferral still recommended, but the
   coupling is real, and `MOVING_MELODIC_CORE` is a second inherited core the
   out-of-scope note never names.
4. **Rhythmic species as gates — resolved "no."** The references classify
   rhythmic structure as a hard rule, not a definition; `MELODIC_CORE` is fully
   assessable on a whole-note submission; and `NoteCountPerBar` returns `[]`
   without a cantus firmus, so a rhythmic gate would be adherent-by-vacancy for
   exactly the solo-voice case this story fixes.
5. **A coverage gate (`CoversCantusFirmus`) is proposed but not recommended.**
   `MinimumNotes(3)` still lets a 3-bar counterpoint against an 11-bar cantus
   firmus through at 1.000. Is that unassessable, or an incomplete submission
   graded on what is there?
6. **`MinimumMelodicIntervals` gates on moving-species guides — deferring.** An
   all-repeated 8-note line already grades 0.638–0.700 there, not 1.0.

### Pre-existing defects found, all out of scope

`CombinedFirstSecondThirdSpeciesMelody` hand-rolls a near-copy of
`MOVING_MELODIC_CORE` and silently omits `NoteFillsFinalBar` and
`StepOutOfUnison`; the harmony twin omits `DIMINUTION_HARMONIC_CORE` despite
covering second and third species; `FourthSpeciesMelody` cannot distinguish
fourth species from first, because `OneToOneWithTies` is *adherent* on a
first-species line; `StartOnPerfectConsonance` and `StepOutOfUnison` are
**harmonic** rules living in the melody guides that score a free 1.0 for a solo
voice — the epic's own "no fault found vs. nothing to find fault in" confusion
occurring inside the melody guides; and `minimum_melodic_intervals.rb:15` renders
"Write at least one melodic interval**s**".

### Corrections to the story text

- All **seven** harmony guides raise, at **every** voice length. The story names
  two and implies short voices only.
- `FuxCantusFirmus` has **15** primaries, not the 12–13 implied.
- `base_spec.rb:27-35`'s `concrete_guide_class?` **rescues `ArgumentError` from
  `guide_items`**, so a new guideline that raises at declaration time would be
  swallowed and the guide silently dropped from the registry-drift check. Verify
  step 4 with `Guide.all.map { |g| g.items_by_tier[:gate].length }` directly, not
  only via the suite.
- The plan reports the four-note Fux figure as 0.462; re-measured here as
  **0.500** for both `:counterpoint` and `"Cantus Firmus"` roles, matching the
  story. The discrepancy is likely a different voice construction; the argument
  is unaffected.
