<!--
metadata:
  created_at:   2026-09-25T14:05:53-07:00
  activated_at: 2026-10-20T16:02:22-07:00
  planned_at:   2026-10-20T16:24:28-07:00
  finished_at:
  updated_at:   2026-10-20T16:24:28-07:00
-->

# Story: Timeline Expressions: Tempo Words, Gradual Tempo Changes, Fermatas, and Meter Symbols

## Summary

AS a developer using HeadMusic

I WANT a flow's timeline to keep tempo words, gradual tempo changes, fermatas, and common- and cut-time symbols

SO THAT an imported score keeps "Allegro", "rit.", its fermatas, and 𝄴 instead of flattening them to a number and `4/4`, and the `Conductor` keeps time through them

## Background

The timeline holds meter, key, and tempo, and it changes them only at downbeats. Four things the formats say about the timeline are lost:

- **Tempo words.** `Tempo.get("allegro")` answers a quarter note at 120 and forgets the word. ABC writes `Q:"Allegro" 1/4=120`, LilyPond `\tempo "Allegro" 4 = 120`, MusicXML `<words>` beside `<metronome>`, and kern `!!!OMD` for a movement designation.
- **Gradual changes.** Ritardando and accelerando appear in every format, as text in most and as `<sound tempo>` in MusicXML. The timeline only has step changes, and no `Conductor` is built from a flow at all, so nothing keeps clock time through a ritardando.
- **Fermatas.** ABC writes `H` or `!fermata!`, LilyPond `\fermata`, MusicXML `<fermata>`, kern `;`, and MEI `<fermata>`, each on a note or rest. Every reader drops them, although in the Bach chorales fermatas mark the ends of phrases.
- **Meter symbols.** `Meter.common_time` answers `4/4`. ABC writes `M:C` and `M:C|`, MusicXML `symbol="common"` and `symbol="cut"`, and kern `*met(c)`. A score read back shows numerals where the composer wrote a symbol.

A fermata is written on notes and rests, but it belongs to the timeline. It does not change any note's pitch or written value, and the positions after it are unchanged; it changes clock time, and it stops every part at once. So a fermata is a hold on the flow's timeline: a position, the rhythmic span it holds, and how much longer the hold lasts, which the `Conductor` applies. It is not a `Time::TempoEvent`, which is a change that lasts until the next one; after a hold, the tempo is the tempo before it. The written symbols come back out of the hold: a writer puts a fermata on every voice event sounding when it begins.

This story also covers the tempo half of the format gaps found in the 2026-09-25 inventory: ABC `Q:` and LilyPond `\tempo` raise on import. MusicXML and MEI read numeric tempo, and kern, MEI (`@midi.bpm`), and MIDI write it, but no format keeps tempo text.

The `Conductor` also computes clock time wrongly across a meter change inside a tempo segment: 6:1 after a 3/4 change at bar 5 answers 10.0 s instead of 9.5 s.

## Example

```ruby
flow.change_tempo(1, HeadMusic::Rudiment::Tempo.new("quarter", 120, text: "Allegro"))
flow.add_tempo_ramp(from: "12:1", to: "13:1", to_tempo: HeadMusic::Rudiment::Tempo.new("quarter", 80), text: "rit.")
flow.change_meter(1, HeadMusic::Rudiment::Meter.common_time)   # remembers its symbol
flow.add_fermata("4:3", :half)                                   # holds a half note's span at 4:3

flow.tempo_at(1).text # => "Allegro"
flow.meter.symbol     # => :common
```

## Acceptance Criteria

### Tempo words

- [ ] A tempo can carry text, with or without a metronome mark, and keeps it through JSON
- [ ] A tempo with text and no number still answers a beats-per-minute value, from the named defaults `Tempo` already has, so the `Conductor` can run; the flow records that the number was not written
- [ ] `Tempo.get("allegro")` keeps the word as its text
- [ ] `Tempo.get` finds named tempos in any case and keeps the spelling it was given as text; two tempos that differ only in text are different tempo changes
- [ ] Tempo text with no number takes its beats per minute from the longest named tempo it contains ("Allegro ma non troppo" is an allegro), and otherwise ♩=120
- [ ] Text is tempo text when a format writes it in its tempo construct (ABC `Q:`, LilyPond `\tempo`, MEI `<tempo>`, kern `!!!OMD` and `*MM[…]`), whatever it says; MusicXML `<words>` is tempo text when its direction also has `<metronome>` or `<sound tempo>`, or when it begins with a named tempo or ramp word; other free text is dropped, pending text directions

### Gradual tempo changes

