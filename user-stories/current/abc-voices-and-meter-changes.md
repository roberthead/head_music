<!--
metadata:
  created_at:   2026-10-21T11:25:49-07:00
  activated_at: 2026-10-21T11:52:19-07:00
  planned_at:
  finished_at:
  updated_at:   2026-10-21T11:52:19-07:00
-->

# Story: ABC Voices and Meter Changes

## Summary

AS a developer using HeadMusic

I WANT ABC to write every voice of a flow and to read and write meter changes after the opening

SO THAT a chorale or a piece that changes meter survives an ABC round trip, fermatas and common- and cut-time symbols included

Split from [Timeline Expressions](../done/timeline-expressions.md), whose criteria for fermatas in every voice and for symbol-only meter changes exclude ABC.

## Background

- The ABC reader reads `V:` voices, but `RenderPreflight#ensure_single_voice` raises "multi-voice ABC output is not supported".
- A meter change after the opening raises both ways. The reader treats a body `M:` line or an inline `[M:3/4]` as an unsupported feature. The writer refuses every entry in `flow.meter_changes`, so neither `[M:3/4]` nor a symbol-only `[M:C|]` can be written.
- Until this story lands, a timeline fermata is written as a mark in ABC's one voice only, and a change of meter symbol alone cannot be written.

## Acceptance Criteria

- [ ] The writer writes each voice under its own `V:` field, with the parts' dynamics in the voice that sounds them
- [ ] A timeline fermata is written as `!fermata!` on each voice event sounding when it begins, in every voice
- [ ] The reader reads a body `M:` line and an inline `[M:…]` field, including `M:C` and `M:C|`, as a meter change at the bar where it appears
- [ ] The writer writes each meter change, including one that changes only the symbol, and it reads back the same
- [ ] A meter change that does not fall on a barline in every voice raises instead of being dropped
- [ ] `TimelineExpressionFixtures.chorale` round-trips through ABC

## Notes

- Multi-voice ABC needs a policy for voices that disagree on where a bar line falls. A flow's bars are shared, so this should not happen, but the writer should check it.

## Implementation Plan

[to be filled in by /stories plan]
