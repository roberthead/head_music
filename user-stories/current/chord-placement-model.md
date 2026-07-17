<!--
metadata:
  created_at:   2026-07-17T13:20:33-07:00
  activated_at: 2026-07-17T13:23:57-07:00
  planned_at:   2026-07-17T13:32:17-07:00
  finished_at:
  updated_at:   2026-07-17T14:29:35-07:00
-->

# Story: Chord Placement Model

## Summary

AS a developer using HeadMusic

I WANT a `Placement` to hold an array of pitches instead of a single pitch attribute

SO THAT a chord within a voice is modeled as one rhythmic event, with its shared position and duration guaranteed by structure rather than convention

## Background

A chord within a single voice shares one stem and therefore one rhythmic value; different durations at the same position indicate different voices. Modeling a chord as multiple co-positioned placements leaves that invariant unenforced and quietly breaks the "voice is a sequence of events" assumptions in `Voice` — `melodic_note_pairs` would compute a melodic interval between simultaneous chord tones, and `first_gap` would falsely report a gap at every chord (the second chord tone starts at the same position as the first, not at `previous.next_position`).

Every notation format also treats a chord as a single event with multiple pitches: ABC `[CEG]2`, LilyPond `<c e g>2`, and MusicXML's `<chord/>` grouping. Moving to a `pitches` array makes the model match, which is a prerequisite for [ABC Chord Input](abc-chord-input.md) and [MusicXML Chord Rendering](musicxml-chord-rendering.md).

## Scope

- `Placement` stores a `pitches` array (empty for a rest, one element for a single note, multiple for a chord).
- `Placement#pitch` becomes a derived method returning the *highest* pitch in `pitches` (nil when empty), so melodic analysis of chordal music follows the top line.
- `Placement#note?` remains true when any pitch is present; `#rest?` when none. Add a `#chord?` predicate (two or more pitches).
- `Voice#place` accepts a single pitch (as today) or an array of pitches.
- One placement per position, enforced structurally: `Voice#place` merges a same-position placement into the existing one when the rhythmic value matches (the pitch union is duplicate-free, so re-placing a pitch is idempotent) and raises `ArgumentError` when it does not — simultaneous pitches with different durations belong in different voices.
- Serialization: `Placement#to_h` always emits a `"pitches"` array (empty for rests); `SCHEMA_VERSION` bumps to 2 and v1 hashes are no longer accepted (no v1 data exists in the wild). Ships as gem 16.0.0.
- Backward compatibility for behavior is a hard requirement: all single-pitch code paths behave identically. Existing specs pass unmodified except serialization wire-shape assertions and specs that relied on co-positioned duplicate placements.
- Out of scope: per-tone attributes within a chord (ties, fingerings, noteheads), ABC/MusicXML chord syntax (separate stories), and any change to `Voice`'s melodic analysis beyond what `#pitch` delegation already provides.

## Example

```ruby
voice.place("2:1", :half, %w[C4 E4 G4])

placement = voice.last_placement
placement.pitches.map(&:to_s)  # => ["C4", "E4", "G4"]
placement.pitch.to_s           # => "G4" (highest pitch)
placement.chord?               # => true

placement.to_h
# => { "position" => "2:1:000", "rhythmic_value" => "half", "pitches" => ["C4", "E4", "G4"] }
```

## Acceptance Criteria

- `Placement` exposes `#pitches` (always an array) and derives `#pitch` as the highest pitch, nil for rests
- `Voice#place` accepts a single pitch or an array of pitches; existing single-pitch call sites are unchanged
- `#chord?` is true for two or more pitches; `#note?` / `#rest?` semantics are unchanged for single notes and rests
- `#to_h` always emits `"pitches"` under `schema_version` 2; `.from_h` rejects v1 hashes with a clear error, and a chord round-trips through `to_h` / `from_h`
- Placing at an occupied position merges when durations match (idempotently — no duplicate pitches) and raises `ArgumentError` naming both durations and the position when they differ
- Existing specs pass unmodified except serialization wire-shape assertions and specs that relied on co-positioned duplicate placements (runtime behavior for single-pitch code is otherwise a no-op)
- Gem version is 16.0.0 with a changelog entry describing the breaking changes
- New specs cover chord construction, `#pitch` derivation, predicates, and serialization round-trips
- Rubocop passes

