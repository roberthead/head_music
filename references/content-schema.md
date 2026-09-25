# Content Schema 4: Object Model and Serialized Document

The `HeadMusic::Content` object model as of 21.1.0, and the document it serializes to. Intended as the reference for anyone reading or writing schema-4 JSON, extending the model, or deciding where a new attribute belongs. Constructor signatures and key names are quoted from source on `main` as of 21.1.0.

---

## 1. Entities and Edges

Every object below `Project` is reachable by ownership from a `Flow`, which is why a flow can stand alone and render without a project. `Player` is the one entity a `Part` points back at without owning it, and it carries no identity beyond its position in the project's authored order. A `Layout` owns nothing at all: it points back at the flows and players it selects, and both selections are written as positions for the same reason.

A `Work` and a `Publication` are *cited*, not owned. A flow writes each one inline, in full, so that a flow standing outside a project still carries the identity of what it is and where it came from. Two flows citing equal works restore to two equal values, and `Project#works` is that list deduplicated.

```
Project ──owns──▶ Player[]            authored order; a chair, not a person
   │
   ├──owns──▶ Credits             project level: arranger, transcriber, orchestrator, reconstructor
   │            └──owns──▶ Credit[] ──▶ Person
   │
   ├──owns──▶ Layout[]            a view; owns no music
   │            │                 Score < Layout adds an ensemble_type and orders and groups the chairs
   │            ├─ back-ref ─▶ Flow[]?     null selects every flow
   │            └─ back-ref ─▶ Player[]?   null selects every player
   │
   └──owns──▶ Flow[]
                ├──cites──▶ Work?          inline; title, catalog number, year
                │             └──owns──▶ Credits    work level: composer, songwriter, lyricist, librettist
                ├──cites──▶ Publication?   inline, as "source"; plus "key" when it is a CantusFirmus::Source
                │             └──owns──▶ Credits    publication level: author, editor, engraver, publisher
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

`Project.new(name: nil, credits: [])`

| Attribute | Type | Cardinality |
|---|---|---|
| `name` | String, defaults to `"Project"` | 1 |
| `players` | `Player`, owned, authored order | 0..* |
| `flows` | `Flow`, owned | 0..* |
| `layouts` | `Layout` or `Score`, owned | 0..* |
| `credits` | `Credits` at the `:project` level | 1 |
| `works` | derived: `flows.filter_map(&:work).uniq` | 0..* |

`add_flow` adopts a standalone flow, mints a `Player` for each player-less part, adopts any player a part already carries into `players` (once, by identity), and raises if the flow, or any of its parts' players, belongs to another project. Players and flows match by object identity. `add_credit(person, role)` replaces the credits with the collection one longer, so the project's arranger is recorded here rather than on any flow. `add_layout(**kwargs)` mints a layout bound to this project and `add_score(ensemble_type:, **kwargs)` mints a `Score`; the project itself renders nothing.

### Player (`content/player.rb`)

`Player.new(project: nil, name: nil)`

| Attribute | Type | Cardinality |
|---|---|---|
| `name` | String or nil | 0..1 |
| `project` | *back-ref* `Project` | 0..1 |
| `parts` | derived: parts across the project's flows whose player is self | 0..* |
| `instruments`, `primary_instrument` | derived from parts | |

Serialized as `{"name"}` only.

### Layout (`content/layout.rb`)

`Layout.new(project:, kind: :custom, flows: nil, players: nil, concert_pitch: true, title_override: nil)`

| Attribute | Type | Cardinality |
|---|---|---|
| `kind` | `:score`, `:part`, or `:custom`; anything else raises | 1 |
| `project` | *back-ref* `Project`, required | 1 |
| `selected_flows` | *back-ref* `Flow`, nil meaning every flow | 0..* |
| `selected_players` | *back-ref* `Player`, nil meaning every player | 0..* |
| `flows`, `players` | derived: the selection, else the project's whole collection | 0..* |
| `concert_pitch` | Boolean; `concert_pitch?` and `transposed?` are its two readings | 1 |
| `title_override` | String or nil | 0..1 |
| `rendered_flows` | derived: selected flows a selected player has a part in | 0..* |
| `title` | derived: the override, else the one work title every selected flow shares, else the project's name | 1 |

A layout renders through `#realize(flow)`, which serializes the flow, drops the parts no selected player fills, renames it, rewrites its pitches when the layout is transposed, and reads a derived flow back. Selection therefore never reaches the writers. `#to_abc` writes a tune book (one `X:` per rendered flow, blank-line separated), `#to_lilypond` one document with a `\score` per flow, and `#to_musicxml_documents` one document per flow -- `#to_musicxml` raises for more than one. A layout selecting nothing renderable raises rather than emitting an empty document.

