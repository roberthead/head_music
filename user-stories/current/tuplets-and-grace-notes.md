<!--
metadata:
  created_at:   2026-09-25T14:05:52-07:00
  activated_at: 2026-10-14T16:39:35-07:00
  planned_at:   2026-10-14T16:55:47-07:00
  finished_at:
  updated_at:   2026-10-15T00:07:44-07:00
-->

# Story: Tuplets and Grace Notes

## Summary

AS a developer or researcher using HeadMusic

I WANT flows to hold tuplets and grace notes

SO THAT I can import the large share of real repertoire that uses them, instead of having the import refuse the whole file

## Background

Every notation format the gem reads or will read expresses tuplets and grace notes:

| Concept | ABC | LilyPond | MusicXML | kern | MEI |
|---|---|---|---|---|---|
| Tuplet | `(3CDE`, `(p:q:r` | `\tuplet 3/2 { c8 d e }`, `\times 2/3` | `<time-modification>`, `<tuplet>` | `12c 12d 12e`, `3%2c` | `<tuplet>`, `<tupletSpan>` |
| Grace note | `{g}A`, `{/g}A` | `\grace`, `\acciaccatura`, `\appoggiatura`, `\slashedGrace` | `<grace slash>` | `q`, `Q` | `@grace` |

The readers handle them badly today:

- ABC's `LineScanner` refuses tuplets and grace notes.
- LilyPond's `MusicReader` raises on `\tuplet` and the grace commands.
- kern's `DurationReader` raises `UnsupportedFeatureError` on tuplet durations. Its `TokenReader` drops grace notes and moves any slur on one to the note it leads to.

Tuplets are now the most common reason a real file fails to import.

The model has no place for either. `RhythmicValue` is a unit, dots, and a tied chain, with no tuplet ratio. A `NoteEvent` holds its sounds, markings, and syllables, but no grace notes. Positions count 960 ticks to a quarter note and 240 subticks to a tick, which is 230,400 subticks (2¹⁰·3²·5²) to a quarter. Ratios built from 2, 3, and 5, such as triplets, sextuplets, and quintuplets, land on whole subticks. Septuplets and other ratios with a prime factor above 5 do not.

This story was last of the model-gap stories. It now comes first among the format stories, as the prerequisite of [MusicXML Import](musicxml-import.md). That makes it also a prerequisite of [MIDI Export](midi-export.md), [MEI Export](mei-export.md), and [MEI Import](mei-import.md), which come after MusicXML Import and rely on it.

## Example

```ruby
triplet = HeadMusic::Rudiment::RhythmicValue.get("eighth", tuplet: "3:2")
voice.place("1:1", triplet, "C4")
voice.place("1:1:320", triplet, "D4")
voice.place("1:1:640", triplet, "E4")
voice.group_tuplet(from: "1:1", to: "1:2")

note = voice.place("1:3", :quarter, "G4")
note.add_grace_note("A4", :sixteenth, slashed: true)
```

`to:` is the group's exclusive end. These names were settled in planning.

## Acceptance Criteria

### Tuplets in the model

- [ ] A rhythmic value can carry a tuplet ratio, written as actual to normal (`3:2`, `5:4`, `6:4`, `7:4`, `2:3`, …). Its total value is its plain value times normal over actual
- [ ] `RhythmicValue#name` and `#to_s` name the ratio (for example "triplet eighth", "5:4 sixteenth"), and two values are equal only when their ratios are equal too. Only 3:2 is named "triplet"; other ratios are named by their unreduced numbers ("6:4 sixteenth", "2:3 eighth"), before any dots ("triplet dotted eighth"). `RhythmicValue.get(value.to_s) == value` for every ratio, dot count, and tied chain
- [ ] Each link of a tied chain carries its own ratio, so one chain may mix ratios ("triplet eighth tied to quarter")
- [ ] A voice holds tuplet groups, each naming a ratio, a written unit for its bracket, and the voice events it brackets. A group's events must be consecutive, carry its ratio, and fill its span exactly; `ArgumentError` names the group otherwise
- [ ] A tuplet group brackets chain links: it may begin or end partway through a chain, at a link boundary, and the links inside it carry its ratio and fill its span exactly. A group of a ratio that rounds begins and ends on voice events
- [ ] A group may mix values under one ratio, such as a quarter and an eighth under 3:2, and may hold rests and chords
- [ ] A value with a ratio but no group is allowed. Writers that need a bracket write one for each run of such values
- [ ] Ratios that land on whole subticks keep exact positions and durations
- [ ] Ratios that do not land on whole subticks, such as septuplets, are rounded. Each onset in a group falls on the subtick nearest its exact place, measured from the group's start, so the group's span stays exact and rounding never accumulates. Values with such a ratio and no group round from the start of their run of consecutive same-ratio values, as a group does from its start; a value alone rounds its duration. Every note keeps its written value and ratio, so writers write what was read
- [ ] Positions and durations are computed from exact Rational fractions and integer subticks, never Float ticks; `Position#+` carries fractional ticks into subticks
- [ ] `Voice::Continuity` and the bar-length checks accept bars filled with tuplets, rounded or not
- [ ] A tuplet note that crosses a barline is split by `BarSplitter` into tied notes of the same ratio. LilyPond, MusicXML, and kern write a group across a barline; ABC raises `RenderError` naming the group. A piece that cannot be written under its ratio raises `RenderError` naming the group
- [ ] Nested tuplets raise `ArgumentError` in the model, and `UnsupportedFeatureError` in the ABC and LilyPond readers; kern, which cannot show nesting, reads one flattened ratio

### Grace notes in the model

- [ ] A note event can carry grace notes that come before it. Each grace note has one or more sounds, pitched or unpitched, a written rhythmic value, and a slashed (acciaccatura) or unslashed (appoggiatura) flag
- [ ] A note event keeps its grace notes when another sound is merged into it
- [ ] Grace notes take no time: they do not move positions, fill bars, or count toward continuity
- [ ] Grace notes may carry articulations and ties to their main note, and a slur may begin on the first of them and end on that event or a later one. A slur that ends on a grace note ends on its main note. The kern reader then keeps a slur on its grace note rather than moving it to the main note
- [ ] A rest event refuses grace notes with `ArgumentError`, as it refuses markings
- [ ] Melodic and harmonic analysis, and every guide, ignore grace notes

### Serialization

- [ ] Flow JSON writes tuplet ratios, tuplet groups, and grace notes as optional keys within schema 5, and existing schema-5 documents read unchanged. Ratios are written inside the `rhythmic_value` name, groups as `tuplets` on a voice, grace notes as `grace_notes` on a voice event, and a slur from a grace note with `from_grace`
- [ ] A bad group, such as one whose events do not fill its span, raises naming its path, such as `parts[0].voices[0].tuplets[2]`

### Readers

