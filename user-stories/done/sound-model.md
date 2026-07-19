<!--
metadata:
  created_at:   2026-07-18T14:27:34-07:00
  activated_at: 2026-07-18T14:45:00-07:00
  planned_at:   2026-07-18T14:53:12-07:00
  finished_at:  2026-07-18T17:03:23-07:00
  updated_at:   2026-07-18T17:03:23-07:00
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

The instruments catalog already provides everything a *named* unpitched sound needs: `Instruments::Instrument.get` resolves names with spaces, casing, and aliases ("tabor" → snare_drum, "kick_drum" → bass_drum), and instrument names are localized in every locale. `UnpitchedSound` optionally wraps a catalog instrument rather than holding a free-form string. The instrument is optional in both directions: a generic hit needs no instrument (rhythm-only lines, clapped cues), and the instrument may be a *pitched* one — percussive hits on pitched instruments (a slap on a violin body, a knock on a piano lid) are valid music. Unpitchedness is a property of the sound, not of the instrument that makes it.

## Scope

- New rudiment `HeadMusic::Rudiment::UnpitchedSound`: an unpitched sound, optionally made on a catalog instrument. `.get` with no argument (or nil) returns the generic instrument-less sound (a singleton; displays as "unpitched"). `.get` with an `Instrument` or a name/alias resolves through `Instruments::Instrument.get` and returns nil for names not in the catalog. The instrument may be pitched or unpitched — a percussive hit on a violin is a valid `UnpitchedSound`. `pitched?` returns false unconditionally: unpitchedness describes the sound, not the instrument. Identity, equality, and hashing key on the instrument's `name_key` (nil for the generic sound), so aliases collapse (`get("tabor") == get("snare drum")`) and generic hits deduplicate with each other but never with instrument-backed ones. Localization comes free from the wrapped instrument; no `Named` include.
- A minimal shared sound interface: `Pitch#pitched?` returns true, `UnpitchedSound#pitched?` returns false, both stringify and compare by value.
- `Placement#sounds` (frozen array) becomes the source of truth. `pitches` becomes the pitched subset of `sounds`; `pitch` remains the highest pitch (nil when there are no pitched sounds).
- `Voice#place` accepts a single sound, an array of sounds, or resolvable values; mixed pitched/unpitched placements are allowed (e.g. kick drum under a bass note). Bare values resolve **pitch first, then unpitched instrument**: `"C4"` is a pitch, `"snare drum"` is an unpitched sound. A bare *pitched*-instrument name (`"violin"`) still raises — auto-converting it to a body-hit would be too surprising a reading of an ambiguous input — but the tailored message now offers both intents: place a pitch such as `"D4"`, or pass `UnpitchedSound.get("violin")` explicitly for a percussive hit. Any other unresolvable value raises a plain "unknown sound" `ArgumentError`. This retires the old quiet-rest leniency for unparseable values; nil (or omission) remains the way to place a rest.
- Predicates:
  - `rest?` — no sounds
  - `sounded?` — one or more sounds (matches `RhythmicElement#sounded?`)
  - `note?` — exactly one sound, pitched or not
  - `pitched_note?` — exactly one sound, and it is pitched
  - `unpitched_note?` — exactly one sound, and it is unpitched
  - `chord?` — two or more *pitched* sounds
  - `pitched?` — one or more pitched sounds; `Voice#notes` selects pitched placements so melodic and style analysis are unaffected by percussion content
  - Note: `rest?`/`note?`/`chord?` are no longer exhaustive — a multi-sound placement with at most one pitched sound (kick + snare; C4 + kick) is neither a note nor a chord. It is still `sounded?`, and `pitched?` tells you whether analysis sees it. A chord is inherently pitched; simultaneous drum hits are a simultaneity, not a chord.
