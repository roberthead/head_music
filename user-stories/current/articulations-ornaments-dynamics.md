<!--
metadata:
  created_at:   2026-09-25T14:05:57-07:00
  activated_at: 2026-09-25T17:40:58-07:00
  planned_at:   2026-09-26T15:57:06-07:00
  finished_at:
  updated_at:   2026-09-26T17:52:10-07:00
-->

# Story: Articulations, Ornaments, Dynamics

## Summary

AS a developer or researcher using HeadMusic

I WANT note events to carry the markings written on them, such as staccato, a trill, or *sfz*, and voices and parts to carry dynamics such as *p* and *f*

SO THAT the many files that use these markings import instead of failing, and the markings survive a trip through the gem

## Background

These are the most common markings in written music, and every format has them:

| Concept | ABC | LilyPond | MusicXML | kern | MEI |
|---|---|---|---|---|---|
| Staccato, accent, tenuto, marcato | `.C`, `!accent!`, `!tenuto!` | `c-.`, `c->`, `c--`, `c-^` | `<articulations>` | `'`, `^`, `~` | `<artic>` |
| Trill, mordent, turn | `TC`, `MC`, `!turn!` | `\trill`, `\mordent`, `\turn` | `<ornaments>` | `t`, `m`, `S` | `<trill>`, `<mordent>`, `<turn>` |
| Dynamics and sforzandos | `!p!`, `!sfz!` | `\p`, `\sfz` | `<dynamics>` | `p` in `**dynam` | `<dynam>` |

The model has none of them. ABC raises on `.` and `!…!` decorations, LilyPond raises on `-.` and `\fermata`, and kern drops them. A folk tune in ABC with one staccato dot, or a LilyPond file with one *f*, cannot be imported.

A voice holds `VoiceEvent`s that fill its time end to end: a `NoteEvent` sounds one or more `Soundable`s, and a `RestEvent` is silent. Three kinds of marking attach to a note event, and dynamic levels are events of their own. They are kept apart as MusicXML and MEI keep them:

| Kind | Holds | Attaches to |
|---|---|---|
| `Rudiment::Articulation` | how a note is attacked, held, or released: staccato, staccatissimo, accent, tenuto, marcato | `NoteEvent` |
| `Rudiment::Ornament` | notes added around the written one: trill, mordent, inverted mordent, turn | `NoteEvent` |
| note dynamic | a dynamic that lasts one note: *sf*, *sfz*, *rfz*, *fp*, held as a `Rudiment::Dynamic` accent | `NoteEvent` |
| `Content::DynamicEvent` | a dynamic level that governs the music after it: *ppp* to *fff* | a voice or a part, at a position |

In the catalog, `mordent` is the lower mordent (the main note, the note below, the main note) and `inverted_mordent` is the upper. ABC `M` and `P`, LilyPond `\mordent` and `\prall`, MusicXML `<mordent>` and `<inverted-mordent>`, and kern `m` and `w` map by that meaning.

Dynamics are not articulations. Both kinds of dynamic draw on one catalog, `HeadMusic::Rudiment::Dynamic`, whose entries are either levels (*ppp* to *fff*) or accents (*sf*, *sfz*, *rfz*, *fp*). A note event holds its accent directly, as it holds a `Pitch`, with no wrapper class. An *sf*, *sfz*, or *rfz* accents its note without changing the level in force. An *fp* puts *p* in force for its own voice from the *fp* note's position onward, even over a dynamic event at that position, until a later dynamic event.

Dynamic events take no time, so they are kept apart from the voice events. A dynamic event can be placed on a voice, where it can fall anywhere, even under a held note or a rest. It can also be placed on a part, where it governs every voice on every staff, as a piano dynamic between the two staves does or as one dynamic does for two voices sharing a staff. A voice is governed by whichever voice or part dynamic comes latest at or before a position, as a player reads the page.

This is the first of five stories from the 2026-09-25 inventory of concepts the model lacks. It comes first because it removes the most import failures, and [Spans Across Notes](../backlog/spans-across-notes.md) builds on its catalog.

## Example

```ruby
note_event = voice.place("1:1", :quarter, "C5")    # a NoteEvent
note_event.articulate(:staccato)                   # a Rudiment::Articulation
note_event.embellish(:trill)                       # a Rudiment::Ornament
note_event.note_dynamic = :sfz                     # a Rudiment::Dynamic accent
note_event.articulations.map(&:name_key) # => ["staccato"]

voice.place_dynamic("1:1", :p)                     # a DynamicEvent on the voice
part.place_dynamic("5:1", :f)                      # a DynamicEvent on the part
voice.dynamic_at("4:1").name_key # => "p"
voice.dynamic_at("5:2").name_key # => "f"
```

`dynamic_at` answers a `Rudiment::Dynamic` level, not a `DynamicEvent`, since the *p* after an *fp* has no event behind it. None of the classes is named `Mark`, which `HeadMusic::Style::Mark` already uses.

## Acceptance Criteria

### Articulations and ornaments

- [ ] `Articulation` and `Ornament` are catalogs loaded from YAML, as playing techniques are: articulations are staccato, staccatissimo, accent, tenuto, and marcato; ornaments are trill, mordent, inverted mordent, and turn
- [ ] Each articulation, ornament, and dynamic has a name through the `Named` mixin, translated in every shipped locale: en, de, es, fr, it, and ru, with en_GB falling back to en
- [ ] A `NoteEvent` can carry any number of articulations and ornaments, each at most once; articulating or embellishing it with a marking it already carries leaves it unchanged
- [ ] When `Voice#place` merges a note event into an existing one at the same position, the existing event keeps its articulations, ornaments, and note dynamic
- [ ] A `RestEvent` refuses an articulation, an ornament, or a note dynamic with `ArgumentError`
- [ ] None of these changes a voice event's sounds, rhythmic value, or position, and dynamic events are not voice events, so `Voice#voice_events`, `Voice::Continuity`, and every existing analysis and style guideline give the same answers

