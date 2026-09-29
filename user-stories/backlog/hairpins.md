<!--
metadata:
  created_at:   2026-09-27T15:48:57-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-09-27T15:48:57-07:00
-->

# Story: Hairpins

## Summary

AS a developer or researcher using HeadMusic

I WANT voices and parts to hold crescendo and diminuendo hairpins

SO THAT dynamic shape survives import alongside the levels it runs between

Split from [Spans Across Notes](../done/spans-across-notes.md), whose span model this story extends.

## Background

| Concept | ABC | LilyPond | MusicXML | kern |
|---|---|---|---|---|
| Crescendo, diminuendo | `!<(!` … `!<)!`, `!crescendo(!` … | `\<` … `\!`, `\>` | `<wedge>` | `<`, `>`, `(`, `)`, `[`, `]` in `**dynam` |

- ABC's `DecorationMapper` and LilyPond's `MarkReader` recognize hairpins and drop them, in a voice and inside `\new Dynamics`.
- kern's `DynamicReader` strips hairpin marks and reads the level left in the token, so `p<` reads as *p*.
- Hairpins live on a voice or a part, as dynamic levels do: on a voice when written beside its notes (ABC, MusicXML), on the part when written in a shared line (LilyPond `\new Dynamics`, kern `**dynam`).

## Acceptance Criteria

- [ ] `Part#add_span` holds hairpins; a part hairpin may start and end at any position, as a `DynamicEvent` may
- [ ] Decide whether a voice hairpin's ends sit on voice events (rests allowed) or at any position
- [ ] `spans_at` includes the part's hairpins; a hairpin ends at a position rather than covering a note, so where a crescendo ends and a diminuendo begins, only the diminuendo is in force
- [ ] An overlap policy for hairpins, decided and pinned
- [ ] ABC reads and writes hairpin start and end marks through `DecorationMapper`
- [ ] LilyPond reads and writes `\<`, `\>`, and `\!` in voices and in `\new Dynamics` (`PartDynamics`, and the spacer grid in `RenderPlan#dynamics_bar`)
- [ ] kern reads and writes hairpin marks in `**dynam`, joined with a level on one row (`p<`) so no mark is lost, and times them with `DynamicPlacer`'s even split and `DataRows`' null-row grid; accents still outrank levels
- [ ] MusicXML writes `<wedge>` through `DirectionWriter`, and `Divisions` counts hairpin ends
- [ ] Round trips assert where each hairpin starts and ends

## Notes

- Depends on [Place Dynamics Where No Note Starts](place-dynamics-where-no-note-starts.md) for ABC hairpin ends in the middle of a note.
- Confirm with a Humdrum tool that kern accepts a level and a hairpin mark joined in one token.
- Part hairpins must not add bars to `Flow#latest_bar_number` or a writer's bar numbering.

## Implementation Plan

[to be filled in by /stories plan]
