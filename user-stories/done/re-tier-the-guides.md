<!--
metadata:
  created_at:   2026-08-16T00:00:00-07:00
  activated_at: 2026-08-16T20:45:18-07:00
  planned_at:   2026-08-16T21:22:40-07:00
  finished_at:  2026-08-17T11:10:22-07:00
  updated_at:   2026-08-17T11:10:22-07:00
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

### The inherited cores become background

Folded in rather than deferred, because the coupling is real: a valid *first*-
species line scores 0.883 against `ThirdSpeciesMelody` today — diffusely "pretty
good" for something that is not third species — and 0.561 with the cores
demoted. The diffuse grade is *caused* by the flat rubric, so fixing the
degenerate range without this leaves the guides still unable to say what they
teach.

`MELODIC_CORE` and `MOVING_MELODIC_CORE` become `secondary_items` in the species
melody guides. What stays primary is what the guide is *for* — the rhythmic and
species-specific rules it adds.

**The harmony guides are not demoted here.** Their cores are a separate story:
[Extract the Harmonic Cores](../backlog/extract-the-harmonic-cores.md). Harmony
guides therefore keep flat rubrics for now, and this story's before/after table
will show melody grades moving while harmony grades move only in the degenerate
range.

Note that `MOVING_MELODIC_CORE` is a second inherited core the original
out-of-scope note never named, and that
`CombinedFirstSecondThirdSpeciesMelody` hand-rolls a near-copy of it rather than
splatting it, so the demotion has to reach that guide by hand.

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
- `FuxCantusFirmus` asks its two questions separately: `MinimumNotes.with(3)` as
  a gate — is this a melody at all — and `MinimumNotes.with(8)` as a primary,
  which is Fux's prescription that a cantus firmus run eight to fourteen notes.
  A four-note voice is therefore *assessable*, is told it is short, and is not
  marked down on a climax and leaps it was never measured against.

  Deliberately no target number. Making the scoring adjustable is half of what
  this epic is for, so a criterion that freezes one fitness works against it.
  What must hold is the shape: assessable, and the complaint is about length.
  The numbers live in the grade table, where they are a measurement rather than
  a promise.
- The species guides grade what they teach above what they inherit. A valid
  *first*-species line scores markedly lower against `ThirdSpeciesMelody` than
  it does today, because the inherited melodic core is background there rather
  than half the rubric.
- Every grade that moves is accounted for in the before/after table, with the
  tier change that caused it. This story does **not** claim the existing suite
  is unchanged — it deliberately changes grades outside the degenerate range,
  and the specs that assert the old numbers are updated with their new values
  recorded.
- The before/after fitness table is committed with the story, covering every
  guide against a fixed corpus of degenerate and valid voices.
- CHANGELOG documents the grading change for each affected guide.

## Learnings

### What the process caught

**Planning found a contradiction inside the story itself.** Scope said split the
Fux threshold; the acceptance criterion said a four-note voice must stay
unassessable. Both cannot hold. The brief to the planner carried the split
forward as "resolved," so the error was propagated rather than caught — the
planner found it by measuring, not by reading.

**Review caught a real defect in the evidence.** The grade table attributed 205
rows to the demotion that had nothing to do with it. The classification rule was
a guess — "fitness moved and the voice is still assessable" — which cannot
distinguish a demotion from a changed threshold. The reviewer also noted the
rule was not committed, so the table could not be regenerated. Attribution is
now by guide, read off the declarations, and the join is a script.

**Membership preservation was worth checking explicitly.** Rewriting seven guides
to declare through a partitioning helper could have silently dropped a
guideline, and nothing would have caught it: the suite does not grade a voice
against a non-matching guide, and a missing rule still produces a plausible
number. A merge-base comparison proved zero lost.

### What went wrong

**A discrepancy got explained instead of investigated.** Asked why the story's
0.897 did not match a measured 0.969, the answer given was that the plan
measured before the demotion landed. It did not — the figure is identical at the
pre-demotion commit, and `FuxCantusFirmus` never demotes at all. A plausible
story beat checking, and it was committed. One measurement refuted it.

**A number was over-pinned in an acceptance criterion.** Freezing a fitness works
against an epic whose purpose is making the scoring adjustable. The criterion
now asserts the shape — assessable, and the complaint is about length — and the
numbers live in the table, where they are measurements rather than promises.

**Two stated counts were wrong**: "nine examples break" was seven, and the first
report of the mislabelled rows said 47 when it was 205.

### Worth carrying forward

- **A green suite meant nothing here.** The demotion moved hundreds of grades and
  broke no tests, because nothing grades a voice against a non-matching guide.
  Asking *why* it stayed green is what justified the property specs.
