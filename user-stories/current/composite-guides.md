<!--
metadata:
  created_at:   2026-08-23T15:37:56-07:00
  activated_at: 2026-08-23T16:57:38-07:00
  planned_at:   2026-08-23T18:13:44-07:00
  finished_at:
  updated_at:   2026-08-23T18:46:12-07:00
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
`items_by_tier`, `key`, `display_name`, `instruction`, and value equality by its
members. `items_by_tier` is not optional — two registry-wide sweeps in
`guide_spec.rb` and `base_spec.rb` call it on every entry.

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
fitnesses. It is simpler, and for an unassessable member it gives the same
number, since that member's fitness *is* its gate factor.

**With today's registry the two rules are numerically indistinguishable**, and
the story is honest about that rather than claiming a difference it cannot
demonstrate. The members of a species composite share `MinimumNotes.with(3)`,
so they fail it together and identically; the only gate that differs between
them is `SetAgainstAnotherVoice`, which scores exactly 0 or 1. A solo voice
therefore grades `0.0` under either rule, at every length.

They part company where the members' gates differ *and* at least one scores a
fraction — `MinimumNotes` does score fractionally (0.333 at one note, 0.667 at
two), so a future species that gated its melody and harmony at different minima
would reach the divergence immediately. There the unconditional mean lets an
assessable member's rubric leak into a grade that was never earned, moving it up
or down according to material the guide declined to look at.

So the rule is chosen for what a gate *means*, not for a number it currently
changes. That is also why it needs the stub-member spec named in the acceptance
criteria: nothing in the registry can fail if the branch is deleted.

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
- A shared example group at `spec/support/shared_examples_for_assessments.rb`
  that both `GuideAssessment` and `CompositeAssessment` must satisfy, so the two
  cannot drift out of protocol sync — the one real cost of grading through two
  classes instead of one. Its load-bearing assertions are relations *between*
  methods, since those are what cannot drift silently:
  `assessments.flat_map(&:guide_item_assessments) == guide_item_assessments`, the
  same for `messages`, and `!assessable?` implying `fitness == gate_factor`. Pair
  it with one reflective example pinning that the two classes declare the same
  public instance methods, since a shared group can only run what it already
  knows to ask for.
- Composites go into the grade corpus, but they do **not** arrive on their own,
  as this story first assumed. `bin/guide_grade_corpus.rb:84` constructs
  `GuideAssessment.new(guide, voice)` directly — the very constructor this story
  makes raise for a composite — and the script's bare `rescue` would swallow that
  into `error: "ArgumentError"` for every composite row while still exiting 0.
  The call must become `guide.assess(voice)`, and that edit must land *before*
  either capture is taken. Its `grade` helper is otherwise fine: it asks only for
  `fitness`, `adherent?`, `messages`, `assessable?`, `guide_item_assessments` and
  `item.gate?`, all of which `CompositeAssessment` answers.
- Dedupe the corpus script's `failed_gates` column for composites. It reads
  `["MinimumNotes", "MinimumNotes", "SetAgainstAnotherVoice"]` below three notes,
  because both members declare `MinimumNotes.with(3)` and each assesses it. Fix
  it in the script, not the model — `guide_item_assessments` must stay the
  members' flat concatenation or the shared example group's strongest invariant
  breaks.
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
- A solo voice submitted to `first_species` is `assessable? == false` and grades
  exactly `0.0`. The example asserts its own premise before its conclusion — that
  the two solo melodies it compares genuinely grade differently against the
  melody member, and that both are assessable there — since without that the
  comparison proves nothing.
- The gate-factor rule is pinned by a case that can tell it apart from the
  rejected alternative. No voice in the registry can: `SetAgainstAnotherVoice`
  scores exactly 0 or 1 and is the only gate that differs between a melody member
  and its harmony partner, so both rules return `0.0` for every reachable solo
  voice and the criterion above would stay green under the implementation this
  story rejected. The discriminating case is stub members — one with a fractional
  failed gate of 0.25, one assessable with a rubric of 0.5. The decided rule
  gives `√(0.25 × 1.0) = 0.5`; the unconditional mean gives
  `√(0.25 × 0.5) ≈ 0.354`. Deleting the branch must fail this example, and it is
  the only example in the suite that would notice.
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

## Implementation Plan