Rendering is a manifestation fact and changes no content: `title_override` reaches the writers as the realized flow's name, leaving `work.title` and `flow.name` alone, and the written key each part prints is derived at render time (see `Layout::Transposition` and `Notation::RenderPlan`) rather than stored. An all-flows, all-players, concert-pitch layout of one flow therefore renders byte-identically to that flow's own `#to_abc`, `#to_lilypond`, and `#to_musicxml`.

### Score (`content/score.rb`)

`Score.new(project:, ensemble_type: nil, **layout_kwargs)` — a `Layout` with `kind` forced to `:score`

| Attribute | Type | Cardinality |
|---|---|---|
| `ensemble_type` | a `Instruments::ScoreOrder` key (`:orchestral`, `:band`, `:brass_quintet`, `:woodwind_quintet`, `:string_quartet`) or nil; anything else raises | 0..1 |
| `score_order` | derived: `Instruments::ScoreOrder.get(ensemble_type)`, nil when unnamed | 0..1 |
| `ordered_players` | derived: every one of the layout's players in score order | 0..* |
| `player_groups` | derived: `[[section_key, [players]], ...]`, trailing `[nil, [...]]` for unplaced chairs | 0..* |

`ordered_players` is a permutation, never a selection: ties keep authored order, so two clarinets stay first and second, and a chair with no instrument or an instrument the order does not know sorts last. Both readers delegate to `ScoreOrder#position_of` and `#section_key_of`, which share one section index with `#order`, so ordering and grouping cannot disagree. Realization writes the parts in `ordered_players` order; a plain `Layout` keeps the authored order.

### Layout::Transposition (`content/layout/transposition.rb`)

`Transposition.for(instrument)` · `.for_semitones(n)` — a frozen, memoized value object; `new` is private

| Attribute | Type | Cardinality |
|---|---|---|
| `semitones` | `Integer`, written minus sounding, i.e. `-instrument.sounding_transposition` | 1 |
| `octaves`, `diatonic_steps`, `fifths_delta` | derived `Integer`s | 1 each |

`#written(pitch)` and `#key_signature(ks)` answer what the player reads; `#key_signature_event(event)` moves a change to the same position. The move is *spelled*, not counted: the semitones decompose into a simple diatonic interval plus whole octaves, so a clarinet's sounding D is a written E rather than an F♭. A key signature moves by moving its tonic spelling and keeping its scale type, never by arithmetic on fifths. A written key needing more than seven sharps or flats raises `Notation::RenderError` naming the enharmonic to write instead. Pure: it knows pitches and key signatures, and nothing of flows, parts, or documents.

### Flow (`content/flow.rb`)

`Flow.new(name: nil, key_signature: nil, meter: nil, tempo: nil, composer: nil, origin: nil, comments: nil, work: nil, source: nil)`

| Attribute | Type | Cardinality |
|---|---|---|
| `name` | String, defaults to `"Composition"` | 1 |
| `composer`, `origin` | any, serialized via `to_s` | 0..1 |
| `work` | *cited* `Work`, or a hash coerced through `Work.from_h` | 0..1 |
| `source` | *cited* `Publication`, or a hash coerced through `Publication.from_h` | 0..1 |
| `timeline` | `Flow::Timeline`, owned | 1 |
| `parts` | `Part`, owned | 0..* |
| `bars` | `Bar`, sparse array by number, bar 0 allowed | 0..* |
| `comments` | `Comment`, owned | 0..* |
| `project` | *back-ref* `Project` | 0..1 |

