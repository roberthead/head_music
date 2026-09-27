<!--
metadata:
  created_at:   2026-09-27T11:01:33-07:00
  activated_at: 2026-09-27T11:01:54-07:00
  planned_at:   2026-09-27T11:54:27-07:00
  finished_at:  2026-09-27T12:25:24-07:00
  updated_at:   2026-09-27T12:25:24-07:00
-->

# Story: Markings Review Follow-ups

## Summary

AS a developer or researcher using HeadMusic

I WANT the markings that MusicXML and kern can express to come through a write and a read intact, and malformed markings in Flow JSON to be refused

SO THAT, within the written bars, MusicXML and kern never lose a dynamic without a word or rewrite a written rhythm to make room for one, and the open items from the markings review are closed

## Background

The review of [Articulations, Ornaments, Dynamics](../done/articulations-ornaments-dynamics.md) left several items open. Each one below was reproduced on `main` at `4ed933d5`.

- **MusicXML drops a trailing voice dynamic.** A voice `C D E` in 4/4 with a *f* placed at beat 4 writes no `<f/>`. `DirectionWriter` finds the voice event sounding at the dynamic's position, and there is none after the last note, so the dynamic is skipped.
- **Kern rewrites a held note's rhythm.** A dotted-quarter C with a *p* one eighth into it is written as `[8c` / `4c]`, so it reads back as an eighth tied to a quarter. Kern's null token `.` says "whatever was sounding continues", so the note can stay `4.c`, with `.` in its column on the rows that carry the *p*.
- **Kern gives a row where nothing attacks no time of its own.** By Humdrum convention, such rows split the time between the timed rows around them evenly. The reader today puts them at the next attack instead: `1c` then `.` beside `p` reads the *p* at 2:1, not 1:3. So the writer's split cannot simply be removed; the reader must learn the convention first.
- **Flow JSON merges alias duplicates.** `["mordent", "lower_mordent"]` names one ornament twice and is read as one mordent, while `["mordent", "mordent"]` raises. Spelling variants such as `["accent", "Accent"]` merge the same way. The writer never produces either.
- **No spec runs a style guideline over a marked flow.** The story's "voice events, continuity, analysis, and style unchanged" criterion is true by construction, but only `voice_events` and `Voice::Continuity` are pinned.
- **The readers list dynamics by hand.** `abc/decoration_mapper.rb` and `lily_pond/mark_reader.rb` spell out the levels and accents that `Dynamic.levels` and `Dynamic.accents` already hold.

The review also named a first-fragment check repeated in `abc/writer.rb` and `lily_pond/render_plan.rb`. A later refactor removed it.

## Acceptance Criteria

### MusicXML

- [x] A voice dynamic after the voice's last event in a bar is written as a `<direction>` after that bar's final note, at the dynamic's position, in both a single-staff part and a grand-staff part
- [x] In a part with two voices where voice 1 ends before voice 2, voice 1's trailing dynamic is written after its last note and before the `<backup>`, with voice 1's `<voice>` and staff, and no `<backup>` or `<forward>` duration changes
- [x] A dynamic under a note or rest writes as it does today

### Kern

- [x] Reading a file whose `**dynam` data sits on rows where every `**kern` field is `.` places each such row at an even split of the time between the timed rows around it, not at the next attack
- [x] A part or voice dynamic that falls while a note is held writes the note whole, with the dynamic on evenly spaced null rows, so that an even split of the time between the timed rows around them lands on the dynamic
- [x] Reading that file back gives the note's written rhythmic value, such as a dotted quarter rather than an eighth tied to a quarter, and the dynamic at its position
- [x] Given a whole note in 4/4 with a *p* at 1:2, writing and reading back gives one whole note and the *p* at 1:2
- [x] The same holds under a rest, and when several voices in the part hold notes across the dynamic
- [x] Dynamics in different parts that fall in the same span each read back at their own positions
- [x] A dynamic that coincides with an attack writes as it does today

### Flow JSON

