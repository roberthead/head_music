<!--
metadata:
  created_at:   2026-07-18T14:27:34-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-07-18T14:27:34-07:00
-->

# Story: Sound Model

## Summary

AS a developer using HeadMusic

I WANT placements to hold sounds — pitched or unpitched — rather than only pitches

SO THAT the content model can represent percussion hits alongside pitched notes and chords

## Background

The content model stores a frozen `pitches` array on `Placement` (see the Chord Placement Model story): empty for a rest, one pitch for a note, two or more for a chord. There is no way to represent a sounded-but-unpitched event such as a drum hit — an empty array already means silence.

The rudiment layer got there first: `HeadMusic::Rudiment::RhythmicElement` partitions into `Note` (pitched), `Rest`, and `UnpitchedNote` (rhythmic value plus optional instrument name), each answering `sounded?`. But that hierarchy is stranded — nothing in `HeadMusic::Content` uses it.

An unpitched hit is not a pitch. `Pitch`'s contract — spelling, register, comparability, interval arithmetic — is exactly what an unpitched sound lacks, and `Placement#pitch` (`pitches.max`, the chord top line) and the whole Analysis module depend on that contract. MusicXML agrees: `<unpitched>` is a sibling of `<pitch>`, not a special pitch value. The structurally honest model is a union at the placement level: a placement has many *sounds*, where each sound is either a `Pitch` or an `UnpitchedSound`.

## Scope

- New rudiment `HeadMusic::Rudiment::UnpitchedSound`: identified by an instrument or sound name (e.g. "snare drum"), with a `.get` factory and value semantics. Deep integration with `HeadMusic::Instruments` is out of scope; a name string is enough for now.
- A minimal shared sound interface: `Pitch#pitched?` returns true, `UnpitchedSound#pitched?` returns false, both stringify and compare by value.
- `Placement#sounds` (frozen array) becomes the source of truth. `pitches` becomes the pitched subset of `sounds`; `pitch` remains the highest pitch (nil when there are no pitched sounds).
- `Voice#place` accepts a single sound, an array of sounds, or anything `Pitch.get`/`UnpitchedSound` can resolve; mixed pitched/unpitched placements are allowed (e.g. kick drum under a bass note in a keyboard-percussion voice).
- Predicates partition cleanly (folding in the planned `note?` refactor):
  - `rest?` — no sounds
  - `sounded?` — one or more sounds (new; replaces the current inclusive `note?` semantics, matching `RhythmicElement#sounded?`)
  - `note?` — exactly one sound
  - `chord?` — two or more sounds
  - `pitched?` — one or more pitched sounds; `Voice#notes` selects pitched placements so melodic and style analysis are unaffected by percussion content
- Serialization moves to schema version 3: each placement serializes a `"sounds"` array whose elements are either a pitch string (`"C4"`) or an object (`{"unpitched": "snare drum"}`). `from_h` accepts only v3, retiring v2 (consistent with retiring v1 in the Chord Placement Model story).
- The ABC and MusicXML writers raise `RenderError` on unpitched sounds until percussion rendering stories exist (consistent with the former raise-on-chord guard).
- Rewrite the dependent backlog stories (ABC Chord Input, MusicXML Chord Rendering) against the sounds model.

## Example

```ruby
composition = HeadMusic::Content::Composition.new(name: "Example", meter: "4/4")
voice = composition.add_voice(role: "percussion and melody")

snare = HeadMusic::Rudiment::UnpitchedSound.get("snare drum")

voice.place("1:1", :quarter, "C4")                 # note
voice.place("1:2", :quarter, ["C4", "E4", "G4"])   # chord
voice.place("1:3", :quarter, snare)                # unpitched hit
voice.place("1:4", :quarter)                       # rest

voice.placements.map { |p| [p.sounds.map(&:to_s), p.sounded?, p.pitched?] }
# => [[["C4"], true, true],
#     [["C4", "E4", "G4"], true, true],
#     [["snare drum"], true, false],
#     [[], false, false]]

composition.to_h["voices"].first["placements"][2]
# => { "position" => "1:3:000", "rhythmic_value" => "quarter",
#      "sounds" => [{ "unpitched" => "snare drum" }] }
```

## Acceptance Criteria

- `HeadMusic::Rudiment::UnpitchedSound` exists with a `.get` factory, value equality, and `pitched?` returning false; `Pitch#pitched?` returns true
- `Placement#sounds` holds the placement's sounds; `pitches` returns the pitched subset; `pitch` returns the highest pitch or nil
- `Voice#place` accepts a pitch, an unpitched sound, or a mixed array
- `rest?`, `sounded?`, `note?`, `chord?`, and `pitched?` behave as defined in Scope, and `Voice#notes` (melodic/style analysis) ignores placements with no pitched sounds
- `Composition#to_h` emits schema version 3 with a `"sounds"` array per placement; `from_h` round-trips v3 and rejects v2 with a clear `ArgumentError`
- The ABC and MusicXML writers raise `RenderError` when asked to render an unpitched sound
- The ABC Chord Input and MusicXML Chord Rendering backlog stories are rewritten against the sounds model
- Rubocop and all specs pass

## Implementation Plan

[to be filled in by /stories plan]
