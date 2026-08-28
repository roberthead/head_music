<!--
metadata:
  created_at:   2026-08-27T16:10:10-07:00
  activated_at: 2026-08-27T16:37:33-07:00
  planned_at:   2026-08-27T16:57:00-07:00
  finished_at:
  updated_at:   2026-08-27T17:17:15-07:00
-->

# Species Guide Harmonic Weights

AS a student submitting a first species counterpoint exercise

I WANT the parallel-perfect prohibition to weigh what it is worth

SO THAT first-species harmony assessments improve

## The defect

Measured against `FirstSpeciesHarmony` on 2026-08-27, using Fux ch. 1 fig. 5 in
D dorian, which grades 1.0000 as published:

| Counterpoint | Grade |
| --- | --- |
| As published | 1.0000 |
| One parallel octave, at its cheapest placement | 0.9514 |
| The cantus firmus doubled an octave up throughout | 0.8300 |

The third row is not a counterpoint at all — it is one line sung twice — and
it earns a B.

It earns it honestly. The guide's two primaries hold 61.8% of the grade between
them, and a doubled line satisfies both perfectly: it is faithfully one note
against one (`OneToOne`), and it has no unisons in the middle
(`NoUnisonsInMiddle`). What it fails is four secondary items holding 0.2229
between them — `ApproachPerfectionContrarily`, `NoParallelPerfectOnDownbeats`
and `PreferContraryMotion` all pinned at 0.0081, and `PreferImperfect` at
0.6180. `NoParallelPerfectOnDownbeats` alone weighs 0.0637.

This is not a compensatory-mean problem. 78% of the weight sits on items the
doubled line genuinely satisfies; nothing was forgiven.

## The change

Promote `NoParallelPerfectOnDownbeats` to primary in `FirstSpeciesHarmony`, and
nowhere else. Measured, not projected:

| Counterpoint | Current | Promoted |
| --- | --- | --- |
| As published | 1.0000 | 1.0000 |
| One parallel octave | 0.9514 | 0.8921 |
| Doubled throughout | 0.8300 | 0.6674 |

The prohibition goes from 0.0637 to 0.2060; the two existing primaries drop from
0.3090 to 0.2060 each; the remaining secondaries absorb the vacated budget.

First species is where this belongs. The tier policy says a species guide is
about the dissonance treatment its rhythm makes possible, and two-part craft is
background — but first species has no dissonance treatment, and its two
primaries are rhythm-and-texture bookkeeping. Note-against-note consonance
handling is what the species is for, so the prohibition is its subject.

The promotion became expressible in one guide only at `5fbab86`, which replaced
the membership partition with direct tier declarations and left
`INHERITED_HARMONIC_CRAFT` as a policy the specs enforce. The place to record a
deliberate exception already exists.

## Why only first species

Promoting the same item in each harmony guide, measured 2026-08-27:

| Guide | Before | After | Budget taken from |
| --- | --- | --- | --- |
| `FirstSpeciesHarmony` | 0.0637 | 0.2060 | `NoUnisonsInMiddle`, `OneToOne` |
| `SecondSpeciesHarmony` | 0.0477 | 0.3090 | `WeakBeatDissonanceTreatment` |
| `ThirdSpeciesHarmony` | 0.0477 | 0.3090 | `ThirdSpeciesDissonanceTreatment` |
| `ThirdSpeciesTripleMeterHarmony` | 0.0477 | 0.3090 | `TripleMeterDissonanceTreatment` |
| `FirstThreeSpeciesHarmony` | 0.0477 | 0.3090 | `FloridDissonanceTreatment` |
| `FourthSpeciesHarmony` | 0.0477 | 0.2060 | `SecondSpeciesBreak`, `SuspensionTreatment` |
| `FifthSpeciesHarmony` | 0.0424 | 0.2060 | `FloridDissonanceTreatment`, `SuspensionTreatment` |

In the four single-primary guides the prohibition would weigh **exactly as much
as the dissonance treatment the guide exists to teach**. First species is the
mild case only because it already has two primaries to dilute.