- [ ] A flow can hold a tempo ramp from one position to another toward a target tempo, with optional text ("rit.", "accel.", "rall.")
- [ ] A ramp's tempo changes linearly in beats per minute over musical position, from its start to its end; a ramp between different beat values interpolates in whole notes per minute; clock time through a ramp uses the closed form, not sampling
- [ ] The `Conductor` converts positions to clock time through a ramp by interpolating the tempo, and back from clock time to positions
- [ ] A ramp with no target tempo ramps to the tempo of a step change at its end, or else to ×3/4 of its start (×4/3 for accel. and stringendo), recorded as not written
- [ ] "a tempo" (restoring the tempo in force before the ramp) can be expressed and round-trips
- [ ] "a tempo" may sit in the middle of a bar, and restores the tempo in force at the start of the latest ramp before it
- [ ] Overlapping ramps raise `ArgumentError`
- [ ] Ramps that touch are allowed; a step tempo change strictly inside a ramp raises `ArgumentError`; a fermata inside a ramp is allowed and stretches the ramp's clock time
- [ ] `tempo_at(bar)` answers the authored tempo: the tempo before a ramp while inside it, the ramp's target after it; `Flow#sounding_tempo_at(position)` answers the interpolated tempo

### Fermatas

- [ ] A flow's timeline can hold a fermata at any position, including in the middle of a bar, spanning a rhythmic value, with a stretch the `Conductor` applies (a default, such as twice the span, when none is given)
- [ ] The `Conductor` lengthens clock time through a fermata by its stretch and leaves every musical position unchanged; clock time converts back to positions across it
- [ ] A fermata's stretch multiplies the clock time of its span (the default 2 makes the span last twice as long); clock time inside a fermata maps back to positions within its span
- [ ] A fermata leaves the tempo in force unchanged: `tempo_at` answers the same before and after it
- [ ] Overlapping fermatas raise `ArgumentError`
- [ ] The timeline's fermatas are kept through JSON
- [ ] Fermata marks on voice events whose sounding intervals overlap become one timeline fermata, from the latest of their starts to the earliest of their ends; a fermata marked in one voice only still holds the whole flow; a fermata on a rest holds like one on a note; a fermata on a tie's later link starts at that link

### Meter symbols

- [ ] A meter can carry a common-time or cut-time symbol, and a meter with a symbol stays equal to its numeric meter for every calculation
- [ ] The symbol is kept through JSON and through the timeline's meter changes
- [ ] `Meter.get` given a meter answers that meter, so `Flow.new(meter:)` and `change_meter` keep its symbol; `Meter.common_time.to_s` stays `"4/4"` and stays `==` to `Meter.get("4/4")`
- [ ] A meter change that changes only the symbol is kept by every reader and written by every writer

### Conductor

- [ ] `Flow#conductor` answers a `Conductor` built from the flow's meters, tempos, ramps, "a tempo" points, and fermatas, with clock zero at the downbeat of the earliest bar
- [ ] The `Conductor` computes clock time correctly across a meter change inside a tempo segment

### Formats

