<!--
metadata:
  created_at:   2026-10-29T20:32:47-07:00
  activated_at: 2026-10-30T08:09:09-07:00
  planned_at:   2026-10-30T08:24:43-07:00
  finished_at:
  updated_at:   2026-10-30T10:19:11-07:00
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
- `RhythmicValue.get` and `RhythmicDuration.get` return nil for a name they cannot read, instead of today's hollow value with a nil unit, and no caller guards with `&.unit`.
- A value's `fraction` of a whole note is its own written fraction scaled by its tuplet ratio, as `link_fraction` computes today; `link_fraction` goes away.

### RhythmicDuration

- `HeadMusic::Rudiment::RhythmicDuration` holds an ordered, non-empty list of `RhythmicValue`s joined by ties. A single untied note is a duration of one value.
- It is immutable and `Comparable`, and it reports its total `fraction`, `subticks`, and `ticks` the way a tied `RhythmicValue` does today.
- `RhythmicDuration.get` parses everything `RhythmicValue.get` parses today, tied names included, and `to_s` round-trips them ("half tied to eighth tied to sixteenth").
- It answers the chain-level questions the current class answers: whether any value is a tuplet, the ratio shared by every value (or nil), a copy with a tuplet ratio on every value, and a copy with another value tied on at the end.

### Comparing durations across types

- `RhythmicUnit`, `RhythmicValue`, and `RhythmicDuration` each answer `fraction`, their length as an exact Rational of a whole note, tuplet ratio included.
- Each answers `same_duration_as?(other)`, true when the two lengths are equal. `other` may be any of the three or a name (read with `RhythmicDuration.get`), and an unreadable name is false. A dotted half has the same duration as "half tied to quarter", an eighth as "sixteenth tied to sixteenth", a whole unit as "whole", and "triplet quarter" as "triplet eighth tied to triplet eighth", while "quarter" and "triplet quarter" differ.
- `<=>` orders any two of the three by length, so `RhythmicValue.get("quarter") < RhythmicDuration.get("quarter tied to eighth")`. It answers 0 for equal lengths even where `==` is false, since `==` compares notation and `<=>` compares length.

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
- `RhythmicDuration` does not delegate `unit`, `dots`, or `unit_name`. Callers ask for a value explicitly.
- Style guidelines judge a tied note by its attack, the first written value, asked for explicitly (`duration.values.first`), so today's grading holds: a one-event "half tied to half" suspension still reads as a half. `AllowFifthSpeciesRhythmicValues` checks every value, so a dotted or unpermitted tied value is still marked.
- Equality is per class: a duration equals a duration with the same `to_s`, and comparing with a String still works. A `RhythmicValue` and a one-value `RhythmicDuration` are not `==`.
- Comparing length is separate from equality: a `DurationComparison` mixin, shared by units, values, and durations, gives `same_duration_as?` and a cross-type `<=>`, both by exact `fraction`.

## Scope Boundaries (Not in v1)

- Durations in clock time (seconds at a tempo). That's a separate concept from notated duration.
- Changing the serialized string format for tied values.

## Implementation Plan

### Approach

Add `RhythmicDuration` alongside today's class, then move everything onto it in layers, each one a green commit. First the holders and the code that reads chains, then the code that builds chains, and last the removal of ties from `RhythmicValue`. The one temporary bridge: until the last step, `RhythmicDuration.get` unfolds a legacy tied `RhythmicValue` into its links. That lets the format readers keep building chains the old way until their own step. The closest existing pattern is `RhythmicValue` itself: a `.get` factory over a `NameReader`, value equality by `to_s`, and `Comparable` by length.

### Steps

0. **Pin today's serialization first.** On this branch, before changing any code, serialize a flow holding "half tied to eighth", "triplet eighth tied to triplet quarter", a dotted value, and a plain value with the current release. Save it as `spec/fixtures/content/flow_with_tied_values.json`. Add `spec/head_music/content/flow_fixture_compatibility_spec.rb`, which loads the fixture, checks each event's duration and position, and checks that re-serializing reproduces the file. It passes on today's code and must keep passing. Commit.