Worse, in those guides the promotion can *raise* the grade of the line it is
meant to punish. A submission that already fails the taught rule loses almost
nothing when that rule's weight is halved, while the vacated budget flows to
secondaries it passes. Measured in `ThirdSpeciesHarmony`, the doubled-octave
line scores **0.2300 now and 0.2617 promoted** — its
`ThirdSpeciesDissonanceTreatment` is pinned at 0.0081, so halving that weight is
a net gain. The worse the dissonance treatment, the more the promotion pays.

First species cannot show this effect: its primaries are structural rules a
doubled line satisfies at 1.0, so there is nothing to rescue.

## What was ruled out

- **The arithmetic.** Three ways out were measured during
  [Extract the Harmonic Cores](../done/extract-the-harmonic-cores.md) and
  rejected: more weight only changes the exchange rate, a third tier subdivides
  a budget rather than changing the arithmetic on it, and the strength axis
  fixes the ordering and not the kind.
- **Disqualification.** Proposed in the retired *Disqualify, Don't Discount* and
  settled: a grade reports how well a submission did, not whether it is
  admissible.
- **Narrowing the overlap with `ApproachPerfectionContrarily`.** A parallel
  octave marks both, one mark each, costing 0.0486 between them on one
  violation. They say different things all the same — one is about approach
  motion to any perfect consonance, the other about consecutive perfects on
  downbeats — so the partial overlap stands and neither rule narrows.
- **How `PreferImperfect` marks.** It scored 0.6180 against a line of nothing
  but perfect consonances, which reads low for a total failure of the
  preference, and it may account for more of the 0.8300 than the tier does.
  Worth measuring here so the next story starts from a number; changing how a
  guideline marks is its own story.

## Scope

`FirstSpeciesHarmony`, the tier policy in `SpeciesHarmony`, and `base_spec`'s
enforcement of it. The other six harmony guides are measured and deliberately
unchanged.

Re-measure rather than quoting the figures above: `bin/guide_grade_corpus.rb`
grades the whole corpus through every guide, and `bin/guide_grade_table.rb`
derives its prose from its own data.

Out of scope: the grading arithmetic, how `PreferImperfect` marks, any veto or
disqualification mechanism, and the `No*` → `Avoid*` rename — each its own
change.

## Acceptance Criteria

- `NoParallelPerfectOnDownbeats` is primary in `FirstSpeciesHarmony` and
  secondary everywhere else.
- `INHERITED_HARMONIC_CRAFT` records the promotion as a named exception, and
  `base_spec`'s "the harmonic cores are background" group permits exactly that
  one and no other.
- A doubled-octave fixture is in the corpus. Only 5 of 114 corpus voices move
  under this change today, so nothing currently graded exercises it.
- What `PreferImperfect` contributes to the doubled-octave grade is written
  down, so the next story starts from a number.
- The corpus is captured before and after, and every grade that moves is
  accounted for — not merely observed to have moved.
- The grades document is regenerated from its own data rather than edited.

## Implementation Plan


Four lines of `lib/` change, landed between three corpus captures. The
promotion itself is mechanically safe — `reject_duplicates` makes a
half-promoted item raise at require time — so the real work is the capture
sequencing, the exception register, and the guard that keeps a second
promotion from slipping in unrecorded.

### Ordering: three captures, two joins

This is the trap. The doubled-octave fixture must exist in **both** captures
of the promotion join, and its own addition must be measured as a separate
join.

`bin/guide_grade_table.rb` partitions the after-capture on `[corpus, guide]`.
Rows present only in the after capture are `added` and excluded from the
counts. Add the fixture between the before and after of one join and its 60
rows land in `added` — the 0.8300 → 0.6674 drop, the one row this story
exists to demonstrate, never appears in any table.

Adding it before the first capture is equally wrong: `guide_grade_corpus.rb`
requires a seam edit be *proven* a no-op, and with a single capture there is
no evidence the 142 pre-existing entries were untouched. A byte-diff cannot
be that proof, because the file gains 60 rows by construction. The proof is
the join itself reporting `moved=0 added=60 removed=0`. The `removed=0` half
is why the fixture is **appended** to the corpus source list and never
inserted into `FUX_FIRST_SPECIES_EXAMPLES`, which would shift every
`fux_first_species_examples-N-vM` label.

