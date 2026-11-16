<!--
metadata:
  created_at:   2026-11-15T21:09:48-05:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-11-15T21:09:48-05:00
-->

# Story: Fifth Species Grades Published Examples Highly

## Summary

AS a consumer of the gem grading fifth-species and free-species counterpoint
I WANT the correct published examples, in Fux and elsewhere, to score highly under the fifth species melody and harmony guides
SO THAT a student who writes the way the textbooks do isn't marked down for it

## Acceptance Criteria

- Every correct published fifth-species example in the fixtures scores highly under `fifth_species_melody` and `fifth_species_harmony`, graded on the counterpoint voice. High, not necessarily perfect: a mark that a source shows to be the author's liberty may stay
- The corpus holds fifth-species examples from beyond Fux: at least Salzer & Schachter, and others where a transcription is available (Jeppesen, Clendinning, Davis and Lybbert, Kennan)
- Each mark on a published example is investigated and settled one of three ways, with its source:
  - the guideline is over-applied, and it is changed, citing a non-Fux source for the rule as changed
  - the fixture is wrong (an octave or pitch error in the transcription), and it is fixed against the scan or the edition
  - the author takes a liberty, and the mark is pinned and the example excluded by name with the reason, on the pattern of `guide_species_diagonal_spec.rb`'s liberties
- A spec pins the floor: the lowest grade the correct examples reach under each guide, with named exclusions, never by loosening the comparison
- Grade changes to other species are reported, and each is justified or avoided
- CHANGELOG entry under Unreleased for any changed guideline

## Notes

Found while reviewing the plan for [free-species-guide](../current/free-species-guide.md) (2026-11-15). Free species inherits the fifth-species craft, so anything fixed here improves free species grading too. Free species can start first: its corpus spec asserts only its own new guidelines.

### Marks on Fux's counterpoint voices under `fifth_species` (2026-11-15)

| Guideline | Figures | First read |
|---|---|---|
| `ApproachPerfectionContrarily` | 82, 85b, 86a, 86b | Likely over-applied: it compares downbeat to downbeat even with notes in between, so a "hidden fifth" can span four quarters |
| `NoParallelPerfectOnDownbeats` | 85b, 86a | Same suspicion: in 86a it pairs downbeats with a held note and a moving line between them |
| `NoParallelPerfectAcrossBarline` | 86a | Check alongside the two above |
| `StepOutOfUnison` | 82, 84a, 85a, 86a | Unclear: may not allow for a unison reached in passing within a florid bar |
| `AvoidCrossingVoices`, `AvoidOverlappingVoices` | 82, 84a, 85a | Fux's liberty or a transcription octave error |
| `StartOnPerfectConsonance` | 82 | Check the fixture and the bass-voice tonic rule |
| `EmbellishedSuspensionTreatment` | 85b | Already a named liberty in `guide_species_diagonal_spec.rb` |
| `ConsonantClimax`, `AlwaysMove`, `PreferLongBeforeShort` | 84a, 85b, 87, 88a | Preferences; probably liberties |

The free species guide moves downbeats onto the meter (its step 1). The downbeat-to-downbeat rules above read that context, so this story is easier after free species lands.

### Principle

Fux is evidence, not an oracle. A mark on a Fux line is a finding to investigate. Changing a rule needs a non-Fux source; otherwise the mark is pinned and the example excluded by name.

### Sources

- `references/fifth-species-counterpoint.md`: cross-source comparison of florid practice
- Salzer & Schachter, *Counterpoint in Composition* (scan on disk): fifth species, pp. 101ff.

## Implementation Plan

[to be filled in by /stories plan]