- **Property specs outlive captured artifacts.** Story 2's oracle proved its
  claim and expired with the session. The six assessability properties check the
  whole registry and survive; each was confirmed to fail for the right reason by
  reverting one change at a time.
- **The base-class declaration trap nearly ate this story.** `gate_items` on
  `SpeciesMelody` would leave every subclass with no gates and raise nothing,
  because `normalize` only objects when all three tiers are empty. The suite
  would have stayed green with every guide still grading an empty voice 1.000.

## Review

Reviewed 2026-08-17 at `524f56d`, against
`git diff $(git merge-base main HEAD)...HEAD -- lib spec bin README.md CHANGELOG.md`
— 36 files. Both findings are fixed in `524f56d`; the verdicts describe the
reviewed state.

### Acceptance criteria

Every criterion verified by running it. The reviewer built a merge-base worktree
rather than trusting the committed captures.

| Criterion | Verdict | Evidence |
| --- | --- | --- |
| Every guide declares a gate | ✅ | all 23 |
| Nothing raises for 0/1/no-companion voices | ✅ | reverting one gate reproduces the original `NoMethodError` |
| Empty voice grades 0.0 | ✅ | all 23 |
| Monotonic among unassessable voices | ✅ | all 23 over the 0–8 ladder |
| No unassessable voice scores 1.0 | ✅ | all 23 |
| Fux splits its threshold | ✅ | reverting the split breaks the new examples |
| Species guides weigh teaching above inheritance | ✅ | first-species line vs `ThirdSpeciesMelody`: 0.883 → 0.561 |
| Every moved grade attributed | ✅ *(after the fix below)* | 3,266 rows reproduce exactly |
| Table committed | ✅ | capture script runs unmodified at the merge-base |
| CHANGELOG documents the change | ✅ | categorical, covering all 17 affected guides |

### The highest-risk check: membership

**No defect.** Dumped every guide's guidelines at the merge-base and at the tip.
Across all ten guides that changed declaration form, the only difference is the
addition of `MinimumNotes(3)` — **zero guidelines lost, none unexpectedly
gained** — and `primary(after) + secondary(after) == primary(before)` holds for
each of the seven species guides. The partition works by membership rather than
declaration form, confirmed against `FirstSpeciesMelody`, which hand-names seven
of `MOVING_MELODIC_CORE`'s nine members instead of splatting the constant and
still has all seven demoted.

### The property specs are load-bearing

Verified by reverting changes in a scratch worktree, one at a time: removing a
melody guide's gate fails three of the six; removing a harmony guide's fails all
six and reproduces the original crash; reverting the short-circuit fails five,
leaving only the gate-presence check green, correctly. None is decorative.

### Findings, both fixed

**1. The table attributed 205 rows to the wrong mechanism.** The classification
rule was a guess — "the fitness moved and the voice is still assessable" — which
cannot distinguish a demotion from a changed threshold. `FuxCantusFirmus`,
`SalzerSchachterCantusFirmus`, `DiatonicMelody` and the six contour guides never
demote: their `secondary_items` is empty before and after, and their rows moved
because the note minimum split. Attribution is now by guide, read off the
declarations, and the join is a committed script (`bin/guide_grade_table.rb`) so
the table regenerates rather than being trusted. The reviewer had flagged that
the classification was not reproducible; now it is.

**2. Three property specs did not name the failing guide.** They looped over all
23 reporting only the mismatched value. Since these are the story's durable
evidence, a failure that does not say which guide broke undercuts the point.

### Corrections to the story's own numbers

- **The 0.897 figure does not reproduce.** The voice measures 0.96875 at the tip
  *and* at the commit before the demotion, and `FuxCantusFirmus` is never
  demoted. An earlier note here blamed the demotion; that was wrong, and is
  corrected above. Most likely a stale hand-estimate, like the plan's 0.462 for
  the same voice.
- **"Nine existing examples break" was seven.** All seven are consequences of the
  tier split — the reviewer recomputed `ContourMelody` item counts independently
  and got 14/14/14/13/14/14, matching the specs — not adjustments to greenwash a
  red suite.

### Out of scope: confirmed absent

No coverage gate; `MinimumMelodicIntervals` appears only where it already did.
The harmony cores are untouched and flat, with
[Extract the Harmonic Cores](../backlog/extract-the-harmonic-cores.md) as the
recorded follow-up.

## Results

A solo voice of nought to four notes, against every registered guide. An
asterisk marks a voice the guide reports it cannot assess. The full
3,266-row table, including the fixture exercises, is in
[re-tier-the-guides.grades.md](re-tier-the-guides.grades.md).

