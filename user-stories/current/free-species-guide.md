<!--
metadata:
  created_at:   2026-11-15T14:57:30-05:00
  activated_at: 2026-11-15T16:00:12-05:00
  planned_at:
  finished_at:
  updated_at:   2026-11-15T19:12:18-05:00
-->

# Story: Free Species Guide

## Summary

AS a consumer of the gem grading a student's two-voice composition (BardTheory's Unit 10 `free-counterpoint-passage` exercise)
I WANT a guide that grades two voices written in species technique with no given cantus firmus
SO THAT a student who composes both lines gets feedback on each line as a melody and on the two together as counterpoint

"Free species": no cantus firmus (no fixed song) is given. The student composes both lines, using the techniques of the species. The name is the gem's own; the guide's instruction text says so, and explains the contrast with a cantus firmus.

## Acceptance Criteria

### The guide

- A registered composite guide, `free_species`, made of a melody guide and a harmony guide, as the species composites are in `HeadMusic::Style::Guide`
- The guide grades either voice of a two-voice flow, and neither voice has to be marked `cantus_firmus?`. Assessing each voice in turn grades the whole passage
- Display names and instructions exist in every locale (en, en_GB, de, es, fr, it, ru). The instruction text says that no cantus firmus is given and both lines are composed
- Nothing disqualifies: every fault lowers the grade, never ends it. Each guideline is placed in a tier (gate, primary, secondary) with a reason, consistent with the tier policy `SpeciesHarmony` documents
- CHANGELOG entry under Unreleased

### Metric strength from the meter (shared change)

- `VoiceContext#downbeat_position?` means the first beat of the bar, read from the meter, not "the cantus firmus attacks here"
- A new `strong_beat_position?` uses `Content::Position#strong?`, so beats 1 and 3 in 4/4 are strong
- `HarmonicContext#motions` is measured between downbeats, not between cantus firmus attacks; `NoParallelPerfectAcrossBarline` finds the next downbeat from the meter
- The guidelines that read beats from the cantus firmus move to the meter: `FloridDissonanceTreatment`, `WeakBeatDissonanceTreatment`, `SecondSpeciesBreak`, `NoParallelPerfectAcrossBarline`, and the suspension rules (`SuspensionTreatment`, `EmbellishedSuspensionTreatment`)
- No species grade changes. A species cantus firmus attacks once per bar, on beat one, so the existing species specs pass unchanged and prove it. A spec that fails here is a finding to report, not a spec to update

### Dissonance

- Strong-beat dissonance must be a prepared suspension that resolves down by step. Weak-beat dissonance must be a passing tone, neighbor tone, nota cambiata, or double neighbor. The existing `DissonanceFigureDetection` is reused, not copied
- **Either voice can explain a dissonance.** A dissonance is properly treated when at least one voice that attacks into it does so as a recognized figure, or when it is a suspension in the held voice. When no voice explains it, every voice that attacked into it is marked, so the fault counts in both voices' grades
- Specs pin: one voice moving against a held note; a suspension (the held voice owns it; the moving voice is not marked); simultaneous dissonant passing tones in both voices (no mark; Salzer & Schachter p. 330 list "dissonant passing tones in both species parts" as a basic situation); a leap into a chord tone against a passing tone in the other voice (no mark); a simultaneous dissonance neither voice explains (both marked)

### Motion

- Two-part craft carries over from `HARMONIC_CORE` and the diminution core: approach perfect consonances by contrary or oblique motion, prefer contrary motion and imperfect consonances, avoid crossing and overlapping, no parallel perfect consonances on downbeats or across the barline
- Parallel perfect consonances are also caught between any two consecutive moments where both voices attack. No species guideline does this today, because a cantus firmus holds still within the bar; in free species both voices can move from beat to beat. A new `NoParallelPerfect` subclass (working name `NoParallelPerfectBetweenAttacks`) covers it

### Rhythm and texture

- Note values are fifth species' (`AllowFifthSpeciesRhythmicValues`), with two differences: a whole note is allowed in any bar, and a `dotted_rhythms:` option (off by default) allows
  - a dotted note wherever the same rhythm written with a tie would pass (a dotted half, or a dotted whole in 3/2)
  - a dotted quarter followed by a single eighth that moves by step to the next note. If that eighth is dissonant, it must be a passing tone or neighbor tone; it is judged at its own position inside the beat
