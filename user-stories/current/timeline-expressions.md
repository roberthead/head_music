<!--
metadata:
  created_at:   2026-09-25T14:05:53-07:00
  activated_at: 2026-10-20T16:02:22-07:00
  planned_at:   2026-10-20T16:24:28-07:00
  finished_at:
  updated_at:   2026-10-21T11:25:49-07:00
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
flow.add_a_tempo("14:1")                                         # back to ♩=120
flow.change_meter(1, HeadMusic::Rudiment::Meter.common_time)   # remembers its symbol
flow.add_fermata("4:3", :half)                                   # holds a half note's span at 4:3

flow.tempo_at(1).text # => "Allegro"
flow.meter_at(1).symbol # => :common
```

## Acceptance Criteria

### Tempo words

- [x] A tempo can carry text, with or without a metronome mark, and keeps both through JSON
- [x] `Tempo.get` finds named tempos in any case and keeps the spelling it was given as its text: `Tempo.get("allegro").text` is `"allegro"`
- [x] Tempo text with no number still answers a beats-per-minute value, so the `Conductor` can run: that of the longest named tempo it contains ("Allegro ma non troppo" is an allegro), and otherwise ♩=120; the tempo records that the number was not written
- [x] Two tempos that differ only in text are different tempo changes
- [x] Text is tempo text when a format writes it in its tempo construct (ABC `Q:`, LilyPond `\tempo`, MEI `<tempo>`, kern `!!!OMD` and `*MM[…]`), whatever it says; MusicXML `<words>` is tempo text when its direction also has `<metronome>` or `<sound tempo>`, or when it begins with a named tempo or ramp word; other free text is dropped, pending text directions

### Gradual tempo changes

- [x] A flow can hold a tempo ramp from one position to another, including in the middle of a bar, toward a target tempo, with optional text ("rit.", "accel.", "rall.")
- [x] A ramp's tempo changes linearly in beats per minute over musical position, from its start to its end; a ramp between different beat values interpolates in whole notes per minute
- [x] The `Conductor` converts positions to clock time through a ramp in closed form, not by sampling, and converts clock time back to positions
- [x] A ramp with no target tempo ramps to the tempo of a step change at its end, or else to ×3/4 of its start (×4/3 for accel. and stringendo), recorded as not written
- [x] "a tempo" may sit in the middle of a bar, restores the tempo in force at the start of the latest ramp before it, and round-trips
- [x] Overlapping ramps raise `ArgumentError`, and so does a step tempo change or an "a tempo" strictly inside a ramp; ramps that touch are allowed, and a fermata inside a ramp is allowed and stretches the ramp's clock time
- [x] `tempo_at(bar)` answers the authored tempo: inside a ramp, the tempo at its start; after it, its target; `Flow#sounding_tempo_at(position)` answers the interpolated tempo

### Fermatas

- [x] A flow's timeline can hold a fermata at any position, including in the middle of a bar, spanning a rhythmic value, with a stretch that multiplies the clock time of its span (by default 2, so the span lasts twice as long)
- [x] The `Conductor` lengthens clock time through a fermata by its stretch and leaves every musical position unchanged; a clock time inside a fermata maps back to a position within its span
- [x] A fermata leaves the tempo in force unchanged: `tempo_at` answers the same before and after it
- [x] Overlapping fermatas raise `ArgumentError`
- [x] The timeline's fermatas are kept through JSON
- [x] Fermata marks on voice events whose sounding intervals overlap become one timeline fermata, from the latest of their starts to the earliest of their ends; a fermata marked in one voice only still holds the whole flow; a fermata on a rest holds like one on a note; a fermata on a tie's later link starts at that link
- [x] Every text format writes a timeline fermata as a fermata mark on each voice event sounding when it begins, in every voice; ABC, which writes one voice, marks that voice (see [ABC Voices and Meter Changes](../backlog/abc-voices-and-meter-changes.md))

### Meter symbols

- [x] A meter can carry a common-time or cut-time symbol, and a meter with a symbol stays equal to its numeric meter for every calculation: `Meter.common_time.to_s` stays `"4/4"` and stays `==` to `Meter.get("4/4")`
- [x] `Meter.get` given a meter answers that meter, so `Flow.new(meter:)` and `change_meter` keep its symbol
- [x] The symbol is kept through JSON and through the timeline's meter changes
- [x] A meter change that changes only the symbol is kept by every reader and written by every writer except ABC's, which refuse every meter change after the opening (see [ABC Voices and Meter Changes](../backlog/abc-voices-and-meter-changes.md))

### Conductor

- [x] `Flow#conductor` answers a `Conductor` built from the flow's meters, tempos, ramps, "a tempo" points, and fermatas, with clock zero at the downbeat of the earliest bar
- [x] The `Conductor` computes clock time correctly across a meter change inside a tempo segment

### Formats

ABC

- [x] Reads and writes `Q:` and inline `[Q:…]`, including quoted tempo text, and `M:C` / `M:C|`
- [x] Reads `H` and `!fermata!` on notes and rests into timeline fermatas, and writes them
- [x] Reads "rit.", "rall.", "accel.", and "a tempo" from annotations (`"^rit."`) and drops other annotation text instead of raising; writes a ramp's text at its start and its target tempo at its end

LilyPond

- [x] Reads and writes `\tempo` with text, a metronome mark, or both
- [x] Reads a plain `\time 4/4` or `\time 2/2` as common or cut time, since that is what LilyPond prints; reads `\numericTimeSignature` and `\defaultTimeSignature`; writes `\numericTimeSignature` before a 4/4 or 2/2 with no symbol
- [x] Reads `\fermata` into timeline fermatas, and writes it
- [x] Reads "rit.", "rall.", "accel.", and "a tempo" from annotations (`^"rit."`, `^\markup`) and drops other annotation text instead of raising; writes a ramp's text at its start and its target `\tempo` at its end

MusicXML

- [x] Writes `<metronome>`, `<sound tempo>`, `<words>` for tempo text and ramps, `<fermata>`, and the time `symbol` attribute
- [x] Reads `<metronome>`, `<words>` as tempo text, `<sound tempo>` anywhere in a bar, ramps from ramp words with `<dashes>`, `<fermata>` on notes and rests, and `<time symbol>`, as the MusicXML Import story deferred to this one