- Serialization moves to schema version 3: each placement serializes a `"sounds"` array whose elements are either a pitch string (`"C4"`) or an object keyed by the instrument's canonical `name_key` (`{"unpitched": "snare_drum"}`), so aliases round-trip deterministically. The generic instrument-less sound serializes as `{"unpitched": null}`. `from_h` accepts only v3, retiring v2 (consistent with retiring v1 in the Chord Placement Model story).
- The ABC and MusicXML writers raise `RenderError` on unpitched sounds until percussion rendering stories exist (consistent with the former raise-on-chord guard).
- Rewrite the dependent backlog stories (ABC Chord Input, MusicXML Chord Rendering) against the sounds model.

## Example

```ruby
composition = HeadMusic::Content::Composition.new(name: "Example", meter: "4/4")
voice = composition.add_voice(role: "percussion and melody")

voice.place("1:1", :quarter, "C4")                 # note
voice.place("1:2", :quarter, ["C4", "E4", "G4"])   # chord
voice.place("1:3", :quarter, "snare drum")         # unpitched hit, via instrument lookup
voice.place("1:4", :quarter)                       # rest

voice.place("2:1", :quarter, HeadMusic::Rudiment::UnpitchedSound.get)            # generic hit, no instrument
voice.place("2:2", :quarter, HeadMusic::Rudiment::UnpitchedSound.get("violin"))  # percussive hit on a pitched instrument

voice.place("2:3", :quarter, "violin")             # ArgumentError: pitched instrument — place a pitch, or UnpitchedSound.get("violin") for a hit
voice.place("2:3", :quarter, "H4")                 # ArgumentError: unknown sound

voice.placements.map { |p| [p.sounds.map(&:to_s), p.note?, p.pitched?] }
# => [[["C4"], true, true],
#     [["C4", "E4", "G4"], false, true],
#     [["snare drum"], true, false],
#     [[], false, false]]

composition.to_h["voices"].first["placements"][2]
# => { "position" => "1:3:000", "rhythmic_value" => "quarter",
#      "sounds" => [{ "unpitched" => "snare_drum" }] }

composition.to_h["voices"].first["placements"][4]
# => { "position" => "2:1:000", "rhythmic_value" => "quarter",
#      "sounds" => [{ "unpitched" => nil }] }
```

## Acceptance Criteria

- `HeadMusic::Rudiment::UnpitchedSound` exists; `.get` with no argument returns the generic instrument-less sound; `.get` with a name resolves names and aliases through `Instruments::Instrument.get` (pitched instruments allowed) and collapses aliases to one identity (`get("tabor") == get("snare drum")`); `pitched?` returns false unconditionally; `Pitch#pitched?` returns true
- `Placement#sounds` holds the placement's sounds; `pitches` returns the pitched subset; `pitch` returns the highest pitch or nil
- `Voice#place` accepts a pitch, an unpitched sound (generic, unpitched-instrument, or pitched-instrument backed), or a mixed array; bare strings resolve pitch-first, then unpitched-instrument; unresolvable values raise `ArgumentError`, with a tailored message for bare pitched-instrument names that offers both the pitch and the explicit-`UnpitchedSound` intents
- `rest?`, `sounded?`, `note?`, `pitched_note?`, `unpitched_note?`, `chord?`, and `pitched?` behave as defined in Scope, and `Voice#notes` (melodic/style analysis) ignores placements with no pitched sounds
- `Composition#to_h` emits schema version 3 with a `"sounds"` array per placement, unpitched sounds serialized by canonical `name_key` (nil for the generic sound); `from_h` round-trips v3 (including alias-input compositions and generic hits) and rejects v2 with a clear `ArgumentError`
- The ABC and MusicXML writers raise `RenderError` when asked to render an unpitched sound
- The ABC Chord Input and MusicXML Chord Rendering backlog stories are rewritten against the sounds model
- Rubocop and all specs pass

## Implementation Plan

### Overview