### Dynamics

- [ ] `HeadMusic::Rudiment::Dynamic` is a catalog loaded from YAML of the levels *ppp*, *pp*, *p*, *mp*, *mf*, *f*, *ff*, and *fff* and the accents *sf*, *sfz*, *rfz*, and *fp*, each named through the `Named` mixin and answering whether it is a level or an accent
- [ ] A `NoteEvent` holds at most one note dynamic, which must be an accent; handed a level, it raises `ArgumentError`
- [ ] A `HeadMusic::Content::DynamicEvent` holds one level at a position, and can be placed on a voice or on a part; handed an accent, it raises `ArgumentError`
- [ ] A voice's dynamic event can fall at any position in its voice, including under a held note or a rest
- [ ] A part's dynamic event governs every voice of the part, on all its staves
- [ ] `Voice#dynamic_at(position)` answers the level in force: the voice or part dynamic at the latest position at or before the given one, the voice's own when both fall at that position; with none written, it answers nil
- [ ] At a note carrying *sf*, *sfz*, or *rfz*, `dynamic_at` answers the level in force before it
- [ ] *p* is in force from an *fp* note's own position, even over a dynamic event at that position, until a later dynamic event; an *fp* sets *p* only for its own voice
- [ ] Two dynamic events at the same position on one voice, or on one part, raise `ArgumentError`

### Serialization

- [ ] Flow JSON writes a voice event's articulations and ornaments as sorted lists of keys, its note dynamic when present, a voice's dynamic events on the voice, and a part's on the part, all within schema 5 as optional keys; a flow with none serializes as it does now, and existing schema-5 documents read unchanged

### Reading

- [ ] ABC reads the articulation, ornament, and sforzando decorations as articulations, ornaments, and note dynamics, in both shorthand (`.`, `T`, `M`, `P`) and `!name!` forms, and a dynamic decoration as a dynamic event on the voice at its note
- [ ] LilyPond reads articulation shorthands and commands, the ornaments, and the sforzandos as articulations, ornaments, and note dynamics, and a dynamic on a note as a dynamic event on the voice
- [ ] LilyPond reads a `\new Dynamics` inside a `\new PianoStaff` or `\new StaffGroup` as dynamic events on the group's part, and one beside a single `\new Staff` in the same `<< >>` as dynamic events on that staff's part
- [ ] kern reads articulations, ornaments, and sforzandos in a token as articulations, ornaments, and note dynamics, and a `**dynam` spine as dynamic events on the part of the nearest `**kern` spine on its left
- [ ] An accent in a `**dynam` spine attaches to every note event of its part that attacks on that row; with none attacking, it is dropped
- [ ] A reader drops an articulation, ornament, or note dynamic written on a rest; a dynamic level written on a rest becomes a dynamic event at the rest's position
- [ ] A marking a reader recognizes but the catalog does not hold, such as a bowing, a breath mark, or a fermata, is dropped, so nothing that imports today starts failing; syntax a reader does not recognize at all still raises `UnsupportedFeatureError`

### Writing

- [ ] ABC, LilyPond, MusicXML, and kern write every articulation, ornament, and note dynamic
- [ ] A writer that splits a note event across bars writes its articulations, ornaments, and note dynamic only on the first written fragment
- [ ] ABC and LilyPond write a voice's dynamic event before the note it falls on. One that falls in the middle of a note is written before the next note instead, and one with no later note is left out
- [ ] ABC writes a part's dynamic events on the voice; where a voice's dynamic event and its part's fall on the same note, it writes only the one `dynamic_at` answers
- [ ] LilyPond writes a part's dynamic events in a `\new Dynamics` context for the part, at their exact positions, using spacer rests
- [ ] MusicXML writes each dynamic event as a `<direction>` at its position, tied to its `<voice>` when it is on a voice and to none when it is on a part
- [ ] kern writes one `**dynam` spine per part that has dynamic events or an *sf*, *rfz*, or *fp*, holding the part's and its voices'. Where several fall at the same position, it writes the first: each voice's accent in voice order, then the part's level, then each voice's level in voice order

### Round trips

- [ ] ABC, LilyPond, and kern each round-trip a flow with a staccato run, a trill, an *sfz*, an *fp*, and changing dynamics, keeping every articulation, ornament, and note dynamic, and the dynamic in force for every voice at every note event
- [ ] A grand-staff piano flow with dynamic events on the part round-trips through LilyPond and kern, and MusicXML writes it with every dynamic as a `<direction>` at its position
- [ ] Maintains 90%+ test coverage

## Notes

- Bowings (up-bow, down-bow), fingering, breath marks, and tremolo are also written on a note. They are out of scope, but the design should be able to hold them later.
- Hairpins are spans and belong to [Spans Across Notes](../backlog/spans-across-notes.md).
- Free-text directions ("dolce", "pizz.", "div.") are out of scope. "pizz." and "arco" overlap with playing techniques, so text directions need a design of their own.
- "marcato" is both an `Articulation` (the `^` sign on one note) and a `PlayingTechnique` (the word "marc." over a passage). They stay separate: a reader turns the sign into the articulation and, once text directions exist, the word into a playing technique.
- Kern's `**dynam` spine cannot say which voice of a part a dynamic belongs to, so a part whose voices have different dynamics comes back with one set, the part's. It also holds one value per position, so a part with an *sf*, *rfz*, or *fp* at the same position as a dynamic event writes only the accent. A level left out can often be told from the levels around it, while an accent left out is gone; and an *fp* overrides a level at its own position anyway, so the level in force reads back the same.
- MusicXML has no reader, so it is checked by asserting on the XML it writes. Reading these markings belongs to [MusicXML Import](../backlog/musicxml-import.md).
- Dynamic events raise on a duplicate position rather than replacing, unlike meter, tempo, and instrument changes, because a second dynamic at one instant is almost always an error.
- Kern tokens with `z` and ABC's `T` and `M` shorthand fail with an unsupported-signifier or unexpected-character error today; this story makes them import.
- Fermatas belong to [Timeline Expressions](../backlog/timeline-expressions.md). A fermata is written on notes and rests, but it holds every part at once and changes clock time rather than any note, so it is a hold on the flow's timeline. Until that story lands, the readers drop fermatas, as kern does today.

