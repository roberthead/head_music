<!--
metadata:
  created_at:   2026-10-21T11:25:49-07:00
  activated_at: 2026-10-21T11:52:19-07:00
  planned_at:   2026-10-21T14:38:30-07:00
  finished_at:
  updated_at:   2026-10-21T14:38:30-07:00
-->

# Story: ABC Voices, Meter Changes, and Key Changes

## Summary

AS a developer using HeadMusic

I WANT ABC to write every voice of a flow and to read and write meter and key changes after the opening

SO THAT a chorale, or a piece that changes meter or key, survives an ABC round trip, fermatas and common- and cut-time symbols included

Split from [Timeline Expressions](../done/timeline-expressions.md), whose criteria for fermatas in every voice and for symbol-only meter changes exclude ABC.

## Background

- The ABC reader reads `V:` voices, but `RenderPreflight#ensure_single_voice` raises "multi-voice ABC output is not supported".
- A meter or key change after the opening raises both ways. The reader treats a body `M:` or `K:` line, or an inline `[M:3/4]` or `[K:D]`, as an unsupported feature. The writer refuses every entry in `flow.meter_changes` and `flow.key_signature_changes`, so neither `[M:3/4]` nor a symbol-only `[M:C|]` can be written.
- A transposed part that changes instrument is refused for the same reason: it needs a second `K:` field.
- Until this story lands, a timeline fermata is written as a mark in ABC's one voice only, and a change of meter symbol alone cannot be written.
- The reader gives each `V:` id its own part and voice, with the id as the voice's role. A header `V:` line keeps only its first word, dropping `clef=` and `nm=`, but a body `V:` line keeps its whole value, so `V:S clef=bass` in the body starts a voice named `S clef=bass`.
- Every `V:` switch ends the voice it leaves, closing its ties and tuplets, so music written in voices interleaved by line cannot tie across a line break.
- No ABC tool is installed yet. LilyPond is the only outside check the specs use today.

## Acceptance Criteria

### Writing voices

- [ ] The writer writes each voice under its own `V:` field, with the parts' dynamics in the voice that sounds them
- [ ] A flow of one voice is written exactly as before, with no `V:` field
- [ ] A voice's `V:` id is its role when the role is non-empty, holds no whitespace or `]`, and no other voice has it; otherwise it is the voice's position in the flow (`V:1`, `V:2`, …)
- [ ] The writer declares each voice in the header in the flow's voice order, and the voices read back in that order with their roles
- [ ] The writer interleaves the voices by line, switching voice on each line of bars, as a score is laid out in systems
- [ ] Every voice breaks its lines at the same bars; a bar in which a voice has no music, before it enters or after it ends, is written as a whole-bar `z` lasting that bar's meter, and reads back as a rest
- [ ] Bar lines, repeats, and voltas are written in every voice; `[Q:]` fields, tempo annotations, `[P:]` labels, and navigation decorations are written in the first voice only
- [ ] A part's dynamics and hairpins are written in that part's first voice; two voices may each hold a hairpin at the same time
- [ ] A timeline fermata is written as `!fermata!` on each voice event sounding when it begins, in every voice

### Reading meter and key changes

- [ ] The reader reads a body `M:` line and an inline `[M:…]` field, including `M:C` and `M:C|`, as a meter change at the bar where it appears
- [ ] The reader reads a body `K:` line and an inline `[K:…]` field as a key signature change at the bar where it appears
- [ ] A meter or key field in any one voice changes the flow's meter or key at that bar, even when the other voices do not repeat it
- [ ] A meter or key field stated only in a voice read after another voice places and spells the earlier voice's music in the changed meter and key, as if every voice had stated it
- [ ] A meter or key field that restates what is in force makes no change; `[M:C]` after `M:4/4` and `[K:Bm]` after `K:D` are changes
- [ ] When two voices state different meters, or different keys, for the same bar, the flow takes the first one read, and a voice that states its own key keeps it for spelling its own pitches
- [ ] A meter field in the middle of a bar takes effect at the next downbeat; a key field in the middle of a bar respells that voice's following pitches at once and changes the flow's key at the next bar line
- [ ] After a key change, each voice spells its pitches in the new key, and a note tied across the bar line into the change reads back at its pitch
- [ ] A tie, slur, or tuplet continues across a `V:` switch
- [ ] The reader reads a body `V:` line by its first word, so `V:S clef=bass` continues voice `S`
- [ ] A `K:` value holding `clef=` or other `name=value` terms reads only its key, and `[K:clef=bass]` changes nothing