- [x] Articulations or ornaments that name one marking twice through different aliases or spellings, such as `["mordent", "lower_mordent"]` or `["accent", "Accent"]`, raise the same error, with the same path, as a repeated key

### Style

- [x] Every guide in `Guide::ALL`, graded over a two-voice published example with articulations, ornaments, note dynamics, and voice and part levels (one under a held note), gives the same fitness and marks as over the same example without them

### Duplication

- [x] The ABC and LilyPond readers take their dynamic levels and accents from `Dynamic.levels` and `Dynamic.accents`, read exactly those, which are what they read today, and drop none of them

### Changelog

- [x] **Breaking.** entries record that kern import re-times dynamics on null-only rows, and that Flow JSON refuses aliases or spelling variants that name one marking twice

## Notes

- The level placement that wraps `ArgumentError` in `abc/voice_state.rb` and `lily_pond/event_placer.rb` stays duplicated. It is three lines in each, and each reader raises its own kind of error with different location details.
- Dynamics in the middle of a note stay in the model. A dynamic under a held note is ordinary, as in a piano's left hand holding while the right hand gets a new level, and formats can write one without touching the note: kern's null token, MusicXML's `<offset>`, and LilyPond's spacer rests for part dynamics.
- A voice dynamic under a held note in LilyPond or ABC still moves to the next note, and kern, ABC, and LilyPond still drop a voice dynamic after the voice's last note. Both belong to [Place Dynamics Where No Note Starts](../backlog/place-dynamics-where-no-note-starts.md).
- A dynamic after a voice's last event in an incomplete bar is written in MusicXML, not refused, because MusicXML can place a direction there without inventing a rest.
- The even split is what the planner reports humlib's `analyzeNullLineRhythms` does. No Humdrum tool was run locally to confirm it.

## Implementation Plan

### Overview

Four items are small and contained: alias-aware duplicate checking in Flow JSON, catalog-derived dynamic lists in the ABC and LilyPond readers, a style-invariance spec, and a trailing-direction pass in the MusicXML writer. Kern takes two commits, reader first: the reader gives null-only rows their Humdrum time, then the writer emits evenly spaced null rows instead of cutting the note. Writer first would briefly produce files that read back wrong while the suite stays green.

### Steps

1. **Refuse a marking named twice through an alias in Flow JSON**
   - `catalog_keys` (`content/flow/schema_values.rb:91-99`) compares raw strings with `values.index(value) != index` before lookup. Resolve each value with `catalog_value` first, then check for duplicates against a `seen` list, as `seen_verses` does at :83-85.
   - Keep the message and path: `"#{path}: duplicate #{label} #{value.inspect}"`, quoting the later entry as written.
   - `KeyedCatalog.canonical_key` snake-cases its input (`rudiment/keyed_catalog.rb:41-44`), so this also catches `["accent", "Accent"]`.
   - `["bogus", "bogus"]` now raises "unknown" at index 0 instead of "duplicate". No spec pins the old order.
   - Specs: `schema_values_spec.rb` (after :317) for an ornament named twice through an alias and an articulation in two cases; `flow_serialization_spec.rb` (the refusal block near :246) for the full message and path.

2. **Read ABC and LilyPond dynamics from the Dynamic catalog**
   - The catalog matches both readers today: `Dynamic.levels` is `ppp pp p mp mf f ff fff` and `Dynamic.accents` is `sf sfz rfz fp`. `pppp`, `ffff`, and LilyPond's `sfp spp sff fz` are in the dropped lists, not the catalog.
   - `abc/decoration_mapper.rb:34-38`: build the entries from `Dynamic.accents` (`[:note_dynamic, name_key]`) and `Dynamic.levels` (`[:level, name_key]`).
   - `lily_pond/mark_reader.rb:35-36`: derive `NOTE_DYNAMIC_COMMANDS` and `LEVEL_COMMANDS` from the same.
   - `rudiment/dynamic` loads before notation (`lib/head_music.rb:123`, :198). The writers already write `name_key` generically.
   - Specs: keep the literal lists in `decoration_mapper_spec.rb` and `mark_reader_spec.rb` as the oracle. Add to each a guard that the dropped lists (`decoration_mapper.rb:42-46`, `mark_reader.rb:38`) share no key with the catalog; in LilyPond's `MEANINGS_BY_COMMAND` a later dropped entry would silently win.