## Implementation Plan

### Overview

Three YAML catalogs under `HeadMusic::Rudiment` (`Articulation`, `Ornament`, `Dynamic`) share one small catalog mixin. A `NoteEvent` holds its markings directly. A new `HeadMusic::Content::DynamicEvent` lives in a sorted collection on both `Voice` and `Part`, and `Voice#dynamic_at` resolves the level in force from the voice's events, its part's events, and any *fp*. Flow JSON gains optional schema-5 keys. Each format then gets its reader and writer work, in steps that can each be committed on their own.

Planned by a story-planner with a product manager, a best-practices engineer, and developers for the model and for each format.

**API**

| Call | Returns | Why |
|---|---|---|
| `NoteEvent#articulate(*keys)` | `self` | A domain verb that chains like `sing` |
| `NoteEvent#embellish(*keys)` | `self` | A writer named `ornament` beside the `ornaments` reader would read as a lookup; the codebase pairs a verb writer with a noun reader, as `sing` does with `syllables` |
| `NoteEvent#note_dynamic=` / `#note_dynamic` | the accent, or `nil` | One value, like `beam_break_before`; `nil` clears it. `accent(:sfz)` would clash with the `:accent` articulation |
| `Voice#place_dynamic`, `Part#place_dynamic` | the `DynamicEvent` | Matches `place`, and is not `change_*`, because the `EventMap` family replaces at a duplicate position and this one raises |
| `Voice#dynamic_at(position)` | a `Rudiment::Dynamic` level, or `nil` | The *p* after an *fp* has no event behind it; the name matches `Part#instrument_at` |
| `DynamicEvent#level` | a `Rudiment::Dynamic` | Reads better than `dynamic_event.dynamic` |

### Steps

1. **Catalog mixin, `Articulation`, and `Ornament`**
   - `HeadMusic::Rudiment::KeyedCatalog` gives all three catalogs one `.get(identifier)`: it snake-cases its input, resolves aliases, and returns a cached, frozen instance, or `nil` for an unknown key, as `Alteration.get` does. `.all` lists records in YAML order. Override the inherited `Named.get_by_name` (`lib/head_music/named.rb:8`) to go through `.get`.
   - Names come through `Named` and `I18n.translate(name_key, scope:, default: name_key.tr("_", " "))`, as `PlayingTechnique#name` does. Names go under `head_music.articulations` and `head_music.ornaments` in `en.yml`, `de.yml`, `es.yml`, `fr.yml`, `it.yml`, and `ru.yml`, using each language's usual term (for example *Triller*, *trino*, *trille*, *trillo*, *трель*); `en_GB` falls back to `en`.
   - Articulation keys: `staccato`, `staccatissimo`, `accent`, `tenuto`, `marcato`. Ornament keys: `trill`; `mordent` (aliases `lower_mordent`, `mordent_lower`); `inverted_mordent` (aliases `upper_mordent`, `pralltriller`); `turn`.
   - Files: `lib/head_music/rudiment/keyed_catalog.rb`, `articulation.rb`, `articulations.yml`, `ornament.rb`, `ornaments.yml`, the six locale files, `lib/head_music.rb` (require after `rudiment/tempo`).
   - Specs: `spec/head_music/rudiment/articulation_spec.rb` and `ornament_spec.rb`, mirroring `playing_technique_spec.rb`: `.get` from a symbol, a string, `"inverted-mordent"`, and each alias; the same instance each time; `.get(:bogus)` is nil; `.all` matches the story's list; names in every locale, with a spec that fails when a key is missing from any locale file.

2. **`HeadMusic::Rudiment::Dynamic`**
   - Records carry `kind: level | accent`; `fp` also carries `level_after: p`, so `dynamic_at` reads data rather than hardcoding *fp*, and *sfp* could be added later as data. Quote the YAML keys (`"p":`, `"f":`).
   - `#level?`, `#accent?`, `#level_after`, `.levels` (ppp to fff, in order), `.accents`. `.get` downcases, so `"MF"` gives `mf`. Names under `head_music.dynamics` in all six locale files: the Italian terms (*pianissimo*, *sforzando*, *fortepiano*) are standard across languages, with local spellings where they differ, such as Cyrillic in ru.
   - Files: `lib/head_music/rudiment/dynamic.rb`, `dynamics.yml`, the six locale files, `lib/head_music.rb`.
   - Spec: `spec/head_music/rudiment/dynamic_spec.rb`: eight levels and four accents, `level?` and `accent?`, `get(:fp).level_after == get(:p)`, nil for `sfz`, names in every locale.

3. **Note-event markings and rest refusal**
   - `VoiceEvent` gets empty defaults (`articulations` and `ornaments` return `[]`, `note_dynamic` returns `nil`), so readers and writers never check `is_a?`.
   - `NoteEvent#articulate` and `#embellish` share one private helper. An unknown key raises `ArgumentError`; a repeated key is ignored. Each set is a hash keyed by `name_key`, like `syllables`, and the readers return frozen arrays sorted by `name_key`. `note_dynamic=` raises for a level or an unknown key.
   - `NoteEvent#merge` is unchanged: the merged-in event is always freshly built by `VoiceEvent.build` (`voice.rb:69`), so it carries no markings, and the existing event keeps its own. Add a clause to the merge comment.
   - `RestEvent#articulate`, `#embellish`, and `#note_dynamic=` raise `ArgumentError`, worded like its `sing` refusal.
   - Files: `lib/head_music/content/voice_event.rb`, `note_event.rb`, `rest_event.rb`.
   - Specs: `note_event_spec.rb` (several markings kept, repeats ignored, sorted, unknown key raises, `note_dynamic = :f` raises, `nil` clears, sounds and timing unchanged); `rest_event_spec.rb` (refusals and empty defaults); `voice_spec.rb` (articulate, then place a second pitch at the same position; the chord keeps the staccato).