## Notes

- Choosing the highest pitch for `#pitch` means `Voice#pitches`, `#highest_pitch`, `#melodic_note_pairs`, and style analysis follow the top line of chordal textures — the conventional melody line — without any changes to `Voice`.
- The [ABC Chord Input](abc-chord-input.md) and [MusicXML Chord Rendering](musicxml-chord-rendering.md) backlog stories were written assuming co-positioned placements; their Background/Scope sections should be updated to build on this model once this story lands.

## Implementation Plan

### Overview

Convert `Placement`'s stored state from a single `@pitch` to a normalized, frozen `@pitches` array with `#pitch` derived as `pitches.max`; `Voice#place` and `Note` pass through unchanged. `to_h` always emits a `"pitches"` array (empty for rests) and drops the singular `"pitch"` key; because that changes the shape of an existing key, `SCHEMA_VERSION` bumps to 2 per the serialization contract, and `from_h` accepts both v2 and legacy v1 hashes.

### Key design decision: unconditional `"pitches"` emission with a schema bump

Per user decision, `to_h` emits `"pitches"` for every placement, and the existing wire-shape specs are updated to match. The four spec locations that pin the exact `"pitch"` hash shape with strict `eq` — `spec/head_music/content/placement_spec.rb:130-145`, `spec/head_music/content/voice_spec.rb:282-292`, `spec/head_music/content/composition_spec.rb:215-216`, and `spec/head_music/content/composition_serialization_spec.rb:106,132,158,178-181` — change to assert the `"pitches"` array shape.

