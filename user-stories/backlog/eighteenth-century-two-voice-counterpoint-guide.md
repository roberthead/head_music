<!--
metadata:
  created_at:   2026-11-15T19:12:18-05:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-11-24T15:36:48-08:00
-->

# Story: Eighteenth-Century Two-Voice Counterpoint Guide

## Summary

AS a consumer of the gem grading Bach-style two-voice writing (BardTheory's invention units, 11 and 13)
I WANT a guide for eighteenth-century free counterpoint
SO THAT tonal two-voice writing is judged by its own rules (implied harmony, accented dissonance, the authentic cadence) instead of species rules it routinely breaks

## Acceptance Criteria

- A registered composite guide, `eighteenth_century_two_voice_counterpoint` (name to settle in planning), of a melody guide and a harmony guide
- Rhythm: eighteenth-century values, including sixteenths, dotted rhythms, and ties, judged against the meter
- Dissonance: the accented figures are allowed and recognized (appoggiatura, accented passing tone, suspension and retardation) along with the unaccented ones (passing tone, neighbor tone, escape tone, anticipation). A strong-beat dissonance is not a fault in itself; one that is no recognized figure is
- Cadence: the authentic cadence, with the dominant in root position (5→1 in the bass) under 2→1 or 7→1, through the cadence guideline from [free-species-guide](../current/free-species-guide.md) configured with `forms: [:authentic]`
- Implied harmony: the two voices imply a sensible progression. Planning decides how much of this the gem can check (see Open Questions)
- Display names and instructions in every locale (en, en_GB, de, es, fr, it, ru)
- Specs grade passages from Bach's two-part inventions cleanly, read from kern or MusicXML fixtures through the gem's own readers
- CHANGELOG entry under Unreleased

## Notes

Split from the free species story during its pre-planning (2026-11-15), when that story settled on species technique. It builds on that story's shared changes: metric strength from the meter, "either voice can explain a dissonance," and the configurable cadence guideline.

### Sources

- Kennan, *Counterpoint: Based on Eighteenth-Century Practice*, 3rd ed. (full text on archive.org as `KentKennanCounterpoint`): "Principles of Two-Voice Counterpoint," cadences pp. 27-28: "in authentic cadences the dominant chord is always employed in root position."
- Candidates from `~/Documents/_music-study/counterpoint/counterpoint-sources.txt`: Gauldin, *A Practical Approach to Eighteenth-Century Counterpoint*; Benjamin, *The Craft of Tonal Counterpoint*.

### Figures already settled

- `DissonanceFigures#escape_tone?` exists (see [escape-tone-recognition](../done/escape-tone-recognition.md)). It reads shape and the consonance either side; this guide decides that the escape tone is not on a strong beat, and whether the line that follows it needs a rule. The species guides set none.
- The double neighbor takes precedence over the escape tone. Salzer & Schachter hear a double neighbor that turns back (C–D–B–C–B) as a stepwise line "embellished by échappées", but in this guide it is still a double neighbor with a secondary mark for its continuation, not two escape tones (see [cambiata-and-double-neighbor-fifth-note](../current/cambiata-and-double-neighbor-fifth-note.md)).
- The figure predicates read through a rest. Decide whether a rest breaks a figure before this guide calls them.

### Open questions

- How much implied harmony can be checked without Roman-numeral analysis, which the gem does not model? `Analysis::Sonority` names a two-note dyad only loosely.
- Which non-chord tones need new detection? Escape tone and anticipation are new; appoggiatura and accented passing tone reverse the species assumption that strong beats are consonant.
- Do the imitation and sequence guides get eighteenth-century versions on this base, or do they become configurable as to which base they extend?

## Implementation Plan

[to be filled in by /stories plan]