### Writing meter and key changes

- [ ] The writer writes each meter change, including one that changes only the symbol, and each key change, in every voice, and they read back the same
- [ ] Meter and key changes are written as inline `[M:…]` and `[K:…]` fields at the start of the bar, after any volta and part label, never as body `M:` or `K:` lines
- [ ] A meter or key change at a bar the writer does not write raises instead of being dropped
- [ ] A transposed part that changes instrument is written with a `[K:…]` field in that part's voices, instead of raising
- [ ] In transposed output, each voice's opening key and key changes are its own part's written key

### Round trips and oracles

- [ ] The ABC round-trip comparison checks voices in order with their roles, and the meter changes (with symbols) and key changes by bar
- [ ] `TimelineExpressionFixtures.chorale` round-trips through ABC, as does a fixture with meter and key changes in more than one voice
- [ ] Fixtures left out of the ABC round-trip specs only for having more than one voice are included (`tuplets_in_two_voices`, and the two-voice variants of `tied_under_two_fermatas` and the hairpin generator)
- [ ] Oracle specs render the multi-voice, meter-change, and key-change output with abcm2ps and fail when it exits non-zero or prints a line containing `warning` or `error`, skipping with setup instructions (`brew install abcm2ps`) when it is missing

## Notes

- Multi-voice ABC needs a policy for voices that disagree on where a bar line falls. A flow's bars are shared, so this should not happen, but the writer should check it.
- The reader is lenient on purpose: many tunes write `M:` or `K:` in the first voice only, and ABC tools differ on whether such a field reaches the other voices. The writer is strict on purpose, putting the field in every voice so that no tool has to guess.
- The `[K:…]` for an instrument change goes in that part's voices only, and under the any-voice rule it reads back as a key change of the flow. Transposed output is not expected to round-trip; a spec pins what it reads as.
- A voice padded with `z` bars reads back with rests the original lacked, as kern's padded voices do.

### Deferred

- **Voice names, clefs, and `%%score`.** The reader keeps none of `nm=`, `clef=`, or `%%score`, so writing them cannot round-trip. Until it does, a role such as `Violin I` falls back to a numbered id.
- **Polymeter.** `Timeline` holds one meter map for the whole flow.
- **`K:none`, `K:HP`, and explicit accidentals in `K:`.** `KeyMapper` raises on them in the header, and the body behaves the same.
- **Changes in a flow with a pickup.** The ABC reader reads no pickup, so such a flow cannot round-trip.
- **Lyrics for each voice (`w:`).** They belong to [Lyric Extenders](../backlog/lyric-extenders.md), which builds on the per-voice layout this story sets up.

## Implementation Plan

### Overview

The reader stops reading each voice to its end at a `V:` switch and instead replays all voices in time order, as the LilyPond reader does (`lib/head_music/notation/lily_pond/flow_builder.rb:69-79`). That makes a meter or key field in any one voice govern every voice's music in that bar, and lets ties, slurs, and tuplets cross a line break. Body `M:` and `K:` lines and inline `[M:…]` and `[K:…]` fields become meter and key changes, and pitches are spelled in the key in force for each voice at each note.

The writer moves onto the shared `HeadMusic::Notation::RenderPlan`, as kern, LilyPond, MEI, and MusicXML already have. A new `ABC::VoiceWriter` writes each voice, the body interleaves the voices four bars at a time, and `[M:]` and `[K:]` fields go at the start of the bar in every voice.

The reader steps come first, so every writer step can be checked by a round trip.

### Steps

Each step is one commit with its CHANGELOG line, followed by `bundle exec rubocop -a`.

1. **Add the abcm2ps oracle.**
   - Add `abcm2ps: Oracle.new(-> { which("abcm2ps") }, "brew install abcm2ps")` to `Oracles::ALL`, beside verovio.
   - Add `spec/support/abcm2ps_toolchain.rb`, modelled on `LilyPondToolchain#compile_warnings` (`spec/support/lily_pond_helpers.rb:~135`). It writes the tune to a temp directory, runs `Open3.capture2e("abcm2ps", "-O", out, path)`, and returns the lines matching `/warning|error/i`, plus a failure on a non-zero exit. abcm2ps prints a banner on every run, so the helper matches lines rather than failing on any output.
   - Add `spec/head_music/notation/abc_abcm2ps_spec.rb`, tagged `oracle: :abcm2ps`, rendering `TimelineExpressionFixtures.melody` with no warnings. Later steps add cases.

