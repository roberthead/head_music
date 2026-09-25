<!--
metadata:
  created_at:   2026-09-25T14:05:54-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-09-25T14:05:54-07:00
-->

# Story: Bar Markings: Barline Styles, Rehearsal Marks, and Navigation

## Summary

AS a developer using HeadMusic

I WANT bars to carry their barline style, rehearsal marks, and navigation instructions such as segno, coda, D.C., and Fine

SO THAT a score's structure survives import, and the gem can tell what order the bars are played in

## Background

`Bar` holds repeat structure and nothing else: `starts_repeat`, `ends_repeat_after_num_plays`, and `plays_on_passes` for 1st and 2nd endings. The formats say more about a bar:

| Concept | ABC | LilyPond | MusicXML | kern | MEI |
|---|---|---|---|---|---|
| Double and final barlines | `\|\|`, `\|]` | `\bar "\|\|"`, `\bar "\|."` | `<bar-style>` | `\|\|`, `==` | `@right` |
| Rehearsal marks and section labels | `P:A` | `\mark \default` | `<rehearsal>` | `*>A` | `<reh>` |
| Segno, coda, D.C., D.S., Fine | `!segno!`, `!coda!`, `!D.C.!`, `!fine!` | `\segnoMark`, `\codaMark`, text | `<segno>`, `<coda>`, `<sound dacapo>` | text | `<dir>`, `@type` |

Kern already reads section labels and expansion lists (`*>A`, `*>[A,A,B]`) and ignores them, and every writer puts a final barline only at the very end. A double bar before a new section, a rehearsal letter, or a D.C. al Fine are lost on the way through.

## Example

```ruby
flow.bars(8).last.barline = :double
flow.bars(9).last.rehearsal_mark = "B"
flow.bars(9).last.segno = true
flow.bars(16).last.jump = HeadMusic::Content::Jump.new(:dal_segno, to: :fine)
flow.bars(12).last.fine = true

flow.performance_order # => [1, 2, ..., 16, 9, 10, 11, 12]
```

## Acceptance Criteria

### Model

- [ ] A bar's closing barline can be regular, double, final, or dashed; regular is the default and is not serialized
- [ ] A bar can carry a rehearsal mark: a letter, a number, or free text such as "Verse"
- [ ] A bar can carry a segno or coda sign, a Fine, a "To Coda", and a jump (D.C. or D.S., al Fine or al Coda)
- [ ] `Flow#performance_order` lists the bars in the order they are played, unfolding repeats, 1st and 2nd endings, and jumps; a jump to a sign that does not exist raises `ArgumentError`
- [ ] Repeat structure and navigation that cannot be followed (a jump with no end) raise rather than loop

### Serialization and formats

- [ ] Flow JSON writes the new bar fields sparsely, within schema 4; existing schema-4 documents read unchanged
- [ ] ABC reads and writes double and final barlines, `P:` sections, and the navigation decorations
- [ ] LilyPond reads and writes `\bar` styles and `\mark`, and writes segno and coda marks
- [ ] MusicXML writes `<bar-style>`, `<rehearsal>`, `<segno>`, `<coda>`, and the `<sound>` attributes for jumps
- [ ] kern reads and writes `||` and section labels (`*>A`), and writes `==` only at the end
- [ ] A flow with a D.S. al Coda round-trips through each format that can express it
- [ ] Maintains 90%+ test coverage

## Notes

- This is also the natural home for the repeat writing the 2026-09-25 inventory found missing: ABC, LilyPond, and MusicXML writers drop repeats and endings today. If this story grows too large, split repeat writing into a story of its own.
- `performance_order` gives MIDI export (backlog) and the `Conductor` a way to play a flow as written, not as printed.
- Kern expansion lists (`*>[A,A,B]`) describe a performance order directly. Reading them could check `performance_order`.

## Open Questions

1. Are rehearsal marks per flow (one row of letters over the score) or per part? MusicXML repeats them in every part, but they mean one thing.
2. Should `performance_order` answer bar numbers, or bar objects with the pass number, so a caller can tell the first and second playing apart?

## Implementation Plan

[to be filled in by /stories plan]