- [ ] ABC reads `(3`, `(p:q:r`, and the meter-dependent default for `(n`, as tuplet groups. It reads `{…}` as grace notes before the next note, and `{/…}` as slashed ones
- [ ] LilyPond reads `\tuplet n/d { … }` as tuplet groups, including the span form `\tuplet 3/2 4 { … }`, which starts a new group each quarter, and the older `\times d/n { … }`. It reads `\grace`, `\acciaccatura`, `\appoggiatura`, and `\slashedGrace` as grace notes
- [ ] kern reads a duration whose undotted value has a non-power-of-two denominator as a tuplet value, with actual the odd factor of the denominator and normal the largest such count below it (`12` a triplet eighth, `24` a triplet sixteenth, `20` a 5:4 sixteenth, `28` a 7:4 sixteenth). It infers a group from the first run of at least two consecutive values of one ratio whose exact length is a plain note value; runs that never fill stay ungrouped. Duplets read as dotted values. It reads `q` as slashed grace notes, and `Q` or `qq` as unslashed ones
- [ ] LilyPond `\afterGrace` is skipped, as the model holds grace notes only before a note. Every reader skips grace notes before a rest, before a tie's later link, and at the end of a voice. Readers keep a grace note's articulations, tie, and slur start; a level on one reads at its main note; its ornaments and accents are dropped
- [ ] Every file that imports today still imports. New committed fixtures with tuplets and grace notes import in ABC, LilyPond, and kern, and the music21 kern corpus files that refused tuplets or grace rows now read past them. The Chopin mazurka and the three Palestrina files import; the four Beethoven Op. 18 No. 1 movements stop later, on problems this story does not touch (reworded 2026-10-15, see Notes)

### Writers

- [ ] ABC writes `(p:q:r` groups, or the short `(3` form where it means the same thing, and `{…}` and `{/…}` grace notes
- [ ] LilyPond writes `\tuplet n/d { … }` groups, and `\acciaccatura` or `\appoggiatura` for grace notes slurred to their main note, and `\slashedGrace` or `\grace` otherwise
- [ ] kern writes tuplet values as reciprocals (`12`, `12.`), a value whose length is a plain or dotted note as that note (duplets as `8.`), and `%` otherwise, and grace notes as `q` and `Q` tokens on rows of their own
- [ ] MusicXML writes `<time-modification>` on every tuplet note, `<tuplet type="start">` and `<tuplet type="stop">` on each group's ends, and `<grace>` with `slash="yes"` for acciaccaturas. `<divisions>` are computed from written values and ratios, so they are exact for septuplets too
- [ ] A written duration for a tuplet value comes from its value and ratio, never from its rounded ticks. `DottedDuration` answers a value's written fraction and its sounding fraction separately: ABC lengths, LilyPond tokens, and MusicXML `<type>` use the written one; kern reciprocals and MusicXML `<duration>` and `<divisions>` the sounding one
- [ ] A timed mark at a tuplet onset is written at its exact onset; a mark strictly inside a note of a rounding ratio, where no note starts, raises `RenderError` naming it

### Tests

- [ ] ABC, LilyPond, and kern round-trip the fixtures and 100 seeds each; ABC merges voices into one and leaves out barline-crossing groups; kern compares sounding onsets and lengths, its canonical ratios, and the groups its inference recovers. MusicXML is checked by summaries of `<time-modification>`, `<tuplet>`, `<grace>`, and `<divisions>`
- [ ] Each format round-trips a flow with triplets, a sextuplet, a quintuplet, a septuplet, a group mixing values, a tuplet note crossing a barline (in the formats that allow it), and grace notes of both kinds before a downbeat
- [ ] A seeded random generator in `spec/support` round-trips 100 seeds per format, naming the seed on failure
- [ ] Every LilyPond output compiles under lilypond 2.26 without warnings
- [ ] Maintains 90%+ test coverage

## Notes

- **Build order.** This follows the shape that worked for Place Dynamics Where No Note Starts and Hairpins. First a shared base on the story branch: the model, JSON, `BarSplitter`, duration-writer rules, fixtures, and the seeded generator. Then one worktree per format, built from that base commit.
- MusicXML reading belongs to [MusicXML Import](musicxml-import.md), and MEI to its two stories. Each takes this model as given.
- [MIDI Export](midi-export.md) sounds grace notes by taking time from the note they precede, and its tick resolution allows for tuplets.
- **Follow-up: nested tuplets.** They are rare outside twentieth-century repertoire, and holding them would mean groups within groups in every bracket writer. They raise because skipping one would leave its bar short.
- **Follow-up: grace notes after a note.** LilyPond's `\afterGrace` and trill terminations would need grace notes held after a note. They are skipped until a caller needs them.
- **The Beethoven movements stop on other problems** (found 2026-10-15). With tuplets and grace rows read, `movement1.krn` ties A♭ to A♮ (line 290) and `movement4.krn` leaves `[4F` unclosed (line 257), both errors in the files. `movement2.krn` changes clef mid-bar (line 1486) and `movement3.krn` ties a chord only in part (line 452). Both of those are valid kern the model cannot hold, so under the skip policy they are candidates for a reader follow-up rather than this story.
- **Follow-up: voice directions in LilyPond output.** The writer never sets `\voiceOne` or `\voiceTwo`, so two voices on one staff whose notes collide warn "this Voice needs a \voiceXx or \shiftXx setting". The Chopin mazurka shows it at a tuplet, but the cause predates tuplets.
- **Follow-up: grace notes in analysis.** No guide needs them. A later story could teach melodic guidelines about ornamental grace notes, and add an option to include them then.

## Decisions

- **A tuplet is a ratio on each value, plus a group on the voice** (decided 2026-10-14). The ratio keeps durations and positions simple arithmetic. The group says which events one bracket holds, which the bracket formats need, and which tells two triplets from one sextuplet. kern, which writes no brackets, has its groups inferred on reading.
- **Ratios that do not divide the subtick grid are rounded to the nearest subtick** (decided 2026-10-14). This reverses the earlier plan to raise `ArgumentError`. Each onset rounds from its group's start, so the group stays exact, and the written value and ratio are kept for writers.
- **Analysis ignores grace notes, with no option yet** (decided 2026-10-14). No caller needs one, and an option with no caller is guesswork about its shape.
- **The format work stays in this story** (decided 2026-10-14). The earlier note offered to split the formats out, but MusicXML Import needs the MusicXML writer's half, and every reader that refuses tuplets today is the problem this story solves.
- **This story is the prerequisite of MusicXML Import** (decided 2026-10-14), so it moves to the front of the format work.
- **Planning clarifications adopted** (2026-10-14, while running the seven-story goal without stopping to ask). The planner's proposed criteria changes were all adopted, since each sharpens a decision above rather than reversing one: groups bracket chain links, exact Rational time, run-based rounding for ungrouped values, ratio naming, kern's ratio mapping and inference, and per-format barline rules. Three open choices kept the story's existing wording: JSON stays schema 5, a mark strictly inside a rounded note raises rather than snapping, and abcm2ps is not installed, so ABC rendering is checked by reading the output only.

