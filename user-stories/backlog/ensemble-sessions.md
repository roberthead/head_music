<!--
metadata:
  created_at:   2026-09-05T16:38:54-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-09-05T16:38:54-07:00
-->

# Ensemble Sessions

AS a developer modeling a rehearsal, recording, or performance

I WANT real people cast into a project's players for a particular occasion

SO THAT the same project can be performed by different ensembles without
duplicating the music or hard-coding a performer into the score

Story 3 of [EPIC: Organizing Content](../epics/organizing-content.md). Depends on
`Person` from [Identity and Presentation](identity-and-presentation.md).

## Background

A `Player` in a project is a chair — "Flute 1", "Piano" — and belongs to the
document. Who sits in that chair is a fact about an *occasion*, not about the
music: the same string quartet is played by different quartets, and the same
player is covered by a substitute at one rehearsal.

This is why the epic separates the two. The sketch's `ScorePartPlayer` was the
join standing in for this distinction; with `Player` as the chair and `Person` as
the human, the join becomes a casting record on a session.

## The Model

```
EnsembleSession
  kind                     # :rehearsal, :recording, :performance
  project
  layout                   # optional: which view was used
  date, venue
  castings []

Casting
  player                   # -> the Project's Player
  people []                # one for a solo chair; many for a section
```

## Design Decisions

### A casting holds many people

A section chair — "Violin I" — is one player realized by many people. A solo chair
is the degenerate case of one. Modeling `people` as a collection avoids a separate
`SectionPlayer` type and matches how a session actually reads.

### Sessions do not change the music

An `EnsembleSession` references a project; it never owns flows, parts, or voices.
Anything a performance changes about the notes — a cut, a transposition, an
ossia taken — is a project or layout concern, not a session one. A session that
needs different notes references a different project.

### A player may go uncast

A session covering only the wind parts leaves the strings uncast. Casting is
partial by nature, and `session.uncast_players` is a useful question, not an
error.

## Acceptance Criteria

- An `EnsembleSession` references a project and records its kind, date, and venue.
- A `Casting` binds one `Player` to one or more `Person`s.
- Two sessions over one project cast different people into the same players
  without touching the music.
- A session reports which players are cast and which are not.
- A session may reference the layout that was used, or none.

## Out of Scope

- Recording takes, session logs, and audio artifacts.
- Contracts, scheduling, and personnel management.
- Per-performer notation differences; those are layout concerns.
