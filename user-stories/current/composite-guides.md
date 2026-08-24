<!--
metadata:
  created_at:   2026-08-23T15:37:56-07:00
  activated_at: 2026-08-23T16:57:38-07:00
  planned_at:
  finished_at:
  updated_at:   2026-08-23T16:57:38-07:00
-->

# Composite Guides

AS an application grading a species counterpoint exercise

I WANT to ask the gem for `first_species` and get one grade back

SO THAT the pairing of a melody guide with a harmony guide, and the rule for
combining their two grades, is counterpoint pedagogy stated once in the gem
rather than re-derived by every consumer

Part of the [Style Assessment Model](../epics/style-assessment-model.md) epic.

## What the consumer does today

BardTheory pins the released `head_music 19.0.0` and grades a submission through
`app/services/counterpoint_analysis_service.rb`, which carries a hand-written
table of the pairs:

```ruby
GUIDE_KEYS_BY_SPECIES = {
  1 => %w[first_species_melody first_species_harmony],
  2 => %w[second_species_melody second_species_harmony],
  # ... five more rows
  "1+2+3" => %w[combined_first_second_third_species_melody combined_first_second_third_species_harmony]
}.freeze
```

Both guides are assessed against the *same* voice — the one whose role is
`counterpoint`. The cantus firmus is in the composition only so the harmony
guide's guidelines can reach it. The two grades are then combined in
`app/services/style_analysis_service.rb`:

```ruby
def combined_fitness(analyses)
  return 1.0 if analyses.empty?
  analyses.map(&:fitness).reduce(:*)**(1.0 / analyses.length)
end
```

A geometric mean. `ExerciseSubmissionGradingService` turns it into
`score: fitness * 100, correct: fitness >= 0.9`.

Three things are wrong with that arrangement, and none of them are BardTheory's
fault:

1. **The species→guides mapping is domain knowledge in an app.** Which two
   guides make up third species is a fact about counterpoint, not about a Rails
   app's wire format.
2. **The combining rule is domain knowledge in an app.** Whether a species grade
   is the geometric or arithmetic mean of its halves is a pedagogical decision.
   It is currently four lines in a private method that no gem spec covers.
3. **Findings are re-attributed by position.** The service does
   `selected_guides.zip(analyses)` to tag each annotation with its guide's
   category. Every member assessment already knows its own guide; the zip is a
   workaround for having no object that holds the pair.

Note also that BardTheory is on the released 19.0.0 — `Style::Analysis`,
`annotations`, `analyze(voice)` — while `main` has already renamed those to
`GuideAssessment`, `guide_item_assessments`, `assess_items`. The consumer has a
migration coming regardless. This story should land in the same major so it is
one migration and not two.

## The design

### `Style::Guides::CompositeGuide`

Several guides graded together as one. Stands in for a guide class wherever one
is expected: answers `assess(voice)`, `assess_items(voice)`, `guide_items`,
`key`, `display_name`, `instruction`, and value equality by its members.

```ruby
composite = HeadMusic::Style::Guide.get("first_species")
composite.guides      # => [FirstSpeciesMelody, FirstSpeciesHarmony]
composite.categories  # => [:melody, :harmony]
composite.category    # => nil -- it spans its members' categories rather than claiming one
composite.composite?  # => true
```

`composite?` is added to `Guides::Base` and `Guides::Configured` returning
`false`, so the two kinds are distinguishable without an `is_a?` check.

### `Style::CompositeAssessment`

| Member | Notes |
| --- | --- |
| `guide`, `voice` | |
| `assessments` | One `GuideAssessment` per member. |
| `fitness` | Geometric mean. See below. |
| `fitness_by_category` | Members grouped by category, geometric mean within each. Grouped rather than keyed, so a composite of two guides sharing a category does not silently drop one. |
| `guide_item_assessments` | Every member's, flattened. |
| `messages` | Every member's, in member order. |
| `adherent?` | All members adherent. |
| `assessable?` | All members assessable. |

`GuideAssessment` gains one line — `def assessments = [self]` — so a leaf and a
composite answer the same question. A consumer walks `assessment.assessments`
and never asks which kind it holds. That uniformity is the whole reason to reach
for the pattern rather than a bare pair.

### Composing grades, not items

This is the load-bearing decision and it needs to be written into the class, not
just this story. The naive composite — one guide whose `items_by_tier` is the
union of its members' — is wrong twice:

**It raises.** `SpeciesMelody::MELODIC_GATES` and
`SpeciesHarmony::HARMONIC_GATES` both contain `MinimumNotes.with(3)`, and
`GuideItem#==` is by value (guideline plus config). `Base.reject_duplicates`
rejects the union of any melody/harmony pair outright.

**It undoes the tier budgets.** `TIER_BUDGETS` exists so that what a guide
teaches does not thin out as inherited craft accumulates around it — the comment
in `GuideAssessment` spells out the 0.200 → 0.111 erosion it was built to
prevent. Merging first species puts roughly nineteen primaries into a single φ⁻¹
budget and halves every taught rule's share. That is the same erosion, arrived
at from a different direction.