The serialization contract (`user-stories/done/composition-serialization.md`) allows additive keys within v1 but requires a `schema_version` bump for shape changes to existing keys, so `SCHEMA_VERSION` becomes 2. `from_h` accepts versions 1 and 2: v1 hashes (bardtheory's persisted jsonb data) still load via the legacy `"pitch"` key, and old gem versions reading a *new* v2 hash fail loudly on the version check (`composition.rb:175`) instead of silently deserializing every note as a rest.

### Steps

1. **Rework `Placement` internals and predicates**
   - Replace `attr_reader :pitch` with `attr_reader :pitches` (line 8); in `ensure_attributes` (lines 63-68), set `@pitches = Array(pitch_or_pitches).map { |p| HeadMusic::Rudiment::Pitch.get(p) }.compact.freeze`. `Array()` is safe (`Pitch` defines no `to_a`/`to_ary`; `Array(nil) == []`); `.compact` preserves today's lenient behavior where `Pitch.get("garbage")` → nil → rest; `.freeze` preserves the value-object contract. Preserve input order; do not sort or dedupe (round-trip fidelity — matches the stable-insertion philosophy documented at `voice.rb:156-161`).
   - Add derived `def pitch` = `pitches.max`, unmemoized (1-4 element arrays; avoids the nil-memoization trap). `Pitch#<=>` compares `midi_note_number` (`pitch.rb:152-154`), so enharmonic ties (`B♯3` vs `C4`) resolve to the first-listed pitch — pin this in a spec.
   - Rename the fourth positional param to `pitch_or_pitches` (arity unchanged; all `Placement.new` call sites verified positional: `voice.rb:20`, `note.rb:20`, plus three spec sites).
   - `note?` becomes `pitches.any?` (currently returns the pitch object; all call sites verified boolean-context, no spec asserts the return value). Add `def chord?` = `pitches.length > 1`. `rest?` unchanged.
   - `to_s`: `pitches.any? ? pitches.map(&:to_s).join(" ") : "rest"` — character-identical for 0-1 pitches (asserted at `voice_spec.rb:193`), "half C4 E4 G4 at 2:1:000" for chords.
   - `delegate :spelling, to: :pitch, allow_nil: true` (line 11) needs no change — it now delegates to the derived top pitch.
   - `to_h` (line 45): always emit `"pitches" => pitches.map(&:to_s)` (empty array for rests); drop the `"pitch"` key.
   - Files: `lib/head_music/content/placement.rb`

2. **Deserialization accepting both keys**
   - In `HashDeserializer#build_voices` (`composition.rb:205-216`), replace the `parsed_pitch(placement_hash["pitch"], path)` call with a new `parsed_placement_pitches(placement_hash, path)` helper following the existing `parsed_*` boundary-validation style: if `placement_hash.key?("pitches")` (use `key?`, not truthiness, so `[]` reads as a rest), require an Array (else `ArgumentError` with path context) and validate each element with per-element paths (`voices[0].placements[2].pitches[1]: unknown pitch ...`), treating a nil element as invalid (a rest is `[]` or legacy `"pitch" => nil`, never `[nil]`). Otherwise fall back to `parsed_pitch(placement_hash["pitch"], path)` unchanged, preserving the exact error text asserted at `composition_serialization_spec.rb:444-448`. Precedence: `"pitches"` wins when both keys are present.
   - Bump `SCHEMA_VERSION` to 2. Relax the version check (`composition.rb:175`) to accept 1 and 2 (e.g. `SUPPORTED_SCHEMA_VERSIONS = [1, 2]`), so bardtheory's persisted v1 jsonb data still loads; update the version-mismatch specs at `composition_serialization_spec.rb:410-429` accordingly (an unknown version like 3 still raises).
   - Files: `lib/head_music/content/composition.rb`

3. **`Voice#place` pass-through**
   - Rename the third param to `pitch_or_pitches` for clarity — cosmetic only; it already passes straight to `Placement.new`. Verified unaffected because a chord is one placement: `first_gap` contiguity, `melodic_note_pairs` (`each_cons(2)`), `notes`, `pitches`, `note_at`, `highest_pitch`, `pitches_string`. Co-positioned single-pitch placements remain legal (the rich fixture at `composition_serialization_spec.rb:54-57` builds one and must stay green). `Note` (`note.rb`) needs no change — its single `Pitch` gets wrapped by normalization.
   - Files: `lib/head_music/content/voice.rb`

4. **Loud-failure guards in the notation writers**
   - `abc/writer.rb:126` and `music_xml/writer.rb:322` read the derived `placement.pitch`, so a chord would silently export as its top note only — syntactically valid output missing notes, the worst failure mode. Raise (`NotImplementedError` or the writer's existing error class) when `placement.chord?`, with a spec each, until the ABC Chord Input / MusicXML Chord Rendering stories land. This cannot break existing code: chords were previously inexpressible as a single placement. Trade-off: anyone constructing chords before those stories ship gets an error instead of a truncated render — chosen deliberately (loud beats silently lossy).
   - Files: `lib/head_music/notation/abc/writer.rb`, `lib/head_music/notation/music_xml/writer.rb`

5. **Specs**
   - Update the wire-shape assertions to the `"pitches"` array shape: `placement_spec.rb:130-145`, `voice_spec.rb:282-292`, `composition_spec.rb:215-216`, `composition_serialization_spec.rb:106,132,158,178-181` (rest emits `"pitches" => []`), and the schema-version specs at `composition_serialization_spec.rb:410-429`.
   - `spec/head_music/content/placement_spec.rb` (extend): chord construction via array; `#pitches` order preserved and frozen; `#pitch` returns highest regardless of input order (`%w[G4 C4 E4]` → G4); enharmonic tie returns first-listed (`%w[B♭4 A♯4]`); `#chord?`/`#note?`/`#rest?` truth table for 0/1/2+ pitches; single-element array identical to bare pitch; empty array → rest (`"pitches" => []`); duplicates preserved; chord `to_h`; chord `to_s`.
   - `spec/head_music/content/voice_spec.rb` (extend): `voice.place("2:1", :half, %w[C4 E4 G4])` creates exactly one placement; `first_gap` nil across a chord; melodic pair between note and chord uses the top pitch.
   - `spec/head_music/content/composition_serialization_spec.rb` (extend): chord round-trips `to_h`/`from_h` losslessly (use `expect_lossless_round_trip(composition, abc: false, musicxml: false)` given step 4's guards); a legacy v1 hash with `"pitch"` keys (including `"pitch" => nil` rests) still loads; `"pitches"` precedence when both keys present; malformed input raises with element path context (non-array `"pitches"`, garbage element, `[nil]`). Build chords with `voice.place` directly — ABC chord syntax doesn't exist yet.
   - All other existing specs remain untouched, including the legacy co-positioned-placement chord fixtures; only wire-shape and schema-version assertions change.
   - Files: `spec/head_music/content/placement_spec.rb`, `spec/head_music/content/voice_spec.rb`, `spec/head_music/content/composition_serialization_spec.rb`, writer specs under `spec/head_music/notation/`

6. **Validation and follow-through**
   - `bundle exec rspec` (full suite green; the only modified existing examples are the wire-shape and schema-version assertions from step 5), `bundle exec rubocop -a`, `bundle exec rake` (90% coverage gate).
   - Update `user-stories/backlog/abc-chord-input.md` and `user-stories/backlog/musicxml-chord-rendering.md` Background/Scope: both are written against the co-positioned-placements model ("one placement per pitch, all at the same position"; contiguity/`<chord/>` grouping of co-positioned placements) and should be rewritten to build on the single-placement pitches array — which simplifies both (MusicXML contiguity works by construction; ABC parser emits one placement).

### Edge cases handled

- Duplicate pitches (`%w[C4 C4 E4]`): preserved, not deduped — the model doesn't silently alter caller data, and dedup would break `from_h(to_h(x)) == x` for such input.
- Nil/unparseable elements: lenient at the constructor (compacted, matching today's single-pitch leniency); strict at the `from_h` boundary (raises with path context), matching the existing split.
- Empty array vs nil argument: both normalize to `[]` → rest.
- Enharmonic tie for `#pitch`: first-listed wins (order-dependent but deterministic since order is preserved); pinned by spec.
- Legacy hash with both `"pitch"` and `"pitches"`: `"pitches"` wins.
- Legacy v1 `"pitch" => nil` rest: loads as a rest; re-serializes as v2 `"pitches" => []`.
- Old gem versions reading new v2 hashes: fail loudly on the schema-version check rather than silently misreading notes as rests.

### Testing Strategy

Wire-shape assertions updated once to the `"pitches"` schema (v2) and then pinned exactly as before, a legacy-v1 loading spec preserving the old fixtures' shape, new chord behavior specs in house style (tests-as-documentation), boundary-validation error-path specs mirroring the existing `parsed_*` cases, and the coverage/lint gates. Details per file in step 5.

### Implementation increment: same-position merge and v2-only schema

Decided with the user after the initial implementation landed:

- `Voice#place` at an occupied position merges into the existing placement when the rhythmic value matches and raises `ArgumentError` ("cannot place a quarter at 1:1:000: position occupied by a half") when it does not. `Placement#merge` performs the pitch union; the union (and the constructor) are duplicate-free, so re-placing a pitch is idempotent. A rest merges cleanly in both directions (a note onto a same-duration rest becomes the note; a rest onto a note is a no-op). The invariant enforced is one *event* per position — overlapping durations at different positions remain representable, as before.
- Since no v1 data exists in the wild, `from_h` accepts only schema version 2; `SUPPORTED_SCHEMA_VERSIONS` and the legacy `"pitch"`-key fallback were removed, and a v1 hash fails loudly on the version check.
- Gem version bumped to 16.0.0 with a changelog entry covering the breaking changes (schema v2 only, derived `#pitch`, boolean `#note?`, merge-or-raise placement, writer chord guards).
- Spec fallout: the co-positioned-placement fixtures now assert merging; a style-guideline fixture with accidentally duplicated `place` calls was cleaned up (its mark count halved accordingly).

### Risks & Open Questions

- **Schema v2 rollout**: consumers must upgrade the gem to read or write v2 hashes; v1 hashes are rejected outright. The 16.0.0 major bump and changelog signal the break.
- **Writer guards raise on chords** (step 4) — recommended over silent top-note export; if silent export is preferred for the interim, drop step 4 and add `abc: true, musicxml: true` round-trip checks instead.
- **`notes_not_in_key` blind spot**: with derived top pitch, an out-of-key inner chord tone is invisible to `Voice#notes_not_in_key` (`voice.rb:29-31`), and `lowest_pitch` of a chordal voice reports the lowest top-line pitch, not the chord bass. The story scopes Voice changes out; the two-line `notes_not_in_key` fix is worth a follow-up (or a one-line scope extension here if desired).
- **`note?` return type** changes from truthy `Pitch` to boolean — all in-repo call sites verified boolean-context; a theoretical external caller chaining off the return value would break.
