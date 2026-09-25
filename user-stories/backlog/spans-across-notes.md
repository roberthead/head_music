<!--
metadata:
  created_at:   2026-09-25T14:05:55-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-09-25T14:05:55-07:00
-->

# Story: Spans Across Notes: Slurs, Hairpins, and Melismas

## Summary

AS a developer or researcher using HeadMusic

I WANT a voice to hold markings that run from one note to another, such as slurs, phrase marks, crescendo and diminuendo hairpins, and lyric extenders

SO THAT phrasing and dynamic shape survive import, and the gem can reason about melismas and phrases

## Background

Some markings belong to a stretch of music, not to one note. Every format has them:

| Concept | ABC | LilyPond | MusicXML | kern | MEI |
|---|---|---|---|---|---|
| Slur | `(CDE)` | `c( d e)` | `<slur>` | `(c d e)` | `<slur>` |
| Phrase mark | — | `\( … \)` | `<slur>` (no separate element) | `{ … }` | `<phrase>` |
| Crescendo, diminuendo | `!<(!` … `!<)!` | `\<` … `\!` | `<wedge>` | `<` and `>` in `**dynam` | `<hairpin>` |
| Lyric extender (melisma) | `_` in `w:` | `__` | `<extend>` | — | `<extend>` |

The model has none of them. ABC and LilyPond raise on slurs and hairpins, and kern drops them. Slurs matter to this gem beyond display: in vocal music a slur marks a melisma, and a phrase mark states where a phrase ends, which a style guide could use.

This story comes second, after [Marks on Notes](marks-on-notes.md). The two share the catalog and the JSON approach, so doing them in order lets the second reuse the first.

## Example

```ruby
voice.add_span(:slur, from: "1:1", to: "1:3")
voice.add_span(:phrase, from: "1:1", to: "4:1")
voice.add_span(:crescendo, from: "2:1", to: "3:1")

voice.spans_at("1:2").map(&:kind) # => [:slur, :phrase]
placement.syllable.extends_to     # => position of the melisma's last note
```

## Acceptance Criteria

### Model

- [ ] A voice can hold spans, each with a kind (slur, phrase, crescendo, diminuendo), a starting placement, and an ending placement in the same voice
- [ ] A span can cross barlines and staff crossings, and still spans the right notes after a writer splits a note at a barline
- [ ] Slurs can nest inside phrase marks; two overlapping slurs in one voice raise `ArgumentError`, as they do in LilyPond
- [ ] A span that starts or ends where the voice has no placement raises `ArgumentError`
- [ ] Removing or moving a placement that a span ends on raises rather than leaving the span dangling
- [ ] A syllable can extend over a melisma to a later placement, and the extender is kept through JSON
- [ ] A voice can answer the spans in force at a position

### Serialization and formats

- [ ] Flow JSON writes spans per voice as placement references, within schema 4; existing schema-4 documents read unchanged
- [ ] ABC reads and writes slurs, hairpins, and `_` extenders in `w:` lines (once ABC lyrics exist; see Notes)
- [ ] LilyPond reads and writes slurs, phrasing slurs, and hairpins, and `__` extenders once LilyPond lyrics exist
- [ ] MusicXML writes `<slur>`, `<wedge>`, and `<extend>`
- [ ] kern reads and writes slurs and phrase marks, and reads and writes hairpins through a `**dynam` spine
- [ ] Each format round-trips a flow with a nested slur and phrase, a hairpin across a barline, and a melisma
- [ ] Maintains 90%+ test coverage

## Notes

- ABC and LilyPond cannot read or write lyrics yet (see the 2026-09-25 inventory). Extenders in those two formats wait for that work; MusicXML and JSON do not.
- Octave lines (8va), pedal marks, and glissandos are also spans. They are out of scope, but the span design should hold them later without a change to its shape.
- Ties are not spans: the model already holds them in the tied chain of a rhythmic value.

## Open Questions

1. Should a span refer to placements or to positions? A reference to a placement follows it when notes move; a position is simpler to serialize.
2. Should the gem infer melismas from slurs in vocal music when a file has no extenders?

## Implementation Plan

[to be filled in by /stories plan]