Introduce `HeadMusic::Rudiment::UnpitchedSound` as a value object wrapping an unpitched catalog instrument, generalize `Placement`'s frozen `pitches` array into a frozen `sounds` array (with `pitches` as the derived pitched subset), repartition the predicates, bump serialization to schema v3 (retiring v2, per the v1 precedent in commit 2a33c9f), and guard both writers against unpitched sounds. The `note?` semantic change (any pitches → exactly one sound) and the `Voice#notes` switch to pitched selection must land together — that pairing is the sharpest edge in the story.

### Decisions

1. **Merge/dedup semantics**: same instrument = same sound. `UnpitchedSound` defines the full value trio — `==`, `eql?`, `hash` — on the wrapped instrument's `name_key` (nil for the generic instrument-less sound), so `uniq` in `Placement#merge` works regardless of instance provenance and aliases collapse (`get("tabor")` deduplicates against `get("snare drum")`); generic hits deduplicate with each other but never with instrument-backed sounds. Merging a pitched placement into an unpitched one at the same position produces a mixed placement; re-merging the same instrument is idempotent (mirrors today's pitch `uniq`). `Pitch` and `UnpitchedSound` never compare equal, and no cross-type `<=>` is defined (no musical ordering exists; a mixed `sounds.sort` should fail honestly).

2. **Value resolution in `Voice#place`**: pitch first, then unpitched instrument, else `ArgumentError`. `Pitch.get` is strict about non-pitch words (`"cowbell"`, `"clap"` → nil, verified), so the pitch-first ordering is safe. Bare strings resolve only to *unpitched*-instrument sounds even though `UnpitchedSound` itself accepts pitched instruments: a bare pitched-instrument name (`"violin"`) raises with a tailored message offering both intents ("violin is a pitched instrument; place a pitch such as \"D4\", or pass UnpitchedSound.get(\"violin\") for a percussive hit"), detected by consulting `Instrument.get` in the error path. Explicit `UnpitchedSound` and `Instrument` arguments carry unambiguous intent and are never second-guessed. This **retires the quiet-rest leniency** pinned at `spec/head_music/content/placement_spec.rb:236-239` — that spec flips to expect `ArgumentError`; nil remains the rest input. (Pre-existing `Pitch.get` leniency such as `"A44"` → A4 is out of scope and unchanged.)

3. **Ripple** (verified by grep; the complete production list): `lib/head_music/content/voice.rb:29` (`#notes`, means "pitched" → `pitched?`), `lib/head_music/notation/music_xml/writer.rb:324` (pitch-vs-rest branch → `pitched?`), `spec/head_music/notation/music_xml/writer_spec.rb:10` (helper means "sounded" → `sounded?`). Non-issues: `style/guidelines/prepare_octave_leaps.rb:35,42` and `analysis/melodic_interval.rb:62` call `pitches` on `MelodicNotePair`/`MelodicInterval`, not on Placement; `Content::Note` wraps a single-pitch placement, still `note?` (and `pitched_note?`) under the new definitions; `delegate :spelling, to: :pitch, allow_nil: true` is already nil-safe.

4. **`UnpitchedNote` recomposition: defer.** The `RhythmicElement` hierarchy is unused by Content. Add a one-line comment on `UnpitchedNote` naming `UnpitchedSound` as the intended composition target so the near-duplicate name handling reads as planned, not accidental.

5. **No `HeadMusic::Named` on `UnpitchedSound`; localization is delegated.** The wrapped `Instruments::Instrument` already includes Named and has locale entries in every language, so `UnpitchedSound` gets display names and i18n for free by delegating to the instrument. Adding Named directly would duplicate that machinery. (`UnpitchedNote`'s Named include is vestigial — it shadows Named's `name` and has no locale keys — precedent to avoid, not follow.)

6. **Layering note**: `Rudiment::UnpitchedSound` referencing `Instruments::Instrument` inverts the usual Instruments→Rudiment dependency direction. The reference is runtime-only (inside `.get`), so no load-order or circular-require problem exists; Ruby resolves the constant at call time. Accepted as a documented trade-off — the sound *concept* is a rudiment even though its vocabulary lives in the instruments catalog.