- [ ] ABC reads and writes `Q:`, including quoted tempo text, and `M:C` / `M:C|`
- [ ] LilyPond reads and writes `\tempo` with text and a metronome mark, and writes numeric or symbolic time signatures to match the meter
- [ ] MusicXML writes `<metronome>`, `<sound tempo>`, `<words>` for tempo text and ramps, and the time `symbol` attribute
- [ ] kern reads and writes `*met(c)` and `*met(c|)`, and tempo text through `!!!OMD` for the opening tempo
- [ ] ABC (`H`, `!fermata!`), LilyPond (`\fermata`), and kern (`;`) read fermatas written on voice events in any voice into timeline fermatas, and ABC, LilyPond, MusicXML, and kern write each timeline fermata on every voice event sounding when it begins
- [ ] MEI reads `<fermata>` and `@fermata` into timeline fermatas, `<tempo>` text, and `@meter.sym` / `<meterSig @sym>`, and the Herzliebster fixture keeps its fermatas
- [ ] MEI writes `<fermata>`, tempo text in `<tempo>`, and `@meter.sym` for the common- and cut-time symbols
- [ ] MEI reads and writes ramps as `<tempo func="continuous">` with `@tstamp2` or `@endid`
- [ ] MusicXML reads `<metronome>`, `<words>` as tempo text, `<sound tempo>` anywhere in a bar, ramps from ramp words with `<dashes>`, `<fermata>` on notes and rests, and `<time symbol>`, as the MusicXML Import story deferred to this one
- [ ] ABC and LilyPond read "rit.", "rall.", "accel.", and "a tempo" from annotations (`"^rit."`, `^"rit."`, `^\markup`) and drop other annotation text instead of raising; both write a ramp's text at its start and its target tempo at its end
- [ ] ABC reads and writes inline `[Q:…]` tempo changes
- [ ] LilyPond reads `\numericTimeSignature` and `\defaultTimeSignature`; it reads a plain `\time 4/4` or `\time 2/2` as common or cut time, since that is what LilyPond prints, and writes `\numericTimeSignature` before a numeric 4/4 or 2/2
- [ ] kern reads `*MM[Andante]` as tempo text; kern neither reads nor writes ramps, and does not raise on a flow that has them
- [ ] MIDI export writes tempo events through fermatas and gradual tempo changes, following the `Conductor`
- [ ] MIDI writes a ramp as tempo events at each count boundary inside it, with total clock time matching `flow.conductor`, and a fermata as the tempo divided by its stretch over its span, then restored; ramps and fermatas apply on every pass of performance order
- [ ] MIDI reads a slower tempo restored within one bar as a fermata, and a monotonic run of mid-bar tempo events as a ramp; other mid-bar tempo events are still skipped
- [ ] The hand-encoded chorale fixture (`satb_chorale.krn`) reads exactly two timeline fermatas, at 2:2 and 4:2, each a quarter
- [ ] The Herzliebster fixture reads exactly four timeline fermatas from its sixteen `<fermata>` elements, and its meter has the symbol `:common`
- [ ] Existing schema-5 documents read unchanged
- [ ] Maintains 90%+ test coverage

## Notes

- Timeline changes are downbeat-only (`Timeline.ensure_downbeat!`). Ramps, "a tempo" points, and fermatas need positions in the middle of a bar, so they live beside the timeline's changes in a shared `TimelineSpans` collection (see the plan).
- Fermatas moved here from [Articulations, Ornaments, Dynamics](../done/articulations-ornaments-dynamics.md) (2026-09-26), so the mid-bar timeline mechanism is built once. Until this story lands, the readers drop fermatas.
- Deriving the written symbols normalizes some sources: a part that marked only its last moving note under a held note in another voice, a fermata over a barline, and a general pause all come back as a fermata on every voice event sounding when the hold begins.
- MIDI export is done ([MIDI Export](../done/midi-export.md)); this story steps its tempo meta events through ramps and fermatas.
- Chord symbols are also a layer on the timeline, but they tie into harmony analysis and should get a story of their own. ABC chord symbols keep raising until then.

### Out of scope

- Ramp curve shapes: no format in scope can encode one, and a later optional `"shape"` key can add them without a schema break.
- Restoring the opening tempo from "Tempo I": it reads as tempo text only, since no reader needs the restoration to round-trip.
- Fermatas that apply on only one pass of a repeat: no format in scope encodes them structurally.
- Mid-bar step tempo changes (a numbered "Più mosso" mid-bar): they would change the `{bar => tempo}` shape every writer reads.

## Resolved Questions

1. **Ramp shape.** Linear in beats per minute over musical position; no curves.
2. **Staggered fermatas.** Overlapping marks form one hold from the latest start to the earliest end, the span where every marked event sounds together; writers put the fermata on every event sounding when it begins, so this round-trips.
3. **Character words.** Tempo text is whatever a format writes in its tempo construct; free-standing "dolce" waits for text directions, as [Articulations, Ornaments, Dynamics](../done/articulations-ornaments-dynamics.md) left it.

## Implementation Plan

Planned 2026-10-20 by the story planner (product-manager, two developers, best-practices-engineer). The `file:line` references were checked when this plan was written.

### Overview

- Tempo text and meter symbols become fields on the rudiments (`Tempo`, `Meter`).
- Tempo ramps, "a tempo" points, and fermata holds live in a new ordered collection inside `Flow::Timeline`, beside its three bar-keyed `EventMap`s.
- A flow gains a `Conductor` that converts through ramps (closed form, linear in tempo over musical position) and through holds (uniform slowing over the held span), on a subtick axis that is correct across meter changes.
- MIDI and all five text formats then read and write the new timeline items through shared helpers that collect the marks.
- Every phase leaves the suite green and is one commit.

### Facts the plan depends on