3. **Pin that markings leave style grading unchanged**
   - New `spec/head_music/style/marked_flow_grading_spec.rb`.
   - Take a two-voice published example with marks, such as a Fux first-species example with errors, and grade it with every guide in `HeadMusic::Style::Guide::ALL` through `GuideGrading.grade` (`spec/support/guide_grading.rb`), plain and marked.
   - The marked copy gets articulations, a trill, an *sfz* and an *fp*, a voice level under a held note, and a part level.
   - Compare fitness and each mark's `[code, fitness]`, since `Style::Mark` defines no `==`. Assert the example has marks, so equality can't pass trivially.
   - Build with `place` if the guides need cantus firmus and counterpoint roles, as `consonant_downbeats_spec.rb` does; otherwise use ABC.

4. **Write a voice dynamic after its last note in MusicXML**
   - `music_xml/direction_writer.rb`: add `trailing_lines(voice, bar_number, voice_number:, staff_number:)`, selecting the voice's dynamics in the bar at or after `voice.next_position`, each written with `offset_from(voice.next_position, position)`. It can't overlap `voice_lines`, since `holding_segment` (:63-68) is non-nil exactly when a position is before `next_position`.
   - `music_xml/writer.rb:172-177`: append the trailing lines after the segments, before the `<backup>`.
   - Directions carry no duration, so `written_duration` and backup (`render_plan.rb:61-66`, `writer.rb:138-148`) are unchanged, and `divisions.rb:33-38` already covers each dynamic's offset.
   - Specs: `direction_writer_spec.rb` (a `#trailing_lines` block); `writer_spec.rb` (after :754, `C D E|` with *f* at 1:4: a direction after the final note, no offset, durations still `%w[1 1 1]`); `writer_cross_staff_spec.rb` (the right hand ends early with *pp* after it); a two-voice single-staff case where voice 1 ends at 1:4.

5. **Time kern rows where nothing attacks by Humdrum's even split**
   - `kern/flow_builder.rb` (`read_data`, around :105-116): when a row has no attack, buffer it instead of reading its dynamics at `@voices.current_time`. On the next timed row (an attack or a barline) or at the end, place each buffered row's dynamics at `start + (i + 1) * (finish - start) / (n + 1)`, where `start` is the last timed row's time and `finish` is `current_time`. Rows null in every spine count toward `n`.
   - Take `start` from a barline when one comes between, not from a tie's start. `spine_voices.rb` may need to expose the last timed row's time.
   - Check that null rows mid-note don't trip the reader's error for a null token where no note sounds.
   - Specs in `kern/flow_builder_spec.rb`: `4.c` then `.` beside `p` in 3/8 gives *p* at 1:1:240; several such rows split the time evenly; the held note stays whole; a row after a barline is timed from the barline.
   - CHANGELOG: a **Breaking.** entry for the re-timing.

