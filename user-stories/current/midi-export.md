<!--
metadata:
  created_at:   2026-09-24T18:58:30-07:00
  activated_at: 2026-10-15T11:05:36-07:00
  planned_at:   2026-10-15T11:19:33-07:00
  finished_at:
  updated_at:   2026-10-15T11:19:33-07:00
-->

# Story: MIDI Export

## Summary

AS a developer using HeadMusic

I WANT to render a `HeadMusic::Content::Flow` as a Standard MIDI File

SO THAT I can hear what I have composed or generated, and hand it to DAWs, sequencers, and synthesizers

## Background

A Standard MIDI File (SMF) is a binary format of timed events. It has note on and note off with a key number and velocity, and meta events for tempo, time signature, key signature, track names, and lyrics. MIDI records performance, not spelling: C♯ and D♭ are the same key number, and durations are ticks rather than note values.

The model now holds most of what a performance needs:

- **Pitch and time.** `Pitch#midi_note_number`, the timeline's meter, key, and tempo changes, and `HeadMusic::Time` for positions.
- **Order of play.** `Flow#performance_order` unfolds repeats, endings, D.C., and D.S. into the bars as played.
- **Loudness.** `Voice#dynamic_at` answers the dynamic level in force at a position from the voice's and the part's dynamic events. Note dynamics (*sf*, *sfz*, *rfz*, *fp*), articulations, and hairpins are held too.
- **Instruments.** Parts have instruments, with mid-piece instrument changes and sounding transpositions. Unpitched sounds name their instrument.

Two things are missing. The instrument catalog has no General MIDI program numbers, and unpitched instruments have no GM percussion key numbers. This story adds both.

## Example

```ruby
bytes = flow.to_midi
File.binwrite("exercise.mid", bytes)
```

## Acceptance Criteria

### Entry point and file

