# EPIC: Organizing Content

AS a developer

I WANT musical content organized around a vocabulary that serves general-purpose notation, not just counterpoint exercises

SO THAT a piano voice can cross staves, a player can change instruments mid-movement, and a score is a view of the music rather than the music itself

## Vision

`HeadMusic::Content::Composition` is doing too many jobs. It is simultaneously the
document, the movement, the timeline, the credits, and the container of voices —
and its voices are bare melodic lines with no instrument, no staff, and no
performer. That shape is adequate for two-voice species counterpoint and for
almost nothing else.

This epic replaces it with a vocabulary borrowed from Dorico where Dorico has a
good answer, and extended where it does not.

### Three axes, not one hierarchy

The central claim of this epic is that three genuinely different concerns have
been collapsed into one:

| Axis | Question it answers | Nouns |
|---|---|---|
| **Content** | What music exists, on what timeline? | `Project`, `Flow`, `Part`, `Voice`, `Placement` |
| **Identity** | Whose piece is this, and who published it? | `Work`, `Person`, `Credit`, `Layout`, `Score` |
| **Casting** | Who realizes it, on what occasion? | `Player`, `EnsembleSession` |

A `Score` is a *view* of content, not a kind of it. The moment a score is content,
you cannot have two scores of the same music without duplicating the music, and
`#to_lilypond` / `#to_musicxml` stop being renderings and become conversions.
Titles and credits belong to the work; a layout may override what it *displays*.

### The container hierarchy

```
Project                  # the document: Dorico's project
  players []             #   the chairs: "Flute 1", "Piano"
  flows []               #   movements, songs, cues, exercises
  layouts []             #   score and part views

Flow                     # a continuous span of music; owns its own timeline
  project?               #   optional — a flow may stand alone
  title                  #   "II. Andante"
  work?                  #   optional catalog identity (see Identity story)
  timeline               #   meter map + tempo map + key map
  bars []                #   barlines, repeats, voltas
  parts []               #   one per player present in this flow

Part                     # this player's music in this flow
  player?                #   optional — a part with no player is a staff of music
  instruments            #   event map: flute -> piccolo -> flute
  staff_systems          #   event map: which staves, brace/bracket
  voices []

Voice
  part
  staff_assignments      #   event map: which staff, at any moment
  placements []
```

**Containment is total; context is optional.** A voice is always in a part, always
in a flow — so `voice.part.staff_system_at(position)` never needs a nil check.
What is optional is the *upward* reference: `Flow#project`, `Flow#work`,
`Part#player`.

That is what makes a chunk of music expressible without inventing a noun for it.
A cantus firmus, a scale, a sight-reading example, an ABC import — each is a flow
with no project, which is Dorico's own use of flows for worksheets of short
examples. A `Project` remains the thing that supplies what only multi-part
coordination needs: players, score order, layouts.

`Player` is the project-level chair; `Part` is that chair's music in one flow.
That pairing is what makes "the flute plays in movements 1 and 3" expressible
without a nullable join — there is simply no `Part` for that player in flow 2 —
and it is what makes an instrument change *within* a part honest: conceptually it
is still the same player.

### One mechanism for everything that changes

Every "this can change partway through" in the model is the same shape, and
`HeadMusic::Time::EventMapSupport` already exists to express it:

| Map | Owner | Query |
|---|---|---|
| meter, tempo, key signature | `Flow` | `flow.meter_at(position)` |
| instrument | `Part` | `part.instrument_at(position)` |
| staff system | `Part` | `part.staff_system_at(position)` |
| clef | `Staff` | `staff.clef_at(position)` |
| staff assignment | `Voice` | `voice.staff_at(position)` |

Today the same job is done two incompatible ways: `Content::Bar` carries key and
meter changes for the Content module, while `Time::MeterMap` and `Time::TempoMap`
do it properly for the Time module and are unused by Content. Unifying on event
maps retires that duplication and makes cross-staff voices a special case of a
mechanism that already had to exist.

### Voices orthogonal to staves

A voice belongs to a part and *has* a staff at any given moment. A left-hand
piano voice that rises into the treble staff for four bars is a span in the
voice's staff-assignment map; a single cross-staff note is a very short span. One
mechanism, no note-level special case.

This falls out correctly in both export formats, which is good evidence the model
is right: MusicXML wants `<staff>` per note and `<voice>` per part — exactly this
pair — and LilyPond wants `\change Staff` at span boundaries, which is exactly
where the map's events are.

## Stories

1. **[Content Architecture](../backlog/content-architecture.md)** — `Project`, `Flow`,
   `Part`, `Voice`, `StaffSystem`, `Staff`, the event maps, and the position
   unification. Retires `Composition`. This is the only story with migration cost.
2. **[Identity and Presentation](../backlog/identity-and-presentation.md)** — `Work`,
   `Person`, `Credit`, `Layout`, `Score`. Folds `CantusFirmus::Source` into a
   general citation vocabulary.
3. **[Ensemble Sessions](../backlog/ensemble-sessions.md)** — casting real people
   into players for a rehearsal, recording, or performance. Depends on `Person`
   from story 2.

## Non-goals

- **No `MusicContent` or `Material` abstract base class.** A score and a standalone
  melody share no behavior worth an ancestor; the shared thing is "holds
  placements," which is a role, not a superclass.
- **No `Fragment`.** Anchorless, relatively-positioned content is deferred until
  something needs it — motif transformation or a voicing library. A standalone
  flow covers every case in the gem today.
- **No `Sequence` / editing canvas.** That is an editor concept. A library needs
  the time axis, not the 2D canvas that an editor draws on it.
- **No full FRBR stack.** `Work` is adopted (see story 2); `Expression` and `Item`
  are not. Cataloging software is a different product.
- **No engraving.** Layout is a selection of flows and players plus display
  overrides, not a spacing and collision engine.
