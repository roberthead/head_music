<!--
metadata:
  created_at:   2026-07-06T09:06:45-07:00
  activated_at: 2026-07-06T09:14:45-07:00
  planned_at:   2026-07-06T09:35:50-07:00
  finished_at:
  updated_at:   2026-07-06T10:23:49-07:00
-->

# Story: Rework Style Analysis Scoring as a Weighted Rubric

## Summary

AS a curriculum author scoring student exercises (in the sibling `bardtheory` project)

I WANT the `Style::Analysis` fitness score to behave like a graded rubric — where the rules that define an exercise dominate the grade, and the score does not swing with the length of the line

SO THAT an otherwise-perfect melody that ignores the assigned brief (e.g. the wrong contour for a contour guide) earns a low grade, and two proportionally-equal submissions of different lengths earn the same grade

## Background

The scalar returned by `HeadMusic::Style::Analysis#fitness` is being adopted by the `bardtheory` curriculum as the **grade on a learning exercise**. That semantic — a grade, not an aesthetic judgment — is what drives every decision below.

Two problems surfaced in the melody contour guides, and they turn out to be **orthogonal**:

1. **Single-rule failures are diluted.** A melody that satisfies every rule except the assigned contour scores ~96%. Measured empirically on a 5-note descending line analyzed under `ArchContourMelody`: overall fitness `0.9607`, with the only failing annotation being `Contoured` at `0.618`.

2. **Scores are volatile with line length.** Rules that emit one penalty mark per offending note compound multiplicatively, so a proportionally-equal violation costs far more on a long line than a short one.

### Why #1 happens

`Analysis#fitness` is an **unweighted geometric mean** over every rule in the guide's `RULESET`:

```ruby
# lib/head_music/style/analysis.rb:25
fitness_scores.reduce(:*)**(1.0 / fitness_scores.length)
```

`ArchContourMelody` has 12 rules. One failing rule at the golden penalty (`PENALTY_FACTOR = GOLDEN_RATIO_INVERSE ≈ 0.618`) is diluted by the `1/12` exponent:

```
0.618 ^ (1/12) = 0.9607
```

The contour is not ignored — it is one binary rule competing with eleven others, and the geometric mean's exponent compresses any single failure toward 1.0.

A related, arguably worse defect of the same exponent: **a rule's failure is diluted by however many other rules happen to sit in the guide.** Wrong contour scores `0.618^(1/12) = 0.96` in a 12-rule guide but `0.618^(1/8) = 0.94` in an 8-rule guide. Adding an unrelated rule to a guide makes every existing rule more forgiving.

### Why #2 happens

An annotation's fitness is the **product** of its marks' fitnesses (`annotation.rb:59`), and guidelines built with `Mark.for_each` emit one mark per offending note. A rule broken on 2 notes scores `0.618² = 0.38`; the same 20%-violation rate on a 30-note line breaks ~6 notes and scores `0.618⁶ = 0.056`. Same proportional badness, wildly different score, purely because the line is longer. Note that `Contoured` itself is length-invariant (it emits a single `Mark.for_all`), which confirms the two problems are independent.

## Target behavior

- An otherwise-perfect melody with the **wrong contour** for its guide should grade **under 70%** — ideally **exactly 61.8%** (`GOLDEN_RATIO_INVERSE`).
- Two submissions with the **same proportional adherence** but different lengths should grade the **same** (within the tolerance of genuinely length-dependent musical facts, e.g. contour minimum-length guards).

## Design decisions (agreed)

These were settled during design discussion; they are the spec, not open questions.

- **Aggregator: weighted _arithmetic_ mean at the top level**, replacing the geometric mean. Weights are rubric point values. Rationale: the score is a *grade*, and grades are additive point rubrics. A weighted arithmetic mean expresses "contour is worth N points of the exercise" directly and legibly, and — critically for a teaching tool — produces a grade breakdown a student can be shown ("you lost 38 of your 100 points on contour"). The geometric mean's floor for a single dominant failure is its own penalty value (`≈61.8%`), which is unreachable-from-below and requires absurd weights (~30–100× everything else) to approach; the arithmetic mean hits any target with legible weights.