So the composite holds member *assessments* and combines their grades.

### Grading

**Geometric mean, decided.** A species grade is two grades that must both hold.
A perfect melody against a half-graded harmony reads 0.707 rather than the
arithmetic 0.75, and either half at zero takes the whole grade to zero. Acing
the melody does not buy relief from the harmony.

**A failed gate in any member makes the composite unassessable, decided.**
`assessable?` is `assessments.all?(&:assessable?)`.

**An unassessable composite's fitness is its members' gate factors alone,
decided.** This is `GuideAssessment`'s own rule lifted one level. Its comment
states it: *"A voice failing a precondition has not earned a bad grade on the
rest, so the rubric is not computed and fitness is the gates alone."* The same
sentence with the nouns raised reads: if any member is unassessable, the
composite has not earned a grade on the *other members* either.

```ruby
def fitness
  @fitness ||= geometric_mean(
    assessable? ? assessments.map(&:fitness) : assessments.map(&:gate_factor)
  )
end
```

This needs `gate_factor` promoted from private to public on `GuideAssessment` —
the one change the story makes to an existing type's surface. It is already the
number that class computes; it is currently only reachable from inside.

The rejected alternative was the unconditional geometric mean of member
fitnesses. It is simpler, and for the unassessable member it gives the same
number, since that member's fitness *is* its gate factor. But it lets an
assessable member's rubric leak into a grade that was never earned: a solo voice
submitted for first species fails `SetAgainstAnotherVoice`, and its harmony gate
factor is then square-rooted against a melody rubric that graded normally. Which
direction that moves the number depends on the melody, which is the tell — a
precondition failure should not be softened *or* sharpened by material the guide
declined to grade.

Write the rule into the class, next to the sentence it was lifted from.

### Registry

Composites belong in `REGISTRY`, and therefore in `ALL`, `Guide.keys`, and
`Guide.all`. They reference entries built in the first pass, so the registry
gains a second pass:

```ruby
COMPOSITE_MEMBERS = {
  "first_species" => %w[first_species_melody first_species_harmony],
  "second_species" => %w[second_species_melody second_species_harmony],
  "third_species" => %w[third_species_melody third_species_harmony],
  "third_species_triple_meter" => %w[third_species_triple_meter_melody third_species_triple_meter_harmony],
  "fourth_species" => %w[fourth_species_melody fourth_species_harmony],
  "fifth_species" => %w[fifth_species_melody fifth_species_harmony],
  "first_three_species" => %w[first_three_species_melody first_three_species_harmony]
}.freeze
```

Built with `fetch`, in the temperament the file already has: a member renamed in
`Guides` takes the gem down at load rather than leaving a species with half a
ruleset.

`ALL.each(&:guide_items)` and `Template.verify!(ALL)` both walk the registry, so
`CompositeGuide` must answer `guide_items` (its members' items, `uniq` — they
share gates) and `instruction`. Seven new locale entries under
`head_music.style.guides`. Instruction only: `display_name_for` humanizes
`first_species` to "First Species" without help.

### Guarding against the wrong arithmetic

`Guide.get` passes through anything answering `assess_items`, and
`GuideAssessment.new(guide, voice)` is a public constructor that BardTheory
calls directly today. A composite handed to `GuideAssessment` would flatten its
members' items and return a plausible number computed the wrong way — the exact
failure the design above exists to avoid.

`GuideAssessment#initialize` should refuse it:

```ruby
if guide.composite?
  raise ArgumentError, "#{guide.inspect} grades its members separately -- use guide.assess(voice)"
end
```

and `CompositeAssessment#initialize` should refuse a non-composite, symmetrically.

## The renames

Four renames ride along, because the composite key for the mixed-rhythm guide
would otherwise be `combined_first_second_third_species`, and because the
composite registry is the moment every one of these keys is being read anyway.

| Today | Becomes |
| --- | --- |
| `Guides::CombinedFirstSecondThirdSpeciesMelody` | `Guides::FirstThreeSpeciesMelody` |
| `Guides::CombinedFirstSecondThirdSpeciesHarmony` | `Guides::FirstThreeSpeciesHarmony` |
| `Guidelines::AllowedRhythmicValuesForCombined123` | `Guidelines::AllowWholeHalfQuarterNotes` |
| `Guidelines::AllowedRhythmicValuesForFifthSpecies` | `Guidelines::AllowFifthSpeciesRhythmicValues` |

Each carries a locale key, a filename, a spec filename, and a `require` line in
`lib/head_music.rb`; the two guides carry a registry key as well. Both
guidelines appear in `spec/head_music/style/guide_item_strings_spec.rb`, and
each is declared by exactly one guide — `AllowWholeHalfQuarterNotes` by
`FirstThreeSpeciesMelody`, `AllowFifthSpeciesRhythmicValues` by
`FifthSpeciesMelody`.