Every empirical claim below was re-verified against the working tree before it
was written down: the item-union counts, the three fitness numbers, the
solo-voice sweep, and the four file-and-line claims about specs and scripts.

### Overview

`CompositeGuide` mirrors `Guides::Configured` member-for-member — an
instance-valued registry entry with constructor-time item resolution,
reverse-key lookup, and value equality — so the lookup facade, the load-time
warm-up, and `Template.verify!` need no special case. `CompositeAssessment`
holds one `GuideAssessment` per member and combines their grades. The work lands
in five steps, the first two of which are behavior-free and exist so the corpus
capture can join.

### Sequencing

**The four renames land first, alone, and the corpus-script seam change lands
second — before any capture is taken.** The precedent from epic story 1
("Mechanical, and it makes story 2's diff readable") is the weakest of three
reasons. The forcing one is mechanical:

`bin/guide_grade_table.rb:34` joins captures with
`indexed.fetch([row[:corpus], row[:guide]])` — an unconditional `fetch`. A
before-capture taken on today's tree is keyed
`combined_first_second_third_species_{melody,harmony}`; the after tree emits
`first_three_species_{melody,harmony}`. Those rows raise `KeyError` and take the
table script down. Teaching the script an old→new key alias is precisely the
"guess the cause after the fact" its own header (`bin/guide_grade_table.rb:14-22`)
records as having mislabelled two hundred rows. So the before-capture must run
on a tree that already carries the new names.

The same argument applies to the capture script itself, one step later.

| Step | Content | Verified by |
| --- | --- | --- |
| 1 | The four renames | `bundle exec rake validate` |
| 2 | `guide_grade_corpus.rb` grades via `guide.assess(voice)`; capture `tmp/before.json` | `rake validate`; capture byte-identical to a pre-edit capture |
| 3 | The two new types, `composite?`, `categories`, `assessments`, public `gate_factor`, both guards, the shared example group — **not registered** | `rake validate` |
| 4 | Two-pass `REGISTRY`, seven locale entries, the registry-sweep spec updates | `rake validate` |
| 5 | `tmp/after.json`, the table-script edit, `composite-guides.grades.md`, CHANGELOG | `rake validate` + the generated doc |

Steps 3 and 4 could merge. Keeping them apart separates failures that surface in
a spec from failures that surface on `require` — the latter take the whole suite
down and hide everything else.

Baseline before starting: 6733 examples, 0 failures, 99.77% line coverage,
rubocop clean, `Guide.all.length == 23`, `PLURAL_GAPS == []`.

### Step 1 — The four renames

- `git mv` in `lib/head_music/style/`:
  - `guides/combined_first_second_third_species_melody.rb` → `guides/first_three_species_melody.rb`
  - `guides/combined_first_second_third_species_harmony.rb` → `guides/first_three_species_harmony.rb`
  - `guidelines/allowed_rhythmic_values_for_combined123.rb` → `guidelines/allow_whole_half_quarter_notes.rb`
  - `guidelines/allowed_rhythmic_values_for_fifth_species.rb` → `guidelines/allow_fifth_species_rhythmic_values.rb`
- The same four basenames under `spec/head_music/style/guides/` and
  `spec/head_music/style/guidelines/`.
- Class names in the four moved files, plus the two references:
  `guides/fifth_species_melody.rb:9` and `guides/first_three_species_melody.rb:10`.
- `lib/head_music.rb`: four `require` lines rewritten in place (guidelines at
  270-271, guides at 295-296). Neither block is alphabetical; the only constraint
  is the comment at the end — `head_music/style/guide` stays last.
- `lib/head_music/style/guide.rb:22-23`: the two `GUIDE_CLASSES` entries.
- `lib/head_music/locales/en.yml`: guideline keys at 664 and 669, guide keys at
  932 and 934. Values unchanged. The guidelines block is alphabetical, so the two
  renamed keys swap order and both still sit immediately before `always_move`;
  the guides block is in species order, so `first_three_species_*` stays where it
  is.
- `lib/head_music/locales/en_GB.yml`: guideline keys at 40 and 45 (swap, same
  reason), guide key at 87 (moves down past `first_species_melody`).
- `spec/head_music/style/guide_item_strings_spec.rb:14-15` — two table rows,
  renamed and swapped; sentences unchanged.
- `spec/head_music/style/guide_spec.rb:216-217` — two `published_keys` entries,
  moving down past `first_species_melody`.
