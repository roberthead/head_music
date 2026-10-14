<!--
metadata:
  created_at:   2026-09-27T15:48:57-07:00
  activated_at: 2026-10-13T20:31:33-07:00
  planned_at:   2026-10-14T07:39:58-07:00
  finished_at:
  updated_at:   2026-10-14T08:31:29-07:00
-->

# Story: Hairpins

## Summary

AS a developer or researcher using HeadMusic

I WANT voices and parts to hold crescendo and diminuendo hairpins

SO THAT dynamic shape survives import alongside the levels it runs between

Split from [Spans Across Notes](../done/spans-across-notes.md), whose span model this story extends.

## Background

| Concept | ABC | LilyPond | MusicXML | kern |
|---|---|---|---|---|
| Crescendo, diminuendo | `!<(!` … `!<)!`, `!crescendo(!` … | `\<` … `\!`, `\>`, `\cresc`, `\dim` | `<wedge>` | `<`, `>`, `(`, `)`, `[`, `]` in `**dynam` |

- ABC's `DecorationMapper` and LilyPond's `MarkReader` recognize hairpins and drop them, in a voice and inside `\new Dynamics`. LilyPond's `\cresc` and `\dim` are dropped too, and `\crescTextCresc`-style styling commands raise `UnsupportedFeatureError`.
- kern's `DynamicReader` strips hairpin marks and reads the level left in the token, so `p<` reads as *p*.
- Hairpins live on a voice or a part, as dynamic levels do: on a voice when written beside its notes (ABC, MusicXML), on the part when written in a shared line (LilyPond `\new Dynamics`, kern `**dynam`).
- Once a voice can hold a hairpin, the four slur writers would print it as a slur (ABC, MusicXML) or raise `KeyError` (kern and LilyPond `SpanMarks`), since each takes every span on a voice for a curve.
- The commonest hairpin ends where the music ends, on the downbeat after the last written bar, which the prerequisite's preflight refuses for a level.
- LilyPond drops a voice level in a bar where that voice has only a whole-bar rest.

## Acceptance Criteria

### Model and JSON

- [ ] `crescendo` (aliases `cresc`, `hairpin_crescendo`) and `diminuendo` (aliases `decrescendo`, `decresc`, `dim`) are `SpanKind` rows named in every locale, and no writer prints a hairpin as a slur or raises `KeyError`
- [ ] `Part#add_span` holds hairpins; a part hairpin may start and end at any position, as a `DynamicEvent` may
- [ ] A voice hairpin's ends may sit at any position, including inside a note, on a tied note's later link, or where the music ends
- [ ] `spans_at` includes the part's hairpins; a hairpin ends at a position rather than covering a note, so where a crescendo ends and a diminuendo begins, only the diminuendo is in force
- [ ] `add_span` raises `ArgumentError` naming both hairpins when two hairpins of one owner overlap; touching hairpins are kept; a voice hairpin may overlap its part's, and different voices' hairpins may overlap
- [ ] A part crescendo from 3:1 to 5:1 in four bars of 4/4 leaves `latest_bar_number` and `last_sounding_bar_number` at 4
- [ ] Flow JSON writes a part's `"spans"` after `"dynamic_events"` within schema 5; a bad part span raises naming its path, such as `parts[0].spans[1]`

### Writers

- [ ] A hairpin ending where the last written bar ends is written in every format (ABC `!<)!y`, LilyPond `<>\!`, kern `[[`/`]]`, MusicXML a wedge stop after the last note); a level or hairpin start there is refused
- [ ] A hairpin start or end outside the written bars raises a `RenderError` naming the mark and position, such as "the crescendo end at 6:1:000 falls after the music ends in bar 4"
- [ ] At one position, every writer writes hairpin ends, then levels and accents, then starts
- [ ] LilyPond and kern write a hairpin with a level or accent strictly inside it as touching pieces that meet there; ABC and MusicXML write it whole
- [ ] ABC and kern raise a `RenderError` naming both hairpins when hairpins from different owners of one written line overlap; the same hairpin from several owners is written once
- [ ] ABC writes hairpin start and end marks through `PositionMarks`
- [ ] LilyPond writes `\<`, `\>`, and `\!` in voices (through `TimedMarks`) and in `\new Dynamics` (the spacer grid in `RenderPlan#dynamics_bar`)
- [ ] kern writes hairpin marks in `**dynam`, joined with a level on one row (`]p<`) so no mark is lost, on `DataRows`' null-row grid; accents still outrank levels
- [ ] MusicXML writes `<wedge>` through `DirectionWriter`, numbered in document order, and `Divisions` counts hairpin starts and ends
- [ ] LilyPond writes a voice's marks in a bar where it has only a whole-bar rest

