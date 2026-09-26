<!--
metadata:
  created_at:   2026-09-25T14:05:57-07:00
  activated_at: 2026-09-25T17:40:58-07:00
  planned_at:
  finished_at:
  updated_at:   2026-09-25T19:58:12-07:00
-->

# Story: Marks on Notes: Articulations, Ornaments, Fermatas, and Dynamics

## Summary

AS a developer or researcher using HeadMusic

I WANT notes to carry the marks written on them, such as staccato, a trill, a fermata, or *sfz*, and voices and parts to carry dynamics such as *p* and *f*

SO THAT the many files that use these markings import instead of failing, and the markings survive a trip through the gem

## Background

These are the most common markings in written music, and every format has them:

| Concept | ABC | LilyPond | MusicXML | kern | MEI |
|---|---|---|---|---|---|
| Staccato, accent, tenuto, marcato | `.C`, `!accent!`, `!tenuto!` | `c-.`, `c->`, `c--`, `c-^` | `<articulations>` | `'`, `^`, `~` | `<artic>` |
| Trill, mordent, turn | `TC`, `MC`, `!turn!` | `\trill`, `\mordent`, `\turn` | `<ornaments>` | `t`, `m`, `S` | `<trill>`, `<mordent>`, `<turn>` |
| Fermata | `HC`, `!fermata!` | `\fermata` | `<fermata>` | `;` | `<fermata>` |
| Dynamics and sforzandos | `!p!`, `!sfz!` | `\p`, `\sfz` | `<dynamics>` | `p` in `**dynam` | `<dynam>` |

The model has none of them. ABC raises on `.` and `!…!` decorations, LilyPond raises on `-.` and `\fermata`, and kern drops them. A folk tune in ABC with one staccato dot, or a LilyPond file with one *f*, cannot be imported.

Fermatas matter to this gem in particular. In the Bach chorales, fermatas mark the ends of phrases, and the kern reader throws them away.

The markings fall into two kinds:

- **Marks** belong to one note: articulations, ornaments, the fermata, and the sforzandos (*sf*, *sfz*, *rfz*, *fp*), which accent their note without changing the dynamic in force, except that *fp* leaves *p* in force after it.
- **Dynamics** (*ppp* to *fff*) govern the music after them, so they are events at a position rather than marks. A dynamic can be written on a voice, and it can then fall anywhere, even under a held note or a rest. It can also be written on a part, where it governs every voice on every staff, as a piano dynamic between the two staves does or as one dynamic does for two voices sharing a staff. A voice is governed by whichever voice or part dynamic comes latest at or before a position, as a player reads the page.

This is the first of five stories from the 2026-09-25 inventory of concepts the model lacks. It comes first because it removes the most import failures, and [Spans Across Notes](../backlog/spans-across-notes.md) builds on its catalog.

## Example

```ruby
placement = voice.place("1:1", :quarter, "C5")
placement.mark(:staccato)
placement.mark(:fermata)
placement.mark(:sfz)
placement.marks.map(&:name_key) # => ["staccato", "fermata", "sfz"]
placement.marked?(:fermata)     # => true

voice.change_dynamic("1:1", :p)
part.change_dynamic("5:1", :f)
voice.dynamic_at("4:1").name_key # => "p"
voice.dynamic_at("5:2").name_key # => "f"
```

## Acceptance Criteria

### Marks

- [ ] A catalog of marks is loaded from YAML, as playing techniques are: articulations (staccato, staccatissimo, accent, tenuto, marcato), ornaments (trill, mordent, inverted mordent, turn), the fermata, and the sforzandos (*sf*, *sfz*, *rfz*, *fp*)
- [ ] Each mark has a category and a name through the `Named` mixin, with English names and fallbacks for the other locales
- [ ] A placement can carry any number of marks, each at most once; a rest can carry a fermata, and adding any other mark to a rest raises `ArgumentError`
- [ ] Marks and dynamics do not change a placement's pitches, rhythmic value, or position, so every existing analysis and style guideline gives the same answers

### Dynamics

- [ ] The dynamics *ppp*, *pp*, *p*, *mp*, *mf*, *f*, *ff*, and *fff* can be written on a voice or on a part at a position
- [ ] A voice dynamic can fall at any position in its voice, including under a held note or a rest
- [ ] A part dynamic governs every voice of the part, on all its staves
- [ ] `Voice#dynamic_at(position)` answers the dynamic in force: the voice or part dynamic at the latest position at or before the given one, the voice's own when both fall at that position, and *p* after an *fp*; with none written, it answers nil
- [ ] Two dynamics at the same position on one voice, or on one part, raise `ArgumentError`

### Serialization

- [ ] Flow JSON writes a placement's marks as a sorted list of keys, voice dynamics on their voice, and part dynamics on their part, all within schema 4 as optional keys; a flow with none serializes as it does now, and existing schema-4 documents read unchanged

### Reading

- [ ] ABC reads the articulation, ornament, fermata, and sforzando decorations as marks, in both shorthand (`.`, `H`, `T`) and `!name!` forms, and a dynamic decoration as a voice dynamic at its note
- [ ] LilyPond reads articulation shorthands and commands, `\fermata`, the ornaments, and the sforzandos as marks; a dynamic on a note as a voice dynamic; and a `\new Dynamics` context as dynamics of the part it sits in
- [ ] kern reads articulations, ornaments, fermatas, and sforzandos in a token as marks, and a `**dynam` spine as dynamics of the part of the nearest `**kern` spine on its left
- [ ] A marking a reader recognizes but the catalog does not hold, such as a bowing or a breath mark, is dropped, so nothing that imports today starts failing; syntax a reader does not recognize at all still raises `UnsupportedFeatureError`

### Writing

- [ ] ABC, LilyPond, MusicXML, and kern write every mark in the catalog
- [ ] ABC and LilyPond write a voice dynamic before the note it falls on. One that falls in the middle of a note is written before the next note instead, and one with no later note is left out
- [ ] ABC writes part dynamics on the voice, and LilyPond writes them in a `\new Dynamics` context for the part
- [ ] MusicXML writes each dynamic as a `<direction>` at its position, with a voice dynamic tied to its `<voice>` and a part dynamic tied to none
- [ ] kern writes one `**dynam` spine per part that has dynamics, holding the part's dynamics and its voices'. Where several fall at the same position, it writes the first: the part's before any voice's, and the voices in order

### Round trips

- [ ] Each format round-trips a flow with a fermata at each phrase end, a staccato run, a trill, an *sfz*, an *fp*, and changing dynamics, keeping every mark and the dynamic in force for every voice at every note
- [ ] A grand-staff piano flow with part dynamics round-trips through LilyPond, MusicXML, and kern
- [ ] The hand-encoded chorale fixture keeps its fermatas on import
- [ ] Maintains 90%+ test coverage

## Notes

- Bowings (up-bow, down-bow), fingering, breath marks, and tremolo are also marks on a note. They are out of scope, but the catalog should be able to hold them later.
- Hairpins are spans and belong to [Spans Across Notes](../backlog/spans-across-notes.md).
- Free-text directions ("dolce", "pizz.", "div.") are out of scope. "pizz." and "arco" overlap with playing techniques, so text directions need a design of their own.
- Kern's `**dynam` spine cannot say which voice of a part a dynamic belongs to, so a part whose voices have different dynamics comes back with one set, the part's.

## Implementation Plan

[to be filled in by /stories plan]
