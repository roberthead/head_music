<!--
metadata:
  created_at:   2026-09-24T18:58:30-07:00
  activated_at: 2026-10-15T12:24:49-07:00
  planned_at:   2026-10-15T12:44:52-07:00
  finished_at:
  updated_at:   2026-10-15T13:30:19-07:00
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

- [ ] `HeadMusic::Notation::MEI.render(flow, **options)` and `Flow#to_mei` return a well-formed MEI 5.1 document. `Flow#to_mei` takes `transposed:` and `arranger:`
- [ ] With `MEI_SCHEMA` set to `mei-CMN.rng` from MEI 5.1, every golden and fixture output validates with `xmllint --relaxng`
- [ ] `<mdiv label>` is the flow's name. `<titleStmt><title>` is the layout's title, else the Work's title, else the flow's name. Each work-level credit is its own `<persName role>`, one per person, falling back to the flow's composer string, and a layout's arrangers are `role="arranger"`
- [ ] Every element from `<mdiv>` down carries an `xml:id` that is a valid NCName, unique in the document, and prefixed by its mdiv number. It is built from part, voice, bar, and onset, so rendering the same flow twice gives the same ids, and every `@startid` and `@endid` names one
- [ ] `Layout#to_mei` renders the layout's realized flows as one document, with one `<mdiv>` per flow
- [ ] The writer raises `MEI::RenderError` before writing anything for an empty flow, for unpitched note events (grace notes included), for text XML cannot hold, and for a part whose staff system changes, since a change renumbers the staves later control events name

### Parts, staves, and voices

- [ ] `<scoreDef>` carries the starting key signature and meter, and a `<staffGrp>` with one `<staffDef>` per staff carrying its clef
- [ ] A multi-staff part is a nested `<staffGrp symbol>` (from `StaffSystem#bracket`) carrying the player's `<label>`, and its `<staffDef>`s carry none. A single-staff part's `<staffDef>` carries it. Each staff definition carries `<instrDef midi.instrnum>` for its instrument, and each voice with a role a `<layerDef n><label>`
- [ ] Each voice's `<layer n>` is its 1-based index among its part's voices, and keeps that number on every staff it is written on, so a voice crossing at a barline keeps its layer number
- [ ] Each bar becomes a `<measure n>`, and a pickup a `<measure n="0" type="upbeat">`. An underfull final bar carries `metcon="false"`. A staff with no voice in a bar is a bare `<staff n/>`

### Notes and rhythms

- [ ] Notes carry `@pname`, `@oct`, `@dur`, and `@dots`
- [ ] `@accid` is written when the key and the earlier notes in the bar, on that staff across all its layers, at that letter and octave, do not already imply the pitch. Otherwise an altered pitch carries `@accid.ges`. A tied continuation shows none and does not change what later notes in the bar show
- [ ] Rests are `<rest>`, and a rest event that fills its bar is `<mRest>` regardless of other layers. Chords are `<chord>`. Ties are `@tie` (`i`, `m`, `t`), including notes that cross a barline, split by `BarSplitter`
- [ ] Tuplets are `<tuplet num numbase>`, and grace notes carry `@grace` (`acc` or `unacc`). A tuplet crossing a barline is written as a hidden `<tuplet>` in each bar plus a `<tupletSpan>`, and a beam that cannot nest with a tuplet is a `<beamSpan>`
- [ ] Beams are `<beam>` groups, following the grouping the MusicXML writer uses, from code shared with it rather than a copy

### Timeline

- [ ] Keys are MEI 5 `@keysig`, on `<scoreDef>`, and on a transposing `<staffDef>` in a transposed render
- [ ] A key, meter, or clef change at a later bar is written as a `<scoreDef>` or `<staffDef>` before that measure
- [ ] The opening tempo is `scoreDef/@midi.bpm` and is not printed. A tempo change is a `<tempo>` control event with `@midi.bpm` in quarters per minute and `@mm`, `@mm.unit`, and `@mm.dots`
- [ ] At an instrument change, a `<staffDef>` before that measure carries the new `<instrDef>` and, when transposed, the new `@trans.diat` and `@trans.semi`
- [ ] With `transposed: true`, a transposing part's `<staffDef>` carries `@trans.diat` and `@trans.semi` and its notes are written pitch, as the `transposed:` option means for the other writers

### Markings and spans

