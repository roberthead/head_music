<!--
metadata:
  created_at:   2026-09-25T14:05:54-07:00
  activated_at: 2026-09-30T11:08:10-07:00
  planned_at:   2026-09-30T11:50:54-07:00
  finished_at:
  updated_at:   2026-09-30T11:58:03-07:00
-->

# Story: Bar Markings: Barline Styles, Rehearsal Marks, and Navigation

## Summary

AS a developer using HeadMusic

I WANT bars to carry their barline style, rehearsal marks, and navigation instructions such as segno, coda, D.C., and Fine

SO THAT a score's structure survives import, and the gem can tell what order the bars are played in

## Background

`Bar` holds repeat structure and nothing else: `starts_repeat`, `ends_repeat_after_num_plays`, and `plays_on_passes` for 1st and 2nd endings. The formats say more about a bar:

| Concept | ABC | LilyPond | MusicXML | kern | MEI |
|---|---|---|---|---|---|
| Double and final barlines | `\|\|`, `\|]` | `\bar "\|\|"`, `\bar "\|."` | `<bar-style>` | `\|\|`, `==` | `@right` |
| Rehearsal marks and section labels | `P:A` | `\mark \default` | `<rehearsal>` | `*>A` | `<reh>` |
| Segno, coda, D.C., D.S., Fine | `!segno!`, `!coda!`, `!D.C.!`, `!fine!` | `\segnoMark`, `\codaMark`, text | `<segno>`, `<coda>`, `<sound dacapo>` | text | `<dir>`, `@type` |

Kern already reads section labels and expansion lists (`*>A`, `*>[A,A,B]`) and ignores them. Only ABC and kern write a final barline, and only at the very end. A double bar before a new section, a rehearsal letter, or a D.C. al Fine are lost on the way through.

## Example

```ruby
flow.bars(8).last.barline = :double
flow.bars(9).last.rehearsal_mark = "B"
flow.bars(9).last.segno = true
flow.bars(16).last.jump = HeadMusic::Content::Jump.new(:dal_segno, to: :fine)
flow.bars(12).last.fine = true

flow.performance_order.map(&:number) # => [1, 2, ..., 16, 9, 10, 11, 12]
flow.performance_order.last          # => #<data PlayedBar bar=Bar 12, pass=1, playing=2>
```

## Acceptance Criteria

### Model

- [ ] A bar's closing barline can be regular, double, final, dashed, or dotted; regular is the default and is not serialized
- [ ] A bar can carry a rehearsal mark: a letter, a number, or free text such as "Verse"; it is stored as a string, so `12` and `"12"` are the same mark
- [ ] A bar can carry a segno or coda sign, a Fine, a "To Coda", and a jump (D.C. or D.S., al Fine or al Coda)
- [ ] A rehearsal mark, segno, and coda sign mark the start of their bar; a barline, Fine, To Coda, and jump mark its end. A final barline at the end of the flow is implied, and writers draw it
- [ ] `Flow#performance_order` lists the bars in the order they are played, unfolding repeats, 1st and 2nd endings, and jumps
- [ ] `performance_order` answers `PlayedBar`s with `bar`, `pass` (the repeat pass that endings and verses key on), and `playing` (the running count of times that bar has sounded)
- [ ] After a D.C. or D.S., repeats are not taken again, and each repeated section plays its last ending
- [ ] Fine and To Coda act only after the jump
- [ ] A plain D.C. or D.S. stops at whichever comes first after its target, a Fine or a To Coda
- [ ] A repeat plays as many times as the larger of its play count and the highest pass its endings name
- [ ] A closing repeat with no opening repeat goes back to the bar after the previous closing repeat, or to the first bar
- [ ] `performance_order` raises `ArgumentError` for navigation it cannot follow: more than one jump; a D.S. with no segno before it; an al Fine with no Fine after the target; an al Coda with no To Coda between the target and the jump, or no coda sign after it

### Serialization and formats

