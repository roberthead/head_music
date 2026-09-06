<!--
metadata:
  created_at:   2026-09-05T16:38:54-07:00
  activated_at: 2026-09-05T17:50:48-07:00
  planned_at:   2026-09-05T20:48:21-07:00
  finished_at:
  updated_at:   2026-09-06T10:39:11-07:00
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
Staff                              # line count, clef map, -> Instruments::Staff?
```

`Flow#timeline` is a `Flow::Timeline` holding the three maps, with `Flow`
delegating to it (decision 7).

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
  signature        # required — Integer, fifths (negative = flats)
  tonal_context?   # optional — a Key or a Mode; the interpretation
```

A signature underdetermines its interpretation: two sharps is D major, B minor,
E dorian, or A mixolydian. `KeySignature` already behaves this way — its `#==`
compares alterations only, so `KeySignature.get("D major") == KeySignature.get("B minor")`
is true. The tonal context is therefore an analytical claim, and optional.

**The signature is a fifths integer, not a `KeySignature`.** An earlier draft of
this story said `KeySignature`, and that cannot be built: `KeySignature.get("3 flats")`
raises, so the only way to express three flats is to name an interpretation of it
(`KeySignature.get("C minor")`) — after which the event stores tonic `C` and
quality `minor` as noise that is *actively wrong* whenever `tonal_context` says
C dorian. That is a field that lies, which is what this story rejects everywhere
else. Fifths is also exactly what MusicXML stores, and it leaves the `Rudiment`
gap in Out of Scope genuinely optional rather than blocking.

`KeySignature` is unusable as a map value for two further reasons: `#==` raises on
`nil`, and there is no `#hash` override, so it cannot dedupe.

The interpretation is not derivable from the signature in the other direction
either, because the two can legitimately diverge. C dorian written in cantus
mollis takes the parallel minor's signature and naturalizes the sixth:

```
C dorian alterations: B♭ E♭        # 2 flats — the mode's own collection
C minor  alterations: B♭ E♭ A♭     # 3 flats — what is printed at the clef
```

Stored as `signature: -3, tonal_context: C dorian`, the A-naturals are ordinary
accidentals on the notes. Neither field derives the other, which is why both are
kept.

The interpretation is usually a `Key` or a `Mode` — the `QualifiedDiatonicContext`
subclasses. `DiatonicContext` is *not* the signature-only abstraction it might
appear to be; `TonalContext` requires a `tonic_spelling`, so every diatonic
context already carries a tonal center.

**But `Key` and `Mode` do not cover every signature the gem admits, so the
interpretation may also be a `KeySignature`.** `KeySignature.get("C harmonic_minor")`
is valid, and `harmonic_minor` is neither a `Key::QUALITIES` member nor one of
`Mode::MODES`. Narrowing every signature into one of the two subclasses moves
that limit from render time to *construction* time: a flow in C harmonic minor
becomes unbuildable, when today it builds fine and merely cannot be rendered as
a MusicXML `<key>` element. So the tonal context narrows to a `Key` or a `Mode`
where the scale type is one, and stays a `KeySignature` where it is not.

The two export formats disagree about which field they need:

- **MusicXML** wants `<fifths>` (required) and `<mode>` (optional) — exactly this
  shape. `MusicXML::KeyMapper` must be re-signatured to match: today `.mode` reads
  the *signature's* scale type and never returns nil, and the writer emits
  `<mode>` unconditionally. It becomes `fifths(signature)` and `mode(tonal_context)`,
  the latter accepting nil. This is a real API change to a class with its own
  spec, not the no-op an earlier draft implied.
- **LilyPond** wants `\key <tonic> <mode>`, which demands an interpretation, and
  has **no rendering for the divergent case** — `\key c \dorian` prints two flats,
  and no `\key` command means "three flats read as dorian." Where the two diverge,
  **prefer the signature** (`\key c \minor`), since this story defines the
  signature as what is printed at the clef.

#### The fifths fallback table has two callers

A flow may carry a signature with no tonal context, and two consumers then need
the conventional reading of that signature:

- **LilyPond**, which cannot emit `\key` without a tonic and mode.
- **`Style::Guideline`**, whose `Diatonic` guideline needs a tonic —
  `guideline.rb:35-36` delegates `key_signature` to the container and
  `tonic_spelling` to that.

Build one fifths → `Key` table in `Rudiment` and use it in both places, rather
than letting LilyPond read `tonic_spelling` off whatever the signature happened to
be constructed as. Non-negative fifths give the major key with that many sharps;
negative give the major key with that many flats.