6. **Write a mid-note dynamic on null rows instead of cutting the note in kern**
   - `kern/data_rows.rb`: replace `cut_for_dynamics` (:38-44) with row planning. For each span between consecutive timed offsets in the bar (bar start, every attack in any `**kern` column, bar end), collect every part's dynamic offsets inside it. The grid step is the greatest common divisor of those offsets and the span, measured from the span's start. Emit a row at every grid point strictly inside the span, with dynamics on their rows and `.` in every other field; `data_rows.rb:50` already writes `.` in kern columns.
   - The grid spans all parts, since a dynamic in one part's `**dynam` makes a row in every spine.
   - Delete `SpineTokens.cut` and `FIRST_PIECE_TIE`/`LAST_PIECE_TIE` (`kern/spine_tokens.rb:36-73`), whose only caller is `data_rows.rb:42`.
   - Rests stay whole the same way. The pickup rule in `dynamic_fields.rb:61` is unchanged; confirm no null row lands before the first attack.
   - Update in `kern/writer_spec.rb` (around :251-290): "ties the part's notes where a dynamic falls in the middle of them" and "ties a note through each dynamic in it, and splits a rest into rests" now write whole values with null rows; "refuses a dynamic that splits a note into values no binary note spans" becomes "writes the note whole under a dynamic at any offset". Also `kern_round_trip_spec.rb:159`.
   - Add to `kern_round_trip_spec.rb`: the dotted quarter with *p* at 1:1:480; a whole note with *p* at 1:2; a rest across a dynamic; two voices (`*^`) holding across one; two parts with dynamics in one span at different offsets; and a kern-local assertion that dynamic positions survive `marked_melody` and `grand_staff_piano_with_dynamics`. Keep it kern-local, because LilyPond and ABC voice dynamics move by accepted design.

### Testing strategy

- One commit per step. Run the touched spec files, then `bundle exec rake` and `bundle exec rubocop -a` before each commit.
- The literal lists in the reader specs stay the oracle for step 2.
- Round-trip position assertions are the core of the kern work. The shared fixtures only check which dynamic is in force at each note, so a dynamic moved to the next attack went unnoticed; the whole note with *p* at 1:2 separates the even split from both "next attack" and "midpoint".

### Risks

- A fine grid, such as a dotted value against a dynamic at a small offset, writes many null rows. It is legal Humdrum, and a cap can come later if it appears in practice.
- MusicXML `<offset>` on the last element of a measure is valid but rarely produced, so some importers may ignore it. `<forward>` would claim time the voice doesn't hold.
- Kern still drops a trailing voice dynamic at `data_rows.rb:31-32`; that is deferred with the other formats' trailing drops.

## Review

Reviewed 2026-09-27 at `e5773334`, covering the six implementation commits (`2fdcafef` through `c0338bd6`).

### Acceptance criteria

| Criterion | Verdict | Evidence |
|---|---|---|
| MusicXML trailing voice dynamic, single staff and grand staff | ✅ | `music_xml/direction_writer.rb` `trailing_lines`, `writer.rb`; `writer_spec.rb` and `writer_cross_staff_spec.rb` |
| Two voices: direction before `<backup>`, voice and staff kept, durations unchanged | ✅ | `writer_spec.rb` (`note direction backup note`, backup 3); the cross-staff spec (backup 2) |
| A dynamic under a note or rest writes as before | ✅ | `voice_lines` unchanged; "writes nothing for a dynamic under the last note" |
| Kern reader times null-only rows by the even split | ⚠️ | `kern/dynamic_placer.rb` `pass`, and specs in `flow_builder_spec.rb`. A grace-note row is taken for a null-only row; see finding 1 |
| Writer keeps notes whole, with dynamics on null rows | ✅ | `kern/data_rows.rb` `row_offsets`; `writer_spec.rb` |
| Read-back gives the written value and position | ✅ | `kern_round_trip_spec.rb` (dotted quarter, *p* at 1:1:480) |
| Whole note with *p* at 1:2 | ✅ | `kern_round_trip_spec.rb` |
| Under a rest, and several voices holding | ✅ | `kern_round_trip_spec.rb` |
| Different parts, same span | ✅ | `kern_round_trip_spec.rb` |
| A dynamic at an attack writes as before | ✅ | the existing `writer_spec.rb` cases pass |
| Flow JSON alias and spelling duplicates | ✅ | `schema_values.rb` `catalog_keys`; `schema_values_spec.rb`, `flow_serialization_spec.rb` |
| Every guide grades a marked flow the same | ✅ | `style/guide_marked_flow_grading_spec.rb`; each side builds a fresh flow |
| ABC and LilyPond read dynamics from the catalog | ✅ | `abc/decoration_mapper.rb`, `lily_pond/mark_reader.rb`; literal oracle lists and guard specs |
| CHANGELOG **Breaking.** entries | ✅ | both entries under Changed |

