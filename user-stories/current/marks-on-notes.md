<!--
metadata:
  created_at:   2026-09-25T14:05:57-07:00
  activated_at: 2026-09-25T17:40:58-07:00
  planned_at:
  finished_at:
  updated_at:   2026-09-25T19:33:06-07:00
-->

# Story: Marks on Notes: Articulations, Ornaments, Fermatas, and Dynamics

## Summary

AS a developer or researcher using HeadMusic

I WANT a placement to carry the marks written on it, such as staccato, accent, a trill, a fermata, or a dynamic like *p* or *sfz*

SO THAT the many files that use these marks import instead of failing, and the marks survive a trip through the gem

## Background

These are the most common markings in written music, and every format has them:

| Concept | ABC | LilyPond | MusicXML | kern | MEI |
|---|---|---|---|---|---|
| Staccato, accent, tenuto, marcato | `.C`, `!accent!`, `!tenuto!` | `c-.`, `c->`, `c--`, `c-^` | `<articulations>` | `'`, `^`, `~` | `<artic>` |
| Trill, mordent, turn | `TC`, `MC`, `!turn!` | `\trill`, `\mordent`, `\turn` | `<ornaments>` | `t`, `m`, `S` | `<trill>`, `<mordent>`, `<turn>` |
| Fermata | `HC`, `!fermata!` | `\fermata` | `<fermata>` | `;` | `<fermata>` |
| Dynamic at a point | `!p!`, `!sfz!` | `\p`, `\sfz` | `<dynamics>` | `p` in `**dynam` | `<dynam>` |

The model has none of them. ABC raises on `.` and `!…!` decorations, LilyPond raises on `-.` and `\fermata`, and kern drops them. A folk tune in ABC with one staccato dot, or a LilyPond file with one *f*, cannot be imported.

Fermatas matter to this gem in particular. In the Bach chorales, fermatas mark the ends of phrases, and the kern reader throws them away. Keeping them gives future phrase-aware analysis something real to stand on.

This is the first of five stories from the 2026-09-25 inventory of concepts the model lacks. It comes first because it removes the most import failures for the least design risk, and [Spans Across Notes](../backlog/spans-across-notes.md) builds on its catalog.

## Example

```ruby
placement = voice.place("1:1", :quarter, "C5")
placement.mark(:staccato)
placement.mark(:fermata)
placement.mark(:sfz)
voice.change_dynamic("1:1", :p)
part.change_dynamic("5:1", :f)

placement.marks.map(&:name_key) # => ["staccato", "fermata", "sfz"]
voice.dynamic_at("5:2").name_key # => "f"
placement.marked?(:fermata)     # => true
```

## Acceptance Criteria

### Marks on a placement

- [ ] A catalog of marks is loaded from YAML, as playing techniques are: articulations (staccato, staccatissimo, accent, tenuto, marcato), ornaments (trill, mordent, inverted mordent, turn), the fermata, and the sforzando family (*sf*, *sfz*, *rfz*, *fp*)
- [ ] Each mark has a category and a name through the `Named` mixin, with English names and fallbacks for the other locales
- [ ] A placement can carry any number of marks, each at most once; a rest can carry a fermata but not an articulation, ornament, or sforzando, and adding one raises `ArgumentError`
- [ ] Marks do not change a placement's pitches, rhythmic value, or position, so every existing analysis and style guideline gives the same answers

### Dynamics

- [ ] Dynamics *ppp* through *fff* (and *mp*, *mf*) are events at a position, not marks, and can be written on a voice or on a part
- [ ] A voice dynamic can sit at any position in its voice, including under a held note or a rest
- [ ] A part dynamic applies to every voice of the part, across all its staves, as a piano dynamic between the staves does
- [ ] `Voice#dynamic_at(position)` answers the dynamic in force: the most recent voice or part dynamic at or before the position, whichever was written last; with none written, it answers nil
- [ ] *fp* sets *p* as the dynamic in force after its note; *sf*, *sfz*, and *rfz* leave the dynamic in force unchanged
- [ ] Two dynamics at the same position on the same voice, or on the same part, raise `ArgumentError`

