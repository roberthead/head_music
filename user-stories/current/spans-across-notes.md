<!--
metadata:
  created_at:   2026-09-25T14:05:55-07:00
  activated_at: 2026-09-27T13:53:22-07:00
  planned_at:
  finished_at:
  updated_at:   2026-09-27T15:07:11-07:00
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

The model has none of them. As of `e31cf6a8`:

- **Slurs raise in ABC and LilyPond.** `(CDE)` and `c( d e)` raise `UnsupportedFeatureError`. LilyPond's phrasing slur `\(` raises `ParseError: Unexpected character "\"`, because the lexer takes it for a malformed command. Syntax that is valid but unsupported should not raise a parse error.
- **Hairpins are dropped in ABC and LilyPond.** ABC's `DecorationMapper` recognizes `!<(!`, `!crescendo(!`, and their kin and drops them. LilyPond's `MarkReader` drops `\<`, `\>`, and `\!`, including inside `\new Dynamics`.
- **kern drops all of them.** The token reader passes over `(`, `)`, `{`, and `}`, and `DynamicReader` skips `<`, `>`, `(`, `)`, `[`, and `]` in `**dynam`.
- **ABC and LilyPond still have no lyrics.** `w:` raises, and so does `\new Lyrics`. kern reads `**text`, but a `_` there comes through as no syllable.

Slurs matter to this gem beyond display: in vocal music a slur marks a melisma, and a phrase mark states where a phrase ends, which a style guide could use.

This story comes second, after [Articulations, Ornaments, Dynamics](../done/articulations-ornaments-dynamics.md), and builds on its shapes:

- `KeyedCatalog` for the kinds of span.
- Position-keyed events, like `DynamicEvent` with `Voice#place_dynamic` and `Part#place_dynamic`, where a second event at one position raises.
- Optional keys within Flow JSON schema 5, validated through `SchemaValues`.
- `BarSplitter.position_at` and `offset_in_bar` for turning a position into an offset in its bar and back.

It also inherits the format machinery that the two dynamics stories built:

- **ABC:** `DecorationMapper`.
- **LilyPond:** `MarkReader`, and `PartDynamics` for a `\new Dynamics` context.
- **kern:** `DynamicFields` and `DataRows` on the writing side. On the reading side, `DynamicPlacer` times rows where nothing attacks by Humdrum's even split.
- **MusicXML:** `DirectionWriter` and `Divisions`.

### Lessons carried over

- **kern's `**dynam` spine holds one value per row**, and an accent already outranks a level there. A hairpin mark that lands on a row with a level or an accent collides with it. Decide up front which one wins, and keep whatever cannot be recovered from the marks around it.
- **`expect_same_markings` compares only the level in force at each note.** It cannot see a span that moved. Round trips here have to assert where each span starts and ends.
- **Check every helper that does arithmetic on a flow's timeline against spans** before calling a format done: MusicXML `Divisions`, kern row planning, LilyPond spacer rests, and `BarSplitter` segments.

## Example

```ruby
voice.add_span(:slur, from: "1:1", to: "1:3")
voice.add_span(:phrase, from: "1:1", to: "4:1")
voice.add_span(:crescendo, from: "2:1", to: "3:1")

voice.spans_at("1:2").map(&:kind) # => [:slur, :phrase]
note_event.syllables[1].extends_to # => position of the melisma's last note
```

## Acceptance Criteria

### Model

- [ ] A voice can hold spans, each with a kind (slur, phrase, crescendo, diminuendo) and a start and an end where the same voice has voice events
- [ ] A span can cross barlines and staff crossings, and still spans the right notes after a writer splits a note at a barline
- [ ] Slurs can nest inside phrase marks; two overlapping slurs in one voice raise `ArgumentError`, as they do in LilyPond
- [ ] A span that starts or ends where the voice has no voice event raises `ArgumentError`
- [ ] Placing a note onto a rest that a span starts or ends on, which replaces the rest, leaves the span on the new note; placing anything that would leave a span's end where the voice has no voice event raises rather than leaving the span dangling
- [ ] A syllable can extend over a melisma to a later note event, and the extender is kept through JSON
- [ ] A voice can answer the spans in force at a position

### Serialization and formats

- [ ] Flow JSON writes spans per voice as optional keys within schema 5, validated with path-tagged errors as the markings are; existing schema-5 documents read unchanged
- [ ] ABC reads and writes slurs, hairpins, and `_` extenders in `w:` lines (once ABC lyrics exist; see Notes)
- [ ] LilyPond reads and writes slurs, phrasing slurs, and hairpins, and `__` extenders once LilyPond lyrics exist
- [ ] MusicXML writes `<slur>`, `<wedge>`, and `<extend>`
- [ ] kern reads and writes slurs and phrase marks, and reads and writes hairpins through a `**dynam` spine
- [ ] Each format round-trips a flow with a nested slur and phrase, a hairpin across a barline, and a melisma, asserting where each span starts and ends, not only which spans exist
- [ ] Each reader turns what it drops or refuses today into spans, and every file that imports today still imports
- [ ] LilyPond's `\(` and `\)` no longer raise `ParseError`
- [ ] Maintains 90%+ test coverage

## Notes

- ABC and LilyPond cannot read or write lyrics yet (see the 2026-09-25 inventory). Extenders in those two formats wait for that work; MusicXML and JSON do not.
- Octave lines (8va), pedal marks, and glissandos are also spans. They are out of scope, but the span design should hold them later without a change to its shape.
- Ties are not spans: the model already holds them in the tied chain of a rhythmic value.

## Open Questions

1. Should a span refer to voice events or to positions? A reference to a voice event follows it when notes move; a position is simpler to serialize.
   - **Recommendation: positions.** Everything the markings stories added is keyed by position: `DynamicEvent`, `BarSplitter.position_at`, and the kern reader's even split. Positions also serialize without a way to reference a voice event. `Voice` cannot remove or move a voice event, so the one way a span's end can lose its note is `place` replacing a rest with a note, which keeps the position. That is the case the Model criteria pin.
2. Should the gem infer melismas from slurs in vocal music when a file has no extenders?

## Implementation Plan

[to be filled in by /stories plan]