- **Golden-ratio rubric split (Design B).** Using the identity `φ⁻¹ + φ⁻² = 1` (`0.618 + 0.382 = 1`): weight the defining rule (contour) at `φ⁻¹ ≈ 61.8%` of the rubric and everything else at `φ⁻² ≈ 38.2%`, and have the contour rule score `φ⁻² = 0.382` (not zero) on failure. A wrong contour on an otherwise-perfect line then scores `0.618·0.382 + 0.382·1 = 0.618` — exactly the golden target. This keeps the golden penalty *inside* the rule (0.382 is itself a golden value) and makes "not a zero" true at both the rule and overall level. The contour weight is a **configurable default** (defaults to `φ⁻¹`), overridable per guide — the golden value is the chosen default, not a hardcoded constraint.

- **Rate-normalize each rule's fitness** so a rule reports a *rate* of adherence, not a *count* of violations. This makes each rule's score length-invariant at the source, which (with fixed weights) makes the overall grade length-invariant by construction. This is the fix for problem #2 and is independent of the aggregator choice.

- **Weights live at guideline-default + guide-level override.** A guideline declares a sensible default weight (its intrinsic importance); a guide's `RULESET` entry may override it for that context (via the existing `Annotation.with(...)` composition mechanism). This honors "the same rule matters differently in different guides" (contour dominates a contour guide) without re-encoding shared judgments in every ruleset and letting them drift.

- **Keep the golden multiplicative penalty _inside_ each rule.** `Mark#fitness`, `PENALTY_FACTOR`, and per-mark composition stay as-is at the rule level. Only the **top-level** fuser in `Analysis#fitness` changes from geometric to weighted-arithmetic. The multiplicative world is preserved where it already lives.

- **Contour is not a gate.** A wrong-contour line is not disqualified (0%); a student who wrote a musically excellent line that missed the brief demonstrated real skill and should grade ~61.8%, not zero. Under Design B "not a zero" holds even at the rule level (the contour rule bottoms out at `φ⁻²`, not 0). Contour is the highest-weighted *rubric* line item — a quality judgment, not a qualification.

- **Gate tier (qualification to be assessed).** Separate from quality, some rules answer "is there a gradable attempt here at all?" — their failure means *nothing to assess*, not *assessed poorly*. These compose **multiplicatively in front of the rubric**:

  ```
  fitness = ∏(gate fitnesses) × weighted_arithmetic_mean(rubric rules)
  ```

  This restores the hard-zero for genuinely disqualifying failures (an empty line → 0) that the arithmetic mean would otherwise delete — *without* zeroing quality failures like contour. Verified regression this fixes: an empty melody under the plain weighted mean scores **0.9653** (every rule vacuously passes at 1.0 except the lone low-weight `MinimumNotes`), where it must be 0. Gates are **graded multipliers**, not binary: an empty line → `MinimumNotes` = 0 → ×0; a line 4-of-5 notes → ×0.8 (mild haircut); a sufficient line → ×1 (no effect). Gates are pulled **out** of the rubric mean (no double-count), so rubric peer weights are computed over the non-gate rules.

- **Gate set (v1): sufficiency thresholds only.** `MinimumNotes`, and a new `MinimumMelodicIntervals` where appropriate — both check "is there enough of an attempt to grade?", never quality. Gate-ness is a **per-guide option** (`SomeRule.with(gate: true)`, defaulting per-guideline), applied "when appropriate" — a rule may gate in one guide and be absent or rubric in another. Broader gate candidates are deferred to a follow-up audit.

- **Soft floor for broken (but real) work.** For a submission that *passes the gates* (a real attempt) but scores badly on the rubric, the arithmetic mean deliberately stops failures from cascading to zero: it floors around 0.4–0.5, not near 0, because rate-normalized rules bottom out near `φ⁻¹` and the mean averages them. This is the intended consequence of grade semantics (partial credit) — a real-but-flawed attempt is not a literal 0%, while a non-attempt (gate failure) still is.