## Implementation Plan

### Overview

A tuplet becomes two things. Each rhythmic-value link carries an unreduced `TupletRatio`, and the voice holds `TupletGroup`s, each a half-open position range that brackets links. Time arithmetic moves from Float ticks to exact Rational fractions with integer subticks. Ratios that do not divide the grid (septuplets) round each onset from the start of its group or run, so spans stay exact.

Grace notes are frozen `GraceNote` values on a `NoteEvent`. They are never voice events, so analysis ignores them with no change to `lib/head_music/style` or `lib/head_music/analysis`. A slur that begins on one is a `Span` with `from_grace: true`.

The work follows the Hairpins shape. A shared base lands first on `story/tuplets-and-grace-notes`: model, exact arithmetic, JSON, `BarSplitter`/`DottedDuration`, a shared `TupletBrackets`, preflight, fixtures and a seeded generator. Then five worktrees run in parallel by format, and coordinator steps follow.

Specialists consulted: product-manager, three developers (shared model; ABC and LilyPond; kern and MusicXML) and best-practices-engineer (type design and exact arithmetic). ui-ux-designer and accessibility-specialist were skipped because the story has no user interface.

All paths are relative to `/Users/roberthead/github.com/roberthead/head_music`.

### Problems found in today's code (each verified by running Ruby)

- **Tuplet names already parse, wrongly.** `RhythmicValue.get("triplet eighth")` returns a plain eighth. `Parser::PATTERN` (`lib/head_music/rudiment/rhythmic_value/parser.rb:7`) matches the bare unit, and `dots_from_words` matches "triplet" as triple-dotted.
- **`Position#+` drops anything below a tick.** It adds Float ticks (`lib/head_music/content/position.rb:94`), and `value_for` truncates them with `.to_i`:
  - a dotted 256th ends at `1:1:022` instead of `1:1:022:120`;
  - a 9:8 eighth loses 160 subticks;
  - Float math alone gives a 9:8 eighth 102,399.99 subticks.
- **`BarSplitter.offset_in_bar` ignores subticks** (`lib/head_music/notation/bar_splitter.rb:54`). It has about 14 callers across the formats.
- **`RhythmicValue` defines `==` but not `eql?` or `hash`.** So `uniq` and `tally` treat equal values as different, and `NotesSameLength#occurrences_by_rhythmic_value` (`lib/head_music/style/guidelines/notes_same_length.rb:55`) counts by object identity.
- **The kern reader raises on real grace rows.** A row holding only grace tokens, with a null token in a spine whose note just ended, raises "A null token … falls where no note is sounding" (`lib/head_music/notation/kern/spine_voices.rb`). Three music21 corpus files hit this.

### Model decisions

- **`HeadMusic::Rudiment::TupletRatio`** (new, `lib/head_music/rudiment/tuplet_ratio.rb`):
  - A frozen value with `.get("3:2" | [3, 2] | ratio)`, memoized, nil for garbage.
  - Holds `actual` and `normal`, never reduced, so 6:4 is not 3:2. `factor` is `Rational(normal, actual)`.
  - `1:1` and non-positive numbers raise `ArgumentError`. There is no silent fallback the way bad dots have one.
  - `name` is "triplet" for 3:2 only and the numbers otherwise ("5:4", "6:4", "2:3"), since "quintuplet" and "duplet" are ambiguous across ratios.
  - `==`, `eql?` and `hash` compare `[actual, normal]`.
- **`RhythmicValue`:**
  - Signatures: `get(identifier, tuplet: nil)` and `new(unit, dots:, tied_value:, tuplet:)`. With `tuplet:`, `get` puts the ratio on every link of the chain.
  - Each link keeps its own ratio, so one chain may mix ratios ("triplet eighth tied to quarter").
  - New readers: `tuplet_ratio`, `tuplet?`, and `uniform_tuplet_ratio` (nil when the links differ).
  - New exact values:
    - `fraction`: an exact Rational of a whole note covering dots, ratio and the whole chain. `DottedDuration.dotted_unit_fraction`'s arithmetic moves here.
    - `exact_subticks`: `fraction * 921_600`.
    - `subticks`: `exact_subticks.round`, rounding half up (`Rational#round`), taken once over the chain.
  - `relative_value`, `total_value` and `ticks` become `fraction`-based values `.to_f`. They stay Floats, bit-identical for binary values, because guidelines compare them with Float constants and `{0.25 => x}[1/4r]` is nil.
  - Names put the ratio first on each link: "triplet eighth", "5:4 sixteenth", "triplet dotted quarter", "triplet quarter tied to triplet eighth".
  - `get` strips a leading `triplet` or `\d+:\d+` word from each tied head before the existing parsers run. A head with a ratio word that does not then parse returns nil. `get(v.to_s) == v` holds for every ratio × dots × chain.
  - `append_tied`, `from_tied_words`, the `Parser.from_*` builders and `DottedDuration.single_value` all carry the ratio.
  - `eql?` and `hash` are based on `to_s`. `<=>` still compares `total_value`, so a triplet sixteenth and a 6:4 sixteenth compare as 0 while `==` is false, as "dotted quarter" and "quarter tied to eighth" already do.
- **`Rhythm::SUBTICKS_PER_TICK = 240`**, with `HeadMusic::Time::SUBTICKS_PER_TICK` aliased to it the way `PPQN` is. Rudiment loads before Time. A whole note is 921,600 subticks.
- **Positions:**
  - `Position#+` adds `other.subticks` into `subtick`.
  - New `Position#advance(subticks:)`.
  - `BarSplitter.offset_in_bar` adds `Rational(subtick, ticks_per_count * 240)`.
- **Rounding (the run rule):**
  - `VoiceEvent#onset_remainder` is the exact onset minus `position`, as a Rational number of subticks. It is non-zero only when:
    - the event just before ends here,
    - and the adjacent links share a ratio.
  - Tuplet groups do not break a run (revised 2026-10-15). A group that starts where a run starts has every onset measured from its start, as before; a group inside a longer run keeps the run's exact onsets, so back-to-back partial brackets such as 3 + 7 + 4 septuplet sixteenths stay exact. Grouping then moves no onset, so `group_tuplet` leaves memoized timing in place. A value alone is a run of one.
  - `next_position` = `position.advance(subticks: (onset_remainder + rhythmic_value.exact_subticks).round)`. Continuity's `previous.next_position == current.position` then holds with no change to `voice/continuity.rb`.
  - Readers already place each note at `voice.next_position`, so they land on the rule with no reader-side rounding. This also makes the story's place-then-group example work.
  - Ratios built from 2, 3 and 5 always have whole `exact_subticks`, so they never round.