- [ ] Articulations are `@artic`, and note dynamics are `<dynam>` at the note
- [ ] Trills, mordents, and turns are `<trill>`, `<mordent>` (with `@form` `lower` or `upper`), and `<turn>` control events at their note
- [ ] Dynamic levels are `<dynam>` control events at their `@tstamp`. A voice's carries `@staff` and `@layer`; a part's carries `@staff` (the top staff) and no `@layer`
- [ ] Hairpins are `<hairpin @form>` with `@tstamp` and `@tstamp2`, including one ending on the final barline, with `@staff` and `@layer` as for dynamics
- [ ] Slurs are `<slur>` and phrase marks are `<phrase>`, both with `@startid` and `@endid`
- [ ] Barline styles are `measure/@right`. Repeats are `rptstart` and `rptend`, endings are `<ending n="1-2" label="1., 2.">` around their measures, rehearsal marks are `<reh>`, and segno, coda, Fine, D.C., and D.S. are `<repeatMark @func>`. To Coda is `<repeatMark func="coda">To Coda</repeatMark>`, and D.C. and D.S. carry their full text

### Lyrics

- [ ] Each syllable is a `<verse n>/<syl>` in its note. A hyphen after it sets `@wordpos` and `@con="d"`

### Verification

- [ ] Golden documents are pinned for a two-voice species exercise, the SATB chorale fixture, the grand-staff piano fixture, and the markings and hairpin fixtures, and for the navigation, part-marks, cross-staff, triplet, grace-note, two-verse, and transposed clarinet fixtures
- [ ] Every ABC, LilyPond, kern, tuplet, hairpin, and MuseScore-render fixture renders without error, or raises for a reason the spec names
- [ ] A spec checks that every id is unique and every reference resolves
- [ ] When MuseScore 4 is available, each golden converts through `mscore` (with `meiversion="5.1+basic"`), and its pitches and durations per measure match the flow
- [ ] A Verovio spec renders the goldens when `verovio` is installed and is skipped otherwise. One golden is checked by hand in editor.verovio.org and recorded here
- [ ] Maintains 90%+ test coverage

## Notes