7. **Test strategy** is folded into steps 1-6 below; the 90% floor is safe because every new branch gets direct coverage.

### Steps

1. **New rudiment: `UnpitchedSound`, plus the `Pitch` half of the sound interface**

   - Create `lib/head_music/rudiment/unpitched_sound.rb`: subclass of `HeadMusic::Rudiment::Base`. `.get` (no argument, or nil) returns the generic instrument-less singleton — frozen, `instrument` nil, `name_key` nil, displays as "unpitched". `.get(value)` returns the argument if already an `UnpitchedSound`; otherwise resolves via `Instruments::Instrument.get(value)` and returns nil when the catalog has no match — **pitched instruments are valid** (a hit on a violin body is an unpitched sound). Stores the instrument; exposes `instrument`, `name` (instrument name, or "unpitched"), `name_key` (canonical identity, nil for generic), `to_s` (name). Value trio `==`/`eql?`/`hash` on `[self.class, name_key]`. **No identity cache beyond the generic singleton** — value equality replaces interning (input strings are unbounded; a class-level cache keyed on raw input would grow without limit). `pitched?` returns false unconditionally: it describes the sound, not the instrument.
   - Edit `lib/head_music/rudiment/pitch.rb`: add `pitched?` returning true; guard `from_number` (line 58) with `return nil unless number.respond_to?(:to_i)` — today `Pitch#==` funnels through `Pitch.get`, so `some_pitch == some_unpitched_sound` raises `NoMethodError` instead of returning false.
   - Edit `lib/head_music.rb`: require the new file with the other rudiments; the Instruments reference is runtime-only, so load order is unaffected.
   - New spec `spec/head_music/rudiment/unpitched_sound_spec.rb`: resolution (name, symbol, alias, spaced/cased forms, `Instrument` instance, pitched instruments like "violin"), the generic singleton (`get == get(nil)`, distinct from every instrument-backed sound), nil for unknown names, alias-collapsing equality, hash/eql? for `uniq`, `to_s`, `pitched?` false even when the instrument is pitched, localization via the instrument. New `shared_examples "a sound"` in `spec/support/` pinning the contract (`pitched?`, `to_s`, value equality, `hash`/`eql?`), included from both the new spec and `spec/head_music/rudiment/pitch_spec.rb`. No `Sound` mixin/superclass — the surface is three methods and the house style is duck typing.

2. **Placement: `sounds` as source of truth** (`lib/head_music/content/placement.rb`)

   - `attr_reader :pitches` → `attr_reader :sounds`; `pitches` becomes `sounds.select(&:pitched?)` — computed fresh, **not memoized** (merge reassigns `@sounds`; a memoized subset would go stale). `pitch` stays `pitches.max` (nil when no pitched sounds); update its doc comment (lines 17-20) to state it returns nil for rests and unpitched-only placements, with `pitched?` as the guard.
   - Predicates anchored on the ground truth, never on each other's negation:
     - `rest?` = `sounds.empty?`
     - `sounded?` = `sounds.any?`
     - `note?` = `sounds.length == 1`
     - `pitched_note?` = `note? && pitched?`
     - `unpitched_note?` = `note? && !pitched?`
     - `chord?` = `pitches.length > 1` (pitched count — simultaneous drum hits are not a chord)
     - `pitched?` = `sounds.any?(&:pitched?)`
     - (Defining `rest?` as `!note?` under the new semantics would classify every chord as a rest — the single worst latent bug in this refactor. Note also that `rest?`/`note?`/`chord?` are intentionally non-exhaustive for multi-sound placements with ≤1 pitched sound.)
   - `merge` (line 46): `@sounds = (sounds + other.sounds).uniq.freeze`.
   - `to_s` (line 63): build from `sounds`; bracket unpitched names at the join so multi-word names aren't ambiguous — `"quarter C4 [snare drum] at 2:1"`. Pitch-only output stays byte-identical to today. Sounds keep insertion order (uniq preserves first occurrence); deterministic low-to-high emission remains the MusicXML chord story's job.
   - `ensure_pitches`/`fetch_pitch` (lines 98-109) → `ensure_sounds`/`resolve_sound`: pass through `UnpitchedSound`; wrap explicit `Instruments::Instrument` input via `UnpitchedSound.get` (pitched or not — an explicit instrument is unambiguous intent). For other values: `Pitch.get(value)`, else `UnpitchedSound.get(value)` **only when the matched instrument is unpitched**, else raise `ArgumentError` — the tailored both-intents message when `Instrument.get(value)&.pitched?` (a bare pitched-instrument name), generic "unknown sound" otherwise. The old quiet-rest leniency comment (lines 95-97) is removed with the behavior; nil input still means rest.
   - `to_h` (line 70): `"sounds"` array replacing `"pitches"` entirely — pitch sounds as strings (`"C4"`), unpitched as `{"unpitched" => name_key&.to_s}` (nil for the generic sound).

