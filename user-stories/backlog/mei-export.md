<!--
metadata:
  created_at:   2026-09-24T18:58:30-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-09-24T18:58:30-07:00
-->

# Story: MEI Export

## Summary

AS a developer using HeadMusic

I WANT to render a `HeadMusic::Content::Flow` as an MEI document

SO THAT I can render the gem's output with Verovio and contribute it to scholarly-edition workflows that use MEI

## Background

[MEI](https://music-encoding.org/) is the XML format of scholarly music editions (see [MEI Import](mei-import.md) for the structure). Export matters for two reasons. Verovio, the engraver used by most web-based notation viewers, takes MEI as its native input, so MEI is the most faithful way to get engraved output in a browser. And MEI can say things MusicXML cannot, such as editorial annotations. Later, it could carry the gem's style-guide findings as `<annot>` elements tied to the notes they concern.

This story mirrors [MusicXML Export](../done/music-xml-export.md): `HeadMusic::Notation::MEI.render(flow, **options)` behind a one-line `Flow#to_mei` delegate, with validation up front so the caller never receives a truncated document.

## Example

```ruby
mei = flow.to_mei
mei # => String of a well-formed MEI 5 document with <meiHead> and <music>
```

## Acceptance Criteria

- [ ] `HeadMusic::Notation::MEI.render(flow)` and `Flow#to_mei` return a well-formed MEI document that validates against the MEI CMN schema
- [ ] `<meiHead>` carries the title and composer
- [ ] `<scoreDef>` carries the key and meter, with one `<staffDef>` per part carrying its label and clef
- [ ] Each voice becomes a `<layer>` in its part's `<staff>`, and each bar becomes a `<measure>`
- [ ] Notes carry `@pname`, `@oct`, `@dur`, and `@dots`; accidentals render as written (`@accid`) or implied by the key (`@accid.ges`)
- [ ] Rests, chords, ties, and lyrics (`<verse>/<syl>`) render
- [ ] Mid-piece key and meter changes render as `<scoreDef>` changes at the right measure
- [ ] Transposing parts render with `@trans.diat` / `@trans.semi` and the `transposed:` option behaves as it does for the other writers
- [ ] Beaming follows the same grouping the MusicXML and LilyPond writers use
- [ ] Output renders in Verovio without errors
- [ ] Every golden fixture parses back through MEI import to an equal flow, once that story lands
- [ ] `Layout#to_mei` renders a multi-flow layout as one document with one `<mdiv>` per flow
- [ ] Maintains 90%+ test coverage

## Notes

- Generate the XML without a runtime dependency, as the MusicXML writer already does.
- Give elements `xml:id`s from the start. That lets a later story attach guideline findings as `<annot @plist>`, which is a distinctive reason to choose MEI over MusicXML.
- Out of scope for v1: mensural output, editorial markup, dynamics, articulations, and slurs.

## Open Questions

1. Should `xml:id`s be stable across renders (derived from position) so that annotations and diffs remain meaningful?
2. MEI 5 only, or should MEI 4 be offered for older toolchains?

## Implementation Plan

[to be filled in by /stories plan]
