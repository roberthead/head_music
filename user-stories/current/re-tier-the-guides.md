<!--
metadata:
  created_at:   2026-08-16T00:00:00-07:00
  activated_at: 2026-08-16T20:45:18-07:00
  planned_at:
  finished_at:
  updated_at:   2026-08-16T20:45:18-07:00
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

[to be filled in by /stories plan]
