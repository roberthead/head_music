<!--
metadata:
  created_at:   2026-09-24T18:58:30-07:00
  activated_at: 2026-10-16T08:30:49-07:00
  planned_at:   2026-10-16T08:54:50-07:00
  finished_at:
  updated_at:   2026-10-16T11:04:54-07:00
-->

# Story: MIDI Import

## Summary

AS a developer using HeadMusic

I WANT to read a Standard MIDI File into a `HeadMusic::Content::Flow`

SO THAT I can analyze music that exists only as MIDI, such as files from online archives and sequenced arrangements

## Background

MIDI records performance, not notation. Importing it means inferring three things the file does not say:

- **Spelling.** Key number 61 could be C♯ or D♭. [Key and Spelling Inference](key-and-spelling-inference.md) does this, and lands before this story.
- **Rhythmic values.** Ticks must be quantized to note values. Notes that cross a barline must be split and tied, and durations that are not a single value must become tied chains. `BarSplitter` already splits notes at barlines for the writers.
- **Voices.** A track, or a channel within a track, may hold several simultaneous lines, which must be separated into voices or chords.

[MIDI Export](midi-export.md) lands earlier. It defines `HeadMusic::MIDI`, the General MIDI program and percussion-key data in the instrument catalog, and an SMF reader in `spec/support`, which this story promotes into the gem.

## Prerequisites

- [MIDI Export](midi-export.md), for the module, the GM data, and the SMF event reader
- [Key and Spelling Inference](key-and-spelling-inference.md), for key finding and spelling

## Example

```ruby
flow = HeadMusic::MIDI.parse(File.binread("invention.mid"))
flow.voices.first.voice_events.first.pitch.to_s # => "C4"
```

## Acceptance Criteria

### Entry point and file

- [ ] `HeadMusic::MIDI.parse(bytes, key: nil, grid: :auto)` returns a `HeadMusic::Content::Flow` from an SMF of format 0 or 1. Unknown options or values raise `ArgumentError`
- [ ] `MIDI::UnsupportedFeatureError` subclasses `MIDI::ParseError`. `HeadMusic::MIDI::Reader` moves from `spec/support` into the gem, and MIDI Export's specs use it
- [ ] A truncated or malformed file raises `MIDI::ParseError` naming the byte offset. Examples:
  - a missing `MThd`;
  - fewer tracks than declared;
  - a chunk that runs past the end;
  - a bad variable-length quantity;
  - a division of 0 or a format above 2;
  - a tempo of 0;
  - a meta event shorter than its type;
  - a key signature outside −7..7 fifths, or with a mode other than 0 or 1;
  - a time-signature numerator of 0.
- [ ] The reader accepts:
  - an `MThd` longer than 6 bytes;
  - more `MTrk` chunks than declared;
  - trailing bytes after the declared tracks;
  - a track that ends without an end-of-track event;
  - running status, including after a meta event.

  Unknown chunk types are skipped, as the SMF specification asks
- [ ] SysEx, controller, pitch-bend, aftertouch, and unrecognized meta events are skipped. Text is read as UTF-8 when valid and otherwise as Windows-1252, without raising
- [ ] These raise `MIDI::UnsupportedFeatureError`:
  - a format 2 file, which holds independent sequences rather than one piece;
  - a file with an SMPTE time division, which has no beat to quantize to;
  - a time-signature denominator above 64.
- [ ] Limits:
  - A file that would need more than 10,000 bars, 200,000 notes, 128 parts, or 1,000,000 voice-bars raises `ParseError` before any flow is built.
  - A part needing more than 64 voices raises `UnsupportedFeatureError`.
  - Call-counting specs pin parsing as linear.
- [ ] No error outside `MIDI::ParseError` escapes. A fuzz spec truncates and flips the bytes of a rendered file to check this

### Timeline

- [ ] Meta events are read from every track and merged by tick. At one tick, the last in merged order wins, and a restatement that changes nothing is ignored
- [ ] Time-signature meta events set the meter and lay out the bars, including changes. With none, the meter is 4/4. A change that does not fall on a barline raises `UnsupportedFeatureError`, since the model would need a short bar in the middle of the piece. The bars end at the latest release or event, or at a later end of track that lands on a barline, as export ends a last bar of rests. A time signature within one tick of a sixty-fourth or triplet-sixty-fourth point, counted from the one before, snaps to it; any other raises `UnsupportedFeatureError` naming its tick and saying it falls between grid points
- [ ] Tempo meta events become tempo changes, taking the tempo in force at each bar's downbeat, restated in the meter's beat with the fewest decimals that write back the same microseconds. With none, the tempo is 120 quarter notes per minute. Changes within a bar are skipped until [Timeline Expressions](timeline-expressions.md) can hold gradual ones
- [ ] Key-signature meta events set the key signature and tonal context, including changes. One within a bar takes effect at that downbeat when no note starts before it in the bar, and otherwise at the next downbeat
- [ ] When the file has no key signature, or the caller passes `key: :infer`, the key regions come from key finding. `key:` also takes a key, a key name, or key regions
- [ ] When the second time signature arrives before a full bar of the meter that follows it, the first bar is a pickup of that length. Leading silence in a full first bar stays as rests and is never a pickup
- [ ] MIDI Export writes a pickup's time signature with the smallest power-of-two denominator that holds it, and restates the meter at bar 1 when none does. A part with no instrument writes no program change

### Notes and rhythms

- [ ] Note on and note off pairs become note events, and a note on with velocity 0 counts as a note off. Notes pair per channel and key across every track, in merged order, first in, first out. A note belongs to the track holding its note on, and a note off that matches no sounding note is skipped
- [ ] A note still sounding at the end of its track ends there. The bars end after the latest onset as well as the latest release, so a note of no length or never released on the final barline, or snapped to it, gets a bar of its own
- [ ] Every note is spelled by the speller from the prerequisite, using the key in force, with notes labeled by voice so melodic direction applies
- [ ] By default the grid is the coarsest, among sixteenths, thirty-seconds, sixty-fourths and their triplet divisions, that places every onset within one tick. When none does, it is the coarsest grid that places at least 99% as many onsets as the best grid does. `grid:` takes one of these values or any Rational down to 1/256, a 256th note, the shortest rhythmic unit a flow can hold, and raises `ArgumentError` for one finer
- [ ] A release less than one grid step before the next onset in its part extends to that onset. Other releases snap to the nearest grid point, and no note is shorter than one step
- [ ] Notes and rests are written as single values where one fits, and as tied chains otherwise. A note that crosses a barline is split and tied. Triplet values are written as 3:2 tuplets, cut at beats where they cross one. Quintuplets and septuplets need an explicit `grid:`
- [ ] Time between notes in a voice becomes rests, and a voice that starts late or ends early is padded, so every voice satisfies `Voice::Continuity`

