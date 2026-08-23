<!--
metadata:
  created_at:   2026-08-22T18:13:53-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-08-22T18:13:53-07:00
-->

# Disqualify, Don't Discount

AS a student submitting a counterpoint exercise

I WANT a rule I am forbidden to break to be able to disqualify my submission

SO THAT writing parallel octaves costs me more than a discount I can pay for with
everything else I did well

Split out of [Extract the Harmonic Cores](extract-the-harmonic-cores.md), which
established that no arrangement of tiers or weights can produce this and stopped
there.

## The defect

Every grade in the system is a weighted arithmetic mean of item fitnesses. A
weighted mean is **compensatory**: excellence on one item always buys back a
failure on another. There is no arrangement of weights that changes this, only
arrangements that change the exchange rate.

Concretely, on `SecondSpeciesHarmony` after the harmonic re-tiering: one parallel
octave on a downbeat moves the grade from 1.000 to 0.982. A student who writes
parallel octaves throughout, and is otherwise flawless, still passes comfortably.
The guideline is named `NoParallelPerfectOnDownbeats` — *no* — and the arithmetic
can only say *less*.

## What has already been ruled out

Measured during [Extract the Harmonic Cores](extract-the-harmonic-cores.md):

- **More weight.** Raising a prohibition's weight raises its discount and
  nothing else. It stays purchasable.
- **A third tier.** Splitting the rubric φ⁻¹ / φ⁻³ / φ⁻⁴ and putting the
  prohibitions in their own tier gives a failing parallel **0.941** — *worse*
  than the 0.900 it scored under a flat rubric — because φ⁻³ divided among four
  prohibitions is 0.059 each. Adding a tier subdivides a budget; it does not
  change the arithmetic operating on it.
- **The strength axis.** Strong-weighs-twice-weak fixes the *ordering* — a
  prohibition now costs twice a preference — and leaves the *kind* untouched.

## What is worth exploring

**Gates already multiply.** `fitness = gate_factor * rubric_fitness` is the only
non-compensatory arithmetic in the system, and it works. What makes it unusable
for prohibitions is that `assessable?` is defined as "all gates adherent," so
anything expressed as a gate also declares the submission ungradeable. Those are
two separate claims — "this cannot be judged" and "this is disqualified" — and
they share one mechanism.

Decoupling them is the smallest change that could work: a veto set that
multiplies into the grade without touching `assessable?`.

**But φ⁻ⁿ may be too harsh multiplicatively.** A guideline's fitness is already a
product of its marks; multiplying that product into the grade compounds twice.
One violation at φ⁻¹ takes the whole grade to 0.618. `√fitness` gives 0.786 for
one violation and 0.618 for two, which reads more like a penalty and less like an
execution — but it is a second arithmetic to explain and justify.

**A weighted geometric mean** is the textbook answer and is a drop-in that reuses
the existing weights: `Π fᵢ^wᵢ`. It is non-compensatory in exactly the right way
and needs no new concept. It is also too blunt as written — any single item at
0 zeroes the grade, including a background one — so it would need a floor, and
the floor is where the design gets argued about.

## Questions to settle

- Is "disqualified" a property of the guideline, of the guide's declaration of
  it, or of the tradition? Parallel octaves are absolute in Fux and negotiable in
  later practice, which suggests the declaration or the tradition rather than the
  rule.
- How do a failed gate and a failed veto compound? Two multiplicative factors
  against one rubric needs stated semantics before it needs code.
- Should a disqualified submission report a grade at all, or a distinct verdict?
  A student told "0.24" learns less than one told which rule ended it.
- Does the veto set stay small on purpose? The candidate is the three
  parallel-perfect prohibitions and nothing else; a veto set that grows becomes a
  second rubric.

## Scope

- Decide the four questions above.
- Implement the chosen arithmetic and state it in the `GuideAssessment` comment,
  which currently describes only the gate-times-rubric form.
- Show the effect on the corpus, and expect it to be invisible: of 252 assessable
  rows only 35 fail anything and **none fails a hard prohibition**, so the
  corpus cannot demonstrate this and constructed cases must.

## Acceptance Criteria

- A voice that violates a vetoing guideline cannot reach a passing grade by
  adherence elsewhere, demonstrated with a constructed voice that is otherwise
  flawless.
- A voice that fails a gate is still distinguishable from a voice that is merely
  disqualified — `assessable?` does not become true for the one or false for the
  other.
- The compounding rule for gate factor and veto factor is stated in a comment and
  covered by a spec that exercises both at once.
- The corpus before/after table is produced and its emptiness is stated rather
  than read as "no regression."

## Notes

This is one of two things [Extract the Harmonic Cores](extract-the-harmonic-cores.md)
found and declined to fix. The other is that a wrong answer cannot score worse
than the guideline's own mark — `Contoured` marks a mismatched contour at φ⁻², so
a trough submitted for an arch floors at 0.382 no matter how it is weighted. That
one lives in [Tell the Species Apart](tell-the-species-apart.md).

The two are related but not the same: this story is about a fault the arithmetic
refuses to take seriously, that one is about a fault the guideline itself reports
gently.