The aggregate root that renders: `to_abc`, `to_lilypond`, `to_musicxml`. `voices` is derived from parts. The three musical constructor arguments are not stored on the flow; they become the timeline's opening values.

**`#composer` is `work&.composer || @composer`.** A cited work's composer credits win; the authored string is the fallback, which is what the ABC `C:` and LilyPond `composer =` readers fill with text like `"Trad."` or `"arr. J. Smith"` — not a person, and never minting a `Work`. A work carrying no composer credit falls through to the string, so a lyricist-only work still prints the name it was authored with. `#to_h` writes the derived string under `"composer"`, so a reader that knows nothing of works still prints the name it printed before. `origin` stays a plain string: ABC's `O:` is geographic provenance, an expression fact with nothing at the work level to hold it.

### Work (`content/work.rb`)

`Work.new(title:, catalog_number: nil, year: nil, credits: [])` — a `Data.define` value, frozen and compared by value

| Attribute | Type | Cardinality |
|---|---|---|
| `title` | String | 1 |
| `catalog_number` | String or nil — `"Op. 27 No. 2"`, `"BWV 1007"`, `"K. 545"` | 0..1 |
| `year` | Integer or nil | 0..1 |
| `credits` | `Credits` at the `:work` level; an array is coerced | 1 |

The catalog identity of a composition, independent of any one notated version of it. `#composer` joins the composer credits' names with `", "` and answers nil where there are none — joined rather than translated, because the string lands in ABC, LilyPond, and MusicXML header fields, which have no locale. `#with_credit(person, role)` answers a new work; `#to_s` is the title and catalog number joined. Two equal works `uniq` to one, which is what makes a sonata's four flows report one work and a fake book's eighty report eighty.

### Publication (`content/publication.rb`)

`Publication.new(title:, edition: nil, year: nil, publisher: nil, abbreviation: nil, notes: nil, credits: [])` — hand-rolled, frozen, compared by value

| Attribute | Type | Cardinality |
|---|---|---|
| `title`, `edition`, `publisher`, `abbreviation`, `notes` | String or nil | 0..1 each |
| `year` | Integer or nil | 0..1 |
| `credits` | `Credits` at the `:publication` level | 1 |

A published edition: the book, treatise, or score a flow cites as its `source`. Distinct from the work it publishes, because one work has many editions and one edition holds many works. Not a `Data.define`, because `CantusFirmus::Source` subclasses it to add a catalog `key`; equality is on the publication's own fields, so a source restored from a document still equals the catalog entry it names. `#authors` is `credits.names(:author)`.

`Source#to_h` adds `"key"`, and the flow deserializer resolves a `"source"` carrying one through `Source.get` before falling back to `Publication.from_h` — so `"source": {"key": "fux", ...}` reads back as the catalog's own `CantusFirmus::Source`, with its notes and abbreviation intact. `Publication.from_h` itself always builds a plain publication. `Source.get`, `.all`, `.keys`, `#publication_name`, `#publication_edition`, and `#author_names` are unchanged from 21.0.0.

### Credits (`content/credits.rb`)

`Credits.new(level, credits = [])` · `Credits.from_h(array, level:)` — `Enumerable`, frozen

| Attribute | Type | Cardinality |
|---|---|---|
| `level` | `:work`, `:project`, or `:publication`; anything else raises | 1 |
| `credits` | `Credit`, owned, authored order; hashes are coerced | 0..* |

The one place the level constraint is enforced: a credit whose role belongs to another level raises `ArgumentError` — "`arranger` is a project role, not a work role". `#add(person, role)` answers a new collection rather than mutating this one. `#for(role)` answers the matching credits and `#names(role)` their people's full names, which is how a writer reaches the composer or the arranger.

### Credit (`content/credit.rb`)

`Credit.new(person:, role:)` — a `Data.define` value

| Attribute | Type | Cardinality |
|---|---|---|
| `person` | `Person`; a hash or a bare name is coerced | 1 |
| `role` | `Role`; a key or a translated name is coerced through `Role.get` | 1 |

Level-agnostic on purpose: the `Credits` collection holding it is what decides which roles are admissible. Serialized as `{"role", "person"}`.

### Role (`content/role.rb`)

`Role.get(identifier)` — `Named`, memoized per key; `new` is private