**The signature itself is unbounded; the table is not.** Theoretical keys run past
seven — `MusicXML::KeyMapper.fifths` already answers 8 for G♯ major and 9 for
D♯ major, counting each double accidental twice — so the signature must carry them.
The fallback table covers only −7..+7, because beyond that there is no conventional
major key to name. A signature outside that range **with no tonal context** has no
reading and raises; the same signature *with* a tonal context renders fine, since
nothing needs the fallback.

### 3. A voice has a staff at any moment

```ruby
voice.staff_at(position)     # => Staff
voice.cross_to(staff, from: position, through: other_position)
```

(`until:` would be a Ruby keyword.)

The staff-assignment map defaults to the part's first staff, so a single-staff
part needs no assignments at all. A one-note cross-staff is a span of one note's
duration — no note-level special case.

`ClefSelector` survives, demoted: it is the fallback for a part whose staves were
never authored (an ABC import, a bare counterpoint exercise), not the primary
source of truth. When a staff has an authored clef, writers use it.

### 4. One position type

`Content::Position` becomes a `Flow`-bound wrapper around a `Time::MusicalPosition`
value, **delegating to** it for value semantics and `RadixCarry` normalization
rather than duplicating them. `Time` stays pure and flow-unaware; `Content`
supplies the binding that makes meter lookup possible.

A position is **immutable**: construct it, normalize once, freeze, and never
expose the mutable inner value. `MusicalPosition#normalize!` mutates in place, so
without this the wrapper inherits a mutable identity for a value type that is used
as a sort key.

Three equality questions are settled here rather than discovered:

- `#<=>` compares the `[bar, count, tick, subtick]` tuple lexically.
- `#eql?` and `#hash` are defined on that same tuple, alongside `#<=>` — not left
  to `Object` identity.
- **The flow does not participate in `#==`.** Today `Comparable#==` derives from a
  flow-blind `#<=>`, so positions in different flows already compare equal, and
  `Voice#placement_at` guards with exactly that comparison. Preserving it keeps
  `placement_at` working; changing it is a silent behavior change to note lookup.

Two naming corrections fall out:

- **`beat` → `count`.** `Meter` already distinguishes `beats_per_bar` from
  `counts_per_bar` — in 6/8 there are 2 beats and 6 counts — so
  `MusicalPosition#beat` is misnamed against the gem's own vocabulary. It is a
  count. `Content::Position` already gets this right.
- **One PPQN.** `Time::PPQN` and `Rudiment::Rhythm::PPQN` are the same 960 declared
  twice; keep the `Rudiment::Rhythm` declaration and alias the other.
  `SUBTICKS_PER_TICK` has no `Rudiment` counterpart and stays in `Time`.

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
**reference to an `Instruments::Staff`** for percussion mapping — the catalog
class already owns `mappings`, `mapping_for_position`, `instrument_for_position`,
and `positions_for_instrument`, so the instance layer references rather than
re-implements. A `Content::StaffSystem` is an ordered set of them with a bracket
or brace.

**Seeding must be pinned, because nothing seeds an instrument map.** `MeterMap`
seeds 4/4, but `part.instrument_at(position).default_staff_scheme` is a
`NoMethodError` on nil for this gem's two commonest cases — a counterpoint part
and a standalone flow. So: an instrument map with no events answers nil, and
`staff_system_at` falls back to a one-staff system.

The clef fallback stays **in the writers** (`staff.clef_at(position) ||
ClefSelector.for(voice)`), not in `Staff#clef_at`. `ClefSelector` reads a *voice's*
pitch range, so putting the fallback on the staff would require a `Staff → Voice`
back-reference the model does not otherwise have. There are only two lib call
sites, so the demotion is cheap.

Note for the CHANGELOG: `Content::Staff` is deleted and a different type
reintroduced under the same constant, in one commit. A 20.x caller of
`Content::Staff.new(:bass_clef)` gets wrong output rather than a `NoMethodError`,
so it needs its own migration bullet.

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

**Total containment means `Voice.new` mints its own chain.** `Voice#initialize`
today invents a container when given none (`voice.rb:17`), and the 532-line
`voice_spec.rb` depends on that. Preserve it: a bare `Voice.new` mints
`Flow → Part → Voice` rather than raising. Rejecting a flow-less `Part` (below)
and self-provisioning a container are consistent — neither ever yields a voice
whose containment has a hole.

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
event with no loss, as the two fields of decision 2: `tonal_context` is
`Mode.get("D dorian")`, and `signature` is that collection's fifths — `0`, since
dorian on D is the white-note collection. The mode is carried by the tonal
context, not inferred from the signature, which is what lets an example in
E phrygian and one in D dorian share a signature of `0` without collapsing into
each other.