kern

- [x] Reads and writes `*met(c)` and `*met(c|)`, tempo text through `!!!OMD` for the opening tempo, and `;` fermatas
- [x] Reads `*MM[Andante]` as tempo text
- [x] Neither reads nor writes ramps, and does not raise on a flow that has them

MEI

- [x] Reads `<fermata>` and `@fermata` into timeline fermatas, `<tempo>` text, and `@meter.sym` / `<meterSig @sym>`
- [x] Writes `<fermata>`, tempo text in `<tempo>`, and `@meter.sym` for the common- and cut-time symbols
- [x] Reads and writes ramps as `<tempo func="continuous">` with `@tstamp2` or `@endid`

MIDI

- [x] Writes a ramp as tempo events at each count boundary inside it, with total clock time matching `flow.conductor`, and a fermata as the tempo divided by its stretch over its span, then restored; ramps and fermatas apply on every pass of performance order
- [x] Reads a slower tempo restored within one bar as a fermata, and a monotonic run of mid-bar tempo events as a ramp; other mid-bar tempo events are still skipped

### Fixtures and compatibility

- [x] The hand-encoded chorale fixture (`satb_chorale.krn`) reads exactly two timeline fermatas, at 2:2 and 4:2, each a quarter, at the ends of its phrases
- [x] The Herzliebster fixture reads exactly four timeline fermatas from its sixteen `<fermata>` elements, and its meter has the symbol `:common`
- [x] Existing schema-5 documents read unchanged: the new keys are optional within schema 5, which no release has shipped yet
- [x] Maintains 90%+ test coverage

## Notes

- Timeline changes are downbeat-only (`Timeline.ensure_downbeat!`). Ramps, "a tempo" points, and fermatas need positions in the middle of a bar, so they live beside the timeline's changes in a shared `TimelineSpans` collection (see the plan).
- Fermatas moved here from [Articulations, Ornaments, Dynamics](../done/articulations-ornaments-dynamics.md) (2026-09-26), so the mid-bar timeline mechanism is built once. Until this story lands, the readers drop fermatas.
- Deriving the written symbols normalizes some sources: a part that marked only its last moving note under a held note in another voice, a fermata over a barline, and a general pause all come back as a fermata on every voice event sounding when the fermata begins.
- MIDI export is done ([MIDI Export](../done/midi-export.md)); this story steps its tempo meta events through ramps and fermatas.
- Chord symbols are also a layer on the timeline, but they tie into harmony analysis and should get a story of their own. ABC chord symbols keep raising until then.

### Out of scope

- Ramp curve shapes: no format in scope can encode one, and a later optional `"shape"` key can add them without a schema break.
- Restoring the opening tempo from "Tempo I": it reads as tempo text only, since no reader needs the restoration to round-trip.
- Fermatas that apply on only one pass of a repeat: no format in scope encodes them structurally.
- Mid-bar step tempo changes (a numbered "Più mosso" mid-bar): they would change the `{bar => tempo}` shape every writer reads, so readers drop them.
- Tempo text in MIDI: it could be a marker meta event, but no reader needs it to round-trip.

## Resolved Questions

1. **Ramp shape.** Linear in beats per minute over musical position; no curves.
2. **Staggered fermatas.** Overlapping marks form one fermata from the latest start to the earliest end, the span where every marked event sounds together; writers put a mark on every event sounding when it begins, so this round-trips.
3. **Character words.** Tempo text is whatever a format writes in its tempo construct; free-standing "dolce" waits for text directions, as [Articulations, Ornaments, Dynamics](../done/articulations-ornaments-dynamics.md) left it.

Decided on 2026-10-20, with the plan:

4. **MIDI ramps are inferred** from monotonic runs of mid-bar tempo events, accepting a heuristic for files the gem did not write.
5. **A ramp with no written target** ramps to ×3/4 of its start (×4/3 for accel.), recorded as not written.
6. **A plain LilyPond `\time 4/4`** reads as common time, as LilyPond prints it, even though every 4/4 rendering changes.

## Implementation Notes

Implemented 2026-10-20/21 on `story/timeline-expressions`: Phase 1 directly; Phases 3–9 by developer agents in sequence; Phases 10–13 and a MIDI follow-up by five worktree agents in parallel from the ABC commit, then cherry-picked; then two consolidation agents and six RubyCritic agents. `rake validate` passes (18,490 examples, coverage 99.77%, RubyCritic 83.75 with no file below C), and `rake oracles` with both schemas, MuseScore, and the 370 chorales passes (1,012 examples, 0 failures).

Where the work departed from the plan:

- **No schema bump.** Schema 5 has not shipped (v22.0.0 writes 4), so the new keys are optional within it (Phase 2 dropped).
- **Meter changes refuse to strand** a ramp, "a tempo", or fermata on a count its bar no longer has, and restore the previous meter; readers set meters first.
- **A fermata mark lasts until the next mark on the same voice event,** so a tied note can carry two fermatas (one per link) in every format, and LilyPond `c'2\fermata~ c'2\fermata` reads as two. `FermataMarks.carriers` maps each event to all its fermatas.
- **MIDI import** reads a whole-bar slowdown as a fermata only when no note starts inside the bar (the tempo bytes cannot tell a fermata from a one-bar tempo change), and takes a ramp's run only from changes a count or less apart, as export writes them.
- **`TempoMarkReading#add_ramp_end`** lets MusicXML `<dashes>` and MEI `@tstamp2` end a ramp where they say.
- **ABC** writes one voice and no meter changes, as before, so the chorale fixture only reads from ABC, and the symbol-only meter change criterion does not apply to it.
- **`Tempo.get("Moderato")`** answered ♩=0 (it contains "at"); fixed with the case bug.
- **Constant tempo pieces are exact Rationals;** `Tempo#ticks_per_beat` is a Float, which had made them Floats.

Left open, for a later story or a decision:

- **chor202.krn:** the tenor's `;` sits on the later link of a tied note, so kern reads two touching fermatas (2:4–3:1 and 3:1–3:1:480) where the music means one. This follows the criterion that a mark on a later link starts there; MIDI already treats touching fermatas of one stretch as one.
- **MIDI inference residue:** a ramp starting at a bar that also changes tempo, a fermata inside a ramp, a ramp ending mid-bar followed by another change in that bar, and a whole-bar fermata followed by a new tempo do not round-trip through MIDI. A ramp another program writes with steps sparser than a count reads as downbeat tempos.
- **Fermata stretch** survives only JSON and MIDI.
- **`references/content-schema.md`** is still marked "as of 21.1.0" apart from the new timeline keys.