| guide | 0 notes | 1 note | 2 notes | 3 notes | 4 notes |
| --- | --- | --- | --- | --- | --- |
| `fux_cantus_firmus` | 0.000* | 0.125 → 0.333* | 0.230 → 0.667* | 0.365 → 0.937 | 0.454 → 0.882 |
| `salzer_schachter_cantus_firmus` | 0.000* | 0.125 → 0.333* | 0.235 → 0.667* | 0.366 → 0.941 | 0.464 → 0.903 |
| `diatonic_melody` | 0.000* | 0.200 → 0.333* | 0.391 → 0.667* | 0.600 → 0.964 | 0.769 → 0.947 |
| `first_species_melody` | 1.000 → 0.000* | 1.000 → 0.333* | 0.935 → 0.667* | 0.949 → 0.978 | 0.924 → 0.966 |
| `first_species_harmony` | raised → 0.000* | raised → 0.000* | raised → 0.000* | raised → 0.000* | raised → 0.000* |
| `second_species_melody` | 1.000 → 0.000* | 0.978 → 0.333* | 0.920 → 0.667* | 0.933 → 0.863 | 0.910 → 0.853 |
| `second_species_harmony` | raised → 0.000* | raised → 0.000* | raised → 0.000* | raised → 0.000* | raised → 0.000* |
| `third_species_melody` | 1.000 → 0.000* | 0.978 → 0.333* | 0.920 → 0.667* | 0.933 → 0.863 | 0.910 → 0.853 |
| `third_species_harmony` | raised → 0.000* | raised → 0.000* | raised → 0.000* | raised → 0.000* | raised → 0.000* |
| `third_species_triple_meter_melody` | 1.000 → 0.000* | 0.978 → 0.333* | 0.920 → 0.667* | 0.933 → 0.863 | 0.910 → 0.853 |
| `third_species_triple_meter_harmony` | raised → 0.000* | raised → 0.000* | raised → 0.000* | raised → 0.000* | raised → 0.000* |
| `fourth_species_melody` | 1.000 → 0.000* | 1.000 → 0.333* | 0.939 → 0.667* | 0.952 → 0.981 | 0.928 → 0.971 |
| `fourth_species_harmony` | raised → 0.000* | raised → 0.000* | raised → 0.000* | raised → 0.000* | raised → 0.000* |
| `combined_first_second_third_species_melody` | 1.000 → 0.000* | 1.000 → 0.333* | 0.930 → 0.667* | 0.945 → 0.978 | 0.918 → 0.966 |
| `combined_first_second_third_species_harmony` | raised → 0.000* | raised → 0.000* | raised → 0.000* | raised → 0.000* | raised → 0.000* |
| `fifth_species_melody` | 1.000 → 0.000* | 1.000 → 0.333* | 0.898 → 0.667* | 0.896 → 0.672 | 0.865 → 0.617 |
| `fifth_species_harmony` | raised → 0.000* | raised → 0.000* | raised → 0.000* | raised → 0.000* | raised → 0.000* |
| `arch_contour_melody` | 0.000* | 0.000* | 0.122 → 0.333* | 0.600 → 0.986 | 0.483 → 0.598 |
| `ascending_contour_melody` | 0.000* | 0.000* | 0.397 → 0.667* | 0.371 → 0.604 | 0.788 → 0.980 |
| `descending_contour_melody` | 0.000* | 0.000* | 0.244 → 0.667* | 0.371 → 0.604 | 0.483 → 0.598 |
| `static_contour_melody` | 0.000* | 0.200 → 0.333* | 0.244 → 0.667* | 0.600 → 0.986 | 0.483 → 0.598 |
| `valley_contour_melody` | 0.000* | 0.000* | 0.122 → 0.333* | 0.371 → 0.604 | 0.483 → 0.598 |
| `wave_contour_melody` | 0.000* | 0.000* | 0.122 → 0.333* | 0.371 → 0.604 | 0.483 → 0.598 |

Three kinds of movement, and each row of the full table names which one applies:

- **crash fixed** (126 rows) — the harmony guides raised for a voice with no
  companion, at every length. They grade it now.
- **gated** (959 rows) — a precondition stops the assessment rather than scaling
  it, so a voice that fails one is not also marked down on rules it was never
  measured against.
- **demoted** (859 rows) — the species guides weigh what they teach above what
  they inherit. A valid first-species line scored 0.883 against
  `ThirdSpeciesMelody` and now scores 0.561.

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

- **A coverage gate.** `MinimumNotes.with(3)` still lets a three-bar counterpoint
  against an eleven-bar cantus firmus through. Whether that is unassessable or
  an incomplete submission graded on what is there is a separate question.
- **`MinimumMelodicIntervals` as a gate on the moving-species guides.** An
  all-repeated eight-note line already grades 0.638–0.700 there, not 1.0, so
  nothing in this story needs it.

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