- [ ] Flow JSON writes the new bar fields sparsely, within schema 5; existing schema-5 documents read unchanged
- [ ] ABC reads and writes double, final, and dotted barlines, `P:` sections, and the navigation decorations
- [ ] ABC reads a `P:` header (playing order) without raising, and ignores it
- [ ] ABC sets a repeat's play count from its highest ending number
- [ ] ABC reads the abcm2ps `!D.C.alfine!`, `!D.C.alcoda!`, `!D.S.alfine!`, and `!D.S.alcoda!`
- [ ] ABC and MusicXML write repeats and 1st and 2nd endings
- [ ] LilyPond reads and writes `\bar` styles, `\mark`, `\sectionLabel`, `\segnoMark`, `\codaMark`, `\fine`, and `\jump`; its output compiles with lilypond 2.26 without warnings
- [ ] MusicXML writes `<bar-style>`, `<rehearsal>`, `<segno>`, `<coda>`, and the `<sound>` attributes for jumps
- [ ] kern reads and writes `||` and section labels (`*>A`), and writes `==` only at the end
- [ ] A D.S. al Coda flow round-trips through Flow JSON, ABC, and LilyPond. MusicXML output is checked element by element. kern is excluded, because it has no standard navigation token
- [ ] Maintains 90%+ test coverage

## Notes

- `performance_order` gives MIDI export (backlog) and the `Conductor` a way to play a flow as written, not as printed.
- Not in this story, and left without a story of their own for now:
  - LilyPond repeats and endings (`\repeat volta n { } \alternative { }`). The block has to wrap the same bars in every staff, while the writer writes one flat line per bar, and the reader would need a nested construct it rejects today. The flat `\bar ".|:"` is visual only (MIDI and `\unfoldRepeats` ignore it).
  - kern endings and expansion lists (`*>[A,A1,A,A2]`). kern expresses endings only as section labels plus a playing order; reading one is the inverse of `performance_order`, and could check it.

## Answered Questions

1. Are rehearsal marks per flow (one row of letters over the score) or per part? MusicXML repeats them in every part, but they mean one thing.

Answer: Stored per flow, written to parts when that is the convention of the format.

2. Should `performance_order` answer bar numbers, or bar objects with the pass number, so a caller can tell the first and second playing apart?

Answer: Bar objects with the pass number

## Implementation Plan

### Overview

The markings become validated, sparse fields on the existing `Bar`, with a `Jump` value object for D.C. and D.S. A new `Flow::PerformanceOrder` works out the playing order: it reads the bar structure once, raises on any jump it cannot follow, then walks the bars. Each format extends the code that already handles its barlines. Repeat and ending writing goes into ABC and MusicXML here; LilyPond repeats and kern endings are left out (see Notes).

Consulted: product-manager, developer, best-practices-engineer (navigation model and unfolding algorithm). No UI work, so no designer or accessibility specialist.

Verified against the code on `story/bar-markings`:

- Repeat state is read only by the ABC parser, the kern reader, and the kern writer. The kern writer writes repeat barlines but not endings.
- The ABC, LilyPond, and MusicXML writers drop repeats and endings.
- These raise `UnsupportedFeatureError` today: ABC `P:A` in the body, a `P:` header, and `!D.S.alcoda!`; LilyPond `\bar`, `\mark`, `\segnoMark`, `\section`, and `\repeat`.
- `abc/repeat_tagger.rb:49` always sets the play count to 2.

Repeat and ending writing, by format:

- **ABC: in this story.** The reader already reads `|:`, `:|`, and `[1`, so an ABC round trip is only faithful if the writer writes them too. The closing-token code is rewritten for barline styles anyway.
- **MusicXML: in this story.** `<bar-style>`, `<repeat>`, and `<ending>` share the `<barline>` element.
- **LilyPond repeats: not in this story.** `\repeat volta n { } \alternative { }` must wrap the same bars in every staff, while the writer writes one flat line per bar; the reader would need a nested construct it rejects today (~300 lines). The flat `\bar ".|:"` is visual only and would be thrown away later.
- **kern endings and expansion lists: not in this story.** kern expresses endings only as section labels plus an expansion list (`*>[A,A1,A,A2]`); reading those is the inverse of `performance_order`.

### Steps