## Acceptance Criteria

- `Analysis#fitness` computes `∏(gate fitnesses) × weighted_arithmetic_mean(rubric rules)` — gates multiply in front; rubric rules are a weight-normalized arithmetic mean.
- Annotations expose a `weight` (per-guideline default, overridable via `Annotation.with(...)`) and a `gate?` predicate (per-guideline default, overridable via `.with(gate: …)`). Both defaults are configurable, not hardcoded magic numbers.
- Gates are pulled out of the rubric mean; rubric peer weights are computed over the non-gate rules so the contour share stays exactly `φ⁻¹`.
- In the contour guides, the `Contoured` rule carries weight `φ⁻¹` of the rubric (≈61.8%) by default; the remaining rubric rules split `φ⁻²` (≈38.2%). On a wrong contour the contour rule scores `φ⁻²` (0.382), not zero.
- An otherwise-perfect melody with the wrong contour grades at 61.8% (± rounding); definitely under 70%.
- Rule fitnesses are rate-normalized: two lines with the same proportional violation rate but different lengths produce the same rule fitness (and the same overall grade).
- A wrong contour is **not** a zero, at either the rule level (`φ⁻²`) or the overall grade (~0.618).
- **A non-attempt is a zero.** An empty line (and, where a `MinimumMelodicIntervals` gate applies, a line without enough melodic motion) grades 0 via the gate multiplier. A line just short of a sufficiency threshold takes a proportional haircut (e.g. 4-of-5 notes → ×0.8), not a cliff.
- `MinimumNotes` is a gate (graded multiplier); a `MinimumMelodicIntervals` gate exists and is wired into guides where appropriate.
- `adherent?` means every rule is adherent (a fully-correct submission still grades 1.0).
- Existing guide specs are updated to the new scoring; a perfect submission remains 1.0; a real-but-fully-broken submission (passing the gates) grades ~0.4–0.5 (soft floor, intended); a non-attempt grades 0.

## Scenario: Wrong contour grades in the low 60s

Given an otherwise well-formed diatonic melody whose shape does not match the assigned contour

When it is analyzed under a contour guide (e.g. `ArchContourMelody`)

Then the overall fitness is 61.8% (± rounding), and in all cases under 70%

And the failing `Contoured` annotation is the dominant contributor to the lost credit

## Scenario: Grade is length-invariant

Given two melodies that violate the same rule at the same proportional rate (e.g. 20% of notes), one short and one long

When each is analyzed under the same guide

Then both receive the same fitness for that rule, and the same overall grade

## Scenario: A rule's weight is contextual to the guide

Given a guideline that is defining in one guide and incidental in another

When the same guideline appears in two different `RULESET`s with different weights

Then each guide grades that rule according to its own weight, without changing the guideline class

## Scenario: A wrong contour is not a zero

Given a musically excellent melody with the wrong contour

When it is analyzed under a contour guide

Then the grade is low-but-nonzero (≈61.8%), reflecting the quality of the line while penalizing the missed brief

## Scenario: A perfect submission still grades 100%

Given a melody that satisfies every rule in its guide

When it is analyzed

Then `fitness` is 1.0 and `adherent?` is true

## Scenario: A non-attempt grades zero (gate)

Given an empty voice (no notes), or — where a `MinimumMelodicIntervals` gate applies — a line with insufficient melodic motion

When it is analyzed under a guide whose sufficiency rule is a gate

Then the gate fitness is 0, the gate multiplier drives the overall grade to 0

And this holds regardless of how many other rules vacuously pass

## Scenario: Falling just short of a sufficiency threshold takes a haircut, not a cliff

Given a melody with 4 notes under a guide requiring a minimum of 5 (`MinimumNotes.with(5, gate: true)`)

When it is analyzed