### 7. `Flow::Timeline` owns the three maps

The maps get an owner rather than hanging off `Flow` directly. `Flow` delegates
`meter_at`, `tempo_at`, and `key_signature_at` to a `Flow::Timeline` holding the
meter, tempo, and key-signature maps.

This is a complexity budget, not taste: `rake validate` runs rubycritic, and a
`Flow` absorbing bars, voices, `to_abc`, `to_h`, and `to_lilypond` *plus* three
maps flogs badly enough to fail it.

### 8. A `Flow` renders; a `Project` does not

`Flow#to_abc`, `#to_lilypond`, and `#to_musicxml` are **permanent public API**, not
a temporary home for methods that `Layout` will take over. Rendering one flow is
exactly what a standalone flow needs, and story 2's `Layout` adds the case above
it — selective, multi-flow, transposed, for a chosen set of players.

**`Project` gets no `to_musicxml`.** "Render three flows" has no answer without a
layout to select among them, and inventing one here would be a method story 2 has
to remove.

### 9. Metadata parks on `Flow`; instruments are derived

`composer` and `origin` park on `Flow` as plain strings and serialize at v4. All
three writers emit them today, so dropping them regresses output, and `Work` is
story 2. When `Work` arrives, `Flow#composer` delegates to `work&.composer` and
falls back to the string — superseded without a second breaking change.

`Player#instruments` is **derived**, not stored: the union of its parts'
instrument-map values across the project's flows, with `#primary_instrument` the
one in force at the opening of its first part. `Instruments::ScoreOrder` orders by
that. Derived because a stored field would drift from the parts that actually
carry the instrument.

### 10. Hard break, with one compatibility reader

`Composition` is removed, not deprecated, and schema goes to 4.

**`Flow.from_v3_h(hash)` ships read-only in 21.0.0 and is deleted in 22.0.0.**
The previous bumps got by with a migration recipe — v2→v3 was "rename each
placement's `pitches` key to `sounds`", doable in SQL against a jsonb column — but
v3→v4 restructures the container, so no equivalent recipe can be written. Without
a reader in 21.0.0 a downstream app would need two gem versions loaded at once to
migrate. `HashDeserializer` already replays v3 through the public builder API, so
this is a narrow retention rather than new work.

Call sites to move: the ABC, LilyPond, and MusicXML readers and writers (all three
`RenderPlan`s take a composition today), `Notation::PreflightChecks`,
`Style::Guideline` and its `VoiceContext`, and every guideline that reaches
through a voice to its composition. **`Guideline#key_signature` reads the flow's
opening key signature event** — behavior-preserving under a key map, and the
choice must be explicit or ~85 specs go red for a reason nobody attributes
correctly. `Guide#assess` never raises for want of a tonal context; it falls back
through the fifths table.

This is **21.0.0**. `LilyPond.parse` and `ABC.parse` change return type five days
after shipping in 20.0.0/20.1.0, so the migration notes name them individually —
a reader scanning for "Composition" will not otherwise realize `parse` moved. The
v3 hard-fail names 20.1.0 as the last version that reads it.

Counterpoint's shape under the new model: **one `Flow`** — no project required —
with one `Part` per voice and one `Voice` per part. `Flow#cantus_firmus_voice` and
`#counterpoint_voice` are preserved.

## Acceptance Criteria

- A `Project` holds `Player`s in **authored (insertion) order** and any number of
  `Flow`s; a `Flow` holds one `Part` per player present in it. (`ScoreOrder`
  sorting belongs to `Score` in story 2; declaring authored order here keeps the
  two stories from contradicting.)
- A `Part` answers `#instrument_at(position)` and `#staff_system_at(position)`, and
  both change mid-flow while the part remains one part with one player.
- A `Voice` answers `#staff_at(position)`; a voice placed across a staff change
  reports different staves for placements on either side of it.
- A piano part with two staves renders a voice that crosses between them: MusicXML
  emits `<staves>2</staves>` and `<staff>2</staff>` on the crossed notes, LilyPond
  emits `\change Staff` at the span boundaries. **`spec/support/lily_pond_helpers.rb`
  must be extended first** — it strips only key and time commands and then requires
  every remaining token to match `SIMPLE_TOKEN` (which `\change Staff` fails), and
  asserts `music_lines.length == bars * voices`, which breaks once one part holds
  two staves.
- A flow's meter, tempo, and key signature are read from its timeline;
  `Bar` no longer carries key signature or meter, and still carries repeat
  structure and voltas.
