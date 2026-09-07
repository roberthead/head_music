# Content Schema 4: Object Model and Serialized Document

The `HeadMusic::Content` object model as released in 21.0.0, and the document it serializes to. Intended as the reference for anyone reading or writing schema-4 JSON, extending the model, or deciding where a new attribute belongs. Constructor signatures and key names are quoted from source on `main` at `09e1316`.

---

## 1. Entities and Edges

Every object below `Project` is reachable by ownership from a `Flow`, which is why a flow can stand alone and render without a project. `Player` is the one entity a `Part` points back at without owning it, and it carries no identity beyond its position in the project's authored order.

```
Project ──owns──▶ Player[]            authored order; a chair, not a person
   │
   └──owns──▶ Flow[]
                ├──owns──▶ Timeline        meter, tempo, key signature maps
                ├──owns──▶ Part[]
                │            ├─ back-ref ─▶ Player?
                │            ├─ map by bar ▶ Instruments::Instrument?
                │            ├─ map by bar ▶ StaffSystem ──owns──▶ Staff[1..*]
                │            │                                       └─ map by bar ▶ Rudiment::Clef?
                │            └──owns──▶ Voice[]
                │                         ├─ map by bar ▶ Staff      (one of the part's staves; serialized by index)
                │                         └──owns──▶ Placement[]     kept in position order
                │                                      ├──▶ Position          frozen value
                │                                      ├──▶ sounds[]          Pitch | UnpitchedSound; [] is a rest
                │                                      └──▶ syllables{verse}  Syllable
                ├──owns──▶ Bar[]            sparse, by number; repeat state only
                └──owns──▶ Comment[]
```

"Map by bar" means a `HeadMusic::Time::EventMap` keyed by the bar's downbeat position. Notes and chords have no class of their own: a chord is a placement with more than one pitched sound, and a rest is one with none.

---

## 2. The One Mechanism

Seven things change mid-piece, and all seven use `Time::EventMap` the same way. The map holds a default and a sorted list of events. Asking for the value at a bar returns the most recent event at or before that bar's downbeat, or the default when none precedes it. The opening value is the *default*, not an event, so a flow that merely opens in 3/4 reports no meter changes.

```
bar:     1     2     3     4     5     6     7     8
meter:   4/4 ─────── 6/8 ───────────── 3/4 ──────────▶
         default     event at 3:1:000  event at 6:1:000

meter_at(5)         → 6/8
meter_change_at(5)  → nil
```

Keys are `MusicalPosition.new(bar, 1, 0, 0)`, built by a private `downbeat_of` helper in each owning class. A change anywhere but a downbeat raises. Each map has two readers: the value in force at a bar, and the change authored exactly at that bar.

| Owner | Map | Value type | Default | Readers |
|---|---|---|---|---|
| `Flow::Timeline` | `meter_map` | `Rudiment::Meter` | opening meter, 4/4 if none | `meter_at` · `meter_change_at` |
| `Flow::Timeline` | `tempo_map` | `Rudiment::Tempo` | opening tempo, quarter = 120 | `tempo_at` · `tempo_change_at` |
| `Flow::Timeline` | `key_signature_map` | `Time::KeySignatureEvent` | opening event at 1:1 | `key_signature_at` · `key_signature_change_at` |
| `Part` | `instrument_map` | `Instruments::Instrument` | opening instrument or nil | `instrument_at` · `instrument_changes` |
| `Part` | `staff_system_map` | `Content::StaffSystem` | authored system or nil; falls back to one memoized single staff | `staff_system_at` · `staff_system_changes` |
| `Voice` | `staff_assignment_map` | `Content::Staff` | nil; falls back to the system's first staff | `staff_at` · `staff_assignments` |
| `Staff` | `clef_map` | `Rudiment::Clef` | authored clef or nil | `clef_at` · `clef_changes` |

---

## 3. Classes

Cardinality is from the owner's point of view. *Back-ref* marks a reference the object does not own.

### Project (`content/project.rb`)

`Project.new(name: nil)`

| Attribute | Type | Cardinality |
|---|---|---|
| `name` | String, defaults to `"Project"` | 1 |
| `players` | `Player`, owned, authored order | 0..* |
| `flows` | `Flow`, owned | 0..* |

`add_flow` adopts a standalone flow, mints a `Player` for each player-less part, and raises if the flow belongs to another project. Players and flows match by object identity.

### Player (`content/player.rb`)

`Player.new(project: nil, name: nil)`