| Level | Roles |
|---|---|
| `:work` | composer, songwriter, lyricist, librettist |
| `:project` | arranger, transcriber, orchestrator, reconstructor |
| `:publication` | author, editor, engraver, publisher |

Twelve roles and no more: an unrecognized identifier raises `ArgumentError` rather than falling through to `Named`'s name-minting getter. `.get` accepts a key, a `Role`, or the role's name in any available locale; `#name(locale_code:)` translates through `head_music.credit_roles`, like `Clef`. `.for_level(level)` lists a level's roles and `#level` answers which one a role belongs to. `author` sits at the publication level because the cantus firmus sources are treatises, whose people are authors rather than editors.

### Person (`content/person.rb`)

`Person.new(full_name:, sort_name: nil, birth_year: nil, death_year: nil)` — a `Data.define` value

| Attribute | Type | Cardinality |
|---|---|---|
| `full_name` | String | 1 |
| `sort_name` | String, defaulting to `full_name` | 1 |
| `birth_year`, `death_year` | Integer or nil, independently omittable | 0..1 each |

One identity, not one spelling of a name: two spellings of a composer are one `Person`. The sort name is resolved in the constructor rather than in the reader, so a person given no sort name equals the same person given the obvious one; it is stored rather than derived, because "Bach, Johann Sebastian" is not a rule that survives van Beethoven, de Falla, or a mononym. A death year preceding the birth year raises. Not `Named`: a proper name is data, not vocabulary. Serialized with all four keys always present.

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
  "credits": [                                    // this version's people: arranger, transcriber,
    { "role": "arranger",                         //   orchestrator, reconstructor
      "person": { "full_name": "Andrés Segovia", "sort_name": "Segovia, Andrés",
                  "birth_year": 1893, "death_year": 1987 } }
  ],
  "flows": [
    {                                             // Flow#to_h, plus one key the project adds:
      "players": [0, null],                       // parallel to "parts": index into project players; null = no player

      "schema_version": 4,
      "name": "Allemande",
      "composer": "Johann Sebastian Bach",        // derived: the work's composer, else the authored string, else null
      "origin": null,

      "work": {                                   // the cited work, written inline; or null
        "title": "Cello Suite No. 1",
        "catalog_number": "BWV 1007",
        "year": null,
        "credits": [                              // composer, songwriter, lyricist, librettist
          { "role": "composer",
            "person": { "full_name": "Johann Sebastian Bach", "sort_name": "Bach, Johann Sebastian",
                        "birth_year": 1685, "death_year": 1750 } }
        ]
      },

      "source": {                                 // the cited publication, written inline; or null
        "title": "Sechs Suiten für Violoncello solo",
        "edition": "Urtext", "year": 2000, "publisher": "Bärenreiter",
        "abbreviation": null, "notes": null,
        "credits": [                              // author, editor, engraver, publisher
          { "role": "editor", "person": { "full_name": "Bettina Schwemer", "sort_name": "Schwemer, Bettina",
                                          "birth_year": null, "death_year": null } }
        ],
        "key"?: "fux"                             // only a catalog entry writes one, and it reads
      },                                          //   back as that entry rather than as a copy

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
  ],

  "layouts": [
    {
      "kind": "part",                             // "score" | "part" | "custom"
      "title_override": "Flute Book",             // or null
      "concert_pitch": true,                      // false renders each part at the pitch its player reads
      "ensemble_type": null,                      // a ScoreOrder key on a score that names one; null otherwise
      "flows": [0, 2],                            // indexes into "flows"; null selects every flow
      "players": [1]                              // indexes into "players"; null selects every player
    },
    {
      "kind": "score",
      "title_override": null,
      "concert_pitch": false,
      "ensemble_type": "orchestral",
      "flows": null,
      "players": null
    }
  ]
}
```

### Sparse and required keys

| Container | Always present | Omitted when empty or default |
|---|---|---|
| Project | `schema_version`, `name`, `players`, `flows`, `layouts`, `credits` | |
| Layout entry | `kind`, `title_override` (nullable), `concert_pitch`, `ensemble_type` (nullable; non-null only on a score), `flows` (nullable), `players` (nullable) | |
| Flow | `schema_version`, `name`, `composer` (nullable), `origin` (nullable), `work` (nullable), `source` (nullable), `timeline`, `parts`, `bars`, `comments` | |
| Work | `title`, `catalog_number` (nullable), `year` (nullable), `credits` | |
| Publication | `title`, `edition`, `year`, `publisher`, `abbreviation`, `notes`, all nullable, and `credits` | `key`, written only by a catalog entry |
| Credit | `role`, `person` | |
| Person | `full_name`, `sort_name`, `birth_year` (nullable), `death_year` (nullable) | |
| timeline | `meter`, `key_signature`, `tempo`, `meter_changes`, `key_signature_changes`, `tempo_changes` | |
| Part | `voices` | `instrument`, `instrument_changes`, `staff_system`, `staff_system_changes` |
| Voice | `role` (nullable), `placements` | `staff_assignments` |
| Placement | `position`, `rhythmic_value`, `sounds` | `beam_break_before`, `syllables` |
| Syllable | `text` | `verse` when 1, `hyphen_after` when false |
| StaffSystem | `bracket`, `staves` | |
| Staff | `clef` (nullable) | `clef_changes` |
| Bar entry | `number` | `starts_repeat`, `ends_repeat_after_num_plays`, `plays_on_passes`; all three absent drops the bar |
| Comment | `text`, `position` (nullable) | |

The four keys added in 21.1.0 — `"work"` and `"source"` on a flow, `"credits"` and `"layouts"` on a project — are always written and never required. Absent means none: a document written by 21.0.0 reads to a flow citing nothing and a project with no credits and no layouts, rather than raising.

### Position strings

Written by `Position#code` as `"<bar>:<count>:<tick, three digits>"`, with `":<subtick, three digits>"` appended only when the subtick is non-zero: `"1:1:000"`, `"1:3:000:120"`. Read by `SchemaValues#position`, which accepts one to four non-negative integer fields: `"5"`, `"5:2"`, `"5:2:480"`, `"5:2:480:120"`.