- A key signature event stores `signature: 2` with no tonal context; the flow
  renders to MusicXML with `<fifths>2</fifths>` and **no** `<mode>` element, and to
  LilyPond as `\key d \major` via the fifths table.
- A key signature event whose signature and tonal context diverge — `signature: -3,
  tonal_context: C dorian` — round-trips both **through schema-4 JSON**, and
  renders to MusicXML as `<fifths>-3</fifths>` with `<mode>dorian</mode>` and to
  LilyPond as `\key c \minor` (signature preferred, per decision 2).
- A signature outside −7..+7 (a theoretical key such as G♯ major, fifths 8) renders
  when the event carries a tonal context, and raises when it does not — the fifths
  fallback table has no entry beyond seven.
- A meter or key signature event placed anywhere but a downbeat raises. (Both are
  bar-aligned by definition, which is what lets the maps key by bar number.)
- `flow.position("2:3:480:120").to_a == [2, 3, 480, 120]`, and
  `Time::PPQN.equal?(Rudiment::Rhythm::PPQN)`.
- Placing notes across a meter change preserves order: `voice.placements` is
  ascending and `placement_at` retrieves each one. (Guards the `bsearch` in
  `Voice#place`.)
- A `Flow` built with no project holds parts, voices, and placements, answers its
  timeline, and renders to ABC, LilyPond, and MusicXML without a project.
- `project.add_flow(flow)` adopts a standalone flow and mints a player for each
  part that has none, named from the part's opening instrument or "Part N";
  parts that already had players keep them. Adopting a flow this project already
  owns is a no-op; adopting one owned by another project raises.
- A flow with zero parts raises at preflight when rendered to MusicXML, which
  requires at least one `<score-part>`.
- `voice.staff_at` past the end of a `cross_to` span returns the part's first
  staff; `cross_to` raises when the target staff is absent from the staff system
  in force over the span.
- `CantusFirmus::Example#to_flow` returns a standalone flow whose voice sounds the
  example's pitches in order.
- Round-trip serialization at schema 4 preserves players, flows, parts, voices,
  staff assignments, instrument changes, and repeat structure — and round-trips a
  standalone flow as its own document.
- `Flow.from_v3_h` reads a schema-3 hash into an equivalent flow; `Flow.from_h`
  rejects one with an error naming 20.1.0 as the last version that read it.
- Species counterpoint guides assess each corpus voice to **the fitness captured
  in a fixture before the refactor began**. (Capture that fixture in Phase 0 —
  without it this reduces to "the guide specs still pass," since most assert
  `marks_count` on hand-built material rather than end-to-end fitness.)
- `HeadMusic::Content.const_defined?(:Composition, false)` is false. (The
  `inherit` flag matters: constant lookup from a module reaches `Object`, so the
  one-argument form would also answer true for any top-level `Composition` another
  gem happens to define. That no *spec* references it is a grep, enforced in
  review rather than as an example.)

## Out of Scope

- **Constructing a `KeySignature` from a bare signature.** `KeySignature.get("2 sharps")`
  raises today, so a signature can only be built by naming an interpretation of it
  — and `#name` then reports that interpretation ("D major") even where only the
  accidentals were meant. Two small changes are wanted: a construction path from
  alterations or a fifths integer, and a `#name` that does not assert a tonic it
  was never given. That is `Rudiment` work with its own tests and belongs in its
  own story. **Storing the signature as a fifths integer (decision 2) is what
  keeps this optional** — an earlier draft made it a blocker.
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

## Implementation Plan

Phases each end green (`bundle exec rake`, ~2m38s). Phases 0-2 are additive and
touch no consumer.

### Two pre-existing bugs that must be fixed first

Both live in `Time::MusicalPosition` — the type this story adopts as the unified
position — and both were reproduced against the gem:

**`normalize!` destroys the last count of every bar.** `RadixCarry#carry` uses
`divmod`, correct for 0-indexed `tick`/`subtick` and wrong for the 1-indexed
`beat`:

```
3/4  1:3:0:0 -> 2:0:0:0        6/8  1:6:0:0 -> 2:0:0:0
4/4  1:4:0:0 -> 2:0:0:0        7/8  1:7:0:0 -> 2:0:0:0
```

**`#<=>` is not a total order across a meter change.** `to_total_subticks` reads
a single `@meter` and assumes every prior bar had it:

```
(4,4) normalized 4/4 -> total=3456000
(5,1) normalized 7/8 -> total=3225600     cmp=1, inverted
```

Both are latent today only because `Time` is essentially unused by `Content` —
which is what the Background section describes. This refactor makes them live and
data-destroying on the path every note travels, which is why the position work
leads rather than follows. `Content::Position`'s lexical `[bar_number, count, tick]`
comparison is the sound one, and `EventMapSupport#compare_positions` already
bypasses `#<=>` in favor of the tuple.