- Each voice may keep one texture as long as it likes; the fifth-species rule that each line mix textures (`MixSpeciesTextures`) does not apply per voice
- A new harmony guideline (working name `IndependentTextures`) marks stretches where both voices share the same texture for more than `maximum_run:` bars, default 2 (Salzer & Schachter's figure for one line, pp. 101-102). It reuses `MixSpeciesTextures`'s classification of a bar's texture
- A staggered entry (one voice resting while the other begins) is allowed and is not a fault

### Cadence

- Each voice steps into its last note in either direction (`StepToFinalNote` in the melody guide, not `StepUpToFinalNote`), and ends on the tonic
- A new harmony guideline (working name `ClausulaVera`) requires the two-part cadence: the leading tone and the second degree in the next-to-last position, moving to the tonic by contrary step, into an octave or unison. Either voice may carry the leading tone. It is a primary item
- The guideline takes `.with(forms:)`, defaulting to the clausula vera, so the eighteenth-century guide can reuse it with the authentic cadence (5→1 in the bass). This story implements only the clausula vera form; the structure for a second form is specced, not built

### Length

- New `MinimumBars.with(n)` and `MaximumBars.with(n)` guidelines, modeled on `MinimumNotes`/`MaximumNotes`
- The guide takes `bars:` (a number or a range, such as `8..12`) and passes it through. Unset by default, so the guide is neutral about length unless an exercise asks
- Bars are counted from the first entry of either voice to the last note, so a staggered entry does not count as missing bars
- A passage outside the range loses grade in proportion to how far outside it is

### Verification

- Specs grade at least one textbook two-voice passage cleanly (Salzer & Schachter or another species source, cited in the spec), and grade written faults with the expected marks: an unprepared strong-beat dissonance, beat-to-beat parallel fifths, both voices in quarters for three bars, a cadence with both voices stepping the same way

## Notes

### Decisions from pre-planning (2026-11-15)

1. **Metric strength:** read from the meter in the shared contexts, for every guide (not a separate context, not a per-guide strategy). Beat 3 in 4/4 counts as strong, as `Position#strong?` says.
2. **Dissonance ownership:** either voice can explain a dissonance; unexplained ones mark every voice that attacked into it.
3. **Style:** species-derived ("free species"), not eighteenth-century. Eighteenth-century free counterpoint is its own backlog story: [eighteenth-century-two-voice-counterpoint-guide](../backlog/eighteenth-century-two-voice-counterpoint-guide.md).
4. **Dotted rhythms:** an option, off by default, allowing tie-equivalent dots and a dotted quarter plus stepwise eighth.
5. **Cadence:** a dedicated, primary, configurable cadence guideline requiring the clausula vera. Salzer & Schachter require both the leading tone and the second degree in the next-to-last measure of two-part writing (p. 20), and their combined-species chapter defers cadences to that rule (p. 333). The 5→1 bass appears only with a third voice (pp. 33-34). Kennan's eighteenth-century practice puts the dominant in root position, so 5→1 belongs to that guide.
6. **Texture:** moves from each voice to the pair (`IndependentTextures`); whole notes anywhere.
7. **Length:** configurable `bars:`, unset by default.
8. **Name:** "Free Species". Salzer & Schachter's "combined species" means two different species against a cantus firmus in three voices (pp. 330-331), so that name would mislead.

### Scope

- Two voices only. Three- and four-voice counterpoint (BardTheory Units 12 and 14) needs every pair of voices checked and is a separate change to the harmony context.
- No imitation or sequence: [free-species-with-imitation-guide](../backlog/free-species-with-imitation-guide.md) and [free-species-with-sequence-guide](../backlog/free-species-with-sequence-guide.md) build on this guide.
- BardTheory can't place a note inside a beat yet, so students can't use the dotted-quarter-and-eighth rhythm until its editor supports subdivisions. The gem supports it regardless.

### Sources

- Salzer & Schachter, *Counterpoint in Composition* (scan on disk): two-part cadence p. 20; three-part cadence pp. 33-34; fifth-species texture pp. 101-102; combined species pp. 330-333.
- Kennan, *Counterpoint*, 3rd ed., "Principles of Two-Voice Counterpoint," pp. 27-28: the contrast case for the cadence.
- `references/fifth-species-counterpoint.md`: cross-source comparison of florid dissonance treatment.

### Downstream

BardTheory's backlog story `unit-10-composition-exercises` waits on this guide and needs it released to RubyGems.

## Implementation Plan

[to be filled in by /stories plan]