## Implementation Plan

Planned 2026-10-20 by the story planner (product-manager, two developers, best-practices-engineer), and revised the same day for consistency. The `file:line` references were checked when the plan was written.

### Terms

- **Fermata:** the timeline item, a `Time::Fermata` from `from` to `to` with a `stretch`. It holds every voice at once.
- **Fermata mark:** the written symbol on one voice event (ABC `H`, kern `;`, `<fermata>`). Readers collect marks and turn them into fermatas; writers derive marks from fermatas.
- **Carriers:** the voice events, in every voice and rests included, sounding when a fermata begins. A writer puts a fermata mark on each.
- **Step change:** a tempo, meter, or key change at a downbeat, as the timeline has today.
- **Authored tempo** is the tempo as written; **sounding tempo** is the interpolated tempo at a position inside a ramp.

### Overview

- Tempo text and meter symbols become fields on the rudiments (`Tempo`, `Meter`).
- Ramps, "a tempo" points, and fermatas live in a new ordered collection inside `Flow::Timeline`, beside its three bar-keyed `EventMap`s of step changes.
- A flow builds a `Conductor` that converts through ramps (closed form) and fermatas (uniform slowing), on a subtick axis that is correct across meter changes.
- MIDI and all five text formats then read and write the new items through shared helpers.
- Every phase leaves the suite green and is one commit.

### Facts the plan depends on

- **The `Conductor` is already wrong across meter changes.** `musical_time_converter.rb:27,52,68` uses one meter per tempo segment. `conductor_spec.rb:323-331` pins 10.0 s where the answer is 9.5 s.
- **No `Conductor` is built from a `Flow` today.** Only MIDI's own `ConductorTrack` keeps time for a flow.
- **The `Conductor`'s `TempoMap` is keyed by musical position,** not by bar (`tempo_map.rb:33-41`), so it already accepts tempo events in the middle of a bar.
- **`Meter.get` drops the symbol.** `Meter.get(Meter.common_time)` answers the plain registered 4/4 (`meter.rb:14`, `timeline.rb:32,70`).
- **`Tempo` has no `==`, and named lookup is case-sensitive.** `Tempo.get("Andante")` answers ♩=120, and so does an unknown word such as `Tempo.get("dolce")` (`tempo.rb:43,53`).
- **Schema versions must match exactly** (`deserializer.rb:34-38`).
- **MIDI round trips will see fermatas.** MIDI export times events in whole notes (`midi/conductor_track.rb`), and round-trips kern `satb_chorale` and LilyPond `bach_invention_01` (`midi/round_trip_spec.rb:46-47`); both fixtures have fermata marks.
- **The chorale fixture's fermatas are at 2:2 and 4:2.** The pickup is bar 0, and a mid-bar repeat follows each fermata.
- **Herzliebster has 16 `<fermata>` elements,** four per staff, which group into four fermatas.
- **ABC raises on `Q:` and on quoted strings** (`abc/header.rb:85-89`, `abc/line_scanner.rb:104-107`).
- **LilyPond prints a plain `\time 4/4` as 𝄴,** so every numeric 4/4 the LilyPond writer emits today renders as common time (`lily_pond/voice_writer.rb:78-80`).
- **Ruby has `Math.atanh` but no `log1p`.**

### Design decisions

1. **Where mid-bar items live.**
   - A new `Content::Flow::TimelineSpans` holds each of `tempo_ramps`, `a_tempos`, and `fermatas` inside `Timeline`. It keeps its items sorted, inserts by binary search, and refuses an item that overlaps another (half-open intervals), as `Spans#add` does (`spans.rb:22-31`). An "a tempo" is a point (`to == from`), so two at the same position count as overlapping.
   - Positions are normalized through `Content::Position.for_flow` and compared with the step changes' positions through `to_a`. `Position#normalize` consults only the meter map, so storing these items creates no construction cycle.
   - `Content::Spans` is not reused: a `Span` needs a `SpanKind`, its overlap rule is for hairpins, and its owners are voices and parts.
   - Step tempo changes stay downbeat-only.
2. **Value types.** `Time::TempoRamp(from, to, to_tempo, text)`, `Time::ATempo(position, text)`, and `Time::Fermata(from, to, stretch)`, each a `Data.define`. `add_fermata(position, rhythmic_value)` is the API, but a fermata is stored as `from`/`to`, because the overlap a reader finds is not always one rhythmic value.
3. **A fermata slows time uniformly.** Clock time runs `stretch` times slower across `[from, to)`, with `Fermata::DEFAULT_STRETCH = 2`. This can be inverted, and MIDI can write it as the tempo divided by the stretch, then restored. A pause added at one instant was rejected because it can do neither.
4. **A ramp is linear in tempo** over musical position, from the tempo in force at `from` to its target at `to`. When the two ends have different beat values, it interpolates in whole notes per minute, and the sounding tempo is reported in the starting beat value.
5. **A ramp's target.**
   - `to_tempo` is the target when it is given.
   - When it is nil, it stays nil in the timeline and in JSON, and is resolved wherever a target is needed (`tempo_at`, `#conductor`): the step change at `to`, if there is one, or else ×3/4 of the starting tempo (×4/3 for accel., accelerando, and stringendo), with `metronome_mark: false`.
   - A step change at `to` that differs from a given `to_tempo` takes effect at `to`, after the ramp, as any step change does.
6. **"a tempo"** restores the tempo in force at the start of the latest ramp before it. With no ramp before it, it changes nothing and keeps its text.
7. **`tempo_at(bar)` answers the authored tempo, never the sounding one.**
   - In a bar whose downbeat lies inside a ramp, it answers the tempo at the ramp's start.
   - At or after the ramp's end, it answers the ramp's target.
   - At or after an "a tempo", it answers the restored tempo.
   - Fermatas never change it.
   - An interpolated answer would make the readers' restatement checks (`timeline_reading.rb:31`, `kern/timeline_reader.rb:92`) see restatements that are not there.
   - `Flow#sounding_tempo_at(position)` answers the interpolated tempo, through `Conductor#tempo_at`.