```bash
mkdir -p tmp
bundle exec ruby bin/guide_grade_corpus.rb tmp/c0.json      # rows=4260 corpus=142

# fixture only: spec/spec_helper.rb plus one word in the corpus script
bundle exec ruby bin/guide_grade_corpus.rb tmp/c1.json      # rows=4320 corpus=144
bundle exec ruby bin/guide_grade_table.rb tmp/noop.md \
  "the doubled-octave fixture:tmp/c0.json:tmp/c1.json"      # moved=0 added=60 removed=0

# the lib and spec changes
bundle exec rubocop -a && bundle exec rake
bundle exec ruby bin/guide_grade_corpus.rb tmp/c2.json      # rows=4320

bundle exec ruby bin/guide_grade_table.rb \
  user-stories/current/species-guide-harmonic-weights.grades.md \
  "the doubled-octave fixture:tmp/c0.json:tmp/c1.json" \
  "the promotion:tmp/c1.json:tmp/c2.json"
```

### Steps

1. **Capture `c0` on a clean tree** with `bundle exec rake` green (6822
   examples, 0 failures, 99.76% line coverage).

2. **Add the doubled-octave fixture and nothing else; capture `c1`; prove the
   no-op.** It goes in `spec/spec_helper.rb` rather than inline in the corpus
   script so `first_species_harmony_spec.rb` grades the same object the
   corpus does. Append `doubled_octave_examples` to the corpus script's source
   list — one word.

   ```ruby
   # Not a counterpoint: the Fux chapter one figure 5 cantus firmus sung
   # again an octave up. One line, twice.
   DOUBLED_OCTAVE_EXAMPLES = [
     {
       source: "Fux chapter one figure 5 doubled at the octave",
       key: "D dorian",
       cantus_firmus_pitches: %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4],
       counterpoint_pitches: %w[D5 F5 E5 D5 G5 F5 A5 G5 F5 E5 D5]
     }
   ].freeze
   ```

3. **Record the promotion in `SpeciesHarmony`.** Keyed by guide **key
   string**, not class constant: `lib/head_music.rb:287-288` loads
   `species_harmony` before `first_species_harmony`, so a class reference
   here is a load-time `NameError`.

   ```ruby
   HARMONIC_CRAFT_PROMOTIONS = {
     "first_species_harmony" => [HeadMusic::Style::Guidelines::NoParallelPerfectOnDownbeats]
   }.freeze
   ```

   `INHERITED_HARMONIC_CRAFT` itself is unchanged — the prohibition is still
   background in the other six. Rewrite its comment, which currently promises
   the exception "belongs here," to point at the new constant.

4. **Promote the item in `FirstSpeciesHarmony`**, writing both sides out
   rather than deriving them from the register.

   ```ruby
   primary_items(
     HeadMusic::Style::Guidelines::NoUnisonsInMiddle,
     HeadMusic::Style::Guidelines::OneToOne,
     HeadMusic::Style::Guidelines::NoParallelPerfectOnDownbeats
   )

   secondary_items(*HARMONIC_CORE, except: HeadMusic::Style::Guidelines::NoParallelPerfectOnDownbeats)
   ```

   Keep `NoUnisonsInMiddle` **first**: `README.md:109` documents
   `guide.primary_items.first` as that guideline for this exact guide.
   Deriving the pair from the register would buy nothing — forgetting
   `except:` already raises at require time via `reject_duplicates`, and
   excepting without promoting is caught by `base_spec`.

5. **Rewrite the `base_spec` guard** at `describe "the harmonic cores are
   background"`. `match_array` against the register closes both directions;
   a literal pin on the register closes the third, since a second promotion
   added to *both* the hash and a guide would keep a purely derived loop
   green. The per-guide loop is itself the "other six unchanged" assertion —
   six of its seven examples assert an empty promotion set — so no per-file
   specs are needed.

   Leave `describe "the harmony guides hold the rules they held"` alone. It
   reads `guide_items`, which unions the tiers, so it is unchanged by a tier
   move — and that it still passes is evidence the change moves tier without
   changing what is graded.