- **The `Conductor` is already wrong across meter changes.** `musical_time_converter.rb:27,52,68` uses one meter per tempo segment. `conductor_spec.rb:323-331` pins 10.0 s where the answer is 9.5 s.
- **No `Conductor` is built from a `Flow` today.** Only MIDI's own `ConductorTrack` exists.
- **`Meter.get` drops the symbol.** `Meter.get(Meter.common_time)` answers the plain registered 4/4 (`meter.rb:14`, `timeline.rb:32,70`).
- **`Tempo` has no `==`, and named lookup is case-sensitive.** `Tempo.get("Andante")` answers 120, and so does an unknown word such as `Tempo.get("dolce")` (`tempo.rb:43,53`).
- **Schema versions must match exactly** (`deserializer.rb:34-38`).
- **MIDI export exists, and its round trips will see fermatas.** It times events in whole notes (`midi/conductor_track.rb`). It round-trips kern `satb_chorale` and LilyPond `bach_invention_01` (`midi/round_trip_spec.rb:46-47`), and the invention has `\fermata`.
- **The chorale fixture's fermatas are at 2:2 and 4:2.** The pickup is bar 0, and a mid-bar repeat follows each fermata.
- **Herzliebster has 16 `<fermata>` elements,** four per staff, which group into four moments.
- **ABC raises on `Q:` and on quoted strings** (`abc/header.rb:85-89`, `abc/line_scanner.rb:104-107`).
- **LilyPond's `\time 4/4` prints 𝄴 by default,** so `lily_pond/voice_writer.rb:78-80` writes common time for every numeric 4/4 today.
- **Ruby has `Math.atanh` but no `log1p`.**

### Design decisions

1. **Where mid-bar items live.**
   - A new `Content::Flow::TimelineSpans` holds three instances inside `Timeline`: `tempo_ramps`, `a_tempos`, and `fermatas`. It keeps them sorted, inserts by binary search, and refuses half-open overlaps, the way `Spans#add` does.
   - Positions are normalized through `Content::Position.for_flow` and compared with the step maps' positions through `to_a`.
   - `Position#normalize` consults only the meter map, so storing these items creates no construction cycle.
   - `Content::Spans` is not reused: a `Span` needs a `SpanKind`, its overlap rule is for hairpins, and its owners are voices and parts.
   - Step tempo changes stay downbeat-only.
2. **Value types.**
   - `HeadMusic::Time::TempoRamp(from, to, to_tempo, text)`, `ATempo(position, text)`, and `Fermata(from, to, stretch)`, each a `Data.define`.
   - `add_fermata(position, rhythmic_value)` is the API, but a fermata is stored as `from`/`to`, because the overlap a reader finds is not always one rhythmic value.
3. **A fermata slows time uniformly.**
   - Clock time runs `stretch` times slower across `[from, to)`, with `DEFAULT_STRETCH = 2`.
   - This can be inverted, and MIDI can write it as the tempo divided by the stretch, then restored.
   - A pause added at one instant was rejected because it can do neither.
4. **`tempo_at(bar)` answers the authored tempo, never an interpolated one.**
   - Before or inside a ramp, it answers the tempo at the ramp's start.
   - After the ramp's end, it answers the ramp's target.
   - After an "a tempo", it answers the restored tempo.
   - Fermatas never change it.
   - An interpolated answer would make the readers' restatement checks (`timeline_reading.rb:31`, `kern/timeline_reader.rb:92`) see restatements that are not there.
   - `Flow#sounding_tempo_at(position)` answers the interpolated value, through `Conductor#tempo_at`.
5. **Invariants, each raising `ArgumentError`:**
   - A ramp overlapping a ramp.
   - A fermata overlapping a fermata.
   - A step tempo change strictly inside a ramp (checked by both `change_tempo` and `add_tempo_ramp`).
   - An "a tempo" strictly inside a ramp.
   - A ramp whose `from >= to`.
   - A target tempo of zero or fewer beats per minute.
   - A stretch below 1.

   These are allowed:

   - Ramps or fermatas whose ends touch.
   - A fermata inside or across a ramp.
   - A step change at a ramp's start, which sets the ramp's start tempo, or at its end, which overrides its target.
   - A meter change inside a ramp.

   `change_meter` re-checks the fermatas, since a meter change can move a fermata's end.
