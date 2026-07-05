<!--
metadata:
  created_at:
  activated_at: 2026-07-05T10:26:49-07:00
  planned_at:   2026-07-05T11:04:02-07:00
  finished_at:
  updated_at:   2026-07-05T13:05:41-07:00
-->

# Extract Staff Schemes to NotationStyle

AS a developer

I WANT staff schemes and notation conventions to live in a NotationStyle model

SO THAT notation concerns are separated from instrument definition and can vary independently

## Background

The current architecture embeds staff schemes (clefs, sounding transpositions, number of staves) directly in each instrument definition. This conflates two independent concerns:

1. **What the instrument is** — its pitch, range, family, physical characteristics
2. **How it's notated** — which clefs, transposed or concert pitch, regional conventions

These concerns are orthogonal. A euphonium in a British brass band uses treble-clef transposed notation, while the same instrument in an orchestra uses bass clef at concert pitch — the notation choice depends on the **tradition or context**, not the instrument itself. Likewise a French horn is one instrument whether its everyday part is in treble clef (transposed) or a low passage drops to bass clef.

`lib/head_music/instruments/instrument.rb` already flags this: its `staff_schemes` accessor carries the comment *"notation schemes (to be moved to NotationStyle later)."* This story does that move.

## Current State

Each instrument in `instruments.yml` carries a `staff_schemes` map. The `default` scheme is the everyday notation; additional named schemes encode alternative conventions — some are traditions, some are register/clef choices:

```yaml
euphonium:
  family_key: tuba
  range_categories:
  - baritone
  staff_schemes:
    default:
    - clef: bass_clef
      sounding_transposition: 0
    british_band_default:      # this is a *tradition*, not a different instrument
    - clef: treble_clef
      sounding_transposition: -14

french_horn:
  family_key: horn
  pitch_key: f
  staff_schemes:
    default:
    - clef: treble_clef
      sounding_transposition: -7
    bass_clef:                 # low-register clef alternative, a notation choice
    - clef: bass_clef
      sounding_transposition: 5
```

(The `Variant` class and `Instrument#variants` are currently backward-compat shims — the YAML has no `variants:` key. Named `staff_schemes` are the real carriers of the notation conflation.)

Problems with the current approach:

- Named schemes like `british_band_default` (a tradition) and `bass_clef` (a low-register clef alternative) describe **notation conventions**, yet they live inside the instrument as if they were properties of the instrument.
- Adding a new tradition (say, a concert-pitch score) means editing many instruments' scheme maps.
- The same scheme choice is duplicated across every instrument that shares it.
- `sounding_transposition` (a notation concern) is stored alongside `pitch_key` (an instrument property).

## Proposed State

Instrument definitions keep only what the instrument *is*. Notation conventions move into named notation styles, keyed by tradition.

```yaml
# instruments.yml — purely about the instrument
euphonium:
  family_key: tuba
  range_categories:
  - baritone
  # no staff_schemes — only one euphonium

french_horn:
  family_key: horn
  pitch_key: f
  # no staff_schemes
```

```yaml
# notation_styles.yml — notation conventions by tradition
#
# `default` is the fallback style and lists EVERY instrument. Named styles are
# sparse OVERLAYS: they list only the instruments whose notation differs, and
# any instrument they don't mention falls back to `default`.

default:
  name: "Default"
  instrument_notations:
    euphonium:
      clef: bass_clef
      sounding_transposition: 0
    french_horn:
      clef: treble_clef
      sounding_transposition: -7
      alternatives:             # recorded, not yet selectable (see Resolved Decisions)
      - clef: bass_clef
        sounding_transposition: 5
        category: range          # used for low passages
        name_key: bass_clef
    piano:                       # grand-staff structure lives in the default style
      staves:
      - clef: treble_clef
      - clef: bass_clef
    # ... every instrument appears here

british_brass_band:
  name: "British Brass Band"
  instrument_notations:          # overlay: only the differences
    euphonium:
      clef: treble_clef
      sounding_transposition: -14
    tuba:
      clef: treble_clef
      sounding_transposition: -26
    baritone_horn:
      clef: treble_clef
      sounding_transposition: -14

german:
  name: "German notation"
  instrument_notations:          # overlay: only the differences
    bass_clarinet:
      clef: bass_clef
      sounding_transposition: -2

concert_pitch:
  name: "Concert Pitch Score"
  # Overrides interval-transposers to concert pitch; octave-transposers
  # (piccolo, double bass, …) are unlisted and keep their octave via `default`.
  instrument_notations:
    french_horn:
      clef: treble_clef
      sounding_transposition: 0
```