4. **`DynamicEvent`, storage on Voice and Part, and `Voice#dynamic_at`**
   - `DynamicEvent.new(flow, position, level)` raises unless the dynamic is a level, coerces the position as `VoiceEvent#ensure_position` does, and raises for a `Position` from another flow (`Position#eql?` ignores the flow; `Comment` has the same guard). It has `name_key`, `to_h` (`{"position" => "5:1:000", "level" => "f"}`), and `to_s`.
   - `DynamicEvents`, a sorted collection both Voice and Part delegate to: `#place` inserts with `bsearch_index` (as `Voice#insertion_index` does) and raises at an equal position, so `"5:1"` and `"5:1:000"` collide; `#latest_at(position)` uses `bsearch`; `#to_a`, `#empty?`. Do not reuse `Time::EventMap`: it needs `position.bar`, which `Content::Position` lacks, and it replaces rather than raises.
   - `Voice#dynamic_at(position)` coerces the position, then takes the maximum by `[position, rank]` of: the part's latest event at or before it (rank 0), the voice's own (rank 1), and the latest note event at or before it whose `note_dynamic.level_after` is set (rank 2). It answers that candidate's level, or `nil`. The *fp* search walks back from a `bsearch` index and stops once it passes the best candidate, so writers don't pay O(n) per call. A voice reaches its part through `voice.part`, whatever staff it is on.
   - `Flow#latest_bar_number` keeps counting voice events only, so a trailing dynamic adds no bar.
   - Files: `lib/head_music/content/dynamic_event.rb`, `dynamic_events.rb`, `voice.rb`, `part.rb`, `lib/head_music.rb` (require both after `content/syllable`, before `content/voice`).
   - Specs: `dynamic_event_spec.rb` (accent raises, unknown key raises, foreign position raises, string positions coerced, `to_h`); `voice_spec.rb` (nil before anything is written; at and after an event; under a held note and a rest; later of part and voice wins; voice wins a tie; *p* from the *fp* note, beating a level at that position, and *f* after a later *f*; *sfz* leaves the level alone; duplicates raise in both spellings; `voice_events` and `Voice::Continuity` unchanged); `part_spec.rb` (a part event reaches two voices, including one that `cross_to`s the lower staff; a duplicate raises).

5. **Flow JSON, optional keys within schema 5**
   - Written only when non-empty, following `syllables`: a voice event's `"articulations"` and `"ornaments"` (sorted key lists) and `"note_dynamic"` (a string); a voice's and a part's `"dynamic_events"`, each a list of `{"position", "level"}`.
   - `schema_values.rb` gains `catalog_keys(values, catalog, label, path)`, which raises with the path on a non-array, an unknown key, a duplicate, or the wrong kind (a level as `note_dynamic`, an accent in `dynamic_events`). `deserializer.rb` rejects markings on a rest, like the syllables check. `hash_deserializer.rb` places the dynamic events and re-raises `ArgumentError` with its path. `v4_upgrade.rb` and `SCHEMA_VERSION` are unchanged.
   - Files: `voice_event.rb`, `voice.rb`, `part.rb`, `flow/schema_values.rb`, `flow/deserializer.rb`, `flow/hash_deserializer.rb`.
   - Specs: new `describe` blocks in `flow_serialization_spec.rb`, leaving `rich_flow` alone because the unknown-keys spec depends on it: a round trip through `to_h` and JSON; an unmarked voice event's keys are exactly `%w[position rhythmic_value sounds]`, and voice and part hashes have no `"dynamic_events"`; a handwritten schema-5 document without the new keys reads. Every rejection path in `schema_values_spec.rb`. A layout realization spec showing markings survive the transposing hash merge.

6. **Shared notation helper and cross-format fixtures**
   - `HeadMusic::Notation::DynamicPlacement` (`lib/head_music/notation/dynamic_placement.rb`), for ABC and LilyPond, gives a voice's `[voice_event, level]` pairs: each dynamic event goes on the first note event at or after its position, one with no later note is dropped, one on a rest stays on the rest, and where two land on one note event it keeps the one `dynamic_at` answers. An `include_part:` flag lets ABC fold in the part's events.
   - `spec/support/marking_fixtures.rb`: `marked_melody` (one voice with a staccato run, a trill, an *sfz*, an *fp*, a level under a held note, and three level changes) and `grand_staff_piano_with_dynamics` (`LilyPondFixtures.cross_staff_piano` plus part-level *p*, *f*, *mp* and one voice-level dynamic). The kern fixture keeps accents off rows that carry a level.
   - `expect_same_markings(original, round_tripped)` compares markings event by event and `dynamic_at` for every voice at every note event.
   - Spec: `spec/head_music/notation/dynamic_placement_spec.rb`.