8. **Invariants.** `Timeline` raises `ArgumentError` for:
   - a ramp that overlaps another ramp, or a fermata that overlaps another fermata;
   - a step tempo change strictly inside a ramp, whether `change_tempo` or `add_tempo_ramp` comes second;
   - an "a tempo" strictly inside a ramp;
   - a ramp whose `from >= to`;
   - a target tempo of zero or fewer beats per minute;
   - a stretch below 1.

   It allows:

   - ramps that touch, and fermatas that touch;
   - a fermata inside or across a ramp;
   - a step tempo change at a ramp's start (it sets the starting tempo) or at its end (decision 5);
   - a meter change inside a ramp.

   `change_meter` and `remove_meter_change` raise `ArgumentError`, and put the previous meter back, when a ramp, "a tempo", or fermata would sit on a count or tick its bar no longer has. Readers therefore set meters before adding these items. (Validation of a ramp's `from >= to` and target, and of a fermata's stretch, lives in the value types, so it holds everywhere.)
9. **Reading fermata marks.** Marks whose sounding intervals overlap form one fermata, from the latest of their starts to the earliest of their ends: the span in which every marked event sounds together. Unmarked voices are ignored. Writers mark the carriers, so this round-trips. Ending at the latest end instead was rejected, because a marked event could then start inside the fermata.
10. **Reading tempo text.** Text is tempo text because of where a format writes it, not because of its words:
    - Whatever sits in ABC `Q:`, LilyPond `\tempo`, MEI `<tempo>`, kern `!!!OMD`, or kern `*MM[…]` is tempo text.
    - MusicXML has no tempo slot: `<words>` is tempo text only when the same direction has `<metronome>` or `<sound tempo>`, or when it begins with a named tempo or ramp word.
    - Deciding by vocabulary would be unsafe, because `Tempo.get` turns any unknown word into ♩=120.
11. **Reading ramps from text.** A ramp word starts a ramp that ends at the next numbered tempo mark, "a tempo", or fermata, or else at the end of the music. The numbered mark at its end, if any, is its target.
12. **Building the `Conductor`.** `Timeline#conductor` resolves ramp targets and "a tempo" points into tempo events (the `TempoMap` accepts mid-bar positions), and passes ramps and fermatas to the `Conductor`, which knows nothing of "a tempo". Step changes are added last, so they win when they share a position with a resolved event (`event_map.rb:74-75`). Clock zero is the downbeat of the earliest bar, pickup bar included; MIDI keeps its own offset for a pickup.

### Phases

**Phase 1: Fix the `Conductor` across meter changes.**
- New `Time::MeterScale` measures positions in subticks across meter changes. It walks the meter events once, keeping the cumulative subticks `C_i` at each change `i`:
  ```
  x(p) = C_i + (bar − bar_i)·S_bar + (count − 1)·S_count + tick·SUBTICKS_PER_TICK + subtick
  ```
  The inverse finds the segment by binary search and then uses `divmod`.
- Switch `MusicalTimeConverter` to it, and round to nanoseconds once, at the output.
- Replace the `bar + 1000` guess and its silent fallback with a final segment that has no end.
- Change `conductor_spec.rb:323-331` to expect 9.5 s, and add the inverse (9.5 s gives `6:1`).

**Phase 2: dropped.** The plan bumped the schema to 6, but v22.0.0 wrote schema 4, so schema 5 first ships in 23.0.0, and this release's other new keys are optional within it. The new keys in Phases 3, 4, and 6 are optional within schema 5 too, and a document without them reads as before. (A schema-6 commit was written and then removed.)

**Phase 3: Meter symbols.**
- `Meter.new(top, bottom, symbol = nil)`, positional because `fetch_or_register` passes positional arguments (`base.rb:18-21`), with `attr_reader :symbol`. `NAMED` gives common time `:common` and cut time `:cut`.
- `Meter.get` returns a `Meter` it is given unchanged. `Meter.for_symbol(:common | :cut)` raises on anything else.
- `==` and `to_s` do not change.
- The timeline keeps the given instance through `Timeline.new(meter:)` and `change_meter`.
- JSON writes `"meter_symbol"` beside the opening `"meter"`, and `"symbol"` in each meter change, leaving both out when there is no symbol. A symbol that disagrees with its numerals raises on read.

**Phase 4: Tempo text.**
- `Tempo.new(beat_value, bpm, text: nil, metronome_mark: true)`, with value equality over all four fields through `HeadMusic::ValueEquality`. `metronome_mark: false` records that the number was not written; `bpm` is always present.
- `Tempo.get` keeps its identifiers (names and `"q = 120"`). It looks names up in any case, keeps the given spelling as text (writing `_` as a space), memoizes on the exact text, and answers named tempos with `metronome_mark: false`.
- `Tempo.for_text(text)` is what readers use for free tempo text. It takes its defaults from the longest whole-word named tempo in the text, or else ♩=120, with `metronome_mark: false`. It is not memoized.
- `TempoEvent` and `TempoMap` pass the `Tempo` through instead of rebuilding it from its parts (`tempo_event.rb:34-37`, `tempo_map.rb:30`).
- `timeline_reading.rb` `same_tempo?` compares the text.
- JSON writes `"text"` and `"metronome_mark": false` in each tempo, leaving each out when it is at its default.

**Phase 5: The `Conductor`'s math for ramps and fermatas.**
- Add the three `Data` types. `Conductor.new` gains `tempo_ramps:` and `fermatas:` (decision 12), and `Conductor#tempo_at(position)` answers the sounding tempo.
- The converter divides the `MeterScale` axis into pieces, breaking at every tempo event, at both ends of every ramp, and at both ends of every fermata.
- **Speed** is `v = bpm · ticks_per_beat · SUBTICKS_PER_TICK / 60e9`, in subticks per nanosecond.
  - Inside a ramp from `X0` to `X1`, `v(x) = v0 + Δ·(x − X0)/L`, where `L = X1 − X0` and `Δ = v1 − v0`.
  - Each piece carries `s`, the stretch of the fermata covering it, or 1.