### Parts and voices

- [ ] In format 1, each track that holds notes becomes a part; a track that holds notes on several channels becomes one part per channel. Format 0 is split by channel. A track after the first with a name or program change but no notes becomes a part of rests
- [ ] A track name meta event becomes the part's player name, unless it equals the part's instrument name exactly, case included, so "Soprano" names the player of a part whose instrument is "soprano". The sequence name is the flow's name. In format 1, track 0's name is the flow's name only when track 0 holds no notes
- [ ] A program change sets the part's instrument through the GM program data. A later program change becomes an instrument change at the bar of its channel's next note on
  - A channel with no program change has no instrument, and a part with no program in force at its first note has none until a change. A part of rests takes its track's first program.
  - A program with no catalog instrument gives no instrument, and a later change to one keeps the instrument in force.
  - An ambiguous program resolves through the track or instrument name, and otherwise through a pinned table covering every such program.
- [ ] Channel 10 becomes an unpitched part, its key numbers mapped to unpitched sounds through the GM percussion data. Keys with no catalog instrument of their own map through aliases (36 → bass drum, 40 → snare, 44 and 46 → hi-hat, 57 → crash, 59 → ride), and otherwise to the generic unpitched sound. Percussion chords group by onset alone
- [ ] Notes in one part that start and end together, after quantizing, become one chord
- [ ] Notes that overlap without forming a chord go to separate voices, deterministically:
  - Chords are taken in onset order, top first.
  - A voice is free when its last release is at or before the onset.
  - A chord joins the free voice nearest by mean key number, with ties going to the lower voice.
  - A chord opens a new voice when no voice is free.

### Lyrics

- [ ] Lyric meta events are quantized like onsets and attach syllables to the note they fall on, and a trailing hyphen sets `hyphen_after`. Several lyrics at one onset become successive verses. A standalone `-` and lyrics on no onset are skipped

### Round trip and real files

- [ ] For fixtures that fit the export's grid, the first parse matches the written flow per part in onsets, rhythmic values, key numbers, meter, key signature, tempo, programs, and lyrics, and exporting it again gives the same events. Spelling is compared separately: the spec pins every note spelled differently from the written flow. Fixtures exclude what export cannot write back:
  - same-key overlaps on one channel;
  - unisons between parts that share a channel;
  - unpitched sounds in a pitched part;
  - modes;
  - GM stand-ins and percussion with no GM key;
  - verses beyond the number of passes;
  - repeats, dynamics, staccato, grace notes, and tuplets other than triplets.
- [ ] With `KERN_CORPUS` pointing at the Bach chorales, every chorale goes through kern import, MIDI export (with navigation removed), and MIDI import. It is parsed with the key from its signatures and with `key: :infer`. Both spelling rates are pinned as floors beside the 99.945% and 99.947% figures from Key and Spelling Inference
- [ ] When MuseScore is available, its MIDI exports of the MusicXML fixtures parse to the same pitches per part, with its known losses pinned
- [ ] A public-domain sequenced file from Mutopia parses end to end and is committed as a fixture, with its license noted in `spec/fixtures/midi/README.md`
- [ ] The Aarden tonic-heavy fixture from Key and Spelling Inference is parsed with no key signature, and its inferred key is pinned
- [ ] Maintains 90%+ test coverage

## Notes

- **Round trips leave out what export performs rather than notates:**
  - Repeats and jumps are played out, so they come back written out.
  - Staccato notes are shortened, so they come back as shorter notes and rests.
  - Grace notes take time from their neighbors, so they come back as short notes.
  - Dynamics become velocities.

  Round-trip specs use flows without these, or compare against `Flow#performance_order`.
- **Follow-up: dynamics from velocity.** Accents and hairpins move velocities off the export's level table, so a reader would invent level changes. A useful version needs its own rules for runs, thresholds, and ramps.
- **Follow-up: live performances.** Human-performed MIDI, unquantized, with rubato and no tempo map, needs beat tracking before quantizing. v1 is scoped to sequenced files.
- **From Key and Spelling Inference** (2026-10-15): voices are separated before spelling, so melodic direction applies; the spelling floor should cite that story's inferred-key chorale figure.
- **Shapes MIDI Export writes** (decided in that story, 2026-10-15): a first bar shorter than the meter that follows is a pickup, which export trims to its first onset, and a tempo should be restated in the meter's beat, since export writes microseconds per quarter.
- **MuseScore writes minor keys as major signatures**, and some files carry a default C major they do not mean. v1 trusts signatures, since inferring the mode would override MIDI Export's correct ones, which the round trip needs. Mode inference within a given signature is a follow-up once the MuseScore spec measures its cost.
- **Legacy encodings** (GBK, EUC-KR, Shift-JIS) decode as Windows-1252 replacement text. Detecting the encoding needs a heuristic that the few samples cannot tune.
- **Follow-ups found by the planning probes, each in another format's story:** MusicXML Export writes no tempo and pads an implicit pickup measure with a leading rest, and the ABC reader ignores an anacrusis.
- **Deferred, with reasons:**
  - **Inferring repeats.** SMF has no repeat events, and bars may be identical on purpose.
  - **`transposed:` on import.** Program 57 covers both the B♭ and C trumpet, so the written pitch would be a guess.
  - **Sustain pedal.** It lengthens sound, not notation.
  - **Karaoke `.kar` text.** It needs its own rules to tell lyrics from text.
  - **Markers as rehearsal marks.** Their text follows no convention.
  - **MuseScore's no-trailing-space hyphen convention.** Only one file shows it, and reading it needs a per-file detector.