1. **Model: `Jump` and the new `Bar` fields**
   - `class HeadMusic::Content::Jump < Data.define(:kind, :to)`, with `def self.new(kind, to: nil) = super(kind:, to:)` so `Jump.new(:dal_segno, to: :fine)` works (confirm `#with` still works).
   - Validates `KINDS = %i[da_capo dal_segno]` and `TARGETS = [nil, :fine, :coda]`, raising `ArgumentError`.
   - `da_capo?`, `dal_segno?`; `to_s` ("D.C.", "D.S. al Coda"); `to_h` (`{"kind" => "dal_segno", "to" => "coda"}`, `"to"` omitted when nil); `from_h`.
   - `Jump.get(text)` parses "D.C.", "D.S.", "Da Capo", "Dal Segno" with optional "al Fine"/"al Coda"; nil otherwise.
   - `to: nil` means play from the target and stop at whichever comes first, a Fine or a To Coda. `:fine` ignores To Coda; `:coda` ignores Fine.
   - Require `content/jump` in `lib/head_music.rb` before `content/bar`.
   - `Bar#barline`: one of `%i[regular double final dashed dotted]`; symbol or string; `nil` resets to `:regular`; anything else raises.
   - `Bar#rehearsal_mark`: non-empty stripped String; a positive Integer is stored as a String.
   - `segno`, `coda`, `fine`, `to_coda`: writers accept only `true`/`false`, with `?` readers.
   - `jump`: a `Jump` or nil.
   - One short comment on placement: start of bar — `rehearsal_mark`, `segno`, `coda`, `starts_repeat`; end of bar — `barline`, `fine`, `to_coda`, `jump`, `ends_repeat_after_num_plays`.
   - `to_h` stays sparse; `to_s` gains a summary such as `Bar [B] segno || D.S. al Coda`.
   - Update the comments on `Bar` and `Bars#serialize` that say bars hold repeat structure only.
   - Files: `content/jump.rb` (new), `content/bar.rb`, `content/flow/bars.rb`, `head_music.rb`, `spec/.../content/jump_spec.rb` (new), `spec/.../content/bar_spec.rb`.

2. **Flow JSON, still schema 5**
   - Rename `Deserializer#apply_repeat_flags` to `apply_bar_fields`; update its caller in `hash_deserializer.rb`.
   - Read new keys through new `SchemaValues` methods (`barline`, `rehearsal_mark`, `jump`, strict boolean) — today `"segno": "no"` would read as true.
   - Wrap setter `ArgumentError`s with their document path (`bars[3].jump: ...`), as `each_placed` does.
   - No schema bump, no `v4_upgrade.rb` change: every new key is optional.
   - Update the bar table and JSON example in `references/content-schema.md`.
   - Files: `flow/deserializer.rb`, `flow/hash_deserializer.rb`, `flow/schema_values.rb`, `references/content-schema.md`, `spec/.../flow_serialization_spec.rb`.

3. **`Flow#performance_order`**
   - `Flow::PerformanceOrder`; `Flow#performance_order` is `PerformanceOrder.new(self).bars`, never memoized (`Bar` is mutable).
   - Element: `PlayedBar = Data.define(:bar, :pass, :playing)` with `def number = bar.number`. `pass` is the repeat pass that `plays_on_pass?` checks; `playing` counts the times that bar has sounded so far (1, 2, 3...). The walk keeps its own `after_jump` flag internally.
   - Range: `earliest_bar_number` to the later of `latest_bar_number` and a new `Bars#last_marked_number` (last bar whose `to_h` is non-empty). Bars allocated only by reading must not extend the range.
   - Analysis pass, once, indexed by bar number:
     - Repeat regions open at the first bar and at each `starts_repeat`; after a repeat end, a region closes at the first following bar with no `plays_on_passes`.
     - `final_pass(region)` is the max of 1, each `ends_repeat_after_num_plays`, and each pass named in a `plays_on_passes` there.
     - Lenient: a `:|` with no `|:` returns to the start of its region; a second `|:` before a `:|` opens a new region.
     - A D.S. goes to the last segno before the jump bar; To Coda goes to the first coda sign after it.
   - Raise `ArgumentError`, naming bars, when: more than one jump; a D.S. has no segno at or before it; an al Fine has no Fine at or after the target; an al Coda has no To Coda between target and jump, or no coda sign after that To Coda.
   - A Fine or To Coda with no jump using it is allowed and ignored.
   - Walk, at each bar:
     1. Entering a region: `pass = after_jump ? region.final_pass : 1`.
     2. Skip unless `bar.plays_on_pass?(pass)`; a skipped bar's `:|` does not fire.
     3. Emit the `PlayedBar`.
     4. Then, in order: after the jump a Fine stops (unless al Coda); after the jump a To Coda goes to the coda, once (unless al Fine); a `:|` with `pass < count` before the jump increments `pass` and returns to region start; an untaken jump is taken (set `after_jump`, move to target); otherwise next bar.
   - A repeat on the jump bar is taken before the jump.
   - Termination: every backward move is bounded, so no step budget is needed.
   - Files: `flow/performance_order.rb` (new), `flow.rb`, `flow/bars.rb`, `head_music.rb`, `spec/.../flow/performance_order_spec.rb` (new, builds bars directly).

