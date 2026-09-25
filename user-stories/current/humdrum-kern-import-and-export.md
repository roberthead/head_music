<!--
metadata:
  created_at:   2026-09-24T18:58:30-07:00
  activated_at: 2026-09-24T19:27:11-07:00
  planned_at:
  finished_at:
  updated_at:   2026-09-24T19:36:05-07:00
-->

# Story: Humdrum **kern Import and Export

## Summary

AS a developer or researcher using HeadMusic

I WANT to read and write Humdrum `**kern` files as `HeadMusic::Content::Flow`s

SO THAT I can analyze the large scholarly corpora encoded in kern — the Bach chorales, Josquin, Palestrina, and the KernScores library — with the gem's analysis and style guides

## Background

[Humdrum](https://www.humdrum.org/) is a text-based representation for computational musicology. A `**kern` file lays voices out in tab-separated spines, one column per voice, one row per time slice. Each token combines a duration and a pitch (`4cc#` is a quarter C♯5; `8.GG` a dotted eighth G2). Interpretation records (`*k[f#]`, `*M3/4`, `*clefG2`) carry key, meter, and clef, and `=` rows mark barlines.

Kern is the most widely used format for the repertoire the Style guides grade. Reading it gives the counterpoint work real corpora to measure against, such as the Palestrina validation set that [Sixteenth-Century Style](../backlog/sixteenth-century-style.md) needs. Writing it lets the gem's output flow into the Humdrum toolkit and Verovio.

This story follows the entry-point shape of ABC and LilyPond: `HeadMusic::Notation::Kern.parse` and `.render`, with a `Flow#to_kern` delegate.

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

flow = HeadMusic::Notation::Kern.parse(kern)
flow.voices.length # => 2
flow.to_kern       # => the same spines back
```

## Acceptance Criteria

### First step: players in a standalone flow

- [ ] A part in a flow with no project can carry a `Player` that has no project
- [ ] `Flow#to_h` writes a part's player name when it has one, and `Flow.from_h` restores it as a projectless `Player`; a part with no player serializes as it does now
- [ ] `Project#add_flow` adopts a part's existing player into `project.players` when the project does not own it yet, rather than leaving it orphaned; adopting the same flow twice still changes nothing
- [ ] Two parts in one flow that share a player object still share one player after adoption and after a Flow JSON round trip
- [ ] A project saved and read back keeps adopted players, and layouts can select them
- [ ] Existing schema-4 documents read unchanged

### Kern

- [ ] A spine's display name (`*I"Soprano`) becomes its part's player name on import, and a part's player name is written as `*I"` on export
- [ ] `HeadMusic::Notation::Kern.parse(string)` returns a `HeadMusic::Content::Flow`
- [ ] `HeadMusic::Notation::Kern.render(flow)` and `Flow#to_kern` return a `**kern` string
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
- `Project#to_h` embeds each `flow.to_h` and already pairs parts with players by index. Once a part's hash carries a player name, a project document says the player twice. Planning should decide whether the project writer drops the per-part name or the reader treats the index as the source of truth.
- Grace notes (`q`), ornaments, articulations, beams (`L`, `J`), and stem directions can be ignored on import and omitted on export in v1.

## Decisions

- **The module is `HeadMusic::Notation::Kern`** (decided 2026-09-24). Other Humdrum representations such as `**mens` would get modules of their own if they come.
- **Import returns a `Flow`** (decided 2026-09-24), as ABC and LilyPond import do. Players are project-level chairs that last across flows, and a kern file is one flow. A spine's instrument code (`*Ivox`, `*Ivioln`) maps to its part's `instrument`, and `Project#add_flow` mints players named for those instruments when a caller wants them.
- **A part in a standalone flow may carry a player** (decided 2026-09-24), and that is where a spine's display name (`*I"Soprano`) goes. Until now, readers left `Part#player` nil by convention. A player without a project was possible, but Flow JSON did not save it, and `Project#add_flow` kept it without adding it to `project.players`, so the name was lost either way. Fixing that is this story's first step, ahead of the kern reader. It also opens the way for ABC `V:` names and LilyPond `\new Staff = "..."` names to become players later.

## Open Questions

1. Does the player name belong in the schema as a per-part field of Flow JSON, and does that need a schema version bump, or is an optional field additive within schema 4?

## Implementation Plan

[to be filled in by /stories plan]