| Attribute | Type | Cardinality |
|---|---|---|
| `name` | String or nil | 0..1 |
| `project` | *back-ref* `Project` | 0..1 |
| `parts` | derived: parts across the project's flows whose player is self | 0..* |
| `instruments`, `primary_instrument` | derived from parts | |

Serialized as `{"name"}` only.

### Flow (`content/flow.rb`)

`Flow.new(name: nil, key_signature: nil, meter: nil, tempo: nil, composer: nil, origin: nil, comments: nil)`

| Attribute | Type | Cardinality |
|---|---|---|
| `name` | String, defaults to `"Composition"` | 1 |
| `composer`, `origin` | any, serialized via `to_s` | 0..1 |
| `timeline` | `Flow::Timeline`, owned | 1 |
| `parts` | `Part`, owned | 0..* |
| `bars` | `Bar`, sparse array by number, bar 0 allowed | 0..* |
| `comments` | `Comment`, owned | 0..* |
| `project` | *back-ref* `Project` | 0..1 |

The aggregate root that renders: `to_abc`, `to_lilypond`, `to_musicxml`. `voices` is derived from parts. The three musical constructor arguments are not stored on the flow; they become the timeline's opening values.

### Flow::Timeline (`content/flow/timeline.rb`)

`Timeline.new(meter: nil, key_signature: nil, tempo: nil)`

| Attribute | Type | Cardinality |
|---|---|---|
| `opening_meter` | `Rudiment::Meter` | 1 |
| `opening_tempo` | `Rudiment::Tempo` | 1 |
| `opening_key_signature_event` | `Time::KeySignatureEvent` | 1 |
| `meter_map`, `tempo_map`, `key_signature_map` | event maps, see §2 | 0..* each |

A key signature event holds a fifths `Integer` and an optional tonal context (`Key`, `Mode`, or `KeySignature`). A fifths value past ±7 with no tonal context is refused at authoring. Passing `nil` to a `change_*` method raises and points at the matching `remove_*_change`.

### Part (`content/part.rb`)

`Part.new(flow:, player: nil, instrument: nil, staff_system: nil)`

| Attribute | Type | Cardinality |
|---|---|---|
| `flow` | *back-ref* `Flow`, required | 1 |
| `player` | *back-ref* `Player` | 0..1 |
| `voices` | `Voice`, owned | 0..* |
| `instrument_map` | `Instruments::Instrument` by bar | 0..* |
| `staff_system_map` | `StaffSystem` by bar | 0..* |

`staff_system_at` never answers nil: an unauthored part gets one memoized single staff, which is deliberately not serialized.

### Voice (`content/voice.rb`)

`Voice.new(part: nil, flow: nil, role: nil)`

| Attribute | Type | Cardinality |
|---|---|---|
| `part` | *back-ref* `Part`, minted if absent | 1 |
| `role` | String or nil | 0..1 |
| `placements` | `Placement`, owned, position order, binary-search insert | 0..* |
| `staff_assignment_map` | `Staff` by bar, no default | 0..* |
| `melodic_line` | derived snapshot: pitches, range, leaps | 1 |

`assign_staff(bar, staff)` raises unless the staff is in the part's system at that bar. `cross_to(staff, from:)` is the same call in spoken order. `place` merges into an existing placement at the same position.

### Placement (`content/placement.rb`)

`Placement.new(voice, position, rhythmic_value, sound_or_sounds = nil)`

| Attribute | Type | Cardinality |
|---|---|---|
| `voice` | *back-ref* `Voice` | 1 |
| `position` | `Position`, frozen | 1 |
| `rhythmic_value` | `Rudiment::RhythmicValue` | 1 |
| `sounds` | `Pitch` or `UnpitchedSound`, frozen, deduplicated; empty is a rest | 0..* |
| `beam_break_before` | `true`, `false`, or `nil` for the meter default | 0..1 |
| `syllables` | `Syllable` keyed by verse `Integer` | 0..* |

Comparable by position only. `pitch` is the top note. Predicates: `rest?`, `note?`, `chord?`, `pitched?`, `sung?`.

### Position (`content/position.rb`)

`Position.new(flow, code_or_bar, count = nil, tick = nil, subtick = nil)`

| Attribute | Type | Cardinality |
|---|---|---|
| `flow` | *back-ref* `Flow` | 1 |
| `bar_number`, `count`, `tick`, `subtick` | `Integer`, via `Time::MusicalPosition` | 1 |
| `code` | `"bar:count:ttt"`, plus `":sss"` only when subtick ≠ 0 | 1 |