Then the gate contributes a graded multiplier (`4/5 = 0.8`), scaling the rubric grade down proportionally rather than to zero

## Open questions (resolved during planning)

- **Contour arrangement → resolved: Design B.** Contour weight defaults to `φ⁻¹` (≈61.8%); the contour rule scores `φ⁻²` (0.382) on failure. Both land the wrong-contour case on exactly 61.8% while keeping "not a zero" true at the rule level. (Design A — weight `φ⁻²`, rule → 0 — was rejected because it forces a raw zero and contradicts "golden penalty inside the rule.")
- **Literal constants vs. configurable → resolved: configurable, defaulting to golden.** The contour weight is a per-guideline default that happens to default to `φ⁻¹`; guides may override it. The golden value is the chosen default, not a hardcoded constraint.
- **Broken-line floor → resolved: accept the soft floor.** A real (gate-passing) but fully-broken melody grades ~0.4–0.5, not near 0. This is the intended consequence of the arithmetic mean and grade semantics.
- **Gate tier → resolved: needed, and narrow.** A qualification-to-be-assessed tier multiplies in front of the rubric (`∏ gate × rubric`). Gates are graded multipliers, not binary. The v1 gate set is sufficiency-only — `MinimumNotes` plus a new `MinimumMelodicIntervals` — wired per guide "when appropriate." Contour is explicitly *not* a gate (it is a rubric quality item). This restores correct 0-for-non-attempt behavior that the arithmetic mean would otherwise lose (empty line was scoring 0.9653).
- **Opportunities denominator → default `notes.length` where a rule scales with length; genuinely rule-specific otherwise.** For this story only `diatonic` and `maximum_notes` (the length-scaling rules that appear in contour guides) override `fitness_denominator`; the other `for_each` rules are deferred to a bounded follow-up.
- **Defining rule in non-contour guides → deferred.** Non-contour guides stay flat (all weights default to 1.0) for this story; promoting a defining rule (e.g. `Diatonic` in strict species) is a follow-up.
- **Structured grade-breakdown object for `bardtheory` → deferred.** The weighted terms make it cheap to add later (likely a small `Rubric` object); out of scope for v1, which delivers only the scalar.
- **Migration blast radius → measured.** ~81 spec files under `spec/head_music/style/` reference `fitness`/`adherent`/`messages`; most assertions are range-based and survive. See the migration step in the plan.

## Notes

- Empirical baseline reproduced during design: a 5-note C-major descending line (`G4 F4 E4 D4 C4`) under `ArchContourMelody` → `fitness 0.9607`, 12 annotations, only `Contoured` failing at `0.618`.
- Relevant files: `lib/head_music/style/analysis.rb`, `lib/head_music/style/annotation.rb`, `lib/head_music/style/mark.rb`, `lib/head_music/style/guidelines/contoured.rb`, `lib/head_music/style/guides/*contour_melody.rb`, `lib/head_music.rb` (golden constants).

## Implementation Plan

### Overview

Convert `HeadMusic::Style::Analysis#fitness` to `∏(gate fitnesses) × weight-normalized arithmetic mean of the rubric rules`; give `Annotation` a per-guideline default `weight` and a `gate?` predicate, both overridable through the existing `Annotation.with(...)` / `Configured` factory; and make length-scaling rules report an **adherence rate** via an overridable `fitness_denominator`. Contour guides weight `Contoured` at `φ⁻¹` (0.618, a configurable default) with rubric peers sharing `φ⁻²` (0.382); the contour rule fails to `φ⁻²` (0.382, not zero). `MinimumNotes` (and a new `MinimumMelodicIntervals`, where appropriate) become gates. Behavioral change only — no data model, persistence, or migrations.

**Crux resolved (Design B):** wrong-contour on an otherwise-perfect line = `0.618·0.382 + 0.382·1.0 = 0.618` exactly (gates pass, ×1). Perfect = `1.0`. Empty line = `0` (gate ×0). The contour rule bottoms out at `φ⁻²`, so "not a zero" holds at the rule and overall level; a non-attempt is still 0 via the gate.

