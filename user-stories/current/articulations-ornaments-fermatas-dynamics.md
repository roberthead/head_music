<!--
metadata:
  created_at:   2026-09-25T14:05:57-07:00
  activated_at: 2026-09-25T17:40:58-07:00
  planned_at:
  finished_at:
  updated_at:   2026-09-26T15:09:56-07:00
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

| Class | Holds | Attaches to |
|---|---|---|
| `Articulation` | how a note is attacked, held, or released: staccato, staccatissimo, accent, tenuto, marcato | `NoteEvent` |
| `Ornament` | notes added around the written one: trill, mordent, inverted mordent, turn | `NoteEvent` |
| `NoteDynamic` | a dynamic that lasts one note: *sf*, *sfz*, *rfz*, *fp* | `NoteEvent` |
| `DynamicEvent` | a dynamic level that governs the music after it: *ppp* to *fff* | a voice or a part, at a position |

Dynamics are not articulations. Both kinds of dynamic draw on one catalog, `HeadMusic::Rudiment::Dynamic`, whose entries are either levels (*ppp* to *fff*) or accents (*sf*, *sfz*, *rfz*, *fp*), as `Pitch` is the rudiment a `NoteEvent` places. A `NoteDynamic` accents its note without changing the dynamic in force, except that *fp* leaves *p* in force after it.

Dynamic events take no time, so they are kept apart from the voice events. A dynamic event can be placed on a voice, where it can fall anywhere, even under a held note or a rest. It can also be placed on a part, where it governs every voice on every staff, as a piano dynamic between the two staves does or as one dynamic does for two voices sharing a staff. A voice is governed by whichever voice or part dynamic comes latest at or before a position, as a player reads the page.

This is the first of five stories from the 2026-09-25 inventory of concepts the model lacks. It comes first because it removes the most import failures, and [Spans Across Notes](../backlog/spans-across-notes.md) builds on its catalog.

## Example

```ruby
note_event = voice.place("1:1", :quarter, "C5")    # a NoteEvent
note_event.articulate(:staccato)                   # an Articulation
note_event.ornament(:trill)                        # an Ornament
note_event.accent_dynamic(:sfz)                    # a NoteDynamic
note_event.articulations.map(&:name_key) # => ["staccato"]

voice.place_dynamic("1:1", :p)                     # a DynamicEvent on the voice
part.place_dynamic("5:1", :f)                      # a DynamicEvent on the part
voice.dynamic_at("4:1").name_key # => "p"
voice.dynamic_at("5:2").name_key # => "f"
```

The method names are placeholders for planning to settle. None of the classes is named `Mark`, which `HeadMusic::Style::Mark` already uses.

## Acceptance Criteria

### Articulations and ornaments

- [ ] `Articulation` and `Ornament` are catalogs loaded from YAML, as playing techniques are: articulations are staccato, staccatissimo, accent, tenuto, and marcato; ornaments are trill, mordent, inverted mordent, and turn
- [ ] Each articulation and ornament has a name through the `Named` mixin, with English names and fallbacks for the other locales
- [ ] A `NoteEvent` can carry any number of articulations and ornaments, each at most once
- [ ] A `RestEvent` refuses an articulation, an ornament, or a note dynamic with `ArgumentError`
- [ ] None of these changes a voice event's sounds, rhythmic value, or position, and dynamic events are not voice events, so `Voice#voice_events`, `Voice::Continuity`, and every existing analysis and style guideline give the same answers

### Dynamics