- The voice separation above is a first fit. Contour- and range-aware separation, which would let the counterpoint guides grade imported polyphony, is a follow-up.
- **Spelling with `key: nil` and the modes** (measured 2026-10-16). The chorales spell at 99.939% with `key: nil`, 51 misses against the 46 Key and Spelling Inference measured on the kern flows with the key given. The five extra all come from modes. Seven of the 47 modal chorales spell differently through MIDI: chor025, chor113 (F Dorian), chor155, chor218, chor237 (G Dorian), and chor034, chor205 (E Phrygian). A MIDI key signature holds only major or minor, so export writes each mode as the major key of its signature, and import spells F Dorian as E♭ major. That loses 7 notes the mode spelled, such as F♯4 in G Dorian read as G♭4, and gains 2 the mode missed, such as chor113's F♭4. No signature is applied late and no reader step drops anything, so this is the format's limit, the "modes" exclusion below, not a reader bug.
- **Round trips** (step 8, 2026-10-16). `spec/head_music/midi/round_trip_spec.rb` round-trips nine fixtures. Each reads back its notes, bars and lyrics, writes the same events again, and spells every note as written:
  - ABC SPEED_THE_PLOUGH, with its repeat taken out, and ABC CHROMATIC_AIR;
  - LilyPond bach_invention_01;
  - kern satb_chorale, with its repeat taken out, and kern piano_splits, with its dynamics taken out;
  - `MuseScoreFixtures.two_verses`, sung once, since it has no repeat and export sings verse n only on pass n;
  - `clarinet_changes`, a drum kit, and an eighth pickup in 3/4.

  Excluded by name, each pinned as still differing:
  - tuplets_and_grace_notes.ly and tuplets.krn, for grace notes, quintuplets and septuplets;
  - articulations_ornaments_dynamics.krn, for staccato;
  - grace_notes.krn, for grace notes;
  - hairpins.krn, for hairpins;
  - the D.C. and D.S. MusicXML fixtures, for jumps, accents, staccato and hairpins.

  `generated_round_trip_spec.rb` passes 98 of `TupletGenerator`'s first 100 seeds, and 997 of 1,000 with `TUPLET_SEEDS=1..1000`. It uses one voice. Two piano hands drawn from one range come back otherwise in 94 of 100 seeds, because one hand strikes a key while the other holds it, which is the "same-key overlaps" exclusion. Its bars are compared without numbers, because a pickup a full bar long reads as bar 1. The three excluded seeds show one loss, kept rather than fixed:
  - Seeds 53, 82 and 266 hold a lone triplet note before triplet rests. Only its release is off the sixteenth grid its onsets fit, and the grid is chosen from onsets only (Settled choices).

  Seeds 87, 287 and 954, which end in a bar of rests, were excluded until review (fixed 2026-10-16). Export writes that bar only as the end of track's tick, and import ended the bars at the latest note. Import now ends them at an end of track that lands on a barline past the last note, and the bar budget counts to it.
- **An export bug the round trips found** (fixed 2026-10-16). `ConductorTrack#pickup_meter` counted a pickup in the larger of the meter's denominator and the pickup's, where it needed their least common multiple. A pickup of two-thirds of a whole note in 6/8 was therefore written as a truncated 5/8, and import raised for a meter change within bar 2. Seeds 5 and 34 found it.
- **The chorale corpus** (step 9, 2026-10-16, 38 seconds). All 366 readable chorales go through kern import, MIDI export with their repeats taken out, and MIDI import. Every chorale reads back its 83,196 notes and its bars under both keys, and re-exports the same events. None is refused.

  | Key | Spelled | Misses by rule |
  | --- | --- | --- |
  | `key: nil` | 99.939% (83,145) | direction 41, center 5, raised 4, sonority 1 |
  | `key: :infer` | 99.947% (83,152) | direction 34, center 5, raised 4, sonority 1 |

  The inferred figure equals Key and Spelling Inference's. With `key: :infer`, 315 chorales open on the signature they were written in.
- **MuseScore's MIDI** (step 9, 2026-10-16, MuseScore 4). Nine of the 14 MusicXML fixtures come back with the same spelled pitches per part, in the order they sound, once the tracks MuseScore writes per staff are taken together. Its losses are pinned:
  - two_verses' padded pickup reads as a full first bar;
  - Chromatic Air's A minor is written as a C major signature and reads as C major, at no cost in spelling;
  - clarinet_changes_transposed keeps the first clarinet's transposition through the instrument changes.

  Excluded by name:
  - the invention and the D.S. fixture, whose ornaments MuseScore plays as notes;
  - grace_notes_before_downbeat, whose grace notes it plays as notes;
  - the D.C. fixture, whose D.C. al Fine it does not play;
  - clarinet_changes_transposed, as pinned above.

  The cost of trusting MuseScore's major signatures for minor keys measured zero on Chromatic Air. That is one tune, too few to decide mode inference on.
- **Real files** (step 9, 2026-10-16):
  - Mutopia's Polonaise in F major, BWV Anh. 117a, which is Public Domain, reads as two parts of two voices each, in 3/4 and F major, on a sixteenth grid, with 235 notes in 16 bars.
  - music21's test01, which has no key signature, reads as one piano voice of 18 repeated C4s on a sixteenth grid, and infers F major.

## Decisions

- **The module is `HeadMusic::MIDI`** (decided 2026-10-14), shared with MIDI Export.
- **Key finding and spelling are a separate prerequisite story** (decided 2026-10-14), in `HeadMusic::Analysis`.
- **One part per track and channel, voices separated by first fit, chords for notes that start and end together** (decided 2026-10-14). This settles the earlier questions about voice separation and the default grid.
- **Valid content the model cannot hold is skipped, not raised** (decided 2026-09-26, as policy for every reader). Format 2, SMPTE time division, and a time-signature change within a bar raise, because each leaves no honest flow to build.

- **Planning choices adopted without stopping to ask** (2026-10-16, while running the seven-story goal; Rob may revise any). All of the planner's proposed story changes were adopted:
  - **Grid.** The grid is chosen from onsets only, within one tick, because MuseScore ends nearly every note a tick early. Releases extend to the next onset when within a step, or else snap.
  - **Pickup.** It comes from the meter events, not the first note, because exported chorales open with rests.
  - **Pairing.** Notes pair across tracks per channel, since export writes some releases in another track.
  - **Voices.** First-fit voices are taken top first, by mean key number. The voice cap is 64.
  - **Instruments.** A channel with no program gets no instrument, so MIDI Export stops writing program 1 for a part with no instrument. Export also writes a short pickup's time signature exactly.
  - **Keys.** Signatures are trusted by default.
  - **Tuplets.** Triplets come through the default grid; quintuplets and septuplets need an explicit `grid:`.
  - **Round trip.** The round trip is judged on the first parse plus a byte-level re-export.
  - **Shared helpers.** `EventMap#add` and `Bars#span` are made linear, since MIDI files can change tempo or key in every bar.

- **Decided during implementation, without stopping to ask** (2026-10-16; Rob may revise any):
  - **Export pickups.** A pickup's time signature never goes below the flow's own denominator. A half-note pickup in 3/4 writes 2/4, as before, so pickups that already exported correctly write the same bytes.
  - **Export programs.** A part that loses its instrument after having one writes program 1, so a D.C. back to a bar before the instrument arrived cannot replay a stale program. A part with no instrument from the start writes none.
  - **`grid:` bounds.** A grid finer than 1/256 of a whole note, a 256th note, raises `ArgumentError`, so the grid cannot make the bar layout unbounded and asks for no value finer than the model can write.
  - **Error translation.** It rescues model constructors' `ArgumentError` and the like only in the flow-building phase, so a bug in the reader or quantizer surfaces as itself rather than as a `ParseError`.