- **Septuplet example** (7:4 sixteenths from 1:1):
  - Onsets: `1:1:000`, `1:1:137:034`, `1:1:274:069`, `1:1:411:103`, `1:1:548:137`, `1:1:685:171`, `1:1:822:206`. The group ends exactly at `1:2:000`.
  - Durations: 32914, 32915, 32914, 32914, 32914, 32915, 32914, which sum to 230,400. Rounding each value alone would give 230,398.
  - Remainders: 0, +2/7, −3/7, −1/7, +1/7, +3/7, −2/7.
- **Memoizing `next_position`:** it is memoized behind a voice revision counter that `place` bumps when it inserts before the last event. This replaces the current permanent `||=`, which goes stale when grouping changes a run.
- **`HeadMusic::Content::TupletGroup`** (new, `lib/head_music/content/tuplet_group.rb`):
  - A frozen value holding `voice`, `from`, `to` (an exclusive end, half-open like hairpins) and `unit`. `ratio` is derived from its links.
  - The group holds positions, not event objects, because `RestEvent#merge` returns a new object.
  - `to_s` reads like "3:2 tuplet from 1:1 to 1:2"; `to_h` gives `{"from", "to", "unit"}`. Ordering mirrors `Span#<=>`.
- **`Voice#group_tuplet(from:, to:, unit: nil)` returns the group.** It raises `ArgumentError` naming the group unless:
  - `from < to`;
  - `from` and `to` fall on link boundaries (exact link onsets);
  - every link in the range carries one ratio;
  - the links' exact sum equals `to − from`.

  Two more rules:
  - **Rounded-ratio boundaries:** for a ratio that rounds, the group's boundaries must be event boundaries, which keeps the run rule simple.
  - **Default unit:** the written total ÷ actual when that is one plain or dotted value; otherwise the GCD of the links' written fractions. So quarter + eighth under 3:2 gives eighth, and six sixteenths under 6:4 give sixteenth.

  One group may hold more than one tuplet's worth: `\tuplet 3/2 { six eighths }` is one bracket, as LilyPond draws it. Overlapping another group raises "nested tuplets are not supported: the … overlaps the …".
- **Other `Voice` methods:**
  - `tuplets` (sorted) and `tuplet_at(position)`, found by binary search, never a linear scan as in `Spans#covering`.
  - `Voice#place` raises, naming the group, when a new (not merged) event's position falls inside a group. A merge at an event start is safe, because `ensure_same_rhythmic_value!` already compares ratios.
- **Groups across a barline stay one group in the model.** `BarSplitter` splits events, and `TupletBrackets` maps groups onto segments.
- **`HeadMusic::Content::GraceNote`** (new, `lib/head_music/content/grace_note.rb`):
  - A `Data` holding `sounds` (one or more, pitched or unpitched, through `SoundResolver`), `rhythmic_value` (a single link with no tie and no ratio), `slashed`, `tied` (to whatever follows) and `articulations` (frozen, sorted).
  - It has no position.
- **Grace notes on events:**
  - `NoteEvent#add_grace_note(sound_or_sounds, rhythmic_value, slashed: false, tied: false, articulations: [])` appends and returns `self`.
  - `VoiceEvent#grace_notes` returns `[]`.
  - `RestEvent#add_grace_note` raises "a rest cannot carry grace notes; the grace note at … needs a note".
  - `NoteEvent#merge` keeps the receiver's grace notes, as it keeps its markings.
- **Slur from a grace note:**
  - `Span.new(…, from_grace: false)` and `Voice#add_span(kind, from:, to:, from_grace: false)`. `from_grace` starts the span on the first grace note of the note event at `from`, and allows `from == to` (the usual slur from a grace note to its own main note).
  - It requires a `curve?` kind and grace notes at `from`. `Part#add_span` refuses it.
  - The sort key becomes `[from, from_grace ? 0 : 1, to, kind_index]`, which leaves existing order unchanged.
  - A slur ending on a grace note ends on its main note.
  - The product manager proposed a "slurred to main" flag on the grace notes instead, deferring slurs to later notes. That would not meet "a slur may begin on the first of them" or the kern criterion, which is why the span flag was chosen.
- **JSON (schema stays 5):**
  - The ratio travels inside the existing `"rhythmic_value"` string. A separate key could not express a chain of mixed ratios.
  - A voice gains `"tuplets": [{"from", "to", "unit"}]`.
  - An event gains `"grace_notes": [{"sounds", "rhythmic_value", "slashed"?, "tied"?, "articulations"?}]`.
  - A span gains `"from_grace"?`.
  - Path errors come from `each_placed`, for example `parts[0].voices[0].tuplets[2]: the 3:2 tuplet … must fill …`.
- **Written vs. sounding duration:**
  - `DottedDuration.dotted_unit_fraction` stays the written length, used for ABC lengths, LilyPond tokens and MusicXML `<type>`.
  - New `DottedDuration.sounding_fraction(link)` is the written length × factor, used for kern reciprocals, MusicXML `<duration>`/`<divisions>`/`<backup>` and LilyPond bar sums.
  - `rhythmic_value_for(fraction, tuplet: nil)` divides by the factor, builds the binary value, then puts the ratio back on every link. It is nil when no binary value fits.
  - The kern developer suggested folding the ratio into `dotted_unit_fraction` so that kern and MusicXML need no further change. That was rejected because it would quietly break ABC and LilyPond written tokens; each writer switches explicitly instead.
- **Exact onsets for writers:** new `BarSplitter.onset_in_bar(voice_event)` = `offset_in_bar(position) + onset_remainder / 921_600`. Every writer locates notes and marks with it, never with a rounded position.
- **Marks inside rounded notes:** a timed mark (dynamic, hairpin end, `\after`) strictly inside a rounded-ratio note, where no note starts, is refused in preflight with `RenderError` naming the mark. Writing it would mean a subtick-denominator offset: kern would write millions of null rows, and MusicXML divisions would reach about 7 × 921,600. Snapping it to the nearest onset is the alternative (see Open Questions). Marks at a tuplet onset are written at its exact onset.

### Reader rules

- **ABC:**
  - `(p:q:r` becomes a `:tuplet` token, and `/\(\d/` leaves `UNSUPPORTED_PATTERNS`. r defaults to p. q follows the ABC 2.1 table: 2→3, 3→2, 4→3, 6→2, 8→3; for 5, 7 and 9 it is 3 in a compound header meter (`Meter#compound?`) and 2 otherwise. A p outside 2–9 with no q is a `ParseError`.
  - Counted toward r: each note, chord (once), `z` and `x`. Not counted: graces, decorations, `y`, ties, slurs, bar lines.
  - Broken rhythm scales the written value, and the ratio is kept separately.
  - The count continues across a bar line.
  - A `(p` while notes are still owed raises `UnsupportedFeatureError` ("nested tuplets"). A voice change or the end of the tune with notes owed drops the incomplete group but keeps the ratios.
  - `{…}` and `{/…}` are read by a new `GraceScanner`. Grace lengths are relative to `L:`. Articulations are kept; other decorations are dropped.
  - Grace notes wait for the next note or chord, and are dropped at a rest, bar line, voice change, end of tune, or inside an open tie.
  - `(` before `{` starts the slur on the first grace note.
  - Groups are added in `Parser#finish`, as hairpins are.