6. **Answers to the open questions.**
   - **Q1, ramp shape:** linear in speed over musical position, with no curve parameter, because no format in scope can encode a curve. When the two ends have different beat values, the tempo is interpolated in whole notes per minute. A later, optional `"shape"` key could add curves without breaking the schema.
   - **Q2, staggered fermatas:** fermata marks whose sounding intervals overlap form one hold.
     - The hold runs from the latest start among the marked events to the earliest end. That is the interval in which every marked event sounds together.
     - With the writer's rule (a fermata on every voice event sounding when the hold begins), this round-trips exactly.
     - The product-manager suggested ending at the latest end instead. The developers' rule wins because nothing marked then starts inside the hold. The two rules agree on every chorale pattern seen.
   - **Q3, character words:** tempo text is defined by where a format writes it, not by vocabulary.
     - Whatever sits in ABC `Q:`, LilyPond `\tempo`, MEI `<tempo>`, kern `!!!OMD`, or kern `*MM[…]` is tempo text.
     - MusicXML's `<words>` is tempo text only when the same direction has `<metronome>` or `<sound tempo>`, or when the text begins with a named tempo word or ramp word.
     - Free-standing "dolce" stays out of scope.
7. **A ramp with no written target** ramps to the step change at its end. With none there, it ramps to ×3/4 of its start (×4/3 for accel. and stringendo), with `metronome_mark: false`. A ramp read from text ends at the next numbered tempo mark, "a tempo", or fermata, or else at the end of the music.
8. **"a tempo"** is an `ATempo` point, which may sit mid-bar. It restores the tempo in force at the start of the latest ramp before it. With no ramp before it, it changes nothing and keeps its text.
9. **Clock zero for `Flow#conductor`** is the downbeat of the earliest bar, pickup bar included. MIDI keeps its own pickup offset.

### Phases

**Phase 1: Fix the `Conductor` across meter changes.** New `Time::MeterScale` measures positions in subticks across meter changes.
- It walks the meter events once, keeping the cumulative subticks at each change:
  ```
  x(p) = C_i + (bar − bar_i)·S_bar + (count − 1)·S_count + tick·SUBTICKS_PER_TICK + subtick
  ```
  The inverse finds the segment by binary search and then uses `divmod`.
- Switch `MusicalTimeConverter` to it, and round to nanoseconds once, at the output.
- Replace the `bar + 1000` guess and its silent fallback with a final segment that has no end.
- Change `conductor_spec.rb:323-331` to expect 9.5 s, and add the inverse (9.5 s gives `6:1`).

**Phase 2: Flow JSON schema 6 that still reads schema 5.**
- `SCHEMA_VERSION = 6` and `READABLE_SCHEMA_VERSIONS = [5, 6]`, used by `Deserializer` and `Project.from_h`.
- `V4Upgrade` stamps documents as 6.
- The specs for an unsupported version use 7. Add a spec that a schema-5 document reads unchanged.

**Phase 3: Meter symbols.**
- `Meter#symbol` takes a positional third argument, because `fetch_or_register` passes positional arguments. `NAMED` gives common time `:common` and cut time `:cut`.
- `Meter.get` returns a `Meter` it is given unchanged. `Meter.for_symbol(:common | :cut)` raises on anything else.
- `==` and `to_s` do not change.
- The timeline keeps the given instance through `Timeline.new(meter:)` and `change_meter`.
- JSON writes `"meter_symbol"` beside the opening `"meter"` and `"symbol"` in each meter change, leaving both out when there is no symbol. A symbol that disagrees with its numerals raises on read.

**Phase 4: Tempo text.**
- `Tempo.new(beat_value, bpm, text: nil, metronome_mark: true)`, with value equality over all four fields through `HeadMusic::ValueEquality`.
- `Tempo.for_text(text)` takes its defaults from the longest whole-word named tempo in the text, or else ♩=120, with `metronome_mark: false`. It is not memoized.
- `Tempo.get` looks names up in any case, keeps the given spelling as text (with `_` written as a space), memoizes on the exact text, and answers named tempos with `metronome_mark: false`.
- `TempoEvent` and `TempoMap` pass the `Tempo` through instead of rebuilding it from its parts.
- `timeline_reading.rb` `same_tempo?` compares the text.
- JSON writes `"text"` and `"metronome_mark": false`, leaving each out when it is at its default.

**Phase 5: The `Conductor`'s math for ramps and fermatas.**
- Add the three `Data` types. `Conductor` gains `tempo_ramps:`, `a_tempos:`, and `fermatas:`, and `Conductor#tempo_at(position)` answers the interpolated speed.
- The converter builds pieces on the `MeterScale` axis. A piece breaks at every tempo event, ramp end, "a tempo", and fermata end.
- **Speed** is `v(T) = bpm · ticks_per_beat · SUBTICKS_PER_TICK / 60e9`, in subticks per nanosecond.
  - Inside a ramp, `v(x) = v0 + Δ·(x − X0)/L`, where `L = X1 − X0`.
  - Each piece carries `s`, the stretch of the fermata covering it, or 1.
