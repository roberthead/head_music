<!--
metadata:
  created_at:   2026-09-27T15:48:57-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-10-13T21:39:33-07:00
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

- Builds on [Place Dynamics Where No Note Starts](../done/place-dynamics-where-no-note-starts.md), whose mechanisms place a mark at any position in each format; hairpin starts and ends should go through them:
  - `PreflightChecks#ensure_timed_marks_within_music` and its `timed_marks` list refuse a mark outside the written bars. A hairpin ending exactly where the music ends must be allowed, though a level there is refused.
  - ABC `PositionMarks` puts a mark on the note that attacks there, on an overlay of invisible rests (`& x2 !<)!x6`) inside a note or rest, or on a trailing `x` after the music.
  - LilyPond `TimedMarks` puts a mark on the link that attacks there, `\after D` inside a link, or a trailing spacer after the music. `\after` at the very end of the music prints "programming error: no broken bound", `lily_pond/duration_reader.rb` refuses a zero-length `s1*0`, and `\after` inside `\new Dynamics` still raises a `ParseError`.
  - kern's null-row grid, its `ryy` fill after the music (`WrittenBars#dynamic_after_music?`), and the pickup's leading rest (`WrittenBars#pickup_onset`) look only at dynamic events, and must count hairpin ends.
  - ABC and kern refuse different levels at one position (`ensure_one_level_per_position`); a hairpin mark beside a level on one line needs its own rule.
- Confirm with a Humdrum tool that kern accepts a level and a hairpin mark joined in one token.
- Part hairpins must not add bars to `Flow#latest_bar_number` or a writer's bar numbering.
- `SpanKind` already reads a `positions` anchor, so the hairpin kinds are catalog rows. Think in document order, not musical time, wherever a hairpin's ends share a tied or split note, or sit in different voices of a part: every bug the slurs review found was there. A random round-trip generator over tied notes found what the fixtures missed.

## Implementation Plan

[to be filled in by /stories plan]