- **LilyPond:**
  - Recognized forms: `\tuplet n/d [dur] { … }` or a single item, `\times d/n`, and `\tupletSpan dur` / `\default`.
  - The span form starts a new group every `dur` of sounding time from the group's start, and a remainder becomes its own short group. This was verified in 2.26.
  - Inside a bracket, values carry the ratio, and spacer and `\after` offsets are written time, scaled by normal/actual. Verified: `\after 8` inside 3/2 lands at 1/12.
  - The carried duration stays written and global: `\tuplet 3/2 { c8 d e } f` gives a plain eighth `f`.
  - `R` or `<< >>` inside a tuplet, a tuplet inside a tuplet, and a tuplet inside grace music raise `UnsupportedFeatureError`.
  - Grace commands:

    | Command | Slashed | Slur from grace to main note |
    |---|---|---|
    | `\grace` | no | no |
    | `\slashedGrace` | yes | no |
    | `\appoggiatura` | no | yes, implied |
    | `\acciaccatura` | yes | yes, implied |

    An explicit `(` on the first grace replaces the implied slur.
  - Grace durations and `\relative` pitches always go through the normal readers, even for grace notes that are then dropped. They carry the duration on: `c'4 \grace d'16 c'` makes the second `c'` a sixteenth.
  - `\afterGrace [frac] main { … }` reads `main` and discards its grace notes, as do grace notes before a rest, spacer, `R`, tied later link, or end of stream.
  - On a grace note, articulations, a same-pitch `~`, and the slur start are kept. A level or hairpin mark lands at the main note. Ornaments and accents are dropped.
  - Each `\tuplet` gives a `group_tuplet` call in `EventPlacer#finish`, rescuing `ArgumentError`.
- **kern:**
  - `N` is 1/N of a whole note and `N%M` is M/N. The ratio is worked out from the undotted value p/q with q = 2^k·m, m odd:
    - m = 1 is plain, as today (`2%3` is a dotted whole, `8%5` a half tied to an eighth).
    - Otherwise actual is m, normal is the largest p_odd·2^j below m, and the written unit is p/q·actual/normal.
    - Examples: `3` is a 3:2 half, `6` a 3:2 quarter, `12` a 3:2 eighth, `24` a 3:2 sixteenth (not 6:4), `20` a 5:4 sixteenth, `28` a 7:4 sixteenth, `112` a 7:4 64th, `9` a 9:8 eighth, `3%2` a 3:2 whole, `10%3` a 5:3 half, `12.` a dotted 3:2 eighth.
    - A unit outside maxima to 256th raises `UnsupportedFeatureError`.
  - Nested ratios cannot be seen in kern and read as one flattened ratio. Duplets (2:3) read as dotted values.
  - **Group inference** (new `kern/tuplet_groups.rb`, run in `Layer#place` after ties merge, on exact Rationals):
    - Start at an event whose links all share ratio R.
    - Gather consecutive events of exactly R; rests and uniform tied chains count (`[3g 3g]`).
    - Close at the first point with at least two events whose exact sum is an undotted binary value. For example, `12. 24 12` closes at 1/4.
    - Barlines do not end a group: split pieces come back as same-ratio chains.
    - A run that never fills stays ungrouped.
    - Known losses: a sextuplet comes back as two triplets, and 6:4 as 3:2.
  - **Grace notes:**
    - `q` is slashed. `Q` and `qq` are unslashed.
    - The written value is the reciprocal, or an eighth when none is given (`aaq/`). A grace chord on one row is one grace note with several pitches.
    - `VoiceCursor` queues grace notes for the track's next attack, and drops them before a rest, at a spine end, or at a join.
    - An opening slur on the first grace note stays there as `from_grace`. Other slur marks on grace notes move to the main note.
    - `8qc[` ties to a main note of the same pitch.
    - A row holding only grace tokens skips the null-token check. This is the bug fix noted above.

### Steps

Each step is one commit. Run the touched specs, then `bundle exec rake` and `bundle exec rubocop -a`. Run each new spec against the old code by copying files aside, never by stashing. Do not assert console output.

#### Shared base (sequential, on `story/tuplets-and-grace-notes`)

1. **Value equality for rhythmic values.**
   - `RhythmicValue#eql?` and `#hash` based on `to_s`.
   - Specs: `uniq` and `tally` in `spec/head_music/rudiment/rhythmic_value_spec.rb`, and a `NotesSameLength` spec showing the most common value is now found.
   - Check `spec/fixtures/style/corpus_fitness.json` for changed marks. CHANGELOG: Fixed.
   - Files: `lib/head_music/rudiment/rhythmic_value.rb`, `lib/head_music/style/guidelines/notes_same_length.rb` (spec only, unless it needs touching).
2. **`TupletRatio`, ratios on `RhythmicValue`, exact fractions.**
   - The new class is required before `rhythmic_value` in `lib/head_music.rb`. Add `Rhythm::SUBTICKS_PER_TICK`, then the names, parsing, `fraction`, `exact_subticks` and `subticks` described above.
   - Specs: new `spec/head_music/rudiment/tuplet_ratio_spec.rb`, plus a `get`/`to_s` round trip over ratio × dots × chain. Pin that "triplet dotted eighth" is not triple-dotted, that `exact_subticks` is whole for 3:2, 5:4, 6:4, 2:3 and 9:8 (102,400) and 230400/7 for a 7:4 sixteenth, and that `<=>` is 0 while `==` is false for 3:2 vs 6:4 sixteenths.
   - Files: `lib/head_music/rudiment/{tuplet_ratio,rhythmic_value,rhythm}.rb`, `rhythmic_value/parser.rb`, `lib/head_music/time.rb`.
3. **Exact subtick arithmetic.**
   - `Position#+` via subticks, `Position#advance`, and subticks in `BarSplitter.offset_in_bar`.
   - Specs: `position_spec.rb` (dotted 256th ends at `1:1:022:120`; the carry in 6/8), `bar_splitter_spec.rb`. CHANGELOG: Fixed.
   - Files: `lib/head_music/content/position.rb`, `lib/head_music/notation/bar_splitter.rb`.
