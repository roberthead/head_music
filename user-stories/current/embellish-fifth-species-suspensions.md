<!--
metadata:
  created_at:   2026-09-18T17:00:05-07:00
  activated_at: 2026-09-19T08:36:41-07:00
  planned_at:
  finished_at:
  updated_at:   2026-09-20T13:20:04-07:00
-->

# Embellish Fifth Species Suspensions

AS a student submitting a florid counterpoint exercise

I WANT a suspension whose resolution is delayed or decorated the way Fux
allows to be graded as a suspension, not as a fault

SO THAT Fux's own fifth-species example grades higher on the fifth-species
composite than a fourth-species line does

Found by [Require the Species Rhythm](../done/require-the-species-rhythm.md)
when Fux's chapter five figure 82 became a fixture.

## The defect

`SuspensionTreatment` accepts one shape: the held note resolves down by step
to a consonance as its very next note. Fifth species relaxes that.
`references/fifth-species-counterpoint.md` section 3.4.5 lists five
embellishments, and the reference's own guideline map proposes an
`EmbellishedSuspensionTreatment` to cover them:

1. Anticipated resolution on beat 2, repeated on beat 3.
2. Anticipated resolution decorated with an eighth-note lower neighbor.
3. Escape tone: a consonant step up on beat 2, then the resolution.
4. A consonant leap on beat 2, then the resolution.
5. Delayed resolution: one intervening consonance, then the resolution (Fux).

Fux figure 82, bar 9, is type 5: E5 held over F4 (a seventh), then A4 (a
consonant third), then D5 (the resolution) on beat 3. `SuspensionTreatment`
marks it. Bar 8 (F5 over G4, resolved to E5 then decorated E5 D5 E5) passes,
because the first note after the suspension is the resolution.

Measured on the story branch:

| Voice | fifth_species_melody | fifth_species_harmony | fifth_species |
| --- | --- | --- | --- |
| Fux figure 82 (fifth species) | 0.970 | 0.819 | 0.891 |
| Fux figure 73 (fourth species) | 0.881 | 0.981 | 0.929 |

The melody diagonal holds. The composite diagonal fails only because of the
harmony side, and `spec/head_music/style/guide_species_diagonal_spec.rb`
carries that one cell as pending with this story named in the reason.

Other marks on figure 82's harmony are secondary and arguably Fux's own
choices rather than gaps: `AvoidCrossingVoices` (bar 2 dips below the
cantus), `PreferContraryMotion` (seven marks on a florid line), and
`StartOnPerfectConsonance`, which treats the counterpoint as the bass voice
because its lowest note ties the cantus firmus's lowest note. Worth a look
while here, but the suspension is the one that moves the grade.

## Decisions

- **A separate guideline, not a configured `SuspensionTreatment`.** Decided
  2026-09-20. `EmbellishedSuspensionTreatment`, the name the reference
  proposes, is declared by `FifthSpeciesHarmony` in place of
  `SuspensionTreatment`. Fourth species keeps the strict rule untouched:
  it has no room for an intervening note, so a leap between suspension and
  resolution there is a genuine fault.

## Questions to settle

- Does the delayed resolution require the intervening note to be a quarter,
  so the resolution still lands on beat 3, as Girton insists?

## Acceptance Criteria

- Fux figure 82 is adherent on the fifth-species suspension guideline.
- Fux figure 82 grades at least as high on `fifth_species` as any fixture of
  another species, and the pending example in the diagonal spec is removed.
- A fourth-species line with a leap between suspension and resolution is
  still marked by `FourthSpeciesHarmony`.

## Implementation Plan

[to be filled in by /stories plan]