### Coverage budget

`spec/spec_helper.rb` sets `minimum_coverage 90` (line 9) *and*
`maximum_coverage_drop 1.0` (line 22) against a baseline of 99.74% line coverage.
`coverage/` is gitignored and CI runs from a fresh checkout, so the drop guard is
inert in CI but binds every local run — a budget of roughly **87 wholly-uncovered
new lines per run**, not the ~930 the 90% floor would allow. Spec each new class
in the commit that creates it.

### Phase 0 — Fix the position bugs, and capture the grading baseline

Fix `RadixCarry` for 1-indexed components; replace `MusicalPosition#<=>` with
lexical tuple comparison and move `to_total_subticks` onto the meter-map owner
(`Conductor`). Releasable on their own merits with zero model change.

**Also capture the corpus fitness fixture here, before any structural change** —
every guide assessed against every corpus voice, written to a fixture. This is
what makes "guides assess unchanged" a real assertion rather than "the specs still
pass"; `bin/guide_grade_corpus.rb` already produces exactly this shape for the
`.grades.md` reports, so it is a script invocation rather than new tooling.

Deleting the old comparator also removes `TempoMap#normalize_position` and its
`attr_writer :meter`, which exist only to compensate for it. Verify
`conductor_spec.rb` stays green; a dependency on the old ordering is itself a bug.

### Phase 1 — Extract `Time::EventMap`; one PPQN; `beat` → `count`

A **class holding opaque values, composed into** `MeterMap`/`TempoMap` rather than
inherited — three different first-event policies (meter requires a non-removable
first event, tempo carries an extra `@meter`, staff assignment defaults with no
stored event) mean a superclass needs a hook per policy where a constructor
argument does not. Matches the project's "prefer delegation over inheritance".

Two API requirements that are expensive to retrofit:

- **`at` must be a `bsearch`, not `reverse.find`.** Post-refactor every rendered
  note takes up to five map lookups, and `Position` construction itself calls
  `meter_at` in a rollover loop. Precompute each event's tuple at insert.
- **`change_at` is required.** Three consumers need "is there an *explicit* change
  at this bar" as distinct from "what value is in force":
  `RenderPlan#measure_key_changes`, ABC's mid-piece check, and LilyPond's conflict
  detection.

`Time::PPQN` becomes an alias of `Rudiment::Rhythm::PPQN`. Keep
`EventMap#each_segment` normalization-free and leave `TempoMap`'s normalizing
wrapper in place — `Conductor` depends on the difference.

### Phase 2 — `Flow`, `Part`, `Player`, `Project`, bridged by `Composition < Flow`

`Flow` carries what `Composition` carries plus `parts`; `Flow#voices` is
`parts.flat_map(&:voices)`; `Flow#add_voice(role:)` mints a player-less `Part`
holding one `Voice`. `composition.rb` shrinks to `class Composition < Flow; end`.

The bridge is an intra-branch device that never ships — the hard break in
decision 10 is about the released API, not intermediate commits. It dies in
Phase 3.

**The migration lever is the constructor, not a spec helper.** `CompositionContext`
is referenced by only 3 files; the real surface is 93 spec files, 180
`Composition.new` sites and 258 `add_voice` calls, all built inline. A
shape-preserving `Flow.new` plus `Flow#add_voice` makes the migration one `sed`
with no semantic review — and one `Part` per `Voice` is decision 10's own
prescription, not a shim smuggled past it.

`Flow#voices` alone migrates the notation layer: all 17 `.voices` sites in `lib`
are flat iterations. MusicXML's one-`<score-part>`-per-voice is the sole exception,
deferred to Phase 7.

### Phase 3 — Mechanical rename; `Composition` deleted

One `sed` of the constant across 93 spec files and the **4 lib construction
sites** (`content/voice.rb:17`, `hash_deserializer.rb:47`, `abc/parser.rb:45`,
`lily_pond/composition_builder.rb:56`). Rename `composition_builder.rb` →
`flow_builder.rb`, move `content/composition/*` → `content/flow/`, delete
`composition.rb` and the dead `content/staff.rb` with its spec.

Restrict the `sed` to the constant; leave `let(:composition)` names to a cosmetic
pass. Coverage rises — the dead staff class takes 27 covered lines with it.

### Phase 4 — Timeline becomes the source of truth

**4a (additive):** `Flow#timeline` holds meter, tempo, and a new
`KeySignatureMap`. `Bar#key_signature`/`#meter` become derived reads. Zero
consumer changes; existing specs now prove the maps.

