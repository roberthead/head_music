<!--
metadata:
  created_at:   2026-09-05T16:38:54-07:00
  activated_at: 2026-09-05T17:50:48-07:00
  planned_at:
  finished_at:
  updated_at:   2026-09-05T17:50:48-07:00
-->

# Content Architecture

AS a developer notating music of any kind, not only species counterpoint

I WANT content organized as Project → Flow → Part → Voice over a timeline of event maps

SO THAT a piano voice can cross between staves, a player can change instruments
mid-movement, and a multi-movement work is one document rather than several

Story 1 of [EPIC: Organizing Content](../epics/organizing-content.md).

## Background

`HeadMusic::Content::Composition` is the document, the movement, the timeline, and
the credits at once, and its `Voice` is a bare melodic line with no instrument, no
staff, and no performer. Four specific consequences:

- **A voice cannot be on a staff.** `Notation::ClefSelector.for(voice)` exists only
  because of this — it *infers* a clef from the voice's pitch range, because
  nothing in the model records which staff the voice is written on. Both the
  LilyPond and MusicXML writers depend on that guess.
- **`Content::Staff` is dead.** It is referenced by nothing but its own spec.
- **Timeline changes are modeled twice, incompatibly.** `Content::Bar` carries key
  and meter changes for the Content module; `Time::MeterMap` and `Time::TempoMap`
  do the same job properly and are unused by Content.
- **Positions are modeled twice.** `Content::Position` is `bar:count:tick` bound to
  a composition; `Time::MusicalPosition` is `bar:beat:tick:subtick` and pure. Both
  resolve ticks at 960 PPQN, from two separately-declared constants
  (`Rudiment::Rhythm::PPQN` and `Time::PPQN`).

## The Model

```
Project
  players []                       # chairs; ordered for score order
  flows []

Flow
  project?                         # OPTIONAL — a flow may stand alone
  title
  timeline                         # meter map + tempo map + key signature map
  bars []                          # barlines, repeats, voltas
  parts []

Part
  flow
  player?                          # OPTIONAL — a part with no player is a staff of music
  instrument_map                   # event map over the flow's timeline
  staff_system_map                 # event map
  voices []

Voice
  part
  role                             # retained: "cantus firmus", etc.
  staff_assignment_map             # event map
  placements []

StaffSystem                        # ordered staves + bracket/brace
Staff                              # line count, clef map, optional percussion mapping
```

## Design Decisions

### 1. `Player` is project-level; `Part` is per-flow

A `Player` is a chair in the document ("Flute 1", "Piano"), carrying a name and a
position in score order. A `Part` is that chair's music within one flow. A player
absent from a flow simply has no part there.

In this story `Player` is minimal — a named, orderable chair. Casting a real
person into it belongs to [Ensemble Sessions](ensemble-sessions.md).

### 2. Everything that changes over time is an event map

Extract the generic map from what `Time::MeterMap` and `Time::TempoMap` already
share: an ordered list of `(position, value)` events with `at(position)`,
`changes`, and `each_segment`. `MeterMap` and `TempoMap` keep their typed APIs and
are re-expressed in terms of it, joined by a new `KeySignatureMap` and by the
instrument, staff-system, clef, and staff-assignment maps.

`Bar` keeps only what is genuinely bar-shaped — barlines, repeat structure, volta
brackets — and loses `key_signature` and `meter`, which move to the flow's
timeline. `flow.bar(n).key_signature` remains answerable as a derived read.

#### The key signature event carries a signature and, optionally, an interpretation

```
KeySignatureEvent
  signature        # required — the accidentals printed at the clef
  tonal_context?   # optional — a Key or a Mode; the interpretation
```

A signature underdetermines its interpretation: two sharps is D major, B minor,
E dorian, or A mixolydian. `KeySignature` already behaves this way — its `#==`
compares alterations only, so `KeySignature.get("D major") == KeySignature.get("B minor")`
is true. The tonal context is therefore an analytical claim, and optional.

The interpretation is not derivable from the signature in the other direction
either, because the two can legitimately diverge. C dorian written in cantus
mollis takes the parallel minor's signature and naturalizes the sixth:

```
C dorian alterations: B♭ E♭        # 2 flats — the mode's own collection
C minor  alterations: B♭ E♭ A♭     # 3 flats — what is printed at the clef
```

Stored as `signature: 3 flats, tonal_context: C dorian`, the A-naturals are
ordinary accidentals on the notes. Neither field derives the other, which is why
both are kept.