### Reading order

`Project.from_h` reads players, then flows, then layouts, because a layout names flows and players by index. `HashDeserializer#build` reads the citations first — `"work"` through `Work.from_h` and `"source"` through `Publication.from_h`, each skipped when absent — then timeline changes, then parts (instrument changes, staff system changes, voices, placements, staff assignments), then repeat flags, then comments. The timeline must come first because a position string such as `"2:5:000"` only parses in a bar governed by a meter with five counts. Unknown top-level keys are ignored. `Project.from_h` and `Flow.from_h` both refuse any version but 4.

---

## 5. What Moved from Schema 3

`Flow.from_v3_h` read the 20.x document through 21.x and was removed in 22.0.0, so a v3 document is read with head_music 21.x and saved again. The difference is structural, not a renaming of keys.

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

---

## 7. Additive Keys Do Not Bump the Schema

The rule the version number follows, stated once so that the next key does not have to relitigate it.

- **A rename or a container restructure bumps the schema version.** Both bumps so far were earned that way: schema 3 renamed each placement's `pitches` to `sounds`, and schema 4 moved key, meter, and tempo off the bars and onto a timeline, and voices under parts. An old reader handed such a document reads it *wrongly*, so it must be told to refuse.
- **A new optional key does not.** `Flow#to_h` and `Project#to_h` are read by `HashDeserializer#build` and `Project.from_h`, which look up the keys they know and never enumerate the hash, so an unrecognized key costs nothing. A 21.0.0 reader accepts a 21.1.0 document and loses only the information it has no home for — and `"composer"` still carries the derived name, so even that loss does not reach the page.

Schema 4 therefore covers 21.0.0 and 21.1.0 alike. `"work"`, `"source"`, `"credits"`, and `"layouts"` were added under it, and a document from either version reads in either direction. Bumping to 5 would have made 21.0.0 *reject* documents it can read perfectly well, and forced a second retained reader alongside `Flow.from_v3_h`, which was kept until 22.0.0.

The rule has one condition: a new key must be optional on read and meaningless to a reader that ignores it. A key an old reader would need in order to be correct is a restructure wearing a new name, and takes the bump.