2. **Read a body `V:` line by its first word, and skip `name=value` terms in `K:`.**
   - `BodyLexer#field_token` (`body_lexer.rb:59`) keeps `value.split.first` as the voice id, as `Header#store_field` does (`header.rb:92`).
   - `KeyMapper` drops `clef=`, `middle=`, and other `name=value` terms before mapping (`key_mapper.rb:10, 114-121`). A value holding only such terms maps to no key change. `K:none`, `K:HP`, and explicit accidentals keep raising.
   - Specs: `body_lexer_spec.rb` (`V:S clef=bass` continues `S`); `key_mapper_spec.rb` (`D clef=bass` is D, `clef=bass` alone is no key); `parser_spec.rb` (a tune with `V:` attributes reads two voices, not four).

3. **Replay the voices in time order in the reader, with no change in output.**
   - `Parser#interpret` splits the token stream into one stream per `VoiceState`. The `:voice_change` tokens are used up by the split. Tokens before any `V:` go to the current voice, as `voice_registry.rb:45` does today. Leading `Q:`, `P:`, and annotation tokens that belong to no voice are handled first.
   - Then it repeatedly handles the next token of the stream whose cursor is lowest. At equal cursors, untimed tokens (fields, bar lines, decorations) come before notes, then voices in declaration order. Borrow `Cursor#sort_key` from `lily_pond/flow_builder.rb`.
   - A `V:` switch no longer ends a voice (`parser.rb:160-166`). `end_voice`, which closes notes, overlays, invisible rests, and tuplets (`voice_state.rb:129-135`), and `bar_marks.leave`, run only in `finish` (`parser.rb:188-194`). Do not add a suspend step that calls `@tuplets.close`, which would drop a tuplet's ratio mid-group.
   - `Parser#handle_tuplet` reads the meter at the voice's bar instead of `header.meter` (`parser.rb:86-87`).
   - Specs: every existing ABC reader spec passes unchanged. New `parser_spec.rb` cases: a note tied across a line break into the other voice's line reads as one tied note, and a tuplet left open across a `V:` switch keeps its ratio. Revisit `parser_spec.rb:769` and `:1022` if their premise was the switch ending the voice.

4. **Read meter fields.**
   - `BodyLexer#field_token` emits `{type: :meter}` for `M:` and `{type: :key}` for `K:` instead of `:unsupported`. `LineScanner#scan_bracket` matches `[M:…]` and `[K:…]` before the `INLINE_FIELD_PATTERNS` fallback (`line_scanner.rb:~133-139`). `[M:C|]` is safe there, since `scan_bar_line` matches only `[|`.
   - `Header.resolve_meter` becomes a class method, so the body parses meters the same way, `C` and `C|` included.
   - A new `ABC::TimelineFields` records a meter field with `flow.change_meter` at the stating voice's bar, or at the next downbeat when the voice is mid-bar. It skips a restatement through `TimelineReading.same_meter?` (`timeline_reading.rb:46`), made public; because it compares symbols, `[M:C]` after `M:4/4` is a change. The first statement for a bar wins, so the writer's change in every voice reads back as one change.
   - Retarget the "unsupported inline field" examples (`body_lexer_spec.rb:355,540`, `parser_spec.rb:890,1428`) to a field that stays unsupported, such as `[I:…]`.
   - Specs (`parser_spec.rb`): a body `M:3/4` line; `[M:3/4]`; `[M:C]` and `[M:C|]` changing only the symbol; a field in voice 2 only, with voice 1 written first, placing voice 1's bar at 3/4 positions; a restatement in every voice making one change; disagreeing voices, the first read winning; a mid-bar field taking effect at the next downbeat; a tuplet after a change to a compound meter.

5. **Read key fields, spelling each voice in its own key.**
   - `TimelineFields#key` records `flow.change_key_signature` at the bar, or at the next bar line when the voice is mid-bar. The first statement wins, checked with `timeline.key_signature_change_at`, because `change_key_signature` silently replaces an earlier change at the same bar (`timeline.rb:122-133`). A restatement of the same signature and key name is skipped.
   - A voice spells its pitches in its own latest `[K:]` until the flow next changes key, and otherwise in the flow's key at the current bar. `PitchBuilder` stops freezing its key at construction (`pitch_builder.rb:19-21`) and takes it per call from something like `VoiceState#spelling_key`. `ChordReader` and `GraceReader` go through the same path (`parser.rb:82,106`). Looking up the key at each pitch, rather than adopting it at the bar line, keeps the replay correct when a bar line is handled before another voice's `[K:]` at the same position.
   - Specs: `[K:D]` in voice 1 spells voice 2's `F` as F♯ in that bar; a voice stating its own disagreeing key keeps its own spelling while the flow keeps the first key; a mid-bar `[K:]` respells the rest of that voice's bar and changes the flow at the next bar line; `pitch_builder_spec.rb` takes the key per call.

