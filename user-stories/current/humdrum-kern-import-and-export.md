<!--
metadata:
  created_at:   2026-09-24T18:58:30-07:00
  activated_at: 2026-09-24T19:27:11-07:00
  planned_at:   2026-09-24T19:56:33-07:00
  finished_at:
  updated_at:   2026-09-24T20:08:13-07:00
-->

# Story: Humdrum **kern Import and Export

## Summary

AS a developer or researcher using HeadMusic

I WANT to read and write Humdrum `**kern` files as `HeadMusic::Content::Flow`s

SO THAT I can analyze the large scholarly corpora encoded in kern — the Bach chorales, Josquin, Palestrina, and the KernScores library — with the gem's analysis and style guides

## Background

[Humdrum](https://www.humdrum.org/) is a text-based representation for computational musicology. A `**kern` file lays voices out in tab-separated spines, one column per voice, one row per time slice. Each token combines a duration and a pitch (`4cc#` is a quarter C♯5; `8.GG` a dotted eighth G2). Interpretation records (`*k[f#]`, `*M3/4`, `*clefG2`) carry key, meter, and clef, and `=` rows mark barlines.

Kern is the most widely used format for the repertoire the Style guides grade. Reading it gives the counterpoint work validation at corpus scale, beyond the Jeppesen examples that [Sixteenth-Century Style](../backlog/sixteenth-century-style.md) encodes in ABC. Writing it lets the gem's output flow into the Humdrum toolkit and Verovio.

This story follows the entry-point shape of ABC and LilyPond: `HeadMusic::Notation::Kern.parse` and `.render`, with a `Flow#to_kern` delegate.

## Example

```ruby
kern = <<~KERN
  **kern	**kern
  *M4/4	*M4/4
  *k[]	*k[]
  =1	=1
  2C	2e
  2G	2d
  =2	=2
  1C	1c
  ==	==
  *-	*-
KERN

flow = HeadMusic::Notation::Kern.parse(kern)
flow.voices.length # => 2
flow.to_kern       # => the same spines back
```

## Acceptance Criteria

### First step: players in a standalone flow

- [ ] A part in a flow with no project can carry a `Player` that has no project
- [ ] `Flow#to_h` writes a part's player name when it has one, and `Flow.from_h` restores it as a projectless `Player`; a part with no player serializes as it does now
- [ ] Flow JSON records part players as a sparse `"part_players"` list with a per-part `"player"` index, within schema 4; project documents leave both out, and the project's player indexes are the source of truth
- [ ] `Project#add_flow` adopts a part's existing player into `project.players` when the project does not own it yet, rather than leaving it orphaned; adopting the same flow twice still changes nothing
- [ ] Two parts in one flow that share a player object still share one player after adoption and after a Flow JSON round trip
- [ ] A project saved and read back keeps adopted players, and layouts can select them
- [ ] Existing schema-4 documents read unchanged

### Kern: entry points and structure

- [ ] `HeadMusic::Notation::Kern.parse(string)` returns a `HeadMusic::Content::Flow`
- [ ] `HeadMusic::Notation::Kern.render(flow)` and `Flow#to_kern` return a `**kern` string
- [ ] Each `**kern` spine becomes a voice in a part of its own; `**dynam`, `**harm`, and other non-kern, non-lyric spines are skipped on import
- [ ] Kern spines are read left to right as bass to top; `flow.parts` are ordered top-down, and the writer reverses them
- [ ] Rows whose field count does not match the active spines, input that is not UTF-8, a missing `*-`, and files with no `**kern` spine raise `ParseError` with a line number
- [ ] Spine splits and joins (`*^`, `*v`, `*x`, `*+`) raise `UnsupportedFeatureError` in any spine, including skipped ones

### Kern: tokens

- [ ] Pitch tokens (letter case and repetition for register, `#`/`-`/`n` accidentals) map to the right pitches both ways
- [ ] Duration tokens, including dots, `0`, and `00`, map to rhythmic values both ways
- [ ] Tuplet durations (`3`, `6`, `12`, non-dyadic `%`) raise `UnsupportedFeatureError` naming the token
- [ ] Rests (`r`), chords (space-separated tokens in one cell), and ties (`[`, `_`, `]`) map both ways
- [ ] Ties across barlines import as one tied placement, and the writer splits any placement that crosses a barline into tied tokens
- [ ] Chords whose notes have different durations, and chords tied only in part, raise `UnsupportedFeatureError`
- [ ] Unclosed ties, a stray `]`, and ties between different pitches raise `ParseError`
- [ ] Fermatas, beams, stems, slurs, articulations, and grace notes are dropped; any other unrecognized signifier raises `UnsupportedFeatureError`

### Kern: interpretations and records

- [ ] `*k[...]` maps to the key signature and `*G:`/`*a:`/`*d:dor` to its tonal context, independently of each other, including mid-piece changes
- [ ] `*M` maps to the meter, including mid-piece changes
- [ ] `*MM` is read as quarter notes per minute, and other beat values are converted on export
- [ ] `*clef` interpretations (`G2`, `F4`, `Gv2`, `C1`–`C4`) set the part's clef
- [ ] `*Isoprn`, `*Ialto`, `*Itenor`, `*Ibass` map to catalog instruments; unknown codes leave the instrument nil
- [ ] A spine's display name (`*I"Soprano`) becomes its part's player name on import, and a part's player name is written as `*I"` on export; two parts sharing a player write the same name, and on import every spine gets its own player
- [ ] Transposed spines (`*ITr`, `*Trd`) raise `UnsupportedFeatureError`
- [ ] Interpretations that disagree across kern spines on one row raise `UnsupportedFeatureError`
- [ ] `!!!OTL`, falling back to `!!!OTL@@xx`, becomes the flow name; other reference records not listed below (including `!!!!` universal records) and all `!`/`!!` comments are dropped

### Kern: work citation

- [ ] When the file has a title, import builds a `Work` on the flow: title from `!!!OTL` (or `!!!OTL@@xx`), `catalog_number` from `!!!SCT`, and `year` from the first year in `!!!ODT`
- [ ] `!!!COM` in sort order (`Bach, Johann Sebastian`) becomes a composer `Credit` whose `Person` has full name `Johann Sebastian Bach` and that sort name; a name without a comma is taken as both
- [ ] `!!!CDT` birth and death years (`1685/02/21/-1750/07/28/`) set the composer's `birth_year` and `death_year`; a date the reader cannot parse is ignored rather than raised
- [ ] Several `!!!COM` records become several composer credits
- [ ] A file with `!!!COM` but no title keeps the composer as the flow's composer string, since a `Work` requires a title
- [ ] The writer emits `!!!COM` (sort name), `!!!CDT` (years), `!!!OTL`, `!!!SCT`, and `!!!ODT` from the flow's work, and falls back to the flow's name and composer string when it has no work

### Kern: bars

- [ ] Barline rows (`=N`) establish bar numbers; an unnumbered `=` continues the count
- [ ] Notes before the first numbered barline form a pickup bar (bar 0 when the first barline is `=1`), padded with a leading rest; the writer leaves the padding out
- [ ] A short final bar reads without error
- [ ] A bar that is too long, or kern spines that disagree on a bar's length, raise `ParseError` naming the bar and line; a short bar in the middle of the piece raises `UnsupportedFeatureError`
- [ ] Repeat barlines (`!|:`, `:|!`) set bar repeat flags; `*>` labels and expansion lists are ignored

### Kern: lyrics

- [ ] A `**text` or `**silbe` spine attaches its syllables to the nearest `**kern` spine on its left; successive text spines for one kern spine become verses 1, 2, …
- [ ] Kern hyphenation (`mei-` / `-nes`) sets `hyphen_after` on the syllable before the break
- [ ] A syllable with no note under it raises `ParseError`
- [ ] The writer emits a `**text` spine to the right of each sung part, one per verse

### Kern: writer errors

- [ ] The writer raises `RenderError` for a part with more than one voice, an empty flow, unspellable or unpitched notes, and `transposed: true` with a transposing instrument

### Notes that cross a barline in MusicXML and LilyPond

- [ ] The MusicXML and LilyPond writers render a placement that crosses a barline as tied notes, one per bar, instead of raising `RenderError`
- [ ] The splitting logic is shared by the ABC, kern, MusicXML, and LilyPond writers, rather than copied into each
- [ ] A fourth-species flow, with ties across every barline, renders to MusicXML and LilyPond, and LilyPond compiles it when the binary is installed
- [ ] The hand-encoded chorale fixture, imported from kern, renders to MusicXML and LilyPond

### Kern: round trip and corpus

- [ ] Parsing the writer's output of a parsed file gives an equal `to_h` (the reader is idempotent)
- [ ] For arbitrary flows, render then parse gives an equal normalized `to_h`, excluding voice role, comments, citations, and beam breaks
- [ ] A hand-encoded fixture with a pickup, ties across barlines, a repeat in the middle of a bar, SATB `*I"` names, `*MM`, a tonal designation, and a lyric spine parses end to end
- [ ] With `KERN_CORPUS` pointing at a local clone of the Bach chorales, every chorale parses except the known ones with short bars in the middle of the piece
- [ ] Maintains 90%+ test coverage

## Notes

- Kern prints spines lowest voice first (the bass is the leftmost column). Import and export both respect that order.
- Grace notes (`q`), ornaments, articulations, beams (`L`, `J`), and stem directions are ignored on import and omitted on export in v1.
- A repeat mark in the middle of a bar is recorded on its whole bar, as ABC does, so a repeat's extent is approximate on export. The notes stay correct.
- Kern has no field for voice role, so a re-imported counterpoint flow has no `cantus_firmus_voice`.

## Decisions

- **The module is `HeadMusic::Notation::Kern`** (decided 2026-09-24). Other Humdrum representations such as `**mens` would get modules of their own if they come.
- **Import returns a `Flow`** (decided 2026-09-24), as ABC and LilyPond import do. Players are project-level chairs that last across flows, and a kern file is one flow. A spine's instrument code maps to its part's `instrument`, and `Project#add_flow` mints players named for those instruments when a caller wants them.
- **A part in a standalone flow may carry a player** (decided 2026-09-24), and that is where a spine's display name (`*I"Soprano`) goes. Until now, readers left `Part#player` nil by convention. Flow JSON did not save it, and `Project#add_flow` kept it without adding it to `project.players`, so the name was lost either way. Fixing that is this story's first step. It also opens the way for ABC `V:` names and LilyPond `\new Staff = "..."` names to become players later.
- **Part players stay within schema 4** (decided 2026-09-24). They follow the precedent of `work`/`source`, which were added as optional keys (`lib/head_music/content/flow/hash_deserializer.rb:36-43`). A bump to 5 would make every existing document unreadable, because the version check is exact (`flow/deserializer.rb:30-35`). The key is `part_players`, because `Project#to_h` already merges `"players"` into each flow hash (`project.rb:111`).
- **Lyrics are in scope** (decided 2026-09-24), both directions.
- **Spine splits and tuplets raise in v1** (decided 2026-09-24). A split is a second voice that exists for only part of the piece, which every writer's continuity check rejects unless it is padded with phantom rests. A tuplet needs a tuplet ratio that `RhythmicValue` does not have, which would be a change to the core duration model.
- **The chorale corpus is not vendored** (decided 2026-09-24). `craigsapp/bach-370-chorales` is CC BY-NC-SA 4.0 and this repo is MIT. The committed fixture is hand-encoded, and the real corpus runs only when `KERN_CORPUS` points at a local clone.
- **One story, not two** (decided 2026-09-24). The reader and writer share their token and interpretation tables, and the round-trip criteria need both.
- **Import builds a `Work`** (decided 2026-09-24) from the title, catalog number, date, and composer records, with the composer as a `Person` credit. The writer emits those records back.
- **The MusicXML and LilyPond writers learn to split notes that cross a barline** (decided 2026-09-24), in this story, so an imported chorale renders. Today `ensure_notes_within_barlines` (`lib/head_music/notation/preflight_checks.rb:18-27`) rejects them, which also blocks fourth-species flows and ABC imports with ties across barlines.
- **`Project#add_flow` raises** (decided 2026-09-24) when a part's player belongs to another project, matching the existing check that a flow belongs to one project. The CHANGELOG records it under Changed.

## Open Questions

1. Should `*part`/`*staff` grouping (multi-voice parts, grand staves) be a follow-up story?

## Implementation Plan

Consulted: product-manager and developer, via the story-planner. Load-bearing claims were checked against the code and the upstream repository on 2026-09-24.

### Overview

Parts first get players that survive Flow JSON within schema 4: a sparse flow-level `"part_players"` list and a per-part `"player"` index. `Project#to_h` strips both, so the project's player indexes stay the only source of truth, and `Project#add_flow` adopts those players. Then comes a LilyPond-shaped kern pipeline (Lexer, Document, FlowBuilder, Preflight, Writer) that validates before building and rejects any token it does not recognize.

### Steps

Each step is one commit, with its specs.

1. **Adopt a standalone flow's existing players into the project**
   - `Player#project` becomes an `attr_accessor` (`lib/head_music/content/player.rb:12`), mirroring `Flow#project`.
   - In `Project#add_flow` (`project.rb:62-70`):
     - Before changing anything, raise `ArgumentError` if any part's player belongs to another project. This mirrors the flow check at line 64.
     - A part with no player gets one minted, as today.
     - A part whose player has no project gets `player.project = self`, and the player is appended to `players` only if it is not already there by identity (`equal?`), so a shared player is appended once.
     - Adding the same flow twice still returns early.
   - CHANGELOG, under Changed: `add_flow` now raises for a player that belongs to another project.
   - Update the comment near `references/content-schema.md:87`.
   - Specs: `spec/head_music/content/project_spec.rb`; `spec/head_music/content/player_spec.rb` (`#parts` works after adoption).

2. **Persist part players in Flow JSON (schema 4, additive)**
   - `Flow#to_h` (`flow.rb:163-175`): add a sparse `"part_players" => [{"name" => ...}]` listing the distinct players by identity, in order of first appearance.
   - `Part#to_h` (`part.rb:88-98`): add a sparse `"player" => index`.
   - `HashDeserializer#build_parts` (`flow/hash_deserializer.rb:71-82`): create one projectless `Player` per list entry and pass `player:` to `add_part`. Validate the index through `flow/schema_values.rb`, so a bad index raises `ArgumentError` with its path.
   - `Project#to_h`: strip `"part_players"` and each part's `"player"` before merging the indexes, so project documents stay byte-identical to today's.
   - `Project#adopt_flow_at` (`project.rb:95-103`): assign `part.player = player_index && players[player_index]` for every part, so the index wins.
   - Update the stale comment at `lib/head_music/content/layout/realization.rb:30-31`. Document the keys in `references/content-schema.md`. Add a CHANGELOG line.
   - Specs:
     - `flow_serialization_spec.rb`: a name round-trips; two distinct players with the same name stay distinct; a shared player stays shared; a document without the keys reads; a bad index raises.
     - `project_serialization_spec.rb`: adopted players survive save and read; layouts select them; project documents contain no `part_players`; a document with both forms resolves to the index.
     - `flow_spec.rb`: the keys are omitted when there are no players; the existing `contain_exactly` at `flow_spec.rb:383-386` and `[["voices"]]` at `:402-405` still pass unchanged.

3. **Kern module skeleton**
   - `HeadMusic::Notation::Kern.parse` and `.render(flow, transposed: false)`.
   - `ParseError(message, line_number:, snippet:)`, shaped like `abc.rb:20-29`, plus `UnsupportedFeatureError < ParseError` and `RenderError`.
   - A `Dir[...]` require, and wiring in `lib/head_music.rb`.
   - Blank input raises `ParseError`, as `lily_pond/parse_preflight.rb:16-20` does.
   - Files: `lib/head_music/notation/kern.rb`, `kern/parser.rb`, `spec/head_music/notation/kern_spec.rb`.

4. **Lexer**
   - A `Record` built with `Data.define(:kind, :line, :fields)`. Kinds: universal reference `!!!!`, reference `!!!`, global comment `!!`, local comment `!`, exclusive `**`, interpretation `*`, barline `=`, data.
   - Strip CR.
   - Raise `ParseError` for:
     - input that is not valid UTF-8 (older KernScores files are Latin-1, so this must not escape as an `Encoding::` error);
     - a field-count mismatch, naming the line and both counts;
     - data before the `**` header;
     - a missing `*-`, or content after it.
   - Raise `UnsupportedFeatureError` for `*^`, `*v`, `*x`, `*+`, or a partial `*-` in any spine.
   - Files: `kern/lexer.rb`, `kern/record.rb`, and a spec.

5. **Document**
   - Classify the spines as kern, lyric (`**text`, `**silbe`), or skipped. Raise `ParseError` when there is no kern spine.
   - Collect the citation records: every `!!!COM` in order, `!!!CDT`, `!!!OTL` (or failing that `!!!OTL@@xx`), `!!!SCT`, `!!!ODT`.
   - Everything else is ignored: other reference records, `!!!!` records, `!!`/`!` comments, `*>` labels and expansion lists.
   - Files: `kern/document.rb`, and a spec.

6. **Token readers**
   - Pitch:
     - Register is 3 + repeat count for lowercase and 4 − repeat count for uppercase.
     - Accidentals: `#`, `##`, `-`, `--`, `n`. Mixed letters raise `ParseError`.
     - Build pitches with `Pitch.from_name`, as `lily_pond/pitch_reader.rb:97` does.
   - Duration:
     - Accepted: recip values with dots, `0`, `00`, and dyadic `N%M`, where `DottedDuration.expressible?` allows them (`dotted_duration.rb:37-39`).
     - `3`, `6`, `12` and non-dyadic `%` raise `UnsupportedFeatureError`.
   - Token:
     - Recognized: chords, rests (`r`, `rr`), tie flags `[ _ ]`, null tokens `.`.
     - `q`/`Q` grace notes are dropped.
     - A whitelist of ignorable signifiers is dropped: `L J K k / \ ; ' ~ ^ " ( ) { } < > ? x X y`.
     - Any other letter raises `UnsupportedFeatureError`.
   - Files: `kern/pitch_reader.rb`, `duration_reader.rb`, `token_reader.rb`, and specs.

7. **Interpretation tables (two-way)**
   - Key: `*k[...]` gives the signature's fifths; a non-standard list raises `UnsupportedFeatureError`. `*G:`, `*a:`, `*d:dor` give the tonal context, independently of the signature, matching the timeline's split (`timeline.rb:98-110`).
   - Meter: `*M`. `*met(...)` is ignored.
   - Tempo: `*MM` is quarter notes per minute and may be fractional.
   - Instruments: `*Isoprn`/`*Ialto`/`*Itenor`/`*Ibass` map to `soprano_voice`/`alto_voice`/`tenor_voice`/`bass_voice`; check these against the Humdrum `*I` reference before adding more. `*IC…`, `*IG…` and `*I'…` are ignored. `*ITr…`/`*Trd` raise.
   - Clefs: `G2`, `F4`, `Gv2`, and `C1`–`C4`. Unknown clefs are dropped, which is safe because kern pitch does not depend on the clef.
   - Files: `kern/key_reader.rb`, `meter_reader.rb`, `tempo_reader.rb`, `instrument_codes.rb`, `clef_codes.rb`, and specs.

8. **FlowBuilder core**
   - Build a throwaway flow and raise before returning it (`lily_pond/flow_builder.rb:52-62`).
   - Process row by row, so a change is in force before the bar it governs.
   - Parts:
     - Order: the rightmost kern spine becomes the first part. Every writer treats part order as top-down (`music_xml/writer.rb:92,112`, `lily_pond/writer.rb:74`).
     - `*I"Name` mints a projectless `Player`.
     - Clefs go through `StaffSystem.single_staff(clef:)`, and mid-piece clefs through `change_clef`.
   - Timeline:
     - If the opening signature and designation disagree, raise `UnsupportedFeatureError` (`timeline.rb:34-37`).
     - Mid-piece changes go through `change_*`. A change that is not at a downbeat, or spines that disagree on a row, raise `UnsupportedFeatureError`.
   - Notes, rests and chords are placed. Chord notes with mismatched durations raise.
   - Barlines: `=N` sets bar numbers; an unnumbered `=` continues the count; `==` ends the piece; `=Na` raises.
   - Validation uses exact `Rational` sums via `DottedDuration` (`dotted_duration.rb:21-26`):
     - a bar that is too long, or spines that disagree, raise `ParseError`;
     - a short bar in the middle of the piece raises `UnsupportedFeatureError`;
     - attacks within a row must be simultaneous, and a null token must fall inside a sounding note.
   - Files: `kern/flow_builder.rb`, and specs (including the story's example in `parser_spec.rb`).

9. **Ties**
   - Fuse `[ _ ]` chains into one placement with `append_tied` (`rhythmic_value.rb:105-108`). The chain may cross barlines, which is the ABC precedent (`abc/parser.rb:148-157`, `abc/voice_state.rb:136-160`). The tied notes must have the same pitch.
   - `ParseError`: an unclosed tie, a stray `]`, or a tied rest.
   - `UnsupportedFeatureError`: a chord tied only in part.
   - Files: `kern/voice_cursor.rb`, `flow_builder.rb`, and specs.

10. **Pickup, final bar, repeats**
    - Data before the first numbered barline becomes bar N−1, right-aligned and padded with one leading rest from `0:1`. Writers require a voice's first placement to start its bar (`voice/continuity.rb:23-27`, `preflight_checks.rb:29-33`), and bar 0 is already the pickup convention (`flow.rb:104-106`, `music_xml/writer.rb:152-157`).
    - A short final bar is accepted and not padded.
    - `!|:` sets `starts_repeat`, and `:|!` sets `ends_repeat_after_num_plays = 2` on the bar that contains it, as ABC's `RepeatTagger` does (`abc/repeat_tagger.rb:47-53`).

11. **Lyrics import**
    - Each `**text`/`**silbe` spine attaches to the nearest kern spine on its left. Successive text spines for one kern spine become verses.
    - A syllable goes to the placement attacked on its row through `Placement#sing(text, verse:, hyphen_after:)`.
    - A trailing `-` sets `hyphen_after`; a leading `-` is stripped.
    - Null tokens and `|`/`_` melisma marks are skipped.
    - A syllable on a row with no attack in its kern spine raises `ParseError`.
    - Files: `kern/lyric_reader.rb`, `flow_builder.rb`, and specs.

12. **Work citation import**
    - `kern/citation_reader.rb` turns the collected records into a `HeadMusic::Content::Work` (`lib/head_music/content/work.rb`).
    - Title: `!!!OTL`, or failing that `!!!OTL@@xx`. With no title, build no `Work`, and pass the first `!!!COM` as the flow's `composer:` string, as today.
    - `catalog_number`: `!!!SCT`, verbatim. `year`: the first four-digit year in `!!!ODT`.
    - Composers: each `!!!COM` becomes `Person.new(full_name:, sort_name:)`. `Last, First Middle` becomes the full name `First Middle Last`, with the record as the sort name; a name without a comma is used as both. Add each one with `with_credit(person, :composer)`.
    - `!!!CDT`: when there is one composer, the years before and after the `-` set `birth_year` and `death_year`. Kern's approximate-date marks (`~`, `?`, `<`, `>`) keep the year that follows them. Anything unparseable is ignored, since `Person` validates years and a bad date should not sink the music.
    - The flow's name stays the title, so `flow.name` and `flow.work.title` agree.
    - Files: `kern/citation_reader.rb`, `flow_builder.rb`, `spec/head_music/notation/kern/citation_reader_spec.rb`.

13. **Extract a shared bar splitter from the ABC writer**
    - Move `Segment` and `segments_of` / `fraction_to_bar_end` / `fraction_within_bar` (`lib/head_music/notation/abc/writer.rb:125-150`) into `HeadMusic::Notation::BarSplitter`. It yields, for each placement, one segment per bar it sounds in, with the fraction in that bar and whether it continues.
    - Point the ABC writer at it. This step is a pure refactor: every ABC spec passes unchanged.
    - Files: `lib/head_music/notation/bar_splitter.rb`, `abc/writer.rb`, `spec/head_music/notation/bar_splitter_spec.rb`.

14. **Writer core**
    - Header records from the flow's work: `!!!COM` (each composer's sort name), `!!!CDT` (when a composer has years, as `YYYY/-YYYY/`), `!!!OTL`, `!!!SCT`, `!!!ODT`. With no work, write `!!!COM` from the composer string and `!!!OTL` from the name.
    - One `**kern` spine per part, written in reverse part order.
    - Interpretation rows: `*I"name`, the `*I` code (only for instruments in the table), clef (the authored clef, or `ClefSelector` as a fallback), `*k[...]`, the designation, `*M`, and `*MM` converted to quarter notes per minute.
    - End with `==` and `*-`.
    - `Kern::RenderPlan < Notation::RenderPlan`.
    - `Kern::Preflight` includes `ensure_contiguous_voices` and `PlacementValidation`, but not `ensure_notes_within_barlines`. It adds these `RenderError`s: a part with other than exactly one voice, an empty flow, unspellable or unpitched notes, and `transposed: true` with a transposing instrument.
    - Files: `kern/writer.rb`, `render_plan.rb`, `preflight.rb`, `pitch_writer.rb`, `duration_writer.rb`, and specs.

15. **Writer structure and lyrics**
    - Split placements at barlines into tied tokens with `BarSplitter`.
    - Emit chords.
    - Leave out the pickup bar's leading rest.
    - Write repeat barlines and mid-piece interpretation changes.
    - Pad shorter voices with rests.
    - Emit a `**text` spine to the right of each sung part, one per verse: a hyphen after a syllable with `hyphen_after`, a leading hyphen on the next syllable, and `.` elsewhere.

16. **MusicXML splits notes at barlines**
    - `MusicXML::NoteWriter` already writes a tied chain as one `<note>` per component with `<tie>`/`<tied>` start and stop (`music_xml/note_writer.rb:7`, `:110-120`). Feed it `BarSplitter` segments, so a placement that crosses a barline becomes the tail of one `<measure>` and the head of the next, with the tie carried across.
    - Drop `ensure_notes_within_barlines` from `music_xml/preflight.rb:29`.
    - Specs: the preflight spec at `music_xml/preflight_spec.rb:54-63` and the writer spec at `music_xml/writer_spec.rb:696` flip from expecting `RenderError` to asserting the tied notes; a fourth-species flow renders; a tie across a barline between different durations renders.

17. **LilyPond splits notes at barlines**
    - Split with `BarSplitter` in the LilyPond voice writer, joining the pieces with `~` so that bar checks stay true.
    - Drop `ensure_notes_within_barlines` from `lily_pond/preflight.rb:25`. Once no writer calls it, remove it from `preflight_checks.rb`.
    - Specs: `lily_pond/preflight_spec.rb:56-67` flips; a fourth-species flow round-trips through `LilyPond.parse`, which already folds `~` into tied values; add it to `LilyPondFixtures` so the binary oracle compiles it when LilyPond is installed.

18. **Round trip**
    - `spec/support/kern_round_trip.rb` compares a normalized `Flow#to_h`. The normalization:
      - drops voice `role`, `beam_break_before`, `comments`, `origin`, `work` and `source`;
      - merges bar 0's leading rests, and joins consecutive linked rests;
      - compares tempo in quarter notes per minute;
      - treats an absent staff system as a single staff with `ClefSelector`'s clef.
    - It also asserts idempotence: `parse(render(parse(x))).to_h == parse(x).to_h`.
    - Cover hand-built flows, `LilyPondFixtures`, a `CantusFirmus::Example#to_flow`, and a sung flow with two verses.

19. **Hand-encoded fixture and corpus sweep**
    - `spec/fixtures/notation/kern/satb_chorale.krn`: an original four-part setting written for the test, released under the repo's MIT license. It is modeled on the features of `chor001.krn` but copies none of its music:
      - a 3/4 pickup, and a short final bar;
      - ties across barlines, including one between different durations (`[4g` then `8g]`);
      - a `:|!` in the middle of a bar;
      - `*clefGv2`, `*MM100`, `*G:`, `*k[f#]`;
      - SATB `*I"` names and `*I` codes;
      - a `**text` spine under the soprano;
      - a `!!!!SEGMENT` record, `!!` comments, fermatas and beams.
    - `spec/head_music/notation/kern/chorale_fixture_spec.rb` checks:
      - four parts ordered Soprano to Bass;
      - the bar 0 pickup;
      - G major, 3/4, quarter = 100;
      - the tie and the repeat flag;
      - the lyrics;
      - the work: title, catalog number, and a composer credit with a sort name and years;
      - an idempotent round trip;
      - `to_musicxml` and `to_lilypond` succeed on the imported flow.
    - `spec/head_music/notation/kern_corpus_spec.rb`:
      - Skips unless `ENV["KERN_CORPUS"]` is set, much as the lilypond-binary specs skip when the binary is missing (`lily_pond_round_trip_spec.rb:128-131`). The variable points at a local clone of `craigsapp/bach-370-chorales`, which is never committed.
      - Every file must parse, except that files with short bars in the middle of the piece must raise `UnsupportedFeatureError`. The planner reported chor011, chor130, chor197 and chor280; verify that list when first running the sweep.

20. **`Flow#to_kern` delegate and docs**
    - Add it next to `to_abc` and `to_lilypond` (`flow.rb:151-161`).
    - Update the README format list and the CHANGELOG.

### Testing Strategy

- Specs live under `spec/head_music/notation/kern/`, mirroring lib. Use `described_class`, never assert on stdout, and build compositions with `ABC.parse` where it fits.
- Edge cases to pin:
  - a tie across a barline between different durations;
  - a `:|!` in the middle of a bar;
  - bar 0 padding on import and its removal on export;
  - a short interior bar raises `UnsupportedFeatureError`, and a long bar raises `ParseError`;
  - two distinct same-named players;
  - project documents do not contain `part_players`;
  - deleting the new keys from a new document still reads the same music;
  - misaligned null tokens;
  - CRLF input and invalid encoding;
  - a syllable with no note under it.
- Round-trip equality has two levels: the reader is exactly idempotent, and arbitrary flows are compared by normalized `to_h`. A future schema field then fails the kern round trip until kern carries it or the normalization excludes it on purpose.

### Risks

- **`Project#add_flow` changes behavior.** It now sets `player.project`, and it raises for a player that belongs to another project.
- **Instrument codes** beyond the four vocal ones need checking against the Humdrum `*I` reference. Unmapped instruments are left out on export. `*Ivox` cannot resolve, because `voice` is only a family in the catalog.
- **The clef fallback on export** relies on `ClefSelector`, which knows only treble and bass (`clef_selector.rb:11-19`). The round-trip normalization absorbs this.
- **Corpus statistics are the developer's report, not verified:** 251 of the 370 chorales have pickups, and 366 of 370 validate. Confirm them with the first `KERN_CORPUS` run.