4. **The run rule.**
   - `VoiceEvent#onset_remainder`, the new `next_position` with revision-based memoizing, and `VoiceEvents#preceding` delegated as `voice_event_preceding`.
   - Specs: the septuplet table, a lone 7:4, and an ungrouped run in `voice_event_spec.rb`; no gap in a septuplet bar in `voice/continuity_spec.rb`.
   - Files: `lib/head_music/content/{voice_event,voice_events,voice}.rb`.
5. **`TupletGroup` and `Voice#group_tuplet`.**
   - Link-boundary validation, the default unit, refusing a placement inside a group, `tuplets` in `Voice#to_h`, and the group reset in the run rule.
   - Specs: new `tuplet_group_spec.rb` and `voice_tuplets_spec.rb` covering:
     - the corrected story example;
     - quarter + eighth under 3:2;
     - a rest and a chord in a group;
     - a group ending on the first link of `triplet eighth tied to quarter`;
     - each validation message;
     - nested and overlapping groups;
     - placement inside a group;
     - a rest-to-note merge inside a group keeping `first_gap` nil.
   - Pause here so Rob can check the model API.
6. **Grace notes and slurs from them.**
   - Files: `lib/head_music/content/{grace_note,note_event,rest_event,voice_event,span,voice,part}.rb`.
   - Specs: new `grace_note_spec.rb`, plus `note_event_spec.rb`, `rest_event_spec.rb`, `voice_spans_spec.rb` (`from_grace` with `from == to`; refused for a hairpin or a note without grace notes).
   - Analysis guard: grace notes of both kinds, a tied one, an articulated one and a grace slur in the marked copy in `spec/head_music/style/guide_marked_flow_grading_spec.rb`. Also a `voice_spec.rb` example showing `notes`, `melodic_line` and `voice_events` unchanged.
7. **Flow JSON.**
   - `grace_notes(values, path)` in `lib/head_music/content/flow/voice_event_values.rb`.
   - `tuplets(values, path)` and `from_grace` in `schema_values.rb`.
   - Grace notes applied in `deserializer.rb#build_voice_events` (a rest with grace notes raises with its path).
   - `add_tuplets` in `hash_deserializer.rb` after `build_voice_events`.
   - Spec `flow_serialization_spec.rb`: round trips, old documents reading unchanged, path errors (`parts[0].voices[0].tuplets[2]`, `…voice_events[3].grace_notes[1]`), and an unknown ratio name failing as "unknown rhythmic value".
8. **`DottedDuration` and `BarSplitter` for tuplets.**
   - `sounding_fraction`, and the `tuplet:` option on `rhythmic_value_for`.
   - `BarSplitter.onset_in_bar`; `segments_of` cuts at exact onsets and lengths.
   - `Segment#rhythmic_value` passes the uniform ratio; a piece that cannot be written under it makes `rhythmic_value!` raise `RenderError` naming the group.
   - Specs:
     - 3:2 quarters from beat 4 split the middle note into a triplet eighth tied to a triplet eighth;
     - 7:4 eighths from beat 4 split exactly despite rounded positions;
     - a 2:3 duplet crossing a barline in 6/8 raises.
   - Files: `lib/head_music/notation/{dotted_duration,bar_splitter}.rb`.
9. **`TupletBrackets` and preflight.**
   - New `lib/head_music/notation/tuplet_brackets.rb`: `TupletBrackets.for(voice)` returns `Bracket = Data.define(:ratio, :unit, :links, :group)` at link level over `RenderPlan` segments. Each run of ungrouped same-ratio links closes when its written total reaches actual × its shortest unit; any leftover forms its own bracket. Also `#crosses_barline?` and `#label`.
   - `lib/head_music/notation/preflight_checks.rb` gains `ensure_tuplets_within_bars(flow)` (ABC calls it) and `ensure_no_marks_inside_rounded_notes(flow)` (all writers).
   - Specs: new `tuplet_brackets_spec.rb`, and a four-format table in `preflight_checks_spec.rb`.
10. **Fixtures, expectations and generator (specs only).**
    - `spec/support/tuplet_fixtures.rb` (`TupletFixtures.all`), built with `voice.place` at `voice.next_position`. `ABC.parse` cannot be used yet, because the ABC reader cannot read these until its worktree lands. Fixtures:
      - `triplets` (eighths plus a quarter triplet over a half), `sextuplet` (6:4), `quintuplet` (5:4), `septuplet` (7:4);
      - `mixed_value_tuplet` (quarter + eighth, a rest, a chord), `duplet_in_six_eight`, `ungrouped_tuplet_run`, `triplet_tied_out` (group ending inside a chain);
      - `tuplet_crossing_barline`, `septuplet_crossing_barline`, `tuplets_in_two_voices`;
      - `grace_notes_before_downbeat` (slashed single; unslashed pair tied in with a `from_grace` slur; grace chord; articulated grace), and `grace_notes_in_pickup`.
    - `TupletExpectations` helpers:
      - `tuplet_summary` (`[from, to, ratio, unit]`) and `bracket_summary` (via `TupletBrackets`, so ungrouped runs and groups compare alike);
      - `grace_summary`, and `sounding_summary` (`[exact onset, fraction, sounds]`, for kern);
      - `expect_same_tuplets(original, round_tripped, bracketed: false)` and `expect_same_grace_notes`;
      - `span_summary` in `marking_fixtures.rb` extended with `from_grace`.
    - `spec/support/tuplet_generator.rb` with `SEEDS` from `ENV.fetch("TUPLET_SEEDS", "1..100")`. Signature: `TupletGenerator.flow(seed, voices: 2, cross_barlines: true, ratios: %w[3:2 6:4 5:4 7:4], meters: %w[4/4 6/8], ungrouped: true, graces: true, pickup: true)`.
      - About 20% rests, plus chords.
      - Groups sometimes start on the last beat.
      - Grace notes before about 20% of notes, sometimes with a grace slur.
    - A self-spec checks every seed and fixture: no gap, groups valid, and the JSON round trip gives equal `to_h`. Examples are named "… seed N". Run `TUPLET_SEEDS=1..2000` once before handing off.

#### Parallel worktrees, all from the commit after step 10 (name the hash; worktree agents branch from `main`)

CHANGELOG lines stay in the commit bodies until step 31.

| Worktree | Steps | Files owned |
|---|---|---|
| ABC | 11–14 | `lib/head_music/notation/abc/*`, `spec/head_music/notation/abc/*`, `spec/support/abc_round_trip.rb`, `abc_round_trip_spec.rb` |
| LilyPond reader | 15–16 | `lily_pond/{lexer,token,music_reader,music_item_reader,voice_stream,event_placer,duration_reader,mark_reader}.rb`, new `tuplet_reader.rb` and `grace_reader.rb`, their specs, new `spec/fixtures/notation/lily_pond/tuplets_and_grace_notes.ly` |
| LilyPond writer | 17–18 | `lily_pond/{render_plan,voice_writer,timed_marks,preflight,mark_writer}.rb`, new `grace_writer.rb`, `spec/support/lily_pond_helpers.rb`, `writer_spec.rb`, `render_plan_spec.rb`, `timed_marks_spec.rb` |
| kern | 19–24 | `lib/head_music/notation/kern/*`, `spec/head_music/notation/kern/*`, `spec/support/kern_round_trip.rb`, new `spec/fixtures/notation/kern/{tuplets,grace_notes}.krn` |
| MusicXML | 25–28 | `lib/head_music/notation/music_xml/*`, `spec/head_music/notation/music_xml/*`, `spec/support/music_xml_helpers.rb` |

