<!--
metadata:
  created_at:   2026-10-29T20:32:47-07:00
  activated_at: 2026-10-30T08:09:09-07:00
  planned_at:
  finished_at:
  updated_at:   2026-10-30T08:20:46-07:00
-->

# Story: Rhythmic Duration

## Summary

AS a developer modeling written rhythm with head_music
I WANT `RhythmicValue` to mean one written note value (unit, dots, tuplet ratio) and a separate `RhythmicDuration` to hold one or more tied values
SO THAT the gem's vocabulary matches common music theory usage, and code that needs a single written value can say so in its types instead of guarding against ties by hand

## Acceptance Criteria

### RhythmicValue

- `HeadMusic::Rudiment::RhythmicValue` is one written value: a rhythmic unit, 0–3 augmentation dots, and an optional tuplet ratio. It has no `tied_value`, `tied_chain`, or `append_tied`.
- `RhythmicValue.get` parses single names ("dotted quarter", "triplet eighth", "5:4 sixteenth") and returns nil for a tied name ("half tied to eighth").
- A value's fraction of a whole note is its written fraction scaled by its tuplet ratio, as `link_fraction` computes today.

### RhythmicDuration

- `HeadMusic::Rudiment::RhythmicDuration` holds an ordered, non-empty list of `RhythmicValue`s joined by ties. A single untied note is a duration of one value.
- It is immutable and `Comparable`, and it reports its total `fraction`, `subticks`, and `ticks` the way a tied `RhythmicValue` does today.
- `RhythmicDuration.get` parses everything `RhythmicValue.get` parses today, tied names included, and `to_s` round-trips them ("half tied to eighth tied to sixteenth").
- It answers the chain-level questions the current class answers: whether any value is a tuplet, the ratio shared by every value (or nil), a copy with a tuplet ratio on every value, and a copy with another value tied on at the end.

### Callers

- Voice events and rhythmic elements (notes, rests, unpitched notes) hold a `RhythmicDuration`.
- Code that only accepts a single written value takes a `RhythmicValue`: grace notes, tuplet group units, tempo beats, and the "single value" checks in the MIDI, ABC, kern, and LilyPond writers. The `!value.tied_value` guards in those places go away.
- Code that walks a tied chain (bar splitting, the notation writers, MIDI note timing, voice tracks) iterates the duration's values.
- `DottedDuration` returns a `RhythmicDuration` when a fraction needs ties, and a single-value duration otherwise.

### Compatibility

- Serialized flows keep their current rhythmic value strings, so flows saved by earlier releases load unchanged. A spec loads a flow fixture containing a tied value written by the current release.
- ABC, kern, LilyPond, MusicXML, MEI, and MIDI round-trip specs pass unchanged in what they read and write.
- Ships as a major version (23.0.0), with a CHANGELOG entry listing the API changes and how to migrate.

## Notes

- Motivation: in theory usage a rhythmic value (note value) is one written symbol — notehead, dots, and any tuplet marking. A duration is how long the sound lasts, which notation spells as one value or several tied together. Today `RhythmicValue` covers both: "A rhythmic value is a duration composed of a rhythmic unit, any number of dots, an optional tuplet ratio, and a tied value." bardtheory's dictionary now follows the theory usage (its Rhythmic value and Duration entries, 2026-10-29).
- The split names a structure the code already has. The class comment says "Each link of a tied chain carries its own ratio", so each link is already a rhythmic value in the theory sense.
- About 40 call sites in `lib/` touch `tied_value`, `tied_chain`, or `append_tied`, across content, MIDI, and every notation format. About 30 spec files mention ties.
- Name: `RhythmicDuration` rather than `Duration`, because the gem already uses "duration" for plain Rational lengths (`Analysis::UnspelledNote#duration`, `Analysis::NoteInput`) and has `Notation::DottedDuration`. The prefix also pairs it with `RhythmicUnit` and `RhythmicValue`.
- bardtheory pins `~> 21.1` and only passes single-value strings (`app/services/exercise_submission_grading_service.rb`, the analysis controllers), so its upgrade should be little more than the version bump.

### Decisions (2026-10-30)

- What `RhythmicValue` names today, ties included, becomes `RhythmicDuration`. `RhythmicValue` remains a class of its own: everything except ties. A typical duration is one untied value; it may also be a tied list of values.
- Attributes follow the type. Anything that holds a possibly tied chain (voice events, notes, rests, unpitched notes, `with_rhythmic_value`) is renamed to `rhythmic_duration`. Anything limited to one written value (grace notes, tuplet group units, tempo beats, a `ChainLink`'s one link) keeps `rhythmic_value`. No deprecated alias, since 23.0.0 is major. The serialized flow key stays `"rhythmic_value"`.
- `RhythmicValue.get` returns nil for a tied name, as it does for any name it cannot read.
- `RhythmicDuration` does not delegate `unit`, `dots`, or `unit_name`. Callers ask for a value explicitly, and each style guideline decides what a tied note means, so a tied quarter no longer passes as a plain quarter.
- Equality is per class: a duration equals a duration with the same `to_s`, and comparing with a String still works. A `RhythmicValue` and a one-value `RhythmicDuration` are not `==`.

## Scope Boundaries (Not in v1)

- Durations in clock time (seconds at a tempo). That's a separate concept from notated duration.
- Changing the serialized string format for tied values.

## Implementation Plan

[to be filled in by /stories plan]