- **Position to clock time,** for a piece `[a, b)`, where the duration is `d = s·τ`:
  - A constant piece takes `τ = (b − a)/v_a`, as an exact `Rational`.
  - A ramp piece takes `u = Δ·(b − a)/L` and `τ = (2L/Δ)·atanh(u/(2·v_a + u))`, the form of `(L/Δ)·ln(v_b/v_a)` that avoids cancellation.
  - When `|Δ| < 1e-12·v_a`, the piece is treated as constant.
- **Clock time to position:** walk the pieces, subtracting each duration. In the piece where the remainder `r` runs out, let `t = r/s`:
  - A constant piece gives `x = a + t·v_a`.
  - A ramp piece gives `x = a + (v_a/k)·(2h/(1 − h))`, where `h = tanh(k·t/2)` and `k = Δ/L`.
  - Past the last piece, the music continues at the final speed.
  - A clock time inside a fermata maps proportionally into the held span.
- **Number types:** offsets are integer subticks, constant pieces use `Rational`, and only ramp interiors use `Float`. Round to integer nanoseconds once.
- **Round trips:** position → clock → position is exact. Clock → position → clock is within one subtick.

**Phase 6: The timeline and flow API.**
- `TimelineSpans`: `add`, `remove(from)`, `covering(position)`, `latest_at_or_before(position)`, and `to_a`. An "a tempo" is stored with `to = from`.
- `Timeline` gains the three collections, the invariants in decision 5, the `tempo_at` in decision 4, and `#conductor(starting_bar_number)`. Step changes are added to the `Conductor` last, so they win when they share a position with something else.
- `Flow` gains:
  - `add_tempo_ramp(from:, to:, to_tempo: nil, text: nil)`
  - `add_a_tempo(position, text: "a tempo")`
  - `add_fermata(position, span = nil, to: nil, stretch: Fermata::DEFAULT_STRETCH)`, which takes exactly one of `span` and `to`
  - removers for all three, and the lists `tempo_ramps`, `a_tempos`, and `fermatas`
  - `sounding_tempo_at(position)` and `conductor`
- JSON always writes the three lists:
  - `"tempo_ramps": [{"from", "to", "tempo", "text"}]`
  - `"a_tempos": [{"position", "text"}]`
  - `"fermatas": [{"from", "to", "stretch"}]`

  Positions are written as `Position#code`. On read, the meter changes are replayed first, then the ramps, the "a tempo" points, and the fermatas.

**Phase 7: MIDI export and import together.** This must land before any text reader produces fermatas, or the MIDI round trips break.
- New `MIDI::TempoSteps`, built from one `flow.conductor` per render, beside `hairpin_ramps.rb`.
  - Tempo steps fall at the downbeat, at each count boundary under a ramp, at ramp ends, at "a tempo" points, and at fermata ends.
  - A step under a ramp takes the average rate, so the file's total time matches the `Conductor` at every step.
  - Under a fermata, the tempo is divided by the stretch, then restored.
  - Elsewhere the steps are unchanged, so existing files keep their bytes.
- `ConductorTrack#tempo` becomes `#tempos`. Ramps and fermatas apply on every pass through the performance order.
- `Preflight` checks every tempo step.
- **Import:**
  - A slower tempo that is restored to the exact prior value within one bar becomes a fermata.
  - A monotonic run of at least two mid-bar tempo events that settles into a tempo held through the next downbeat becomes a ramp.
  - Other mid-bar events are still skipped.
- `spec/support/midi_round_trip.rb` compares ramps and fermatas, but not tempo text or meter symbols.

**Phase 8: Shared notation helpers** (no behavior change yet).
- `Notation::FermataMarks` collects marks with `add(voice_event, from:)` and `add_moment(position, voices)`. `apply(flow)` drops duplicates, groups overlapping intervals into one hold each, and rescues `ArgumentError` per group.
- `FermataMarks.carriers(flow)` answers, for each hold, the voice event sounding when it begins, in every voice, rests included.
- `Notation::TempoMarkReading` holds one vocabulary for every reader:
  - Ramp words: rit., ritard., ritardando, rall., rallentando, accel., accelerando, stringendo.
  - "a tempo" words: a tempo, tempo I, tempo primo. Tempo I is kept only as text.

  It collects marks with `add(position, tempo_or_nil, text)`, and `apply(flow)` turns them into steps, ramps, and "a tempo" points. A mark mid-bar that is neither a ramp nor an "a tempo" is dropped.