6. **Move the writer onto `RenderPlan` and a per-voice writer, with no change in output.**
   - Add `ABC::RenderPlan < Notation::RenderPlan`, whose `key_value(event)` returns the key signature, mapped to text by `KeyMapper.abc_value`.
   - Lift `lead?` (`lily_pond/render_plan.rb:72-74`) and the music-end logic (`lily_pond/render_plan.rb:20-35,116-120`) into the base `RenderPlan` rather than copying them.
   - Move everything `Writer` does for `flow.voices.first` into `ABC::VoiceWriter`: position marks, slur and tuplet writers, segments, `ensure_marks_reachable`, `bar_strings`, and `written_bars` (`writer.rb:40-145`). `Writer` keeps the header, with `K:` from `plan.first_measure_key(first part)`, and the assembly.
   - Specs: `writer_spec.rb` and `abc_round_trip_spec.rb` pass byte for byte; add `voice_writer_spec.rb` and `render_plan_spec.rb`.

7. **Write meter and key changes.**
   - Delete `RenderPreflight#ensure_no_mid_piece_changes` (`render_preflight.rb:43-46`) and add a check that raises for a change at a bar outside `plan.bar_numbers`. Changes are keyed by bar, so that is the only way a change can miss a bar line. Update the class comment.
   - `VoiceWriter` writes the fields after `BarLineWriter.opening`, in the order volta, `[P:]` (lead voice only), `[M:…]`, `[K:…]`, `[Q:]` (lead voice only). `[M:…]` goes through `Writer::METER_SYMBOLS`, so `[M:C|]` changes only the symbol. The inline form is always used, even at a line's start.
   - Each bar is spelled in the key in force there: `BarWriter#bar(bar_segments, key_signature)` passes it to `PitchWriter#start_new_bar(key_signature)`, replacing the memoized `written_key_signature` (`writer.rb:66-70`). A note tied into a change is written under the new key, so it reads back at its pitch.
   - Specs: replace the refusals at `writer_spec.rb:~260-285` and `render_preflight_spec.rb:~17-27` with output expectations; round-trip `LilyPondFixtures.key_and_meter_change`, `tie_into_key_change`, and `tie_into_meter_change` (`spec/support/lily_pond_fixtures.rb:162-210`) and a symbol-only change (as in `mei_timeline_expressions_spec.rb:45`); add oracle cases.

8. **Write every voice, interleaved by line.**
   - Delete `ensure_single_voice`. Declare each voice with a `V:` line before `K:`; a single-voice flow writes no `V:` field. The id is the role when it is non-empty, holds no whitespace or `]`, and is unique; otherwise the voice's 1-based position.
   - The body walks `plan.bar_numbers.each_slice(BARS_PER_LINE)`, and for each slice each voice writes `V:id` and its line.
   - A bar the voice is silent in is a whole-bar `z` lasting that bar's meter (`z8` in 4/4, `z6` in 3/4, with `L:1/8`), and a voice that ends early is padded to the end. Not `x`, which abcm2ps draws as nothing, and not `Z`, which the reader rejects (`line_scanner.rb:49`).
   - Bar lines, repeats, and voltas go in every voice; `RepeatTagger` tracks state per voice and sets values only on the flow's bars (`repeat_tagger.rb:23-49`). `[Q:]`, tempo annotations, `[P:]`, and navigation decorations go in the lead voice only, passing `lead:` to `BarLineWriter.opening/closing` and `PositionMarks`, as the LilyPond writer does (`lily_pond/bar_mark_writer.rb:11`). A second `"^rit."` at the same position would add a second ramp step, and abcm2ps would print navigation on every staff.
   - A part's dynamics and hairpins go in its first voice: `PositionMarks.new(voice, lead:, part:)` adds `voice.part`'s levels and spans only when `part:` is true (today it adds them for every voice, `position_marks.rb:82-97`). `ensure_dynamics_fit_one_voice` becomes a check per voice.
   - `FermataMarks.carriers(flow)` already supplies `!fermata!` on each event sounding when a timeline fermata begins, so each `VoiceWriter` carries its fermatas.
   - Strengthen `ABCRoundTripHelper#expect_abc_round_trip` (`spec/support/abc_round_trip.rb`) to compare voices in order with their roles, and `meter_changes` and `key_signature_changes` by bar.
   - Specs: round-trip `TimelineExpressionFixtures.chorale`; a two-voice fixture with meter and key changes in every voice; one with the changes in the second voice only, reading the same. Flip `abc_round_trip_spec.rb:281` (`tuplets_in_two_voices`) and `writer_spec.rb:~245-255`; remove the comment at `flow_serialization_spec.rb:7`; give `flow_spec.rb:307` another way to make the writer raise. Pin a late-entering voice's `z` bars and rests, the id fallback (`cantus firmus`, a duplicate role), a fermata in every voice, and simultaneous hairpins in two voices. Add oracle cases for the chorale and the multi-voice change fixture.