- [ ] `HeadMusic::MIDI.render(flow, **options)` and `Flow#to_midi` return a binary `String` (`Encoding::BINARY`) holding a format 1 SMF. Lyric and name texts are UTF-8 bytes with byte-length prefixes. The same flow gives the same bytes
- [ ] Track 0 is the conductor track. It holds the sequence name (from the flow's name), and the tempo, time-signature, and key-signature meta events
- [ ] Every part gets one track, in `flow.parts` order, including a part with no notes. The track name comes from the part's player name, else its instrument's name, else its first voice's role; with none, no name is written
- [ ] A part takes a pitched channel when it holds a pitched sound, and pitched channels are 1–9 and 11–16 in part order. Its unpitched sounds go to channel 10 within its own track, and no program change is written on channel 10
- [ ] Pitched parts that play the same instrument throughout share one channel, each keeping its own track. `MIDI::RenderError` is raised only when more than fifteen distinct pitched channels are needed, and it names the count
- [ ] Ticks per quarter note are the least common multiple of 480 and the denominators of every onset and release the file writes, articulation shortening and grace notes included, computed exactly from written values and ratios, so a septuplet is exact in MIDI though the model rounds it. When that exceeds 32767, the writer uses 960 and rounds each onset and release to the nearest tick, keeping every note at least one tick long
- [ ] A flow with no voice events raises `MIDI::RenderError` from a preflight, before any bytes are written. A flow of rests only renders a valid file with no notes
- [ ] A sounding key outside 0..127 raises `RenderError`, naming the pitch and its position, before any output
- [ ] Tempo is round(60,000,000 / (bpm × beat value in quarters)), so a dotted quarter at 60 writes 666,667. Time signatures write clocks per click as 24 × the beat value in quarters (6/8 → 36) and 8 thirty-seconds per quarter. A meter whose denominator is not a power of two, or a tempo of 0 bpm, raises `RenderError`. Key signatures beyond seven fifths are written enharmonically
- [ ] A file begins at the pickup's first onset. When the pickup's length is a whole number of the meter's unit, it gets its own time signature, and the flow's meter follows at bar 1

### Notes

- [ ] Each pitched note event writes note on and note off at its ticks, and a chord writes one per pitch; rests write nothing
- [ ] Tied notes sound as one note, not re-struck. A note tied over a barline sounds into the next played bar only when that bar follows it in the score; otherwise it releases at the barline, and a tie arriving from a bar that was not just played strikes fresh
- [ ] When a note on a channel's key begins while that key is held, the held note is released and the key struck again at the new onset, then sounds until the later of the two releases. This applies across percussion parts on channel 10
- [ ] Grace notes sound on the beat, taking time from the main note. A lone acciaccatura sounds as a thirty-second. A lone appoggiatura takes half the first link of its main note. A group of two or more sounds a thirty-second each. A group never takes more than half the main note, and shares that half equally when it would. A grace note tied to its main note's key sounds through the main note and is not struck again. Grace notes take the main note's dynamic level, without its note dynamic or articulations, and add their own articulations; before an *fp*, that is the level in force before it
- [ ] Staccato sounds for half the note's value, staccatissimo for a quarter, staccato with tenuto (portato) for three quarters, and tenuto for all of it; other notes sound for their full value. Staccatissimo wins over staccato, and shortening applies to the last link of a tied chain
- [ ] Unpitched note events go to channel 10, at the GM percussion key their instrument names, or at `DEFAULT_PERCUSSION_KEY` when it names none
- [ ] With `transposed: true`, each pitch is read as written and sounds at its written pitch plus the sounding transposition of the part's instrument in force at its bar. A part with no transposing instrument sounds as written. The key signature stays concert

### Order of play

- [ ] Bars are written in `Flow#performance_order`, so repeats, endings, D.C., and D.S. are played out, including the tail bar of a final tied note
- [ ] At each played bar, the writer writes the tempo, meter, and key signature in force whenever they differ from the last written, so a repeat or D.C. to before a change restores the earlier values. A part's program change follows the same rule

### Loudness

- [ ] `HeadMusic::MIDI` defines frozen constants, each pinned by a spec: velocities ppp 16, pp 32, p 48, mp 64, mf 80, f 96, ff 112, fff 127; a default level of *mf*; accent +16, marcato +24, *sf*/*sfz* +24, *rfz* +16, adding together. Velocities are clamped to 1..127
- [ ] A note's velocity comes from the dynamic level in force at its onset, as `Voice#dynamic_at` answers it, or the default with none
- [ ] A note dynamic of *sf*, *sfz*, or *rfz* raises that note's velocity by its documented amount. An *fp* note sounds at *f*'s velocity, though `Voice#dynamic_at` at its onset answers *p*; the notes after it sound at *p*
- [ ] Accent and marcato raise a note's velocity by their documented amounts
- [ ] Under a hairpin, a note's velocity is interpolated by its onset. The ramp runs from the level in force at the hairpin's start to the level placed at its end. When no level is placed at its end, the ramp runs to one level beyond the start, in the hairpin's direction, and that level stays in force after it until the next placed level. A level placed inside a hairpin ends the ramp there
- [ ] A voice hairpin applies to its own voice, and a part hairpin to every voice of the part. The innermost hairpin governs, a voice's over its part's

### Instruments

- [ ] Every instrument records a GM program, and every unpitched percussion instrument a GM percussion key, using the nearest GM sound, except those named in an explicit exclusion list in the specs. Programs are stored 1-based
- [ ] Every pitched part writes a program at its start, and another at each instrument change: its instrument's GM program, or 1 (Acoustic Grand Piano) when it has none

### Lyrics

- [ ] Each syllable writes a lyric meta event at its note's onset, with a hyphen after it when `hyphen_after` is set
- [ ] On pass *n* of a repeat, a note sings verse *n* when the flow has a verse *n*, and verse 1 otherwise. When two voices of a part sing at one onset, the first voice's syllable is written

### Verification

- [ ] Specs decode the bytes with a reader in `spec/support` and assert on events and ticks, not on raw byte strings alone. MIDI Import may promote that reader into the gem
- [ ] The ABC, LilyPond, and kern fixtures, and the MusicXML fixtures `marked_da_capo_al_fine`, `marked_dal_segno_al_coda`, `clarinet_changes`, and `two_verses`, each render, and their decoded notes match the flow's key numbers and onsets
- [ ] When MuseScore is available, a spec converts rendered fixtures through it and compares their pitches
- [ ] A rendered fixture opens in at least one real MIDI tool (MuseScore, GarageBand, `timidity`, or `fluidsynth`) without errors, checked by hand and recorded in the story
- [ ] Maintains 90%+ test coverage

## Notes

- The SMF is written without a dependency, with `Array#pack` and a variable-length quantity helper, and without running status.
- Note velocities are fixed at each attack. Swelling a held note through a hairpin would take controller 11 (expression) events, and that is a follow-up: a controller acts on the whole channel, so it would swell other parts sharing channel 10 or a shared channel.
- **Follow-up: ornament realization.** Trills, mordents, and turns sound as plain notes. A realization depends on style and tempo: the starting note, the speed, and where the trill ends. The speed depends on rit. and accel., which the `Conductor` cannot follow until Timeline Expressions lands.
- **Waits on Timeline Expressions:** fermatas, ritardandos, and accelerandos come with [Timeline Expressions](timeline-expressions.md), which teaches the `Conductor` to keep time through them. The writer should then write the matching tempo events.
- A MIDI key signature holds only major or minor. A tonal context in another mode writes its signature as major.
- **No `Layout#to_midi` in v1.** An SMF is one sequence, so several flows would have to be joined or written as several files. The caller can render each realized flow instead. Several flows would need format 2, which MIDI Import does not read, so the output could not round-trip.
- **No pan, volume, bank select, or GM System On.** The model holds no data for them, so any value would be invented.
- **Hand check** (2026-10-15). Speed the Plough, rendered at division 480 and converted with `mscore -o speed.musicxml speed.mid` by MuseScore 4, wrote its MusicXML without errors, and that file reads back with the render's 104 pitches in order. The gated `spec/head_music/midi/muse_score_spec.rb` repeats this for every fixture.

## Decisions

- **The module is `HeadMusic::MIDI`** (decided 2026-10-14), beside `Notation` and `Time`, since MIDI holds performance, not notation. `MIDI::RenderError` and `MIDI::ParseError` live there, and [MIDI Import](midi-import.md) builds in the same module.
- **One track per part** (decided 2026-10-14). A part is one instrument, which in MIDI means one channel and one program. This matches how scorewriters export.
- **Dynamics, accents, and hairpins shape velocity in v1** (decided 2026-10-14). This reverses the original constant-velocity scope, since the model now holds all three.
- **This story follows MusicXML Import** in the backlog order (decided 2026-10-14), and so lands after [Tuplets and Grace Notes](tuplets-and-grace-notes.md). That is why the tick resolution and grace-note criteria cover them.

- **`MIDI::RenderError` subclasses `HeadMusic::Notation::RenderError`** (decided 2026-10-15), matching the four existing writers so one rescue clause covers every writer, though MIDI is not notation.
- **Planning choices adopted without stopping to ask** (2026-10-15, while running the seven-story goal; Rob may revise any). All of the planner's proposed story changes were adopted:
  - same-key overlaps re-strike rather than merge, since merging loses an inner voice's repeated attack;
  - pitched parts on one instrument share a channel, so an orchestral flow fits;
  - the tick resolution is the least common multiple of 480 and every emitted time, so staccato and grace notes stay exact and tools never see a division of 1;
  - every pitched part writes a program, 1 when its instrument has no GM program, so a repeat or shared channel never plays a stale one;
  - the default percussion key is 76 (Hi Wood Block), a neutral click that does not pose as a drum kit;
  - key signatures beyond seven fifths are written enharmonically rather than raised;
  - unpitched sounds in a pitched part go to channel 10 within the part's track;
  - the *fp*, hairpin follow-through, ties across a repeat, pickup trimming, verses by pass, and `transposed:` criteria are made exact, as the planner found the model's current answers differ from the story's wording.

- **Implementation choices made without stopping to ask** (2026-10-15; Rob may revise any):
  - A grace note takes its main note's level but not the main note's accent or marcato, which belong to the main note's own attack; before an *fp* it takes the level in force before the *fp*, not the *p* the *fp* leaves.
  - When two voices sing at one onset, the first voice with a syllable for that pass's verse wins; a note with no syllable for verse *n* sings nothing on pass *n* when the flow has a verse *n*.
  - On a shared channel, two parts striking one key at one onset sound once, in the first part's track, and a release that meets another track's strike is written in the striking track, so a player cannot reorder the two.
  - Track names use the instrument's catalog name, lowercase, as the MusicXML and LilyPond writers do.
  - GM stand-ins: euphonium and baritone horn take Tuba (59), mandolin 26, synthesizer 81, ukuleles 25, arpeggione 43, tam-tam the Chinese Cymbal key (52), and tenor drum the Low Tom key (45). Castanets have no GM Level 1 key.

## Implementation Plan

### Overview

The plan adds a `HeadMusic::MIDI` module that works in two layers:

- **A musical event builder.** It turns a flow into absolute-tick event value objects. Its input is the bars of `Flow#performance_order`, and all time is exact `Rational` whole notes from `Notation::BarSplitter`'s exact onsets. It never reads the rounded `Position` subticks. Every `RenderError` is raised in a preflight before any bytes exist.
- **A stateless byte encoder.** It writes `Array#pack`, VLQ, no running status, and an `ASCII-8BIT` result.

A decoder in `spec/support` reads the bytes back into the same event value objects, so MIDI Import can promote it by moving the file.

I consulted the product manager, the developer, and the best-practices engineer, the last because of the binary format and a measured performance hazard. I skipped the UI/UX and accessibility specialists because the story has no UI.

**Verified problems in current code that the plan depends on:**

- **The final tied note's tail bar is never played.** `lib/head_music/content/flow/performance_order.rb:39-41` bounds the order by `flow.latest_bar_number`. `Flow#last_sounding_bar_number` (`lib/head_music/content/flow.rb:138-144`) is the bound that includes it.
- **The story's *fp* criterion is wrong about the model.** `Voice#dynamic_at` answers *p* at the *fp* note's own onset. `DynamicResolver#accent_level_at` (`lib/head_music/content/voice/dynamic_resolver.rb:38-44`) finds the first event *after* the position, then walks back from there, which includes the note itself.
- **`dynamic_at` is O(n) per call, so O(n²) per voice.** It builds a resolver on every call (`lib/head_music/content/voice.rb:105-107`). With no level placed, `floor` is nil and the walk goes back to index 0 (`dynamic_resolver.rb:39-41`). The best-practices engineer measured 2000 notes with one *p* at 0.94s, and each doubling of length quadruples it. Unfolding repeats multiplies that again.
- **Hairpins are not in `dynamic_at`.** `dynamic_resolver.rb:17-21` reads only dynamic events and accents.
- **Navigation errors arrive as `ArgumentError`.** They come from `lib/head_music/content/flow/navigation.rb:25-62`. `Layout::Transposition` raises `Notation::RenderError` (`lib/head_music/notation/layout/transposition.rb:155`). The MIDI preflight must translate both.
- **`Instrument#pitched?` is false for timpani, crotales, didgeridoo, and tabla.** The cause is their `neutral_clef` in `notation_styles.yml`, according to the developer. So the channel choice must key on the sounds a part actually holds, not on `pitched?`.

### Steps

Each step is one commit, with its specs, and keeps `bundle exec rake validate` green.

0. **Let performance order reach a final tie's tail bar.**
   - Change `last_number` to `[flow.last_sounding_bar_number, flow.last_marked_bar_number].compact.max`.
   - Spec: a whole note tied from bar 3 into bar 4 plays bars `[1, 2, 3, 4]`.
   - Re-run `flow_navigation_round_trip_spec.rb` and `flow_serialization_spec.rb`, which also call `performance_order`.
   - CHANGELOG under Fixed. This is not Breaking, because the only consumers today are specs.
   - Files: `lib/head_music/content/flow/performance_order.rb`, `spec/head_music/content/flow/performance_order_spec.rb`, `CHANGELOG.md`

1. **General MIDI data in the instrument catalog.** This can run in a worktree in parallel with step 2.
   - Add `gm_program` (1-based, 1–128, as GM tables and MusicXML print it) and `gm_percussion_key` (35–81) to `instruments.yml`.
   - Read both in `initialize_data_from_record` (`lib/head_music/instruments/instrument.rb:187-196`). Add `#gm_program` and `#gm_percussion_key`, falling back to the parent the way `pitch_key` does, so variants like `clarinet_in_a` inherit.
   - Values: the developer's table, using nearest stand-ins. For example:
     - violin 41, cello 43, flute 74, clarinets 72, horns 61, voices 53, timpani 48;
     - lute 25, crotales 10;
     - bass drum 35, snare 38, hi-hat 42, crash/suspended cymbals 49, ride 51, tambourine 54, triangle 81, woodblock and temple blocks 76.
   - Explicit exclusion constants in the spec:
     - `NO_GM_PROGRAM`: didgeridoo, theremin, tabla, and the unpitched percussion;
     - `NO_GM_PERCUSSION_KEY`: drum_kit, castanets, tam_tam, tenor_drum, tabla, timpani, crotales.
   - Specs: accessors and inheritance. A catalog spec checks that every value is in range, and that every instrument not in an exclusion list has a value. The spec names the four `pitched?`-false instruments explicitly rather than iterating over `reject(&:pitched?)`.
   - Files: `lib/head_music/instruments/instruments.yml`, `lib/head_music/instruments/instrument.rb`, `spec/head_music/instruments/instrument_spec.rb`, `spec/head_music/instruments/general_midi_catalog_spec.rb`

2. **MIDI module, event value objects, SMF encoder, and the spec reader.** This can run in parallel with step 1.
   - **Module and errors.** `lib/head_music/midi.rb` holds the module, `RenderError`, `ParseError` (with an `offset:`, mirroring `MusicXML::ParseError` at `lib/head_music/notation/music_xml.rb:20-38`), and a `Dir[...].sort` loader. `RenderError` subclasses `HeadMusic::Notation::RenderError`, as all four existing writers do (`abc.rb:35`, `kern.rb:32`, `lily_pond.rb:37`, `music_xml.rb:45`), so one rescue clause covers every writer.
   - **Require.** Add `require "head_music/midi"` after line 213 of `lib/head_music.rb`.
   - **Event value objects** (`Data.define`, with absolute ticks and 0-based wire channels):
     - `NoteOn`, `NoteOff`: `(tick, channel, key, velocity)`;
     - `ProgramChange`: `(tick, channel, program)`;
     - `Tempo`: `(tick, microseconds_per_quarter)`;
     - `TimeSignature`: `(tick, numerator, denominator, clocks_per_click)`;
     - `KeySignature`: `(tick, fifths, minor)`;
     - `Text`: `(tick, kind, text)`, where kind is `:sequence_name`, `:track_name`, or `:lyric`;
     - `EndOfTrack`: `(tick)`.

     Each has `#payload` returning binary bytes. `ProgramChange` subtracts 1 from the 1-based program only in `#payload`.
   - **Encoder** (`MIDI::SMF`):
     - `SMF.vlq(n)` accepts 0..0x0FFFFFFF and otherwise raises `ArgumentError`.
     - `SMF.file(division:, tracks:)` writes MThd with `pack("a4Nnnn")`. Each MTrk length is taken from the finished body's `bytesize`.
     - Events are sorted on `[tick, rank, insertion_index]`, because MRI's `sort_by` is not stable. The ranks are: names 0, then tempo/time/key 1, program change 2, note-off 3, lyric 4, note-on 5.
     - No running status. Note-off is `0x8n` with velocity 64. Text is written as `text.encode("UTF-8").b`, with its length from `bytesize`. Literals are written as `"MThd".b`.
   - **Reader.** `spec/support/midi_reader.rb` holds `HeadMusic::MIDI::Reader.new(bytes).read`, which returns a sequence of format, division, and tracks of the value objects above. It also has convenience methods: `Track#notes` (on/off pairs with durations), `#name`, `#lyrics`, and `#program_changes`. It accepts running status, velocity-0 note-on, and unknown chunks, which MuseScore and Import need. It raises `ParseError` with a byte offset for:
     - an over-long VLQ;
     - a chunk overrun;
     - a missing end-of-track;
     - an unknown status byte.
   - **Specs:**
     - golden bytes for the VLQ boundaries (0, 0x7F, 0x80, 0x3FFF, 0x4000, 0x1FFFFF, 0x200000, 0x0FFFFFFF, plus -1 and 0x10000000 raising);
     - MThd bytes, an empty MTrk (`00 FF 2F 00`, length 4), 6/8 as `FF 58 04 06 03 24 08`, key −3 as `FD`;
     - `"Café"` with a declared length of 5;
     - result encoding is `Encoding::BINARY`;
     - the reader on hand-built bytes, including the malformed cases.
   - Files: `lib/head_music/midi.rb`, `lib/head_music/midi/events.rb`, `lib/head_music/midi/smf.rb`, `lib/head_music.rb`, `spec/support/midi_reader.rb`, `spec/head_music/midi/smf_spec.rb`, `spec/head_music/midi/events_spec.rb`, `spec/head_music/midi/reader_spec.rb`

3. **Performance timeline, tick resolution, and preflight.** These are pure, with no bytes.
   - **`PerformanceTimeline`** walks `flow.performance_order`, which returns `PlayedBar` objects (`bar`, `pass`, `playing`, `#number`). Each `PlayedSpan` has `(played_bar, start, window_from, length)` in Rational whole notes. A bar's length is the meter's top over bottom, copied from `BarSplitter.bar_length` (`lib/head_music/notation/bar_splitter.rb:98-101`), which is private.
   - **Pickup.** A pickup bar (number < 1) is right-aligned, as `music_xml/bar_map.rb:8-12` does. Its window starts at the earliest exact onset, and this applies on every pass.
   - **`BarPieces`** cuts a sounding interval at barlines using `BarSplitter.exact_start` and `onset_in_bar` (`bar_splitter.rb:83-86`). Each piece has `continues` and `joins_previous` flags. A continuing piece stays open only when the next played bar is `n + 1`; otherwise it releases at the barline. A `joins_previous` piece with nothing open is struck fresh.
   - **`TickResolution.new(times)`** computes the LCM of 480 and the `(t * 4).denominator` of every time the writer emits. Those times include bar starts, onsets, and releases *after* articulation and grace shaping. It stops as soon as the LCM passes 32767. Otherwise it uses 960, rounds each endpoint on its own, and forces `release >= onset + 1`. It exposes `#division`, `#exact?`, and `#ticks(t)`.
   - **`Preflight`** raises `RenderError` for:
     - a flow with no voice events;
     - more than 15 distinct pitched channels needed (see step 4's channel sharing);
     - a sounding key outside 0..127, naming the pitch and position;
     - a meter denominator that is not a power of two, or a numerator above 255;
     - a tempo of 0 bpm or one outside 1..0xFFFFFF µs per quarter;
     - an absolute tick above 0x0FFFFFFF.

     It re-raises navigation `ArgumentError` and `Transposition`'s `Notation::RenderError` as `MIDI::RenderError` with the same message.
   - **Specs:** a plain flow; `NavigationFixtures.da_capo_al_fine`; a tie into a first ending that the repeat skips; the pickup trim. For resolution: quarters → 480; triplets → 480; `TupletFixtures.septuplet` → 3360; a coprime 3/5/7/11/13 mix → 960 with no zero-length note; a staccatissimo dotted 32nd stays exact. One spec per preflight error.
   - Files: `lib/head_music/midi/performance_timeline.rb`, `lib/head_music/midi/bar_pieces.rb`, `lib/head_music/midi/tick_resolution.rb`, `lib/head_music/midi/preflight.rb`, and a matching `spec/head_music/midi/*_spec.rb` for each

4. **Core writer, `MIDI.render`, and `Flow#to_midi`, with stubs for the feature collaborators.**
   - **`Writer#to_s`** runs Preflight, then the timeline, then the conductor track and part tracks (Rational times), then `TickResolution`, then `SMF`.
   - **`ConductorTrack`:**
     - The sequence name comes from `flow.name`.
     - At each played span, it writes the meter, tempo, and key in force there whenever they differ from the last ones written, so a D.C. back over a change restores the opening values.
     - Tempo is `(Rational(60_000_000) / (bpm.to_r * beat_value.fraction * 4)).round`. Dotted quarter = 60 gives 666,667.
     - `clocks_per_click` is `meter.beat_value.fraction * 96`: 4/4 → 24, 6/8 → 36.
     - Key: `sf` is `KeySignatureEvent#signature`, brought into −7..7 by ±12. `mi` is 1 only for a minor key or aeolian; other modes write major.
     - A pickup bar whose length is a whole number of the meter's unit writes its own time signature, and the flow's meter follows at bar 1.
   - **`PartTrack`:** one track per part in `flow.parts` order, including parts with no events. The track name is `part.player&.name || part.instrument&.name || first voice's role name`, omitted when none exists.
   - **`ChannelAllocator`:**
     - A part counts as pitched by its sounds (voice events and grace notes), not by `Instrument#pitched?`.
     - Pitched parts take wire channels 0–8 and 10–15 in `flow.parts` order.
     - Parts with the same instrument throughout, and no instrument changes, share one channel.
   - **`KeyOverlaps`** works per `[channel, key]`:
     - A later onset inside a held note writes note-off and then note-on at that onset, and the note releases at the latest release.
     - Touching notes re-strike.
     - On channel 10 it works across tracks.
   - **`SoundKeys`** (pitched): with `transposed: true`, the key is `pitch.midi_note_number + part.instrument_at(bar)&.sounding_transposition.to_i`. This is the bar rule of `Layout::Realization#written_voice_event`, and the conductor key stays concert.
   - **End of track:** every track ends with `EndOfTrack` at the same tick, `max(end of last played span, last release)`.
   - **Stubs** for steps 5a–5d to fill:
     - `NoteTiming` returns one piece `[0, fraction)`;
     - `VelocityResolver` returns `DEFAULT_VELOCITY`;
     - `ProgramChanges` returns `[]`;
     - `LyricEvents` returns nil;
     - unpitched sounds raise `RenderError("unpitched sounds are not yet supported")`.
   - **Entry points:** `MIDI.render(flow, transposed: false)`, and `Flow#to_midi(**options)` beside `to_kern` (`flow.rb:197-199`).
   - **Specs:**
     - format 1; track count; division; names, including the role fallback;
     - chords; ties within a bar and across a barline;
     - two voices on one key, overlapping and touching;
     - repeat unfolding; re-emitted meta after a D.C.;
     - pickup; end of track;
     - the empty flow raises, and a rests-only flow renders;
     - 16 distinct pitched parts raise, naming 16, but 16 violin parts share and render;
     - `transposed: true` across `clarinet_changes`;
     - determinism: two renders give identical bytes, and so does a `Flow.from_h(flow.to_h)` round trip.
   - **Shared invariant helper** in `spec/support/midi_reader.rb`, which every MIDI spec calls. It checks that:
     - every note-on has exactly one later note-off;
     - no key is on twice;
     - deltas are non-negative;
     - the end-of-track comes last.
   - Files: `lib/head_music/midi/writer.rb`, `conductor_track.rb`, `part_track.rb`, `channel_allocator.rb`, `key_overlaps.rb`, `sound_keys.rb`, and the stubs `note_timing.rb`, `velocity_resolver.rb`, `program_changes.rb`, `lyric_events.rb` (all under `lib/head_music/midi/`), plus `lib/head_music/content/flow.rb`, `spec/head_music/midi/writer_spec.rb`, `channel_allocator_spec.rb`, `key_overlaps_spec.rb`, `conductor_track_spec.rb`

5a. **Loudness.** This can run in a worktree in parallel with 5b–5d.
   - **Velocity constants** in `HeadMusic::MIDI`, all frozen and pinned by specs:
     - `VELOCITIES`: ppp 16, pp 32, p 48, mp 64, mf 80, f 96, ff 112, fff 127;
     - `DEFAULT_LEVEL`: mf;
     - accent +16 and marcato +24;
     - sf and sfz +24, rfz +16.
   - Boosts add together. The result is clamped to 1..127.
   - An *fp* note sounds at *f* with no boost. Later notes take *p* from the model.
   - **One forward sweep per voice** replaces calls to `dynamic_at` at each onset. It merges the voice's dynamic events, the part's dynamic events, and each note's `note_dynamic.level_after`, keeping the precedence of `dynamic_resolver.rb:26-32` (accent, then voice, then part). Results are memoized per voice event, so repeats reuse them.
   - **Hairpins:**
     - Collect `voice.spans + part.spans` that are hairpins, sorted once.
     - Split them at interior dynamic events with `Notation::HairpinSegments.split` (`hairpin_segments.rb:9-17`).
     - The innermost hairpin governs, with the voice's own over the part's.
     - The ramp runs from the level in force at the start (or the default) to the level placed at the end (or one level beyond, clamped to ppp..fff).
     - Interpolation is linear by score onset, so every pass plays the same ramp.
     - A level-less hairpin's target level stays in force afterwards (see Proposed story changes).
   - Grace notes take the main note's base velocity, but not its note dynamic.
   - **Specs:**
     - a parity spec of the sweep against `dynamic_at` at every onset of `HairpinFixtures` and `MarkingFixtures`, excluding the *fp* note;
     - *fp*; sfz plus accent; clamping;
     - a crescendo with and without an end level;
     - a part hairpin over two voices (`MuseScoreFixtures.piano_part_marks`);
     - a hairpin inside a repeat.
   - Files: `lib/head_music/midi/velocity_resolver.rb`, `spec/head_music/midi/velocity_resolver_spec.rb`, `spec/head_music/midi/writer_loudness_spec.rb`

5b. **Grace notes and articulation length.** Parallel with 5a, 5c, and 5d.
   - **Articulation length:** staccatissimo ¼, staccato ½, staccato with tenuto (portato) ¾, tenuto 1. Otherwise the shortest factor wins. Shortening applies to the last link of a tied chain.
   - **Grace notes** sound on the beat, taking time from the main note:
     - a lone acciaccatura sounds as 1/32;
     - a lone appoggiatura takes half the first link of its main note;
     - a group of two or more sounds 1/32 each;
     - the total is capped at half the main note and shared equally beyond the cap;
     - a grace chord gives one piece per pitch;
     - a `tied` last grace note on the main note's key sounds as one piece through the main note's release.
   - Specs use `TupletFixtures.grace_notes_before_downbeat`, `grace_notes_in_pickup`, and an acciaccatura on a flow's first note, and assert that nothing falls before tick 0.
   - Files: `lib/head_music/midi/note_timing.rb`, `spec/head_music/midi/note_timing_spec.rb`, `spec/head_music/midi/writer_grace_notes_spec.rb`

5c. **Instruments and percussion.** Parallel with 5a, 5b, and 5d.
   - **`ProgramChanges`:** at each played span, a part's channel gets the program of the instrument in force (`Part#instrument_at`, `part.rb:67-81`) whenever it differs from the last program written. A pitched part with no GM program writes 1 (Acoustic Grand Piano). Channel 10 never receives a program change.
   - **`SoundKeys`** (unpitched): channel 10, at `sound.instrument&.gm_percussion_key`, else `DEFAULT_PERCUSSION_KEY = 76` (Hi Wood Block). `UnpitchedSound.generic` has no instrument (`unpitched_sound.rb:27-29`). Unpitched sounds in a pitched part go to channel 10 in that part's track.
   - Specs:
     - a drum part; the generic sound; `drum_kit`;
     - two percussion parts on the same key at once;
     - the clarinet change with a D.C. restoring the first program;
     - a mixed pitched and unpitched part;
     - an instrument with no GM program writes 1.
   - Files: `lib/head_music/midi/program_changes.rb`, `lib/head_music/midi/sound_keys.rb`, `spec/head_music/midi/writer_instruments_spec.rb`

5d. **Lyrics.** Parallel with 5a, 5b, and 5c.
   - `FF 05` carries the syllable as UTF-8, with `-` appended when `hyphen_after` is set.
   - On pass *n*, a note sings verse *n* when the flow has verse *n* anywhere, and verse 1 otherwise (`PlayedBar#pass`).
   - When two voices of a part sing at one onset, the first voice in the part wins.
   - Specs: `MuseScoreFixtures.two_verses` over its repeat, with its bar-0 pickup; a Latin accented syllable and a Cyrillic one.
   - Files: `lib/head_music/midi/lyric_events.rb`, `spec/head_music/midi/writer_lyrics_spec.rb`

6. **Fixture parity, the MuseScore check, and release notes.**
   - **Fixture parity.** Render these fixtures:
     - ABC `SPEED_THE_PLOUGH` and `CHROMATIC_AIR` (`spec/support/abc_fixtures.rb`);
     - LilyPond `bach_invention_01` and `tuplets_and_grace_notes`;
     - all `spec/fixtures/notation/kern/*.krn`;
     - the MusicXML fixtures `marked_da_capo_al_fine`, `marked_dal_segno_al_coda`, `clarinet_changes`, and `two_verses`.

     Assert the decoded multiset of (key, onset tick) against a value derived independently from `midi_note_number` and the exact onsets unfolded by `performance_order`. For events with grace notes, compare keys only.
   - **MuseScore spec,** gated like `spec/head_music/notation/music_xml_real_files_spec.rb:121-123`:
     - Write the `.mid` to a tmpdir and call `MuseScore.convert_file` (`spec/support/musescore.rb:42-53`, which already judges the output file and well-formedness, not the exit status).
     - Parse the result with `Notation::MusicXML.parse`, and compare pitch sequences for fixtures without tuplets, since MuseScore quantizes.
     - Include one fixture rendered at the smallest division, 480.
   - **Hand check.** Run it once and record it in the story: render Speed the Plough to the scratchpad, run `"/Applications/MuseScore 4.app/Contents/MacOS/mscore" -o speed.musicxml speed.mid`, and confirm the output file exists. timidity and fluidsynth are not installed.
   - **CHANGELOG:** MIDI export, the GM catalog fields, and the step 0 fix.
   - Files: `spec/head_music/midi/fixtures_spec.rb`, `spec/head_music/midi/muse_score_spec.rb`, `CHANGELOG.md`, `user-stories/current/midi-export.md`

**Parallel worktrees.** Worktree agents branch from `main` (381e3323), which lacks this branch's `84f072e8`. Each agent must first reset to the named base.

- **Steps 1 and 2:**
  - **Base:** the step 0 commit on `story/midi-export`.
  - **Contract:** step 1 touches only `lib/head_music/instruments/` and its specs; step 2 touches only `lib/head_music/midi*`, `lib/head_music.rb`, and `spec/support/midi_reader.rb`. The one shared name is `Instrument#gm_program` / `#gm_percussion_key` returning a 1-based Integer or nil. Step 4 consumes it, not step 2.
- **Step 3** is sequential after steps 1 and 2 are integrated. **Step 4** follows step 3.
- **Steps 5a–5d:**
  - **Base:** the step 4 commit.
  - **Contract:** each agent replaces exactly one stub and adds its own `writer_*_spec.rb`. CHANGELOG lines go in commit bodies, and the coordinator writes the CHANGELOG at integration.
  - The contract, frozen in step 4: times are Rational whole notes, velocities are Integers 1..127, and channels are 0-based wire channels.

```ruby
HeadMusic::MIDI::NoteTiming::Piece = Data.define(:sounds, :from, :to, :velocity, :id) # relative to the exact onset
HeadMusic::MIDI::NoteTiming.new(voice_event, velocity_resolver).pieces      # => [Piece]
HeadMusic::MIDI::VelocityResolver.new(voice).velocity(voice_event)          # => Integer
HeadMusic::MIDI::VelocityResolver.new(voice).grace_velocity(voice_event, grace_note)
HeadMusic::MIDI::SoundKeys.new(part, channel:, transposed:).for(sound, bar_number) # => [channel, key]
HeadMusic::MIDI::ProgramChanges.new(part, timeline).changes                 # => [[time, program_1_based]]
HeadMusic::MIDI::LyricEvents.new(flow).text_for(voice_event, pass)          # => String or nil
```

### Testing Strategy

- **Golden bytes only for encoder primitives.** That means the VLQ boundaries, MThd, an empty MTrk, each meta event, and UTF-8 text length. Every musical spec decodes with the spec-support reader and asserts on events and ticks.
- **Shared invariant helper.** Every writer spec calls the step 4 helper (paired note on/off, no key on twice, non-negative deltas, end-of-track last).
- **Building flows.** Use `HeadMusic::Notation::ABC.parse` for flows. Reuse `TupletFixtures`, `NavigationFixtures`, `MarkingFixtures`, `HairpinFixtures`, and `MuseScoreFixtures`.
- **Edge cases that must have specs:**
  - septuplet exactness (onsets are multiples of division/7);
  - the 960 fallback with no drift over a long 7:4 run, and no zero-length notes;
  - a tie into a skipped first ending;
  - re-emitted tempo, meter, key, and program after a D.C.;
  - pickup with a repeat;
  - *fp*; a hairpin with no end level; a part hairpin over two voices;
  - same-key overlap within a part and across percussion parts;
  - an acciaccatura on the first note;
  - more than 15 distinct pitched channels;
  - an empty flow;
  - a pitch out of range under `transposed:`;
  - binary encoding with non-ASCII lyrics.
- **Velocity parity.** The sweep is pinned against `dynamic_at` by a parity spec. That spec is what licenses the faster path.
- **Determinism.** Same flow, same bytes, including after a `to_h` round trip. Use no Floats between the flow and the ticks or velocities.
- **MuseScore.** The automated check is gated and environment-dependent. The hand check is recorded in the story.
- **Conventions.** No stdout assertions, `described_class` throughout, and coverage stays at 90% or above under `bundle exec rake validate`.

### Risks & Open Questions

All open choices are settled by a recommendation; the trade-offs are noted here.

- **The specialists disagreed on the tick resolution.** The options were: the smallest exact LCM, as the story says; that LCM including the derived articulation and grace durations, as the developer and best-practices engineer proposed; or a 480 base with derived durations rounded, as the product manager proposed. **Recommendation:** use `lcm(480, every emitted time)`, derived times included. It stays exact wherever the bare LCM is, avoids divisions of 1 or 3 that tools handle poorly, and keeps staccatissimo exact. The cost is that the 960 fallback arrives a little sooner (a 480 base hits 32767 at about a 68× factor).
- **`RenderError` superclass.** The best-practices engineer and the developer chose `StandardError`; the product manager chose to subclass. **Recommendation:** subclass `Notation::RenderError`, matching the four existing writers so callers keep one rescue clause. It sits a little oddly against the "MIDI is not notation" Decision; record it as a Decision.
- **Same-key overlap.** The story says merge; the product manager says re-strike. **Recommendation:** re-strike, because merging loses an inner voice's repeated attack against a held note. This changes the story, so it is listed below.
- **Mixed pitched and unpitched part.** The best-practices engineer would raise; the developer and product manager would route the unpitched sounds to channel 10 in the part's track. **Recommendation:** route them, since that is cheap and expresses the model.
- **Key signature beyond ±7.** The product manager would raise; the developer would normalize. **Recommendation:** normalize by ±12. The sounding key is unchanged, and writers raise only when the model cannot be expressed.
- **Default percussion key.** 38 (snare, developer) or 76 (Hi Wood Block, product manager). **Recommendation:** 76. A neutral click does not pose as a drum-kit part.
- **Performance.** Without the sweep, `dynamic_at` is quadratic. If the parity spec turns up a precedence case the sweep cannot match cheaply, fall back to memoized `dynamic_at` per score voice event and accept O(n²). That is acceptable at corpus size, but a long fugue will be noticeably slow.
- **Fallback assumption.** A broken run of a rounding ratio (`voice_event.rb:205-210` returns remainder 0) starts at a rounded position. Its subtick denominator then pushes past the cap, and the 960 fallback is used. That is correct behavior, but less is exact than the septuplet example in the story suggests.
- **Timpani and crotales.** `notation_styles.yml` gives them a `neutral_clef`, so `Instrument#pitched?` is wrong for them. The MIDI plan works around it by choosing channels by sounds. Fixing the data would change `SoundResolver` for the bare name "timpani" (`sound_resolver.rb:42-50`), according to the developer. Defer it to its own small story, because it touches resolution behavior unrelated to MIDI.
- **Channel 10 overlaps.** A merged note on channel 10 stays in the first part's track. This is harmless but unusual.
- **Not verified by me:** the developer's GM program numbers per catalog key, and the `notation_styles.yml` line numbers. The step 1 catalog spec checks the ranges; check the numbers against a GM table while implementing.