### Readers

- [ ] ABC reads hairpin start and end marks through `DecorationMapper`, pairing them by kind
- [ ] LilyPond reads `\<`, `\>`, and `\!` in voices and in `\new Dynamics` (`PartDynamics`), ending an open hairpin at a level, accent, or new hairpin in its context; it reads `\cresc`, `\dim`, and `\decresc` as hairpins, and skips `\crescTextCresc`-style commands instead of raising
- [ ] kern reads hairpin marks in `**dynam`, timed with `DynamicPlacer`'s even split, pairing them as Verovio does
- [ ] Readers drop unterminated, mismatched, stray, and zero-length hairpins without raising, and every file that imports today still imports

### Tests

- [ ] Round trips assert where each hairpin starts and ends, covering ends on a tied note's later link, on a rest split at a barline, touching on a tied note, in two voices of a grand staff, in a pickup, and at the final barline after full and short bars
- [ ] A seeded random generator in `spec/support/hairpin_generator.rb` round-trips 100 seeds per format, naming the seed on failure, and every LilyPond output compiles under 2.26 with no warnings

## Notes

- Builds on [Place Dynamics Where No Note Starts](../done/place-dynamics-where-no-note-starts.md), whose mechanisms place a mark at any position in each format; hairpin starts and ends go through them:
  - `PreflightChecks#ensure_timed_marks_within_music` and its `timed_marks` list refuse a mark outside the written bars. A hairpin ending exactly where the music ends must be allowed, though a level there is refused.
  - ABC `PositionMarks` puts a mark on the note that attacks there, on an overlay of invisible rests (`& x2 !<)!x6`) inside a note or rest, or on a trailing `x` after the music.
  - LilyPond `TimedMarks` puts a mark on the link that attacks there, `\after D` inside a link, or a trailing spacer after the music. A level under `\after` at the very end of the music prints "programming error: no broken bound"; `\after 1 \!` compiles cleanly, and the plan uses `<>\!` there. `lily_pond/duration_reader.rb` refuses a zero-length `s1*0`, and `\after` inside `\new Dynamics` still raises a `ParseError`.
  - kern's null-row grid, its `ryy` fill after the music (`WrittenBars#dynamic_after_music?`), and the pickup's leading rest (`WrittenBars#pickup_onset`) look only at dynamic events, and must count hairpin marks.
  - ABC and kern refuse different levels at one position (`ensure_one_level_per_position`); hairpins get the same treatment through `ensure_one_hairpin_at_a_time`.
- A level and a hairpin mark joined in one kern token (`p<`, `]p<`, `[mf<`, `f[`, `[>`) were confirmed with Verovio 6.3.0's Humdrum importer only. So was the doubled close `[[`/`]]`, which Verovio reads as ending where its row ends; other Humdrum tools may read it as a plain close, a beat early.
- Part hairpins must not add bars to `Flow#latest_bar_number` or a writer's bar numbering.
- Think in document order, not musical time, wherever a hairpin's ends share a tied or split note, or sit in different voices of a part: every bug the slurs review found was there. A random round-trip generator over tied notes found what the fixtures missed.
- **Decisions** (Rob, 2026-10-14):
  - A level or accent strictly inside a hairpin splits it into touching pieces in LilyPond and kern, whose renderers otherwise cut or drop it; ABC and MusicXML write it whole.
  - kern ends a hairpin at the final barline with a doubled close (`[[`, `]]`), and its reader pairs as Verovio does: `<` only with `[`, `>` only with `]`, and a level, accent, or new opener before the close drops the open hairpin.
  - A voice hairpin may overlap its part's in the model; ABC and kern, with one line each, refuse it when writing.
  - LilyPond's `\cresc`, `\dim`, and `\decresc` read as hairpins and write back as `\<` and `\>`, losing the text look. `diminuendo` is the catalog's primary key.
