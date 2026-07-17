<!--
metadata:
  created_at:   2026-07-16T12:00:00-07:00
  activated_at: 2026-07-16T18:59:42-07:00
  planned_at:   2026-07-16T19:25:49-07:00
  finished_at:
  updated_at:   2026-07-16T21:38:30-07:00
-->

# Story: Composition Serialization (to_h / from_h)

## Summary

AS a developer using HeadMusic

I WANT to serialize a `HeadMusic::Content::Composition` to a plain hash and reconstruct it losslessly

SO THAT downstream apps can persist compositions in a database and reload them with full fidelity

## Background

HeadMusic can render a `Composition` outward to notation formats (`#to_abc`, `#to_musicxml`, `#to_s`) and read *inward* from ABC (`HeadMusic::Notation::ABC.parse`). What's missing is a canonical, round-trippable **serialization of the object itself** — a structured form that captures everything the model holds and rebuilds an equivalent object.

This is distinct from the notation-format work under the [Notation Module epic](../epics/notation-module.md). ABC, MusicXML, and LilyPond are engraving/interchange formats — each lossy relative to the in-memory object (tick-precise positions, voice roles, comments, and mid-piece changes don't all survive an ABC round trip). This story is about **persistence fidelity**, not notation: a JSON-able hash that is the source of truth from which notation formats can be regenerated.

**Driving consumer.** The bardtheory app is adding a Staff Notation View. It will store `Composition` records in its database — a JSON `definition` column as the source of truth, plus a cached MusicXML render — and reference them by slug in lesson content. It needs `#to_h` / `.from_h` to persist and reload compositions. This serialization is a hard prerequisite for that story; bardtheory pins `head_music` from RubyGems (currently `~> 15.1`), so a released version carrying these methods is the deliverable.

## Example

```ruby
composition = HeadMusic::Notation::ABC.parse(abc)   # or built any other way
hash        = composition.to_h                      # plain, JSON-safe Hash

restored    = HeadMusic::Content::Composition.from_h(hash)
restored.to_h       == composition.to_h             # => true
restored.to_musicxml == composition.to_musicxml     # => true
```

## Acceptance Criteria

- `HeadMusic::Content::Composition#to_h` returns a plain, JSON-serializable Hash — only `Hash`/`Array`/`String`/`Integer`/`Float`/`true`/`false`/`nil`; no symbols as values and no custom objects.
- `HeadMusic::Content::Composition.from_h(hash)` reconstructs an equivalent Composition using the existing public construction API (`new`, `add_voice`, `Voice#place`, `change_key_signature`, `change_meter`, `add_comment`) — not private state, where the public builders suffice.
- **Round-trip identity:** for any Composition `c`, `Composition.from_h(c.to_h).to_h == c.to_h`, and both `#to_musicxml` and `#to_abc` output match the original.
- **JSON-safety:** `Composition.from_h(JSON.parse(c.to_h.to_json))` round-trips unchanged (guards against non-JSON values leaking into the hash).
- The hash captures full model fidelity, at minimum:
  - Composition attributes: `name`, `key_signature`, `meter`, `composer`, `origin`, `comments`.
  - Voices with their `role` and ordered placements.
  - Placements: `position` at full precision including tick offsets (`"1:1:480"`, not rounded to the beat grid), `rhythmic_value`, and `pitch` as a pitch-name string — with `nil` preserved as a rest.
  - Chords (simultaneous pitches at a position).
  - Mid-piece `change_key_signature(bar, ...)` and `change_meter(bar, ...)`.
  - Comments (`add_comment(text, position = nil)`, and the constructor's `comments:` string-or-array form).
- Pitch spellings/accidentals round-trip faithfully (preserve the object's exact pitch string; don't normalize enharmonics).
- The hash carries a `schema_version` so the format can evolve.
- Specs cover: single-voice diatonic, accidentals, rests, chords, multi-voice with roles, tick-precise positions, a mid-piece key change, a mid-piece meter change, comments, and a round trip seeded from existing ABC fixtures (e.g. `ABCFixtures::SPEED_THE_PLOUGH`).

## Notes

**Existing construction/serialization surface** (verified in the current codebase):

- Constructor: `Composition#initialize(name:, key_signature:, meter:, composer:, origin:, comments:)` (`lib/head_music/content/composition.rb:8`); `key_signature`/`meter` coerce from strings via `KeySignature.get` / `Meter.get`.
- Builders: `#add_voice(role:)` (`composition.rb:16`), `Voice#place(position, rhythmic_value, pitch = nil)` (`lib/head_music/content/voice.rb:19`), `#add_comment` (`composition.rb:21`), `#change_key_signature(bar_number, key_signature)` (`composition.rb:44`), `#change_meter(bar_number, meter)` (`composition.rb:48`).
- Existing serializers: `#to_abc` (`composition.rb:72`), `#to_musicxml` (`composition.rb:76`), `#to_s` (`composition.rb:68`). No `to_h`/`as_json`/`deconstruct` exists today; the only importer is ABC.

**Suggested hash shape** (illustrative — adjust to the real model):

```ruby
{
  "schema_version" => 1,
  "name" => "…",
  "key_signature" => "C major",
  "meter" => "4/4",
  "composer" => nil,
  "origin" => nil,
  "comments" => [{ "text" => "…", "position" => "1:1" }],
  "key_changes" => [{ "bar" => 5, "key_signature" => "G major" }],
  "meter_changes" => [{ "bar" => 9, "meter" => "3/4" }],
  "voices" => [
    {
      "role" => "melody",
      "placements" => [
        { "position" => "1:1",     "rhythmic_value" => "quarter", "pitch" => "C4" },
        { "position" => "1:1:480", "rhythmic_value" => "eighth",  "pitch" => "E4" },
        { "position" => "1:2",     "rhythmic_value" => "quarter", "pitch" => nil  }
      ]
    }
  ]
}
```

**Design preferences.**

- Prefer composing `#to_h` from smaller `#to_h` methods on `Voice`, `Placement`, etc. if that fits the codebase style, rather than one monolithic method.
- Round-trip via strings where constructors already coerce them (key signature, meter, pitch) to avoid instantiating value objects in the hash.
- No new runtime dependencies; pure Ruby / stdlib.

**Serialization layering — `to_h`/`from_h` is the primitive; JSON is thin sugar.**

The expensive work is Composition↔hash (walking voices/placements/positions/changes/comments and rebuilding via the builder API). Hash↔JSON-string is trivial (`JSON.generate`/`JSON.parse`), so a JSON API is not a lighter lift — it's the same work plus a string layer. Keep `to_h`/`from_h` as the source of truth and, if convenient, add `to_json`/`from_json` as one-line delegates:

```ruby
def to_h; ...; end                                  # the real primitive
def to_json(*args) = to_h.to_json(*args)            # optional string/API-boundary sugar
def self.from_h(hash); ...; end                     # the real primitive
def self.from_json(str) = from_h(JSON.parse(str))   # optional one-liner
```

Rationale for hash-first, not JSON-string-first:

- **Postgres json/jsonb wants the hash, not a string.** The driving consumer stores `definition` in a jsonb column; ActiveRecord serializes/deserializes a Ruby `Hash` to/from jsonb automatically (`record.definition = comp.to_h`; `Composition.from_h(record.definition)`). It never handles a JSON string. Returning a JSON string instead would force AR to re-parse it, or push the caller to a plain `text` column and forfeit jsonb indexing/query — strictly worse for this path.
- **Ruby convention.** Idiomatic `to_json` is built on top of `to_h`/`as_json`; there is no standard `from_json` (the convention is `JSON.parse` → build from hash). The delegates above follow that.
- **Keep the primitive named `to_h`, not `as_json`.** `as_json` is the ActiveSupport hook; `to_h` stays framework-neutral, which suits a plain gem, and jsonb columns consume it just as happily.

So: add `to_json`/`from_json` as optional conveniences for string/HTTP boundaries, but they carry no weight for the DB storage path — that path is pure hash.

**Open questions for planning.**

- Exact key names and nesting (e.g. inline `key_changes`/`meter_changes` vs. a per-bar structure).
- How chords are represented in the placement list (grouped array vs. repeated positions) — follow whatever the model already does internally.
- Whether `from_h` should tolerate/upgrade older `schema_version`s, or hard-fail on mismatch for v1.

## Implementation Plan

### Overview

Add `#to_h` methods to `Placement`, `Comment`, `Bar`, and `Voice`, composed by `Composition#to_h`, plus `Composition.from_h` that replays the hash through the existing public builder API in dependency order (key/meter changes → voices/placements → repeat flags → comments) — the same access path the ABC parser uses (`lib/head_music/notation/abc/parser.rb:250-265`). Three small prerequisite fixes make the round trip actually lossless: tied `RhythmicValue` string parsing (confirmed silent-loss bug), coercing `Bar` writers, and stable placement ordering. Ships as gem 15.2.0 for the bardtheory `~> 15.1` pin.

### Finalized hash schema (schema_version 1)

All keys are strings; all values are JSON primitives. `voices`, `bars`, and `comments` are always present (possibly `[]`). Placement and comment hashes always include all their keys (`pitch`/`position` may be `null`); top-level `composer`/`origin` emit `null` explicitly — schema stability over compactness. `bars` is sparse: only bars with non-default state appear, each carrying `number` plus only the keys that are set.

```json
{
  "schema_version": 1,
  "name": "Speed the Plough",
  "key_signature": "G major",
  "meter": "4/4",
  "composer": null,
  "origin": null,
  "voices": [
    {
      "role": "melody",
      "placements": [
        {"position": "1:1:000", "rhythmic_value": "eighth", "pitch": "G4"},
        {"position": "1:1:480", "rhythmic_value": "eighth", "pitch": null},
        {"position": "3:1:000", "rhythmic_value": "quarter", "pitch": "C5"},
        {"position": "3:1:000", "rhythmic_value": "quarter", "pitch": "E5"}
      ]
    }
  ],
  "bars": [
    {"number": 1, "starts_repeat": true},
    {"number": 5, "key_signature": "D major", "meter": "6/8"},
    {"number": 8, "ends_repeat_after_num_plays": 2, "plays_on_passes": [1, 2]}
  ],
  "comments": [
    {"text": "First strain", "position": "1:1:000"},
    {"text": "Traditional", "position": null}
  ]
}
```

Value formats — each chosen because the corresponding constructor verifiably coerces the string back:

| Field | Format | Round-trip vehicle |
|---|---|---|
| `key_signature` (top-level and per-bar) | `KeySignature#name`, e.g. `"F♯ minor"` — **never** `#to_s`, which returns the unparseable `"3 flats"` | `KeySignature.get` (splits tonic + scale type, `key_signature.rb:14-22`); `#name` is always `"<tonic> <parent-scale-type>"` because construction normalizes to the parent type |
| `meter` | `Meter#to_s`, e.g. `"6/8"` | `Meter.get` (verified) |
| `position` | `Position#to_s`, e.g. `"1:1:480"` (tick zero-padded to 3) | `Position.new(composition, string)` (verified) |
| `rhythmic_value` | `RhythmicValue#to_s`, e.g. `"dotted quarter"`, `"half tied to eighth"` | `RhythmicValue.get` (after Step 1 fix) |
| `pitch` | `Pitch#to_s` with unicode accidentals (`"B♭3"`, `"F𝄪5"`); `null` = rest | `Pitch.get` (verified for unicode; note `"F##5"` returns nil — always emit `#to_s`) |
| `role` | `role&.to_s` or `null` | `add_voice(role:)`; `cantus_firmus?` already matches on `role.to_s`, so symbol→string is behavior-preserving |

### Resolution of the story's open questions (with evidence)

1. **Key names/nesting for changes:** a single sparse `"bars"` array, not separate `key_changes`/`meter_changes`. Evidence: `Bar` (`lib/head_music/content/bar.rb`) holds key signature, meter, *and* repeat structure (`starts_repeat`, `ends_repeat_after_num_plays`, `plays_on_passes`) together — and repeats, though absent from the story's fidelity list, are **forced into scope**: `ABC.parse(ABCFixtures::SPEED_THE_PLOUGH)` sets `starts_repeat` on bar 1 and `ends_repeat_after_num_plays = 2` on bar 8 (verified), so the required `to_abc`-equality criterion fails without them.
2. **Chords:** the model's only chord representation is multiple co-positioned placements in one voice (the ABC lexer treats `[...]` chords as unsupported tokens, `body_lexer.rb:175-176`). No special schema structure needed — the ordered placement list with duplicate `position` values covers it. Caveat: `to_musicxml` currently raises `RenderError` on exactly this structure (verified), so the MusicXML-equality criterion is scoped to compositions MusicXML can render (see Risks).
3. **schema_version policy:** hard-fail. `raise ArgumentError, "unsupported schema_version: #{version.inspect} (supported: 1)"` unless strictly `Integer` `1` (reject `"1"`; `.inspect` disambiguates). Unknown *keys* are ignored, so additive v1.x evolution stays possible. No migration machinery until a v2 exists.
4. **Position string parsing:** exists and round-trips — `Position#to_s` emits `"bar:count:tick"` and the constructor parses it by splitting on `/\D+/` (`position.rb:12-19`). Two verified constraints shape `from_h`: (a) parsing rolls counts/ticks over via `composition.meter_at`, so **meter changes must be applied before any position string parses**; (b) negative bars don't survive (`"-1:1:000"` reparses as `[0,1,1]`) — bar 0 does — so `from_h` rejects bar numbers below 0. (Integer `{bar, count, tick}` components were considered for jsonb queryability; strings win on story alignment and compactness given (a) and (b) are handled.)
5. **Comments:** `Comment` stores text plus an optional `Position` (accepts strings; raises on a foreign composition's Position). The constructor's `comments:` param is **text-only** (`composition.rb:13`), so `from_h` must use `add_comment(text, position)` for every comment; `to_h` always converges both input shapes to `[{"text" => ..., "position" => ... | null}]`.

### Steps

1. **Fix tied `RhythmicValue` string parsing (prerequisite — confirmed silent-loss bug)**
   - `RhythmicValue.get("half tied to eighth")` currently drops the tie and returns plain `half`, while the ABC duration resolver produces tied values (`abc/duration_resolver.rb:67-73`) — any ABC-seeded composition with a cross-unit duration would serialize lossily and *pass* naive specs. In `.get`'s String branch, split on `" tied to "` and rebuild recursively (`new(head.unit, dots: head.dots, tied_value: tail)`).
   - Spec: `get(rv.to_s) == rv` for single and chained ties.
   - Files: `lib/head_music/rudiment/rhythmic_value.rb`, `spec/head_music/rudiment/rhythmic_value_spec.rb`

2. **Coerce `Bar#key_signature=` / `#meter=` writers**
   - They are plain `attr_accessor`s (`bar.rb:9`), so `change_meter(4, "6/8")` stores a raw String, which then breaks `Position` rollover (`meter.ticks_per_count`) and `Bar#to_h`. Replace with writers that call `KeySignature.get` / `Meter.get` when non-nil, mirroring `Bar#initialize` — backward compatible since objects pass through `.get` unchanged.
   - Files: `lib/head_music/content/bar.rb`, `spec/head_music/content/bar_spec.rb`

3. **Make `Voice` placement ordering stable**
   - `insert_into_placements` re-sorts with `Placement#<=>` comparing position only; Ruby's sort is unstable, so chord-note order is officially nondeterministic — and the chord round-trip criterion makes order load-bearing. Replace the sort with stable insertion: `index = @placements.index { |existing| existing > placement } || @placements.length; @placements.insert(index, placement)`. Do **not** add a tie-breaker to `Placement#<=>` (position-only comparison is used semantically elsewhere).
   - Files: `lib/head_music/content/voice.rb` (lines 149-152), `spec/head_music/content/voice_spec.rb` (co-positioned chord ordering example)

4. **Harden `Composition#bars` for bar numbers below `earliest_bar_number`**
   - Verified: `change_key_signature(0, ...)` on a composition without bar-0 placements raises `NoMethodError` on `nil`. One-line fix: iterate/slice from `[earliest_bar_number, last].min`.
   - Files: `lib/head_music/content/composition.rb` (lines 36-42), `spec/head_music/content/composition_spec.rb`

5. **Leaf `#to_h` methods**
   - `Placement#to_h` → `{"position" => position.to_s, "rhythmic_value" => rhythmic_value.to_s, "pitch" => pitch&.to_s}`
   - `Comment#to_h` → `{"text" => text, "position" => position&.to_s}`
   - `Bar#to_h` → sparse hash without `number` (Bar doesn't know its own number): each of key_signature (via `#name`), meter, `starts_repeat`, `ends_repeat_after_num_plays`, `plays_on_passes` only when set; `{}` for a default bar
   - `Voice#to_h` → `{"role" => role&.to_s, "placements" => placements.map(&:to_h)}`
   - Files: `lib/head_music/content/placement.rb`, `comment.rb`, `bar.rb`, `voice.rb`; unit examples in the four existing spec files under `spec/head_music/content/`

6. **`Composition#to_h` + `SCHEMA_VERSION = 1`**
   - Assemble the schema; `key_signature.name`, `meter.to_s`. For bars, do **not** use the public `bars` method (it returns a slice, losing the number offset, and stops at `latest_bar_number`); use a private helper over the raw `@bars` array: `each_with_index.filter_map { |bar, number| ... {"number" => number}.merge(bar.to_h) unless bar.nil? || bar.to_h.empty? }`.
   - Files: `lib/head_music/content/composition.rb`, `spec/head_music/content/composition_spec.rb`

7. **`Composition.from_h` + `to_json`/`from_json` delegates**
   - Entry: raise `ArgumentError` on non-Hash; `deep_transform_keys(&:to_s)` (ActiveSupport is already a runtime dependency) so symbol-keyed Ruby hashes also load; strict `schema_version` check per Resolution 3.
   - Four phases, each load-bearing:
     1. `new(name:, key_signature:, meter:, composer:, origin:)` then `change_key_signature`/`change_meter` per bar entry — **before any position parses** (meter map drives count/tick rollover).
     2. `add_voice(role:)` + `voice.place(position, rhythmic_value, pitch)` in serialized order (stable insertion from Step 3 preserves chord order).
     3. Repeat flags via `composition.bars(number).last` + Bar's validating public setters — **after placements**, so a pickup-bar-0 flag finds its bar.
     4. `add_comment(text, position)` last (positions parse under the final meter map).
   - **Boundary validation (verified failure modes):** `Pitch.get("garbage")` returns nil — a corrupted pitch would silently deserialize as a *rest*; `RhythmicValue.get("garbage")` returns a broken object that explodes later; `Meter.get("garbage")` raises a useless internal arity error. `from_h` must validate factory results and raise `ArgumentError` with path context (e.g. `voices[0].placements[3]: unknown pitch "H#4"`), and reject bar numbers `< 0`. `ArgumentError` matches the content module's existing convention (`bar.rb`, `comment.rb`).
   - Delegates: `def to_json(*_args) = to_h.to_json`; `def self.from_json(json) = from_h(JSON.parse(json))`.
   - Files: `lib/head_music/content/composition.rb`

8. **Round-trip spec suite**
   - New file: `spec/head_music/content/composition_serialization_spec.rb` with a shared helper `expect_lossless_round_trip(composition)` asserting `from_h(to_h).to_h == to_h` plus `to_abc` equality (and `to_musicxml` equality where renderable). Scenario matrix in Testing Strategy below.
   - Files: `spec/head_music/content/composition_serialization_spec.rb`

9. **Finish: lint, coverage, release prep**
   - `bundle exec rubocop -a`, `bundle exec rake` (90% coverage gate). Bump to 15.2.0 (minor — bardtheory pins `~> 15.1`). CHANGELOG entry documenting the schema v1 hash as public API: once bardtheory persists it in jsonb, the schema is a compatibility surface independent of gem semver — additive optional keys are fine within version 1 (because `from_h` ignores unknown keys); any change to existing keys' shape or meaning requires a `schema_version` bump.
   - Files: `lib/head_music/version.rb` (or equivalent), `CHANGELOG.md`

### Design Considerations

(No UI surface — this is a pure-Ruby library story; the ui-ux and accessibility perspectives were deliberately skipped.)

- `#to_h` on each content class (alongside existing `#to_s`) matches the gem's value-object style; the Notation precedent of delegating to renderer classes doesn't apply — those translate to foreign formats, while `to_h` is the object's own intrinsic representation. Standard Ruby disables Metrics cops (confirmed), so no cop pressure forces an extracted serializer; extract a builder class from `from_h` only if it exceeds ~5 private helpers.
- Exporter limitations must never leak into the serialization contract: the hash is the source of truth; for compositions MusicXML rejects, `to_h`/`from_h` still round-trips losslessly and `from_h(c.to_h).to_musicxml` raises the same `RenderError`.
- `to_h` is pure aside from idempotently materializing the already-memoized `@bars` (which `meter_at` does anyway); `Hash#==` ignores key order, so specs compare hashes, never `to_json` strings.

### Testing Strategy

| Acceptance criterion | Test |
|---|---|
| JSON-safe hash | Recursive walk asserting only Hash/Array/String/Integer/Float/booleans/nil; string keys only |
| Round-trip + `to_abc`/`to_musicxml` equality | `expect_lossless_round_trip` per scenario below |
| JSON safety | `from_h(JSON.parse(c.to_h.to_json)).to_h == c.to_h`; also covers the `to_json`/`from_json` delegates |
| Single-voice diatonic | `ABC.parse` of a simple tune |
| Accidentals / exact spellings | `ABCFixtures::CHROMATIC_AIR` (also covers composer + origin + minor key); one manual double-sharp placement to prove `𝄪` survives |
| Rests | `voice.place("1:2:000", :quarter)` → `"pitch" => nil` |
| Chords | Two placements at `"1:1:000"` in one voice; order preserved; `to_h` + `to_abc` only (MusicXML raises — documented) |
| Multi-voice with roles | Two `add_voice(role:)` voices, including two voices with the *same* role (voices are an ordered array, never a role-keyed map) |
| Tick-precise positions | Placement at `"1:1:480"`; exact string in hash |
| Mid-piece key change | `change_key_signature(5, "D major")` with a string arg (exercises Step 2 coercion) |
| Mid-piece meter change | `change_meter(3, "6/8")` **with a later placement whose count only parses correctly under 6/8** — locks in the phase-1-before-phase-2 ordering |
| Comments | With position, without position, and constructor `comments:` string/array forms converging |
| ABC fixture seed + repeats | `ABC.parse(ABCFixtures::SPEED_THE_PLOUGH)`: `from_h(to_h).to_abc == original.to_abc` (repeats at bars 1 and 8 are load-bearing) and `to_musicxml` equality |
| Tied durations | ABC note spanning e.g. 5 eighths round-trips (Step 1 fix) |
| schema_version | Present, `== 1`; `from_h` raises ArgumentError on missing / `2` / `"1"` |
| Malformed input | Non-Hash, unknown pitch string, unknown rhythmic value, negative bar number → `ArgumentError` with path context, never `NoMethodError` |
| Edge cases | Empty composition (`voices: []`, compare `to_h` only — `to_musicxml` raises "no voices" on both sides); voice with role but zero placements; `plays_on_passes: [1, 2]` volta bars; unknown top-level key ignored; `"name" => nil` vs `"name" => "Composition"` produce `to_h`-identical results (pinned as documented equivalence) |

Unit-level `#to_h` examples extend the existing mirrored specs: `composition_spec.rb`, `voice_spec.rb`, `placement_spec.rb`, `bar_spec.rb`, `comment_spec.rb`, `rhythmic_value_spec.rb`.

### Risks & Open Questions

**Risks / edge cases**

- **Tied-duration bug is the stealthiest failure**: without Step 1, ABC-seeded hashes are silently lossy and round-trip specs that avoid tied durations still pass. It's first in the step order deliberately.
- **Chords vs `to_musicxml`**: the MusicXML-equality criterion is scoped to renderable compositions (same-voice chords raise `RenderError` today). Fixing MusicXML chord rendering is a separate story — resist coupling it here; bardtheory's cached-render path works today for what it renders, and this story blocks their release.
- **Phase ordering in `from_h` is load-bearing** (meters before placements; placements before repeat flags; comments last). The 6/8 meter-change spec pins it against regression.
- **Negative bar numbers** don't survive position strings (`"-1:1:000"` → bar 0) and would index `@bars` from the tail; v1 declares bar ≥ 0 as the supported domain and `from_h` rejects below that. Nothing in the ABC parser produces negatives today.
- **Silent factory nils**: `Pitch.get` returning nil turns corrupted pitches into rests; only the Step 7 boundary validation prevents wrong-music-no-error outcomes on drifted jsonb rows.
- **Schema-as-API discipline**: after bardtheory persists hashes, schema v1 is a public contract. `from_h` ignoring unknown keys is what keeps additive evolution possible; hold that line in review.

**Open questions — resolved by the user (2026-07-16)**

1. **Unicode vs ASCII key/pitch strings**: **Unicode verbatim.** Serialize `KeySignature#name` (`"F♯ minor"`) and `Pitch#to_s` (`"B♭3"`) exactly as emitted; pin with a spec.
2. **Repeats formally in scope**: **In scope.** Bar-level repeat structure (`starts_repeat`, `ends_repeat_after_num_plays`, `plays_on_passes`) serializes in the sparse `"bars"` array; the SPEED_THE_PLOUGH `to_abc` criterion stands as written.
3. **`schema_version` strictness**: **Strict Integer.** `from_h` raises `ArgumentError` on `"1"`, `2`, or missing.

## Review

**Date:** 2026-07-16 · **Commit reviewed:** 5b0fd0a · Full suite: 5640 examples, 0 failures, 99.73% line coverage.

### Acceptance criteria

- ✅ **`#to_h` returns a plain JSON-serializable Hash** — `lib/head_music/content/composition.rb:91-103`; recursive-walk assertion in `composition_serialization_spec.rb:20-34`.
- ✅ **`.from_h` rebuilds via the public construction API** — `HashDeserializer` (`composition.rb:152-301`) replays `new` → `change_key_signature`/`change_meter` → `add_voice` + `Voice#place` → public `Bar` repeat setters → `add_comment`; no private state touched.
- ⚠️ **Round-trip identity incl. `to_musicxml`/`to_abc` equality** — *scoped-met*: `from_h(c.to_h).to_h == c.to_h` holds universally; renderer-output equality is asserted wherever the renderers can render. ABC comparison skipped for multi-voice, mid-piece changes, and chords; MusicXML for same-voice chords and empty compositions — pre-existing renderer limitations, not serialization loss. Compensating specs pin that the restored composition raises the identical `RenderError`. The literal "for any Composition" is unsatisfiable without separate renderer fixes.
- ✅ **JSON-safety round trip** — `from_h(JSON.parse(c.to_h.to_json)).to_h == c.to_h` plus `to_json`/`from_json` delegates (`composition_serialization_spec.rb:73-82`).
- ✅ **Full model fidelity** — attributes, voices with roles + ordered placements, tick-precise positions, tied rhythmic values, nil-pitch rests, chords as co-positioned placements, mid-piece key/meter changes and repeat/volta state in sparse `"bars"`, comments in both builder and constructor forms.
- ✅ **Pitch spellings round-trip faithfully** — enharmonics not normalized (`B♭4` vs `A♯4`); double sharp `F𝄪5` and `"F♯ minor"` verbatim unicode.
- ✅ **`schema_version` carried** — `SCHEMA_VERSION = 1`; strict-Integer validation raising `ArgumentError` on missing/`2`/`"1"`.
- ✅ **Spec coverage of all listed scenarios** — all ten present in `composition_serialization_spec.rb` (single-voice diatonic L85, accidentals L102 via `CHROMATIC_AIR`, rests L168, chords L190, multi-voice roles L216, tick positions L238, key change L259, meter change with phase-ordering pin L279, comments L314, `SPEED_THE_PLOUGH` round trip with repeats L349), plus tied durations, malformed input, and edge cases beyond the list.

**Deliverable note:** version bumped to 15.2.0 with CHANGELOG documenting schema v1 as a compatibility surface, but publishing to RubyGems is a manual step outside this branch.

### Code review findings

**Critical:** none.

**Important:**

1. ✅ **FIXED** — `composition.rb` — **invalid key signature slips through validation.** `KeySignature.get("Q major")` returns a hollow object (`tonic_spelling=nil`) rather than nil, passing the truthiness guard. Fixed: `parsed_key_signature` now requires `tonic_spelling`; corrupted-input specs added (top-level and per-bar).
2. ✅ **FIXED** — `composition.rb` — **position strings never validated.** `Position.new` silently coerces garbage to `"0:1:000"`. Fixed: new `parsed_position` helper validates the `bar[:count[:tick]]` shape (non-negative parts) for placements and comments; specs added for garbage, negative-bar, and comment positions.

**Minor:**

3. `composition.rb` — repeat flags accept any truthy value (string `"yes"` acts as `true`); harmless for real JSON (booleans survive), inconsistent with otherwise-strict validation. Accepted as-is.
4. ✅ **FIXED** — corrupted-input spec block lacked invalid-key-signature and invalid-position cases; five specs added alongside findings 1–2.

**Verified non-issues:** `to_json(*_args)` nests correctly in `{a: composition}.to_json`; stable chord insertion correct; `from_tied_words` recursion terminates; `to_h` leaks no mutable state; pickup-bar reindexing consistent.

**Verdict:** solid, well-tested feature. Findings 1–2 (and the spec gap, finding 4) fixed post-review; full suite 5645 examples, 0 failures, 99.73% line coverage. Nothing blocks `finish` except the manual RubyGems release.