- **Decided before steps 8 and 9** (2026-10-16):
  - **Track names.** A track name sets no player only when it equals the instrument's name exactly, case included, so "Soprano" names the singer of a soprano part.
  - **Notes on the final barline.** The bars end after the latest onset as well as the latest release, so a note of no length or never released on the final barline gets a bar of its own.
  - **Spelling with `key: nil`.** The five misses beyond Key and Spelling Inference's were to be traced, and fixed if they came from a reader bug. They come from modes, which SMF cannot hold, as the Notes record.

## Implementation Plan

### Overview

`HeadMusic::MIDI.parse(bytes, key: nil, grid: :auto)` runs in two phases, following the two-phase pattern of `MusicXML::FlowBuilder`.

- **Phase one** produces exact records: a hardened decoder promoted from `spec/support/midi_reader.rb`, then a size budget, then a bar layout taken from the time signatures, then quantization to Rational whole notes, then first-fit voice separation, then spelling through `PitchSpeller` with labeled voices.
- **Phase two** builds the flow through the shared notation core: `BarMap`, a timeline applied to the flow, and `VoicePlacer` per voice.

Three things land first, because without them the round-trip criteria cannot pass or a real file would go quadratic: two export fixes and two linear-time fixes in shared `Flow` helpers.

Specialists: I consulted the product manager, the developer, and the best-practices engineer (for hostile SMF input and performance). A second developer measured 413 real files: 24 from music21, 369 written by export, and 18 written by MuseScore 4. I skipped the UI/UX and accessibility specialists because the story has no UI.

**Claims about current code, checked against the files:**

- **Export loses the barlines of a short pickup.** `ConductorTrack#pickup_meter` (`lib/head_music/midi/conductor_track.rb:39-44`) returns the flow's meter unless the pickup is a whole number of counts. The dedupe at `:21` then drops the restatement at bar 1. So an eighth pickup in 3/4 writes one 3/4 at tick 0, and every barline lands an eighth early. Both the product manager and the developer reproduced it.
- **A part with no instrument exports program 1.** `ProgramChanges#program_at` (`lib/head_music/midi/program_changes.rb:29-31`, `DEFAULT_PROGRAM = 1` at `:7`) writes 1, so the part would come back as a piano.
- **Export writes releases in another track.** `KeyOverlaps` (`lib/head_music/midi/key_overlaps.rb:33-34`) writes a release in the striking track, and merges simultaneous strikes on a shared channel (`:30-31`). Notes must therefore pair per channel across tracks, in merged order.
- **Two shared `Flow` helpers are quadratic.**
  - `EventMap#add` scans linearly (`lib/head_music/time/event_map.rb:72`).
  - `Bars#span` walks every bar from the first on each call (`lib/head_music/content/flow/bars.rb:12-16`), and `flow.rb:102` calls it.
  - The engineer measured one tempo or key change per bar: 2,500 bars took 0.51 s and 10,000 took 8.17 s.
- **The decoder lets the wrong exceptions and values through.**
  - It raises `TypeError` on a short time signature.
  - A short tempo gives nil microseconds, and a short key signature gives nil fifths.
  - It accepts an SMPTE division, format 2, division 0, a tempo of 0, and a denominator of 2^200.
  - It tags text as UTF-8 without checking (`spec/support/midi_reader.rb:203`).
  - It names the sequence only for format 1 (`:202`).
  - It peeks at a status byte without checking the track's limit (`:160`).
- **Unlabeled notes lose the direction rule.** `PitchSpeller#voices` (`lib/head_music/analysis/pitch_speller.rb:157-162`) keeps only labeled notes once any note is labeled, so every `UnspelledNote` must carry a voice label.
- **VoicePlacer pads every voice across the flow** unless `trim_edges:` is set (`lib/head_music/notation/voice_placer.rb:31`). MEI sets it (`mei/flow_builder.rb:64`).
- **`DottedDuration` caps a single value at 8 whole notes.** `rhythmic_value_for` returns nil above `MAX_FRACTION = 8` (`lib/head_music/notation/dotted_duration.rb:14,68`).
- **The model already holds what import needs.** `Part#change_instrument` (`part.rb:75`), `Flow#change_tempo` and `#change_key_signature` (`flow.rb:108,120`), and `Syllable#hyphen_after` exist, so no data model changes are needed.

### Steps

Each step is one commit with its specs, and keeps `bundle exec rake validate` green. Steps 1–3 run in parallel worktrees from **74d590a3**. Each worktree agent writes its CHANGELOG lines in its commit body, and the coordinator merges them (the format fan-out practice). The worktrees in step 5 branch from step 4's commit; record its SHA in the agent prompts, because worktree agents otherwise branch from `main`.

1. **Two export fixes that import depends on** (worktree A, from 74d590a3)
   - **Pickup meter.** `pickup_meter` uses the smallest power-of-two denominator, up to 64, that makes the pickup a whole number of counts, so an eighth pickup in 3/4 writes `1/8` and then `3/4`.
     - Where none exists (a triplet pickup), write the flow's meter at tick 0 and force a restatement at bar 1, bypassing the dedupe at `:21`.
   - **Programs.** `ProgramChanges#program_at` writes no program when `part.instrument_at(bar)` is nil, and keeps 1 for an instrument that has no GM program.
     - GM players default to program 1, so playback does not change.
     - This revises one clause of export's "every pitched part writes a program" decision. The stale-program risk that decision guarded against cannot arise here, because only parts with no instrument go unwritten.
   - Specs, in `spec/head_music/midi/conductor_track_spec.rb`:
     - an eighth pickup in 3/4;
     - a dotted-quarter pickup in 6/8;
     - a triplet pickup, which restates;
     - a 1/64 pickup.
   - Specs, in `writer_instruments_spec.rb`: no program for a part with no instrument. Update any spec that expected program 1.
   - CHANGELOG under Changed. Bytes change but the API does not, so this is not **Breaking.**
   - Files: `lib/head_music/midi/conductor_track.rb`, `lib/head_music/midi/program_changes.rb`, `spec/head_music/midi/conductor_track_spec.rb`, `spec/head_music/midi/writer_instruments_spec.rb`

2. **Make `EventMap#add` and `Bars#span` linear** (worktree B, from 74d590a3)
   - `EventMap#add` and `#remove` find the position with `bsearch_index` on the tuple, with a fast path for appending past the last event.
   - `Bars` remembers the range it has already allocated, so `span` fills in only what is missing.
   - Call-counting specs:
     - adding N and then 2N changes per bar costs at most 2.2× the `Event#at?` calls;
     - `Bar.new` is called once per bar.
   - CHANGELOG under Fixed, for performance.
   - Files: `lib/head_music/time/event_map.rb`, `lib/head_music/content/flow/bars.rb`, `spec/head_music/time/event_map_spec.rb`, `spec/head_music/content/flow/bars_spec.rb`