- **Settled while building:**
  - LilyPond reads a hairpin end after all the written time, spacers included, as the final barline, since `<>\!` after a short final bar's last note is how the writer ends one there and how LilyPond draws it. An end where a short bar's music stops is written on a spacer that fills the bar (`e'4 s4\!`), so the two never meet.
  - MusicXML writes a measure's part directions before its voices, so where a part hairpin starts as a voice hairpin stops, the part's start comes first in the file. They take different numbers, so readers pair them correctly; moving part directions after the voices would have changed where every part dynamic is written.
  - LilyPond warns "crescendo too small" for a quarter-note hairpin starting at an accent at default spacing. That is page room, not notation, so the hairpin compile check widens spacing (`common-shortest-duration` 1/64); the writer and `compile_warnings` are unchanged.
  - ABC and LilyPond round trips leave out pickups: both write a full-length bar 0 as an ordinary first bar, which reads back as bar 1 and moves every position, notes included. That predates this story.
  - kern refuses three seeds in four of the two-voice generator, whose voices and part overlap; every seed also round-trips with its hairpins on one line across two voices.
  - ABC reads a second start of the same kind before an end as replacing the first, which is dropped as unterminated.
- **Deferred**, each for a reason in the code:
  - kern textual "cresc.": a `**dynam` text token has no end mark, so reading it as a span would invent its end.
  - Niente (`o<`): `Span` holds only kind, from, and to, and ABC cannot spell it; `o<` reads as a crescendo.
  - MusicXML reading: the gem has no MusicXML reader.
  - Style use of hairpins: nothing under `lib/head_music/style` reads dynamics.
  - `\after` inside `\new Dynamics`: the writer never needs it, since the spacer grid and `<>\!` reach every binary offset.
  - ABC pickups: the ABC reader reads no pickup, for notes either.

## Implementation Plan

### Overview

Hairpins become two `SpanKind` rows, `crescendo` and `diminuendo`, anchored at `positions`, ending at their `to` (extent `to_position`), and held by a voice or a part. Every start and end goes through the prerequisite's position mechanisms. Each format gains one form for an end at the final barline: ABC `!<)!y`, LilyPond `<>\!`, kern `[[`/`]]`, and a MusicXML `<wedge type="stop">` with `<offset>`. A shared base (model, JSON, preflight, a hairpin-splitting helper, fixtures, and a seeded generator) lands first on the story branch; then five worktrees run in parallel by format, as the prerequisite did.

### Model decisions

- **Anchor:** `positions` for voice and part. The commonest end has no voice event under it, and every writer now places marks inside notes.
- **Overlap:** `Spans#add` refuses two overlapping hairpins of any kinds in one owner, naming both; touching is allowed, since a hairpin covers `from` up to but not including `to`. A voice and its part, and different voices of a part, may overlap; ABC (`ensure_one_hairpin_at_a_time(owners, line:)`) and kern refuse it when writing, naming both, and write the same hairpin from several owners once.
- **Extent and `spans_at`:** `extent: to_position`, so `Voice#span_end` returns `span.to`. Move the innermost-first sort out of `Spans#covering` into `Spans.innermost_first`; `Part#spans_at` is `covering { |span| span.to }`; `Voice#spans_at` merges its own spans with `part.spans_at`. `Voice#spans` stays the voice's own, and `dynamic_at` ignores hairpins.
- **End at the final barline:** `Flow#final_barline_position`, the downbeat after `last_sounding_bar_number`. A level or start must lie within the written bars; an end may sit anywhere up to and including that position. Writers that group marks by bar map bar N+1, offset 0, to the end of bar N.
- **Order at one position, in every writer:** ends, then levels and accents, then starts (`]p<`, `\!\p\<`, MusicXML stop, level, start). LilyPond always writes `\!`.

### Reader rules

- **LilyPond:** a level, accent, `\<`, or `\>` in the same context ends an open hairpin; at one moment, ends come before starts in any written order. `\cresc`, `\dim`, `\decresc` read as hairpins, and `\endcresc`, `\enddim`, `\enddecresc` like `\!`.
- **kern (Verovio):** `<` pairs only with `[`, `>` only with `]`; a level, accent, text, or new opener before the closer drops the open hairpin; a wrong closer is ignored.
- **ABC (abcm2ps):** explicit pairing by kind; neither a level nor a new start ends an open hairpin.
- **Every reader** drops unterminated, mismatched, stray, and zero-length hairpins, and catches `add_span`'s `ArgumentError`. `articulations_ornaments_dynamics.krn` still reads no hairpin.

### Steps

Each step is one commit. Run the touched specs, then `bundle exec rake` and `bundle exec rubocop -a`. Every dynamics and span bullet in CHANGELOG Unreleased is unreleased, so steps amend those bullets as additions, without **Breaking.**

#### Shared base (sequential, on `story/hairpins`)