Frozen value object. Equality and hash ignore the flow. Normalization carries under each crossed bar's own meter, so one instant has exactly one spelling. 960 ticks per quarter, 240 subticks per tick.

### StaffSystem (`content/staff_system.rb`)

`StaffSystem.new(staves: nil, bracket: :none)`

| Attribute | Type | Cardinality |
|---|---|---|
| `staves` | `Staff`, owned, never empty | 1..* |
| `bracket` | `:brace`, `:bracket`, or `:none` | 1 |

Factories: `single_staff(clef:)`, `grand_staff`. `include?` is identity.

### Staff (`content/staff.rb`)

`Staff.new(clef: nil, line_count: 5, instruments_staff: nil)`

| Attribute | Type | Cardinality |
|---|---|---|
| `line_count` | `Integer`, default 5 | 1 |
| `instruments_staff` | `Instruments::Staff`, catalog staff for percussion mapping | 0..1 |
| `clef_map` | `Rudiment::Clef` by bar, nil when unauthored | 0..* |

No equality. A staff is known by identity, so a voice's assignment serializes as an index into the system in force at that bar.

### Bar (`content/bar.rb`)

`Bar.new(flow, number: 1)`

| Attribute | Type | Cardinality |
|---|---|---|
| `number` | `Integer` | 1 |
| `starts_repeat?` | Boolean | 1 |
| `ends_repeat_after_num_plays` | `Integer` ≥ 2 or nil | 0..1 |
| `plays_on_passes` | unique positive `Integer`s, or nil for every pass | 0..* |
| `meter`, `key_signature` | derived: the change authored in this bar, else nil | 0..1 |

Repeat structure only. Key and meter storage moved to the timeline in this release.

### Comment and Syllable (`content/comment.rb`, `content/syllable.rb`)

`Comment.new(flow, text, position = nil)` holds `text` and an optional `Position` that must belong to this flow.

`Syllable.new(text, verse: 1, hyphen_after: false)` is frozen and compares by value.

---

## 4. The Serialized Document

`Project#to_h` wraps one or more `Flow#to_h`. Keys are strings and values are JSON-safe. Keys marked `?` are sparse: omitted when empty or at their default.

```jsonc
{
  "schema_version": 4,
  "name": "Suite",                                // Project name, defaults to "Project"
  "players": [ { "name": "piano" }, { "name": null } ],
  "flows": [
    {                                             // Flow#to_h, plus one key the project adds:
      "players": [0, null],                       // parallel to "parts": index into project players; null = no player

      "schema_version": 4,
      "name": "Allemande",
      "composer": "Trad.",                        // or null
      "origin": null,

      "timeline": {
        "meter": "4/4",                           // opening values are the map defaults …
        "key_signature": "D major",               // … the opening signature by name, not by fifths
        "tempo": { "beat_value": "quarter", "beats_per_minute": 96.0 },   // bpm is always a Float
        "meter_changes": [ { "number": 3, "meter": "6/8" } ],             // [] when none
        "key_signature_changes": [
          { "number": 5, "signature": -3, "tonal_context": "C dorian" }   // fifths Integer; context by name or null
        ],
        "tempo_changes": [ { "number": 3, "tempo": { "beat_value": "half", "beats_per_minute": 72.5 } } ]
      },

      "parts": [
        {
          "instrument"?: "Piano",                 // Instrument#name at bar 1
          "instrument_changes"?: [ { "number": 9, "instrument": "Celesta" } ],
          "staff_system"?: {                      // only when authored; the single-staff fallback is never written
            "bracket": "brace",                   // "brace" | "bracket" | "none"
            "staves": [
              { "clef": "treble_clef",            // Clef#name_key, or null when never authored
                "clef_changes"?: [ { "number": 2, "clef": "bass_clef" } ] },
              { "clef": "bass_clef" }
            ]
          },
          "staff_system_changes"?: [ { "number": 3, "staff_system": { /* same shape */ } } ],
          "voices": [
            {
              "role": "right hand",               // or null
              "placements": [
                {
                  "position": "1:1:000",          // bar:count:tick, ":subtick" only when non-zero
                  "rhythmic_value": "eighth",     // "half tied to eighth" for ties
                  "sounds": [ "F♯4", "A4" ],      // [] is a rest; two pitches is a chord
                  "beam_break_before"?: false,    // omitted when nil
                  "syllables"?: [ { "text": "glo", "verse"?: 2, "hyphen_after"?: true } ]   // verse omitted when 1
                },
                { "position": "1:3:000:120", "rhythmic_value": "quarter", "sounds": [ { "unpitched": "snare_drum" } ] }
              ],
              "staff_assignments"?: [ { "number": 5, "staff": 1 } ]   // index into the system in force at that bar
            }
          ]
        }
      ],

      "bars": [                                   // sparse: a bar with no repeat state is not written
        { "number": 1, "starts_repeat"?: true },
        { "number": 3, "plays_on_passes"?: [1, 2] },
        { "number": 8, "ends_repeat_after_num_plays"?: 2 }
      ],

      "comments": [ { "text": "da capo", "position": "8:1:000" } ]   // position may be null
    }
  ]
}
```