7. **ABC reader**
   - `body_lexer.rb`: take `.` and `~` out of the unsupported `[()~.]` class and add a `:decoration` token for `!word!`, legacy `+word+`, and the shorthand letters `[.~HLMOPSTuv]`, scanned before the unsupported patterns. An unterminated `!foo` still raises. `.|` is ABC 2.1's dotted bar line and keeps raising: a dot decorates only when a note, chord, or rest follows. If a `U:` header redefines `u` or `v`, raise rather than guess. Check that inline fields like `[T:…]` are not lexed as decorations.
   - `decoration_mapper.rb`: `DecorationMapper.classify` returns `{kind:, key:}` or `nil`.

     | Kind | ABC | Key |
     |---|---|---|
     | Articulation | `.`, `!staccato!` | staccato |
     | | `!wedge!` | staccatissimo |
     | | `L`, `!accent!`, `!>!`, `!emphasis!` | accent |
     | | `!tenuto!` | tenuto |
     | | `!marcato!`, `!^!` | marcato |
     | Ornament | `T`, `!trill!` | trill |
     | | `M`, `!lowermordent!`, `!mordent!` | mordent |
     | | `P`, `!uppermordent!`, `!pralltriller!` | inverted_mordent |
     | | `!turn!` | turn |
     | Note dynamic | `!sf!`, `!sfz!`, `!rfz!`, `!fp!` | same |
     | Level | `!ppp!` to `!fff!` | same |
     | Dropped | `~`, `H`, `O`, `S`, `u`, `v`, `!roll!`, `!fermata!`, `!invertedfermata!`, `!breath!`, `!upbow!`, `!downbow!`, `!0!`–`!5!`, `!open!`, `!thumb!`, `!snap!`, `!slide!`, `!trem1!`–`!trem4!`, `!segno!`, `!coda!`, `!D.C.!`, `!D.S.!`, `!fine!`, `!pppp!`, `!ffff!`, hairpin and phrase decorations | none |

     `!marcato!`, `!sf!`, `!rfz!`, `!fp!`, and `!^!` are abcm2ps and abc2svg extensions, read leniently.
   - `Preflight.reject_unrecognized_decorations` runs over the whole tune before `interpret` (`parser.rb:39`), keeping unsupported input rejected up front.
   - `parser.rb`, `voice_state.rb`: buffer decorations in `VoiceState`, attach them to `PendingNote`, and apply them in `flush_pending_note`. Before a rest, a level becomes a dynamic event at the rest's position and other marks are dropped. A decoration with nothing to attach to (before a bar line, a tie, the end of the tune) raises `ParseError`. Model `ArgumentError`s are wrapped as `ParseError` with a line number.
   - Specs: `body_lexer_spec.rb` (the three "unsupported" cases near lines 396–406 now expect `:decoration`; rename "turn mark" to "roll mark", since `~` is the Irish roll); `preflight_spec.rb`; `parser_spec.rb` (replace the `!trill!` row of the unsupported table with `!bogus!`; a `describe "decorations"` block pinning `M` to `mordent` and `P` to `inverted_mordent`, and covering `!p!z4`, `Hz4`, `.|`, and a dangling decoration).

8. **ABC writer and round trip**
   - `decoration_writer.rb`: staccato as `.`, everything else as `!name!` (`!lowermordent!`, `!uppermordent!`, `!marcato!`, …). The writer already refuses multi-voice flows (`writer.rb:38`).
   - `Writer#token` marks only the segment where the note starts (`segment.bar_number == voice_event.position.bar_number`), writing the level from `DynamicPlacement` with `include_part: true`, then articulations, ornaments, and the note dynamic.
   - Specs: `writer_spec.rb` (exact strings, a trailing dynamic left out, a mid-note dynamic moved to the next note, a tied note marked once); a new `spec/head_music/notation/abc_round_trip_spec.rb` running `expect_same_markings` on `marked_melody`.

9. **LilyPond reader: marks after a note**
   - The lexer already lexes the shorthands as `:unsupported` (`lexer.rb:30`), and `lexer_spec.rb:183-193` keeps passing.
   - `mark_reader.rb`: `MarkReader.match(cursor)` recognizes two-character shorthands `[-^_][.!>\-^_+]` (`.` staccato, `!` staccatissimo, `>` accent, `-` tenuto, `^` marcato; `_` portato and `+` stopped are dropped); a direction sign plus a command, or a bare command: `\staccato`, `\staccatissimo`, `\accent`, `\tenuto`, `\marcato`, `\trill`, `\mordent`, `\prall` (inverted_mordent), `\turn`, `\sf`, `\sfz`, `\rfz`, `\fp`, `\ppp` to `\fff`. Dropped: `\fermata`, `\upbow`, `\downbow`, `\breathe`, `\sfp`, `\spp`, `\sff`, `\fz`, `\pppp`, `\ffff`. Not matched, so they still raise: a `-` before a number (fingering), and single marks like the `!` in `cis!`.
   - `MusicItemReader` loops through marks after a note, rest, or chord and stores them on new `VoiceStream::Event` fields (`articulations`, `ornaments`, `note_dynamic`, `level`), wrapping `ArgumentError` as `read_key` does.
   - `FlowBuilder#place_note` and a new `#place_rest` apply them at the position captured before the voice advances. Do not use `VoiceStream#mark` or `apply_marker`: they position at replay time and would put `c4\p d4`'s *p* on the d. Marks on a rest other than a level are dropped.
   - `--` is tenuto after a note and a hyphen in `\lyricmode`; `MarkReader` runs only after note items, so add a spec proving lyrics are unaffected. A dynamic on an inner link of a tie (`c1~ c4\p~ c4`) is read at the start of the tied group, because `VoiceStream#extend_tie` merges the links first; pin that limitation in a spec.
   - Files: `mark_reader.rb`, `voice_stream.rb`, `music_item_reader.rb`, `flow_builder.rb` under `lib/head_music/notation/lily_pond/`.
   - Specs: a new `mark_reader_spec.rb`; in `document_reader_spec.rb`, remove `f` and `p` from the shared unsupported list at line 359 and add a markings block. Write backslash-heavy specs with the Edit tool.

10. **LilyPond reader: `\new Dynamics`**
    - `lexer.rb`: move `SPACER_PATTERN` out of the unsupported patterns into a `:spacer` token checked right after `rest_token`; update `lexer_spec.rb:79-83`.
    - `context_reader.rb`: add `"Dynamics"` to `CONTEXT_TYPES` and to the contexts a staff group allows. Its part is the enclosing `\new PianoStaff` or `\new StaffGroup`'s; otherwise the nearest `\new Staff` before it in the same `<< >>`; with neither, it raises.
    - Inside a Dynamics context the reader accepts only spacers, rests, bar checks, and `MarkReader` marks. Articulations and accents are dropped there, and notes raise.
    - `FlowBuilder` tracks the context's running position with `Position + rhythmic_value` (`position.rb:92-95`) and calls `part.place_dynamic` for each level.
    - Files: `lexer.rb`, `context_reader.rb`, `music_reader.rb`, `voice_stream.rb`, `flow_builder.rb`.
    - Specs: levels at mixed offsets including mid-note, the piano case between staves, the single-staff sibling case, an orphaned context raising, and a note inside a Dynamics context raising.