`combined` is being freed deliberately: it currently means "mixed rhythm" on
these two guides and would mean "composed of members" on the new type. One word,
two meanings, in the same namespace.

The two guideline names take different shapes on purpose. First through third
species allow a set small enough to say — whole, half, quarter — so the name
says it. Fifth species allows that set plus eighths, plus ties, under conditions
the guideline itself decides; enumerating it in a class name would be a lie of
omission, so the name points at the species and lets the class hold the rule.

Consumer impact: `combined_first_second_third_species_melody` and
`..._harmony` are published registry keys that BardTheory names in
`GUIDE_KEYS_BY_SPECIES`. Breaking, and belongs in the same major as the rest.

## Scope

- `Style::Guides::CompositeGuide` and `Style::CompositeAssessment`.
- `composite?` on `Guides::Base`, `Guides::Configured`, and `CompositeGuide`.
- `assessments` on `GuideAssessment`, returning `[self]`.
- `gate_factor` promoted to public on `GuideAssessment`.
- The `GuideAssessment` / `CompositeAssessment` construction guards.
- Two-pass `REGISTRY` in `Style::Guide`, with seven composite entries.
- Seven `instruction` entries in `en.yml`, plus whatever `en_GB.yml` needs.
- The four renames, across `lib/`, `spec/`, and both locale files.
- Update `spec/head_music/style/guide_spec.rb`: the pinned count moves 23 → 30,
  and the published-key list gains seven entries and changes two.
- The solo-voice sweep in that spec (`each_guide_and_length`) now runs composites
  too. A solo voice fails the harmony member's `SetAgainstAnotherVoice` gate, so
  the sweep exercises the unassessable path directly — keep it green rather than
  exempting composites from it.
- Composites go into the grade corpus. `bin/guide_grade_corpus.rb` walks
  `Guide::ALL`, so they arrive on their own; its `grade` helper already asks only
  for `fitness`, `adherent?`, `messages`, `assessable?`, `guide_item_assessments`
  and `item.gate?`, every one of which `CompositeAssessment` answers. Confirm the
  `failed_gates` column reads correctly for a composite — it names the guideline,
  and a composite's flattened items carry gates from both members.
- Regrade the corpus and capture a `composite-guides.grades.md` alongside the
  existing `re-tier-the-guides.grades.md` and `extract-the-harmonic-cores.grades.md`,
  showing each species composite beside the two members it is built from.

## Acceptance Criteria

- `Guide.get("first_species")` returns a `CompositeGuide` over
  `[FirstSpeciesMelody, FirstSpeciesHarmony]`, and the same holds for all seven
  species keys.
- `composite.assess(voice).fitness` equals the geometric mean of the members'
  fitnesses, proven against a hand-computed value for at least one Fux
  first-species voice.
- A voice scoring 1.0 on its melody member and 0.5 on its harmony member grades
  0.707, not 0.75.
- A member fitness of 0.0 takes the composite to 0.0.
- A solo voice submitted to `first_species` is `assessable? == false`, and its
  fitness is the geometric mean of the two members' gate factors — pinned by a
  spec that names the number, and demonstrably unchanged when the melody the
  solo voice sings is changed to one that grades differently.
- `assessment.assessments` answers a one-element array for a `GuideAssessment`
  and one element per member for a `CompositeAssessment`, so a consumer walking
  it needs no branch.
- `fitness_by_category` returns a melody grade and a harmony grade for every
  species composite.
- `GuideAssessment.new(composite, voice)` raises with a message naming
  `assess`, rather than grading a flattened rubric.
- `Guide.all.length` is 30, every entry answers `instruction` and `guide_items`,
  and `Template.verify!` passes at load in English.
- No occurrence of `CombinedFirstSecondThirdSpecies`, `AllowedRhythmicValuesFor`,
  or their snake-case forms remains anywhere in `lib/`, `spec/`, or `bin/`.
- The existing 23 leaf guides grade bit-identically to before. Composites are
  additive; nothing about a leaf's rubric changes.
- The regraded corpus contains a row per species composite per fixture, and
  `composite-guides.grades.md` shows each composite beside its two members.
- `bundle exec rake validate` is green.

## Open questions

- **Should the melodic-only guides get composites too?** `diatonic_melody` and
  the six contour guides are single guides that a consumer already asks for by
  one key. They need nothing. But if a melody exercise ever wants "arch contour
  *and* diatonic," `CompositeGuide` is already the answer and the registry entry
  is one line.

## Notes

The registry already contains non-class entries: `CONTOUR_CONFIGURATIONS` puts
six `Guides::Configured` *instances* into `REGISTRY` alongside the seventeen
classes, and `Guide.get` duck-types on `respond_to?(:assess_items)` rather than
checking for a class. A `CompositeGuide` instance is the same move a second
time, so nothing about the lookup facade needs to change.

Downstream, `StyleAnalysisService#combined_fitness` deletes entirely and
`CounterpointAnalysisService`'s seven-row pair table collapses to seven single
keys — or disappears, if the app sends gem keys on the wire.