3. **Voice: analysis chain moves to `pitched?`** (`lib/head_music/content/voice.rb`)

   - Line 29 `#notes`: `@placements.select(&:pitched?).sort_by(&:position)`. This single line keeps every melodic/style consumer (`pitches`, `range`, `melodic_note_pairs`, `melodic_intervals`, all Style guidelines) behaving exactly as today — chords still contribute their top pitch, unpitched-only placements become invisible to analysis, and mixed placements (bass note + kick) are analyzed by their pitch. It also protects the nil-unsafe direct calls downstream (`notes_not_in_key`'s `note.pitch.spelling`, `highest_pitch`'s `pitches.max`). `#rests` keeps `rest?`, correct under the new partition. Must land in the same commit as step 2's predicate change.
   - `#place`: no signature change; rename the `pitch_or_pitches` parameter to `sound_or_sounds`.

4. **Serialization schema v3** (`lib/head_music/content/composition.rb`, `CHANGELOG.md`)

   - `SCHEMA_VERSION = 3` (line 6). `validate_schema_version` (line 173) already rejects v2 with "unsupported schema_version: 2 (supported: 3)"; append a one-line migration hint when the rejected version is 2 — v2's `"pitches"` arrays became v3's `"sounds"` arrays (precedent: the v1 retirement did the same). `parsed_placement_pitches` (line ~326) → `parsed_placement_sounds`: accept exactly two element shapes — a String (via existing `parsed_pitch`, raising on unparseable) or a Hash whose keys are exactly `["unpitched"]` whose value is nil (the generic sound) or a name `UnpitchedSound.get` can resolve, pitched instruments included (raising `ArgumentError` naming the unknown instrument otherwise) — and raise `ArgumentError` with the `voices[i].placements[j].sounds[k]` path for anything else (extra keys, empty-string names, non-string non-nil values). `deep_transform_keys(&:to_s)` at line 156 already normalizes symbol keys from JSON round-trips. Update the v2 references in class comments.
   - `CHANGELOG.md`: Breaking entry mirroring the v2 entry — key rename, v2 rejected, `note?` semantic change and the retired quiet-rest leniency called out explicitly, persisted-jsonb migration caveat.
   - `lib/head_music/version.rb`: bump to `17.0.0` — a major release, per the owner's explicit sign-off on the breaking change (precedent: the chord placement model shipped as 16.0.0).

5. **Writers: RenderError on unpitched**

   - `lib/head_music/notation/abc/writer.rb` `#token` (line 122): raise `RenderError` when any sound is unpitched, **before** the `chord?` guard — a lone unpitched sound passes `rest?` false and would crash `pitch_writer.token(nil)` at line 128; note `chord?` alone no longer catches mixed or multi-unpitched placements now that it counts pitched sounds only. The guard must fire for mixed placements too.
   - `lib/head_music/notation/music_xml/writer.rb` `#note_lines` (line ~313): same guard before the chord guard; line 324's branch changes `placement.note?` → `placement.pitched?`.
   - Both messages follow house style (cf. `abc/key_mapper.rb:48`): name the sound and the position — e.g. `cannot render unpitched sound "snare drum" at 2:1: percussion rendering is not yet supported` — using each format's own `RenderError` class.