- `spec/head_music/style/guides/base_spec.rb:103` — the `expected` hash key.
- `spec/head_music/style/guides/fifth_species_melody_spec.rb:20`, plus the
  `describe` lines of the two renamed guide specs and the `include` at
  `combined_first_second_third_species_melody_spec.rb:18`.
- `CHANGELOG.md:28,105,106` name the old class and keys inside the still-unreleased
  section; update them so the released history stays truthful.

Verify with the acceptance criterion's own check:
`git grep -n "CombinedFirstSecondThirdSpecies\|combined_first_second_third\|AllowedRhythmicValuesFor\|allowed_rhythmic_values_for" lib spec bin`
returns nothing.

### Step 2 — The capture seam, then the before-capture

`bin/guide_grade_corpus.rb:84` constructs
`HeadMusic::Style::GuideAssessment.new(guide, voice)` directly — the exact
constructor Step 3 makes raise for a composite. The bare `rescue` at :94 would
swallow that into `{fitness: nil, error: "ArgumentError"}` for every composite
row, and the run would still exit 0. The story's Scope claims composites "arrive
on their own"; they do not.

- Change `bin/guide_grade_corpus.rb:84` to `guide.assess(voice)`. This is
  provably the same call on the before tree — `Guides::Base.assess` is
  `GuideAssessment.new(self, voice)` (`guides/base.rb:34-36`) and
  `Configured#assess` is identical (`configured.rb:15-17`).