**4b (repoint and delete):** move `render_plan.rb:25-33` (**keeping the
`{bar_number => value}` return shape**, which is what leaves both writers
untouched), `music_xml/divisions.rb:22`, `abc/writer.rb:47-57`,
`lily_pond/flow_builder.rb:126`, and `Content::Position#meter`. Then drop the
`Bar` readers and their serialization.

**Key these maps by bar number, not position.** These events are bar-aligned by
definition, and position-keying creates a construction cycle: `Position.new`
rolls over, asks `flow.meter_at(self)`, and the map reads a `count` that has not
been rolled over yet. Bar-keying also keeps `Time` free of a `Content` dependency,
which the load order requires. **Corollary: reject meter and key events off a
downbeat.**

**Risk — the pickup-bar coupling.** `Composition#earliest_bar_number` includes
`first_allocated_bar_number`, so a key change at bar 0 pulls the bar range to 0,
which is what makes MusicXML emit `implicit="yes"`. With maps that coupling
vanishes silently unless `earliest_bar_number` unions the voices' earliest bar
with the maps' earliest event. **Write a characterization spec for the bar-0 →
`implicit="yes"` output before touching anything.** Keep an explicit `Flow#bar(n)`
allocator — `ABC::RepeatTagger` and `HashDeserializer` depend on allocate-on-read.

### Phase 5 — One position type

`Content::Position` wraps a `MusicalPosition` plus the flow, gains `subtick`, and
keeps `#code`/`#values`/`#strength`/`#+`/`#start_of_next_bar`. Construct,
`normalize!` once, freeze, never expose the mutable inner value.

Define `#eql?`/`#hash` alongside `#<=>` in the same commit, and decide explicitly
whether the flow participates in `#==` — today `Comparable#==` derives from a
flow-blind `#<=>`, so positions in *different flows* compare equal, and
`placement_at` guards with exactly that comparison.

Serialization is a 10-file diff, not 82: the 911 position literals are constructor
*inputs*, and only 91 output assertions exist. Keep the parser lenient and emit
subtick only when nonzero.

**Risk — the silent one.** `Voice#place` bsearches over `Position#<=>`. A
non-monotonic comparator returns the *wrong placement* rather than raising.
Phase 0 is the mitigation; add a spec placing notes across a meter change and
asserting both `placements` order and `placement_at` retrieval.

### Phase 6 — Parts, staves, cross-staff (additive)

`Part#instrument_at`/`#staff_system_at`, `Content::Staff` and
`Content::StaffSystem`, `Voice#staff_assignment_map`/`#staff_at`/`#cross_to`,
`Project#add_flow`.

**Pin the seeding policy first.** `MeterMap` seeds 4/4; nothing seeds an
instrument map, so decision 5's `part.instrument_at(position).default_staff_scheme`
is a `NoMethodError` on nil for the two commonest cases in this gem — a
counterpoint part and a standalone flow. Specify: instrument maps answer nil, and
`staff_system_at` falls back to a one-staff system.

**Keep the clef fallback in the writers** (`staff.clef_at(position) ||
ClefSelector.for(voice)`), not in `Staff#clef_at` — `ClefSelector` reads a
*voice's* pitch range, and putting the fallback on the staff would require a
`Staff → Voice` back-reference the model does not otherwise have.

Most likely phase to trip the 87-line drop budget: four new classes with no
consumers until Phase 7.

### Phase 7 — Writers emit staves and voices

**One format at a time, ABC → LilyPond → MusicXML.**

- **ABC first** — it raises for >1 voice, so cross-staff is inexpressible; it
  needs only the container rename.
- **LilyPond second** — best-instrumented: a round-trip spec asserts reader and
  writer against each other, and CI compiles the output with the real `lilypond`
  binary. That is where `\change Staff` is proven to actually engrave.
- **MusicXML last** — no reader, therefore no round-trip; its only net is XPath
  assertions. Do it when the model has stopped moving.

Because `Flow#add_voice` mints one `Part` per `Voice`, every existing fixture
still yields one `<score-part>` and one `\new Staff` per voice — **byte-identical
output for all current specs.** Only new two-staff-piano fixtures exercise new
paths.

### Phase 8 — Schema 4, `Example#to_flow`, cleanup

`SCHEMA_VERSION = 4`, `Project#to_h`/`.from_h`, standalone flow as its own
document. `SchemaValues`' 12 validators are container-agnostic and reuse wholesale
— only the container walk is rewritten. `Example#to_flow(rhythmic_value: :whole,
meter: "4/4")`. Rename `CompositionContext` → `FlowContext` and scrub prose.