**Gate regression this fixes (verified):** without the gate tier, an empty melody scores **0.9653** under the plain weighted mean — every rule vacuously passes at 1.0 except the lone low-weight `MinimumNotes` at 0. The old geometric mean hid this (one 0 zeros the product); the arithmetic mean deletes that implicit gate, so the gate tier is mandatory, not optional.

### Steps

1. **Characterization test first — lock the baseline before changing anything.**
   - Assert the *current* `Analysis.new(ArchContourMelody, voice).fitness` for a 5-note descending line ≈ `0.9607`. Run green, then update/remove after the change lands (documents the reproduced baseline).
   - Files: `spec/head_music/style/guides/arch_contour_melody_spec.rb`

2. **Add `weight` and `gate?` to `Annotation`.**
   - Add `DEFAULT_WEIGHT = 1.0` and `def self.default_weight = DEFAULT_WEIGHT` (subclasses override).
   - Add `def weight = options.fetch(:weight, self.class.default_weight)` (reads the existing protected `options`, `annotation.rb:92`). Do **not** add a parallel options hash — `weight`/`gate` share the `@options` bag with domain config like `contour:`.
   - Add `def self.default_gate? = false` and `def gate? = options.fetch(:gate, self.class.default_gate?)`, so gate-ness is a per-guideline default overridable per guide (`SomeRule.with(gate: true)`).
   - `Annotation.with(**options)` (line 33) already accepts arbitrary keys, so `SomeGuideline.with(weight: w, gate: true)` works for bare classes unchanged.
   - Add `Configured#with(**more)` → `Configured.new(guideline_class, options.merge(more))` so an already-configured entry (e.g. `MinimumNotes.with(5)`) can take a weight/gate override without dropping prior options. `Configured#new(voice)` already splats `**options`, so `:weight`/`:gate` flow through automatically.
   - Files: `lib/head_music/style/annotation.rb`