- **Position to clock time.** A piece `[a, b)` lasts `s·τ`, where:
  - a constant piece has `τ = (b − a)/v_a`, as an exact `Rational`;
  - a ramp piece has `u = Δ·(b − a)/L` and `τ = (2L/Δ)·atanh(u/(2·v_a + u))`, the form of `(L/Δ)·ln(v_b/v_a)` that avoids cancellation;
  - a ramp with `|Δ| < 1e-12·v_a` is treated as constant.

  Sum the whole pieces before the target, then the partial piece.
- **Clock time to position.** Walk the pieces, subtracting each duration. In the piece where the remainder `r` runs out, let `t = r/s`:
  - a constant piece gives `x = a + t·v_a`;
  - a ramp piece gives `x = a + (v_a/k)·(2h/(1 − h))`, where `k = Δ/L` and `h = tanh(k·t/2)`;
  - past the last piece, the music continues at the final speed.

  Since `s` divides the time, a clock time inside a fermata maps proportionally into its span.
- **Number types.** Offsets are integer subticks, constant pieces use `Rational`, and only ramp interiors use `Float`. Round to integer nanoseconds once.
- **Round trips.** Position → clock → position is exact, since a subtick is about 2,170 ns at ♩=120. Clock → position → clock is within one subtick.

**Phase 6: The timeline and flow API.**
- `TimelineSpans`: `add`, `remove(from)`, `covering(position)`, `latest_at_or_before(position)`, and `to_a`.
- `Timeline` gains the three collections, the invariants (decision 8), the authored `tempo_at` (decision 7), and `#conductor(starting_bar_number)` (decision 12).
- `Flow` gains:
  - `add_tempo_ramp(from:, to:, to_tempo: nil, text: nil)`, which adds bars as `change_*` does (`flow.rb:110`);
  - `add_a_tempo(position, text: "a tempo")`;
  - `add_fermata(position, span = nil, to: nil, stretch: Fermata::DEFAULT_STRETCH)`, which takes exactly one of `span` and `to`;
  - `remove_tempo_ramp`, `remove_a_tempo`, and `remove_fermata`, each by start position;
  - `tempo_ramps`, `a_tempos`, `fermatas`, `sounding_tempo_at(position)`, and `conductor`.
- JSON always writes the three lists, as it writes the lists of step changes:
  - `"tempo_ramps": [{"from", "to", "tempo", "text"}]`, with `"tempo"` left out when the target is nil;
  - `"a_tempos": [{"position", "text"}]`;
  - `"fermatas": [{"from", "to", "stretch"}]`, with a whole stretch written as an Integer.

  Positions are written as `Position#code`. On read, meter changes are replayed first, then ramps, "a tempo" points, and fermatas, each with its path for error messages (`deserializer.rb:153-159`).

**Phase 7: MIDI export and import, together.** This must land before any text reader produces fermatas (Phases 9–13), or the MIDI round trips break.
- **Export.** New `MIDI::TempoSteps`, beside `hairpin_ramps.rb`, built from one `flow.conductor` per render. `#in_bar(bar_number)` answers `[[offset, microseconds_per_quarter], …]`:
  - tempo steps fall at each downbeat, at each count boundary under a ramp, at both ends of every ramp and fermata, and at "a tempo" points;
  - a step under a ramp takes the average rate over the step, so the file's clock time matches the `Conductor` at every step;
  - under a fermata, the tempo is divided by the stretch, and restored at its end, even at the end of the piece;
  - a flow with no ramps or fermatas exports the same bytes as today.
- `ConductorTrack#tempo` becomes `#tempos` (`conductor_track.rb:20,49-51`). Ramps and fermatas apply on every pass through the performance order, and a jump into a ramp resumes at the sounding tempo there.
- `Preflight#check_tempos` checks every step against `MAX_MICROSECONDS_PER_QUARTER`.
- **Import** (`midi/timeline_reader.rb:74-79`):
  - a slower tempo restored to the exact prior value within one bar becomes a fermata;
  - a monotonic run of at least two mid-bar tempo events that settles into a tempo held through the next downbeat becomes a ramp to the settled tempo, and the downbeat readings inside it are suppressed;
  - other mid-bar tempo events are still skipped.
- `spec/support/midi_round_trip.rb` compares tempo numbers, ramps, and fermatas, but not tempo text or meter symbols, which MIDI cannot hold.

**Phase 8: Shared notation helpers** (no behavior change yet).
- `Notation::FermataMarks` collects marks with `add(voice_event, from:)` (`from` being the start of the marked tie link) and `add_moment(position, voices)` (for MEI marks anchored only by `@tstamp`). `apply(flow)` drops duplicates, forms fermatas by decision 9, and rescues `ArgumentError` per fermata, as `marking_reader.rb:70-74` does.
- `FermataMarks.carriers(flow)` maps each carrier to its fermata, through `voice.voice_event_sounding_at` (`voice.rb:24`).
- `Notation::TempoMarkReading` gives every reader one vocabulary and one rule:
  - ramp words: rit., ritard., ritardando, rall., rallentando, accel., accelerando, stringendo;
  - "a tempo" words: a tempo, tempo primo, and Tempo I, which is kept only as text;
  - `add(position, tempo_or_nil, text)` collects marks, and `apply(flow)` makes a numbered mark at a downbeat a step change (unless it restates the tempo in force), a ramp word a ramp (decision 11), and an "a tempo" word an `ATempo`; any other mark in the middle of a bar is dropped.
- `Notation::TempoMarks` gives writers the opening tempo, the step changes, the ramps, and the "a tempo" points, in time order.
- Extend `FlowTimedMarks` (`flow_timed_marks.rb:40-58`) with fermata starts and ramp ends, so the writers' preflight checks cover them.

**Phase 9: ABC.** ABC comes first among the formats because the round-trip fixtures for Phases 10–13 are written in ABC; `spec/support/timeline_expression_fixtures.rb` arrives here.
- **Reading tempo.** New `abc/tempo_field.rb` reads `1/4=120`, `3/8=60`, `"Allegro" 1/4=120` (with the text before or after the number), `"Allegro"` alone, and the legacy `Q:120` in `L:` units. `header.rb` keeps the raw `Q:` until `L:` is known. Inline `[Q:…]` and body-line `Q:` become `:tempo` tokens.
- **Writing tempo.** `Q:` before `K:`, and `[Q:…]` at each change. A `"` in the text, or a fractional tempo, raises `RenderError`.
- **Meter symbols.** The writer writes `M:C` and `M:C|`. A tune with no `M:` reads as a plain 4/4 with no symbol (`header.rb:121`).
- **Fermatas.**
  - `H`, `!fermata!`, `+fermata+`, and `!invertedfermata!` move from the dropped decorations into a `:fermata` kind (`decoration_mapper.rb:27-72`).
  - Rests keep their marks (`pending_decorations.rb:58-61`), and a later tie link passes its own start.
  - A `!fermata!` written before a barline marks the voice's last event.
  - The writer writes `!fermata!` on every carrier.