**`Flow.from_v3_h` lands here too.** Today's `HashDeserializer` is *retained* as
the v3 reader rather than deleted — it already replays v3 through the public
builder API, and every concept it replays has a home in the new model, so it
becomes a read-only path minting one `Part` per v3 voice. BardTheory's upgrade is
then read-row → re-save. Deleted in 22.0.0.

Note this reverses Phase 3's instruction to move `composition/hash_deserializer.rb`
into `content/flow/` as the live deserializer: it moves, but becomes the v3 path
while `Flow.from_h` gets a new v4 walk beside it.

### Format sequencing, summarized

`notation/render_plan.rb` is subclassed by LilyPond and MusicXML only; **ABC has
no render plan** and reads the flow directly. So: all three together for the
Phase 3 rename; two units for Phase 4 (LilyPond and MusicXML move for free via
the shared base, ABC is an independent edit); strictly one at a time for Phase 7.

### Riskiest phase

**Phase 5.** Phase 4's pickup-bar coupling is more *hidden*, but it surfaces as a
visible MusicXML diff and has a characterization spec available. Phase 5's failure
mode is silent — a non-monotonic comparator makes `bsearch` return the wrong
placement, producing wrong music with no exception, on the path every note
travels — and it sits underneath Phases 6-8.

De-risking: Phase 0 first as separately-revertible commits with their own specs;
pin `#<=>`/`#eql?`/`#hash` and the flow-identity question in one commit; add an
explicit monotonicity spec across a 4/4 → 3/4 change; keep Phase 4 as two
independently revertible commits so a Phase 5 bisect is not confounded.


## Decisions Taken After Planning

Planning raised eight objections and nine open questions. All are resolved; the
resolutions are folded into the sections above, and recorded here so the reasoning
is not lost.

| Raised | Resolution | Where it landed |
|---|---|---|
| `signature` as `KeySignature` is unbuildable | Store fifths as an `Integer` | Decision 2 |
| `MusicXML::KeyMapper` needs a real API change | `fifths(signature)` / `mode(tonal_context)`, the latter nil-accepting | Decision 2 |
| LilyPond cannot render the divergent case | Prefer the signature; explicit fifths→tonic table | Decision 2 |
| `Content::Staff` re-implements the catalog class | Reference `Instruments::Staff` instead | Decision 5 |
| Nothing seeds an instrument map | Empty map answers nil; one-staff fallback | Decision 5 |
| `until:` is a Ruby keyword | `from:` / `through:` | Decision 3 |
| Decision 6 contradicted `Voice#initialize` | `Voice.new` mints its own chain | Decision 6 |
| Circular support for the flow-binding claim | Sentence removed | Decision 6 |
| `Flow` will flog badly | `Flow::Timeline` owns the three maps | Decision 7 |
| Is rendering permanent API? | Yes on `Flow`; `Project` never renders | Decision 8 |
| `composer`/`origin` have no home | Plain strings on `Flow`; `Work` supersedes without removing | Decision 9 |
| `Player` cannot answer what it plays | `#instruments` derived from its parts | Decision 9 |
| Guideline key signature becomes position-dependent | Guidelines read the flow's opening event | Decision 10 |
| Persisted schema-3 data | **BardTheory persists content** — `Flow.from_v3_h` ships read-only in 21.0.0, deleted in 22.0.0 | Decision 10 |
| Intra-branch `Composition < Flow` bridge | **Accepted** — never ships, dies in Phase 3 | Plan, Phase 2 |
| Seven untestable criteria | Reworded with literal expected output | Acceptance Criteria |
| Eight unpinned edge cases | Added as criteria | Acceptance Criteria |

A subsequent consistency pass caught nine more, all applied:

| Found | Resolution |
|---|---|
| Cantus firmus section still described the pre-fifths signature | Rewritten as the two fields of decision 2 |
| Fifths stated as −7..+7, but the gem answers 8 for G♯ major | Signature unbounded; the *fallback table* is what stops at seven |
| "one `Project`, one `Flow`" contradicted decision 6 | Counterpoint is one `Flow`, no project |
| Decisions 7 and 8 were grab-bags of four topics each | Split into decisions 7-10, one argument apiece |
| `const_defined?(:Composition)` also answers true via `Object` | Added the `inherit` flag |
| Decision 4 said "inherits `RadixCarry`"; Phase 5 said "wraps" | Delegates — Phase 5 was right |
| Immutability, `#eql?`/`#hash`, and flow-identity lived only in the plan | Moved into decision 4 |
| "Reject events off a downbeat" had no criterion | Added |
| `SUBTICKS_PER_TICK` had no stated home | Stays in `Time` — no `Rudiment` counterpart |