11. **LilyPond writer: marks and voice dynamics**
    - `RenderPlan#token` (`render_plan.rb:42-50`) marks only the segment where the note starts: articulations as shorthands (`-.`, `-!`, `->`, `--`, `-^`), ornaments and the note dynamic as commands (`\trill`, `\mordent`, `\prall`, `\turn`, `\sfz`, …), and voice levels from `DynamicPlacement` after the note.
    - Extend `SIMPLE_TOKEN` and `strip_commands` in `spec/support/lily_pond_helpers.rb` first, or `expect_structurally_valid_lilypond` rejects every new spec.
    - Files: `render_plan.rb`, `voice_writer.rb`, `spec/support/lily_pond_helpers.rb`.
    - Specs: `writer_spec.rb`, with exact strings, structural validity, and the `"a compilable document"` shared example.

12. **LilyPond writer: `\new Dynamics`, and the round trips**
    - `Writer#part_lines` (`writer.rb:95-105`) gives a part with dynamic events a `\new Dynamics { … }`: between the staves inside its `\new PianoStaff` or `\new StaffGroup`, or as a sibling after a single staff in the same `<< >>`. Gaps are filled with spacers, split at bar lines with `BarSplitter` and `DottedDuration`, so part events stay at their exact positions.
    - Files: `writer.rb`, `render_plan.rb`, `spec/support/lily_pond_fixtures.rb`, `spec/support/lily_pond_round_trip.rb`.
    - Specs: `expect_lily_pond_round_trip` on `marked_melody` and `grand_staff_piano_with_dynamics`; extend `expect_equivalent_voice_voice_events` with the markings and compare the part's dynamic events.

13. **MusicXML writer: `<notations>`**
    - `note_writer.rb#notation_lines`, after the ties, writes `<ornaments>`, `<articulations>`, and `<dynamics>` on the chord's first note only (the one without `<chord/>`), following `lyric_writer.rb:17`.

      | Key | Element |
      |---|---|
      | staccato, staccatissimo, accent, tenuto | `<staccato/>`, `<staccatissimo/>`, `<accent/>`, `<tenuto/>` |
      | marcato | `<strong-accent/>` |
      | trill, mordent, inverted_mordent, turn | `<trill-mark/>`, `<mordent/>`, `<inverted-mordent/>`, `<turn/>` |
      | sf, sfz, rfz, fp | `<sf/>`, `<sfz/>`, `<rfz/>`, `<fp/>` |

    - Keep the tables in `lib/head_music/notation/music_xml/marking_writer.rb`. `<mordent>` is the sign with the vertical line, the lower mordent; pin it by name.
    - Specs: `marking_writer_spec.rb`, plus `writer_spec.rb` cases using `spec/support/music_xml_helpers.rb`.