### ✅ Decided: split the Fux threshold, and fold in the demotion

Both decisions go against the recommendation below, deliberately. Recorded here
with what they cost, and the story's criteria above are reconciled to match.

**`FuxCantusFirmus` splits: `gate 3` + `primary 8`.** The two-questions design is
the story's actual thesis, and honouring it is worth the churn. Consequences,
measured: a four-note voice becomes assessable rather than unassessable at
0.500 (recorded here as 0.897; the figure does not reproduce — see below); seven spec expectations change; fourteen of twenty-one corpus exercises
shift, the largest being "Fux C with too few notes" (7 notes) moving 0.858 →
0.974. `SalzerSchachterCantusFirmus` follows suit. `DiatonicMelody`'s 5-note gate
splits the same way, which propagates through `contour_melody.rb:52,54` to all
six contour entries.

**The inherited cores are demoted in this story, not a later one.** See Scope.

**The "existing suite unchanged" property is therefore given up.** That was the
strongest evidence available for a story that changes grades, and it is now
unavailable — the before/after table and the property specs carry the whole
weight. Expect a large number of updated expected values, each of which needs
its new number justified by a tier change rather than accepted because the suite
went green.

### The recommendation this overrode

**Scope** (line 129) says `gate MinimumNotes(3)` + `primary MinimumNotes(8)`.
The **acceptance criterion** (line 162) says a four-note voice must be
*unassessable* rather than 0.500. Both cannot hold: with a 3-note gate, four
notes passes and is assessable — recorded here as **0.897**.

That figure does not reproduce. The voice measures 0.96875 at the tip, and also
at the commit *before* the demotion landed, and `FuxCantusFirmus` is never
demoted at all — it declares through `primary_items` directly, so its
`secondary_items` is empty before and after. An earlier note in this story
attributed the difference to the demotion; that explanation was wrong. 0.897 is
most likely a stale hand-estimate, like the 0.462 the plan reported for the same
voice and which also did not reproduce. The number the table carries is
measured.

Keeping `MinimumNotes.with(8)` as the gate gives exactly **0.500, unassessable**,
the stated target, and short-circuiting alone already satisfies the scenario "a
short attempt is short, not bad" — the climax and leaps are not penalised
*because they are never computed*. The asymmetry with `MaximumNotes(14)` then
reads as justified: four notes has nothing to judge; fifteen has a climax, leaps
and an ending and is simply too long.

Measured cost of the split against the real fixture corpus: 14 of 21 exercises
shift and 9 existing examples break, the largest being "Fux C with too few
notes" (7 notes) moving 0.858 → 0.974. All seven valid Fux exemplars stay 1.000.

The recommendation was to keep the 8-note gate and drop the split, on the
grounds that short-circuiting alone already delivers "a short attempt is short,
not bad" — the climax and leaps are not computed rather than computed and
halved — and that the asymmetry with `MaximumNotes(14)` then reads as justified
rather than defective. Overridden in favour of the two-questions design.

### Recommended tiering

| Guides | Gate |
| --- | --- |
| `FuxCantusFirmus`, `SalzerSchachterCantusFirmus` | `MinimumNotes.with(3)` gate; `.with(8)` stays primary |
| `DiatonicMelody` | `MinimumNotes.with(3)` gate; `.with(5)` becomes primary |
| 6 contour configurations | inherit DiatonicMelody's gate, plus the motion gate |
| 7 species **melody** guides | `MinimumNotes.with(3)` — **new** |
| 7 species **harmony** guides | `SetAgainstAnotherVoice`, `MinimumNotes.with(3)` — **new** |

Plus the demotion: the inherited cores become `secondary_items` across the
species guides. Grades move well outside the degenerate range, so the existing
suite does **not** stay green — see the reconciled acceptance criteria.

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

0. ~~Does the demotion extend to the harmony guides?~~ **Decided: no, not
   here.** It gets its own story —
   [Extract the Harmonic Cores](../backlog/extract-the-harmonic-cores.md) —
   because the counter-argument is real (parallel fifths are arguably not
   *background* in a counterpoint exercise, whatever the species) and because
   three harmony guides reach into a core they also splat, which wants fixing
   before anything is demoted.

1. ~~`FuxCantusFirmus`: keep the 8-note gate, or split it?~~ **Decided: split.**
2. ~~`DiatonicMelody`: keep the 5-note gate?~~ **Decided: split, same as Fux.**
3. ~~Deferred demotion.~~ **Decided: folded in.** The measurement behind it: a
   valid *first*-species line scores 0.883 against `ThirdSpeciesMelody` today,
   and 0.561 with the cores demoted. `MOVING_MELODIC_CORE` is a second inherited
   core the original out-of-scope note never named, and the harmony guides have
   two of their own.
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
