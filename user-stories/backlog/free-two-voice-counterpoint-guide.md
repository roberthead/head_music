<!--
metadata:
  created_at:   2026-11-15T14:57:30-05:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-11-15T14:57:30-05:00
-->

# Story: Free Two-Voice Counterpoint Guide

## Summary

AS a consumer of the gem grading a student's two-voice composition (BardTheory's Unit 10 `free-counterpoint-passage` exercise)
I WANT a guide that grades two freely composed voices, with no given cantus firmus and no declared species
SO THAT a student who writes both voices gets feedback on each line as a melody and on the two lines together as counterpoint

## Acceptance Criteria

- A registered composite guide, `free_two_voice_counterpoint`, made of a melody guide and a harmony guide, as the species composites are in `HeadMusic::Style::Guide`
- The guide grades either voice of a two-voice flow, and neither voice has to be marked `cantus_firmus?`. Assessing each voice in turn grades the whole passage
- Strong and weak beats come from the meter (`Content::Position#strong?`), not from where the other voice attacks. Today `VoiceContext#downbeat_position?` treats every cantus firmus attack as a downbeat, which is wrong when both voices move
- Dissonance treatment is judged from the rhythm: a dissonance on a strong beat must be a prepared suspension that resolves down by step; a dissonance on a weak beat must be a passing tone, neighbor tone, nota cambiata, or double neighbor. The existing figure detection (`DissonanceFigureDetection`) is reused, not copied
- A dissonance is judged in the voice that makes it. When both voices attack together into a dissonance, the guide decides which voice is at fault and the specs pin that decision (see Open Questions)
- Two-part craft carries over: approach perfect consonances by contrary or oblique motion, no parallel perfect consonances (on any beat and across the barline), prefer imperfect consonances, avoid crossing and overlapping, end on a perfect consonance with a proper cadence
- Rhythm is free within fifth-species note values or a deliberately chosen wider set. A staggered entry (one voice resting while the other begins) is allowed and is not a fault
- Each guideline is placed in a tier (gate, primary, secondary) with a reason, consistent with the tier policy `SpeciesHarmony` documents, and nothing disqualifies: faults lower the grade, never end it
- Display names and instructions exist in every locale (en, en_GB, de, es, fr, it, ru)
- Specs grade at least one textbook free-counterpoint example cleanly, and grade worked student-style faults (an unprepared strong-beat dissonance, parallel fifths across a barline) with the expected marks
- CHANGELOG entry under Unreleased

## Notes

### Why the species guides don't fit

Every harmony guideline measures one voice against a single `cantus_firmus` (`Style::Guideline::HarmonicContext#interval_with_cantus`, and `VoiceContext#cantus_firmus` falls back to `other_voices.first`). For two voices the fallback is good enough: each voice's "cantus firmus" is simply the other voice. What breaks is the assumption that the other voice holds whole notes, so that its attacks mark the downbeats. `FloridDissonanceTreatment#properly_treated?` and `downbeat_position?` both depend on it. Free counterpoint needs metric position from the meter instead.

That change could move into `HarmonicContext`/`VoiceContext` for every guide (in a cantus-firmus exercise, cantus firmus attacks and strong beats are the same), or stay limited to the new guidelines. Decide during planning. If the species guides switch to meter-based beats, their specs must show no change in grading.

### Scope

- Two voices only. Three- and four-voice counterpoint (BardTheory Units 12 and 14) needs every pair of voices checked and is a separate, larger change to the harmony context.
- No imitation. That is [two-voice-counterpoint-with-imitation-guide](two-voice-counterpoint-with-imitation-guide.md), which builds on this guide.

### Sources

Base the rules on free-counterpoint pedagogy, not on Fux alone (Fux is evidence, not the authority). Candidates: Salzer & Schachter's chapters on combining species, Kennan's *Counterpoint* (eighteenth-century practice), Jeppesen. `references/fifth-species-counterpoint.md` already compares sources on florid dissonance treatment and is the starting point.

### Open questions

- When both voices attack together into a dissonance, which voice is at fault? The voice that moved by leap, the upper voice, or both?
- Which note values are allowed? Is fifth species' set enough, or does free counterpoint need eighth-note pairs and dotted rhythms from the start?
- How long a passage does the gate require? BardTheory's exercise asks for 8–12 bars.
- Does the melody half reuse `SpeciesMelody`'s moving-species craft or get a lighter core? Rules like `AlwaysMove` and `StepUpToFinalNote` may not apply to the lower voice of a free passage.

### Downstream

BardTheory's backlog story `unit-10-composition-exercises` waits on this guide and needs it released to RubyGems.

## Implementation Plan

[to be filled in by /stories plan]