1. **Hairpin kinds, and slur writers kept to curves.** `family: curve | hairpin` on every `span_kinds.yml` row, the two hairpin rows, `SpanKind#hairpin?`/`#curve?` delegated from `Span`, locale names (ru: крещендо, диминуэндо), and `.select(&:curve?)` in `abc/slur_writer.rb`, `music_xml/slur_numbers.rb`, `kern/span_marks.rb`, `lily_pond/span_marks.rb`. Specs: `span_kind_spec.rb`, and a "writes no slur and does not raise" example in each writer spec.
2. **Part spans, overlap, `spans_at`, `Flow#final_barline_position`.** `content/spans.rb`, `part.rb`, `voice.rb`, `flow.rb`. Specs: `spans_spec.rb`, new `part_spans_spec.rb`, `voice_spans_spec.rb` (merge order, touching, the bar pin). Pause here so the model API can be checked.
3. **JSON for part spans.** `Part#to_h`, `hash_deserializer.rb`, `deserializer.rb`; schema stays 5. Spec: `flow_serialization_spec.rb` with path errors.
4. **Preflight for hairpin starts and ends.** `timed_marks` gains starts, a new `timed_ends` follows the end rule, and `ensure_one_hairpin_at_a_time`. Spec: a four-format table in `preflight_checks_spec.rb`.
5. **`HairpinSegments`.** `lib/head_music/notation/hairpin_segments.rb`: given hairpins and cut positions, the touching pieces.
6. **Fixtures, expectations, generator (specs only).** Fixtures in `spec/support/marking_fixtures.rb`: `hairpin_ending_on_tied_note`, `hairpin_starting_on_split_note`, `touching_hairpins_on_tied_note`, `hairpin_on_split_rest`, `hairpins_in_two_voices`, `hairpin_under_held_note`, `part_hairpin`, `single_voice_part_hairpin`, `hairpin_to_music_end`, `hairpins_after_short_final_bar`, `hairpin_in_pickup`, `hairpin_in_voice_that_ends_early`, `level_inside_hairpin`. Helpers `hairpin_summary`, `expect_same_hairpins(original, round_tripped, merged_into:, segmented_by:)`, `expect_same_hairpin_in_force`, and `span_summary` filtered to curves. Generator `spec/support/hairpin_generator.rb`, seeded, `SEEDS = 1..100`, `ENV["HAIRPIN_SEEDS"]` for wider runs, options `one_line:` and `pickup:`.

#### Parallel worktrees, all from the commit after step 6

| Worktree | Steps | Files owned |
|---|---|---|
| ABC | 7, 8 | `notation/abc/*`, ABC specs |
| MusicXML | 9, 10, 11 | `notation/music_xml/*`, `spec/support/music_xml_helpers.rb`, MusicXML specs |
| LilyPond reader | 12, 13 | `mark_reader`, `voice_stream`, `event_placer`, `music_reader`, `music_item_reader`, `dynamics_item_reader`, `part_dynamics`, their specs |
| LilyPond writer | 14, 15, 16 | `timed_marks`, `render_plan`, `voice_writer`, `writer`, `spec/support/lily_pond_helpers.rb`, `lily_pond/writer_spec.rb` |
| kern | 17, 18, 19 | `notation/kern/*`, kern specs, a new `hairpins.krn` fixture |