- [ ] `HeadMusic::Rudiment::Dynamic` is a catalog loaded from YAML of the levels *ppp*, *pp*, *p*, *mp*, *mf*, *f*, *ff*, and *fff* and the accents *sf*, *sfz*, *rfz*, and *fp*, each named through the `Named` mixin and answering whether it is a level or an accent
- [ ] A `NoteDynamic` attaches one accent to a `NoteEvent`, at most one per note; handed a level, it raises `ArgumentError`
- [ ] A `HeadMusic::Content::DynamicEvent` holds one level at a position, and can be placed on a voice or on a part; handed an accent, it raises `ArgumentError`
- [ ] A voice's dynamic event can fall at any position in its voice, including under a held note or a rest
- [ ] A part's dynamic event governs every voice of the part, on all its staves
- [ ] `Voice#dynamic_at(position)` answers the dynamic in force: the voice or part dynamic at the latest position at or before the given one, the voice's own when both fall at that position, and *p* after an *fp*; with none written, it answers nil
- [ ] Two dynamic events at the same position on one voice, or on one part, raise `ArgumentError`

### Serialization

- [ ] Flow JSON writes a voice event's articulations and ornaments as sorted lists of keys, its note dynamic when present, a voice's dynamic events on the voice, and a part's on the part, all within schema 5 as optional keys; a flow with none serializes as it does now, and existing schema-5 documents read unchanged

### Reading

- [ ] ABC reads the articulation, ornament, and sforzando decorations as articulations, ornaments, and note dynamics, in both shorthand (`.`, `T`, `M`) and `!name!` forms, and a dynamic decoration as a dynamic event on the voice at its note
- [ ] LilyPond reads articulation shorthands and commands, the ornaments, and the sforzandos as articulations, ornaments, and note dynamics; a dynamic on a note as a dynamic event on the voice; and a `\new Dynamics` context as dynamic events on the part it sits in
- [ ] kern reads articulations, ornaments, and sforzandos in a token as articulations, ornaments, and note dynamics, and a `**dynam` spine as dynamic events on the part of the nearest `**kern` spine on its left
- [ ] A marking a reader recognizes but the catalog does not hold, such as a bowing, a breath mark, or a fermata, is dropped, so nothing that imports today starts failing; syntax a reader does not recognize at all still raises `UnsupportedFeatureError`

### Writing

- [ ] ABC, LilyPond, MusicXML, and kern write every articulation, ornament, and note dynamic
- [ ] ABC and LilyPond write a voice's dynamic event before the note it falls on. One that falls in the middle of a note is written before the next note instead, and one with no later note is left out
- [ ] ABC writes a part's dynamic events on the voice, and LilyPond writes them in a `\new Dynamics` context for the part
- [ ] MusicXML writes each dynamic event as a `<direction>` at its position, tied to its `<voice>` when it is on a voice and to none when it is on a part
- [ ] kern writes one `**dynam` spine per part that has dynamic events, holding the part's and its voices'. Where several fall at the same position, it writes the first: the part's before any voice's, and the voices in order

### Round trips

- [ ] Each format round-trips a flow with a staccato run, a trill, an *sfz*, an *fp*, and changing dynamics, keeping every articulation, ornament, and note dynamic, and the dynamic in force for every voice at every note event
- [ ] A grand-staff piano flow with dynamic events on the part round-trips through LilyPond, MusicXML, and kern
- [ ] Maintains 90%+ test coverage

## Notes

- Bowings (up-bow, down-bow), fingering, breath marks, and tremolo are also written on a note. They are out of scope, but the design should be able to hold them later.
- Hairpins are spans and belong to [Spans Across Notes](../backlog/spans-across-notes.md).
- Free-text directions ("dolce", "pizz.", "div.") are out of scope. "pizz." and "arco" overlap with playing techniques, so text directions need a design of their own.
- Kern's `**dynam` spine cannot say which voice of a part a dynamic belongs to, so a part whose voices have different dynamics comes back with one set, the part's.
- Fermatas belong to [Timeline Expressions](../backlog/timeline-expressions.md). A fermata is written on notes and rests, but it holds every part at once and changes clock time rather than any note, so it is a hold on the flow's timeline. Until that story lands, the readers drop fermatas, as kern does today.

## Implementation Plan

[to be filled in by /stories plan]