6. **Spec updates and new coverage**

   - `spec/head_music/content/placement_spec.rb`: `to_h` fixtures `"pitches"` → `"sounds"` (lines 137, 145, 192, 232); deliberately flip the chord `be_note` expectations (lines 173, 213, 226); flip the quiet-rest leniency block (lines 236-239) to expect `ArgumentError`. New: predicate table covering lone-pitch (`note?`, `pitched_note?`), lone-unpitched (`note?`, `unpitched_note?`, not `pitched?`), pitched chord, two-unpitched and one-pitch-plus-drum placements (neither `note?` nor `chord?`, still `sounded?`), empty; merge dedup across aliases (`"tabor"` merged into `"snare drum"`); unpitched/mixed `to_h` shapes; unpitched `to_s` bracketing; pitched-instrument-name and unknown-string `ArgumentError` messages.
   - `spec/head_music/content/composition_serialization_spec.rb`: ~31 `schema_version` refs 2 → 3; `"pitches"` fixtures → `"sounds"` (lines 106, 132, 158, 180, 230, 487-541); the rejection block (lines 437-465) inverts — v2 becomes the rejected-past case with the migration-hint message asserted, the future-version probe moves to 4. New: unpitched and mixed round-trips (order preserved; alias input `"tabor"` round-trips as canonical `"snare_drum"`; generic `{"unpitched" => nil}` and pitched-instrument-backed `{"unpitched" => "violin"}` round-trip), unknown-instrument and malformed-element errors with path context.
   - `spec/head_music/content/composition_spec.rb` (lines 215-216, 340, 346 + schema refs) and `spec/head_music/content/voice_spec.rb` (fixtures at 372-373; new: `#notes` excludes unpitched-only (including generic and violin-hit placements) but includes mixed placements; `place` accepts `"snare drum"` as a bare string, an `UnpitchedSound` (generic and instrument-backed), an `Instrument` (pitched or not), and a mixed array; `place` raises for bare `"violin"`; same-position merge across pitched/unpitched).
   - Writer specs: RenderError on unpitched (single and mixed) in both writers, message content asserted; regression pin that a two-pitch chord still raises `RenderError` (never silently emits `<rest/>`); fix `music_xml/writer_spec.rb:10`'s helper (`note?` → `sounded?`).
   - Existing style/analysis specs should pass untouched (they build pitched content, mostly via `ABC.parse`).

7. **Rewrite the dependent backlog stories (content-only edits)**

   - `user-stories/backlog/abc-chord-input.md`: Background/Scope reworded from "pitches array" / `"pitches"` key / schema v2 to sounds model / `"sounds"` key / schema v3; state that bracket groups produce all-pitched placements and the unpitched RenderError guard stays. The Ruby examples remain literally correct (`pitches` survives as the pitched subset).
   - `user-stories/backlog/musicxml-chord-rendering.md`: same terminology updates; chord emission defined as one `<note>` per **pitched** sound, low to high, unpitched guard remaining until a percussion-rendering story.

8. **Verification**

   - `bundle exec rspec`, `bundle exec rubocop -a`, `bundle exec rake validate`. Final grep sweeps: `grep -rn "note?" lib spec` (no caller left meaning "sounded"), `grep -rn '"pitches"' lib spec` (no stale fixture keys). Do not commit without an explicit request (project rule).

### Testing Strategy