11. **ABC reader, tuplets.**
    - New `abc/tuplet_marker.rb`: a Data holding actual, normal and count, plus the default-q table.
    - `token.rb` gains a `tuplet` field; `line_scanner.rb` gets `scan_tuplet`.
    - `parser.rb` gets `handle_tuplet`, and `tuplet` joins `OVERLAY_MUSIC`.
    - `voice_state.rb`: `PendingNote#ratio`, an open-tuplet record, and `add_tuplets` in `finish`.
    - `duration_resolver.rb`: `rhythmic_value(…, tuplet:)`.
    - Flip `body_lexer_spec.rb:477` and `parser_spec.rb:672`. New `tuplet_marker_spec.rb`, and `(5` read in both 4/4 and 6/8.
12. **ABC reader, grace notes.**
    - New `abc/grace_scanner.rb`. The two `{` patterns leave `UNSUPPORTED_PATTERNS`.
    - `handle_grace` in `parser.rb`; pending grace notes, the drop rules and the grace slur in `voice_state.rb`.
    - Flip `preflight_spec.rb:48` and `parser_spec.rb:671,691,696`.
13. **ABC writer, tuplets.**
    - New `abc/tuplet_writer.rb`: r is the number of tokens in the bracket. The short `(3` and `(2` are used only when q matches the table and r == p; `(p:q:r` otherwise. `(6` is not 6:4 under 2.1. One bracket per ungrouped run.
    - `duration_writer.rb` writes the written multiplier, and collapses a chain only within one ratio; a mixed chain is written link by link with `-`.
    - `bar_writer.rb` gets the prefixes.
    - `writer.rb#validate!` calls `ensure_tuplets_within_bars`, so a group crossing a barline raises "ABC cannot write the 3:2 tuplet at 1:2 across the barline into bar 2" before assembly.
14. **ABC writer, grace notes, and round trips.**
    - Order: `(3`, then the slur `(` (before `{` only for a grace slur), then `{/g}`, decorations, the note. Grace notes go on a note's first segment only.
    - Round trips over the fixtures, with the barline-crossing ones expecting `RenderError` and voices merged into one.
    - Generator: `voices: 1, pickup: false, cross_barlines: false`, one meter. Plus a render-parse-render stability check.
15. **LilyPond reader, tuplets.**
    - The `:tuplet` token and `\tupletSpan`.
    - `music_reader.rb#read_item_command` reads the body.
    - `voice_stream.rb`: open ratio and span, wrapping values, scaling spacers and `\after`.
    - `event_placer.rb`: groups cut at the span, `finish`; subtick fixes in `bar_start?` (285), `elapsed_fraction` (293) and `shifted` (128).
    - Flip `document_reader_spec.rb:361` and `parser_spec.rb:171`.
16. **LilyPond reader, grace notes.**
    - New `grace_reader.rb`, using `MusicItemReader`'s pitch and duration readers and `MarkReader`.
    - `VoiceStream#add_graces` and the drop rules; `Event` gains `graces:`; `EventPlacer#place_note` adds the grace notes and the grace slur. `\afterGrace` is discarded.
    - The hand-written `.ly` fixture covers `\times`, the span form with a remainder, `\tupletSpan`, `\tuplet 3/2 c'4`, every grace command, `\afterGrace 7/8`, a grace before a rest, grace notes in `\relative`, a grace inside a tuplet, and `\after` inside a tuplet.
17. **LilyPond writer, tuplet brackets.**
    - First extend `lily_pond_helpers.rb`: strip `\tuplet n/d {` and its `}` while scaling durations across lines, accept them in `SIMPLE_TOKEN`, and scale `\after`. Check the helpers against the existing outputs before going further.
    - Then `RenderPlan#link_words` wraps each `TupletBrackets` bracket in `\tuplet n/d { … }`, across barlines where needed (verified in 2.26). Ratios are written as held.
    - `from`/`to` use `sounding_fraction`; `TimedMarks.duration` scales offsets inside a bracket.
    - `VoiceWriter#short_bar_rest` (`voice_writer.rb:167`) raises `RenderError` naming the bar instead of calling `.tied_chain` on nil.
18. **LilyPond writer, grace notes.**
    - `grace_writer.rb` writes:
      - `\acciaccatura` for slashed grace notes with a `from_grace` slur to the main note;
      - `\appoggiatura` for unslashed ones with that slur;
      - `\slashedGrace` or `\grace` otherwise;
      - an explicit `(` when the slur ends later.
    - Word order: tuplet opening, grace command, `\after`s, then the word.
    - Grace articulations go in `mark_writer.rb`; the helpers get a `GRACE` pattern.
    - `compile_warnings` is empty for every writer-spec example. No sync warnings were found with grace notes against `R1*4/4`, a Dynamics context, or mid-bar.
19. **kern tuplet durations.** `duration_reader.rb` uses the mapping table; rewrite `duration_reader_spec.rb:23-31` as a table, and `token_reader_spec.rb:118`.
20. **kern group inference.** New `kern/tuplet_groups.rb`; `layer.rb` calls `group_tuplet`. New `tuplet_groups_spec.rb`, `flow_builder_spec.rb` cases, and `tuplets.krn`.
21. **kern reading grace notes.**
    - `token_reader.rb` parses grace subtokens instead of returning `GRACE` early.
    - `voice_cursor.rb` queues them; `spine_voices.rb` gets the null-check fix; `layer.rb` adds them to events.
    - Rewrite `token_reader_spec.rb:58-63,176` and `flow_builder_spec.rb:590,837`. Add a two-spine grace-row case, a spec showing a real gap still raises, and `grace_notes.krn`.
22. **kern writing tuplet durations.**
    - `duration_writer.rb#reciprocal`:
      - a binary whole value writes `0`/`00`;
      - a unit numerator writes `N`;
      - a value whose sounding length is a binary or dotted note writes that note (a duplet eighth writes `8.`, as Humdrum does);
      - anything else writes `q%p`;
      - dots follow in every case (`12.`).
    - `spine_tokens.rb`, `dynamic_fields.rb` and `written_bars.rb` take onsets from `onset_in_bar`.