3. **Promote and harden the decoder** (worktree C, from 74d590a3)
   - **Move the decoder.** `spec/support/midi_reader.rb:1-236` moves to `lib/head_music/midi/reader.rb`, keeping the name `HeadMusic::MIDI::Reader`. `MIDIInvariants` and its `RSpec.configure` stay behind in `spec/support/midi_invariants.rb`.
   - **Errors.** Add `class UnsupportedFeatureError < ParseError; end` in `lib/head_music/midi.rb`, as `kern.rb:29` and `mei.rb:58` do.
   - **Value objects.** `Track` becomes a `Data.define` with frozen events and a `terminated` flag. `Note` gains `track` as a sixth member.
   - **What the decoder tolerates:**
     - `MThd` longer than 6 bytes;
     - more `MTrk` chunks than declared, all of them read (music21's test04 declares 18 tracks and holds 19);
     - a truncated chunk or stray bytes after the declared tracks, ignored;
     - a missing end-of-track, which ends the track at the end of its chunk with `terminated: false`, so `MIDIInvariants` still catches it in export's own output;
     - running status kept across meta events (cleared after SysEx).
   - **What raises `ParseError` with an offset:**
     - fewer tracks than declared;
     - division 0;
     - format 3 or higher;
     - meta data shorter than its type needs (tempo 3 bytes, time signature 4, key signature 2), reading only the needed prefix when it is longer;
     - tempo 0;
     - key signature `sf` outside −7..7, or `mi` other than 0 or 1;
     - time signature numerator 0;
     - a status peek at or past the track's limit;
     - input that is not a String, which raises `ArgumentError` instead.
   - **What raises `UnsupportedFeatureError`:**
     - format 2;
     - SMPTE division;
     - a denominator exponent above 6, which `Meter` cannot hold.
   - **Text.** UTF-8 when valid, otherwise Windows-1252 with `invalid:`/`undef: :replace`. NULs are stripped.
   - **Sequence name.** In format 0, the track name is the sequence name. In format 1, track 0's name is the sequence name only when track 0 holds no notes; MuseScore puts notes in track 0 in all 18 of its files.
   - **Pairing** is FIFO per `[channel, key]` over `merged_events`, so it works across tracks. A note belongs to the track holding its note on. An unmatched note off is skipped. A note never released ends at its own track's last tick.
   - **Decode limits**, as constants on `Reader` and checked while reading:
     - `MAX_BYTES` 16 MiB;
     - `MAX_EVENTS` 1,000,000;
     - accumulated tick above `division × 4 × MAX_WHOLE_NOTES` (10,000) raises `ParseError` at that event.
   - **Specs:**
     - `spec/head_music/midi/reader_spec.rb`: one example per case above, each asserting the offset.
     - `reader_fuzz_spec.rb`: render a multi-track fixture, then for every prefix length and every byte XORed with 0x01, 0x80 and 0xFF, `Reader#read` returns a `Sequence` or raises `MIDI::ParseError`.
     - Existing `smf_spec.rb`, `muse_score_spec.rb` and export specs pass unchanged.
   - CHANGELOG under Added: `HeadMusic::MIDI::Reader`.
   - Files: `lib/head_music/midi.rb`, `lib/head_music/midi/reader.rb`, `spec/support/midi_reader.rb` (deleted), `spec/support/midi_invariants.rb`, `spec/head_music/midi/reader_spec.rb`, `spec/head_music/midi/reader_fuzz_spec.rb`

4. **Freeze the contract: record types, stubs, budget, and the parse skeleton** (sequential, on the integration of 1–3)
   - Commit the records and signatures below, with minimal working stubs, so step 5's worktrees fill them in without touching shared files.
   - `MIDI.parse(bytes, key: nil, grid: :auto)` validates its options, raising `ArgumentError` for unknown values, and has one translation boundary.
     - It rescues `ArgumentError`, `ZeroDivisionError`, `FloatDomainError`, `RangeError` and `EncodingError` from model constructors, and re-raises them as `ParseError` with `cause` kept. The precedent is `midi/preflight.rb:27-33`.
     - It never rescues `StandardError`, `NoMethodError` or `TypeError`, since those are bugs the fuzz spec should find.
   - `Budget` checks the limits arithmetically, before any layout allocates:
     - `MAX_NOTES` 200,000;
     - `MAX_BARS` 10,000;
     - `MAX_PARTS` 128;
     - `MAX_VOICES_PER_PART` 64, which raises `UnsupportedFeatureError` naming the part;
     - `MAX_VOICE_BARS` (voices × bars) 1,000,000.
   - Contract:

     ```ruby
     # Ticks in, exact Rational whole notes out; time 0 is the file's tick 0.
     HeadMusic::MIDI::PartKey = Data.define(:track, :channel)
     HeadMusic::MIDI::BarLayout.new(time_signatures, division:)       # Reader TimeSignature events
       # #bars, #bar_at(time), #first_number (0 or 1), #bar_starts => {Integer => Rational}, #time(tick)
     HeadMusic::MIDI::BarLayout::Bar = Data.define(:number, :start, :length, :meter)
     HeadMusic::MIDI::Quantizer.new(layout, notes, division:, grid: :auto)  # notes: [Reader::Note]
       # #grid => Rational; #notes => [QuantizedNote]; #snap(tick) => Rational, for meta events
     HeadMusic::MIDI::QuantizedNote = Data.define(:part_key, :key, :onset, :release)
     HeadMusic::MIDI::VoiceSeparator.new(quantized_notes_of_one_part, percussion: false).voices
       # => [[Chord, ...], ...] in voice order
     HeadMusic::MIDI::VoiceSeparator::Chord = Data.define(:onset, :release, :keys)   # keys sorted, unique
     HeadMusic::MIDI::NoteValues.new(layout)
       # #value(onset, release) => RhythmicValue (a tied chain); #rests(from, to) => [[time, RhythmicValue]]
     HeadMusic::MIDI::InstrumentMap.instrument(program, hint: nil)   # => Instrument or nil
     HeadMusic::MIDI::InstrumentMap.sound(key, hint: nil)            # => UnpitchedSound, generic when none
     HeadMusic::MIDI::LyricAttacher.new(lyrics, events_by_part).attach  # lyrics: [[part_key, time, text]]
     ```

   - Specs: one per option error, one per budget limit (from generated bytes), and the translation boundary.
   - Files: `lib/head_music/midi.rb`, `lib/head_music/midi/{budget,bar_layout,quantizer,voice_separator,note_values,instrument_map,lyric_attacher}.rb`, `spec/head_music/midi/budget_spec.rb`, `spec/head_music/midi/parse_options_spec.rb`

5. **Pure stages, filled in parallel** (worktrees 5a–5e, from step 4's commit). Each owns only its own file and spec.
   - **5a. `BarLayout` and `Quantizer`.**
     - Meter, pickup, mid-bar refusal, and the grid and release rules, as given under Settled choices.
     - Specs:
       - a 1-tick-late onset;
       - a release 1 tick early, and one 97 ticks early (MuseScore's whole note);
       - K525's gate-time shape at division 256;
       - a zero-length note;
       - triplets at division 1024;
       - fallback ranking;
       - a pickup through restatement;
       - a lone 1/4 piece, which is not a pickup;
       - leading silence, which is not a pickup;
       - a mid-piece 1/4 bar, as repeats write it;
       - a mid-bar change, which raises.
     - Files: `bar_layout.rb`, `quantizer.rb`, and their specs.
   - **5b. `VoiceSeparator`.**
     - Chords and first fit, as given under Settled choices.
     - Specs:
       - a chord against overlapping lines;
       - a voice that opens late;
       - ties broken to the lower index;
       - percussion grouped by onset;
       - the voice cap.
     - Files: `voice_separator.rb` and its spec.
   - **5c. `NoteValues`.**
     - Notes cut at barlines and chained.
     - Values that are not binary are cut at beats.
     - Rests within a bar are written by `NoteValues`, cut at beats. VoicePlacer's own fill wrote a 1/3 gap as a "triplet half", so it fills only whole empty bars.
     - Chains are built right to left with one `append_tied` per link (`tie_folding.rb:63-69`), and no piece is longer than a bar or 8 whole notes.
     - Specs:
       - a triplet tied into a binary value;
       - a 1/3 gap written as a triplet eighth plus a quarter;
       - a note held across 2,000 bars, with a call-counting spec on `append_tied`.
     - Files: `note_values.rb` and its spec.
   - **5d. `InstrumentMap`.**
     - Reverse maps from `gm_program` and `gm_percussion_key`.
     - A pinned table for each ambiguous program: 10, 16, 25, 43, 53, 57, 58, 59, 61, 65, 68, 69, 71, 72, 74, 75.
     - Hint resolution through `Instrument.get`.
     - Percussion aliases: 36 → bass_drum, 40 → snare_drum, 44 and 46 → hi_hat, 57 → crash_cymbal, 59 → ride_cymbal, and ties broken as 49 → crash_cymbal, 76 → woodblock.
     - Spec: all 128 programs and keys 35–81 pinned. An ambiguous program with no table entry fails the spec.
     - Files: `instrument_map.rb`, `spec/head_music/midi/instrument_map_spec.rb`
   - **5e. `LyricAttacher`.**
     - The lyric rules given under Settled choices.
     - Files: `lyric_attacher.rb` and its spec.

6. **FlowBuilder: `MIDI.parse` end to end** (sequential, after integrating 5a–5e)
   - **`PartSource`.** Groups notes, programs, names and lyrics by `PartKey`.
     - Parts are ordered by track, then channel.
     - Format 0 is split by channel.
     - A format 1 track after the first that has a name or program but no notes becomes an all-rest part, since export writes empty parts.
   - **`TimelineReader`.**
     - Applies meter, tempo, key and instrument changes at downbeats.
     - Merges the sorted change events against the bar starts in one sweep, never filtering per bar.
     - Emits a change only when the value differs from the bar before.
   - **`Spelling`.**
     - Builds `NoteInput.new(unspelled, layout.bar_starts)` (`note_input.rb:103`), with `voice: [part_index, voice_index]` on every note and pickup onsets negative.
     - Runs `PitchSpeller` once over the whole flow.
     - Extracts the key-signature dedupe in `Respelling#write_key_signatures` (`respelling.rb:51-61`) into a public class method, which both callers use, to keep flay clean.
     - Converts signatures with `MusicXML::KeyMapper.tonal_context` (`key_mapper.rb:68-75`).
   - **`PartReading`.** Gives the measures (tolerance 0, one conductor reading for all parts), tracks, `errors` → `HeadMusic::MIDI` and `where` → `{}`.
   - **`FlowBuilder`.** `BarMap`, then `VoicePlacer` per voice. Voice 1 of each part uses `trim_edges: false`, and later voices `trim_edges: true`.
   - Specs, in `spec/head_music/midi/parse_spec.rb` and siblings:
     - format 0 and 1; parts per track and channel; flow and player names;
     - meter, tempo and key changes; a tempo within a bar, which is skipped; 6/8 tempo restatement;
     - a key signature within a bar; `key: :infer`; `grid:`;
     - `Voice::Continuity` on every voice; pairing across tracks; an unreleased note; FIFO re-strike;
     - 16 parts on 16 channels; a program change within a bar;
     - percussion on channel 10, including the 36 alias and the generic fallback;
     - a file with no time signature or tempo, which reads as 4/4 at 120;
     - lyrics with hyphens and two verses;
     - "contains no music" for a file with no notes (raises `ParseError`);
     - the Aarden tonic-heavy fixture, rendered with no key signature, with the inferred key pinned.
   - Files: `lib/head_music/midi/{part_source,timeline_reader,spelling,part_reading,flow_builder}.rb`, `lib/head_music/midi.rb`, `lib/head_music/analysis/respelling.rb` (or wherever `Respelling` lives), `spec/head_music/midi/parse_spec.rb`, `parse_instruments_spec.rb`, `parse_lyrics_spec.rb`, `parse_percussion_spec.rb`

7. **Scaling specs**
   - These count calls and never time. Model them on `spec/head_music/notation/mei/flow_builder_size_spec.rb:78-98`.
   - Count:
     - `Position#initialize`, `Flow#meter_at`, `EventMap#add`, `Bars#span`;
     - `Voice#place`, `RhythmicValue#append_tied`;
     - VoiceSeparator distance evaluations;
     - a `TracePoint(:call)` total.
   - Allow at most 2.2× for 2× the input. Assert `voice.revision` stays zero.
   - Shapes, all generated as SMF bytes:
     - (a) N bars of four voices;
     - (b) one note held for N bars;
     - (c) N tempo changes and N key changes;
     - (d) N time-signature changes at barlines;
     - (e) unreleased notes at the voice cap;
     - (f) 12-note chords at every onset.
   - Files: `spec/head_music/midi/parse_scaling_spec.rb`

8. **Round trips against MIDI Export**
   - `round_trip_spec.rb`.
     - Sources:
       - export's fixture list without repeats or grace notes;
       - `satb_chorale.krn` and `piano_splits.krn`;
       - `MuseScoreFixtures.two_verses` without its repeat;
       - a percussion flow and `clarinet_changes`;
       - an eighth pickup in 3/4, which exercises step 1.
     - The comparison is given under Settled choices.
   - `generated_round_trip_spec.rb`: `TupletGenerator.flow(seed, ratios: %w[3:2 6:4], graces: false, pickup: true)`.
   - Spelling is pinned separately, as an exact list of differing notes per fixture.
   - Files: `spec/head_music/midi/round_trip_spec.rb`, `spec/head_music/midi/generated_round_trip_spec.rb`

9. **Corpus, MuseScore, and the archive fixture**
   - `kern_corpus_import_spec.rb`, gated on `KERN_CORPUS`:
     - For each of `KernCorpus.readable_paths`, strip navigation from `to_h["bars"]` before export. chor001 otherwise writes its replayed pickup as a 1/4 bar mid-file.
     - Render MIDI and parse it twice, with `key: nil` and with `key: :infer`.
     - Match notes by part, onset and key number through `NoteInput.for` on both flows.
     - Assert that all 83,196 notes match, which is a structural check, and that re-export gives the same events.
     - Pin the spelling rates as floors and the misses by rule as ceilings, beside Key and Spelling Inference's 99.945% (key given) and 99.947% (inferred, 83,152 of 83,196).
     - Record key agreement as well.
     - Keep a refusal manifest; none is expected.
   - `muse_score_import_spec.rb`, gated like `music_xml_real_files_spec.rb:121-123`:
     - MuseScore converts the MusicXML fixtures to `.mid`.
     - Compare pitch sequences per part with `MusicXML.parse` of the same file.
     - Pin the known losses: minor written as major, and the padded pickup.
   - `archive_files_spec.rb`:
     - A public-domain Mutopia MIDI file, with a license note in `spec/fixtures/midi/README.md`, parses end to end. Pin its part count, meter, grid and voice counts.
     - Also include music21 `test01.mid` under the MEI fixture precedent (`spec/fixtures/notation/mei/real/README.md`).
     - Fetch from Mutopia, which is reachable. No local file is clearly licensed: music21's `license.txt` excludes corpus files, and `cs1-1pre.mid` states no rights.
   - Files: those specs, plus `spec/fixtures/midi/`

10. **Adversarial review, CHANGELOG, and the story**
    - Run a hostile-input review, as the MusicXML and MEI Learnings recommend; corpora hold no hostile structure.
    - Write the CHANGELOG under Added, Changed and Fixed.
    - Reword the criteria per "Proposed story changes" and check the boxes.
    - Files: `CHANGELOG.md`, `user-stories/current/midi-import.md`

**Settled choices** (recommendations, with reasons):

- **Grid.**
  - The candidates are the story's six, tried coarsest first: 1/16, 1/24, 1/32, 1/48, 1/64, 1/96 of a whole note. 1/16 comes first on a tie, so a piece whose onsets all fall on quarters reads as sixteenths, not triplets.
  - `:auto` chooses from **onsets only**. An onset fits when it lies within 1 tick of a grid point measured from its bar's downbeat.
    - Releases are left out because the strict rule fits 0 of the 18 MuseScore files, which end nearly every note 1 tick early.
    - The 1-tick allowance is needed because triplets at division 1024 sit 0.33 tick off 1/48.
    - A wider allowance (division/48) wrongly pushes three music21 files to 1/64.
  - When no grid fits, the fallback is the grid that places the most onsets within 1 tick, with ties going to the coarser grid. Sixteenths placed 58.5% of test07's onsets, where 1/48 placed 98.1%.
  - Snapping uses integer arithmetic, rounding half up, and converts to `Rational` once.
- **Releases.**
  - If the unsnapped gap from a release to the next onset in the same part is less than one grid step, the release moves to that onset (legato).
  - Otherwise it snaps to the nearest grid point, and is never shorter than one step.
  - This covers MuseScore's 1-tick and 97-tick early releases and K525's gate times of 0.6 to 0.75. With plain nearest-snapping, K525 would show a false rest after 2,872 of its 6,391 notes.
  - Export's own releases are exact (0-tick gaps), so the round trip is unaffected.
- **Pickup.** Bar 0 is a pickup only when the second time signature arrives before a full bar of the meter that follows it. That happens either when the first meter is shorter (export's `1/4` then `4/4`) or when a restatement falls inside the first bar (step 1's triplet case). Leading silence is never a pickup, because export writes six chorales that open with rests in a full bar, and they look identical.
- **Meter.**
  - The meter is 4/4 when the file has none.
  - A change on a barline applies at that bar, and a restatement of the same meter is ignored.
  - A change anywhere else raises `UnsupportedFeatureError`, naming the bar. No case appeared in 413 files.
  - Mid-piece short bars from played-out repeats read as meter changes.
- **Tempo.**
  - The tempo in force at each downbeat applies, and changes within a bar are skipped. test04 has 94 of 96 changes within a bar, and Timeline Expressions owns ramps.
  - Each tempo is restated in `meter.beat_value`, with the fewest decimals (0–3) that re-encode to the same microseconds. 666,667 µs in 6/8 reads as a dotted quarter at 60.
  - At one tick, the last event in merged order wins.
  - Compound meter comes from the numerator, never `clocks_per_click`, which writers set to 36, 24 or 12 for 6/8.
- **Key.**
  - With `key: nil`, the file's signatures are used as given, converted at downbeats.
    - A signature within a bar applies at that downbeat when no note starts earlier in the bar, and otherwise at the next one.
    - Export writes its signatures on purpose, and the round trip depends on them.
  - With no signature, or `key: :infer`, `PitchSpeller.new(input, key: :infer)` runs and the flow's signatures come from its regions.
  - `key:` also takes a `Key`, a key name, or `[KeyRegion]`, matching `PitchSpeller#initialize`.
- **Voices.**
  - Within a part, notes with equal quantized onset and release form one chord, with duplicate keys merged.
  - Chords are sorted by `[onset, -highest key]`. A voice is free when its last release is at or before the onset.
  - A chord joins the free voice with the smallest `|mean key − chord mean key|`, with ties going to the lower index. If no voice is free, it opens a new one.
  - Taking the top note first makes voice 1 the top line.
- **Tuplets.**
  - Triplet values are written through `DottedDuration.rhythmic_value_for(piece, tuplet: DottedDuration.tuplet_ratio(piece))` (`dotted_duration.rb:37-59`), with no `TupletGroup`. Writers bracket ungrouped runs (`tuplet_brackets.rb:57-62`).
  - Values that are not binary are cut at beats.
  - Quintuplets and septuplets come back only with an explicit `grid:`, such as `Rational(1, 28)`.
- **Ties.** One voice event per sounding note, its chain cut at barlines (and at beats when not binary), and `BarSplitter` re-splits it when writing. `TieFolding` is not used, because MIDI has no tie syntax.
- **Percussion.**
  - Channel 10 (wire channel 9) is always a part of its own, as the story's decision says.
  - Key to sound goes through `InstrumentMap.sound`. The part's instrument is the hint when that is unpitched, otherwise the one instrument all its sounds share, otherwise drum_kit.
  - Chords group by onset alone, and releases take the chord's longest, since drum releases are arbitrary.
  - Program changes on channel 10 are ignored.
- **Instruments.**
  - The program in force on the channel at the part's first note sets the instrument.
  - A later change takes effect at the bar of the channel's next note on.
  - The hint (instrument-name meta, then track name) wins when `Instrument.get(hint)&.gm_program == program`. Otherwise the pinned table, or the sole instrument for that program, or nil.
  - A channel with no program has no instrument; GM's piano default would claim an instrument the file never named. This is why step 1 stops export writing 1 for such parts.
  - A track name equal to the resolved instrument's name, case included, sets no player, because export writes the instrument name when a part has no player. A name differing only in case is a player's, such as "Soprano" for the singer of a soprano part (decided 2026-10-16).
- **Lyrics.**
  - A lyric is snapped like an onset and attaches to the first voice in its part with a note starting there.
  - A trailing `-` is stripped and sets `hyphen_after`. Whitespace, Unicode whitespace such as non-breaking spaces included, is stripped.
  - Empty text, a standalone `-` (music21's melisma marker) and lyrics on no onset are skipped.
  - Several lyrics at one onset become verses 1, 2 and so on, in order, which is MuseScore's shape.
  - A lyric in a track with no notes goes to the first part with an onset there.
- **Round-trip judgement.** Two checks:
  1. The first parse, `import(export(F))`, compared with F per part:
     - multisets of (onset, total `rhythmic_value.fraction`, sorted keys);
     - meter, key-signature fifths and mode, tempo in microseconds, and GM program at every bar;
     - lyrics as (onset, text, hyphen, verse).
  2. `export(import(export(F)))` decodes to the same events as `export(F)`. This catches drift a field list would miss.

  Fixtures must fit the grid at export's division (480 for binary values and triplets). Voice assignment within a part is not compared: export writes both hands of the invention to one channel, and 92 of its 120 onset clusters end unevenly.

### Testing Strategy

- **Unit specs** for every stage, as listed in each step, using `described_class` and no stdout assertions.
- **Fuzz spec on the decoder** (step 3): every truncation and three XOR masks on every byte of a rendered fixture. This is exhaustive on that fixture, which is stronger than the hand-written hostile documents the XML readers used.
- **Error boundary** (step 4): only `MIDI::ParseError` and its subclass escape `parse`. `SystemStackError` and memory exhaustion are prevented by the budget, not rescued.
- **Call-counting scaling specs** (steps 2, 5c and 7). The export Learnings found that "linear" needs a counting spec.
- **Round trips** (step 8) compare the first parse, following the kern Learnings.
- **Corpus sweep** (step 9): floors and ceilings rather than exact pins, plus a refusal manifest.
- **Second writer**, gated on MuseScore: MuseScore MIDI compared with MusicXML parses of the same file.
- **Coverage** of 90% or more, checked with `bundle exec rake validate` per commit.

### Risks & Open Questions

- **Trusting signatures by default misreads two real cases.** MuseScore writes every minor key as major (0 minor signatures in 18 files, though the MusicXML said minor), and K525 carries C major although it is in G. Recommendation: keep `key: nil` trusting signatures for v1. Have the gated MuseScore spec measure the spelling cost of the lost minor mode, and decide on mode inference within a given signature from that number.
- **Aarden's bias toward the tonic-heavy subdominant** applies whenever a file has no signature. Step 6 pins the fixture from Key and Spelling Inference, so a change of profile shows as a spec diff. `profile:` passes through with `:infer`.
- **Legacy encodings come out as replacement text.** GBK, EUC-KR and Shift-JIS text (music21 test04, test19, test21) decodes as Windows-1252, so non-Latin lyrics and names will not read correctly. Detecting the encoding was not attempted, because it needs a heuristic that one sample cannot tune.
- **First-fit voices are weak counterpoint input** where lines cross. The story already lists contour-aware separation as a follow-up.
- **Some exports cannot be recovered.** A part's unpitched sounds come back as a second part. Unisons between parts that share a channel come back as one note. Modes come back as major. Generic sounds come back as woodblock. Two instruments on one program, such as clarinet in B♭ and in A (both 72), cannot be told apart. All are excluded from round-trip fixtures and listed in the story's Notes.
- **Changing export bytes (step 1)** alters output for existing callers, for pickups and for parts with no instrument. It is recorded under Changed, not **Breaking.**, because the API is unchanged.
- **Cross-format coupling.** MIDI calls `MusicXML::KeyMapper.tonal_context`. That is acceptable as a public class method, and moving it to `Rudiment::KeySignature` is a later cleanup.
- **Specialist disagreements, resolved:**
  - **Pairing per track or across tracks.** The engineer suggested per track. `key_overlaps.rb:33-34` writes releases in another track, so pairing is across tracks per channel.
  - **Track-count mismatch.** The engineer suggested reading only the declared count. I chose to read every complete chunk, because dropping a real track (test04) would lose music silently.
  - **Voice cap.** 32, 64 and 128 were proposed. I chose 64, raising `UnsupportedFeatureError`, since dropping notes would corrupt the music.
  - **Percussion durations.** "Until the next onset, or one beat" was proposed. I chose the pitched release rule with chords grouped by onset, so exported percussion keeps its durations.
  - **Unpitched notes in a pitched track.** The product manager suggested they join that track's part. I kept the story's separate part, because pitch-distance voice separation means nothing for drum keys, and format 0 needs the channel split anyway.
- **Writer gaps found by the probes, outside this story:**
  - head_music's MusicXML writer emits no tempo.
  - It pads an implicit pickup measure with a leading rest, so MuseScore writes a full first bar.

  Both belong to MusicXML Export. The gated MuseScore spec here pins them and does not work around them in the reader.
- **The ABC reader ignores an anacrusis.** `G | c2 d2 e2 f2 |` puts C5 at 1:1:480. Pickup fixtures must therefore come from kern, MusicXML or the API, despite the memory note that prefers ABC. It is worth a separate fix.

Probe scripts and outputs are in `/private/tmp/claude-501/-Users-roberthead-github-com-roberthead-head-music/32cd5f96-66f9-4ba4-aa1b-0a3786f3fdb9/scratchpad/midiimp-plan/` (`probes/`, `bpe/`, `developer/`).
