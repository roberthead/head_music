<!--
metadata:
  created_at:   2026-09-24T18:58:30-07:00
  activated_at: 2026-10-15T12:24:49-07:00
  planned_at:
  finished_at:
  updated_at:   2026-10-15T12:24:49-07:00
-->

# Story: MEI Export

## Summary

AS a developer using HeadMusic

I WANT to render a `HeadMusic::Content::Flow` as an MEI document

SO THAT I can render the gem's output with Verovio and contribute it to scholarly-edition workflows that use MEI

## Background

[MEI](https://music-encoding.org/) is the XML format of scholarly music editions. A score nests `<music>/<body>/<mdiv>/<score>`. A `<scoreDef>` holds the key, the meter, and a `<staffGrp>` of `<staffDef>`s, and `<section>`s of `<measure>`s follow it. Each measure holds `<staff>/<layer>` elements of `<note>`, `<rest>`, and `<chord>` events, followed by "control events" such as `<slur>`, `<hairpin>`, and `<dynam>`. Control events point at notes by `@startid` and `@endid`, or sit at a beat with `@tstamp`.

Export matters for two reasons. Verovio, the engraver behind most web notation viewers, takes MEI as its native input. And MEI can say things MusicXML cannot, such as editorial annotations. Those let a later story carry the gem's guideline findings as `<annot>` elements tied to the notes they concern.

The writer has a full model to write. The MusicXML, LilyPond, ABC, and kern writers already write all of it:

- multi-voice and multi-staff parts
- notes that cross a barline, split by `BarSplitter`
- articulations, ornaments, and note dynamics
- dynamic levels and hairpins at any position
- slurs and phrase marks
- barline styles, repeats, endings, rehearsal marks, and navigation
- lyrics, transposing instruments, and instrument changes

Tuplets and grace notes arrive before this story, under the backlog order.

This story follows the writer shape the others share: `HeadMusic::Notation::MEI.render(flow, **options)` behind `Flow#to_mei`, with a preflight so the caller never receives a truncated document.

## Example

```ruby
mei = flow.to_mei
mei # => String of a well-formed MEI 5 document with <meiHead> and <music>
```

## Acceptance Criteria

### Document

- [ ] `HeadMusic::Notation::MEI.render(flow, **options)` and `Flow#to_mei` return a well-formed MEI 5 document
- [ ] With `MEI_SCHEMA` pointing at a local copy of `mei-CMN.rng`, every fixture's output validates with `xmllint --relaxng`
- [ ] `<meiHead>` carries the title, and the composer as a `<persName role="composer">`, from the flow's `Work` when it has one and from its name and composer string otherwise
- [ ] Every element the writer emits carries an `xml:id` derived from its position in the flow (part, voice, bar, and event), so rendering the same flow twice gives the same ids
- [ ] `Layout#to_mei` renders the layout's realized flows as one document, with one `<mdiv>` per flow
- [ ] The writer raises `MEI::RenderError` for an empty flow and for unpitched note events, before writing anything

### Parts, staves, and voices

- [ ] `<scoreDef>` carries the starting key signature and meter, and a `<staffGrp>` with one `<staffDef>` per staff, carrying its label (from the player name) and clef
- [ ] A multi-staff part is a nested `<staffGrp symbol="brace">` labeled once for the part
- [ ] Each voice becomes a `<layer>` on its staff, numbered within the staff in voice order. A staff crossing at a barline moves the voice's layer to its new staff
- [ ] Each bar becomes a `<measure n>`, and a pickup a `<measure n="0" type="upbeat">`

### Notes and rhythms

- [ ] Notes carry `@pname`, `@oct`, `@dur`, and `@dots`
- [ ] An accidental the key does not imply is written as `@accid`. One the key implies is written as `@accid.ges`. Within a bar, an accidental already shown on that pitch is not shown again
- [ ] Rests are `<rest>`, and a rest filling its bar is `<mRest>`. Chords are `<chord>`. Ties are `@tie` (`i`, `m`, `t`), including notes that cross a barline, split by `BarSplitter`
- [ ] Tuplets are `<tuplet num numbase>`, and grace notes carry `@grace` (`acc` or `unacc`)
- [ ] Beams are `<beam>` groups, following the grouping the MusicXML writer uses, from code shared with it rather than a copy

### Timeline

- [ ] A key, meter, or clef change at a later bar is written as a `<scoreDef>` or `<staffDef>` before that measure
- [ ] Tempo changes are `<tempo>` control events with `@midi.bpm`
- [ ] With `transposed: true`, a transposing part's `<staffDef>` carries `@trans.diat` and `@trans.semi` and its notes are written pitch, as the `transposed:` option means for the other writers

### Markings and spans

- [ ] Articulations are `@artic`, and note dynamics are `<dynam>` at the note
- [ ] Trills, mordents, and turns are `<trill>`, `<mordent>` (with `@form` `lower` or `upper`), and `<turn>` control events at their note
- [ ] Dynamic levels are `<dynam>` control events at their `@tstamp`, on the voice's staff and layer for a voice, and under the part's top staff for a part
- [ ] Hairpins are `<hairpin @form>` with `@tstamp` and `@tstamp2`, including one ending on the final barline
- [ ] Slurs are `<slur>` and phrase marks are `<phrase>`, both with `@startid` and `@endid`
- [ ] Barline styles are `measure/@right`. Repeats are `rptstart` and `rptend`, endings are `<ending n>` around their measures, rehearsal marks are `<reh>`, and segno, coda, Fine, To Coda, D.C., and D.S. are `<repeatMark @func>`

### Lyrics

- [ ] Each syllable is a `<verse n>/<syl>` in its note. A hyphen after it sets `@wordpos` and `@con="d"`

### Verification

- [ ] Golden documents are pinned for a two-voice species exercise, the SATB chorale fixture, the grand-staff piano fixture, and the markings and hairpin fixtures
- [ ] Every ABC, LilyPond, and kern fixture renders without error
- [ ] The golden fixtures render in Verovio without errors or warnings, checked by a spec that runs when Verovio is installed and is skipped otherwise
- [ ] Maintains 90%+ test coverage

## Notes

- Generate the XML as the MusicXML writer does, as text, without a runtime dependency.
- **Follow-up: guideline findings as annotations.** Findings would become `<annot @plist>` pointing at the notes they concern. The position-derived `xml:id`s exist for this, and so that a diff of two renders shows only what changed.
- Unpitched percussion raises for now. MEI writes it as `<note>` with `@loc` on a percussion staff, and the gem has no mapping from an unpitched sound to a staff position yet.
- **Waits on Timeline Expressions:** fermatas, tempo words, and meter symbols come with [Timeline Expressions](timeline-expressions.md), and `<fermata>`, `<tempo>` text, and `@meter.sym` with them.
- The round trip through MEI belongs to [MEI Import](mei-import.md), which lands after this story.

## Decisions

- **MEI 5 only** (decided 2026-10-14). Verovio and the current schema use it, and MEI 4 toolchains read most MEI 5 CMN.
- **`xml:id`s are stable, derived from position** (decided 2026-10-14), so that annotations and diffs remain meaningful.
- **Markings, spans, bar markings, multi-staff parts, tuplets, and grace notes are in scope** (decided 2026-10-14). The original v1 deferred dynamics, articulations, and slurs. The model now holds them, every other writer writes them, and leaving them out would make MEI the one lossy writer.

## Implementation Plan

[to be filled in by /stories plan]