- Generate the XML as the MusicXML writer does, as text, without a runtime dependency.
- **Follow-up: guideline findings as annotations.** Findings would become `<annot @plist>` pointing at the notes they concern. The position-derived `xml:id`s exist for this, and so that a diff of two renders shows only what changed.
- Unpitched percussion raises for now. MEI writes it as `<note>` with `@loc` on a percussion staff, and the gem has no mapping from an unpitched sound to a staff position yet.
- **Waits on Timeline Expressions:** fermatas, tempo words, and meter symbols come with [Timeline Expressions](timeline-expressions.md), and `<fermata>`, `<tempo>` text, and `@meter.sym` with them.
- **Deferred: `Flow#source` as `<sourceDesc>`.** Mapping a `Publication` takes its own bibliographic decisions, nothing reads it back yet, and it fits the `<annot>` follow-up, which already touches scholarly apparatus.
- **Deferred: cautionary accidentals.** The model has no courtesy flag, so any rule would be an invented style choice.
- **Verovio is not installed here** (Rob's choice), so MuseScore 4's MEI import stands in as the automated real-tool check. MuseScore reads only `meiversion="5.1+basic"` and hangs on any other value, so its spec rewrites the version and runs under a timeout.
- The round trip through MEI belongs to [MEI Import](mei-import.md), which lands after this story.

## Decisions

- **MEI 5 only** (decided 2026-10-14). Verovio and the current schema use it, and MEI 4 toolchains read most MEI 5 CMN.
- **`xml:id`s are stable, derived from position** (decided 2026-10-14), so that annotations and diffs remain meaningful.
- **Markings, spans, bar markings, multi-staff parts, tuplets, and grace notes are in scope** (decided 2026-10-14). The original v1 deferred dynamics, articulations, and slurs. The model now holds them, every other writer writes them, and leaving them out would make MEI the one lossy writer.
- **Planning choices adopted without stopping to ask** (2026-10-15, while running the seven-story goal; Rob may revise any). All of the planner's proposed story changes were adopted:
  - layers are numbered within the part, not the staff, so a crossing voice keeps its number and MEI Import can follow it;
  - keys are MEI 5.1's `@keysig`, since its schema rejects `@key.sig`;
  - a tuplet crossing a barline is written as hidden per-bar tuplets plus a `<tupletSpan>` rather than raising, keeping MEI lossless;
  - a part with a staff-system change raises, as kern does;
  - pickup rests stay `<rest>`, not `<space>`, matching what every other writer prints;
  - the schema is not vendored; the spec is gated on `MEI_SCHEMA`, as MusicXML's is on `MUSICXML_XSD`;
  - a repeat played more than twice is written as a `<dir>` "×N" at the end of its bar.

- **Implementation choices made without stopping to ask** (2026-10-15; Rob may revise any):
  - A voice with nothing in a bar, such as a tacet voice or the bars before a voice begins, writes `<layer><mRest/></layer>`, as MusicXML writes a whole-measure rest. A bare `<staff/>` is only for a staff with no voice on it.
  - Feature hooks return elements rather than text, and the measure and section writers bucket them by bar, so no feature filters per measure.
  - `<instrDef midi.instrnum>` is `Instrument#gm_program` minus one, since GM numbering is 1-based and MEI's is 0-based.
  - The clef fallback for a staff uses the first voice on that staff.

## Implementation Plan

### Overview

The plan adds `HeadMusic::Notation::MEI` under `lib/head_music/notation/mei/`. It is built like the MusicXML writer: a preflight, then an eager `RenderPlan` subclass, then text joined once at the end. Before any MEI code, three shared refactors land:

- the beam grouping moves into a format-neutral `Notation::BeamGroups`;
- `XmlText` and the XML control-character check move out of `music_xml/`;
- `mark_offset` moves into `BarSplitter`.

MEI Import gets the golden documents, ids that resolve, and the shared helpers it will need. `XmlReading` and `ParsePreflight` stay in `music_xml/` for that story to move.

Specialists consulted: the product manager, the developer, and the best-practices engineer. The last was brought in because the beam extraction, the id scheme, and the plan-then-write structure are real architecture. The UI/UX designer and the accessibility specialist were skipped because the story has no UI.

**What I verified myself:**

- **MEI 5.1 schema.** I downloaded it into the scratchpad. A probe document that uses every shape this plan relies on validates against it.
- **MuseScore 4.7.5 imports MEI headlessly, with a catch.** It only works when the document says `meiversion="5.1+basic"`. With `5.1`, `5.1+CMN`, `5.0+basic`, or no version, it hangs forever: no output, no exit.

Details are under Testing Strategy.

### Steps

Steps 1–3 branch from `9b98280d`. Step 3 can run in its own worktree in parallel with steps 1–2. They share no contract, and their only shared lines are the requires in `lib/head_music/notation.rb` and the CHANGELOG.

1. **Pin MusicXML beaming that no fixture covers yet**
   - The golden check (`spec/head_music/notation/music_xml_real_files_spec.rb:212-215`) only guards beams in 4/4: `bach_invention_01`, `speed_the_plough`, `triplets`, `two_verses`.
   - Add exact-beam examples against today's code:
     - 6/8, which reaches the compound branch of `Meter#beam_group_unit`;
     - 3/8 whole-bar beaming;
     - a grace note before an inner beamed note;
     - a forced `beam_break_before` from ABC.
   - Use `ABC.parse` to build them. Write them as inline expectations, not new `MuseScoreFixtures`, because those would need MuseScore conversions.
   - Files: `spec/head_music/notation/music_xml/writer_spec.rb`, `spec/head_music/notation/music_xml/beam_grouper_spec.rb`

2. **Extract the shared beam grouping**
   - Only phase A of `BeamGrouper` is format-neutral: splitting a bar into groups (`music_xml/beam_grouper.rb:36-56`). Phase B writes MusicXML's begin/continue/end/hook types (`:59-106`).
   - Create `HeadMusic::Notation::BeamGroups` containing:
     - `Event = Data.define(:levels, :onset, :beam_break_before)`, where `onset` is a Rational fraction of a whole note;
     - `group_start?(onset, meter)`;
     - `groups(events, meter)`, which returns arrays of indices.
   - `MusicXML::BeamGrouper` keeps phase B and gets its groups from `BeamGroups`.
   - The default group-start rule exists twice today: as divisions in the writer (`beam_grouper.rb:55`, with `music_xml/render_plan.rb:144-151`) and as Rationals in the reader (`beam_reader.rb:50-53`). Both should call `BeamGroups.group_start?`. MEI Import becomes the third caller.
   - The best-practices engineer fed Rational onsets from `TupletBrackets.written_links` (`tuplet_brackets.rb:59-65`) into the existing grouper in a scratch run. All 133 voice-bars of the committed renders came out identical.
   - Move `written_links` and `Link` out of `tuplet_brackets.rb` into `notation/written_links.rb`. Tuplets, beams, and MEI ids then share one listing.
   - MEI needs no `@breaksec`. Phase B only breaks a secondary beam where a shorter value drops out (`beam_grouper.rb:76-84`), which Verovio works out from the durations.
   - Proving MusicXML output is unchanged:
     - the stale-render spec passes;
     - step 1's examples pass;
     - a scratch script renders every ABC, LilyPond, kern, Tuplet, Hairpin, and Marking fixture before and after, copied aside (not stashed), and `diff -r` is empty.
   - Files: `lib/head_music/notation/beam_groups.rb`, `lib/head_music/notation/written_links.rb`, `lib/head_music/notation/tuplet_brackets.rb`, `lib/head_music/notation/music_xml/beam_grouper.rb`, `lib/head_music/notation/music_xml/render_plan.rb`, `lib/head_music/notation/music_xml/beam_reader.rb`, `lib/head_music/notation.rb`, `spec/head_music/notation/beam_groups_spec.rb`

3. **Move shared XML text helpers and fix the MusicXML control-character gap** (parallel with 1–2)
   - Move `MusicXML::XmlText` (`music_xml/xml_text.rb:5-20`) to `HeadMusic::Notation::XmlText`, and update every `include` and `require_relative` in `music_xml/`.
   - Add `PreflightChecks#ensure_xml_text(texts)`, built from `FORBIDDEN_TEXT_CHARACTERS` (`music_xml/preflight.rb:15`). Add `\uFFFE`, `\uFFFF`, and a `valid_encoding?` check.
   - Today MusicXML checks only the flow name, the composer, and voice roles (`music_xml/preflight.rb:44-50`). Syllables, player names, instrument names, rehearsal marks, and `Work` credits go unchecked, so the writer can produce ill-formed XML. CHANGELOG this as a Bug fix: MusicXML now raises `RenderError` for these.
   - Move `Divisions.mark_offset` (`music_xml/divisions.rb:15-20`) to `BarSplitter.mark_offset` so MEI's tstamps share it. Leave `Kern::MarkOffset` alone, because its voice scope is different.
   - Leave `XmlReading` and `ParsePreflight` where they are. The writer calls neither. Their errors are MusicXML's own (`xml_reading.rb:61-63`, `parse_preflight.rb:8,29,37`). MEI Import should move them with an `error_class:` parameter, as `PreflightChecks#render_error_class` already does.
   - Files: `lib/head_music/notation/xml_text.rb`, `lib/head_music/notation/preflight_checks.rb`, `lib/head_music/notation/bar_splitter.rb`, `lib/head_music/notation/music_xml/*.rb`, `spec/head_music/notation/preflight_checks_spec.rb`, `spec/head_music/notation/music_xml/preflight_spec.rb`

4. **MEI skeleton: one staff, one voice per part** (on the story branch, after steps 1–3)
   - Run a 15-minute schema spike first. Most shapes are already validated (see Testing Strategy).
   - `MEI.render(flow, **options)`, `Flow#to_mei(**options)` next to `to_kern` (`content/flow.rb:197`), and `MEI::RenderError`.
   - `Writer` writes, in order:
     - `<?xml?>`;
     - an `<?xml-model?>` pointing at `https://music-encoding.org/schema/5.1/mei-CMN.rng`;
     - `<mei meiversion="5.1">` (the schema allows only `5.1` or `5.1+CMN`);
     - `<meiHead>`;
     - one `<mdiv label="{flow name}">`.
   - `HeadWriter` writes the header:
     - `titleStmt/title`;
     - one `<persName role>` per person for each work-level credit, falling back to the `Flow#composer` string (`flow.rb:51-53`);
     - an `arranger:` option;
     - `pubStmt`;
     - `encodingDesc/appInfo/application` with `HeadMusic::VERSION`, as `music_xml/writer.rb:78` does.
   - `Preflight` includes `PreflightChecks`:
     - no voices or no events;
     - `ensure_xml_text`;
     - contiguous voices;
     - markings and timed marks within the music;
     - no marks inside rounded tuplet notes;
     - unpitched sounds in main notes and grace notes, before anything is written. MusicXML only catches these partway through writing (`note_writer.rb:26`). Copy the kern check (`kern/preflight.rb:43-45`).
     - Leave out `ensure_one_hairpin_at_a_time` (`preflight_checks.rb:47-54`). MEI hairpins are independent, and that check is a quadratic `combination(2)`.
   - `RenderPlan < Notation::RenderPlan` implements `key_value` (`render_plan.rb:133-135`) as `@keysig` (`"2f"`, `"0"`). MEI 5.1 rejects `@key.sig`, which I checked with xmllint. It precomputes, in order: written links, `Ids`, and everything else later steps add.
   - `Ids` holds the whole scheme now, as pure functions, so the parallel steps only call it:
     - Every id starts `m{mdiv}-`, even for one flow. A one-flow `Layout#to_mei` then matches `Flow#to_mei` byte for byte, and adding a flow never renames the first flow's ids.
     - Events are keyed by part, voice in part, and the segment's onset: `m1-p1v2-b3c2`, with `t{tick}`/`s{subtick}` added only when nonzero.
     - Bars: bar 0 is `b0` and negative bars are `bm1`.
     - Suffixes: `-k{n}` for later tied-chain links, `-h{n}` for chord members from low to high (`note_writer.rb:63-65`), `-g{n}` for grace notes.
     - Containers and control events: `m1-{kind}-{key}`.
     - Ids come only from integers, never from names, and are counted while walking, never with `Array#index` over voice events. `VoiceEvent#<=>` compares positions only (`voice_event.rb:133-135`), so events in two voices at the same position are `==`.
   - `Markup` is a small line builder that tracks depth. MEI nests more deeply and less predictably than MusicXML's hand-counted `INDENT * n`.
   - `EventWriter` writes:
     - `pname`/`oct`/`dur`/`dots`;
     - `rest`, `chord`, and `mRest` for a lone rest that fills the bar and is not under a tuplet;
     - `@tie` `i`/`m`/`t` across the `BarSplitter` pieces;
     - `<measure n="0" type="upbeat">` for a pickup, with its rests written as `<rest>` as MusicXML writes them;
     - `metcon="false"` on a short final bar;
     - `Durations` raising at plan time for values MEI cannot write.
   - `ScoreDefWriter` (opening only) writes `@keysig`, `@meter.count`/`@meter.unit`, `@midi.bpm` from the opening tempo, and `<staffDef n lines>` with a `<clef shape line dis dis.place>` child. Clef fallback as in `attributes_writer.rb:141-143`, octave clefs as in `:158-160`.
   - Files: `lib/head_music/notation/mei.rb`, `lib/head_music/notation/mei/{writer,head_writer,preflight,render_plan,ids,markup,durations,score_def_writer,section_writer,measure_writer,event_writer}.rb`, `lib/head_music/notation.rb`, `lib/head_music/content/flow.rb`, `spec/head_music/notation/mei_spec.rb`, `spec/head_music/notation/mei/*_spec.rb`, `spec/support/mei_helpers.rb` (REXML with the MEI namespace, plus an id lookup), `spec/head_music/notation/mei_schema_spec.rb` (gated on `MEI_SCHEMA`, modeled on `music_xml_schema_spec.rb:10-15` with `--relaxng`), `spec/head_music/notation/mei_references_spec.rb` (always runs)

5. **Parts, staves, layers, and the fan-out contract**
   - Each `[part, staff]` gets a global staff `n`.
   - A multi-staff part is a nested `<staffGrp symbol>`:
     - the symbol comes from `StaffSystem#bracket`, so `brace`, `bracket`, or none (`staff_system.rb:7`);
     - the group carries the part's `<label>`, and its `staffDef`s carry none.
   - A single-staff part's `staffDef` carries the label.
   - Labels come from the player name only, because MEI Import turns a label into a player.
   - `<instrDef midi.instrnum>` comes from `Instrument#gm_program` (`instruments/instrument.rb:88`). Check whether that value is 1-based; MEI's is 0-based.
   - Voice roles go in `<layerDef n><label>` (validated). Without them, MEI Import cannot restore roles.
   - `<layer n>` is the voice's 1-based index among its part's voices, the same on every staff it is written on. A crossing therefore moves the same layer number to the other staff, which is what MEI Import's crossing rule needs. On the left-hand staff of a piano this gives a lone `layer n="2"`; MuseScore imported that fine.
   - A staff with no voice in a bar is a bare `<staff n/>` (validated). A part with no voices follows the same rule.
   - Preflight raises when a part has a staff-system change. A change renumbers the staves that later `@staff` control events refer to, and kern also raises on it (`kern/preflight.rb:71`).
   - `Tstamp` lives here so that 6D and 6E don't both write it:
     - `beat = 1 + offset × meter.bottom_number`, using `BarSplitter.mark_offset`;
     - an exact decimal when the denominator has only factors of 2 and 5, otherwise rounded to 4 places;
     - `tstamp2 = "{bars later}m+{beat}"`, where reaching the final barline is `top_number + 1`.
   - Extension points for the fan-out:
     - `RenderPlan#items(voice, bar)` returns `Item(segment, link_index, link, tie, graces)`;
     - `EventWriter.attribute_sources` / `child_sources`;
     - `MeasureWriter.control_sources`, where each source answers `lines(bar_number)` and is bucketed once per bar, never filtered again for each measure (the pattern b51cdcf2 removed from MIDI);
     - `SectionWriter.pre_measure_sources` and a `bar_group` hook.
   - Files: `lib/head_music/notation/mei/{render_plan,score_def_writer,measure_writer,section_writer,event_writer,tstamp}.rb`, specs using `LilyPondFixtures.cross_staff_piano`, `tie_into_staff_crossing`, `piano_and_melody`

6. **Fan-out: seven parallel worktrees, each based on the step-5 commit (name its SHA when spawning; worktree agents branch from `main` otherwise)**
   - **Contract:** step 5's extension points and `Ids`.
   - **Rules:** each step adds its own files plus one registration line. CHANGELOG lines go in commit bodies, and the coordinator merges them.
   - **6A. Accidentals** (`mei/accidental_plan.rb`)
     - Accidental memory is kept per staff and per bar, keyed by `[letter, register]`, and seeded from the written key: `first_measure_key(part)` plus changes, so transposed parts use their own key.
     - Walk every layer on the staff in onset order, grace notes before their main note.
     - Write `@accid` where the state does not already imply the pitch, and update the state. Otherwise write `@accid.ges` when the pitch is altered.
     - Tied continuations never show an accidental and never update the state.
     - Another octave of the same letter shows its accidental again.
     - Chord members are judged one by one.
   - **6B. Beams, tuplets, grace notes** (`mei/layer_tree.rb`, `mei/container_spans.rb`)
     - `<tuplet>` contains `<beam>` where they nest; a beam that cuts across a bracket becomes `<beamSpan>`.
     - A bracket that crosses a barline (`tuplet_brackets.rb:37-39`) becomes a `<tuplet>` in each bar with `bracket.visible="false" num.visible="false"`, plus one `<tupletSpan>` (validated). Raising instead would make MEI the one lossy writer.
     - Grace notes get `@grace` `acc` when slashed, `unacc` otherwise. They sit inside a `<beam>` when they come before an inner member.
     - A slur `from_grace` starts on the first grace note (`span.rb:15-17`).
   - **6C. Timeline**
     - Before a changed bar: `<scoreDef keysig/meter.*>`, `<staffDef n>` with a new `<clef>`, and a per-staff `@keysig` in transposed renders.
     - Tempo changes become `<tempo tstamp midi.bpm mm mm.unit mm.dots>`, with `midi.bpm` in quarters per minute.
     - With `transposed: true`, `staffDef/@trans.diat`/`@trans.semi` include octaves (B♭ clarinet −1/−2, bass clarinet −8/−14).
     - An instrument change is a `staffDef` change with a new `instrDef` and `trans.*`, reset to 0/0 when the part returns to an instrument in C.
     - Concert renders write no `trans.*`.
   - **6D. Markings and spans** (`mei/artic_attributes.rb`, `mei/marking_events.rb`)
     - `@artic` is a list, on `<chord>` for a chord, and on the first written piece only (`note_writer.rb:155-157`).
     - Trill, mordent, and turn use `@startid`: `mordent` is `form="lower"` and `inverted_mordent` is `form="upper"` (`rudiment/ornaments.yml:1-13`).
     - Note dynamics are `<dynam startid>`.
     - Levels are `<dynam tstamp staff layer>` for a voice, or `staff={top}` with no `@layer` for a part.
     - Hairpins are `<hairpin form tstamp tstamp2>`.
     - Slurs and phrases use `startid`/`endid`. Move `SlurNumbers.closing_component?` (`slur_numbers.rb:40-42`) out so it is shared, not copied.
   - **6E. Bar markings** (`mei/bar_marks.rb`, `mei/navigation_events.rb`)
     - `@left="rptstart"`.
     - `@right` is `dbl`/`end`/`dashed`/`dotted`/`rptend`; the last bar gets `end`, as `barline_writer.rb:53-59` does.
     - `<ending n="1-2" label="1., 2.">` (validated; `n="1, 2"` is rejected).
     - `<reh>` on the top staff at `tstamp="0"`.
     - `<repeatMark func>` uses `segno`, `coda`, `fine`, `daCapo`, `dalSegno` (all validated). To Coda is `func="coda"` with the text "To Coda", and D.C./D.S. carry their full text.
   - **6F. Lyrics** (`mei/lyric_writer.rb`)
     - `<verse n><syl wordpos con="d">`, on the first piece of an attack only (`lyric_writer.rb:17-18`).
     - `wordpos` `i`/`m`/`t` comes from the neighboring syllables; a one-syllable word gets none.
   - **6G. Layout** (`content/layout/rendering.rb`, `content/layout.rb:100`)
     - `Layout#to_mei` writes one document with one `<mdiv>` per realized flow.
     - The head title is the layout's title; arrangers come from `@layout.project.credits`, as `rendering.rb:70-73` does; `transposed: @layout.transposed?`.
     - Model it on the `BookWriter` branch at `rendering.rb:22-27`.
   - Each sub-step carries its own unit specs plus a schema case in `mei_schema_spec.rb`.

7. **Verification, goldens, and release notes** (on the story branch, after the fan-out is merged)
   - `spec/support/mei_fixtures.rb` (`MEIFixtures::RENDERS`).
   - Goldens in `spec/fixtures/notation/mei/*.mei`, regenerated by a new `rake mei:golden_fixtures` beside `music_xml:musescore_fixtures` (`Rakefile:51`).
   - The golden spec checks:
     - committed files match a fresh render;
     - every element from `<mdiv>` down has an `xml:id`;
     - ids are unique and match `/\A[a-z][a-z0-9-]*\z/`;
     - two renders are identical;
     - every `@startid`/`@endid` resolves.
   - `mei_fixtures_spec.rb` renders every ABC, LilyPond, kern, Tuplet, and Hairpin fixture, listing by name any that raise for a documented reason.
   - The MuseScore and Verovio specs are described under Testing Strategy.
   - `spec/fixtures/notation/mei/README.md` names the schema to fetch.
   - CHANGELOG under 23.0.0. Only the internal `MusicXML::XmlText` is removed, so no **Breaking.** note is needed.
   - Files: `Rakefile`, `spec/support/musescore.rb`, `spec/head_music/notation/mei_*_spec.rb`, `CHANGELOG.md`

### Testing Strategy

- **Unit specs per class**, built with `ABC.parse` where one line of melody is enough. Edge cases:
  - **ids:** pickup, negative bar, tick and subtick, chord member, split plus tied chain, grace chord.
  - **tstamp:** 6/8, pickup, final barline, a meter change inside a span, a triplet onset.
  - **accidentals:** a conflict across layers, a tie over a barline, F and F♯ in one chord, a transposed key.
  - **layer tree:** a beam that crosses a bracket, a bracket that crosses a barline.
  - **layers:** a crossing, an empty staff, a part with no voices.
  - **endings:** a key change inside an ending.
- **Golden documents.**
  - Required by the story:
    - `LilyPondFixtures.fourth_species` (the two-voice species example);
    - `kern/satb_chorale.krn`;
    - `kern/piano_splits.krn` (grand staff);
    - `kern/articulations_ornaments_dynamics.krn`;
    - `kern/hairpins.krn`.
  - Recommended extras, each covering a criterion the required set does not:
    - `marked_dal_segno_al_coda`;
    - `marked_da_capo_al_fine`;
    - `piano_part_marks`;
    - `cross_staff_piano`;
    - `triplets`;
    - `grace_notes_before_downbeat`;
    - `two_verses`;
    - `clarinet_changes_transposed`.
  - The goldens embed `HeadMusic::VERSION` and regenerate on each release, as the MusicXML ones do.
- **RelaxNG, gated on `MEI_SCHEMA`.**
  - Fetch release **v5.1** (2025-01-22): asset `MEI_Schemata_v5.1.zip` from `https://github.com/music-encoding/music-encoding/releases/download/v5.1/MEI_Schemata_v5.1.zip` (sha256 `2586509c350d67b16bdeaae8e8e33e626dee615df88d49c87058484bb6334877`), and extract `mei-CMN.rng` (1.3 MB, sha256 `f6440d5eb59c3e903f2a7a64ea26518646186f8449b86096106846a269eb354b`).
  - Ignore `v6.0-0+featureFreeze`, which is a pre-release.
  - It is already extracted at `/private/tmp/claude-501/-Users-roberthead-github-com-roberthead-head-music/6579b744-7cf1-410f-8f79-7acf007bb139/scratchpad/schema/mei-CMN.rng`.
  - Run: `MEI_SCHEMA=/private/tmp/claude-501/-Users-roberthead-github-com-roberthead-head-music/6579b744-7cf1-410f-8f79-7acf007bb139/scratchpad/schema/mei-CMN.rng bundle exec rspec spec/head_music/notation/mei_schema_spec.rb`
  - My probe `/private/tmp/claude-501/-Users-roberthead-github-com-roberthead-head-music/6579b744-7cf1-410f-8f79-7acf007bb139/scratchpad/mei/probe.mei` validates. It covers:
    - nested `staffGrp` with `<label>`, `<clef dis>`, `layerDef/label`, `staffDef keysig trans.* instrDef`;
    - `measure type="upbeat" metcon="false" left="rptstart"`, a bare `<staff n/>`, `mSpace`;
    - `<reh tstamp="0">`, all five `repeatMark/@func` values, an empty `<tempo midi.bpm mm mm.unit mm.dots>`;
    - `<ending n="1" label="1, 2.">` holding `scoreDef`/`staffDef` changes;
    - `tuplet>beam`, a list-valued `@artic`, `verse/syl` in a chord note, `hairpin tstamp2="0m+7"`, `tupletSpan`, `<dir>`;
    - `keysig="8s"`.
  - It also confirmed what the schema rejects:
    - `@key.sig` on `scoreDef`;
    - `meiversion="5.0"`;
    - `ending n="1, 2"`;
    - an id starting with a digit.
- **Reference integrity, always run.** xmllint's RelaxNG pass skips MEI's Schematron rules. A REXML spec therefore checks unique ids and that every `@startid`/`@endid`/`@plist` resolves.
- **MuseScore, the real-tool stand-in for Verovio.**
  - Gated like `spec/head_music/midi/muse_score_spec.rb:6`: run when `MSCORE` is set, or `MUSESCORE_FIXTURES=1` with MuseScore installed.
  - What I found:
    - **Version string.** It imports only `meiversion="5.1+basic"`, its own export dialect. Any other value hangs indefinitely, while MusicXML converts in 1 second. With `5.1+basic`, a document carrying `keysig`, a beam, a slur, a `tstamp` hairpin, a `tstamp` dynam, `accid`/`accid.ges`, and chords came through (spot-checked in the converted MusicXML).
    - **Ties.** `@tie` was dropped.
    - **Empty staves.** A bare `<staff n/>` or `<layer><mSpace/></layer>` makes it exit with no output. `<mRest/>` works.
    - **Underfull layers.** An underfull layer also gives no output, which is useful for catching writer bugs.
  - Plan:
    - give `MuseScore.convert_file` (`spec/support/musescore.rb:39-50`) a `timeout:`, using spawn plus kill, because `system` would hang the suite;
    - the spec swaps `meiversion` to `5.1+basic`;
    - it fills bare staves with a layer holding `<mRest/>`;
    - it then compares per-measure pitches and written durations with the source flow, ignoring ties and rests. It does not compare markings, because MuseScore's reading of MEI control events is partial.
- **Verovio, gated and skipped.** `mei_verovio_spec.rb` runs only when a `verovio` executable is on `PATH`. It renders each golden to SVG in a temp directory and expects no `[Warning]`/`[Error]` lines in stderr. This checks a tool's output, not the gem's console output.
- **Manual Verovio check, no install.** Paste one golden (recommended: `marked_dal_segno_al_coda`) into editor.verovio.org, and record the result in the story.
- **Coverage.** Unit specs carry the 90%; the goldens are not relied on for it.

### Risks & Open Questions

These are settled with recommendations to adopt:

- **Layer numbering.** The product manager and I chose per-part numbering over the developer's per-staff ranking. The trade-off: a left hand alone on its staff is `layer n="2"`. Verovio's stem direction for a lone layer 2 should be checked in the manual Verovio check.
- **Pickup rests stay `<rest>`.** The developer proposed `<space>` for a nicer upbeat. I rejected it so MEI matches what every other writer prints; `<space>` could become a later display option.
- **The schema is not vendored.** The product manager proposed vendoring it. Gating on `MEI_SCHEMA` matches `MUSICXML_XSD` and your instruction, and keeps 1.3 MB out of the gem repo.
- **Repeating tstamps.** Triplet onsets are rounded to 4 decimal places. MEI Import must snap them to the tick grid.
- **A repeat played more than twice** is written as `<dir>` "×N" at the end of the bar, rather than raising.

Other risks:

- **MusicXML ignores staff-system changes.** `attributes_writer.rb:93-99` writes `<staves>` once, and `music_xml/preflight.rb:23-30` does not refuse a change, so MusicXML silently drops them. MEI raising here is not "the one lossy writer"; consider the same check for MusicXML.
- **Grace notes inside `<beam>`, and `<tupletSpan>` with hidden per-bar tuplets,** are valid but untested in Verovio. Both go into the manual Verovio check. If they misbehave, fall back to `<beamSpan>` for the beam case and `ensure_tuplets_within_bars` (`preflight_checks.rb:70-78`) for the tuplet case.
- **`gm_program` indexing** (1-based or 0-based) needs checking before writing `midi.instrnum`.
- **Ripple to MEI Import** (`user-stories/backlog/mei-import.md`):
  - line 32 and line 81 name only `@key.sig`, which MEI 5.1 rejects, so it must read `@keysig` too;
  - line 62 should read the brace group's `<label>`, not "staves that share one label";
  - add criteria for `mdiv/@label` as the flow name, `scoreDef/@midi.bpm`, `layerDef/label` roles, instrument changes, the passes in `ending/@n`, and a bare `<staff/>` meaning no voice;
  - its "padded with rests" criterion should not add rests to layers before the voice begins.
- **Timeline Expressions** lists no MEI line, so MEI `<fermata>`, tempo text, and `@meter.sym` belong to no story yet. Add MEI to its Formats criteria.