14. **MusicXML writer: `<direction>`**
    - `direction_writer.rb` writes:

      ```xml
      <direction placement="below">
        <direction-type><dynamics><p/></dynamics></direction-type>
        <offset>n</offset>
        <voice>n</voice>
        <staff>n</staff>
      </direction>
      ```

      `<offset>` appears only mid-note, in divisions from the start of the note event that holds the position (`BarSplitter.offset_in_bar` and `RenderPlan#divisions`). `<voice>` follows the writer's rules for notes; a part event has none. `<staff>` is omitted on a single-staff part; on a grand staff a voice event takes its voice's staff and a part event has none.
    - `writer.rb`: part directions go before a bar's loop over voices, voice directions inline in each voice's run of segments, before the `<backup>`. Directions add no duration.
    - Files: `direction_writer.rb`, `writer.rb`, `render_plan.rb`.
    - Specs: `direction_writer_spec.rb`; `writer_spec.rb` (a dynamic at a note's start, mid-note, and under a rest); `writer_cross_staff_spec.rb` (`grand_staff_piano_with_dynamics` with unchanged `<backup>` durations); a structural no-loss spec on `marked_melody` asserting every marking appears in the XML.
    - A part dynamic on a grand staff has no `<staff>`, so other software defaults it to staff 1. Compare with a MuseScore export if interchange matters.

15. **kern token marks: reading and writing**
    - `token_reader.rb`: take the mark characters out of `IGNORED` (line 25) and read them into new `Token` fields. `^^` is marcato, read before the single `^` (accent); `'` staccato, `` ` `` staccatissimo, `~` tenuto; `t`/`T` trill, `m`/`M` mordent, `w`/`W` inverted_mordent, `S` turn; `z` the note dynamic `sfz`. `$` and `R` stay dropped. Marks on a rest are dropped; a chord takes the union of its notes' marks.
    - `layer.rb`, `voice_cursor.rb`: apply the marks when the event is placed; only a tie's first link carries them, as with syllables.
    - `spine_tokens.rb`: write the characters after the pitch on the attacking segment, on every pitch of a chord; `sfz` as `z`. `sf`, `rfz`, and `fp` go in `**dynam` (step 17).
    - Specs: `token_reader_spec.rb`, `flow_builder_spec.rb`, `writer_spec.rb`.

16. **kern `**dynam` reading**
    - `spine_layout.rb`: `**dynam` gets its own kind, `:dynam`, instead of `:skipped`. Update `spine_layout_spec.rb:16,68` and `document_spec.rb:16`, and say in the commit that those changes are intended.
    - `dynamic_reader.rb`, shaped like `lyric_reader.rb` with its nearest-kern-track-on-the-left logic: levels `ppp` to `fff` and accents `sf`, `sfz`, `rfz`, `fp`; `.`, `<`, `>`, and their spans are skipped; other text raises.
    - `flow_builder.rb#read_data`, for every row: a level is kept as `[time, part, key]` and placed with `part.place_dynamic` once bars are final; an accent goes on every note event of that part attacking on the row, and is dropped if none does.
    - `BarSplitter.position_at(flow, bar_number, offset)` turns elapsed time into a `Content::Position` (bar from `clock.bar_containing`, then count and tick from the meter), the inverse of `offset_in_bar`. It is the plan's only new arithmetic, so it gets its own spec in simple and compound meters.
    - Specs: a new `dynamic_reader_spec.rb`; `flow_builder_spec.rb` (a level mid-note, an accent on two staves, an accent with nothing attacking dropped); `bar_splitter_spec.rb`.

17. **kern `**dynam` writing and round trips**
    - `writer.rb`: `Column` gets a `dynam:` flag. A part with dynamic events, or with an *sf*, *rfz*, or *fp*, gets one `**dynam` column after its rightmost column, holding at each position the first of: the part's level, each voice's level in voice order, each voice's accent.
    - A dynamic where nothing attacks needs a row of null tokens in the kern spines; verifying that the row timeline can produce one is the main risk of this step.
    - Files: `lib/head_music/notation/kern/writer.rb`, a new `spec/fixtures/notation/kern/articulations_ornaments_dynamics.krn`.
    - Specs: a new `kern_articulations_dynamics_fixture_spec.rb` modelled on `kern_chorale_fixture_spec.rb`; extend `kern_piano_splits_fixture_spec.rb`, whose `**dynam` spine splits and joins, so `part.dynamic_events` reads *p*, *f*, *p* at the right positions and its reads-back-to-itself check covers dynamics; kern round trips of both shared fixtures.

18. **CHANGELOG**, added in each step's commit: under Unreleased, Added lists the catalogs, the `NoteEvent` markings, `DynamicEvent`, `Voice#dynamic_at`, the optional JSON keys, and each format's reading and writing; Fixed lists kern tokens with `z` and ABC `T`/`M` shorthand. Nothing is **Breaking.**; the kern `SpineLayout` kind is internal.

### Testing strategy

- **Model:** `dynamic_at` ties at exact positions and under held notes and rests; position spellings that normalize to one point; *fp* followed by a later level; a part event reaching a voice on the other staff; `voice_events`, `Voice::Continuity`, and a sampled style guideline unchanged by markings.
- **JSON:** an unmarked flow serializes key for key as now; rests refuse markings both through the API and in a document; every `schema_values` rejection path.
- **Readers:** a closed-vocabulary table spec per format covering every recognized-and-dropped entry, so coverage doesn't depend on round trips; dangling or orphaned marks raise; unknown syntax still raises `UnsupportedFeatureError`.
- **Round trips:** the shared fixtures and `expect_same_markings` hold ABC, LilyPond, and kern to one standard; MusicXML gets structural assertions.
- Never assert console output. Build compositions with `HeadMusic::Notation::ABC.parse` where shorter. Run `bundle exec rake` and `bundle exec rubocop -a` for each step.

## Review

Reviewed 2026-09-26 at commit `469fc444`, covering the story's commits `442167a4^..HEAD`. A product manager checked the acceptance criteria and a code reviewer read the diff; each finding below was reproduced before it was recorded. The full suite passes: 9839 examples, 0 failures, with 99.75% line and 95.57% branch coverage, and rubocop is clean.

### Acceptance criteria

| Criterion | Verdict | Evidence |
|---|---|---|
| Articulation and Ornament catalogs from YAML | ✅ | `rudiment/keyed_catalog.rb`, `articulations.yml`, `ornaments.yml`; `articulation_spec.rb`, `ornament_spec.rb` |
| Names in every locale, en_GB falls back | ✅ | `keyed_catalog_spec.rb` fails on any missing locale key |
| Any number of markings, each once, repeats ignored | ✅ | `note_event.rb:82-90`; `note_event_spec.rb` |
| Merge keeps the existing event's markings | ✅ | `voice.rb:237-247`; `voice_spec.rb:186-199` |
| A rest refuses markings | ✅ | `rest_event.rb:16-26`; `rest_event_spec.rb` |
| Voice events, continuity, analysis, and style unchanged | ⚠️ | True by construction, and `voice_events` and `Voice::Continuity` are pinned (`voice_spec.rb:304`). No spec runs a style guideline over a marked flow, which the plan called for |
| Dynamic catalog of levels and accents | ✅ | `rudiment/dynamic.rb`, `dynamics.yml`; `dynamic_spec.rb` |
| One note dynamic, and it must be an accent | ✅ | `note_event.rb:96-104`; `note_event_spec.rb:83` |
| DynamicEvent holds a level on a voice or a part | ✅ | `dynamic_event.rb:32-44`; `dynamic_event_spec.rb` |
| A voice dynamic can fall under a held note or a rest | ✅ | `voice_spec.rb:225,230` |
| A part dynamic governs every voice on every staff | ✅ | `part_spec.rb:142`, including a voice that crosses staves |
| `dynamic_at` takes the latest, the voice wins a tie, nil when none | ✅ | `voice.rb:92-100`; `voice_spec.rb:246` |
| *sf*, *sfz*, *rfz* leave the level alone | ✅ | `voice_spec.rb:286` |
| *fp* gives *p* from its own note, for its own voice only | ✅ | `voice.rb:208-218`; `voice_spec.rb:267,277` |
| Duplicate positions raise | ✅ | `dynamic_events.rb:20-23`; `voice_spec.rb:292`, `part_spec.rb:146` |
| Flow JSON uses optional schema-5 keys | ✅ | `schema_values.rb`, `deserializer.rb`; `flow_serialization_spec.rb`, `schema_values_spec.rb` |
| ABC reading | ✅ | `abc/decoration_mapper.rb`, `body_lexer.rb`, `voice_state.rb`; `.\|` still raises |
| LilyPond reads marks on notes | ✅ | `lily_pond/mark_reader.rb`, `music_item_reader.rb`, `flow_builder.rb`; `mark_reader_spec.rb` |
| LilyPond reads `\new Dynamics` as part dynamics | ✅ | `context_reader.rb`, `flow_builder.rb`; `lily_pond_dynamics_spec.rb`. It drops accents in these contexts, though (finding 4) |
| kern reads token marks and `**dynam` | ✅ | `kern/token_reader.rb`, `dynamic_reader.rb`, `flow_builder.rb` |
| A `**dynam` accent goes on every attacking note, or is dropped | ✅ | `kern/flow_builder.rb`; flow builder specs cover two staves and the case where nothing attacks |
| Markings on rests are dropped, and a level becomes an event | ✅ | Tested in all three readers |
| Recognized-but-uncatalogued markings are dropped, and unknown syntax raises | ✅ | ABC and LilyPond `DROPPED_*` tables and preflight; `!bogus!`, `\foo`, `-1` raise |
| Every writer writes every marking | ✅ | `abc/decoration_writer.rb`, `lily_pond/mark_writer.rb`, `music_xml/marking_writer.rb`, `kern/spine_tokens.rb` |
| Split notes are marked on the first fragment only | ✅ | A spec in each of the four writers |
| ABC and LilyPond write a voice dynamic before its note | ⚠️ | ABC does. LilyPond omits a voice level that falls on a note carrying *fp* (`render_plan.rb:107-111`), so that event does not survive a round trip, though `dynamic_at` answers the same everywhere |
| ABC folds in part dynamics | ✅ | `DynamicPlacement` with `include_part: true`; `abc/writer_spec.rb:604` |
| LilyPond writes part dynamics in `\new Dynamics` | ✅ | `render_plan.rb`, `writer.rb`; round-trip specs |
| MusicXML `<direction>` with voice and staff rules | ✅ | `music_xml/direction_writer.rb`; `writer_cross_staff_spec.rb:59-79`. It raises on a dynamic between note boundaries (finding 1) |
| kern `**dynam` precedence | ✅ | `kern/dynamic_fields.rb:41-47`; `kern/writer_spec.rb`. The order drops accents (finding 3) |
| `marked_melody` round-trips through ABC, LilyPond, and kern | ✅ | `abc_round_trip_spec.rb`, `lily_pond_round_trip_spec.rb`, `kern_round_trip_spec.rb` |
| Grand-staff piano round-trips through LilyPond and kern; MusicXML writes it | ✅ | Exact through LilyPond. Through kern the voice's *mf* comes back on the part, the loss the Notes predict, and a spec pins it. The MusicXML part is `writer_cross_staff_spec.rb:59-79` |
| 90%+ coverage | ✅ | 99.75% line, 95.57% branch |

### Code review findings

1. **The MusicXML writer raises on a dynamic between note boundaries.** `Divisions.for` (`music_xml/divisions.rb`) never considers dynamic event positions. A voice of quarter notes with `place_dynamic("1:1:480", :p)` raises `RenderError: cannot express a dynamic's offset … in 1 divisions per quarter note`, and so does a LilyPond `\new Dynamics { s8 s8\p … }` read and then written as MusicXML. The fix is to add each dynamic event's offset to the denominators.
2. **The kern writer crashes on a part with dynamics but no voices.** `kern/writer.rb:64` calls `part_columns.last.with(...)` on nil and raises `NoMethodError`. It should skip the `**dynam` column or raise `RenderError`.
3. **The kern writer drops an *sf*, *rfz*, or *fp* that shares a row with a level.** `kern/dynamic_fields.rb:35-46` puts levels first and keeps only the first value. A lost level can be recovered from the context around it, but a lost accent is gone. Either put accents first or raise. The Notes accept the loss, so this is a judgment call, and no spec pins it.
4. **The LilyPond reader silently drops accents in `\new Dynamics`.** `\new Dynamics { s4\sfz s4 s2\p }` between piano staves keeps the *p* and loses the *sfz* (`lily_pond/flow_builder.rb:84-96`). It should either attach the accent to the part's notes attacking there, as the kern `**dynam` reader does, or raise.
5. **The LilyPond writer omits a voice level on an *fp* note.** See the ⚠️ above.
6. **Minor points:**
   - A mid-note kern dynamic splits the note into tied links, so a dotted quarter comes back as a quarter tied to an eighth. That is a format limit, but no spec pins it.
   - The MusicXML writer drops a voice dynamic that falls after the voice's last event in a bar, and says nothing.
   - The deserializer silently merges alias duplicates such as `["mordent", "lower_mordent"]`.
7. **Duplication:**
   - The kern reader and writer keep the mark tables by hand as inverses of each other (`token_reader.rb`, `spine_tokens.rb`).
   - The level and accent lists are hard-coded in `abc/decoration_mapper.rb` and `lily_pond/mark_reader.rb`, where `Dynamic.levels` and `Dynamic.accents` would do.
   - Placing a level and wrapping `ArgumentError` appears in both `abc/voice_state.rb` and `lily_pond/flow_builder.rb`.
   - The first-fragment check is repeated in `abc/writer.rb` and `lily_pond/render_plan.rb`.

### Resolution

- Finding 1 is fixed in `33084ad1`: divisions now count each dynamic event's offset.
- Finding 2 is fixed in `c4e36d3a`: kern Preflight refuses dynamics on a part with no voices, since a `**dynam` spine needs a `**kern` spine on its left.
- Finding 4 is fixed in `fc0749de`: an accent in a `\new Dynamics` goes on every note of the part attacking at its position, as a kern `**dynam` accent does.
- Finding 3 is decided: accents now come ahead of levels in kern's `**dynam` precedence, and the kern writing criterion and the Notes say so. It is pinned in `kern/writer_spec.rb`.
- Finding 5 is decided: LilyPond keeps leaving out a voice level on an *fp* note, pinned in `lily_pond/writer_spec.rb` ("with a level on a note that carries fp").
- Still open: the style-guideline spec for the "unchanged" criterion, and the minor points and duplication above.