4. **ABC reader**
   - Add `.|` to `BAR_LINE_PATTERN` in `line_scanner.rb`; `RepeatTagger#bar_line` sets the completed bar's style: `||` double, `|]` final, `.|` dotted. `[|` stays regular.
   - `Parser#finish` resets a `:final` last bar to `:regular` (implied).
   - `RepeatTagger` sets `ends_repeat_after_num_plays` to the highest ending number read, not a fixed 2.
   - A body `P:` line and inline `[P:x]` become a `:part_label` token setting `rehearsal_mark` on `entered_bar_number`. A header `P:` (playing order) is recognized and ignored.
   - `decoration_mapper.rb`: move `segno coda D.S. D.C. dacoda dacapo fine` (and `S`, `O`) into a `:navigation` kind; add `D.C.alfine`, `D.C.alcoda`, `D.S.alfine`, `D.S.alcoda`. `dacoda` is To Coda.
   - Before a note, a navigation decoration goes on that note's bar. Before a barline, `segno`/`coda` go on the bar being entered, the rest on the bar just completed, via `PendingDecorations#take_navigation` before `cross_bar_line`.
   - Two `!coda!` and no `!dacoda!`: read the first `!coda!` as `to_coda`.
   - Specs to update: `abc/decoration_mapper_spec.rb:49`, `abc/parser_spec.rb:626`, `header_spec.rb` if it pins `P:` raising.

5. **ABC writer: styles, repeats, endings, parts, navigation**
   - New `BarLineWriter` writes bar N's closing token from bars N and N+1: `::`, `:|`, `|:`, else `||`/`|]`/`.|`/`|`; a regular last bar gets `|]`; then `[1` or `[1,2` when bar N+1 starts an ending. A body starting with a repeat begins `|:`.
   - Rewrite `Writer#body_lines` so each bar chunk knows its bar number.
   - Before the closing token: `!fine!`, `!dacoda!`, then the jump. Before the opening barline: `!segno!`, `!coda!`. `[P:B]` right after the opening barline.
   - Remove the "repeat barlines and voltas are deliberately not rendered" comment; update `abc/writer_spec.rb:22`.
   - A play count above 2 is written as `:|` (lossy).

6. **LilyPond writer**
   - New `BarMarkWriter` (`module_function`, like `mark_writer.rb`). Opening: `\mark "B"`, `\segnoMark 1`, `\codaMark 1`. Closing: `\fine`, `\jump "To Coda"`, `\jump "D.S. al Coda"`, `\bar "||"`, `\bar "|."`, `\bar "!"` (dashed), `\bar ";"` (dotted), and `\bar "|."` on a regular last bar.
   - `VoiceWriter#bar_line` puts opening tokens first and closing tokens before the bar check, in every voice line but not silent or Dynamics lines.
   - Oracle: compile a rendered D.S. al Coda score with lilypond 2.26 and grep for warnings; also `\fine` + `\jump` on one bar.

7. **LilyPond reader, including segno and coda**
   - Reading segno and coda is needed for the D.S. al Coda round trip.
   - New `BarMarkReader` with `COMMANDS = %w[bar mark segnoMark codaMark jump fine section sectionLabel]`, dispatched from `MusicReader#read_item_command` and `DynamicsItemReader` (which drops the result). Pushes a `:bar_mark` event through `VoiceStream#mark`.
   - `\mark`: `\default`, number, string, or `\markup` (skipped); `\default`/numbers become letters in LilyPond's sequence (A–Z without I, then AA), counter on `VoiceStream`. `\segnoMark`/`\codaMark`: `\default` or number. `\jump "..."`: `Jump.get`, or `to_coda` for "To Coda"; other text skipped. `\sectionLabel` is a rehearsal mark. `\section` is double. `\bar`: `"||"`, `"|."` (implied at end), `"!"` dashed, `";"` dotted; other types skipped.
   - `EventPlacer#apply_marker`: opening marks at a bar start go on that bar; closing marks at a bar start go on the previous bar; mid-bar marks skipped; a trailing opening mark dropped; a conflicting value raises `ParseError`, as `apply_change` does.
   - Remove `bar` and `mark` from the unsupported list at `lily_pond/document_reader_spec.rb:359`; `\repeat` stays unsupported.