- **Ramps.**
  - Quoted annotations with a `^ _ < > @` prefix are lexed as `:annotation` tokens. Ramp and "a tempo" words go to `TempoMarkReading`, and other annotation text is dropped.
  - Chord symbols, which have no prefix, keep raising.
  - The writer writes `"^rit."` at a ramp's start and `[Q:…]` at its end, which must be an attack or a barline, else `RenderError`.

**Phase 10: kern.**
- **Fermatas.**
  - `;` (and `;y`) comes out of `IGNORED` (`token_reader.rb:48`) and becomes a `fermata` flag on the token, rests included.
  - Chord tokens combine the flag across their notes, and a later tie link carries its own mark.
  - The writer flags every carrier.
- **Meter symbols.** `*met(c)` and `*met(c|)` read and write; other mensuration signs are still ignored. `TimelineReader#change?` compares symbols, since `==` ignores them. The writer adds a `*met(...)` row after `*M`.
- **Tempo text.** `!!!OMD` gives the opening tempo its text, `*MM[Andante]` reads as a tempo with text only, and `ReferenceRecords` writes `!!!OMD:`.
- **Ramps.** None, read or written: kern has no ramp interpretation, and `bar_clock.rb:80-84` rejects a mid-bar `*MM`. The writer writes downbeat `*MM` from the authored tempo and does not raise.

**Phase 11: MEI.**
- **Fermatas.**
  - New `mei/fermata_reader.rb` reads `@fermata` through `attribute_of` (`mark_reader.rb:43-45`), and `<fermata>` by `startid` (which resolves across measures) or by `@tstamp` alone. Duplicates, such as Herzliebster's fermatas encoded both ways, collapse.
  - A new control source writes `<fermata startid staff>` on every carrier.
- **Meter symbols.** `@meter.sym` and `<meterSig @sym>` read and write.
- **Tempo text.**
  - `TempoReading` reads `<tempo>` text, including text nested in `<rend>`. A `<tempo>` with no `@mm` reads with `metronome_mark: false`, and `DownbeatTempo` stops skipping it.
  - The writer writes the text, leaves `@mm` out when the number was not written, and writes a bar-1 `<tempo>` when the opening tempo has text.
- **Ramps.** `<tempo func="continuous" tstamp tstamp2|endid>rit.</tempo>` reads and writes; the next `<tempo @mm>` is the ramp's target.

**Phase 12: LilyPond.**
- **`\tempo`.**
  - A new lexer token reads an optional string and an optional `N(.)* = M(-K)?`; a range reads as its first number. `\tempo` inside `\midi { }` is still skipped.
  - The writer writes `\tempo "Text" 4. = 60`, `\tempo 4. = 60`, or `\tempo "Text"`, in the lead voice. A fractional tempo raises `RenderError`.
- **Time signatures.**
  - A plain `\time 4/4` or `\time 2/2` reads as `:common` or `:cut`. `\numericTimeSignature` and `\defaultTimeSignature` switch the reading.
  - The writer puts `\numericTimeSignature` before a 4/4 or 2/2 with no symbol, and `\defaultTimeSignature` when a symbol returns.
- **Fermatas.** `\fermata` and its 2.26 variants become a `fermata` flag on notes, rests, and whole-bar rests, combined across tie links (`mark_reader.rb:68`). The writer writes `\fermata` on every carrier.
- **Ramps.** `^"rit."` and `^\markup {…}` with ramp words are read, and other annotation text is dropped instead of raising (`voice_item_reader.rb:38`). The writer writes `^\markup \italic "rit."` at the ramp's start (with `\after` when it falls inside a note) and the target `\tempo` at its end.

**Phase 13: MusicXML.**
- **Writing.**
  - The time `symbol` attribute (`attributes_writer.rb:108-117`).
  - New `music_xml/tempo_writer.rb`, in the first part only: `<words>` and `<metronome>` as separate direction types, then `<offset>` and `<sound tempo>`. `<sound tempo>` counts quarter notes per minute: BPM × beat fraction × 4.
  - Ramps as `<words>rit.</words>` with `<dashes>`, and `<sound tempo>` at the target.
  - `<fermata type="upright"/>` on every carrier, rests and whole-measure rests included.
- **Reading.**
  - New `music_xml/fermata_reader.rb`.
  - `@symbol` on 4/4 and 2/2.
  - `<metronome>`, preferred over `<sound tempo>`, anywhere in a bar.
  - `<words>` as tempo text (decision 10).
  - Ramps from ramp words with dashes, targeting the next `<sound tempo>`.

**Phase 14: Wrap-up.** Write the CHANGELOG, check off the story, and run `bundle exec rake validate` and `bundle exec rake oracles`.

### CHANGELOG entries

- **Added:**
  - `Tempo` text and `metronome_mark`, and `Tempo.for_text`.
  - `Meter#symbol` and `Meter.for_symbol`.
  - `Flow#add_tempo_ramp`, `#add_a_tempo`, and `#add_fermata`, with their removers and lists.
  - `Flow#sounding_tempo_at` and `Flow#conductor`.
  - The `Conductor` converts through ramps and fermatas in both directions.
  - Flow JSON keys for the above, optional within schema 5.
  - MIDI writes tempo steps through ramps and fermatas, and reads ramps and fermatas back.
  - One line per format.
- **Changed:**
  - **Breaking.** `Tempo` compares by value, and `Tempo.get` keeps its word as text.
  - **Breaking.** `Meter.get` returns a `Meter` it is given unchanged.
  - **Breaking.** A plain LilyPond `\time 4/4` or `\time 2/2` reads as common or cut time, and the writer writes `\numericTimeSignature` before a numeric one.
