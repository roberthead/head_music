<!--
metadata:
  created_at:   2026-09-25T14:05:57-07:00
  activated_at: 2026-09-25T17:40:58-07:00
  planned_at:
  finished_at:
  updated_at:   2026-09-25T17:40:58-07:00
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

This is the first of five stories from the 2026-09-25 inventory of concepts the model lacks. It comes first because it removes the most import failures for the least design risk, and [Spans Across Notes](spans-across-notes.md) builds on its catalog.

## Example

```ruby
placement = voice.place("1:1", :quarter, "C5")
placement.mark(:staccato)
placement.mark(:fermata)
placement.mark(HeadMusic::Content::Mark.get(:forte))

placement.marks.map(&:name_key) # => ["staccato", "fermata", "forte"]
placement.marked?(:fermata)     # => true
```

## Acceptance Criteria

### Model

- [ ] A catalog of marks is loaded from YAML, as playing techniques are: articulations (staccato, staccatissimo, accent, tenuto, marcato), ornaments (trill, mordent, inverted mordent, turn), the fermata, and dynamics (*ppp* through *fff*, *fp*, *sf*, *sfz*, *rfz*)
- [ ] Each mark has a category and a name through the `Named` mixin, with English names and fallbacks for the other locales
- [ ] A placement can carry any number of marks, each at most once; a rest can carry a fermata but not an articulation or ornament, and adding one raises `ArgumentError`
- [ ] A voice can answer the dynamic in force at a position, from the most recent dynamic mark
- [ ] Marks do not change a placement's pitches, rhythmic value, or position, so every existing analysis and style guideline gives the same answers

### Serialization

- [ ] Flow JSON writes a placement's marks as a sorted list of keys, within schema 4 as an optional key; a placement with no marks serializes as it does now, and existing schema-4 documents read unchanged

### Formats

- [ ] ABC reads and writes the articulation, ornament, fermata, and dynamic decorations, in both shorthand (`.`, `H`, `T`) and `!name!` forms
- [ ] LilyPond reads and writes the articulation shorthands and commands, `\fermata`, the ornaments, and dynamics
- [ ] MusicXML writes `<articulations>`, `<ornaments>`, `<fermata>`, and `<dynamics>`
- [ ] kern reads and writes articulations, ornaments, and fermatas in the token, and dynamics through a `**dynam` spine
- [ ] A mark the catalog does not know still raises `UnsupportedFeatureError` naming it, rather than being dropped
- [ ] Each format round-trips a flow with a fermata at each phrase end, a staccato run, a trill, and changing dynamics
- [ ] The hand-encoded chorale fixture keeps its fermatas on import
- [ ] Maintains 90%+ test coverage

## Notes

- The format sections are the bulk of the work. If planning finds them too large, keep the model, JSON, kern, and MusicXML here, and move ABC and LilyPond to a follow-up.
- Bowings (up-bow, down-bow), fingering, breath marks, and tremolo are also marks on a note. They are out of scope, but the catalog should be able to hold them later.
- Hairpins are spans and belong to [Spans Across Notes](spans-across-notes.md).
- Free text on the score ("dolce", "pizz.") is related but different: it is written text, not a symbol. See the Open Questions.

## Open Questions

1. Where does a dynamic live when a format writes it between notes, as MusicXML directions and kern `**dynam` spines can? Attaching it to the next placement is simplest; a voice-level event at a position is more faithful.
2. Should free-text directions ("dolce", "pizz.", "div.") be marks with a text value, or a separate concept? They appear in every format, and "pizz." overlaps with playing techniques.
3. Should a style guideline use fermatas? For example, a chorale guide could treat a fermata as a phrase end when judging cadences.

## Implementation Plan

[to be filled in by /stories plan]