Behavioral pins carry the story: the shared "a sound" examples define the duck-typed contract; the predicate table and the mixed-placement cases pin the vocabulary boundaries (`note?` vs `pitched_note?` vs `chord?` vs `Voice#notes`); serialization specs pin round-trip shapes, alias canonicalization, and the v2 rejection message; resolution specs pin the pitch-first/instrument-second/ArgumentError routing. The bulk of the diff is mechanical fixture churn in the serialization spec — stale `"pitches"` keys fail loudly, which is acceptable. Coverage floor (90%) is safe: every new branch (resolve_sound paths, v3 element parsing, writer guards, predicates) has direct examples.

### Risks & Open Questions

- **`note?` flips for external consumers.** In-repo call sites are fully enumerated (three), but any downstream code using `note?` to mean "not a rest" changes behavior silently for chords. The CHANGELOG breaking entry is the only mitigation shipped.
- **Catalog-constrained vocabulary, with a generic escape hatch.** A *named* unpitched sound must exist in `instruments.yml` — no free-form names. Coverage today is good (snare, bass drum via "kick_drum" alias, hi-hat, cymbals, triangle, tambourine, cowbell, woodblock) but incomplete (no tom-tom, clap, or rimshot); the generic instrument-less sound covers rhythm-only needs in the meantime, and the extension path is adding catalog entries (with locale strings), which benefits the whole gem.
- **Predicate non-exhaustiveness.** Multi-sound placements with ≤1 pitched sound are neither `note?` nor `chord?`. Safe in-repo because both writers guard unpitched sounds before any note/chord branching; documented in Scope for external consumers.
- **Rudiment→Instruments runtime dependency** (Decision 6): accepted inversion, call-time only.
- **Schema shape lock-in**: `{"unpitched" => "snare_drum"}` is flat; adding future attributes (notehead, playing technique) would cost a v4 bump. Accepted for v1.
- **Convenience input deferred**: `Voice#place` accepts strings, `UnpitchedSound`s, and `Instrument`s, but not `{unpitched: "..."}` hashes — the deserializer constructs instances before replaying, so nothing requires hash acceptance; revisit if REPL ergonomics demand it.

## Review

Reviewed 2026-07-18 at commit `98a0289` (base of `story/sound-model`); **all reviewed changes were uncommitted working-tree changes** on that branch. Reviewers: product-manager (empirical acceptance-criteria verification) and code-reviewer (full-diff quality review). Full suite: 5792 examples, 0 failures; 99.74% line / 97.39% branch coverage; rubocop clean (431 files); `rake validate` passed.

### Acceptance criteria

- ✅ **`UnpitchedSound` rudiment** — generic singleton (`get.equal?(get(nil))`), alias collapse (`get("tabor") == get("snare drum")`, `name_key :snare_drum`), pitched instruments valid (`get("violin")` resolves, `pitched?` false while `instrument.pitched?` true), nil for unknown names, cross-type equality safe both directions, localization via the wrapped instrument (German translation pinned).
- ✅ **`Placement#sounds`/`pitches`/`pitch`** — frozen `sounds` source of truth; `pitches` derived fresh (merge-safe); `pitch` nil for unpitched-only placements.
- ✅ **`Voice#place` resolution** — every input form verified: pitch strings/arrays, bare `"snare drum"`, generic and violin-backed `UnpitchedSound`s, `Instrument` instances (pitched and unpitched), mixed arrays. Bare `"violin"` raises the tailored both-intents message; `"H4"` raises `unknown sound`; quiet-rest leniency retired (nil in an array raises; bare nil remains a rest).
- ✅ **Predicates + `Voice#notes`** — empirical predicate table matches Scope exactly, including the non-exhaustive cases (pitch+drum and two-drum placements are neither `note?` nor `chord?`); `rest?` anchored on `sounds.empty?`, not `!note?`; `Voice#notes` selects `pitched?`, excluding unpitched-only and including mixed placements; `sounded?` matches `RhythmicElement` semantics.
- ✅ **Schema v3** — round-trips byte-equal for named (`{"unpitched" => "snare_drum"}`), generic (`{"unpitched" => nil}`), and pitched-instrument (`{"unpitched" => "violin"}`) sounds; alias input canonicalizes; v2 rejected with migration hint; malformed elements raise with `voices[i].placements[j].sounds[k]` path context.
- ✅ **Writer guards** — both writers raise their own `RenderError` (`cannot render unpitched sound "snare drum" at 1:1:000: percussion rendering is not yet supported`) before the chord guard; mixed placements covered; regression pins confirm chords never silently emit.
- ✅ **Backlog stories rewritten** — both dependent stories aligned with the sounds model, each with a new criterion pinning the unpitched guard.
- ✅ **Rubocop and all specs pass** — see counts above.