### Serialization

- [ ] Flow JSON writes a placement's marks as a sorted list of keys, voice dynamics on their voice, and part dynamics on their part, all within schema 4 as optional keys; a flow with none serializes as it does now, and existing schema-4 documents read unchanged

### Formats

- [ ] ABC reads and writes the articulation, ornament, fermata, sforzando, and dynamic decorations, in both shorthand (`.`, `H`, `T`) and `!name!` forms; a dynamic decoration becomes a voice dynamic at its note
- [ ] LilyPond reads and writes the articulation shorthands and commands, `\fermata`, the ornaments, and dynamics; a dynamic on a note becomes a voice dynamic, and a `\new Dynamics` context in a piano or staff group becomes part dynamics, which the writer emits back
- [ ] MusicXML writes `<articulations>`, `<ornaments>`, `<fermata>`, and `<dynamics>`, with a voice dynamic tied to its `<voice>` and a part dynamic tied to none
- [ ] kern reads and writes articulations, ornaments, fermatas, and sforzandos in the token, and reads a `**dynam` spine as part dynamics for the part of the nearest `**kern` spine on its left; the writer emits a `**dynam` spine per part that has dynamics
- [ ] Signifiers a format recognizes but the catalog does not hold, such as bowings and breath marks, are still dropped on import, so nothing that imports today starts failing; syntax a reader does not recognize at all still raises `UnsupportedFeatureError`
- [ ] Each format round-trips a flow with a fermata at each phrase end, a staccato run, a trill, an *sfz*, and changing dynamics, comparing the dynamic in force for every voice at every placement
- [ ] A grand-staff piano flow with part dynamics round-trips through LilyPond, MusicXML, and kern
- [ ] The hand-encoded chorale fixture keeps its fermatas on import
- [ ] Maintains 90%+ test coverage

## Notes

- Bowings (up-bow, down-bow), fingering, breath marks, and tremolo are also marks on a note. They are out of scope, but the catalog should be able to hold them later.
- Hairpins are spans and belong to [Spans Across Notes](../backlog/spans-across-notes.md).
- Free-text directions ("dolce", "pizz.", "div.") are out of scope. "pizz." and "arco" overlap with playing techniques, so text directions need a design of their own.

## Decisions

- **Dynamics are events on a voice or a part, not marks on a placement** (decided 2026-09-25). A part dynamic covers a piano dynamic between two staves, or one dynamic for several voices on a staff; a voice dynamic covers a dynamic for one voice, and can sit under a held note or a rest.
- **The most recent dynamic wins** (decided 2026-09-25): whichever voice or part dynamic was written last at or before a position governs the voice there, as a player reads the page.
- **Sforzando-type accents are marks on the note** (decided 2026-09-25): *sf*, *sfz*, and *rfz* affect only their note, and *fp* also sets *p* afterward.
- **All four formats are in scope** (decided 2026-09-25): ABC, LilyPond, MusicXML, and kern.
- **Recognized signifiers outside the catalog keep being dropped** (decided 2026-09-25), so no import that passes today starts failing.
- **Free-text directions are out of scope** (decided 2026-09-25).

## Open Questions

1. How does a writer that can only attach a dynamic to a note (ABC; LilyPond without a spacer) write a voice dynamic that falls under a held note? LilyPond can use a spacer-rest line; ABC may have to raise `RenderError`.
2. Kern's `**dynam` spine cannot say which voice of a part a dynamic belongs to. Should the writer raise for a multi-voice part whose voices have different dynamics, or write the part's dynamics only?
3. Should a style guideline use fermatas? For example, a chorale guide could treat a fermata as a phrase end when judging cadences.

## Implementation Plan

[to be filled in by /stories plan]
