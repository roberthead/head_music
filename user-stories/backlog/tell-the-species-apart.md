<!--
metadata:
  created_at:   2026-08-20T09:34:46-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-08-22T18:13:53-07:00
-->

# Tell the Species Apart

AS a student submitting a species harmony exercise

I WANT the guide to notice that what I submitted is not the species it teaches

SO THAT a first-species line handed to a third-species guide is told so, rather
than earning a perfect grade for breaking none of the rules it had no
opportunity to break

Split out of [Extract the Harmonic Cores](extract-the-harmonic-cores.md), which
found this defect while measuring and established that re-tiering cannot fix it.

## The defect

Measured on the `story/extract-the-harmonic-cores` branch, before any change:

- A valid Fux first-species line scores **1.000** against `ThirdSpeciesHarmony`.
  Every rubric item is adherent, including `ThirdSpeciesDissonanceTreatment`,
  which returns 1.0 because a first-species line has no dissonances to treat.
- Across all 26 Fux first-species voices, the seven harmony guides span
  **0.973–0.982** — effectively indistinguishable — and `third_species_harmony`
  (0.978) grades the line *higher* than `first_species_harmony` (0.976).

This is not a weighting problem. A rubric whose items are all 1.0 grades 1.0
under any tiering, so the harmonic-core demotion cannot touch it.

## Why first species is the only detectable one

`FirstSpeciesHarmony` declares `OneToOne`. A constructed third-species line
scores 0.847 against it, with `OneToOne` firing at 0.0 — the guide can say "this
is not first species."

The diminution harmony guides declare no rhythmic counterpart. Second, third,
triple-meter, fourth, and fifth species harmony have nothing that fails when the
submitted rhythm is not theirs, so they reject nothing.

The species-identifying rhythm rules that do exist — `TwoPerBar`,
`FirstBarHalfNotes`, `AllowedRhythmicValuesForFifthSpecies` and their kin — live
on the melody side. That may be the right home. If so, the question becomes
whether a harmony guide should identify species at all, or whether `OneToOne` is
the odd one out and belongs with them.

This is the "no fault found vs. nothing to find fault in" confusion the
re-tiering story named as an epic-level theme. It has a melodic twin already on
record there: `FourthSpeciesMelody` cannot distinguish fourth species from
first, because `OneToOneWithTies` is adherent on a first-species line.

## The floor: a wrong answer cannot score worse than its own mark

Added by [Extract the Harmonic Cores](../current/extract-the-harmonic-cores.md),
which hit this while trying to make a failed lesson score badly.

`Contoured` marks a mismatched contour at φ⁻²:

```ruby
def marks
  return if notes.empty? || matches_contour?
  Mark.for_all(notes, fitness: HeadMusic::GOLDEN_RATIO_INVERSE**2)
end
```

`ContourMelody` declares `primary: [Contoured.with(contour)]` and nothing else,
so that one item is the whole primary tier. A trough submitted for an arch scores
**0.618** today. Weighting can only interpolate between the guideline's own
fitness and 1, so even at 100% of the rubric the floor is **0.382**. No tier,
budget, cap, or weight reaches below it.

Two candidate fixes, and they are the same two this story is already weighing:

- **A harsher mark.** A trough is not a near-miss arch, and φ⁻² is the factor for
  a near miss. `Contoured` could mark a total mismatch at 0.
- **A gate.** "You were asked for an arch and wrote a trough" is a precondition,
  not a rubric line — the same sentence as "this is not third species" with
  different nouns. As a gate it gives `0.382 × rubric`.

Whichever answer this story reaches for species identification should be the same
answer here, because it is the same question.

## Questions to settle

- Is species identification a harmonic concern, a melodic one, or a gate?
  A gate is attractive — "is this even third species" is a precondition, not a
  rubric line — but a gate scales the whole grade to near zero, which may be too
  blunt for a student who submitted the wrong species by mistake.
- Should `OneToOne` stay in `FirstSpeciesHarmony`, or move to
  `FirstSpeciesMelody` alongside `OnePerBar`?
- Does a guideline that finds nothing to fault deserve 1.0 at all, or does the
  guide-item vocabulary need a third answer beyond adherent / not adherent?
  Answering this generally would also fix `OneToOneWithTies`.

## Scope

- Add second, third, triple-meter, fourth, and fifth species example fixtures to
  `spec/spec_helper.rb`, alongside the existing cantus firmus and first species
  sets. The corpus has none, which is why
  [Extract the Harmonic Cores](extract-the-harmonic-cores.md) could not measure
  a cross-species comparison at all.
- Extend `bin/guide_grade_corpus.rb` to include them, so every species can be
  graded against every guide.
- Decide the three questions above and implement the chosen answer.
- Fix `FourthSpeciesMelody`'s inability to distinguish fourth species from
  first, or record why it is out of scope.
- Apply the same answer to `Contoured`, so a contour that does not match at all
  is distinguished from one that nearly does.

## Acceptance Criteria

- The corpus contains valid example lines for every species the registry has a
  guide for, and the assessable harmony row count rises above the current 38.
- A cross-species grade matrix — every species fixture against every species
  guide — is captured, with the diagonal expected to be highest.
- A valid first-species line scores materially lower against `ThirdSpeciesHarmony`
  than a valid third-species line does.
- No species guide grades a line of the wrong species higher than a guide of that
  line's own species.
- The decision on where species identification belongs is stated in the guide or
  guideline comments, not only in this story.
- A trough submitted to `arch_contour_melody` scores materially below the 0.618
  it scores today, and a near-miss arch still scores above it.

## Notes

The corpus limit is the first thing to fix and the reason this story is not
small: the measurement that would prove the defect fixed cannot be taken today,
because there is no valid third-species line anywhere in the repository to take
it against.