7. **ABC reader.** The eight hairpin names move from `DROPPED_NAMES` to `NAMED`; `Decoration#hairpin?`, and `#positional?` covers hairpins; rests and tie merges keep them. New `abc/hairpin_marks.rb` records marks and pairs them by position, ends first, in `Parser#finish`. Waiting marks settle at the cursor in `pause_notes` and `end_voice` before `reject_dangling_decorations`, so `!<)!|` does not raise.
8. **ABC writer.** `PositionMarks` adds the voice's and part's hairpin marks, sorted ends, levels, starts; `BarWriter#trailing` writes the `x` fill and `!<)!y`; `validate!` calls `ensure_one_hairpin_at_a_time`. Round trips with `merged_into: "voice 0"`, a render-parse-render stability check, and generator seeds with one voice, one line, no pickup.
9. **MusicXML `Divisions` counts hairpin starts and ends** (`timed_mark_denominators`), and the offset error names the mark.
10. **`DirectionPlan` refactor**, with no change to output: per bar, in document order, the part's slot, each voice's segments, whole-measure-rest and trailing slots, and a closing slot at the final barline. Existing direction specs pass unchanged.
11. **MusicXML wedges.** `music_xml/wedge_numbers.rb` walks the plan in document order (a stop frees its number, a start takes the lowest free one, a seventeenth open raises), precomputed in `RenderPlan`. Specs: `wedge_numbers_spec.rb`, XPath checks, a `wedge_summary` helper over every fixture and generator seed.
12. **LilyPond reader, voices.** `Marks#hairpin_marks`; `\cresc`, `\dim`, `\decresc` and their `\end…` forms move out of `DROPPED_COMMANDS`; styling commands are skipped; `voice_stream.rb` holds later links' hairpin marks as levels are held; `event_placer.rb` gathers marks from notes, rests, spacers, whole-bar rests, and `\after`, and pairs them in `finish` by time, ends first.
13. **LilyPond reader, `<>` and part hairpins.** `<>` is a zero-length marker in `music_item_reader.rb#read_chord` and `dynamics_item_reader.rb`; `part_dynamics.rb` pairs per Dynamics stream.
14. **LilyPond writer: a voice's marks in bars where it has no events**, on the whole-bar rest (`R1*4/4\!` or `\after 2 \! R1*4/4`). CHANGELOG (Fixed).
15. **LilyPond writer, voice hairpins.** `TimedMarks` from levels plus `HairpinSegments` pieces cut at the voice's levels and accents; `<>\!` before the closing tokens for an end at the final barline. Extend `MARK` and `SIMPLE_TOKEN` in `spec/support/lily_pond_helpers.rb` first.
16. **LilyPond writer, part hairpins.** `dynamics_bars` and `writer.rb` include part hairpins cut at part levels; a part with hairpins and no levels gets a `\new Dynamics`.
17. **kern reader.** `dynamic_reader.rb` returns hairpin marks with their track, including `[[`/`]]` and `o<`; `dynamic_placer.rb` times them, a doubled closer taking the next row's time, and pairs per track by Verovio's rules into `part.add_span`, adding an identical hairpin from two spines once. A new `hairpins.krn` fixture, checked in Verovio.
18. **kern writer.** `dynamic_fields.rb` writes closes, value, opens, from pieces cut at the part's levels and spine accents and merged across owners; `data_rows.rb` adds hairpin offsets to the grid and puts a final `[[` on the last row or one extra null row; `written_bars.rb` counts hairpin marks except an end at the final barline; `preflight.rb` refuses overlapping pieces and counts hairpins in `ensure_dynamics_have_voices`.
19. **kern round trips** over the fixtures and generator seeds, merged into the part; a seed with overlapping pieces expects `RenderError`. Re-check `hairpins.krn` and sample output in Verovio; the `KERN_CORPUS` sweep still passes.

#### Coordinator, after cherry-picking

20. **LilyPond round trips and compile check**: fixtures and generator seeds, owners kept; seeds rendered into one book and compiled once, with `compile_warnings` empty.
21. **Grading guard**: a voice and a part hairpin in `guide_marked_flow_grading_spec.rb`'s marked copy.
22. **Record the decisions** and fold the held-back CHANGELOG lines into Unreleased.

### Testing Strategy

- Every round trip asserts `[owner, kind, from, to]` through `expect_same_hairpins`, and every voice event through `expect_same_voice_events`. Where a format merges owners or splits a hairpin, the expectation uses `merged_into:` or `segmented_by: HairpinSegments`, and `expect_same_hairpin_in_force` shows the kind in force is unchanged everywhere.
- Fixtures cover the places the slur review found every bug: ends on a tie's later link, starts on a split note's later piece, touching on a tied note, ends on a split rest, cross-voice ends whose wedge numbers differ by document order, ends at the final barline after full and short bars, a voice that ends early, and a pickup.
- The generator runs 100 seeds per format in the suite (ABC: one voice, one line, no pickup; kern expects `RenderError` for overlapping pieces). Before landing, run `HAIRPIN_SEEDS=1..2000` once per format.
- LilyPond 2.26 `compile_warnings` empty for every new output; Verovio by hand for kern.
- Each new spec is run against the old code (files copied aside, not stashed). No console assertions.

### Risks

- `[[` is a Verovio and humlib convention; the fallback is an invisible grace row (`qryy [`), which needs a fix to the reader's null-token rule.
- ABC rendering of `!<)!y` and of hairpin marks on an overlay `x` is unverified.
- Split-on-write means LilyPond and kern round trips compare pieces, so the model gains touching hairpins on import.
- Between step 1 and each writer step, writers omit hairpins; acceptable only because nothing is released in between.
- Step 10 touches every MusicXML dynamic path, with only the existing direction specs as its net.
- The ABC reader pairs hairpins at `finish`, so spans appear only after the whole tune is parsed.
