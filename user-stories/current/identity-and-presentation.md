<!--
metadata:
  created_at:   2026-09-05T16:38:54-07:00
  activated_at: 2026-09-08T09:39:00-07:00
  planned_at:   2026-09-08T10:14:57-07:00
  finished_at:
  updated_at:   2026-09-08T16:01:22-07:00
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
  credits []                # arranger, transcriber, orchestrator — this version
  layouts []

Publication                 # generalizes CantusFirmus::Source
  title, edition, year, publisher
  credits []                # author, editor, engraver

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
  ensemble_type             # a ScoreOrder key (:orchestral, :band, ...) or nil
```

## Design Decisions

### Credits are constrained by level

Each level accepts only the roles that belong to it, so the model cannot record a
publisher as having composed the music:

| Level | Roles |
|---|---|
| `Work` | composer, songwriter, lyricist, librettist |
| `Project` | arranger, transcriber, orchestrator, reconstructor |
| `Publication` | author, editor, engraver, publisher |

Roles are `Named`, and so translated like the rest of the gem's vocabulary.
`author` joins the publication level because the existing cantus firmus sources
are treatises, and their people are authors rather than editors.

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

## Implementation Plan

### WEMI mapping

| WEMI level | In head_music after this story | Notes |
|---|---|---|
| **Work** | `Content::Work` (title, catalog_number, year, work-level `Credits`), with `Content::Person`, `Content::Credit`, `Content::Role` | New. A `Flow` cites a `Work` optionally (`flow.work`). |
| **Expression** | `Content::Project` and `Content::Flow` (shipped in 21.0.0), plus the new project-level `Credits` | The story's "Project credits" (arranger, transcriber, orchestrator, reconstructor) are expression-level credits. No new container. |
| **Manifestation** | `Content::Layout` / `Content::Score` (which flows, which players, what order, concert or written pitch, displayed title) and the ABC, LilyPond, MusicXML documents they produce; `Content::Publication` as a manifestation a flow may cite as its source (`flow.source`) | `Publication` credits (author, editor, engraver, publisher) are manifestation-level. |
| **Item** | Not modeled | The gem produces bytes and stops. |

Where the story text and `references/wemi.md` are in tension, WEMI wins on vocabulary and the story wins on scope:

- The story says "FRBR Expression and Item are deliberately not modeled." The reference says `Project`/`Flow` *are* the expression. Both are true and the plan states it this way: the expression level is already modeled by `Project` and `Flow`; what the story declines to add is a *third container* for it. Arrangement is a project-level credit, exactly as the story says.
- The story's `Publication` role table (editor, engraver, publisher) cannot hold the existing `sources.yml` data, whose people are *authors* of treatises. Every specialist found this independently. The plan adds `author` to the publication level; without it the acceptance criterion "data intact" is unsatisfiable. The story's table should be amended when this plan is accepted.
- The story sketch comments "editor" under `Project`; the decision table puts it at `Publication`. The table wins (a critical edition's editor is credited on the edition).
- After shipping, `references/wemi.md` §5 status column is updated to name the release and record the `author` deviation.

### Design

Each of the nine tensions in the planning briefing, resolved. Reasoning that the specialists disagreed on is noted in one line.

1. **Work, Person, Credit are frozen value objects; a Flow cites a Work inline.** `Person`, `Credit`, and `Work` are `Data.define` values (house style already: `abc/book_parser.rb:8`, `lily_pond/voice_stream.rb:8`), so `==`/`eql?`/`hash` come free and `Array#uniq` dedupes. `Flow#to_h` writes `"work"` as an inline hash (or `null`); `Project#works` is `flows.filter_map(&:work).uniq`. A standalone flow is self-contained; a sonata's four flows carry four small equal hashes and `project.works.size == 1`; a fake book's eighty flows carry eighty. Rejected: a project-level `works` array with index references (developer's proposal). Index references are justified for `Player` only because a player has no identity but its position; a work has a title. Trade-off: correcting a work's title means `flow.work = flow.work.with(title: ...)` on each citing flow.
2. **Schema stays 4, additive; this is 21.1.0.** New keys (`"work"` and `"source"` on a flow, `"credits"` and `"layouts"` on a project) are absent-means-none. `HashDeserializer#build` and `Project.from_h` read named keys and never enumerate the hash, so a 21.0.0 reader accepts a 21.1.0 document and loses only the new information, and no consumer validates documents against a strict JSON schema, so the new keys need no coordination; a bump to 5 would make 21.0.0 *reject* those documents and force a second retained reader while `from_v3_h` is still promised until 22.0.0. Both earlier bumps were earned by a key rename or a container restructure; write that rule into `references/content-schema.md`. Rejected: schema 5 (developer). Its concern, "an old reader silently drops the credits," is answered by decision 3: the old reader still gets the composer string it printed before.
3. **`Flow#composer` delegates to the work and falls back to the string; `to_h` writes the derived string.** `def composer = work&.composer || @composer`, where `Work#composer` joins composer credits with `", "` (locale-neutral, since the string lands in untranslated ABC, LilyPond, and MusicXML header fields; falls through to `nil` when the work has no composer credit, so a lyricist-only work still uses the string). `Flow#to_h` already calls the method (`flow.rb:161`), so it writes the derived value and old readers keep the printed name. `from_h` reads both keys independently; when they disagree the work wins and the string is retained in memory. Across a round-trip only the derived string survives, so removing the work afterwards leaves the work's composer rather than the authored name. `Flow.new(composer: "Bach")` remains a legacy string and never mints a `Work`: its callers are the ABC `C:` and LilyPond `composer =` parsers, whose text ("Trad.", "arr. J. Smith") is not a person and has no work title. `origin` stays a plain string permanently: ABC `O:` is geographic provenance, an expression fact, and nothing at the Work level maps to it. Rejected: writing only the authored string under `"composer"` (developer), because it makes `"composer": null` for every work-bearing flow and *that* is the silent drop.
4. **Layout renders by materializing derived flows and calling the permanent `Flow#to_*`.** `layout.realize(flow)` does `hash = flow.to_h`; sets `hash["name"]`; filters `hash["parts"]` by player index (computed from the live `flow.parts`, since the hash carries no players); maps `"sounds"` strings and the timeline's key signature through the transposition; then `Flow.from_h(hash)` and reattaches each kept part's `player` by index. The writers, both `RenderPlan`s, and both `Preflight`s are untouched by selection. Decision 8 holds: `Project` still has no render method; `Layout` does. Rejected: a duck-typed view (`Position#flow`, `Voice#flow`, and `Position#normalize` all reach the original flow's timeline through placements, so a view is inconsistent under transposition), and writer options for filtering (three copies of selection logic). Multi-flow per format: **ABC** is a tune book, one `X:n` per flow joined by a blank line, round-tripped by the existing `BookParser`; **LilyPond** is one document with one `\header { title }` and one `\score` per flow each carrying `\header { piece = "<flow name>" }` (successive `\score` blocks form an implicit book; no `\book` wrapper needed); **MusicXML** is one `score-partwise` per flow, `Layout#to_musicxml` raises `RenderError` naming `#to_musicxml_documents` when more than one flow is selected. A selected flow in which no selected player has a part is skipped, not rendered empty (a flute part book has two movements, not a silent third). `flows: nil`/`players: nil` mean all; a `Score` reorders kept parts into `ordered_players` order, a plain `Layout` keeps authored order.
5. **Transposition is a pure value object; written = sounding minus `sounding_transposition`, spelled through a `DiatonicInterval`; each part gets its own written key, so a transposed mixed score renders.** Catalog convention verified in `notation_styles.yml`: `sounding = written + sounding_transposition` (clarinet −2, cor anglais −7, piccolo +12, double bass −12, bass clarinet −14, contrabass sax −33). `Pitch + Integer` respells through MIDI (`pitch/arithmetic.rb:18`); `DiatonicInterval#above/#below` preserve spelling, so `Layout::Transposition.for_semitones(n)` decomposes `n` into a simple interval from a 12-entry table plus whole octaves and applies them in turn. Key signature transposes by moving the tonic spelling and keeping the scale type (never arithmetic on fifths): `KeySignature.new(transposed_tonic_spelling, ks.scale_type)`. A `KeySignatureEvent` transposes to a new event at the same position with the moved signature and, where one was given, the moved tonal context. **The realized flow's timeline stays in concert pitch**; only each part's pitches are transposed, bar by bar, by the instrument in force at that bar. The written key is a rendering fact derived per part: the shared `Notation::RenderPlan` (`render_plan.rb`) is the single place both formats read `first_measure_key` and `measure_key_changes`, and both call sites already hold the part (`VoiceWriter#lines(voice)` has `voice.part`; `AttributesWriter#lines(part, bar_number)`). Those two methods gain a `part` argument; when the plan is built `transposed: true`, they transpose the timeline's event by `Transposition.for(part.instrument_at(bar))` before mapping it, and an instrument change within a part (B♭ to A clarinet at bar 9) becomes a written key change for that part alone. Rejected: rewriting the flow's single timeline (cannot express two written keys), and a Part-level key map on the model (a written key is not content; it would change the schema and leak a manifestation fact into the expression). Writer output: MusicXML gains `<transpose><diatonic/><chromatic/><octave-change/></transpose>` after `<clef>`, taken from each part's instrument; LilyPond emits the already-transposed pitches plus `\transposition <pitch>` per staff (the part idiom; `\transpose c d {}` would re-transpose what is written), and `\key` is already per `\new Voice`, so per-part keys need no structural change; ABC is single-voice, so its one part's written key goes into `K:` and the accidental-spelling `PitchWriter`, and no `%%transpose` directive (abcm2ps would double-transpose). Concert pitch means sounding pitch for every part, including octave transposers, so a concert-pitch layout is byte-identical to today's output.
6. **`Score < Layout`, thin; ordering logic lives on `ScoreOrder`.** Kept as the story specifies (the story and epic both name `Score`; the AC names it). The subclass fixes `kind: :score`, adds `ensemble_type`, `ordered_players`, `player_groups`. `ScoreOrder` gains `#group(instruments)` and a public `#position_of(instrument)` sharing one section index with `#order`, so the two cannot disagree. Players sort by `[position, authored_index]` (stable; two clarinets keep authored order); players with no instrument or an instrument the order does not know sort last in authored order and group under a `nil` section key. `ensemble_type` must be a `ScoreOrder` key (`orchestral`, `band`, `brass_quintet`, `woodwind_quintet`, `string_quartet`) or `nil` (authored order, one group). Trade-off noted from the best-practices review: `kind` and the subclass are two discriminators for one fact; accepted because the vocabulary is the story's, and the subclass is three methods.
7. **`Publication` is a frozen value class; `CantusFirmus::Source < Publication` keeps its catalog identity and old readers.** `Publication.new(title:, edition: nil, year: nil, publisher: nil, abbreviation: nil, notes: nil, credits: [])`, hand-rolled frozen with value `==`/`eql?`/`hash` (not `Data.define`, because `Source` must add `key`). `Source` keeps `private_class_method :new`, memoized `.all`, `.get`, `.keys`, `normalize_key`, and aliases `publication_name`→`title`, `publication_edition`→`edition`, `author_names`→`credits.names(:author)`; `sources.yml` stays where it is. `spec/head_music/content/cantus_firmus/source_spec.rb` and `example_spec.rb` must pass unedited; that is the compatibility oracle. `Example#to_flow` gains one line, `flow.source = source`, which is what makes the criterion observable in content and not only in the catalog.
8. **`Role` follows `Clef`, not `ScoreOrder`.** `Content::Role` includes `Named`, with a frozen `KEYS_BY_LEVEL` constant (12 roles) and `#name(locale_code:)` = `I18n.translate(name_key, scope: "head_music.credit_roles", locale:)` exactly like `clef.rb:52`. `Role.get` matches the key or any locale's translation and raises `ArgumentError` for an unknown identifier rather than falling through to `Named::ClassMethods#get_by_name`, which would mint a role. The level constraint is enforced once, in a `Content::Credits` collection (`Credits.new(:work)` etc.), which each of `Work`, `Project`, `Publication` holds; `Credit` itself is level-agnostic. Locale files are `en, en_GB, de, es, fr, it, ru` (CLAUDE.md's "en, de, es, fr, it, ja, nl" is stale); `en_GB` falls back to `en` and needs no entries.
9. **`title_override` lives on the layout and reaches the writers through the derived flow's `name`.** Single-flow layout: derived `name = title_override || flow.name`, so no writer change and byte identity when there is no override; `work.title` is never touched. Multi-flow document title: `title_override || (the one work title all selected flows share) || project.name`; each flow's own name becomes LilyPond `piece =`, MusicXML `<movement-title>` plus `<movement-number>`, and ABC `T:` per tune (ABC has no book-title field; a multi-tune layout's override is documented as not rendered).

### Steps

Each step is independently green and shippable. Specs use `described_class`, build flows with `HeadMusic::Notation::ABC.parse` where a melody is needed, and never assert stdout. Run `bundle exec rubocop -a` after each step.

1. **`Person`, `Role`, `Credit`, `Credits`, and the role translations**
   - `Person = Data.define(:full_name, :sort_name, :birth_year, :death_year)` with keyword `initialize` defaulting the three optionals to `nil`; `sort_name` reader falls back to `full_name`; `to_s` is `full_name`; `death_year < birth_year` raises `ArgumentError`; `to_h`/`.from_h` always writing all four keys. Not `Named`: a proper name is data, not vocabulary.
   - `Role`: `include HeadMusic::Named`; `KEYS_BY_LEVEL = {work: %i[composer songwriter lyricist librettist], project: %i[arranger transcriber orchestrator reconstructor], publication: %i[author editor engraver publisher]}.freeze`; `.get`, `.for_level`, `#level`, `#name(locale_code:)`; `private_class_method :new`; unknown key raises.
   - `Credit = Data.define(:person, :role)` coercing `role` through `Role.get`; `to_h` is `{"role" => "composer", "person" => {...}}`.
   - `Credits`: `include Enumerable`; `new(level, credits = [])` validating every credit's `role.level == level` with the message "`arranger` is a project role, not a work role"; `#add(person, role)` returns a new frozen collection; `#for(role)`, `#names(role)`, `#to_h`, `.from_h(array, level:)`.
   - Add `credit_roles:` blocks to `en, de, es, fr, it, ru` under `head_music:`, alphabetically after `chromatic_intervals`. Translations from the developer report (de Komponist/Textdichter/Librettist/Arrangeur/Transkribent/Orchestrator/Rekonstrukteur/Herausgeber/Notenstecher/Verleger/Autor; fr compositeur/parolier/librettiste/arrangeur/transcripteur/orchestrateur/reconstructeur/éditeur scientifique/graveur/éditeur/auteur; es, it, ru likewise); flag `fr`/`es` editor-vs-publisher and `de` Transkribent for a native check.
   - Requires: insert `person`, `role`, `credit`, `credits` after `content/bar` in `lib/head_music.rb`.
   - Files: `lib/head_music/content/person.rb`, `lib/head_music/content/role.rb`, `lib/head_music/content/credit.rb`, `lib/head_music/content/credits.rb`, `lib/head_music/locales/{en,de,es,fr,it,ru}.yml`, `lib/head_music.rb`
   - Specs: `spec/head_music/content/person_spec.rb` (full_name alone valid; years independently omittable; frozen; value equality and `uniq`), `spec/head_music/content/role_spec.rb` (get by key and by German name; unknown raises; `level`; a name in every locale file), `spec/head_music/content/credit_spec.rb`, `spec/head_music/content/credits_spec.rb` (each of the three levels rejects a foreign role with the message; accepted roles per level).

2. **`Work`**
   - `Work = Data.define(:title, :catalog_number, :year, :credits)` with keyword `initialize` wrapping `credits` in `Credits.new(:work, ...)`; `#composer` joins composer credit names with `", "` or answers `nil`; `#to_s` is `[title, catalog_number].compact.join(", ")`; `to_h`/`.from_h`; `with_credit(person, role)` returns a new work.
   - Files: `lib/head_music/content/work.rb`, `lib/head_music.rb`
   - Specs: `spec/head_music/content/work_spec.rb` (composer from credits; two composers joined; empty credits legal and `composer` nil; rejects an arranger; round trip; two equal works `uniq` to one).

3. **A flow cites a work; `Flow#composer` compatibility; project credits**
   - `Flow`: `attr_accessor :work, :source`; `Flow.new(..., work: nil, source: nil)`; `def composer = work&.composer || @composer`; `to_h` adds `"work" => work&.to_h` and `"source" => source&.to_h` (both nullable, always present, like `"composer"`).
   - `HashDeserializer#build` (not the shared `Deserializer#build_base_flow`, so `V3HashDeserializer` gains nothing) reads `"work"` via `Work.from_h` and `"source"` via `Publication.from_h` (step 4 supplies `Publication`; read `"source"` in step 4).
   - `Project`: `attr_reader :credits` (`Credits.new(:project)`), `#add_credit(person, role)`, `#works`; `to_h` adds `"credits"`; `from_h` reads it when present.
   - `Flow#composer` semantics: a flow with `work` whose composer is "Johann Sebastian Bach" and string "Bach" answers the work's name; a work with no composer credit falls back to the string; `Flow.new(composer: "Bach").composer == "Bach"`.
   - Update `references/content-schema.md` §3 (`Flow`, `Project`) and §4 (new sparse keys) in the same step so the document never lags the schema.
   - Files: `lib/head_music/content/flow.rb`, `lib/head_music/content/flow/hash_deserializer.rb`, `lib/head_music/content/project.rb`, `references/content-schema.md`
   - Specs: extend `spec/head_music/content/flow_spec.rb` (composer delegation and fallback; `Flow.new(composer:)` unchanged), `spec/head_music/content/flow_serialization_spec.rb` (a standalone flow citing a work round-trips it inline; a work-bearing document written here reads under a hash with `"work"` deleted, i.e. old-document tolerance), `spec/head_music/content/project_serialization_spec.rb` (two flows citing equal works restore to `==` works and `project.works.size == 1`; project credits round-trip; a 21.0.0-shaped hash with no `"credits"`/`"work"` keys still reads). Writer headers: in `spec/head_music/notation/abc_spec.rb`, `lily_pond_spec.rb`, `music_xml/writer_spec.rb`, one case each for a work-bearing flow (`C:`, `composer =`, `<creator type="composer">` carry the work's composer) and one asserting a legacy flow's output is unchanged.

4. **`Publication` absorbs `CantusFirmus::Source`**
   - `Publication` as decided above; `Source < Publication` built from `sources.yml` with `credits` of `:author` persons (full_name only); aliases for the old readers; `Example#to_flow` sets `flow.source = source`; `HashDeserializer` reads `"source"`.
   - Move the two `cantus_firmus` requires below `content/publication` in `lib/head_music.rb`.
   - Files: `lib/head_music/content/publication.rb`, `lib/head_music/content/cantus_firmus/source.rb`, `lib/head_music/content/cantus_firmus/example.rb`, `lib/head_music/content/flow/hash_deserializer.rb`, `lib/head_music.rb`
   - Specs: `spec/head_music/content/publication_spec.rb` (value equality; rejects a composer credit; round trip); `spec/head_music/content/cantus_firmus/source_spec.rb` and `example_spec.rb` pass **unedited**; new cases in `source_spec.rb`: `Source.get(:fux).is_a?(Publication)`, `.title == "Gradus ad Parnassum"`, `.credits.names(:author) == ["Johann Joseph Fux"]`, `Source.get("Clendinning & Marvin").edition == "3rd"`, `.abbreviation == "C&M"`, `.notes` intact; `example_spec.rb`: `to_flow.source == Source.get(...)` and it round-trips through `Flow#to_h`.

5. **`Layout`: selection, realization, rendering, serialization (concert pitch only)**
   - `Layout.new(project:, kind: :custom, flows: nil, players: nil, concert_pitch: true, title_override: nil)`; `KINDS = %i[score part custom]`; `#flows`/`#players` answer the project's collections when unselected; `#rendered_flows` skips flows where no selected player has a part; `#title`; `#realize(flow)` per decision 4 (transposition hook left as identity until step 7); no memoization of realized flows (`Flow` is mutable, a cached view would go stale silently).
   - `Project#add_layout(**kwargs)` mints and appends to `project.layouts`; `to_h` adds `"layouts"` as `{"kind", "title_override", "concert_pitch", "flows": [indexes] | null, "players": [indexes] | null}`; `from_h` rebuilds them.
   - `Layout#to_abc` (book: `reference_number: index + 1`, joined by a blank line); `#to_lilypond` (single flow delegates to `flow.to_lilypond`; multi-flow via a new `LilyPond::BookWriter` that promotes `Writer#score_lines` to accept a `piece:` keyword); `#to_musicxml` (raises for more than one flow, naming `#to_musicxml_documents`); `#to_musicxml_documents` (one string per flow; `MusicXML.render(flow, work_title: nil, movement_number: nil)` emits `<movement-title>`/`<movement-number>` only when given).
   - Files: `lib/head_music/content/layout.rb`, `lib/head_music/content/layout/realization.rb`, `lib/head_music/content/project.rb`, `lib/head_music/notation/lily_pond/writer.rb`, `lib/head_music/notation/lily_pond/book_writer.rb`, `lib/head_music/notation/lily_pond.rb`, `lib/head_music/notation/music_xml/writer.rb`, `lib/head_music/notation/music_xml.rb`, `lib/head_music.rb`, `references/content-schema.md`
   - Specs: `spec/head_music/content/layout_spec.rb` (nil means all; `rendered_flows` skips; a part with no player is kept only when no player selection was made; `realize` does not change `flow.to_h`; identity realization `realize(flow).to_h == flow.to_h`); `spec/head_music/content/layout_rendering_spec.rb` (two layouts over one project produce different documents in all three formats; a `:part` layout for a player present in flows 1 and 3 renders two movements; ABC book re-parses with `BookParser` to the selected flow count; multi-flow LilyPond has one `\version` and n `\score` blocks; regression guard: an all-flows all-players concert-pitch layout of one flow is byte-identical to `flow.to_abc`, `flow.to_lilypond`, `flow.to_musicxml`); `spec/head_music/notation/lily_pond/book_writer_spec.rb`; extend `project_serialization_spec.rb` with two layouts.

6. **`ScoreOrder#group` and `Score`**
   - `ScoreOrder`: generalize the private ordering index into a section index `{instrument_key => {position:, section_key:}}`; public `#position_of(instrument)` and `#group(instruments)` returning `[[section_key, [instruments]], ..., [nil, [unknown]]]` with empty sections omitted.
   - `Score < Layout`: `Score.new(project:, ensemble_type: nil, **layout_kwargs)`, `kind` forced to `:score`; `#score_order`; `#ordered_players` sorted by `[position_of(player.primary_instrument), authored_index]` with unplaced players last; `#player_groups` as `[[section_key, [players]]]`; realization orders kept parts by `ordered_players`. `Project#add_score(ensemble_type:, **kwargs)`. Layout serialization adds `"ensemble_type"` for scores. `ensemble_type` not in `SCORE_ORDERS` raises `ArgumentError` naming the known keys.
   - Files: `lib/head_music/instruments/score_order.rb`, `lib/head_music/content/score.rb`, `lib/head_music/content/project.rb`, `lib/head_music.rb`
   - Specs: extend `spec/head_music/instruments/score_order_spec.rb` (`group` for orchestral and band; unknown trailing group; `position_of`); `spec/head_music/content/score_spec.rb` (flute, clarinet, violin, and an instrument-less counterpoint player: `ordered_players` in orchestral vs band order; every project player appears exactly once; two clarinet players keep authored order; `player_groups.map(&:first) == [:woodwind, :string, nil]`; `nil` ensemble type gives authored order; rendered MusicXML `<part-list>` follows score order).

7. **Transposition to written pitch**
   - `Layout::Transposition.for_semitones(n)`: `SIMPLE_INTERVAL_BY_SEMITONES` (0..11 as unison through major seventh, 6 as augmented fourth) plus `octaves`; `#written(pitch)` applies the simple interval then octaves via `DiatonicInterval#above/#below`, passes `UnpitchedSound` and rests through untouched; `#key_signature(ks)` moves the tonic spelling and keeps the scale type; `#key_signature_event(event)` returns a new `Time::KeySignatureEvent` at the same position with the moved fifths and, when present, the moved tonal context; `#identity?`; `.for(instrument)` from `-instrument.sounding_transposition` (an instrument-less part or a non-transposing instrument yields the identity).
   - Realization: when `concert_pitch?` is false, map each kept part's `"sounds"` through `Transposition.for(part.instrument_at(bar))`, bar by bar. The timeline is left in concert pitch; the realized flow is a rendering intermediate whose pitches are written and whose timeline is sounding, and only the writers built `transposed: true` read it. A written key beyond `Key.for_fifths`'s ±7 raises `RenderError` naming the part and the enharmonic alternative.
   - `Notation::RenderPlan.new(flow, transposed: false)`: `first_measure_key(part)` and `measure_key_changes(part)` take the part; with `transposed: true` each timeline event is passed through `Transposition.for(part.instrument_at(bar_number)).key_signature_event` before `key_value`. A part whose instrument changes mid-flow gains a key change at that bar even though the timeline has none, so `measure_key_changes(part)` also scans `part.instrument_changes` for bars in range. Results are memoized per part. `precompute_eager_data` runs the key methods for every part so a bad key still raises at construction. Both subclasses' `key_value` are unchanged.
   - Writers: `MusicXML.render(flow, transposed: false)` — `AttributesWriter#lines(part, bar_number)` and `#first_measure_lines(part)` pass the part to the plan, and append `<transpose>` after `<clef>` from `part.instrument_at(bar).sounding_transposition` (chromatic = simple remainder, diatonic = its steps, octave-change when non-zero; omitted for 0; re-emitted at an instrument change). `LilyPond.render(flow, transposed: false)` — `VoiceWriter#lines`/`#silent_lines` read `plan.first_measure_key(voice.part)` and `plan.measure_key_changes(voice.part)`, so `\key` is per voice as it already is; `\transposition <pitch>` per staff, where the pitch is C4 moved by the *diatonic* interval (not `Pitch + Integer`) so B-flat clarinet gives `bes` not `ais`. `ABC.render(flow, transposed: false)` — the single part's transposition rewrites `K:` and seeds `PitchWriter` with the written key; a transposed ABC flow whose part changes instrument raises like any other mid-piece key change.
   - Files: `lib/head_music/content/layout/transposition.rb`, `lib/head_music/content/layout/realization.rb`, `lib/head_music/notation/render_plan.rb`, `lib/head_music/notation/music_xml/{writer,attributes_writer,render_plan}.rb`, `lib/head_music/notation/music_xml.rb`, `lib/head_music/notation/lily_pond/{writer,voice_writer,render_plan}.rb`, `lib/head_music/notation/lily_pond.rb`, `lib/head_music/notation/abc/writer.rb`, `lib/head_music/notation/abc.rb`, `lib/head_music.rb`
   - Specs: `spec/head_music/content/layout/transposition_spec.rb` (clarinet: sounding D4 → written E4, not F♭4; horn in F +P5; piccolo −P8; bass clarinet −14 → M2 up plus octave up; contrabass sax −33; C major → D major for clarinet; C dorian with three flats keeps its context; a transposed event keeps its position; ±7 overflow raises); `spec/head_music/notation/render_plan_spec.rb` (concert plan answers the same key for every part; transposed plan answers D major for the clarinet part and C major for the flute part of one flow; an instrument change adds a key change for that part only); `spec/head_music/content/layout_transposition_spec.rb` (a clarinet `:part` layout in concert pitch and transposed render the same voice as `c'`/`<step>C</step>` and `d'`/`<step>D</step>` with `\key c \major` vs `\key d \major` and `<fifths>0</fifths>` vs `<fifths>2</fifths>`; `<transpose>` sits after `<clef>` and only in the transposed document; `\transposition bes`; a flute + B♭ clarinet + horn in F transposed `Score` renders one MusicXML document whose three parts carry `<fifths>0`, `<fifths>2`, `<fifths>1` and one LilyPond document whose three staves carry `\key c`, `\key d`, `\key g`; the same score in concert pitch is byte-identical to `flow.to_musicxml`; a part changing from B♭ to A clarinet at bar 9 emits a second `<key>` at bar 9 in that part only).

8. **Titles and multi-flow polish**
   - Document title precedence per decision 9; LilyPond `piece =` and MusicXML `<movement-title>` already wired in step 5, now driven by `Layout#title`; ABC's non-rendering of a book title documented in the writer comment.
   - Files: `lib/head_music/content/layout.rb`, `lib/head_music/notation/lily_pond/book_writer.rb`
   - Specs: `spec/head_music/content/layout_title_spec.rb` (override changes `T:`, `title =`, `<work-title>`; `work.title` and `flow.name` unchanged after render; multi-flow default title is the shared work title, else the project name; each movement keeps its own name).

9. **Credits reach the headers**
   - The story's "so that" clause is that the arranger is credited; today only the composer prints. `LilyPond.render(flow, arranger: nil)` emits `arranger = "..."` and `MusicXML.render(flow, arranger: nil)` emits `<creator type="arranger">` when given; `Layout` passes `project.credits.names(:arranger).join(", ")`. ABC has no arranger field; skip. `Flow#to_*` pass nothing, so existing output is unchanged.
   - Files: `lib/head_music/notation/lily_pond/writer.rb`, `lib/head_music/notation/music_xml/writer.rb`, `lib/head_music/content/layout.rb`
   - Specs: one case per writer; a layout over a project with an arranger credit carries it, a plain `flow.to_lilypond` does not.

10. **Documentation, changelog, version**
    - `references/content-schema.md`: finish §1 entity diagram (Work, Publication, Layout edges), §3 class tables, §4 document with the new sparse keys, §7 "Additive keys do not bump the schema"; `references/wemi.md` §5 status column and the `author` deviation; story file's design table gains `author`; `CHANGELOG.md` and `lib/head_music/version.rb` → 21.1.0.
    - Files: `references/content-schema.md`, `references/wemi.md`, `CHANGELOG.md`, `lib/head_music/version.rb`, `user-stories/current/identity-and-presentation.md`

### Acceptance criteria: ambiguities and testable readings

| Criterion | Ambiguity | Testable reading adopted |
|---|---|---|
| A Layout "renders only those" | Which formats; MusicXML is one score per file | All three. LilyPond `\new Staff` count equals selected players with a part in that flow; ABC book tune count equals `rendered_flows.size`; `to_musicxml` raises for more than one flow, `to_musicxml_documents.size == rendered_flows.size`. |
| "Same voice at different written pitches" | Which instrument, interval, does the key move, which writer, mixed ensembles | B♭ clarinet `:part` layout, sounding C4 in C major: concert renders `c'`/`<step>C</step>`/`\key c \major`/`<fifths>0`; transposed renders `d'`/`<step>D</step>`/`\key d \major`/`<fifths>2`/`<transpose>`. The key signature moves per part; a transposed part with a concert key is wrong notation, not a smaller feature. A transposed `Score` over flute, B♭ clarinet, and horn in F renders three different written keys in one document. |
| "Each level rejects a role" | Which class raises, what error | `Credits#add` and `Credits.new` raise `ArgumentError` naming the role's level and the level it was offered to; `Credit` itself is level-agnostic. |
| "Orders and groups its players" | Shape; unknown instruments; ties | `ordered_players` is `Array<Player>`, a permutation of the project's players (assert `sort_by(project.players.index) == project.players`), ties in authored order, unplaced players last. `player_groups` is `[[section_key, [players]]]` in section order, trailing `[nil, [...]]` for unplaced. |
| "Publication serves the existing sources with their data intact" | Which attributes, via which API | All six (`key`, `publication_name`, `abbreviation`, `publication_edition`, `author_names`, `notes`) via the unchanged `Source` API, and `title`/`edition`/`credits(:author)` via the `Publication` API on the same object. `source_spec.rb` unedited. |
| "title_override changes what is displayed" | Which fields; document vs movement | Single flow: `T:`, `title =`, `<work-title>`. Multi-flow: the override is the document title; movements keep their names. `work.title` unchanged. |
| "Flow may cite a Work" and decision 9 | What `composer` answers in each combination | Table in step 3 specs: work wins, string falls back, `Flow.new(composer:)` unchanged. |

New criteria added by this plan, because the story's "so that" and the previous story's learnings need them: round trip of the most featured project (two works, one cited twice; a publication; project credits; a `Score` and a transposed `:part` layout) through `Project#to_h`/`from_h` and JSON; a standalone flow citing a work round-trips inline; a 21.0.0-shaped document with none of the new keys reads to empty collections; a concert-pitch all-players layout of one flow renders byte-identical to `flow.to_*` in all three formats; a `:part` layout over flows 1 and 3 renders two movements; every role name resolves in every locale file.

### Testing Strategy

- **Round trip from the most featured document** (previous story's learning): extend `spec/head_music/content/project_serialization_spec.rb`'s fixture rather than adding a minimal one, and assert `from_h(to_h).to_h == to_h`, JSON equality, and `flows[0].work == flows[1].work`.
- **Writer enumeration** (the other learning): for each of ABC, LilyPond, MusicXML, pin five small cases: work-bearing header, legacy-string header, byte-identical single-flow identity layout, multi-flow shape, transposed shape. Fifteen focused specs, not one integration test.
- **Compatibility oracles that must pass unedited**: `spec/head_music/content/cantus_firmus/source_spec.rb`, `example_spec.rb`, every existing writer spec, `flow/v3_hash_deserializer_spec.rb`.
- **Purity**: `Transposition` and `Credits` are specced with no flow at all; `expect { layout.realize(flow) }.not_to change { flow.to_h }`.
- **Coverage**: floor is 90%. Roughly 700 new lines, mostly attribute and serialization code the round trip exercises. Cover `Transposition`'s octave arms, the `Credits` rejection messages, and the `RenderError` branches (`to_musicxml` with several flows, `Key.for_fifths` overflow, a transposed ABC part that changes instrument) directly. Run the suite sequentially; concurrent SimpleCov runs corrupt the result.

### Risks

- **The realized flow mixes written pitches with a concert timeline.** That is what lets one document carry three written keys without a model change, but any consumer other than a writer built `transposed: true` would read it wrong. `Layout#realize` is private to rendering and documented as such; the identity-layout regression guard and the byte-identity spec for a concert-pitch score pin the concert path.
- **`RenderPlan`'s key methods change signature.** `first_measure_key` and `measure_key_changes` gain a `part` argument, touching both subclasses' consumers and every existing writer spec's fixtures. Keep the change to those two methods; the untouched writer specs are the regression oracle.
- **`Key.for_fifths` stops at ±7.** E major (4 sharps) for clarinet is fine; B major (5) becomes 7 sharps; F♯ major becomes 8 and raises. The message must name the part and suggest the enharmonic or it reads as a bug.
- **`sounding_transposition` is first-staff-only** (`staff_profile.rb:37`). No multi-staff transposing instrument is in the catalog; note, do not fix.
- **Realization cost** is one `to_h`/`from_h` per flow per render, O(placements) with position parsing. An 80-flow fake book re-parses every note; acceptable for a library that serializes on every save. Do not memoize on `Layout` (stale views); if profiling ever demands it, key a cache on `flow.to_h.hash`.
- **`Flow#latest_bar_number` reads voices only**, so a `:part` layout whose part ends early renders a shorter document than the score. Correct for a part book; document it.
- **Translations** for `fr`/`es` editor-vs-publisher (`éditeur scientifique`/`éditeur`, `editor`/`editorial`) and `de` `Transkribent` need a native check.
- **Story text needs two amendments** on acceptance of this plan: `author` joins the `Publication` roles; `ensemble_type` values are `ScoreOrder` keys or `nil`, not `:chamber`/`:pop`/`:solo`.

### Deferred, with the reason for each

- *Score-order data for chamber, pop, solo*: catalog authoring (score orders had their own epic), not modeling; `nil` gives authored order and no criterion exercises an order that does not exist.
- *Bracket emission from `player_groups`* (LilyPond `\new StaffGroup`, MusicXML `<part-group>`): a third writer option across two formats on top of the two this story already adds (`transposed`, titles); no criterion asks for it; `player_groups` is the data that step consumes and it is fully specced here.
- *Concert-pitch scores that keep octave transpositions* (Dorico's convention for piccolo, guitar, double bass): concert pitch here means sounding pitch for every part. The alternative would make today's `Flow#to_*` output for those instruments "wrong" and break the byte-identity guard.
- *A `Work` minted from `Flow.new(composer:)`*: the ABC `C:` and LilyPond `composer =` parsers feed that keyword with text like "Trad." or "arr. J. Smith", which is not a person and has no work title; the explicit path is `flow.work = Work.new(...)`.
- *`editor` as a project-level role*: a critical edition's editor is credited on the edition, so the role stays at the publication level only and `Role#level` stays single-valued.
- *`Person#sort_name` derivation*: "Bach, Johann Sebastian" fails on van Beethoven, de Falla, mononyms; store it, do not derive it; no renderer consumes it.
- *Publication ISBN/ISMN, year/publisher data in `sources.yml`*: no source has one and no writer emits one; one keyword argument when a consumer arrives.
- *A Work → Publication "first published by" edge*: a real relationship, no criterion needs it.
- *LilyPond `\bookpart`, MusicXML `<opus>`*: `\bookpart` only adds page-break control (engraving); `<opus>` is a separate file-referencing document type (Item-level packaging).
- *Pseudonyms, name variants, anonymous attribution*: excluded by the story; value-object `Person` does not foreclose a later authority key.
- *Cues, condensing, spacing*: engraving, per the story and the epic's non-goals.

### CHANGELOG sketch

```markdown
## [Unreleased]

### Added

- **`HeadMusic::Content::Work`, `Person`, `Credit`, `Role`.** A flow may cite a work — a title, catalog number, year, and its people — independent of any one notated version. Credits are constrained by level: composer, songwriter, lyricist, and librettist on a `Work`; arranger, transcriber, orchestrator, and reconstructor on a `Project`; author, editor, engraver, and publisher on a `Publication`. Roles are `Named` and translated. `Flow#composer` answers the cited work's composer and falls back to the authored string, so every existing document renders as before.
- **`HeadMusic::Content::Publication`.** `CantusFirmus::Source` is now a `Publication`; `Source.get`, `.all`, `.keys` and its readers are unchanged, and `Example#to_flow` cites its source on the flow.
- **`HeadMusic::Content::Layout` and `Score`.** A layout selects flows and players, overrides the displayed title, and renders in concert or written pitch through `#to_abc` (a tune book), `#to_lilypond` (one `\score` per flow), and `#to_musicxml` / `#to_musicxml_documents` (one document per flow). A `Score` orders and groups its players by ensemble type via `Instruments::ScoreOrder`, which gains `#group` and `#position_of`. Transposed layouts emit MusicXML `<transpose>` and LilyPond `\transposition`, with spelling preserved and each part's key signature moved by its own instrument, so a transposed score of flute, clarinet, and horn carries three written keys.
- Schema 4 gains optional `work`, `source`, `credits`, and `layouts` keys. 21.0.0 reads 21.1.0 documents and ignores them. Additive keys do not bump the schema; a rename or restructure does.
```

**Semver:** minor, **21.1.0**. No public method changes signature or return type (`Flow#composer` stays a `String`/`nil`; `Flow.new`'s keywords are only extended; `Source` gains readers and loses none); `Flow#to_abc`/`#to_lilypond`/`#to_musicxml` are byte-identical for every existing flow, pinned by the untouched writer specs and the identity-layout regression guard; schema stays 4 and `Flow.from_v3_h` is untouched; `Project` gains no render method. The per-part written key is a rendering fact on `RenderPlan`, not a model field, so it touches no schema. It becomes major only if `Flow#composer` returns a `Person`, `Flow.new(composer:)` starts minting works, or `Source` stops being a constant.

## Review

Reviewed 2026-09-08 at commit `73204f6` (working tree clean). Full suite: 8235 examples, 0 failures; line coverage 99.74%, branch 95.19%. Rubocop on all changed files: no offenses. Reviewers: product-manager and code-reviewer agents, with the three most consequential findings re-verified by hand.

### Acceptance criteria

| # | Criterion | Verdict | Evidence |
|---|---|---|---|
| 1 | A `Flow` may cite a `Work`, or none; flows in one project may cite different works | ✅ met | `flow.rb` `attr_accessor :work`; `flow_spec.rb` "#composer" (work wins, string fallback, mints no work); `project_credits_spec.rb` "#works" round-trip. Gap: no spec has two *distinct* works in one project (the existing spec is work-vs-nil). Verified by hand that three flows citing two works and nil round-trip to `works.size == 2`. |
| 2 | `Work` carries composer credits, `Project` carries arranger credits, each level rejects a foreign role | ✅ met | `credits.rb` `validate_level`; `credits_spec.rb` covers all three levels plus an accept case for all 12 roles; `work_spec.rb`, `project_credits_spec.rb`, `publication_spec.rb` each pin one rejection. |
| 3 | `Person` with only `full_name` is valid; years independently omittable | ✅ met | `person_spec.rb` contexts "with only a full name", "with only a birth year", "with only a death year"; death before birth raises. |
| 4 | A `Layout` selects flows and players and renders only those; two layouts render different documents | ✅ met | `layout_rendering_spec.rb`: flute vs violin parts differ in ABC, LilyPond, and MusicXML; staff and `part-list` counts; part book yields only tunes I and III; identity layout is byte-identical to `flow.to_*`. |
| 5 | A `Score` orders and groups players by ensemble type via `ScoreOrder` | ✅ met | `score.rb` (`Score < Layout`, `ordered_players`, `player_groups` delegating to `ScoreOrder#position_of` / `#section_key_of`); `score_spec.rb` orchestral vs string quartet order, tie order, `[:woodwind, :string, nil]` groups, MusicXML part-list in score order. |
| 6 | Concert-pitch and transposed layouts render the same voice at different written pitches | ✅ met | `layout_transposition_spec.rb`: `c'1`/`d'1`, `\key c`/`\key d`, `\transposition bes`, MusicXML step and fifths, `<transpose>` placement, ABC `K:` and note letters; trio score carries three written keys; concert score byte-identical to `flow.to_*`. |
| 7 | `Publication` serves existing cantus firmus sources with data intact | ✅ met | `Source < Publication` with `publication_name` / `publication_edition` / `author_names` aliases; `source_spec.rb` diff is additions only, so the pre-existing specs pass unedited; new cases check title, edition, abbreviation, notes, and author credits for Fux and C&M. |
| 8 | `title_override` changes the display without changing the work's title | ✅ met | `layout_title_spec.rb`: override reaches ABC `T:`, LilyPond `title =`, MusicXML `<work-title>`; "leaves the flow's own name alone". Gap: no spec asserts `work.title` itself is unchanged. `Work` is a frozen `Data`, and verified by hand. A one-line assertion would pin the criterion's literal wording. |

Everything the Model and Design Decisions sections promise is delivered: `Score < Layout`, `ordered_players`, `player_groups`, serialization round-trips for every new object, CHANGELOG entry, version 21.1.0, and the updates to `references/content-schema.md` and `references/wemi.md`. Nothing from the Out of Scope list leaked in.

### Code review findings

Nothing blocks `finish`. Ordered by severity.

**Important**

1. **A layout silently drops a selected member the project does not hold.** `Layout#selection_indexes` (`layout.rb:177`) uses `filter_map`, so a layout that selects a player from another project serializes as `"players" => []` and reads back as "no chairs", raising `RenderError` only at render time. Verified by hand. Raise on the unknown member at construction instead.

**Minor**

2. **`add_layout(kind: :score)` changes class on round-trip.** `Layout::KINDS` admits `:score`, but `Project#add_layout_from_h` (`project.rb:85`) rebuilds any `"kind" => "score"` as a `Score`. Verified: `Layout` before `to_h`, `Score` after. Rendering does not change because a nil ensemble type keeps authored order, so the impact is a class and an extra `ensemble_type` key. Drop `:score` from `Layout::KINDS` or make `add_layout(kind: :score)` delegate to `add_score`.
3. **The authored `composer:` string is not preserved across a round-trip when a flow cites a work.** `Flow#to_h` writes the derived composer, per plan decision 3 and the CHANGELOG, so this is by design. The consequence: after a round-trip, removing the work leaves the flow with the work's composer string rather than what was authored. Decision 3's phrase "the string is retained" describes in-memory reads only and should say so.
4. `Credit.from_h` (`credit.rb:8`) reads string keys only; `Person.from_h` and `Publication.from_h` normalize. A symbol-keyed credit fails with the misleading `unknown credit role: nil`.
5. `Person.new(full_name: nil)` yields a person named `""` (`person.rb:24`); the years are validated but the one required field is not.
6. `Score#rank_of` (`score.rb:71`) calls `ordered_players` inside a `sort_by` block, re-sorting the roster once per part. Memoize `ordered_players`.
7. `Score#player_groups` (`score.rb:39`) and `ScoreOrder#group` (`score_order.rb:47`) share the same `slice_when` body and the same comment; `Score` could map its players through `score_order.group`.
8. `Layout#to_h` hardcodes `"ensemble_type" => nil` (`layout.rb:133`) so that `Score` can override it; the base class knows a subclass's key.
9. The diff removes a number of pre-existing "why" comments in `flow.rb`, `project.rb`, `flow/hash_deserializer.rb`, `abc/writer.rb`, `music_xml/writer.rb`, `voice_writer.rb`, and `score_order.rb` that are unrelated to this story, including the rationale for the clef fallback living in the writer.

**Nit**

10. `Layout#rendered_flows` is recomputed on every call, several times per render.
11. `Transposition#to_s` (`transposition.rb:107`) has no caller and no spec.
12. `RenderPlan` memoizes `keys_by_part` with `||=`, so a falsy key recomputes.
13. CHANGELOG heading reads `## [21.1.0] - 2026-09-08` rather than `[Unreleased]`; fine if the release goes out on merge.
14. CLAUDE.md still lists the locales as en, de, es, fr, it, ja, nl. The real set is en, en_GB, de, es, fr, it, ru, and all six translated files gained `credit_roles` with `en_GB` falling back correctly. The plan noted the staleness but the branch does not fix it.
15. The story's risk list still flags fr/es `éditeur scientifique` / `éditeur` and de `Transkribent` for a native-speaker check.

### Addressed after review

Applied 2026-09-08, uncommitted at the time of writing:

- Finding 1: `Layout` refuses a flow or player its project does not hold at construction, and `attributes_from_h` no longer drops an out-of-range index, so a document with a stray selection fails to read rather than reading as an absence. Specs in `layout_spec.rb` and `project_serialization_spec.rb`.
- Finding 2: `Layout::KINDS` is `part` and `custom`; `Score::KINDS` is `score`; `Project#add_layout(kind: :score)` answers a `Score`. A round-trip keeps each layout's class.
- Finding 3: plan decision 3 now says the authored string is retained in memory only and that the derived string is what survives a round-trip.
- Finding 4: `Credit.from_h` normalizes symbol keys; `Person` requires a full name; `Score#kept_part_indexes` computes the player order once per flow instead of once per part.
- Finding 5: restored the rationale the branch had dropped, condensed, in `flow.rb`, `flow/hash_deserializer.rb`, `project.rb`, `abc/writer.rb`, `lily_pond/voice_writer.rb`, and `music_xml/writer.rb`. The `score_order.rb` comments that were removed described what the code does rather than why, so they stay removed.

### Done well

`Transposition` is a pure value object specced with no flow at all, and deriving `fifths_delta` from the move itself avoids a second table. Realizing a derived flow keeps the writers, both render plans, and both preflights ignorant of selection, and the byte-identity guards pin it. `ScoreOrder`'s single section index makes ordering and grouping unable to disagree. Passing the pre-existing `Source` specs unedited is exactly the right oracle for the `Publication` absorption.
