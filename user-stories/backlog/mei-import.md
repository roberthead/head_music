<!--
metadata:
  created_at:   2026-09-24T18:58:30-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-09-24T19:23:10-07:00
-->

# Story: MEI Import

## Summary

AS a developer or researcher using HeadMusic

I WANT to pass an MEI document and receive a `HeadMusic::Content::Flow`

SO THAT I can analyze the scholarly digital editions and early-music collections that are published in MEI

## Background

The [Music Encoding Initiative](https://music-encoding.org/) (MEI) is an XML format designed for scholarly editions. It keeps more meaning than MusicXML does: editorial markup (`<app>`, `<choice>`, `<supplied>`), sources and variants, and, through its mensural module, early-music notation. Verovio renders MEI natively, and projects such as the Josquin Research Project, CRIM, and many library digitization efforts publish in it.

An MEI score nests `<music>/<body>/<mdiv>/<score>`, with a `<scoreDef>` (key, meter, and a `<staffGrp>` of `<staffDef>`s) followed by `<section>`s of `<measure>`s. Each measure holds `<staff>/<layer>` elements containing `<note>`, `<rest>`, and `<chord>` events.

This story reads CMN (common music notation) MEI. Its companion is [MEI Export](mei-export.md).

## Example

```ruby
flow = HeadMusic::Notation::MEI.parse(File.read("motet.mei"))
flow.name          # => from <meiHead> <title>
flow.voices.length # => one per staff layer
```

## Acceptance Criteria

- [ ] `HeadMusic::Notation::MEI.parse(string)` returns a `HeadMusic::Content::Flow`
- [ ] `<meiHead>` title and composer map to the flow's identity
- [ ] Each `<staffDef>` becomes a part, and each `<layer>` becomes a voice
- [ ] `<note>` attributes `@pname`, `@oct`, `@accid` / `@accid.ges`, `@dur`, and `@dots`, and child `<accid>` elements, map to pitches and rhythmic values
- [ ] `<rest>`, `<mRest>`, `<chord>`, and ties (`@tie` or `<tie>`) map to placements
- [ ] `<scoreDef>` / `<staffDef>` key (`@key.sig` or `<keySig>`) and meter (`@meter.count`, `@meter.unit`, or `<meterSig>`) map to the timeline, including mid-piece `<scoreDef>` changes
- [ ] `@trans.diat` / `@trans.semi` on a staff definition are honored so transposing parts land in concert pitch
- [ ] `<verse>/<syl>` lyrics attach to placements
- [ ] Editorial markup has a documented rule: for example, `<app>` takes `<lem>` and `<choice>` takes `<corr>` / `<reg>` by default
- [ ] Mensural MEI and other unsupported modules raise `MEI::UnsupportedFeatureError`
- [ ] Malformed XML raises `MEI::ParseError`
- [ ] At least one real edition (from a public MEI corpus) parses end to end
- [ ] Maintains 90%+ test coverage

## Notes

- Parse with REXML, which is a runtime dependency of the gem (decided 2026-09-24).
- Mensural notation is the most interesting long-term reason to read MEI for this gem, since the species and Renaissance guides grade that repertoire. It is also a large model question (ligatures, proportions, no barlines), so it is a follow-up here.
- Target MEI 5 and accept MEI 4 where the elements are the same.

## Open Questions

1. Should editorial choices be selectable through options (`parse(xml, reading: :sic)`), or fixed in v1?
2. Should `<section>` boundaries, repeats, and endings be kept, or flattened?

## Implementation Plan

[to be filled in by /stories plan]