Mapping to the existing rudiments: the signature is a `KeySignature`; the
interpretation is a `Key` or a `Mode` — the `QualifiedDiatonicContext` subclasses.
`DiatonicContext` is *not* the signature-only abstraction it might appear to be;
`TonalContext` requires a `tonic_spelling`, so every diatonic context already
carries a tonal center.

The two export formats disagree about which field they need, and the writers
already show it:

- **MusicXML** wants `<fifths>` (required) and `<mode>` (optional) — exactly this
  shape. `MusicXML::KeyMapper` derives them from the two facts independently.
- **LilyPond** wants `\key <tonic> <mode>`, which demands an interpretation. A flow
  carrying a signature and no tonal context must fall back to the conventional
  major or minor reading of that signature, and the fallback must be documented
  rather than incidental.

### 3. A voice has a staff at any moment

```ruby
voice.staff_at(position)     # => Staff
voice.cross_to(staff, from: position, until: other_position)
```

The staff-assignment map defaults to the part's first staff, so a single-staff
part needs no assignments at all. A one-note cross-staff is a span of one note's
duration — no note-level special case.

`ClefSelector` survives, demoted: it is the fallback for a part whose staves were
never authored (an ABC import, a bare counterpoint exercise), not the primary
source of truth. When a staff has an authored clef, writers use it.

### 4. One position type

`Content::Position` becomes a `Flow`-bound wrapper around a `Time::MusicalPosition`
value, delegating value semantics and inheriting `RadixCarry` normalization rather
than duplicating it. `Time` stays pure and flow-unaware; `Content` supplies the
binding that makes meter lookup possible.

Two naming corrections fall out:

- **`beat` → `count`.** `Meter` already distinguishes `beats_per_bar` from
  `counts_per_bar` — in 6/8 there are 2 beats and 6 counts — so
  `MusicalPosition#beat` is misnamed against the gem's own vocabulary. It is a
  count. `Content::Position` already gets this right.
- **One PPQN.** `Time::PPQN` and `Rudiment::Rhythm::PPQN` are the same 960 declared
  twice; keep the `Rudiment::Rhythm` declaration and alias the other.

`Content::Position` gains the subtick it currently lacks.

### 5. Staves layer: catalog → instance → rendering

Three staff-ish vocabularies already exist and must not be merged carelessly:

| Layer | Module | Role |
|---|---|---|
| Catalog | `Instruments::Staff`, `StaffScheme`, `StaffProfile` | what a piano's staves *are*, from YAML |
| Instance | `Content::StaffSystem`, `Content::Staff` | what *this* part uses, and when |
| Rendering | `Notation::StaffPosition`, `StaffMapping`, `InstrumentNotation` | how it appears |

The catalog layer is unchanged. The instance layer replaces today's dead
`Content::Staff`: a `Content::Staff` has a line count, a clef map, and an optional
instrument binding for percussion mapping; a `Content::StaffSystem` is an ordered
set of them with a bracket or brace. A part's staff system defaults from
`part.instrument_at(position).default_staff_scheme`.

### 6. Containment is total; context is optional

A chunk of music that does not live inside a project is a **`Flow` with no
project** — not a new noun. A flow already owns exactly the context a standalone
piece of music needs (a timeline and bars) and none of what it does not (players,
score order, layouts). This is also Dorico's own use of flows: worksheets of short
examples, scales, and exercises, each a flow in its own right.

Two rules make it work:

- **Containment never has holes.** A voice is always in a part, always in a flow;
  a placement is always in a voice. `voice.part.staff_system_at(position)` needs
  no nil check, ever.
- **Upward context is optional.** `Flow#project`, `Flow#work`, and `Part#player`
  may be absent. A part with no player is simply a staff of music — which is
  precisely what an ABC voice or a LilyPond staff is on import.

Corroborating the level choice: `Content::Position` binds to a **`Flow`**, not to
a project (decision 4). The level that owns the timeline is the level that can
stand alone.

Adoption is the operation that closes the gap:

```ruby
project.add_flow(flow)      # mints players for the flow's unpaired parts
```

A `Part` with no flow is explicitly rejected. Strip the flow and it has no
timeline; strip the project and it has no player; what remains is a voice. The
cases that seem to want it do not: a printed viola part is a `Layout` over a flow,
and a pastable instrument's-worth of music is a flow with one part.

#### `CantusFirmus::Example` realizes into a standalone flow

`Example` is a *catalog datum*, not content — a pitch list with a mode and a
citation, which nothing in the gem currently turns into music. It gains a
realization instead of remaining a dead end:

```ruby
example = CantusFirmus::Example.find_by_slug("fux-d-dorian")
flow = example.to_flow      # one part, no player, one voice, whole notes
flow.to_lilypond            # renders without a project
```

Rhythm and meter are the realization's choice, not the datum's, so they are
parameters (`to_flow(rhythmic_value: :whole, meter: "4/4")`) defaulting to the
pedagogical norm.

The example's `tonal_center` and `mode` land on the flow's opening key signature
event with no loss: `KeySignature.get("D dorian")` retains `scale_type = dorian`
and renders as "no sharps or flats", so the mode survives as the event's tonal
context and the signature derives from it.

### 7. Hard break

`Composition` is removed, not deprecated. Schema goes to 4 with no v3 reader —
serialized v3 documents are re-authored, not migrated.

Call sites to move: the ABC, LilyPond, and MusicXML readers and writers (all three
`RenderPlan`s take a composition today), `Notation::PreflightChecks`,
`Style::Guideline` and its `VoiceContext`, and every guideline that reaches
through a voice to its composition.

Counterpoint's shape under the new model: one `Project`, one `Flow`, one `Part`
per voice, one `Voice` per part. `Flow#cantus_firmus_voice` and
`#counterpoint_voice` are preserved.

## Acceptance Criteria

- A `Project` holds ordered `Player`s and any number of `Flow`s; a `Flow` holds one
  `Part` per player present in it.
- A `Part` answers `#instrument_at(position)` and `#staff_system_at(position)`, and
  both change mid-flow while the part remains one part with one player.
- A `Voice` answers `#staff_at(position)`; a voice placed across a staff change
  reports different staves for placements on either side of it.
- A piano part with two staves renders a voice that crosses between them: MusicXML
  emits the correct `<staff>` per note, LilyPond emits `\change Staff` at the span
  boundaries.
- A flow's meter, tempo, and key signature are read from its timeline;
  `Bar` no longer carries key signature or meter, and still carries repeat
  structure and voltas.
- A key signature event stores a signature with no tonal context, and a flow so
  written renders to MusicXML with `<fifths>` and no `<mode>`.
- A key signature event whose signature and tonal context diverge — C dorian
  written with three flats — round-trips both, and MusicXML emits three flats with
  `dorian`.
- A flow with no tonal context renders to LilyPond by the documented fallback
  rather than raising.
- `Content::Position` and `Time::MusicalPosition` are one value type with one tick
  resolution, addressed in bars, counts, ticks, and subticks.
- A `Flow` built with no project holds parts, voices, and placements, answers its
  timeline, and renders to ABC, LilyPond, and MusicXML without a project.
- `project.add_flow(flow)` adopts a standalone flow and mints a player for each
  part that has none; parts that already had players keep them.
- `CantusFirmus::Example#to_flow` returns a standalone flow whose voice sounds the
  example's pitches in order.
- Round-trip serialization at schema 4 preserves players, flows, parts, voices,
  staff assignments, instrument changes, and repeat structure — and round-trips a
  standalone flow as its own document.
- Existing species counterpoint guides assess a single-flow project unchanged in
  result.
- `Composition` no longer exists in `lib`, and no spec references it.

## Out of Scope

- **Constructing a `KeySignature` from a bare signature.** `KeySignature.get("2 sharps")`
  raises today, so a signature can only be built by naming an interpretation of it
  — and `#name` then reports that interpretation ("D major") even where only the
  accidentals were meant. Two small changes are wanted: a construction path from
  alterations or a fifths integer, and a `#name` that does not assert a tonic it
  was never given. That is `Rudiment` work with its own tests and belongs in its
  own story; this story consumes whatever `KeySignature` offers.
- `Work`, `Person`, `Credit`, `Layout`, `Score` — [Identity and Presentation](identity-and-presentation.md).
- Casting people into players — [Ensemble Sessions](ensemble-sessions.md).
- Engraving concerns: spacing, collision, page turns.
- Cross-*part* voices. A voice belongs to exactly one part; a line that appears in
  another player's staff is a cue, which is a layout concern.
- **`Fragment`** — relatively-positioned content with no anchor, placed into a
  voice at a position. A motif, a rhythm cell, a chord voicing. It was proposed
  for this story and is deliberately deferred: with the standalone flow above, no
  current consumer needs it. The cantus firmus case is a *complete piece*, not an
  anchorless shape, and snippet parsing lands on a flow just as well. What would
  earn it is motif transformation — inversion, retrograde, augmentation — or a
  reusable voicing library, neither of which the gem does yet.