### Resolution model

Looking up an instrument's notation in a style resolves as an **overlay on `default`**:

1. If the named style lists the instrument, use its notation.
2. Otherwise, fall back to the instrument's entry in the `default` style.

So `british_brass_band.notation_for(:trombone)` yields the trombone's `default` notation (brass bands and orchestras notate trombone the same way), while `british_brass_band.notation_for(:euphonium)` yields the treble-clef, −14 override.

### Grand-staff and multi-staff instruments

Staff structure (how many staves, and each staff's clef) is a notation-style concern and lives in `default`. Piano's two-staff treble/bass layout is defined in the `default` style's `piano` entry, alongside single-staff instruments' single clef. A named style may override it, but in practice most inherit the default structure.

## User Stories

**STORY 1: Create NotationStyle class**

AS a developer
WHEN I need to specify how instruments should be notated
I WANT to use a NotationStyle object loaded from `notation_styles.yml`
SO THAT notation conventions are explicit, named, and reusable

**STORY 2: NotationStyle resolves an instrument's notation (overlay on default)**

AS a developer
WHEN I have a NotationStyle and an Instrument
I WANT to query the clef, sounding transposition, and staff structure, falling back to the `default` style when the named style doesn't override the instrument
SO THAT I can notate the instrument correctly for that tradition without repeating shared conventions

**STORY 3: Remove staff_schemes from instrument definitions**

AS a developer
WHEN I read an instrument definition
I WANT it to contain only instrument facts (family, pitch, range), with no `staff_schemes`
SO THAT the instrument model is purely about the instrument, not its notation

**STORY 4: Collapse euphonium's duplicate scheme**

AS a developer
WHEN I look up a euphonium
I WANT a single instrument definition, with its brass-band notation living in the `british_brass_band` style
SO THAT the orchestral-vs-brass-band distinction is a notation choice, not two instrument entries

**STORY 5: Instrument is notated through a NotationStyle**

AS a developer
WHEN I place an instrument in a score
I WANT to specify (or default) the notation style that governs its clef, transposition, and staves
SO THAT the configuration knows how to notate the instrument

## Implementation Notes

(High-level orientation; the authoritative, file-level steps are in the **Implementation Plan** below.)

1. Create `HeadMusic::Notation::NotationStyle`, loaded from a new `notation_styles.yml`, with a `.get(key)` factory (e.g. `NotationStyle.get(:british_brass_band)`) and a `.default` convenience — via a lightweight registry, **not** the `Named` mixin (styles have no translation surface).
2. `notation_style.notation_for(instrument)` returns the resolved notation (clef, sounding transposition, staves) as an `InstrumentNotation` value object, applying the overlay-on-`default` rule from the Resolution model above.
3. Seed `notation_styles.yml` by migrating every instrument's current `default` staff scheme into the `default` style; migrate tradition schemes (`british_band*` → `british_brass_band`; `german_notation`/`italian_notation` → `german`/`italian`) into named styles; and record register/clef alternatives (e.g. french horn `bass_clef`) as categorized `alternatives:` data on the `default` entry (see Resolved Decisions).
4. `default` is the fallback when no style is specified.
5. Preserve the exact numbers currently encoded in `sounding_transposition`; this story does not recompute transpositions from pitch + convention (that composition is deferred — see Resolved Decisions).
6. Provide a way to notate an instrument through a chosen style — `instrument.notation(style:)`, defaulting to `default`.
7. `staff_schemes` is removed from `instruments.yml` and `instrument.rb`; the `Instrument` notation methods (`default_staves`/`default_staff_scheme`, etc.) keep working by delegating to `NotationStyle.default`. The `Variant` shim is untouched (out of scope).

## Acceptance Criteria

- [x] `HeadMusic::Notation::NotationStyle` class exists with a `.get` factory and a `.default` convenience
- [x] `notation_styles.yml` defines a `default` style plus tradition styles (`british_brass_band`, `concert_pitch`, `german`, `italian`)
- [x] The `default` style contains an entry for every instrument
- [x] Named styles are sparse overlays — they list only overriding instruments
- [x] `notation_style.notation_for(instrument)` returns an `InstrumentNotation` (clef, sounding transposition, staves), falling back to `default` for instruments the style doesn't override
- [x] `concert_pitch` overrides interval-transposers only (→ 0); octave-transposers fall back to `default` and keep their octave
- [x] Register/clef alternatives (e.g. french horn bass clef, tenor-voice clefs) are recorded as categorized `alternatives:` data with no selection behavior
- [x] Grand-staff / multi-staff structure (e.g. piano) is defined in the `default` style
- [x] Instrument definitions no longer carry `staff_schemes`
- [x] Euphonium is a single instrument; its brass-band notation lives in `british_brass_band`
- [x] An instrument can be notated through a chosen notation style, defaulting to `default`
- [x] All existing tests pass (with appropriate updates)
- [x] New tests cover style lookup, overlay resolution, default fallback, and grand-staff structure
- [x] Maintains 90%+ test coverage (99.6% line coverage)

## Resolved Decisions

- **Named-style resolution** — Named styles are **sparse overlays on `default`**. A style lists only the instruments whose notation differs; unlisted instruments fall back to the `default` style.
- **Default style** — There is a `default` notation style that lists **every** instrument. It is the fallback when no style is specified. (This supersedes the earlier idea of "orchestral" being the default.)
- **Grand-staff instruments** — Staff structure is defined **in the `default` notation style**, not declared on the instrument. Piano's grand staff is a notation-style concern like any other.
- **Self-contained** — NotationStyle is described on its own terms. There is no dependency on a separate overlay-architecture story (the previously referenced `000-overlay-architecture.md` does not exist).
- **Catalog vs. Content — the bright line** — The Instruments + NotationStyle catalog holds *recognized, reusable* notation conventions. Notation choices a *particular piece* makes (e.g. both piano staves in treble for a passage) belong to `HeadMusic::Content`, not the catalog. Test for inclusion: *would a knowledgeable musician name this option independent of any particular piece?* If yes → catalog; if it's ad hoc for a passage → Content. Any staff's clef stays freely overridable at the Content layer without the catalog knowing.
- **Tradition = the NotationStyle axis** — Traditions are *score-wide and cross-instrument*, so they are modeled as **styles**, not as per-alternative tags. `british_brass_band`, `german`, `italian`, and `concert_pitch` each become a style (sparse overlay of the primary clef + transposition). This absorbs the current `british_band_default`, `german_notation`, and `italian_notation` scheme keys.
- **Range / constraint alternatives = categorized data, selection deferred** ("nouns now, verbs later") — Register-driven and layout alternatives that are *per-part, per-passage* (e.g. french horn bass clef for low passages, tenor-voice tenor/bass clefs) are recorded as an `alternatives:` list on the instrument's `default` entry, each carrying `{clef/staves, category, name_key}` (`category` ∈ `range`, `constraint`, …). This story only **records** that the option exists and why; it does **not** compute per-style transposition composition or wire up how a score selects an alternative — that is a later Content-layer story. (Deferring avoids re-introducing duplication via every style × alternative combination.)
- **`no_pedal` / `single_staff` dropped as emergent from Content** — `organ: no_pedal` and `lute: single_staff` are facts about a *piece* (a manualiter work has no pedal part), i.e. instrumentation, not named notation conventions. They are **not** catalogued; reduced staves fall out of a score that has no pedal / second-staff content. Their current scheme data is intentionally not migrated.
- **Return type** — `notation_for` returns a new `HeadMusic::Notation::InstrumentNotation` value object (not a reused `StaffScheme`).
- **`concert_pitch` overrides interval-transposers only; octave-transposers keep their octave** — A concert-pitch ("C") score removes *interval* transposition but *keeps octave* transposition (standard practice: piccolo, double bass, contrabassoon, guitar, celesta, glockenspiel, xylophone stay written an octave from sounding to avoid ledger lines). So `concert_pitch` lists **only** instruments where `transposing? && !transposing_at_the_octave?` (i.e. `sounding_transposition % 12 != 0`), overriding them to `sounding_transposition: 0` with their default clef. Octave-transposers and non-transposers are unlisted and fall back to `default`, preserving their existing plain-clef + numeric-octave representation for free — perfectly consistent with the sparse-overlay model. No octave-clef machinery is needed for this story.
  - *Edge case (flag, don't special-case):* compound octave+interval transposers (e.g. bass clarinet, −14 → `% 12 = −2`) are classed as interval-transposers and flattened fully to `0` (matches a true C score; some publishers keep the octave).
  - *Follow-up:* a full octave-clef family (`treble-8va`/`bass-8vb`/`15ma`; head_music currently has only `octave_treble_clef`/`vocal_tenor_clef` at G3) would let rendering show octave displacement visually instead of via a numeric transposition — an orthogonal notation-representation story, out of scope here.

## Out of Scope / Follow-ups

- **Percussion staff mappings** — Drum-kit and percussion staff mappings (e.g. bass drum on space 1, snare on line 3) **are** a notation concern and ultimately belong in NotationStyle, since publishers differ. Migrating them is deferred to its own follow-up story; this story focuses on clef, sounding transposition, and staff structure for pitched instruments.
- **Multi-key pitched variants** — Instruments that come in several keys (e.g. clarinet in B♭/A/E♭) are an instrument-model concern distinct from notation and are out of scope here.

## Implementation Plan

### Overview

Introduce `HeadMusic::Notation::NotationStyle`, a value object backed by a new `lib/head_music/notation/notation_styles.yml`, with a lightweight `.get(key)` registry and a `.default` convenience. A `default` style holds one explicit entry per instrument (a mechanical 1:1 copy of each instrument's current `default` staff scheme); named styles (`british_brass_band`, `concert_pitch`) are sparse overlays resolved by `notation_for(instrument)` with whole-entry override on default fallback. `Instrument`'s existing notation methods become thin, call-time (lazy) shims that delegate to `NotationStyle.default`, so every current value returns identically while `staff_schemes` leaves `instruments.yml`.

Two verified data facts shape everything:

- **All 133 instruments already carry their own `default` staff scheme** — the parent-inheritance fallback in `build_staff_schemes` (`instrument.rb:309`) never fires in practice. The flat, per-instrument `default` style is therefore a faithful 1:1 of today's resolved values; no parent-chain resolution needs to be replicated in `NotationStyle`, and "expand each child to its own entry" is a no-op copy.
- **The 9 existing non-default scheme keys are NOT uniformly "traditions"** — and are now handled per the settled architecture (see Resolved Decisions):
  - **Traditions → their own styles:** `british_band*` → `british_brass_band`; `german_notation` → `german`; `italian_notation` → `italian`. Plus the generated `concert_pitch` style.
  - **Range alternatives → categorized `alternatives:` data on the `default` entry (recorded, not yet selectable):** `french_horn: bass_clef` (+5) and `tenor_voice: bass`/`tenor` (register/clef alternatives). (`baritone_horn: treble` is the brass-band tradition, so it goes into `british_brass_band`, not here.)
  - **Dropped as emergent from Content:** `lute: single_staff`, `organ: no_pedal` — instrumentation facts of a piece, not catalogued.

Other counts: 13 grand-/multi-staff instruments (piano/accordion 2 staves, `organ` 3); only `drum_kit` carries deferred `mappings:`; ~48 transposing instruments total, of which the `concert_pitch` overlay covers only the interval-transposers — the ~16 octave-transposers (`sounding_transposition % 12 == 0`) are unlisted and keep their octave via `default`.

### Steps

1. **Create the `NotationStyle` class and data file (sub-story 1)**
   - New `lib/head_music/notation/notation_style.rb`: `HeadMusic::Notation::NotationStyle` with `STYLES = YAML.load_file(File.expand_path("notation_styles.yml", __dir__)).freeze`, `private_class_method :new`.
   - Use a **lightweight `.get` registry, NOT the `Named` mixin.** `Named` is built for localized instrument *names* (`get_by_name` memoizes by `HashKey.for(name)`, drags in the `LocalizedName`/locale fallback chain). NotationStyle keys are internal tradition identifiers with no translation surface. Mirror the *shape* of `.get` without the baggage:
     ```ruby
     def self.get(key)
       @styles ||= {}
       @styles[HeadMusic::Utilities::HashKey.for(key)] ||= new(key)
     end
     def self.default = get(:default)
     ```
   - New `lib/head_music/notation/notation_styles.yml` — `default` section only in this step (generated, see Migration Strategy). Shape: top-level style key → `instrument_notations` → instrument key → array of staff-descriptor hashes structurally identical to today's `staff_schemes[key]` lists (so grand-staff arrays, per-staff `name_key`, and `drum_kit`'s `mappings` all ride along unchanged).
   - Add `require "head_music/notation/notation_style"` to `lib/head_music/notation.rb` (after line 11).

2. **Implement `notation_for` overlay resolution + return value object (sub-story 2)**
   - `notation_for(instrument)` accepts **both an `Instrument` object and a key/name** — normalize once via a call-time `HeadMusic::Instruments::Instrument.get(instrument)` (it already handles both; `score_order` passes objects, external callers pass keys).
   - Resolution is **whole-entry override, not field-level deep-merge**: `instrument_notations[key] || NotationStyle.default.instrument_notations[key]`; return `nil` for unknown instruments. Keep this in one private resolver; do not smear merge logic across YAML anchors.
   - **Return a new frozen value object, `HeadMusic::Notation::InstrumentNotation`** (not a reused `StaffScheme`). `notation_for` is a derived computation, so it should not carry a `.get`; model it like other constructed value objects. It exposes `staves`, `clefs`, `sounding_transposition`, and the predicates, with `==` by resolved data + instrument `name_key` (mirroring `Instrument#==` at `instrument.rb:165`), memoized per style keyed by `name_key`.
   - **Reuse the existing `Staff` (`lib/head_music/instruments/staff.rb`) as the element type** so downstream `.staves.first.clef` keeps working. `Staff#initialize` currently requires a `StaffScheme` parent (`staff.rb:8`) — relax that first parameter (it is only stored, and the `mappings` path is deferred) so a `Staff` can belong to an `InstrumentNotation` without dragging in `StaffScheme`.
   - Files: `lib/head_music/notation/notation_style.rb`, new `lib/head_music/notation/instrument_notation.rb` (+ require in `notation.rb`), edit `lib/head_music/instruments/staff.rb`.
   - *Decided:* use the new `InstrumentNotation` value object (for module-boundary cleanliness), accepting the cost of updating `instrument_spec.rb:116` (which asserts `default_staff_scheme` is a `StaffScheme`) and relaxing `Staff#initialize`. (The alternative considered — reusing `Instruments::StaffScheme` to avoid that spec churn — was rejected because it keeps a Notation object living in the Instruments module.)

3. **Add tradition styles as sparse overlays + record range/constraint alternatives (sub-story 2/4)**
   - **Tradition styles** in `notation_styles.yml`: `british_brass_band` (`euphonium` treble/−14, `tuba` treble/−26, `bass_tuba_in_e_flat` treble/−21, `baritone_horn` treble/−14); `german` and `italian` (migrated from `bass_clarinet`'s `german_notation`/`italian_notation` schemes); `concert_pitch` (generated: **interval-transposers only** — instruments where `transposing? && !transposing_at_the_octave?` — set to `sounding_transposition: 0` with their default clef; octave-transposers and non-transposers are unlisted and fall back to `default`, keeping their octave — see Resolved Decisions). Euphonium collapses here — its brass-band notation is authored into `british_brass_band` and removed from the instrument (sub-story 4).
   - **Range alternatives** are recorded on the `default` style's instrument entries as an `alternatives:` list — each `{clef (or staves), sounding_transposition, category, name_key}`, `category` ∈ `range`/`constraint`. Migrate `french_horn: bass_clef` (range, +5) and `tenor_voice: bass`/`tenor` here. **This story only stores this data** — `InstrumentNotation#alternatives` may expose it, but no selection behavior or per-style transposition composition is built (deferred to a Content-layer story).
   - **Note:** `baritone_horn: treble` (−14) is the brass-band tradition and goes into `british_brass_band` (above), **not** into alternatives.
   - **Do NOT migrate** `lute: single_staff` or `organ: no_pedal` — dropped as emergent from Content (see Resolved Decisions).
   - Files: `lib/head_music/notation/notation_styles.yml`; `lib/head_music/notation/instrument_notation.rb` (optional `alternatives` reader).

4. **Re-point `Instrument` notation methods to `NotationStyle.default` (sub-story 3)**
   - Edit `lib/head_music/instruments/instrument.rb`: reimplement `default_staff_scheme`/`default_staves` as lazy compat shims. Everything else (`default_clefs`, `sounding_transposition`/`default_sounding_transposition`, `transposing?`, `transposing_at_the_octave?`, `single_staff?`, `multiple_staves?`, `pitched?`) already derives from those and needs no change.
     ```ruby
     def default_staves
       HeadMusic::Notation::NotationStyle.default.notation_for(self)&.staves || []
     end
     ```
   - **Load-order landmine (must-hit):** `head_music/instruments/*` loads before `head_music/notation/*`. Reference `HeadMusic::Notation::NotationStyle` **only inside method bodies** — never in the class body, `initialize`, a constant, or a `require` in `instrument.rb`. Any load-time reference raises `NameError` at boot. Late-bound constant resolution inside methods is safe.
   - Delete `@staff_schemes_data`, its reader (line 30), the assignment (line 257), and `build_staff_schemes` (lines 308–318). Update the stale doc comments (lines 24, 113).
   - Files: `lib/head_music/instruments/instrument.rb`.

5. **Strip `staff_schemes` from `instruments.yml` (sub-story 3/4)**
   - Remove the `staff_schemes:` key from all 133 entries via the same generation script that emits the YAML (not by hand). Instruments retain only `family_key`/`pitch_key`/`parent_key`/`alias_name_keys`/`range_categories`. Euphonium becomes a single instrument with no notation data.
   - **Keep Steps 4 and 5 in one commit** — removing the YAML data before the methods are re-pointed would break every notation call in between.
   - Files: `lib/head_music/instruments/instruments.yml`.

6. **Add the "notate through a chosen style" API (sub-story 5)**
   - Add to `instrument.rb`: `def notation(style: :default) = HeadMusic::Notation::NotationStyle.get(style).notation_for(self)`. `.notation` (no arg) equals `default_staff_scheme`'s resolution; `.notation(style: :british_brass_band)` returns euphonium's treble/−14.
   - Files: `lib/head_music/instruments/instrument.rb`.

### Migration Strategy (the 133-entry `default` style)

- **Generate, do not hand-transcribe.** Hand-copying 133 entries across two files is the single largest regression source. Write a throwaway script in `scratchpad/` that iterates `Instrument.all` on the *current pre-refactor code* and emits the `default:` section of `notation_styles.yml` from each instrument's resolved `default` scheme (lifting `record["staff_schemes"]["default"]` verbatim, including grand-staff arrays and `drum_kit`'s `mappings`), and in the same pass produces the stripped `instruments.yml`. Do not commit the script as a rake task.
- **Represent parent inheritance as flat, explicit per-instrument entries** — verified safe because all 133 already define their own default. The `default` style must list every instrument explicitly (already an acceptance criterion); document that a future instrument omitting notation will NOT inherit via the style.
- **Characterization / equivalence guardrail (write it BEFORE the refactor).** On `main`, dump a golden fixture capturing, per instrument, the tuple `{clef keys, sounding_transposition, staves.count, single_staff?, multiple_staves?, pitched?, transposing?}` — `pitched?`'s `neutral_clef` logic (`instrument.rb:153`) is non-obvious and worth pinning. Commit it to `spec/fixtures/notation/legacy_default_notation.json`, then assert post-refactor equality against it in a spec that reads `NotationStyle.default` directly (so it is independent of the soon-delegating `Instrument` methods). This 133-example spec is the safety net proving no default clef list, transposition, or staff count drifted.

### Backward Compatibility

- **Delegate-to-default-style, not keep-and-deprecate.** Keeping `build_staff_schemes` would require `staff_schemes` to stay in `instruments.yml`, contradicting sub-story 3. The listed `Instrument` methods and `score_order.rb:132` (`default_sounding_transposition`) keep behaving byte-for-byte because they all resolve through `default_staves`/`default_staff_scheme`, which now delegate lazily.
- **Coupling direction:** the resolver logic lives in `NotationStyle` (the correct Notation→Instruments arrow), but `Instrument` retains temporary upward compat shims (Instruments→Notation) as an explicit, call-time-only seam. Mark them for a follow-up that migrates direct consumers (`content/staff.rb:18`, `score_order.rb:132`) to ask a style directly, then deletes the shims.
- **Percussion `mappings` (deferred but must not be lost):** carried verbatim into `default`'s `drum_kit` entry; add one assertion that `default.notation_for("drum_kit").staves.first.mappings` is non-empty. Silent loss here is the main data-loss risk.

### Testing Strategy

- **New `spec/head_music/notation/notation_style_spec.rb`:** `.get` returns a `NotationStyle` and is memoized (same object twice); `.default` works; overlay resolution (`british_brass_band.notation_for("euphonium")` → treble/−14, `tuba` → treble/−26); default fallback (`british_brass_band.notation_for("piano")` → 2 staves treble+bass); grand-staff (`default.notation_for("piano")` → 2 staves, `organ` → 3, per-staff `name_key` preserved); euphonium collapse (`default.notation_for("euphonium")` → bass/0, treble/−14 only under `british_brass_band`); `concert_pitch.notation_for("clarinet")` → transposition 0; `german.notation_for("bass_clarinet")` / `italian.notation_for("bass_clarinet")` → their respective clef/transposition; recorded alternatives (`default.notation_for("french_horn").alternatives` includes a `range` bass-clef option; `tenor_voice` has its clef alternatives) with **no** selection behavior asserted; `no_pedal`/`single_staff` are absent from the catalog; signature polymorphism (object == key); unknown instrument → `nil`.
- **New `spec/head_music/notation/notation_style_equivalence_spec.rb`:** the golden-fixture characterization spec (Migration Strategy).
- **New cross-file integrity/validation spec:** the `default` style's instrument-key set equals the `INSTRUMENTS` key set exactly (no orphans, none missing); every key in any named overlay also exists in `default` (catches a typo'd overlay that silently never matches — `Staff#smart_clef_key` at `staff.rb:17` would otherwise build a bogus `"foo_clef"` silently); every referenced clef resolves via `Clef.get`.
- **Existing specs:** `instrument_spec.rb` should pass on values unchanged; update the `default_staff_scheme is_expected.to be_a StaffScheme` assertion (line ~116) for the `InstrumentNotation` return type, and add a `#notation(style:)` case. `staff_scheme_spec.rb` asserts on scheme keys like `british_band_default` sourced from `staff_schemes_data` — decide up front whether to relocate those assertions into `notation_style_spec` or shim. `variant_spec.rb` drives `StaffScheme` via `Variant` (untouched) — expect no change. `staff_spec.rb` constructs `Staff` directly — confirm the relaxed constructor keeps it green. `score_order_spec.rb` should pass unchanged.
- **90% coverage gate:** highest risk is `NotationStyle`'s branches — overlay-vs-fallback line, `nil` guard, `.default` memoization, `#notation(style:)`. The equivalence spec exercises `notation_for` across all 133; the unit spec covers the branches. After deleting `build_staff_schemes`, confirm no now-dead code remains dragging coverage.

### Risks & Open Questions

- **~~Return-type fork~~ — RESOLVED:** `notation_for` returns a new `Notation::InstrumentNotation` value object. Cost accepted: update `instrument_spec.rb:116`, relax `Staff#initialize`.
- **~~Heterogeneous scheme keys~~ — RESOLVED:** tradition → styles; range/constraint → categorized `alternatives:` data (selection deferred); `no_pedal`/`single_staff` dropped as emergent from Content. See Resolved Decisions and Steps 2–3.
- **~~`concert_pitch` semantics~~ — RESOLVED:** overrides interval-transposers only (→ 0, default clef); octave-transposers fall back to `default` and keep their octave. Compound transposers (bass clarinet) flatten fully to 0 — flagged edge case. See Resolved Decisions.
- **`alternatives` transposition composition (explicitly deferred):** a range alternative like horn bass clef `+5 written` becomes `0` under `concert_pitch`; composing `alternative × style` transposition is NOT built here — alternatives are stored as descriptive data only. Flag for the Content-layer follow-up.
- **Coupling seam lifespan:** are the `Instrument` notation shims permanent public API, or explicitly deprecated for removal once `content/staff.rb` and `score_order.rb` migrate to ask a style directly?
- **`Variant` / `staff_scheme_spec` legacy path:** `Variant` still parses its own `staff_schemes` from attributes. Assumed out of scope and untouched — confirm.

### Recommended Commit Sequencing (green at each step)

1. **Sub-story 1** — `notation_style.rb` + generated `notation_styles.yml` (`default` only) + `require` + `.get`/`.default` + committed golden fixture + equivalence spec + validation spec. Nothing else changes; existing tests pass, new specs prove parity.
2. **Sub-story 2** — `InstrumentNotation` value object + `notation_for` overlay + relaxed `Staff` constructor + `notation_style_spec` (overlay/fallback/grand-staff/polymorphism). Green.
3. **Sub-story 2/4** — Add `british_brass_band` + `concert_pitch` overlays; euphonium authored into brass-band style. Green.
4. **Sub-stories 3 + 4 (single commit)** — Re-point `Instrument` methods to `NotationStyle.default`; delete `build_staff_schemes`/`@staff_schemes_data`; strip `staff_schemes` from `instruments.yml`; update `instrument_spec`/`staff_scheme_spec` assertions.
5. **Sub-story 5** — `Instrument#notation(style:)` + spec. Green.

Key files: `lib/head_music/notation/notation_style.rb` (new), `lib/head_music/notation/instrument_notation.rb` (new), `lib/head_music/notation/notation_styles.yml` (new), `lib/head_music/notation.rb`, `lib/head_music/instruments/instrument.rb`, `lib/head_music/instruments/instruments.yml`, `lib/head_music/instruments/staff.rb`, `spec/head_music/notation/notation_style_spec.rb` (new), `spec/head_music/notation/notation_style_equivalence_spec.rb` (new), `spec/fixtures/notation/legacy_default_notation.json` (new).

## Review

Reviewed 2026-07-05 at commit `ec6fe37` (product-manager acceptance check + code review). Full suite green; 99.6% line coverage.

### Acceptance criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | `NotationStyle` with `.get` + `.default` | ✅ | `notation_style.rb:22-32`; `.get` memoizes, accepts string/symbol/instance, raises `KeyError` on unknown key |
| 2 | `notation_styles.yml` defines default + 4 tradition styles | ✅ | `.all` returns exactly `default, british_brass_band, german, italian, concert_pitch` |
| 3 | `default` has an entry for every instrument | ✅ | 133/133; integrity spec `default_keys match_array instrument_keys` |
| 4 | Named styles are sparse overlays | ✅ | overlay sizes 4 / 1 / 1 / 33 ≪ 133; integrity spec guards orphan keys |
| 5 | `notation_for` → `InstrumentNotation` with default fallback | ✅ | brass-band euphonium → treble/−14, trombone falls through to default |
| 6 | `concert_pitch` zeroes interval-transposers only | ✅ | horn/clarinet → 0; piccolo/guitar keep their octave via fallback |
| 7 | Alternatives recorded as categorized data, no selection | ✅ | french horn (`range` bass clef), tenor voice; `alternatives` builds Staff, no selection logic |
| 8 | Grand/multi-staff structure in `default` | ✅ | piano 2 staves, organ 3, per-staff `name_key` preserved |
| 9 | Instruments no longer carry `staff_schemes` | ✅ | `grep -c staff_scheme instruments.yml` → 0 (539 lines removed) |
| 10 | Euphonium single instrument; brass-band in `british_brass_band` | ✅ | default bass/0, brass-band treble/−14 |
| 11 | Notate through a chosen style, default `default` | ✅ | `Instrument#notation(style:)`; verified default vs concert_pitch |
| 12 | All existing tests pass | ✅ | 5030 → 5034 examples, 0 failures |
| 13 | New tests cover lookup/overlay/fallback/grand-staff | ✅ | 3 new notation specs + equivalence + integrity |
| 14 | Maintains 90%+ coverage | ✅ | 99.6% line coverage |

**No blocking issues — all 14 criteria met.**

### Code review findings

- **[Important] `Instrument#notation(style:)` had no direct test** — the new public API was only exercised indirectly. **Addressed** post-review: added `#notation` specs (default + named style) to `instrument_spec.rb`, plus a spec pinning that `staff_schemes` now returns only the default scheme, and an integrity assertion that every notation entry has ≥1 staff. Suite now 5034 examples, 0 failures.
- **[Verified sound]** Load-order safety (no load-time reference from `instrument.rb` to `NotationStyle`); `KeyError`-on-unknown-style does not poison the memo cache; overlay/`default_data` fallback correct; `Staff.new(nil, …)` and the `default_staff_scheme` compat shim sound; YAML shape matches parsers.
- **[Nice-to-have] — dispositioned:**
  - `InstrumentNotation` `eql?`/`hash` — **fixed** (`instrument_notation.rb`): `eql?` aliases `==`, `hash` keyed on `[instrument.name_key, staves_attributes]`; covered by `spec/head_music/notation/instrument_notation_spec.rb`.
  - `|| 0` in `sounding_transposition` — **kept intentionally**: `Staff` never returns nil, so the coalesce is the empty-staves guard (a staff-less notation returns `0`, not `nil`). Removing it would regress that path.
  - Single `category: range` on all alternatives — **left as-is**: assigning a finer taxonomy (e.g. `clef` vs `range`) depends on the deferred alternative-selection semantics ("nouns now, verbs later"); introducing categories now would invent an unratified enum.

### Follow-ups (non-blocking, for later stories)

- Compat-shim lifespan: migrate `content/staff.rb` and `score_order.rb` to ask a style directly, then remove the `Instrument` notation shims.
- Rule-based `concert_pitch` resolution (derive the zeroing rather than hardcoding compound-transposer entries).
- Alternative-selection behavior at the Content layer (the deferred "verbs").