23. **kern writing grace rows.** `SpineTokens::Event#graces` gives tokens like `8ccq`, `8ccQ` and `8cc[q`. `data_rows.rb` writes the grace rows right-aligned before the main row, with `.` in every other column. `span_marks.rb` puts the grace slur's `(` on the first grace.
24. **kern round trips.**
    - Compare `sounding_summary` and canonical ratios (the reader's mapping, duplets as plain values), grace notes, and groups re-inferred by `TupletGroups` from the original.
    - The suite runs the fixtures and 100 seeds; render-parse-render must be exact.
    - By hand, sweep `~/github.com/cuthbertLab/music21/music21/corpus`: the five tuplet files (`beethoven/opus18no1/movement4.krn`, `chopin/mazurka06-2.krn`, the three Palestrina files) and the three grace-row files now read. `KERN_CORPUS` still passes.
25. **MusicXML divisions and offsets.**
    - `<divisions>` is the LCM of the sounding fractions of every written component and of exact mark onsets (×7 for septuplet sixteenths).
    - `divisions.rb#timed_mark_denominators`, `direction_writer.rb#offset_from` and `music_xml_helpers.rb#wedge_place` use `onset_in_bar`. Every `<duration>` comes from `sounding_fraction`.
26. **MusicXML time modification and tuplets.**
    - New `music_xml/tuplet_marks.rb`, precomputed in `RenderPlan` from `TupletBrackets`.
    - `<time-modification>` (`actual-notes`, `normal-notes`, plus `normal-type` when the bracket unit differs from the note's type) on every tuplet note, rest and split piece.
    - `<tuplet type="start|stop" number="voice index + 1"/>` on the first and last lead note of each bracket, placed in `<notations>` after `<tied>` and `<slur>`, with no `bracket` attribute. Brackets cross measures.
27. **MusicXML grace notes.**
    - Element order: `<grace slash="yes"/>` (or `<grace/>`), `<chord/>`, pitch, `<tie>`, voice, type, dots, staff, notations. No `<duration>`, no beams.
    - A tie to the main note writes start on the grace and stop on the main note's first component.
    - `slur_numbers.rb` handles a grace slur's start before the main note's stops.
28. **MusicXML summaries.**
    - `tuplet_summary(xml)` and `grace_summary(xml)` in the helpers, checked against each flow over the fixtures and 100 seeds.
    - A spec gated on `MUSICXML_XSD=path` runs `/usr/bin/xmllint --noout --schema`.

#### Coordinator, after cherry-picking

29. **LilyPond round trips and compile check.**
    - Every fixture, including crossing groups and pickups, with positions shifted for the renumbered pickup as in `spec/head_music/notation/lily_pond_dynamics_spec.rb:153`.
    - Generator with `voices: 2, pickup: true`.
    - `total_duration` in `spec/support/lily_pond_round_trip.rb` moves to `sounding_fraction`.
    - All seeds rendered into one book and compiled once, with `compile_warnings` empty.
30. **Cross-format integration.** `tuplets_and_grace_notes.ly` is read and written to ABC (where it fits), kern and MusicXML, then read back where a reader exists. The kern-imported music21 files are written to MusicXML and LilyPond, and the LilyPond output is compiled. This step catches reader/writer mismatches between worktrees, as the hairpins `<>\!` bug showed.
31. **Record and fold.** Record the decisions and any honest criterion rewording in the story, and fold the CHANGELOG lines into Unreleased.

### Testing Strategy

- **Pin exact numbers in the model specs:**
  - septuplet onsets `[0, 32914, 65829, …]` ending at 230,400;
  - a lone 7:4 sixteenth at 32,914 subticks;
  - a 9:8 eighth at 102,400;
  - quarter + eighth under 3:2 at 153,600 + 76,800;
  - `first_gap` nil after a rest-to-note merge inside a group.
- **Round-trip comparisons:** groups as `[from, to, ratio, unit]` (or `bracket_summary` where a writer turns a run into a group); grace notes per main note as `[sounds, value, slashed, tied, articulations]` plus `from_grace`.
- **Format limits:**
  - kern compares sounding onsets and lengths with canonical ratios, and groups by re-inference;
  - ABC merges voices and refuses crossing groups;
  - MusicXML has no reader, so it is checked by XPath summaries.
- **Seeds:** 100 per format in the suite, `TUPLET_SEEDS=1..2000` once per format before landing.
- **Renderers:** LilyPond 2.26 with `compile_warnings` empty for all new output. Verovio (if installed) and abcm2ps (if installed) by hand.
- **Corpus:** the music21 kern sweep by hand, and the `KERN_CORPUS` Bach spec, which has no tuplets, as a regression guard.

### Risks & Open Questions

- **Groups bracket links, not whole events.** This extends the criterion so that a triplet whose last note is tied over the beat can be one group. The product manager and both format developers raised it; it is the most common real figure. If Rob rejects it, step 5 validates whole events instead, readers rescue the `ArgumentError` and leave those values ungrouped, and writers bracket them as a run. It still renders, but straddled pairs merge into one bracket.
- **Schema 5 vs. 6.** The criterion keeps schema 5. A 22.x gem reading a new document silently turns "triplet eighth" into a plain eighth and its bars run short. 23.0.0 is major, so moving to schema 6 is cheap; Rob should decide.
- **Marks inside rounded notes** are refused here. Snapping them to the nearest onset is the alternative, but it moves the mark on a round trip.
- **Unverified renderer behavior:**
  - abcm2ps is not installed, so whether it draws a tuplet across a bar line and the `{g}(A` slur order are unchecked. `abc2ly` closes tuplets at bar lines, which supports raising. Installing it (`brew install abcm2ps`) before step 13 needs Rob's go-ahead.
  - Verovio may not be installed, so `Q` vs. `qq` for unslashed kern grace notes is unconfirmed (Humdrum defines `Q` as a groupetto). The reader takes both and the writer writes `Q`, as the criterion says.
- **ABC grace notes:** grace chords are undefined in ABC 2.1. The plan reads them and has the writer raise `RenderError`, but this is undecided. Grace lengths relative to `L:` are an assumption.
- **Writers in the gap.** Between step 2 and each format's steps, writers write tuplet values with wrong plain durations rather than refusing them. This is acceptable only because nothing is released in between.
- **Speed.** A ratio value's `next_position` walks its run when its memo is cleared. Watch the kern corpus sweep.
- **Grading may change.** Step 1 changes what `NotesSameLength` marks, so `corpus_fitness.json` may need its expectations updated.
- **The LilyPond helpers become stateful across lines.** A bug there would hide bar-sum errors.
- **Crossing tuplets in other software.** MusicXML tuplets across a barline are valid, but MuseScore and Sibelius importers may mishandle them.
- **A partial ungrouped run just before a group of the same rounded ratio** gives that group's first note the run's remainder, and `group_tuplet` raises. Only kern inference leftovers can cause this.
- **Nothing in the repo raises today on a tuplet or grace fixture.** The "fixtures that raised" criterion has no fixtures behind it; see below.