- `Notation::TempoMarks` gives writers the opening tempo, the changes, the ramp starts and ends, and the "a tempo" points, in time order.
- Extend `FlowTimedMarks` with fermata starts and ramp ends, so the writers' preflight checks cover them.

**Phase 9: ABC** (later specs build their flows with `ABC.parse`, so ABC comes first).
- **`Q:` and `[Q:…]`:** new `abc/tempo_field.rb` reads `1/4=120`, `3/8=60`, `"Allegro" 1/4=120` (with the text before or after the number), `"Allegro"` alone, and the legacy `Q:120` in `L:` units. Inline and body-line `Q:` become `:tempo` tokens.
- **Writing tempo:** the writer puts `Q:` before `K:` and `[Q:…]` at each change. A `"` in the text, or a fractional tempo, raises `RenderError`.
- **Meter symbols:** the writer writes `M:C` and `M:C|`. A tune with no `M:` reads as a plain 4/4, with no symbol.
- **Fermatas:**
  - `H`, `!fermata!`, `+fermata+`, and `!invertedfermata!` become a `:fermata` decoration kind.
  - Rests keep their fermatas, and a later tie link passes its own start.
  - A `!fermata!` written before a barline marks the voice's last event.
  - The writer writes `!fermata!` on every carrier.
- **Ramps:**
  - Quoted annotations with a `^ _ < > @` prefix are lexed. Ramp and "a tempo" words feed `TempoMarkReading`, and other annotation text is dropped.
  - Chord symbols keep raising.
  - The writer writes `"^rit."` at a ramp's start and `[Q:…]` at its end, which must be an attack or a barline.

**Phase 10: kern.**
- **Fermatas:**
  - `;` (and `;y`) comes out of `IGNORED` and becomes a `fermata` flag on the token.
  - Chord tokens combine the flag across their notes, and a later tie link carries its own mark.
  - The writer flags every carrier, rests included.
- **Meter symbols:** `*met(c)` and `*met(c|)` read and write. `TimelineReader#change?` compares symbols, because `==` ignores them. The writer adds a `*met(...)` row after `*M`.
- **Tempo text:** `!!!OMD` gives the opening tempo its text, `*MM[Andante]` reads as a tempo that has only text, and `ReferenceRecords` writes `!!!OMD:`.
- **Ramps:** none, read or written. kern has no ramp interpretation, and a mid-bar `*MM` is rejected. The writer writes downbeat `*MM` from the authored tempo and does not raise.

**Phase 11: MEI.**
- **Fermatas:**
  - New `mei/fermata_reader.rb` reads `@fermata` through `attribute_of`, and `<fermata>` by `startid` (across measures) or by `@tstamp` alone. It drops the duplicates Herzliebster encodes twice.
  - A new control source writes `<fermata startid staff>` on every carrier.
- **Meter symbols:** `@meter.sym` and `<meterSig @sym>` read and write.
- **Tempo text:**
  - `TempoReading` reads `<tempo>` text, including text nested in `<rend>`. Text with no `@mm` means the number was not written, and `DownbeatTempo` stops skipping such tempos.
  - The writer writes the text and leaves `@mm` out when the number was not written.
- **Ramps:** `<tempo func="continuous" tstamp tstamp2|endid>rit.</tempo>` reads and writes, and the next `<tempo @mm>` is the ramp's target.

**Phase 12: LilyPond.**
- **`\tempo`:**
  - A new lexer token reads an optional string and an optional `N(.)* = M(-K)?`. A range reads as its first number.
  - The writer writes `\tempo "Text" 4. = 60`, or `\tempo "Text"` alone, in the lead voice. A fractional tempo raises `RenderError`.
- **Time signatures:**
  - A plain `\time 4/4` or `\time 2/2` reads as `:common` or `:cut`, because that is what LilyPond prints.
  - `\numericTimeSignature` and `\defaultTimeSignature` read and write.
  - The writer puts `\numericTimeSignature` before a 4/4 or 2/2 that has no symbol.
- **Fermatas:** `\fermata` and the 2.26 variants become a `fermata` flag, combined across tie links, on notes, rests, and whole-bar rests. The writer writes `\fermata`.
- **Ramps:** `^"rit."` and `^\markup {…}` with ramp words are read, and other text is dropped instead of raising. The writer writes `^\markup \italic "rit."` (with `\after` when the ramp starts inside a note), and the target `\tempo` at the ramp's end.

