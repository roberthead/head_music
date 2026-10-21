<!--
metadata:
  created_at:   2026-10-21T11:25:49-07:00
  activated_at: 2026-10-21T11:52:19-07:00
  planned_at:
  finished_at:
  updated_at:   2026-10-21T11:56:05-07:00
-->

# Story: ABC Voices, Meter Changes, and Key Changes

## Summary

AS a developer using HeadMusic

I WANT ABC to write every voice of a flow and to read and write meter and key changes after the opening

SO THAT a chorale, or a piece that changes meter or key, survives an ABC round trip, fermatas and common- and cut-time symbols included

Split from [Timeline Expressions](../done/timeline-expressions.md), whose criteria for fermatas in every voice and for symbol-only meter changes exclude ABC.

## Background

- The ABC reader reads `V:` voices, but `RenderPreflight#ensure_single_voice` raises "multi-voice ABC output is not supported".
- A meter or key change after the opening raises both ways. The reader treats a body `M:` or `K:` line, or an inline `[M:3/4]` or `[K:D]`, as an unsupported feature. The writer refuses every entry in `flow.meter_changes` and `flow.key_signature_changes`, so neither `[M:3/4]` nor a symbol-only `[M:C|]` can be written.
- A transposed part that changes instrument is refused for the same reason: it needs a second `K:` field.
- Until this story lands, a timeline fermata is written as a mark in ABC's one voice only, and a change of meter symbol alone cannot be written.
- The reader gives each `V:` id its own part and voice, with the id as the voice's role, and ignores the rest of the line (`clef=`, `nm=`).
- No ABC tool is installed yet. LilyPond is the only outside check the specs use today.

## Acceptance Criteria

- [ ] The writer writes each voice under its own `V:` field, its id taken from the voice's role, with the parts' dynamics in the voice that sounds them
- [ ] The writer interleaves the voices by line, switching voice on each line of bars, as a score is laid out in systems
- [ ] A timeline fermata is written as `!fermata!` on each voice event sounding when it begins, in every voice
- [ ] The reader reads a body `M:` line and an inline `[M:…]` field, including `M:C` and `M:C|`, as a meter change at the bar where it appears
- [ ] The reader reads a body `K:` line and an inline `[K:…]` field as a key signature change at the bar where it appears
- [ ] A meter or key field in any one voice changes the flow's meter or key at that bar, even when the other voices do not repeat it
- [ ] The writer writes each meter change, including one that changes only the symbol, and each key change, in every voice, and they read back the same
- [ ] A meter or key change that does not fall on a barline in every voice raises instead of being dropped
- [ ] A transposed part that changes instrument is written with a `[K:…]` field in that part's voices, instead of raising
- [ ] `TimelineExpressionFixtures.chorale` round-trips through ABC, as does a fixture with meter and key changes in more than one voice
- [ ] Oracle specs render the multi-voice, meter-change, and key-change output with abcm2ps and fail on any warning it prints, skipping with setup instructions (`brew install abcm2ps`) when it is missing

## Notes

- Multi-voice ABC needs a policy for voices that disagree on where a bar line falls. A flow's bars are shared, so this should not happen, but the writer should check it.
- The reader is lenient on purpose: many tunes write `M:` or `K:` in the first voice only, and ABC tools differ on whether such a field reaches the other voices. The writer is strict on purpose, putting the field in every voice so that no tool has to guess.
- The `[K:…]` for an instrument change goes in that part's voices only, so it does not read back as a key change of the flow. Transposed output is not expected to round-trip.
- Voice names and clefs (`nm=`, `clef=`) stay out of scope until the reader reads them.

## Implementation Plan

[to be filled in by /stories plan]