Two consequences worth carrying into implementation:

- **The fifths fallback table has two callers**, not one — LilyPond's `\key` and
  the `Diatonic` guideline's tonic. Build it once in `Rudiment`.
- **Capture the corpus fitness fixture in Phase 0**, before any structural change.
  Without a baseline, "guides assess unchanged" means only "the specs still pass",
  because most guideline specs assert `marks_count` on hand-built material.

## Corrections Found in Implementation

Recorded here rather than silently changed, because each contradicts something
the sections above asserted.

| Section | What it said | What implementation found |
|---|---|---|
| Decision 2 | The interpretation "is a `Key` or a `Mode`" | Those two cannot hold every signature the gem admits. Narrowing to them made a flow in C harmonic minor raise at construction, where it had raised only at render. The tonal context now stays a `KeySignature` for a scale type neither subclass holds. |
| Plan, Phase 1 | Keep `TempoMap`'s normalizing wrapper — "`Conductor` depends on the difference" | It does not. Phase 0 deleted `normalize_position` and its `attr_writer :meter`, and unwired `Conductor`'s link between the maps; `conductor_spec.rb` stayed green untouched. Phase 0's own text called for exactly this, so the two paragraphs disagreed. |
| Plan, Phase 3 | Restrict the `sed` to the constant; leave method and variable names to a cosmetic pass | The half-state is worse than either end — `Voice#composition` returning a `Flow`, a `composition:` keyword argument, `RenderPlan#composition`. The identifier was renamed with the constant. `\bcomposition\b` does not match `CompositionContext`, so the spec-support rename stays parked for Phase 8 as planned. |
| Plan, Phase 4b | "Then drop the `Bar` readers and their serialization" | The duplicate *storage* is gone — the readers are derived views of the timeline — but `Bar#to_h` is how schema 3 serializes mid-piece changes, so dropping the readers outright would break v3 round-tripping before v4 exists. They go in Phase 8 with the schema bump. |
| Decision 4 / Phase 5 | `beat` → `count` framed as a naming correction | It is also a **breaking rename of a public reader**: `MusicalPosition#beat` and `FIRST_BEAT` are gone rather than aliased. Belongs in the 21.0.0 migration notes alongside `Composition`. |
| Decision 4 / Phase 5 | `Content::Position` delegates to `MusicalPosition` for "`RadixCarry` normalization" | Only half of it can. `normalize!` carries counts into bars with a single `divmod`, which assumes every crossed bar has the same count — ten quarter notes from `1:1` in a flow that turns 3/4 at bar 2 answered `3:3:000` instead of `4:1:000`. The subtick and tick carry delegates; the bar walk is done here, one bar at a time, asking the flow for each bar's meter. |
| Acceptance criteria | `staff_at` past the end of a `cross_to` span "returns the part's first staff" | True only for a voice that had never moved. A left hand assigned to the bass staff and crossing up for four bars must come back down to the bass staff, not to the first staff. The span restores whatever was in force before it, which reduces to the first staff in the case the criterion describes. |
| Plan, Phase 8 | `HashDeserializer` "becomes the v3 path" | It became `V3HashDeserializer`, and a new `HashDeserializer` was written for v4 beside it. Keeping one class serving two schemas would have meant a version switch inside every walk. `SchemaValues` is what is actually reused wholesale, as the plan predicted — its validators are container-agnostic, and only five new ones were needed (`fifths`, `tonal_context`, `instrument`, `staff_system`, `clef`). |
| Plan, Phase 6 / decision 3 | `cross_to` is how a staff assignment is made | Deserialization needs a bare map write, because the serialized form *is* the map: a span's two events are already two entries, and reconstructing spans to re-derive them would invent information the document does not carry. `Voice#assign_staff` is that write, and `cross_to` is it plus the bookend. |
| Decision 2 | LilyPond should "prefer the signature" where the two fields diverge | Only where they *diverge*. Preferring it always would print a D dorian flow as `\key c \major`, throwing away a mode LilyPond can express and changing every existing counterpoint document. `printed_key_signature` keeps the interpretation when it agrees with the signature, and where they diverge keeps the tonic if an ordinary key on it prints that signature — which is what yields the `\key c \minor` the criteria ask for, rather than its relative `\key ees \major`. |
| Acceptance criteria | A signature beyond ±7 with no tonal context "raises" | Only for LilyPond. MusicXML stores fifths, which the event already holds, so it renders 8 with or without an interpretation. The fallback table has exactly two callers, and MusicXML is not one of them. |