6. **Fix the two composite literals** in
   `spec/head_music/style/composite_assessment_spec.rb`. Line 125 **breaks**:
   the harmony member for `fux_first_species_examples[7]` becomes
   `0.869504831500`. Line 129 **passes while going stale** — it pins
   `0.945627013125` as the arithmetic mean it must differ from, and the new
   arithmetic mean is `0.934752415750`. Nothing reports the second one.

7. **Add grading specs** to `first_species_harmony_spec.rb` (see Testing
   below).

8. **Capture `c2`, correct the generator's prose, generate the document.**
   `bin/guide_grade_table.rb` classifies synthetic entries by
   `grep(/\Aagainst-|\Asolo-/)` and calls everything else a *published
   fixture*, so the regenerated doc would claim the doubled-octave voices are
   published Fux material. Correct that **in the script**, after `c2` exists —
   the script is a post-processor and `9dedd50` is the precedent. Prefer a
   three-way split (published / ladder / constructed counterexample) over
   widening the regex, which would falsify the neighbouring sentence.

9. **Housekeeping.** The `PreferImperfect` number goes in the story and a
   spec, *not* the grades doc, whose capture schema holds only whole-guide
   fitness. Add the generated doc to `user-stories/index.html`. `CHANGELOG.md`
   under `## [Unreleased]` → `### Changed`.

### What moves, and why

18 rows: 9 voices × 2 registry entries (`first_species_harmony` and the
`first_species` composite). No other guide moves. The story's "5 of 114"
reproduces.

| corpus voice | before | after | delta |
| --- | ---: | ---: | ---: |
| `against-cantus-4` | 0.410249 | 0.454812 | **+0.044563** |
| `against-cantus-8` | 0.639480 | 0.589125 | −0.050355 |
| `fux_first_species_examples-1-v0` | 0.945627 | 0.934752 | −0.010875 |
| `fux_first_species_examples-1-v1` | 0.945627 | 0.934752 | −0.010875 |
| `fux_first_species_examples-7-v0` | 0.945627 | 0.934752 | −0.010875 |
| `fux_first_species_examples-7-v1` | 0.891254 | 0.869505 | −0.021749 |
| `fux_first_species_examples-10-v1` | 0.975684 | 0.970820 | −0.004863 |
| `doubled_octave_examples-0-v0/v1` | 0.829983 | **0.667416** | −0.162568 |

A voice rises exactly when the items that gained weight outscore the items
that lost them. The sole riser, `against-cantus-4`, is a synthetic four-note
ladder scoring `OneToOne` at 0.1459 and `NoUnisonsInMiddle` at 0.3820 against
a prohibition at 0.3820 and three secondaries at 1.0. It is pinned by nothing
and must be explained in the accounting prose or it reads as a bug.

### What `PreferImperfect` contributes

Measured on the doubled-octave line against the promoted guide. This
**contradicts the story's guess** that it may account for more of the 0.8300
than the tier does:

| | value |
| --- | --- |
| grade | 0.667416 |
| `PreferImperfect` item fitness | 0.618034 (= φ⁻¹ exactly) |
| its marks | **1** — one mark for the whole line |
| its normalized weight | 0.038197 |
| what it forgoes | **0.014590** |

So 0.0146 is the entire budget a follow-up story can win there — 4.4% of the
0.3326 deficit. Ten consecutive perfect octaves earn one mark, not ten; on the
same line `NoParallelPerfectOnDownbeats` issues 10 marks and scores 0.008131.
That contrast is the finding.

### Testing

Exactly two examples fail under the promotion: `base_spec` (step 5) and
`composite_assessment_spec:125` (step 6). One goes silently stale
(`:129`). Coverage does not move.