- **Fixed:**
  - The `Conductor`'s clock time across a meter change.
  - `Conductor#clock_to_musical` past 1000 bars.
  - `Tempo.get("Andante")` answers andante instead of ♩=120.

### Testing strategy

- **`Conductor`:**
  - a 4/4 bar ramping from 120 to 80 takes 2.432790649 s, and the inverse holds;
  - a ramp whose two ends are equal;
  - a ramp across a meter change;
  - a ramp between different beat values;
  - the chorale case: ♩=100 in 3/4, with a fermata of stretch 2 over `[2:2, 2:3)`;
  - a fermata inside a ramp;
  - a fermata on the final event lengthens the total;
  - the round-trip bounds from Phase 5.
- **Invariants:** one spec for each `ArgumentError` in decision 8, and one for each allowed case.
- **JSON:** every new key round-trips; a document without the new keys reads with empty lists and no symbols or text; a symbol that disagrees with its numerals raises and names its path.
- **Fermata marks:** `fermata_marks_spec.rb` covers a soprano quarter over a bass eighth pair, a held half note over a moving quarter, a general pause of rests, duplicate marks, fermatas that do not overlap, and carriers that began before the fermata.
- **Format round trips:** `spec/support/timeline_expression_fixtures.rb` (Phase 9) builds ABC flows with `Q:`, `M:C`, `H`, a bass eighth pair staggered under a soprano quarter, and "rit. … a tempo". Its `expect_same_timeline` ignores what a format cannot hold: the stretch everywhere except JSON and MIDI, ramps in kern, and tempo text and meter symbols in MIDI.
- **Fixtures:**
  - `satb_chorale.krn`: fermatas at 2:2 and 4:2, each a quarter.
  - `bach_invention_01.ly`: a fermata at 22:1 spanning a whole note, and meter `:common`.
  - Herzliebster: four fermatas, with positions pinned from a run.
  - Ein feste Burg: fermatas from the outer voices only, including a cross-measure `startid`.
- **Oracles:** LilyPond `compile_warnings` on every new rendering, the MusicXML XSD, the MEI schema, and Verovio.

### Risks

- **Phase order.** If kern or LilyPond fermata reading landed before Phase 7, the MIDI round trips and the kern corpus spec would break. Never commit fermata export without fermata import.
- **MIDI ramp inference** is exact for this gem's own exports and a heuristic for other files (decided; see Resolved Questions).
- **The LilyPond change touches every 4/4 rendering.** Text specs that expect a bare `\time 4/4` need updating in Phase 12.
- **Positions are fixed when an item is added.** A meter change made later before an existing ramp or fermata can leave it stale, as with spans. JSON's replay order avoids this on read, and `change_meter` re-checks the fermatas.
- **A fermata over a barline** reads as a fermata on the events that end there (see Notes).
- **The stretch survives only through JSON and MIDI;** no text format writes it.
- **`Flow#conductor` is rebuilt on every call,** so `TempoSteps` must reuse one instance. Caching clock time per piece can come later.

## Review

Reviewed 2026-10-21 at commit `7ffc32f1` (37 commits, 223 files; no uncommitted changes). Product-manager acceptance verification, plus two code reviews split between the core model (time, content, rudiment, MIDI) and the notation formats. Findings marked *verified* were reproduced independently of the reviewing agent.

Suite: `bundle exec rake`: 18,490 examples, 0 failures; line coverage 99.77%, branch 95.15%. The `rake oracles` specs were not run in this review.

### Acceptance criteria

All criteria are met. Two were met only partially, because of ABC limits that predate this story; after the review they were reworded to exclude ABC, and the work moved to [ABC Voices and Meter Changes](../backlog/abc-voices-and-meter-changes.md).

- ✅ **Tempo words (5/5).** Text through JSON; `Tempo.get` case and spelling; longest-name fallback, else ♩=120, unwritten; text distinguishes changes; each format's tempo construct, and the MusicXML `<words>` rule.
- ✅ **Gradual tempo changes (7/7).** Mid-bar ramps; whole-notes-per-minute interpolation; closed-form `atanh`/`tanh` in both directions (one 4/4 bar from 120 to 80 takes 2,432,790,649 ns); default targets; "a tempo"; overlap rules; `tempo_at` against `sounding_tempo_at`.
- ✅ **Fermatas: model (6/6).** Any position; stretch; inverse inside the span; tempo unchanged; overlap raises; JSON; mark grouping.
- ✅ **Every text format writes timeline fermatas in every voice (reworded to exclude ABC).** kern, LilyPond, MusicXML and MEI mark all carriers. ABC writes only one voice.
- ✅ **Meter symbols (3/4).** Equality and `to_s` unchanged; `Meter.get(meter)` passes the meter through; JSON and meter changes keep the symbol.
- ✅ **A symbol-only meter change is kept by every reader and writer (reworded to exclude ABC).** JSON, kern, LilyPond, MusicXML and MEI round-trip it, and each has a spec that pins it. The review first said only MEI and MusicXML did, but kern (`kern_timeline_expressions_spec.rb`, "reads back the change of sign alone"), LilyPond ("keeps a change of the symbol alone", plus the time-signature render context) and JSON (`flow_serialization_spec.rb`, "round-trips each meter change's symbol, and its absence") already pin it. ABC refuses every mid-piece meter change.
- ✅ **Conductor (2/2).** `Flow#conductor`, with clock zero at the earliest bar; 6:1 after a 3/4 change at bar 5 is 9.5 s (*verified*).
- ✅ **Formats (17/17).** ABC, LilyPond, MusicXML, kern, MEI and MIDI each check out, both in the agent's runs and in named specs. A MIDI export of a ramp and a stretch-3 fermata matches `flow.conductor` to the nanosecond.
- ✅ **Fixtures and compatibility (4/4).** `satb_chorale.krn` has fermatas at 2:2 and 4:2; Herzliebster gives 4 fermatas from 16 `<fermata>` elements and `:common`; schema-5 documents without the new keys still read; coverage holds.

### Code review findings

Ordered by severity. None of them breaks an acceptance criterion as written, but 1–5 are real misreadings that a reader would hit.