1. **Add `HeadMusic::Rudiment::RhythmicDuration`** in `lib/head_music/rudiment/rhythmic_duration.rb`, required in `lib/head_music.rb` right after `rhythmic_value`. Additive only.
   - `new(values)` keeps a frozen, non-empty array of `RhythmicValue`s and raises `ArgumentError` on an empty list or a non-value.
   - `.get(identifier, tuplet: nil)` accepts a `RhythmicDuration` (returned as is), a `RhythmicValue` (wrapped; a legacy tied one is unfolded through `tied_chain`, the bridge), a `RhythmicUnit`, or a Symbol/String split on `/\s+tied\s+to\s+/`, with each piece read by `RhythmicValue.get`. It answers nil if any piece is unreadable.
   - `values`, `fraction` (memoized sum of each value's `link_fraction`), `exact_subticks`, `subticks` (rounded once over the whole), `ticks`, and `total_value`.
   - `tuplet?`, `uniform_tuplet_ratio`, `with_tuplet(ratio)`, and `tied_to(value)`, which returns a new duration with the value tied on at the end.
   - `single_value`, the lone `RhythmicValue` or nil when tied. This is what the "single value" checks will ask.
   - `name`/`to_s` (values joined by " tied to "), `==` (another `RhythmicDuration` or a String, by `to_s`), and `eql?`/`hash` (same class).
   - No `unit`, `dots`, or `unit_name`, per the decisions.
   - **`HeadMusic::Rudiment::DurationComparison`** in `lib/head_music/rudiment/duration_comparison.rb`, required before `rhythmic_unit`. It includes `Comparable` and defines `<=>` (nil unless the other answers `fraction`) and `same_duration_as?(other)`, coercing a String or Symbol through `RhythmicDuration.get` at call time. `RhythmicDuration` includes it.
   - `RhythmicUnit` includes it and gains `fraction` (`Rational(numerator, denominator)`). Its `<=>` replaces the same-class `relative_value` one, which now orders the same.
   - `RhythmicValue` includes it in place of its own `<=>`. During the bridge its `fraction` still spans a legacy chain, which matches its own length for every untied value.
   - Spec `spec/head_music/rudiment/duration_comparison_spec.rb`, a table across the three types: the story's equivalences, triplets, a mismatch, a String argument, an unreadable name answering false, and `<=>` returning 0 where `==` is false.
   - Spec `spec/head_music/rudiment/rhythmic_duration_spec.rb`, carrying over the tied and tuplet-chain examples from `rhythmic_value_spec.rb` and `rhythmic_value/name_reader_spec.rb` (round trips, mixed ratios, subtick rounding once per chain, immutability, equality rules, nil on bad input).

2. **Holders and chain readers switch over.** This is the large, mechanical commit.
   - **Holders** move to `rhythmic_duration`, built with `RhythmicDuration.get`, with no alias:
     - `Content::VoiceEvent` (`voice_event.rb`, `.build`/`initialize`, `to_h` keeps the `"rhythmic_value"` key)
     - `Content::Note`
     - `Rudiment::RhythmicElement` (drop the `unit`/`dots`/`tied_value` delegation, keep `ticks`; `with_rhythmic_value` → `with_rhythmic_duration`)
     - `Rudiment::Note`, `Rest`, and `UnpitchedNote` (`get`, `fetch_or_create`, `value_equality`)
     - `Content::Voice#place` (argument renamed)
   - **Flow reading:** `Content::Flow::SchemaValues#rhythmic_value` → `#rhythmic_duration`. `valid_rhythmic_value?` becomes a check that every value has a unit, and the JSON key stays `"rhythmic_value"`. `Flow::Deserializer` follows.
   - **`Position#+`** takes a duration (anything that answers `subticks`), still converting a unit, Symbol, or String, now through `RhythmicDuration.get`.
   - **Chain readers:** `.rhythmic_value.tied_chain` becomes `.rhythmic_duration.values` in:
     - `content/chain_link.rb`, `content/voice_event/run.rb`
     - `midi/note_timing.rb`
     - `notation/bar_splitter.rb`, `written_links.rb`, `voice_track.rb`, `flow_timed_marks.rb`
     - `notation/abc/tuplet_writer.rb`, `abc/tuplet_grouping.rb`
     - `notation/kern/tuplet_groups.rb`, `kern/spine_tokens.rb`
     - `notation/lily_pond/segment_tokens.rb`, `lily_pond/span_marks.rb`, `lily_pond/voice_writer.rb`, `lily_pond/spacer_run.rb`
     - `notation/music_xml/duration_writer.rb`, `music_xml/divisions.rb`
     - `abc/duration_writer.rb`'s recursive `total_fraction` becomes `duration.fraction`.
   - **`BarSplitter::Segment`:** `rhythmic_value`/`rhythmic_value!` → `rhythmic_duration`/`rhythmic_duration!`, answering a `RhythmicDuration`.
   - **`DottedDuration`:** `rhythmic_value_for` → `rhythmic_duration_for`, answering a one-value duration or a tied one. `tied(values)` builds a `RhythmicDuration`, and `rest_value` → `rest_duration`. `single_value` stays the internal builder of one `RhythmicValue`, and the `tied_value:` keyword goes away.
   - **Style guidelines:** `PreferLongBeforeShort`, `AllowFifthSpeciesRhythmicValues`, `AlwaysMove`, `MixSpeciesTextures`, `NoteCountPerBar`, `NotesSameLength`, and `FirstBar*`. "Undotted quarter/half" checks read the attack, `rhythmic_duration.values.first`. `AllowFifthSpeciesRhythmicValues` checks every value. If that marks an existing Fux fixture, pin the mark and raise it rather than changing the rule. Comparisons against `RhythmicValue.get(...)` become `RhythmicDuration.get(...)`, because cross-class `==` is now false (see Risks).
   - Specs move with the code. Running `grep -rn "rhythmic_value" lib spec` afterward lists what's left on purpose: single-value holders and the JSON key.

3. **Chain builders build durations.** `append_tied` callers use `tied_to`, or `DottedDuration.tied`: `midi/note_values.rb`, `abc/pending_note.rb`, `kern/voice_cursor.rb`, `lily_pond/voice_stream.rb`, and `notation/tie_folding.rb`. Format readers whose token structs carry a chain (`kern/token_reader.rb`, `lily_pond/voice_stream.rb`, `music_xml/voice_tracks.rb`) rename the field to `rhythmic_duration` where it can be tied and keep `rhythmic_value` where it can't.

4. **Strip ties from `RhythmicValue`.**
   - Remove `tied_value`, `tied_chain`, `append_tied`, and `NameReader.from_tied_words`. `fraction` becomes the value's own length, and `link_fraction` is removed, with its callers (`chain_link.rb`, `voice_track.rb`, `note_timing.rb`, `kern/tuplet_groups.rb`, `DottedDuration.sounding_fraction`, `RhythmicDuration#fraction`) moved to `fraction`. `RhythmicValue.get` returns nil for a tied name. Update the class comment.
   - Remove the bridge from `RhythmicDuration.get`.
   - No hollow values. `NameReader.from_words` (reached through `from_snake_case_words`) returns nil when no unit is found, and `RhythmicValue.new` raises `ArgumentError` on an unknown unit. Drop the `&.unit` guards in `analysis/note_input.rb`, `content/flow/voice_event_values.rb`, `content/flow/schema_values.rb` (the hollow-link walk goes too), `rudiment/tempo.rb`, `midi/bar_layout.rb`, `notation/beam_groups.rb`, `content/grace_note.rb`, and `content/tuplet_group.rb`. `rhythmic_value_spec.rb` gains "returns nil for 'garbage'". Check that `Rudiment::Note.get("F#4 garbage")` still falls back the way it does today.
   - Single-value holders become typed and lose their guards: `content/grace_note.rb`, `content/tuplet_group.rb` (`unit`), `rudiment/tempo.rb` and `abc/tempo_field.rb` (beat), `abc/grace_reader.rb`, `kern/token_reader.rb`, `kern/duration_writer.rb`, `lily_pond/tempo_writer.rb`, `lily_pond/timed_marks.rb`, and `midi/note_values.rb`'s single check. Each `!value.tied_value` becomes either nothing (the type guarantees it) or `duration.single_value`. Spec: `rhythmic_value_spec.rb` gains "returns nil for 'half tied to eighth'" and "does not respond to tied_value/tied_chain/append_tied".

5. **CHANGELOG and finish.** Write an Unreleased **Breaking.** entry listing the new class, `DurationComparison` (`same_duration_as?` and the cross-type `<=>`), `RhythmicUnit#fraction`, the renamed readers (`rhythmic_duration`, `with_rhythmic_duration`, `BarSplitter::Segment#rhythmic_duration`, `DottedDuration.rhythmic_duration_for`/`rest_duration`), the removed methods, `RhythmicValue.get` on tied names, and a short before-and-after migration example. Run `bundle exec rake validate`, then `bundle exec rake oracles` (LilyPond/MIDI round trips).

### Data model changes

- New value class `RhythmicDuration`, and `RhythmicValue` loses its tied link.
- Serialized flows are unchanged: same `"rhythmic_value"` key and same strings.

### Tests to add

- `rhythmic_duration_spec.rb` (step 1).
- Flow fixture compatibility spec (step 0).
- The `RhythmicValue` tied-name and no-tie-API examples (step 4).
- `DottedDuration` examples answering a one-value and a tied `RhythmicDuration`.
- Guideline examples with a tied note for each guideline step 2 touches, pinning attack semantics (and every-value semantics for `AllowFifthSpeciesRhythmicValues`).
- Existing ABC, kern, LilyPond, MusicXML, MEI, and MIDI round-trip specs stay unchanged in what they read and write. Their setup code may rename.

### Risks and open questions

- **Equality goes quiet.** With per-class `==`, `note.rhythmic_duration == RhythmicValue.get(:half)` answers false instead of raising. In step 2, grep for `==`, `include?`, `tally`, and hash keys that mix the two types, and convert each one: to `RhythmicDuration.get(...)` where notation is meant, or to `same_duration_as?` where length is meant (as in `NotesSameLength`'s `total_value` checks).
- **Step 2 is large** (~380 lib references, ~90 spec files). It's mechanical but it's one commit. If it stops being reviewable, the commit can be split by module (content, MIDI, then each format). A temporary `rhythmic_value` reader on the holders would keep each piece green, as long as it's deleted before step 4.
- **Rounding:** `subticks` must still round once over the whole duration, not once per value, or 7:4 chains drift. The step 1 specs pin this.
- **bardtheory** reads only strings and the JSON key, so its upgrade is the version bump plus any direct `RhythmicValue` use. That's to be confirmed when it moves to `~> 23.0`.

## Review

Reviewed 2026-10-30 at `a35b6555`, by an independent read of the diff against `main`, with each finding checked against the code.

### Acceptance criteria

| Criterion | Verdict | Evidence |
|---|---|---|
| RhythmicValue is one written value, with no tie API | ✅ | `lib/head_music/rudiment/rhythmic_value.rb:22`, `spec/head_music/rudiment/rhythmic_value_spec.rb:124` |
| `RhythmicValue.get` reads single names, nil for a tied name | ✅ | `lib/head_music/rudiment/rhythmic_value/name_reader.rb:8` |
| nil for unreadable names, no `&.unit` guards | ✅ | `name_reader.rb:42`, `rhythmic_value.rb:51`; no `&.unit` left in `lib/` |
| A value's fraction includes its ratio | ✅ | `rhythmic_value.rb:71` |
| RhythmicDuration: ordered, non-empty list of values | ✅ | `lib/head_music/rudiment/rhythmic_duration.rb:39` |
| Immutable, Comparable, fraction, subticks, ticks | ✅ | `rhythmic_duration.rb:43-65`; a 7:4 chain rounds once |
| `RhythmicDuration.get` reads tied names, `to_s` round-trips | ✅ | `rhythmic_duration.rb:32`, `spec/head_music/rudiment/rhythmic_duration_spec.rb` |
| Chain-level questions | ✅ | `rhythmic_duration.rb:71-90` |
| `fraction` on unit, value, and duration | ✅ | `rhythmic_unit.rb:118`, `rhythmic_value.rb:71`, `rhythmic_duration.rb:44` |
| `same_duration_as?` across types | ✅ | `lib/head_music/rudiment/duration_comparison.rb:14`, `spec/head_music/rudiment/duration_comparison_spec.rb` |
| `<=>` across types, 0 where `==` is false | ✅ | `duration_comparison.rb:10` |
| Voice events and rhythmic elements hold a RhythmicDuration | ✅ | `lib/head_music/content/voice_event.rb:36`, `lib/head_music/rudiment/rhythmic_element.rb:13` |
| Single-value holders take a RhythmicValue, tie guards gone | ✅ | `content/grace_note.rb:57`, `content/tuplet_group.rb:108`, `rudiment/tempo.rb:87` |
| Chain walkers iterate the duration's values | ✅ | `content/chain_link.rb:8`, `notation/bar_splitter.rb`, `midi/note_timing.rb:72` |
| DottedDuration answers a tied or one-value duration | ✅ | `lib/head_music/notation/dotted_duration.rb:37` |
| Flows from earlier releases load unchanged | ✅ | `spec/head_music/content/flow_fixture_compatibility_spec.rb`, fixture from commit `86a091f1` |
| Format round-trip specs unchanged in what they read and write | ⚠️ | Spec diffs are renames only; 277 of 284 oracle specs pending without their corpora and schemas |
| Ships as 23.0.0 with a CHANGELOG entry and migration | ⚠️ | Entry under Unreleased; the version bump is for the release; the entry has gaps (finding 4) |

### Findings

1. **Bug: `Rudiment::Note.get(pitch, "garbage")` builds a note with no duration** (`lib/head_music/rudiment/note.rb:32`). It never checks the nil that `RhythmicDuration.get` now returns, so it registers a note `"C4 "` under the key `"C4_"`, and its `#ticks` fails later. `Rest.get` and `UnpitchedNote.get` answer nil. It should answer nil too.
2. **`Content::Note.new("C4", "garbage")` keeps a nil duration** (`lib/head_music/content/note.rb:14`). The failure surfaces only when its voice event is built. It should raise `ArgumentError`, as `VoiceEvent` does.
3. **The guideline changes are untested.** No style guideline spec places a tied note. The plan called for pinning the attack rule in `AlwaysMove`, `MixSpeciesTextures`, and `PreferLongBeforeShort`, and the every-value rule in `AllowFifthSpeciesRhythmicValues`, which changes that guideline's grades for tied notes.
4. **CHANGELOG gaps.**
   - The unreleased Tuplet ratios entry still says `get` reads "triplet eighth tied to quarter" back, which only `RhythmicDuration.get` does now.
   - The Breaking entry omits that `CantusFirmus::Example#to_flow(rhythmic_value:)`, released in 21.0.0, is now `to_flow(rhythmic_duration:)`.
   - It also omits that `RhythmicElement` dropped `#tied_value` along with `#unit` and `#dots`.
   - It also omits that "tied to" is now read in any case.
5. **Loose tie parsing (low).** `RhythmicValue.get("half tied to")` and `"tied to half"` read as "half", as `RhythmicDuration.get("half tied to")` does. `main` behaves the same, but a dangling tie is no single value.
6. **Style (low).** A comment in `lib/head_music/notation/music_xml/duration_writer.rb` runs to 117 characters after an edit, and the ABC and MusicXML duration writers accept either a value or a duration through `respond_to?(:values)` rather than one type.

### Resolution

Findings 1–4 are fixed: `a4f9b1ad` (Note.get answers nil), `fc6cd2c1` (Content::Note raises), `645cba3f` (guideline specs, each shown to fail under the other rule), and `02a4e0df` (CHANGELOG). The full suite passes, 18,844 examples. Findings 5 and 6 are left as they are: the loose tie parsing matches `main`, and the style points are minor.