**Phase 13: MusicXML.**
- **Writing:**
  - The time `symbol`.
  - New `music_xml/tempo_writer.rb`, in the first part only. It writes `<words>` and `<metronome>` as separate direction types, then `<offset>` and `<sound tempo>`. `<sound tempo>` counts quarter notes per minute: BPM × beat fraction × 4.
  - Ramps as `<words>rit.</words>` with `<dashes>`, and `<sound tempo>` at the target.
  - `<fermata type="upright"/>` on every carrier, rests included.
- **Reading:**
  - New `music_xml/fermata_reader.rb`.
  - `@symbol` on 4/4 and 2/2.
  - `<metronome>`, preferred over `<sound tempo>`.
  - `<words>` as tempo text, per decision 6.
  - Ramps from ramp words plus dashes plus the next `<sound tempo>`.

**Phase 14: Wrap-up.** Write the CHANGELOG, correct the story, and run `bundle exec rake validate` and `bundle exec rake oracles`.

### CHANGELOG entries

- **Added:**
  - `Tempo` text and `metronome_mark`, and `Tempo.for_text`.
  - `Meter#symbol` and `Meter.for_symbol`.
  - `Flow#add_tempo_ramp`, `#add_a_tempo`, and `#add_fermata`, with their removers and lists.
  - `Flow#sounding_tempo_at` and `Flow#conductor`.
  - The `Conductor` converts through ramps and fermatas in both directions.
  - Flow JSON schema 6. Schema-5 documents still read.
  - MIDI writes tempo steps through ramps and fermatas, and reads fermatas and ramps back.
  - One line per format.
- **Changed:**
  - **Breaking.** `Tempo` compares by value, and `Tempo.get` keeps its word as text.
  - **Breaking.** `Meter.get` returns a `Meter` it is given unchanged.
  - **Breaking.** `SCHEMA_VERSION` is 6.
  - **Breaking.** A LilyPond plain `\time 4/4` or `\time 2/2` reads as common or cut time, and the writer writes `\numericTimeSignature` before a numeric one.
  - **Breaking.** An ABC tune with no `M:` reads as a plain 4/4.
  - **Breaking.** `MIDI::ConductorTrack#tempo` becomes `#tempos`.
- **Fixed:**
  - The `Conductor`'s clock time across a meter change.
  - `clock_to_musical` past 1000 bars.
  - `Tempo.get("Andante")` answers andante instead of ♩=120.

### Testing strategy

- **`Conductor`:**
  - A 4/4 bar ramping from 120 to 80 takes 2.432790649 s, and the inverse holds.
  - A ramp whose two ends are equal.
  - A ramp across a meter change.
  - A ramp between different beat values.
  - The chorale case: ♩=100 in 3/4, with a stretch-2 hold over `[2:2, 2:3)`.
  - A fermata inside a ramp.
  - A fermata on the final event lengthens the total.
  - The round-trip bounds from Phase 5.
- **Invariants:** one spec for each `ArgumentError` in decision 5, and one for each allowed case.
- **JSON:** every new key round-trips; a schema-5 document reads with defaults; a symbol that disagrees with its numerals raises and names its path.
- **Shared fixtures:** new `spec/support/timeline_expression_fixtures.rb` builds ABC flows with `Q:`, `M:C`, `H`, a bass eighth pair staggered under a soprano quarter, and "rit. … a tempo". Its `expect_same_timeline` ignores what a format cannot hold: the stretch everywhere except JSON and MIDI, and ramps in kern.
- **Fixtures:**
  - `satb_chorale.krn`: fermatas at 2:2 and 4:2.
  - `bach_invention_01.ly`: a fermata at 22:1 spanning a whole note, and meter `:common`.
  - Herzliebster: four fermatas, pinned from a run.
  - Ein feste Burg: fermatas from the outer voices only, including a cross-measure `startid`.
- **Oracles:** LilyPond `compile_warnings` on every new rendering, the MusicXML XSD, the MEI schema, and Verovio.

### Risks

- **The phase order matters.** Kern or LilyPond fermata reading must not land before Phase 7, or the MIDI round trips and the corpus spec break.
- **MIDI ramp import is inference.** It is exact for this gem's own exports and a heuristic for other files.
- **The ×3/4 default target for "rit." is invented.**
- **A mid-bar step tempo change, such as "Più mosso" with a number, is dropped.** Supporting it would change the `{bar => tempo}` shape that every writer reads.
- **The LilyPond change touches every 4/4 rendering.** Text specs that expect a bare `\time 4/4` need updating.
- **ABC chord symbols keep raising** once annotations are read.
- **A fermata over a barline** reads as a hold on the events that end there.
- **The stretch survives only through JSON and MIDI.**
- **`Flow#conductor` is rebuilt on every call,** so `TempoSteps` must reuse one instance.