8. **MusicXML writer: barlines, repeats, endings, navigation**
   - New `BarlineWriter`: left barline for repeat or ending start (`heavy-light`, `<ending number="1" type="start">1.</ending>`, `<repeat direction="forward"/>`); right barline `light-light`, `light-heavy` (final, regular last bar, repeat end), `dashed`, or `dotted`; ending `stop` with a repeat end, else `discontinue`; `<repeat direction="backward"/>` with `times` only above 2. Children in schema order: bar-style, ending, repeat.
   - New `NavigationWriter`: opening `<rehearsal>`, `<segno/>` + `<sound segno="segno1"/>`, `<coda/>` + `<sound coda="coda1"/>`; closing `<words>` with `<sound tocoda>`, `<sound fine="yes"/>`, `<sound dalsegno>`, or `<sound dacapo="yes"/>`, text escaped through `XmlText`.
   - `PartWriter#measure_lines` order: left barline, attributes, part directions, opening navigation, content, closing navigation, right barline. Written to every part.

9. **kern: `||` and section labels**
   - `BarlineReader::Barline` gains `style`: `||` double; `|!` without colons, or `==`, final. `BarClock#mark_repeats` records the completed bar's style; `FlowBuilder#mark_repeats` (renamed `mark_bars`) applies it, omitting `:final` on the last bar.
   - `InterpretationReader.classify` maps `*>Label` to `[:section, label]`; expansion lists still read as nil. At a downbeat it sets `rehearsal_mark`; before the first barline it waits for bar 1; mid-bar it is dropped (not via `at_downbeat`'s raising path).
   - `WrittenBars#barline` appends `||` or `|!` from the previous bar's style (repeat styles win); `final_barline` stays `==`. `InterpretationRows#changes` writes `*>B` across all spines; spaces become `_` if the lexer splits on them.
   - Extend `spec/support/kern_round_trip.rb` with a `"bar_markings"` key; `kern_corpus_spec.rb` must stay green.

10. **Cross-format D.S. al Coda fixtures and CHANGELOG**
    - New `spec/support/navigation_fixtures.rb` built with `ABC.parse`:
      - A: `[P:A] C D E F | !segno! G A B c |[P:B] d c B A !dacoda!| G F E D !D.S.alcoda!|| !coda! C E G c |]`, order `[1, 2, 3, 4, 2, 3, 5]`.
      - B: a `|: … [1 … :|[2 …` fixture ending with D.C. al Fine.
    - Round trips: ABC (A and B); LilyPond (A only) asserting the same markings, the same `performance_order.map { [it.number, it.pass] }`, and `render(parse(render)) == render`; Flow JSON; MusicXML element assertions; kern `||` and `*>A`. kern has no dashed or dotted barline; those write as `|`.
    - CHANGELOG Unreleased: bar markings and `performance_order`; ABC and MusicXML write repeats and endings; LilyPond and MusicXML write a final barline; ABC accepts `P:` and navigation decorations, LilyPond accepts `\bar` and `\mark`; an older gem reading a new schema-5 document drops the new bar fields.
    - Run `bundle exec rake validate`.

### Testing Strategy

- `performance_order`, from bars alone: the story's example; no markings; `|: :|` and a repeat played 3 times; 1st/2nd endings and `[1,2]`/`[3]`; `A :| B :|` with no `|:`; D.C. over a repeat; D.S. al Coda with two coda signs; plain D.C. stopping at Fine; Fine or To Coda before the jump ignored; Fine on the last bar; pickup bar with D.C.; the jump bar replayed and not retaken; one spec per `ArgumentError`.
- Readers skip valid notation they can't hold: ABC `P:` header, LilyPond `\bar ":|."`, kern mid-bar label, LilyPond `\mark` inside a tie and after the last note.
- Writers: assert tokens and elements, never stdout; compile LilyPond output with 2.26.
- Round trips: step 10, plus the kern corpus.

### Risks and Open Questions

- More than one jump raises in v1. Signs are lenient: last segno before the jump, first coda after the To Coda.
- Only ABC (`|]`) and kern (`==`) write a final barline today; adding it to LilyPond and MusicXML, and repeats to ABC and MusicXML, changes many writer specs mechanically.
- ABC play counts above 2 are written as `:|`, read back as 2 unless numbered endings are present.
- kern `*>A` labels in chorales with expansion lists are sections, not printed marks; the kern corpus output will grow.
- `!D.S.alcoda!` and its family are abcm2ps/abc2svg extensions, not ABC 2.1.
- MusicXML has no reader, so it is checked element by element.
- A double barline does not mark an implied repeat start; barline styles stay visual.
