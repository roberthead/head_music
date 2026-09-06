<!--
metadata:
  created_at:   2026-09-05T16:38:54-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-09-05T16:38:54-07:00
-->

# Identity and Presentation

AS a developer producing scores and parts from a project

I WANT the work's identity, its credits, and the views that render it to be
distinct from the music itself

SO THAT two layouts can present one body of music, and Bach can be credited for
the work while someone else is credited for this arrangement of it

Story 2 of [EPIC: Organizing Content](../epics/organizing-content.md). Depends on
[Content Architecture](content-architecture.md).

## Background

Attribution roles do not all attach at the same level. Composer and lyricist
describe the *work*; arranger and transcriber describe *this version* of it;
editor, engraver, and publisher describe *this publication*. A single flat credit
list on one object cannot express "Bach wrote it, Segovia arranged it, Bärenreiter
published it."

The gem already makes this distinction informally in one corner:
`Content::CantusFirmus::Source` is a publication — name, edition, authors — and
`CantusFirmus::Example` is content that cites it. This story generalizes that
instinct instead of leaving it as a special case for one pedagogical corner.

## Why `Work` is a separate noun from `Project`

A `Project` is a document, and documents legitimately hold flows from unrelated
pieces: a fake book, a graded set of counterpoint exercises, a chapter's worth of
cantus firmi, a sketchbook. Putting the work's identity on the project would make
the model lie in exactly those cases — which are among this gem's primary uses.

So a `Work` is an optional catalog identity that a `Flow` may cite. A four-movement
sonata is one project whose four flows cite one work. A fake book is one project
whose eighty flows cite eighty works. A counterpoint exercise cites none.

This is the `Work` level of the FRBR bibliographic model, adopted alone. FRBR's
`Expression` (this arrangement) and `Item` (this physical copy) are deliberately
not modeled: the project *is* the version, so arrangement is expressed as a
project-level credit rather than as another container.

## The Model

```
Work                        # optional; cited by a Flow
  title
  catalog_number            # Op. 27 No. 2 / BWV 1007 / K. 545
  year
  credits []                # composer, lyricist, librettist, songwriter

Project
  credits []                # arranger, transcriber, editor — this version
  layouts []

Publication                 # generalizes CantusFirmus::Source
  title, edition, year, publisher
  credits []                # editor, engraver

Person
  full_name, sort_name
  birth_year, death_year    # both optional

Credit
  person
  role                      # constrained by the level it attaches to

Layout
  kind                      # :score, :part, :custom
  flows []                  # which flows appear
  players []                # which players appear
  concert_pitch?            # sounding vs. transposed
  title_override

Score < Layout
  ensemble_type             # :orchestral, :band, :chamber, :pop, :solo
```

## Design Decisions

### Credits are constrained by level

Each level accepts only the roles that belong to it, so the model cannot record a
publisher as having composed the music:

| Level | Roles |
|---|---|
| `Work` | composer, songwriter, lyricist, librettist |
| `Project` | arranger, transcriber, orchestrator, reconstructor |
| `Publication` | editor, engraver, publisher |

Roles are `Named`, and so translated like the rest of the gem's vocabulary.

### `Score` orders and groups its players

The sketch's `ordered_score_parts` and `score_parts_grouped_by_orchestra_section`
become layout behavior, delegating to the existing
`Instruments::ScoreOrder`, which already carries per-ensemble section data:

```ruby
score.ordered_players          # score order for the ensemble type
score.player_groups            # sections, for square brackets
```

### `Publication` absorbs `CantusFirmus::Source`

`Content::CantusFirmus::Source` becomes a `Publication` with its YAML preserved,
so any flow can cite a published source, not only a cantus firmus. `Source.get`
survives as a lookup into the cantus firmus subset.

### A person is not necessarily a name

The sketch flags this: "is a person really a person or a particular name."
`Person` records one identity with an optional `sort_name`; two spellings of one
composer are one `Person`. Pseudonyms, attribution disputes, and anonymous works
are out of scope — `Work#credits` may simply be empty.

## Acceptance Criteria

- A `Flow` may cite a `Work`, or cite none; flows in one project may cite different
  works.
- A `Work` carries composer credits; a `Project` carries arranger credits; each
  level rejects a role that does not belong to it.
- A `Person` with only a `full_name` is valid; birth and death years are optional
  and independently omittable.
- A `Layout` selects a subset of flows and players and renders only those; two
  layouts over one project render different documents from the same music.
- A `Score` orders and groups its players by ensemble type via `ScoreOrder`.
- A layout in concert pitch and the same layout transposed render the same voice
  at different written pitches.
- `Publication` serves the existing cantus firmus sources with their data intact.
- A layout's `title_override` changes what is displayed without changing the work's
  title.

## Out of Scope

- Engraving: spacing, collisions, page turns, part condensing.
- FRBR `Expression` and `Item`.
- Cues borrowed from another player's part into a part layout.