9. **Write an instrument change in transposed output.**
   - Delete `ensure_no_instrument_change` (`render_preflight.rb:48-54`). `VoiceWriter` writes `plan.measure_key_changes(voice.part)[bar]`, which already includes `instrument_change_keys` (`render_plan.rb:103-111`), so the `[K:]` lands in that part's voices only. An instrument change and a flow key change in the same bar make one `[K:]`; an instrument change that leaves the written key alone writes nothing.
   - The header `K:` is the first voice's part's opening written key, and any other voice whose part opens in another written key gets a `[K:…]` at the start of its first bar. This fixes a latent bug: `transposition` takes the first voice's instrument (`writer.rb:72-75`), so a transposed score for clarinet and flute writes the clarinet's key for the flute.
   - Specs: flip `layout_transposition_spec.rb:~195-197` to expect the clarinet's written `[K:]` at the change, in its voice only; a two-part transposed score with a written key per voice; pin what the reader makes of that output.

10. **CHANGELOG and bookkeeping.**
    - **Added:** ABC writes every voice under `V:`, interleaved by line, with silent bars as whole-bar rests, and tempo, part labels, and navigation in the lead voice. ABC reads and writes meter changes (body `M:` and inline `[M:…]`, including `C` and `C|`) and key changes, a field in any one voice changing the flow. Transposed ABC writes each part's written key, and an instrument change as a `[K:]` in that part's voices.
    - **Changed:** a tie, slur, or tuplet continues across a `V:` switch; a body `V:` line is read by its first word; `K:` skips `name=value` terms. **Breaking.** ABC tunes with body `M:` or `K:` fields or several voices no longer raise `UnsupportedFeatureError` or `RenderError`. **Breaking.** The signatures of `ABC::BarWriter#bar`, `ABC::PitchWriter#start_new_bar`, `ABC::PositionMarks.new`, and `ABC::PitchBuilder` change.
    - Tick off the criteria, and repoint the links to `../backlog/abc-voices-and-meter-changes.md` in `user-stories/done/timeline-expressions.md` to `../current/`.

### Testing Strategy

- Build fixtures with `HeadMusic::Notation::ABC.parse` or existing fixtures, never with placement loops.
- Steps 3 and 6 are refactors: every existing ABC spec passes unchanged.
- Each ordering hazard gets a spec: a tie and a tuplet across a `V:` switch; a change stated only in a later voice; changes in different voices that depend on each other's bar counting; a `[K:]` in one voice respelling another in the same bar; ties into key and meter changes; a symbol-only change; a restatement in every voice making one change.
- The abcm2ps oracle covers the melody, the chorale, the multi-voice change fixture, and transposed output, under `bundle exec rake oracles`.
- `bundle exec rake validate` keeps coverage at 90% or above.

### Risks

- **Replay ordering.** It relies on ABC placing each note only when the next one arrives (`voice_state.rb:214-222`), and on the exact tie-break at equal cursors. Overlays (`&`) and grace notes inside the replay are the most likely to surprise.
- **Field order beside voltas and part labels.** Whether abcm2ps accepts `[M:]` and `[K:]` next to `[2` and `[P:]` is unverified; the oracle decides, and reordering is cheap.
- **Numbered fallback ids lose the role.** `Violin I` reads back as `1` until the reader reads `nm=`.
- **A transposed lead voice decides the flow's key on read-back** at a real key-change bar, since its written key is read first.