3. **Fix `Contoured.with` signature and set its golden default weight + penalty.**
   - Change `self.with(contour_key)` → `self.with(contour_key, **options)`, calling `super(contour: contour, **options)` (the positional-only signature is why `weight:` can't currently reach this rule).
   - Add `def self.default_weight = HeadMusic::GOLDEN_RATIO_INVERSE` (φ⁻¹ ≈ 0.618). Prefer a named constant (e.g. `DEFAULT_WEIGHT = HeadMusic::GOLDEN_RATIO_INVERSE`) so the default is legible and overridable.
   - Files: `lib/head_music/style/guidelines/contoured.rb`

4. **Contour rule fails to `φ⁻²`, not zero (the crux, Design B).**
   - Change `Mark.for_all(notes)` → `Mark.for_all(notes, fitness: HeadMusic::GOLDEN_RATIO_INVERSE**2)` (0.382), using the same explicit-`fitness:` mechanism 6 guidelines already use. `Mark#fitness`, `PENALTY_FACTOR`, and per-mark composition are untouched at the framework level; the golden penalty stays inside the rule.
   - Files: `lib/head_music/style/guidelines/contoured.rb`

5. **Rate-normalize `Annotation#fitness` via an overridable denominator — NOT a blanket nth-root.**
   - A global geometric mean over `marks.length` is a no-op for `for_all` rules (1 mark) and *double-penalizes* the 6 rules that already hand-roll a rate (`PENALTY_FACTOR**exponent`). Give the *rule* ownership of its opportunity count:
     ```ruby
     def fitness
       mark_fitnesses = [marks].flatten.compact.map(&:fitness)
       return 1.0 if mark_fitnesses.empty?
       mark_fitnesses.reduce(1, :*)**(1.0 / fitness_denominator)
     end

     def fitness_denominator = 1
     ```
   - Default `1` leaves every `for_all` gestalt rule (Contoured, MostlyConjunct, …) and the 6 custom-`fitness:` rules **exactly as today**. Override `fitness_denominator` only on rules whose penalty genuinely scales with line length → `PENALTY^(k/n)`, length-invariant for a fixed rate `k/n`. Guard so the denominator is never `< 1`.
   - Files: `lib/head_music/style/annotation.rb`

6. **Override `fitness_denominator` on the two length-scaling rules in contour guides — defer the rest.**
   - The 10 `for_each` guidelines: `diatonic`, `maximum_notes`, `no_rests`, `no_rests_after_note`, `notes_same_length`, `one_to_one`, `one_to_one_with_ties`, `consonant_climax`, `singable_range`, `avoid_overlapping_voices`. For this story override only the two that scale with length **and** appear in contour guides:
     - `diatonic.rb`: `def fitness_denominator = notes.length` (out-of-key notes / total — clean rate demonstrator).
     - `maximum_notes.rb`: `def fitness_denominator = notes.length` (overage notes / total).
   - Leave harmony-only `for_each` rules and all `for_all` rules for a bounded follow-up. `consonant_climax`/`singable_range`/`avoid_overlapping_voices` already emit 1–2 marks with severity in an explicit `fitness:` and are already near length-invariant — do not touch.
   - Files: `lib/head_music/style/guidelines/diatonic.rb`, `lib/head_music/style/guidelines/maximum_notes.rb`

7. **Rewrite `Analysis#fitness` as gate-multiplier × weighted arithmetic mean, and harden `adherent?`.**
   ```ruby
   def fitness
     return 1.0 if annotations.empty?
     @fitness ||= gate_factor * rubric_fitness
   end

   def adherent?
     annotations.all?(&:adherent?)
   end

   private

   def gate_factor
     gates.map(&:fitness).reduce(1, :*)   # multiplicative, graded (0 disqualifies)
   end

   def rubric_fitness
     rubric = annotations.reject(&:gate?)
     total_weight = rubric.sum(&:weight)
     return 1.0 if rubric.empty? || total_weight.zero?
     rubric.sum { |a| a.weight * a.fitness } / total_weight
   end

   def gates
     annotations.select(&:gate?)
   end
   ```
   - Gates multiply in front; the rubric is the weight-normalized arithmetic mean of the **non-gate** rules. `all?(&:adherent?)` (gates + rubric) is order-independent and decouples "is it perfect?" from float summation. `@fitness ||=` is safe (`0.0` is truthy). Empty-annotations, no-rubric-rules, and all-zero-weight edges short-circuit sensibly.
   - Verified landings under this formula: empty line → `0`; wrong-contour otherwise-perfect → `0.618`; perfect → `1.0`.
   - Files: `lib/head_music/style/analysis.rb`

8. **Designate the sufficiency gates.**
   - Make `MinimumNotes` a gate by default: `def self.default_gate? = true`. Its existing `marks` already returns fitness `0` (empty) or `notes.length / minimum` (short) — exactly the graded multiplier we want; no change to its scoring logic.
   - Add a new `MinimumMelodicIntervals` guideline mirroring `MinimumNotes` (`.with(n)`, `default_gate? = true`), counting melodic intervals (`melodic_intervals` / adjacent note-pairs) against a minimum, with the same graded-deficiency mark (`count / minimum`, `0` when none). This is a sufficiency check ("enough melodic motion to assess"), distinct from `always_move` (which flags each static pair as a quality issue).
   - Wire gates per guide "when appropriate" — `MinimumNotes` is already in `DiatonicMelody`/CF rulesets, so it becomes a gate there automatically; add `MinimumMelodicIntervals.with(n)` only to guides that need it. Do **not** blanket-add it.
   - Because gates are pulled out of the rubric mean (step 7), `MinimumNotes` no longer contributes a rubric weight — so the contour weighting in step 9 must divide `φ⁻²` across the **non-gate** peers only.
   - Files: `lib/head_music/style/guidelines/minimum_notes.rb`, new `lib/head_music/style/guidelines/minimum_melodic_intervals.rb` (+ `require` in `lib/head_music.rb`), spec for the new guideline.

9. **Weight the six contour guide RULESETs over the non-gate (rubric) peers (Design B).**
   ```ruby
   PEERS = HeadMusic::Style::Guides::DiatonicMelody::RULESET
   RUBRIC_PEERS = PEERS.reject { |rule| gate_rule?(rule) } # exclude MinimumNotes gate
   PEER_WEIGHT = (HeadMusic::GOLDEN_RATIO_INVERSE**2) / RUBRIC_PEERS.length
   RULESET = [
     *PEERS.map { |rule| gate_rule?(rule) ? rule : rule.with(weight: PEER_WEIGHT) },
     HeadMusic::Style::Guidelines::Contoured.with(:arch) # weight defaults to φ⁻¹
   ].freeze
   ```
   - `DiatonicMelody::RULESET` has **11 peers** (verified); `MinimumNotes` is now a gate, leaving **10 rubric peers** → `PEER_WEIGHT = φ⁻²/10`. Rubric peers share `φ⁻²` total; `Contoured` carries `φ⁻¹`. Because `φ⁻¹+φ⁻²=1` the weighted mean lands on `0.618` for a wrong contour with gates passing. (Determining `gate_rule?` at ruleset-build time: expose a class-level gate check, or filter on the guideline class — the gate default lives on the class, `MinimumNotes.default_gate? == true`.)
   - `.map` returns a new array, so the shared `DiatonicMelody::RULESET` is not mutated. `rule.with(weight:)` works for both bare classes (→ `Annotation.with`) and already-`Configured` entries (→ new `Configured#with` merge). `Contoured.with(:arch, weight: …)` can override per guide if ever desired.
   - Files: `lib/head_music/style/guides/{arch,valley,wave,ascending,descending,static}_contour_melody.rb`

10. **Regenerate spec expectations, then `bundle exec rubocop -a` and `bundle exec rspec`.** (Migration detail below.)

### Testing Strategy

- **Characterization baseline** (step 1): capture `0.9607` before the change; update after.
- **The five story scenarios**, in `spec/head_music/style/guides/*_contour_melody_spec.rb` (create if missing):
  1. Otherwise-perfect line, wrong contour → `be_within(1e-6).of(HeadMusic::GOLDEN_RATIO_INVERSE)` **and** `be < 0.70`.
  2. Length-invariance → two melodies (prefer `HeadMusic::Notation::ABC.parse` per project memory) with the same proportional Diatonic violation rate at different lengths → equal overall fitness.
  3. Perfect submission → `eq 1.0`, `adherent?` true.
  4. Real-but-fully-broken (passes gates) → `be_between(0.3, 0.55)` (soft floor: substantially below perfect, not near 0).
  5. Contextual weight override → `Klass.with(weight: 2.0).new(voice).weight == 2.0`; default reads `default_weight`; `MinimumNotes.with(5).with(weight: 0.1)` still enforces minimum 5.
  6. Non-attempt (gate) → empty voice → `fitness == 0` and `adherent?` false; assert the empty-line regression (would be ~0.9653 without gates) is now 0.
  7. Sufficiency haircut → 4-of-5 notes under `MinimumNotes.with(5, gate: true)` → gate multiplier 0.8, overall = `0.8 × rubric` (not 0, not full).
- **Gate specs**: `MinimumNotes#gate?` true by default and overridable (`.with(5, gate: false)`); new `MinimumMelodicIntervals` gate — sufficient motion → adherent, too little → graded deficiency, none → 0.
- **Rule-level rate spec** on `Diatonic`: 1-of-5 and 2-of-10 out-of-key → both `PENALTY^0.2`.
- **Rule-level penalty spec** on `Contoured`: a wrong-contour line → annotation fitness `eq HeadMusic::GOLDEN_RATIO_INVERSE**2` (0.382).
- **Exact-`eq` assertions that must change:**
  - `spec/head_music/style/guidelines/contoured_spec.rb` (the `eq PENALTY_FACTOR` rule-level cases) → change to `eq HeadMusic::GOLDEN_RATIO_INVERSE**2` (Contoured now fails to 0.382).
  - `spec/head_music/style/guidelines/diatonic_spec.rb`, `maximum_notes_spec.rb`: single-violation `eq PENALTY_FACTOR` cases → recompute to `PENALTY^(1/n)` per fixture.
- **Assertions that must stay green (do not edit):** the many `eq PENALTY_FACTOR` / `eq SMALL_PENALTY_FACTOR` assertions in `for_all` guideline specs (large_leaps, singable_intervals, suspension_treatment, etc.) are unaffected (denominator 1). `analysis_spec.rb` adherent cases (`eq 1.0`) should still pass — verify.
- **Migration of the ~81 spec files:** most assertions are range-based (`be_between`, `be <`) and survive. Process: (1) `grep -rn "its(:fitness)\|\.fitness).to\|adherent" spec/head_music/style/` and classify each as range (spot-check), exact-on-`for_all` (unaffected), exact-on-Contoured/overridden-`for_each` (regenerate), or guide-level (regenerate); (2) write a throwaway script in the scratchpad that instantiates each affected guide/fixture and prints the actual new fitness — source expected constants from it rather than hand-computing; do **not** check it in; (3) batch edits by guide, running `bundle exec rspec spec/head_music/style/guides` and `.../guidelines` per directory to localize failures.

### Risks & Sequencing

- **Land order to keep the suite green:** steps 2 → 3 → 4 → 5 → 7 (framework: weight + gate + gate-multiplier fitness + rate hook + Contoured penalty) as one coherent change, then 6 (rate overrides), then 8 (designate gates + `MinimumMelodicIntervals`), then 9 (contour weights over rubric peers), then 10 (spec migration). Run the full suite after 7 and again after 9.
- **[Resolved by the gate tier] Veto-to-zero semantics.** The old geometric mean zeroed the whole grade on any single `0`-fitness rule; the arithmetic mean would delete that (empty line → 0.9653). The gate tier restores it *for sufficiency rules only* (`MinimumNotes`, `MinimumMelodicIntervals`). **Audit remaining `fitness: 0` paths** to confirm none *other* than sufficiency needs veto power — grep the guidelines for `fitness: 0`; if a non-sufficiency rule genuinely must disqualify, mark it a gate too. Do not assume the two known gates are exhaustive.
- **[bardtheory coordination — highest] Every grade shifts numerically.** Breaking change for the downstream consumer. Repo is at 14.0.0 → bump **major** and document the fitness-scale change (and the new 0-for-non-attempt behavior) in the changelog. Any consumer pinning expected fitness values will break.
- **Global aggregator change.** `Analysis#fitness` is global, so *every* guide moves from geometric to gate-multiplier × weighted-arithmetic mean (non-contour rubric rules default to weight 1.0 → equal-weight arithmetic mean). Direction is the same but magnitudes differ across all 26 guides — the ~81 specs are the safety net; do not skip a full-suite run.
- **Gate-ness at ruleset-build time.** Step 9 needs to know which RULESET entries are gates *before* instances exist, to compute rubric peer weight. Keep the gate default on the guideline class (`self.default_gate?`) so a class/`Configured` entry can be classified without a voice. A per-entry `.with(gate: true)` override that flips a normally-rubric rule to a gate in one guide would not be visible to that build-time filter — if that case ever arises, compute peer weights from the `Configured` options, not just the class.
- **Edge cases to add explicitly:** empty melody (→ 0), single-note melody, a line with all-repeated notes (0 melodic motion — the `MinimumMelodicIntervals` case), and a guide where multiple rubric rules fail simultaneously (confirm graceful degradation, not collapse).
- **Process note:** the product-manager specialist stalled during planning and returned no output; scope/edge-case items were reasoned directly and folded in. Treat the scope boundary and deferred items (grade-breakdown object, non-contour defining rules, remaining `for_each` rate overrides) as recommendations to confirm, not vetted PM decisions.