Verified unaffected — do not touch: `base_spec` lines 71-76 and 84-133 (all
read `guide_items`, which unions tiers); every existing example in
`first_species_harmony_spec.rb` (`guidelines_of` spans tiers, `adherent?` is
tier-blind); `composite_guide_spec.rb`; `guide_spec.rb`.

New specs, all in `first_species_harmony_spec.rb`:

- **Fill the existing gap.** The `include` block lists eight guidelines and
  omits `NoParallelPerfectOnDownbeats` — the guide's own spec never names the
  rule about to become its subject.
- **Pin the tier**, via `described_class.primary_items.map(&:guideline)`. No
  companion "and not as background" example: `reject_duplicates` raises at
  load, so that case is unreachable.
- **The thesis, executable**, over `doubled_octave_examples`. Follow the
  two-expectation pattern at `second_species_harmony_spec.rb:38-52` — a
  derived ceiling *and* a literal landing, each with its reason. The ceiling:
  with three equal strong primaries the prohibition owns φ⁻¹/3 = 0.206011,
  and at 0.008131 on it the grade cannot exceed 0.795664 even with everything
  else perfect.
- **The marking contrast:** 10 marks against 1. Public API only
  (`GuideItemAssessment#fitness` / `#marks`), never the private
  `rubric_weights`.
- **The published line is untouched:** Fux ch.1 fig. 5 still grades exactly
  1.0, which is what makes this a sharpening rather than a general
  depression.

### Risks

- **The seam-edit rule is the whole risk surface.** A fixture on the wrong
  side of a capture boundary yields a document that looks complete and proves
  nothing. The `moved=0 added=60 removed=0` check is not optional.
- **`composite_assessment_spec:129`** passes with a stale literal and nothing
  reports it.
- **Generated-prose drift** if `guide_grade_table.rb` is not corrected — the
  exact failure `3db5d33` was written to prevent.
- **Should the one-parallel line also join the corpus?** Outside the AC as
  written. It costs 60 rows and no extra capture, but the corpus already
  holds real material in that band.

## Outcome

Landed as planned. The measured figures are in
[the grades document](species-guide-harmonic-weights.grades.md), generated from
three captures joined in two steps: `c0 → c1` adds the doubled-octave fixture
and is a **provable no-op** (`moved=0 added=60 removed=0`), and `c1 → c2` is the
promotion alone (`moved=18 added=0 removed=0`).

| Counterpoint | Before | After |
| --- | ---: | ---: |
| Fux ch. 1 fig. 5 as published | 1.000000 | 1.000000 |
| Doubled at the octave throughout | 0.829983 | **0.667416** |

The doubled line falls from a B to a D. The published line it is built from does
not move at all, which is what makes this a sharpening rather than a general
depression.

### Every mover, accounted for

18 rows moved: 9 voices × 2 registry entries (`first_species_harmony` and the
`first_species` composite, whose delta follows from the harmony member by
geometric mean against an unchanged melody grade). No other guide moved.

No item's fitness changed — a tier move changes only the weights — so every
delta is exactly

> Δgrade = Σᵢ Δwᵢ · fᵢ

and since the weights still sum to one, this is a transfer. Two donors give up
0.103006 each: `NoUnisonsInMiddle` and `OneToOne` fall from φ⁻¹/2 = 0.309017 to
φ⁻¹/3 = 0.206011. Seven receivers take the 0.206011 — `NoParallelPerfectOnDownbeats`
takes 0.142350 of it (0.063661 → 0.206011) and the six remaining background items
share the other 0.063661. So

> Δgrade = 0.206011 × (what the voice scores on the receivers − what it scores on the donors)

and a voice rises exactly when it is written better on what gained weight than on
what lost it. That single rule accounts for all nine:

| voice | on the donors | on the receivers | Δ grade |
| --- | ---: | ---: | ---: |
| `against-cantus-4` | 0.2639 | 0.4802 | **+0.044563** |
| `against-cantus-8` | 0.6910 | 0.4466 | −0.050355 |
| `fux_first_species_examples-1-v0` | 1.0000 | 0.9472 | −0.010875 |
| `fux_first_species_examples-1-v1` | 1.0000 | 0.9472 | −0.010875 |
| `fux_first_species_examples-7-v0` | 1.0000 | 0.9472 | −0.010875 |
| `fux_first_species_examples-7-v1` | 1.0000 | 0.8944 | −0.021749 |
| `fux_first_species_examples-10-v1` | 1.0000 | 0.9764 | −0.004863 |
| `doubled_octave_examples-0-v0` | 1.0000 | 0.2109 | **−0.162568** |
| `doubled_octave_examples-0-v1` | 1.0000 | 0.2109 | **−0.162568** |

**The sole riser is not a bug.** `against-cantus-4` is a synthetic four-note
ladder that fails both donors — `OneToOne` at 0.145898 and `NoUnisonsInMiddle`
at 0.381966, averaging 0.2639 — while scoring 0.4802 across what gained,
including two items at 1.0. Taking weight off the rules it fails hardest and
putting it on rules it fails less had to raise it. This is the promotion working
as designed on a line that was never counterpoint to begin with; the ladders
exist to hold the edges of the arithmetic, not to be graded fairly.

**The story's "5 of 114" reproduces exactly.** The corpus held 142 entries
before the fixture, 28 of them synthetic ladders, leaving 114 of published
material — and exactly 5 of those 114 move: two voices of Fux figure 6 with
errors, two of figure 14, and one of figure 21. The published corpus barely
notices this change; the line it was built to catch loses a sixth of its grade.

The six voices at 1.0000 on the donors are the mirror image: they satisfy both
structural primaries perfectly, so any weight moved away from those can only
cost them. They fall by between 0.005 and 0.022 — the sharpening's price on
published material, and small.

### What `PreferImperfect` contributes

Measured on the doubled-octave line against the promoted guide. This
**refutes the story's guess** that it may account for more of the 0.8300 than
the tier does:

| | value |
| --- | --- |
| grade | 0.667416 |
| `PreferImperfect` item fitness | 0.618034 (= φ⁻¹ exactly) |
| its marks | **1** — one mark for the whole line |
| its normalized weight | 0.038197 |
| what it forgoes | **0.014590** |

0.014590 is the entire budget a follow-up story can win by changing how
`PreferImperfect` marks — 4.4% of the 0.332584 deficit, and about a ninth of
what the tier move was worth. The contrast is the finding: eleven notes of
nothing but perfect octaves earn `PreferImperfect` **one** mark, while
`NoParallelPerfectOnDownbeats` issues **ten** and scores 0.008131. Both are
pinned in `first_species_harmony_spec.rb`.

### One departure from the acceptance criteria

The AC asks that "`INHERITED_HARMONIC_CRAFT` records the promotion as a named
exception." The promotion is registered in a **sibling** constant,
`SpeciesHarmony::HARMONIC_CRAFT_PROMOTIONS`, and `INHERITED_HARMONIC_CRAFT` is
unchanged.

Recording it inside `INHERITED_HARMONIC_CRAFT` would mean removing
`NoParallelPerfectOnDownbeats` from it — and that list is the policy every one
of the seven harmony guides is held to. Removing the item would stop being an
exception for first species and become permission for all seven: any guide
could then promote the prohibition and no spec would notice. The register is
keyed by guide precisely so the exception names its own scope. The AC's intent —
the decision written down once, where a reader will find it — is met, and
`base_spec` now enforces both directions plus a literal pin on the register
itself.

### Where the generator was wrong

`bin/guide_grade_table.rb` is a post-processor, corrected after both captures
existed. Two prose defects, neither of which could touch a number:

- It classified every non-ladder voice as a **published fixture**, so the
  document would have called the doubled-octave line published Fux material.
  Split three ways — published / ladder / constructed counterexample — rather
  than widening the ladder regex, which would have falsified the sentence after
  it (the doubled line is first-species material and is not a ladder).
- It printed the last capture's row count as `first_capture_entries × guides`.
  A story that adds a fixture grows the corpus mid-document, so it printed
  "4320 in the last, 142 × 30" — an equation that does not multiply out. Each
  multiplication now comes from its own capture.