### Sparse and required keys

| Container | Always present | Omitted when empty or default |
|---|---|---|
| Project | `schema_version`, `name`, `players`, `flows` | |
| Flow | `schema_version`, `name`, `composer` (nullable), `origin` (nullable), `timeline`, `parts`, `bars`, `comments` | |
| timeline | `meter`, `key_signature`, `tempo`, `meter_changes`, `key_signature_changes`, `tempo_changes` | |
| Part | `voices` | `instrument`, `instrument_changes`, `staff_system`, `staff_system_changes` |
| Voice | `role` (nullable), `placements` | `staff_assignments` |
| Placement | `position`, `rhythmic_value`, `sounds` | `beam_break_before`, `syllables` |
| Syllable | `text` | `verse` when 1, `hyphen_after` when false |
| StaffSystem | `bracket`, `staves` | |
| Staff | `clef` (nullable) | `clef_changes` |
| Bar entry | `number` | `starts_repeat`, `ends_repeat_after_num_plays`, `plays_on_passes`; all three absent drops the bar |
| Comment | `text`, `position` (nullable) | |

### Position strings

Written by `Position#code` as `"<bar>:<count>:<tick, three digits>"`, with `":<subtick, three digits>"` appended only when the subtick is non-zero: `"1:1:000"`, `"1:3:000:120"`. Read by `SchemaValues#position`, which accepts one to four non-negative integer fields: `"5"`, `"5:2"`, `"5:2:480"`, `"5:2:480:120"`.

### Reading order

`HashDeserializer#build` applies timeline changes first, then parts (instrument changes, staff system changes, voices, placements, staff assignments), then repeat flags, then comments. The timeline must come first because a position string such as `"2:5:000"` only parses in a bar governed by a meter with five counts. Unknown top-level keys are ignored. `Project.from_h` and `Flow.from_h` both refuse any version but 4.

---

## 5. What Moved from Schema 3

`Flow.from_v3_h` reads the 20.x document and is removed in 22.0.0. The difference is structural, not a renaming of keys.

| Schema 3 (20.x) | Schema 4 (21.0.0) |
|---|---|
| `key_signature`, `meter`, `tempo` at the flow's top level | inside `timeline`, as the map defaults |
| per-bar `key_signature` and `meter` on `bars[]` entries, by name | `timeline.*_changes[]` by bar number; key signatures gain a fifths integer and a tonal context |
| no tempo changes | `timeline.tempo_changes[]` |
| flat `voices[]` on the flow | `parts[].voices[]`; each v3 voice becomes its own part on read |
| no instruments, staff systems, clefs, or staff assignments | `parts[].instrument`, `staff_system`, `staves[].clef`, `voices[].staff_assignments` |
| `bars[]` carry key, meter, and repeat state | `bars[]` carry repeat state only |

Shared unchanged: `name`, `composer`, `origin`, `comments`, per-voice `role` and `placements` with `position`, `rhythmic_value`, `sounds`, `beam_break_before`, and `syllables`.

---

## 6. What Does Not Round-Trip

Three known limits of the schema as shipped, each visible in the writer and reader code.

- **Staff line count and catalog staff.** `Staff#to_h` writes only the clef and its changes. A one-line percussion staff backed by an `Instruments::Staff` comes back as a five-line staff with no catalog backing.
- **The opening key signature's fifths and context.** A change carries both a fifths integer and a tonal context by name. The opening signature carries only the interpreted name, so a flow that opens in C dorian written with three flats cannot express that divergence at bar 1. Author it as a change instead.
- **A staff assignment whose staff is not in the system.** Assignments serialize as an index into the staff system in force at that bar. One naming a staff outside the system is dropped rather than raising on write. Authoring already refuses it, so this only matters for a voice whose part changed systems after the assignment was made.