### Code review findings

No blocking or should-fix issues. Verified clean: frozen-array discipline through `merge`; `UnpitchedSound` value equality composing correctly with `Pitch`'s interned identity in `uniq`; writer guards covering every nil-pitch path; no stale `note?`/`pitches` callers anywhere in lib or spec. Four nits, all optional:

1. `pitch.rb:59` — the `respond_to?(:to_i)` guard in `from_number` deserves a one-line why-comment (it exists so `pitch == unpitched_sound` returns false instead of raising; the reason lives only in this story's plan).
2. `shared_examples_for_sounds.rb:23-26` — the "same hash for equal objects" example compares an object with itself; a distinct-but-equal instance would pin the property `uniq` actually relies on (already covered elsewhere by the alias-`uniq` spec, so no coverage gap).
3. `voice.rb:104-114` — `earliest_bar_number`/`latest_bar_number` guard on pitched-only `notes` but read all placements; an unpitched-only voice reports bar 1. Same pre-existing treatment as rests-only voices; revisit when percussion rendering lands.
4. `placement.rb:140,158` — the bare-pitched-instrument error path resolves the instrument twice; raise-path-only, cosmetic.

### Verdict

**Ready to commit and finish.** Both reviewers independently reached the same conclusion; the product-manager reproduced the story's Example block output verbatim.

## Learnings

- **Probe existing capabilities before designing new ones.** The design conversation asked for "some kind of instrument lookup"; two console probes showed `Instruments::Instrument.get` (spaces, casing, aliases) and `Instrument#pitched?` already existed, collapsing a planned subsystem into a wrapper class. The same probes settled the pitch-first resolution order empirically (`Pitch.get` is strict about words) rather than by argument.
- **Design pivots before planning are cheap; the same pivots after implementation would not have been.** The story absorbed three substantial design changes (predicate repartition, catalog-backed identity, generic + pitched-instrument hits) while still in markdown. The conversation about what `pitched?` means — a property of the sound, not the instrument — produced the model's cleanest invariant and the tailored bare-"violin" error.
- **Name the traps in the plan.** The planner's explicit warning that `rest? = !note?` would classify every chord as a rest, and its pre-enumerated three-call-site ripple for the `note?` semantic change, were both exactly right and shaped the implementation prompts. Naming a latent bug in advance is the cheapest way to not ship it.
- **Plans should state intent and invariants, not just line numbers.** Two agents correctly overrode over-specific plan details (spec expectations listed for flipping that were still true; nil-in-array kept strict rather than resolving to the generic hit). Because prompts carried the *why*, agents could correct the *what*.
- **Strict file ownership made parallel agents safe.** Four implementation waves with disjoint file lists, each told "other specs may be red — not yours," produced zero conflicts and a fully green suite on the first integrated run.
- **Carry decision rationale into code comments where a guard looks arbitrary.** The one review nit worth acting on (the uncommented `respond_to?(:to_i)` guard in `Pitch.from_number`) existed because its why lived only in the plan. Implementation prompts should say: if a guard's reason isn't visible at the call site, write the one-line why.
- Incidental discovery, deferred: `Pitch.get("A44")` leniently parses as A4; the catalog lacks tom-tom/clap/rimshot. Both noted in the plan's risks for future stories.
