<!--
metadata:
  created_at:   2026-09-24T18:58:30-07:00
  activated_at: 2026-09-24T19:27:11-07:00
  planned_at:
  finished_at:
  updated_at:   2026-09-24T19:27:11-07:00
-->

# Story: Humdrum **kern Import and Export

## Summary

AS a developer or researcher using HeadMusic

I WANT to read and write Humdrum `**kern` files as `HeadMusic::Content::Flow`s

SO THAT I can analyze the large scholarly corpora encoded in kern — the Bach chorales, Josquin, Palestrina, and the KernScores library — with the gem's analysis and style guides

## Background

[Humdrum](https://www.humdrum.org/) is a text-based representation for computational musicology. A `**kern` file lays voices out in tab-separated spines, one column per voice, one row per time slice. Each token combines a duration and a pitch (`4cc#` is a quarter C♯5; `8.GG` a dotted eighth G2). Interpretation records (`*k[f#]`, `*M3/4`, `*clefG2`) carry key, meter, and clef, and `=` rows mark barlines.

Kern is the most widely used format for the repertoire the Style guides grade. Reading it gives the counterpoint work real corpora to measure against, such as the Palestrina validation set that [Sixteenth-Century Style](sixteenth-century-style.md) needs. Writing it lets the gem's output flow into the Humdrum toolkit and Verovio.

This story follows the entry-point shape of ABC and LilyPond: `HeadMusic::Notation::Humdrum.parse` and `.render`, with a `Flow#to_kern` delegate.

## Example

```ruby
kern = <<~KERN
  **kern	**kern
  *M4/4	*M4/4
  *k[]	*k[]
  =1	=1
  2C	2e
  2G	2d
  =2	=2
  1C	1c
  ==	==
  *-	*-
KERN

flow = HeadMusic::Notation::Humdrum.parse(kern)
flow.voices.length # => 2
flow.to_kern       # => the same spines back
```

## Acceptance Criteria

- [ ] `HeadMusic::Notation::Humdrum.parse(string)` returns a `HeadMusic::Content::Flow`
- [ ] `HeadMusic::Notation::Humdrum.render(flow)` and `Flow#to_kern` return a `**kern` string
- [ ] Each `**kern` spine becomes a voice; non-kern spines (`**dynam`, `**text`, `**harm`) are skipped on import, except `**text` / `**silbe` lyrics if planning keeps them in scope
- [ ] Pitch tokens (letter case and repetition for register, `#`/`-`/`n` accidentals) map to the right pitches both ways
- [ ] Duration tokens, including dots, map to rhythmic values both ways
- [ ] Rests (`r`), chords (space-separated tokens in one cell), and ties (`[`, `_`, `]`) map both ways
- [ ] `*k[...]`, `*M`, and `*MM` tempo interpretations map to the flow's timeline, including mid-piece changes
- [ ] Barline rows (`=N`) establish bar numbers; a bar whose durations do not add up raises `ParseError`
- [ ] Reference records (`!!!COM`, `!!!OTL`) map to composer and title
- [ ] Spine splits and joins (`*^`, `*v`) are read, or raise `UnsupportedFeatureError` if deferred
- [ ] Every flow rendered by the writer parses back to an equal flow (round trip)
- [ ] At least one Bach chorale from the public KernScores corpus parses end to end
- [ ] Maintains 90%+ test coverage

## Notes

- Kern prints spines lowest voice first (the bass is the leftmost column). Import and export should both respect that order.
- Tuplets in kern are expressed as non-power-of-two durations (`6` is a triplet eighth); decide whether the model can hold them or whether they raise.
- Grace notes (`q`), ornaments, articulations, beams (`L`, `J`), and stem directions can be ignored on import and omitted on export in v1.

## Open Questions

1. Should the entry module be `Humdrum` (leaving room for `**mens` and other representations) or `Kern`?
2. Should import produce a `Project` with one player per spine when the file carries instrument interpretations (`*I"Soprano`)?

## Implementation Plan

[to be filled in by /stories plan]