- Resolve the tension with the script's "runs UNMODIFIED on both sides" header
  honestly rather than by refusing the edit: the invariant that header protects
  is *each column is the same measurement made again*, and making the edit before
  both captures preserves it. Prove it — capture once with the current script,
  once with the edited one, and `diff` the JSON. They must be byte-identical.
  Commit `c09eea3` ("Drop the last of the before/after shims from the corpus
  script") is the precedent that this file is edited across stories.
- Capture: `bundle exec ruby bin/guide_grade_corpus.rb tmp/before.json` → 3266
  rows (142 entries × 23 guides), roughly 32s.

### Step 3 — The two new types

**New `lib/head_music/style/guides/composite_guide.rb`.** Mirrors `configured.rb`
throughout: `guides` reader; `composite?` → true; `assess(voice)` →
`CompositeAssessment.new(self, voice)`; `assess_items(voice)`; `items_by_tier` as
a per-tier union `uniq`'d within each tier; `guide_items` memoized into
`@guide_items`; `category` → nil; `categories` → `guides.map(&:category).uniq`;
`key` by reverse lookup; `display_name`/`instruction` keyed-or-fallback;
`==`/`eql?`/`hash`/`name`/`to_s`/`inspect` by members.

Three details are load-bearing:

- Resolve `guide_items` in the constructor, as `configured.rb:12` does.
  `guide_spec.rb:189-193` asserts `instance_variable_defined?(:@guide_items)` on
  every non-Class registry entry, so eager resolution is mandatory and the ivar
  name is fixed.
- **Never touch `key`, `display_name`, or `instruction` from the constructor.**
  They read `Guide::REGISTRY`, which does not exist while the second pass is
  running. Getting this wrong fails on `require`.
- `items_by_tier` is required and the story's surface list omits it —
  `guide_spec.rb:134` and `base_spec.rb:156` both call it over `Guide.all`.

The `uniq` genuinely works: `GuideItem#eql?` is aliased to `#==` (guideline +
config) with `#hash` as `[guideline, config].hash` (`guide_item.rb:57-64`), which
is what `Array#uniq` uses. Verified — `FirstSpeciesMelody.guide_items +
FirstSpeciesHarmony.guide_items` is 27 items, 26 unique; the shared
`MinimumNotes.with(3)` collapses. Do **not** run `Base.reject_duplicates` over
the union: it exists to catch double-counting inside one rubric
(`guides/base.rb:148-155`), and the whole design is that a composite never grades
a merged rubric. Say so in the class comment — **the flattened item list is for
display, not for grading.**

Raise in the constructor on an empty member list, and on any member answering
`composite?`. Nesting is not merely unspecified; at depth two `assessments` would
have to mean both *members* (what `fitness` divides by) and *leaves* (what a
consumer walks), and those diverge. One line defers it honestly and keeps the
`assessments` acceptance criterion true.

**New `lib/head_music/style/composite_assessment.rb`.** `guide`, `voice`,
`assessments` (memoized), `guide_item_assessments` (`assessments.flat_map(...)`,
memoized), `messages`, `adherent?`, `assessable?`, `fitness` (memoized),
`fitness_by_category`, `gate_factor`, private `geometric_mean`. Carry the story's
paragraph — the sentence lifted from `guide_assessment.rb:49-50` — as the comment
above `fitness`.

Memoize `@assessments`: without it every call to `fitness`, `messages`, and
`guide_item_assessments` re-runs the full member analysis and `assessments.first`
is a different object each time.

Geometric mean: `values.reduce(:*) ** (1.0 / values.length)`. It is exact where
exactness is required — `[1.0, 1.0]` → `1.0 ** 0.5` → exactly 1.0 (which
`adherent?` depends on), any 0.0 member → exactly 0.0, and a single member →
`x ** 1.0` → exactly `x`. `Math.exp(mean of logs)` would trade a non-existent
underflow risk at n≤7 for losing both. Leave the empty case to raise
`NoMethodError` on `[].reduce(:*)`; the constructor guard catches it first with a
message that names the guide, and a silent 1.0 there is the "nothing to find
fault in" confusion `guides/base.rb:102-110` already argues against.

**Modified `lib/head_music/style/guide_assessment.rb`:**

- `def assessments = [self]`.
- Move `gate_factor` (:78-80) above `private` (:68), and change `reduce(1, :*)`
  to `reduce(1.0, :*)` — today a gate-less guide returns Integer `1` from what is
  about to be public API. Bit-identical for every registry guide, which all have
  gates.
- Add `fitness_by_category` → `{category => fitness}`, one group of one, so the
  two classes answer the same protocol. It needs `guide.respond_to?(:category)`
  for the duck-typed case.
- The composite refusal in `initialize`, **after** the existing `assess_items`
  check and written leniently:

  ```ruby
  if guide.respond_to?(:composite?) && guide.composite?
    raise ArgumentError, "#{guide.inspect} grades its members separately -- use guide.assess(voice)"
  end
  ```

  A bare `guide.composite?` raises `NoMethodError` for any duck-typed guide,
  breaking `Guides::PermissiveGuide` (`guide_assessment_spec.rb:3-7`),
  `GradedStubGuide` (:13-20), and the `double("Guide", assess_items:)` at :77 —
  and contradicting the documented duck type at `guide.rb:52-56`. Ordering
  matters too: the `assess_items` check must stay first or `new(nil, voice)`
  raises `NoMethodError` instead of the `ArgumentError` pinned at :97-99.
  `CompositeAssessment#initialize` is strict in the other direction — it
  *requires* a composite, so
  `unless guide.respond_to?(:composite?) && guide.composite?` is correct there.

**Modified `guides/base.rb`** (inside `class << self`, beside `category` at
:57-60) and **`guides/configured.rb`** (beside `category` at :43-45):
`composite?` → false, and `categories` → `[category].compact`. `categories` is
the guide-side twin of `assessments = [self]`, and it is what lets the
registry-wide category example survive Step 4.

**Modified `lib/head_music.rb`:** `require "head_music/style/composite_assessment"`
after `guide_assessment`; `require "head_music/style/guides/composite_guide"`
after `guides/configured`. The registry require stays last.

### Step 4 — The registry and the locales

`lib/head_music/style/guide.rb` — split the current expression at :39-42 into a
first-pass constant and merge the second pass over it, never over `REGISTRY`
itself (mid-assignment):

```ruby
LEAF_REGISTRY = GUIDE_CLASSES.to_h { ... }.merge(CONTOUR_CONFIGURATIONS.transform_values { ... }).freeze
COMPOSITE_MEMBERS = {"first_species" => %w[first_species_melody first_species_harmony], ...}.freeze
REGISTRY = LEAF_REGISTRY.merge(
  COMPOSITE_MEMBERS.transform_values { |keys|
    HeadMusic::Style::Guides::CompositeGuide.new(keys.map { |key| LEAF_REGISTRY.fetch(key) })
  }
).freeze
```

`ALL` (:44), the warm-up (:48), and `verify!` (:97) are untouched and pick up the
seven new entries. `fetch` gives the story's intended failure: a member key
removed from `GUIDE_CLASSES` takes the gem down on `require` rather than leaving
a species half-ruled.

**Load-time hazards, traced.** `Template.verify!` (`template.rb:98-111`) asks a
composite for `instruction`, then for each `guide_item` its `name`,
`instruction`, and `violation_previews`. So a composite needs exactly two things:
an `instruction` that renders in `:en`, and a `guide_items` array of real
`GuideItem`s. Every item in that array is an object its members already own and
`verify!` already rendered, so no new template becomes reachable and
`PLURAL_GAPS` cannot grow — which matters, because `guide_strings_spec.rb` pins
it empty. `display_name` is not asked for at load.

**Locales.** Seven `instruction`-only entries under `head_music.style.guides` in
`en.yml`; no `name` entries, since `display_name_for` (`guide.rb:83-89`)
humanizes all seven correctly. `en_GB.yml` needs an override for every composite
instruction containing an American note value, or `guide_strings_spec.rb:136-145`
fails for `en_GB`, `de`, `fr`, `it`, and `ru` at once. On natural wording that is
five of the seven — `first_species`, `second_species`, `third_species`,
`third_species_triple_meter` (also "meter" → "metre", matching the existing
override at :99), and `first_three_species`. The regex is
`\b(whole|half|quarter|eighth|sixteenth)[-\s](note|rest)`, so "mix note values"
is safe. Every `en_GB` key added must have an `en` counterpart.

### Testing strategy

#### The shared example group — fold this into Scope

**New `spec/support/shared_examples_for_assessments.rb`**, loaded by the glob at
`spec/spec_helper.rb:34`, following `shared_examples_for_sounds.rb`. Parameterize
by **guide and voice** rather than by the assessment, so it also pins the
`assess` round-trip:

```ruby
RSpec.shared_examples "a style assessment" do
  subject(:assessment) { guide.assess(voice) }
  # including specs define let(:guide) and let(:voice)
end
```

The protocol is `guide`, `voice`, `assessments`, `guide_item_assessments`,
`messages`, `fitness`, `adherent?`, `assessable?`, `gate_factor`,
`fitness_by_category`. The assertions that earn their place are *relations
between two methods*, because those are what cannot drift:

- `assessments.flat_map(&:guide_item_assessments) == guide_item_assessments` and
  the same for `messages`. **These two are the Composite pattern itself** and are
  the most valuable lines in the group. Assert with `eq`, never `equal?` —
  `def assessments = [self]` allocates a fresh array per call.
- `assessable? == guide_item_assessments.select(&:gate?).all?(&:adherent?)`, and
  `!assessable?` implies `fitness == gate_factor`. The second is literally the
  sentence at `guide_assessment.rb:49-50` that the composite lifts; asserting it
  on both is what stops the two classes disagreeing about what a gate means.
- `adherent?` implies `fitness == 1.0` exactly. Not the converse.
- `fitness` is a Float in `0..1`; `messages` empty when adherent; `assessments`
  non-empty; `assessments.map(&:voice).uniq == [voice]` (the only thing stopping
  a composite from grading its members against different voices).

Do **not** assert `guide_item_assessments` is non-empty: `PermissiveGuide`
(`guide_assessment_spec.rb:119-128`) is a leaf with zero items grading 1.0.
Reachable only through a duck-typed guide, so the invariant is false in general.

Include it from `guide_assessment_spec.rb` for `FuxCantusFirmus` and
`Guide.get("arch_contour_melody")`, and from `composite_assessment_spec.rb` for
`first_species`, each across three voices — adherent, non-adherent,
unassessable.

**Pair it with one reflective example**, in `composite_assessment_spec.rb` only:

```ruby
it "answers the same protocol as a leaf assessment" do
  expect(described_class.public_instance_methods(false))
    .to match_array(HeadMusic::Style::GuideAssessment.public_instance_methods(false))
end
```

The shared group alone cannot catch the stated failure mode — it only runs what
it already knows about, so a method added to one class is invisible to it.
Trade-off accepted: this forbids any asymmetry including a harmless `inspect`
override, and someone will curse it. That pressure is the point; it is what
forces the `gate_factor` and `fitness_by_category` symmetry above rather than
letting it drift. No allowlist constant — an allowlist reintroduces exactly the
drift the spec exists to prevent.

#### Proving the 23 leaves are bit-identical

| Capture | Ref | Rows |
| --- | --- | --- |
| `tmp/before.json` | Step 2's commit — renames landed, composites not yet, script already asking `guide.assess` | 142 × 23 = 3266 |
| `tmp/after.json` | Step 4's commit | 142 × 30 = 4260 |

Because the renames precede both captures, every leaf key joins. The joined
section must print `bin/guide_grade_table.rb:79-84`'s sentence verbatim — **"No
row moved. This change is a provable no-op across the whole corpus."** — over the
3266 joined rows. Any populated "why it moved" tally is a leaf regression. The
994 composite rows have no before column and must be reported separately (see
Step 5).

#### Pinning the unassessable-fitness rule — and the trap in it

**The number is `0.0`, verified.** For `guide_spec.rb`'s 8-note D-dorian ladder
as a solo voice:

| Member | gate factor | fitness |
| --- | --- | --- |
| `FirstSpeciesMelody` | 1.0 | 0.973473 (assessable) |
| `FirstSpeciesHarmony` | **0.0** — `SetAgainstAnotherVoice` returns `Mark.for_all(placements, fitness: 0)` | 0.0 (unassessable) |

Composite: `√(1.0 × 0.0) = 0.0`.

**With the real registry, the decided rule and the rejected alternative are
numerically indistinguishable for every reachable voice.**
`SetAgainstAnotherVoice` scores exactly 0 or 1, never a fraction, and it is the
only gate that differs between a melody member and its harmony partner — the two
share `MinimumNotes.with(3)`. Enumerating: solo with n ≥ 3, both rules give
`√(f × 0) = 0`; n < 3, both members fail the shared gate so each member's
`fitness` *is* its `gate_factor` and the rules agree; n ≥ 3 with a companion,
both assessable and the branch never fires. Measured across n = 0..8, the
composite is `0.0` at every length.

So the story's criterion as written is satisfiable but cannot fail — it would
stay green under the rejected implementation. The decision is still right; it
just needs a spec that can see it. Write both:

- **The literal criterion**, naming `0.0`, asserting `not_to be_assessable`, and
  asserting the premise it depends on — that the two melodies genuinely grade
  differently, both assessable — before asserting the composite number is
  unmoved. Without that premise assertion the example is vacuous twice over.
- **The discriminating case**, in `composite_assessment_spec.rb`, against stub
  members following `GradedStubGuide` (`guide_assessment_spec.rb:12-20`). Give
  member A a *fractional* failed gate (0.25) and member B a passing gate with a
  rubric of 0.5. Decided rule: `√(0.25 × 1.0) = 0.5`. Rejected rule:
  `√(0.25 × 0.5) ≈ 0.354`. This is the only example in the suite that fails if
  the branch is deleted — say so in its comment, so review does not discard it as
  artificial.

#### The hand-computed Fux row

Use `fux_first_species_examples[7]`, "fux chapter one figure 14", reached as
`context.counterpoint_voice` — `CompositionContext.add_voices` always adds cantus
firmus first regardless of hash-key order, so the delegator is the correct
accessor and `voices.first` is not needed.

| | melody | harmony | geometric | arithmetic |
| --- | ---: | ---: | ---: | ---: |
| figure 14 | 1.000000000000 | 0.891254026250 | **0.944062511834** | 0.945627013125 |
| figure 6 (with errors) | 0.986736542386 | 0.945627013125 | 0.965963109709 | 0.966181777756 |

Figure 14 is the better pin: the melody is exactly 1.0, so the composite is
simply `√0.891254026250` and is genuinely hand-computable, and it differs from
the arithmetic mean in the third decimal — so the one example proves both the
value and that it is not the arithmetic mean. Assert `be_within(1e-9)`. Add
figure 6 as a second row where both members are fractional. Note that many
fixtures grade 1.0/1.0 → exactly 1.0, which pins the float-exactness requirement.

The `0.707` criterion needs stub members at 1.0 and 0.5: assert
`be_within(1e-12).of(Math.sqrt(0.5))`. No fixture produces those grades.

#### Registry-sweep examples — three break, four survive

All seven in `guide_spec.rb`, traced against a composite:

| Example | Behavior | Verdict |
| --- | --- | --- |
| "categorizes every guide as melody or harmony" (:100-102) | `[:melody, :harmony, nil]` | **FAILS.** Split: `all.reject(&:composite?)` for the existing claim, plus a new example that a composite's `category` is nil and its `categories` is `%i[melody harmony]` — the claim worth pinning anyway |
| "declares at least one precondition" (:133-135) | Calls `items_by_tier[:gate]` | **Passes only if `CompositeGuide#items_by_tier` exists.** Not in the story's surface list; add it |
| "resolves every configured guide's items at load" (:189-193) | Selects by `reject { is_a?(Class) }`, sweeping composites in | **Passes only with constructor-time resolution.** Makes eager resolution mandatory, not optional |
| "grades an empty voice zero" (:137-144) | `√(0 × 0) = 0.0`, unassessable | Passes |
| "grades rather than raises with no companion" (:148-152) | Both members gate out before any harmonic guideline reaches for a cantus firmus | Passes |
| "never calls an unassessable voice perfect" (:154-160) | 0.0 < 1.0 | Passes |
| "never scores a shorter attempt above a longer one" (:165-172) | All zeros at n = 0..8; sorted trivially | Passes **vacuously**. Comment that the composite's monotonicity is inherited, not tested: a geometric mean of monotone factors is monotone, but this corpus pins one factor at zero |
| "stops at a failed gate" (:174-181) | `solo(0)` — both members fail the shared gate, so both return gates only and `tier.uniq == [:gate]` | Passes, **but it is luck.** At `solo(8)` the melody member is assessable and contributes rubric assessments beside the harmony member's failed gates, giving `[:gate, :primary, :secondary]`. Do not generalize this example to other lengths; comment that a composite stops at the failed gate *per member*, which is the design |

Also `guide_spec.rb:93` and `:246` (23 → 30), `:213-239` (+7 keys, 2 renamed),
and the comment at `:186-188` should name `CompositeGuide` beside `Configured`.

**`base_spec.rb:37-41` breaks too**, and the story did not anticipate it:
`entries.map { |entry| entry.is_a?(Class) ? entry : entry.guide_class }` raises
`NoMethodError` — a `CompositeGuide` is not a `Class` and has no `guide_class`.
Replace with a recursive unwrap: a composite contributes its members' classes, a
`Configured` its `guide_class`, a class itself. `base_spec.rb:8-18` (16 melodic /
7 harmonic) is *unaffected* — composites have `category == nil` and fall out of
both selections, so the counts stay correct. Do not "helpfully" update them.

`guide_strings_spec.rb:80` (23 → 30) and its :38 comment;
`guide_item_strings_spec.rb` needs no count change, since a composite's items are
its members' own `GuideItem` objects and the sweep already `uniq`s.

#### New spec files

- `spec/head_music/style/composite_assessment_spec.rb` — the shared group, the
  reflective protocol example, the three fixture numbers, `fitness_by_category`,
  `assessments`, `messages` in member order, the stub discrimination case, and
  `CompositeAssessment.new(leaf, voice)` raising.
- `spec/head_music/style/guides/composite_guide_spec.rb` — all seven keys
  resolving to the right members, `composite?`, `category`/`categories`,
  `guide_items` deduped (26, not 27), value equality and `hash`, the keyless
  fallback, and the nesting refusal.
- `spec/support/shared_examples_for_assessments.rb`.
- Changed: `guide_assessment_spec.rb` gains `assessments == [self]`, public
  `gate_factor`, the composite refusal naming `assess`, and the shared group;
  `guides/configured_spec.rb` gains one-line `composite?` and `categories`
  examples.

### Step 5 — The after capture and the grades doc

`bin/guide_grade_table.rb` must be edited — its header explicitly sanctions
post-capture edits, since editing it cannot influence either column — for two
things:

1. **Rows with no prior.** Split `after` into joined rows and new rows instead of
   letting `indexed.fetch` raise for the 994 composite rows. Report them in the
   section header: "994 of 4260 rows are new registry entries and have no before
   column; of the 3266 that joined, N moved."
2. **The composite-beside-its-members table** the story asks for, which is a
   shape this script does not currently produce — it only emits before/after
   joins. Derive membership from the data rather than a hardcoded list: key `K`
   is a composite iff `"#{K}_melody"` and `"#{K}_harmony"` also appear as guide
   keys. Emit `| corpus | notes | composite | melody | harmony | √(m·h) | assessable |`.

Build that table from `fux_first_species_examples` and
`clendinning_first_species_examples`. Every solo entry and every cantus-firmus
fixture is a single-voice composition, so its composite row is `0.0` by
construction and carries no information.

**Answering the story's own question — "Confirm the `failed_gates` column reads
correctly for a composite."** It does not. Verified: for `first_species` at
n = 0, 1, and 2 the column reads
`["MinimumNotes", "MinimumNotes", "SetAgainstAnotherVoice"]`, because both
members declare `MinimumNotes.with(3)` and each assesses it independently. Dedupe
in the script's column, not in the model: `guide_item_assessments` must stay the
members' flat concatenation or the shared example group's strongest invariant
(`assessments.flat_map(&:guide_item_assessments) == guide_item_assessments`)
breaks. This is the same asymmetry as `guide_items` being 26 while a fully-graded
composite has 27 assessments — say so in the class comment.

Finally: CHANGELOG `[Unreleased]` gains an Added block (the two types, seven
keys, `assessments`, public `gate_factor`, `categories`) and a Breaking block
(the four renames, the two published-key changes, the `GuideAssessment.new`
guard).

While the epic file is open: story 3 is **already done** — it lives at
`user-stories/done/guideline-strings-into-i18n.md` — but
`user-stories/epics/style-assessment-model.md:366` still shows it unchecked and
links `../current/`. Fix that; it removes the apparent dependency conflict over
`en.yml` entirely.

### Migration and consumer notes

Beyond what 19.0.0 → `main` already breaks for BardTheory (`Analysis` →
`GuideAssessment`, `annotations`, `analyze`), this story breaks exactly one more
thing: the two renamed registry keys in `GUIDE_KEYS_BY_SPECIES`, which reach
`Guide.get!` in a class body at `counterpoint_analysis_service.rb:20` — a
`KeyError` at boot, loud rather than silent. `melodic_analysis_service.rb`'s
contour keys are untouched.

One silent change for any consumer: `Guide.all` grows 23 → 30, so code grouping
the registry by `category` gains a `nil` bucket. That is what `categories` exists
to answer.

**No version bump in this story.** `lib/head_music/version.rb` is still `19.0.0`
and the CHANGELOG shows every breaking change from this epic sitting under
`## [Unreleased]` — the repo accumulates and bumps at release. Bumping here would
either burn 20.0.0 mid-epic or force a second bump, and the migration note
consumers need lists all five stories at once. Once released,
`StyleAnalysisService#combined_fitness` deletes entirely and the seven-row pair
table collapses to seven single keys.

### Risks and open questions

- **The unassessable-fitness rule is unfalsifiable through the registry.** Its
  only real test is the stub-member example. If review discards that as
  artificial, the story's load-bearing decision ships untested.
- **`bin/guide_grade_table.rb:34`'s `fetch` is unconditional.** If the
  before-capture is taken before Step 1, or the Step 5 edit is skipped, doc
  generation dies with a bare `KeyError` naming a corpus label — a failure that
  looks like a corpus bug and is a sequencing bug.
- **`CompositeGuide#key` reverse-looks-up a constant that does not exist during
  construction.** Anything the constructor touches must avoid `key`. Getting this
  wrong fails at `require`, taking every spec with it.
- **Does `fitness_by_category` follow `fitness` into the gate-factor branch?**
  The story specifies it only for the assessable case. Assume yes — showing a
  consumer "melody 1.00 / harmony 0.00 / total 0.00" must not present three
  numbers that do not multiply out — but the alternative is defensible.
- **`CompositeGuide#instruction` for an unregistered composite.** Proposed: the
  members' instructions joined, mirroring `configured.rb:52-55`. Passing the key
  into the constructor would remove the branch but let an ad-hoc composite claim
  a key resolving elsewhere — what `configured.rb:37-38` refuses. If the key is
  passed in, it must join `==` and `hash`, since `key_for` is
  `REGISTRY.key(guide)` and compares by `==`.
- **Rubycritic duplication.** `CompositeAssessment` and `GuideAssessment` will
  share `messages`, `adherent?`, and constructor shape. Resist extracting a base
  class — the two grade by different arithmetic on purpose, and the shared
  example group is the intended guard.
- **The acceptance criterion at "A solo voice submitted to `first_species`…" is
  satisfiable only vacuously.** It should either name `0.0` explicitly and add
  the premise assertions above, or be restated against stub members with a
  fractional gate. This does not change the decision — only the criterion's
  wording.
- Performance, for context rather than concern: the `guide_spec.rb`
  assessability block roughly doubles, and the corpus capture goes 3266 → 4260
  rows, ~32s → ~45s.