### Code review findings

1. **A kern grace-note row is treated as a row with no time of its own (a regression, reproduced).** `FlowBuilder#read_data` counts only notes and rests as attacks, so a row holding only a grace token such as `8qd` joins the even split. `2c` / `.  p` / `8qd` / `2e` reads the *p* at 1:1:640 instead of 1:2, and `2c` / `8qd  p` / `2e` at 1:2 instead of 1:3, which `main` got right. A grace row sits at the next note's time, so it should close the buffer as a timed row there. The writer never writes grace notes, so round trips are unaffected; files from elsewhere are.
2. **The kern writer's null-row count grows with tick resolution.** A whole note with a *p* at `1:1:001` writes 3,839 null rows. It reads back exactly and is fast, and it is bounded at one row per tick of the span. The `RenderError` that capped this came out with `SpineTokens.cut`. Decide whether to cap it and raise, or pin the behavior.
3. **Kern still drops a part dynamic after the flow's last note in a bar** (`kern/data_rows.rb` `dynamic_offsets`; it was already the case on `main`). [Place Dynamics Where No Note Starts](../backlog/place-dynamics-where-no-note-starts.md) records only the voice case, so it should name part dynamics too.

### Resolution

- Finding 1 is fixed in `cd807587`: a row holding only a grace note is timed at the note it leads to, and both inputs are pinned in `kern/flow_builder_spec.rb`.
- Finding 2 is pinned rather than capped, in `b71a1796`: a dynamic one tick into a whole note writes 3,839 null rows. Positions resolve no finer than a tick, so the count is bounded, and it reads back exactly.
- Finding 3 goes to the backlog story, renamed [Place Dynamics Where No Note Starts](../backlog/place-dynamics-where-no-note-starts.md) to cover part dynamics.

Checked and correct: `rational_gcd` on reduced rationals; the round trips for pickups, short final bars, 6/8, and two parts attacking at different times; spine splits and joins between buffered rows; `trailing_lines` against `voice_lines` and `voice_rest_lines`; and the error message and ordering in `catalog_keys`.

## Learnings

- **Reproducing every open item before writing the story changed two of them.** The review said kern splits a note on reading; it splits on writing. And the MusicXML drop was real, with no error. A story written from the review's words alone would have aimed at the wrong code.
- **Checking the plan's premise saved the kern work.** Taking out the writer's split was not enough: the reader put a row with no attack at the next attack, so every mid-note dynamic would have moved and the suite would have stayed green. The shared fixture `expect_same_markings` compares the level in force at each note, not where each dynamic sits, so it could not see the move. A round trip that is meant to keep positions has to assert positions.
- **Reader before writer kept each commit true.** Changing the reader first meant no commit wrote files that read back wrong.
- **Where state lives follows what it needs.** Buffering untimed rows in `FlowBuilder` failed because the spines have ended by the time the file does, so a buffered row's part can no longer be looked up. `DynamicPlacer` resolves the part when it reads the row and fills in the time later.
- **"Attack" was standing in for "timed row", and the two differ.** A grace-note row attacks nothing the model keeps, but in Humdrum it has a time. When adopting another system's convention, list every token type that convention classifies, instead of reusing the nearest existing predicate. The review caught this; the plan did not.
- **Removing a refusal can remove a limit.** `SpineTokens.cut` raised on a split no binary value spans, which also capped how finely kern could place a dynamic. Without it, one tick into a whole note writes 3,839 null rows. It is bounded and correct, but it only came to light because the review went looking.
- **Run a spec against the old code to see that it tests anything.** Stashing each fix showed that the new specs fail without it, and showed that three kern round-trip specs pass either way. Those three stay as position guards, and the implementation summary says so.
- **Explain terms before asking for a decision.** The first round of questions used "null-token row", "kern split", and "offset" without explaining them, and the answers came back as questions. Laying out the mechanism first would have saved that round.