1. **"Tempo I" / "Tempo primo" is read as "a tempo" in every format** (*verified*). `notation/tempo_mark_reading.rb:17`. "a tempo" restores the tempo before the latest ramp, while "Tempo I" restores the opening tempo. In LilyPond, `\tempo "Allegro" 4=120 | \tempo "Meno mosso" 4=90 | c'1^"Tempo I" | …` gives the bars `[120, 90, 90, 90]` where the last should be 120. Fix: take these words out of `A_TEMPO_WORD`, then resolve them to the opening tempo or keep them as tempo text.
2. **MusicXML drops the metronome mark beside an "a tempo", "Tempo I" or ramp word.** `music_xml/tempo_reader.rb:18`, `tempo_direction.rb:49`. `<words>Tempo I</words><metronome>…120` reads as a bare "a tempo", so the tempo stays at 80. A step tempo with text "rit." comes back from MusicXML as ramps, while ABC, LilyPond and MEI keep it as a tempo. Fix: a direction that has a metronome mark becomes `Tempo.new(…, text:)`, the way `TempoMarkReading#add` already handles the other formats.
3. **MIDI import misreads a rit. followed directly by an accel.** (*verified*). `midi/tempo_inference.rb:55-87`. The meeting point is taken as a fermata (stretch 1.102) and both ramps are cut short, so clock time at 5:1 drifts from 10.507 s to 10.565 s. The same happens with **a fermata inside a ramp** (*verified*): the ramp splits in two, the stretch reads as 1.789 instead of 2, and the drift is +36 ms. Fix: before calling a slow-then-faster pair a fermata, check whether the slow change continues a ramp already under way, as `continues_ramp?` already does for the restore side. Add both cases to the MIDI round-trip spec.
4. **ABC moves a fermata on a tie's later link inside a bar** (*verified*). `abc/bar_writer.rb:54-58`. `C D- HD F` reads a fermata at 1:3 and writes it back at 1:2. The other four formats round-trip this case. The fixture ties across a bar line, which forces the split, so it misses the case. Fix: split the segment at the fermata (`D2-!fermata!D2`), or refuse it in `RenderPreflight`.
5. **A mid-bar `<sound tempo>` inside a dashed MusicXML ramp cuts the ramp short.** `music_xml/tempo_reader.rb:72-73` → `tempo_mark_reading.rb:71-72`. A playback-only step inside a written "rit." ends the ramp there, and its real end and target are lost. Fix: while a dashed ramp is open, skip bare `<sound>`-only moments.
6. **LilyPond markup splits hyphenated commands.** `lily_pond/lexer.rb:25`. `\with-color #red rit.` and `\center-column { "rit." }` read no ramp, and `\tempo \markup { \center-column { Allegro } }` reads its text as `"-column Allegro"`. Real files hit this; round trips don't, because the writer only uses `\italic`. Fix: match `\\([A-Za-z]+(?:-[A-Za-z]+)*)` inside markup.
7. **MIDI import adds a duplicate tempo change after a mid-bar "a tempo"** (*verified*). `midi/timeline_reader.rb:53-57`. Step changes are applied before the "a tempo" points, so a rit. from 2:2 to 3:2 followed by "a tempo" at 4:2 reads back with an extra `{5 => 90}`. Clock time is unaffected. Fix: add the "a tempo" points right after `add_ramps`, as the method's comment intends.
8. **`Flow#add_fermata("1:1", "dotted quarter")` raises `NoMethodError`** (*verified*). `content/flow.rb:149`. The span is never passed through `RhythmicValue.get`, although `voice.place` accepts the same string.
9. **A `Conductor` built directly ignores the step change at the end of a ramp with no target.** `time/tempo_pieces.rb:67`. That ramp takes 4.30 s from `Conductor.new(tempo_map:, tempo_ramps:)` and 4.77 s from `flow.conductor`. Fix: resolve the target in one place.
10. **`Tempo.get("Presto agitato")` answers 0 bpm, and `flow.conductor` then raises `ZeroDivisionError`** (*verified*). `rudiment/tempo.rb:74`: the pattern `/=|at/` matches inside "agitato". This predates the branch; format readers use `for_text` and avoid it. Fix: `/=|\bat\b/`.

Lower severity:

- MusicXML writes a ramp whose text isn't a ramp word (for example "slower"), with dashes, and reads it back as a step change. ABC and LilyPond refuse such ramps in preflight; MusicXML has no such check.
- kern writes a ramp's unwritten default target as `*MM90`, which reads back as written.
- `FermataMarks#fermatas` merges each mark only with the last span, which can chain past a mark already used in a merge. This needs an unusual three-voice layout.
- `same_tempo?` in `notation/timeline_reading.rb` compares text but not `metronome_mark?`.
- Duplicated helpers: `MusicalPosition.new(*position.to_a)` appears three times, and there are three versions of the "strictly inside" span check. `TempoPieces#advance` orders events with bare 0/1/2. Several new files carry long "what" comments, against the minimal-comments convention.
- Conventions otherwise hold: no assignments inside conditions, no stdout assertions, and specs use `described_class`.

### Resolved after review

Findings 1–8 were each reproduced, then fixed with specs (suite: 18,510 examples, 0 failures):

1. `08ff2502`: "Tempo I" at a downbeat changes to the opening tempo with its text; in the middle of a bar it still reads as "a tempo".
2. `ffda82d2`: a MusicXML `<metronome>` beside ramp, "a tempo", or "Tempo I" words makes them the text of a tempo.
3. `0ac81cb9`: MIDI import finds a ramp's turn a count after its last step, solving the turning tempo from the logarithmic means of the last two steps. A fermata inside a ramp holds the extrapolated step. Both round-trip exactly.
4. `0a0f593c`: ABC writes a fermata on a tied note's later link as `D2-!fermata!D2`.
5. `0dafa807`: a bare `<sound tempo>` inside a ramp's open dashes plays the ramp instead of ending it.
6. `f2dae8bc`: LilyPond markup lexes hyphenated commands whole, and squeezes spaces in its text.
7. `e7884c87`: MIDI "a tempo" points are applied before step changes. This corrects a spec that had pinned the duplicate change.
8. `00a791a5`: `Position#+` reads rhythmic value names with `RhythmicValue.get`.

### Blocking `finish`

Nothing. Findings 1–8 are fixed (see above). The two ABC criteria now exclude ABC, with the work in [ABC Voices and Meter Changes](../backlog/abc-voices-and-meter-changes.md). The specs for symbol-only meter changes already existed.
