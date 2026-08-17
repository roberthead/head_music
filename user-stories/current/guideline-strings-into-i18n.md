<!--
metadata:
  created_at:   2026-08-16T00:00:00-07:00
  activated_at: 2026-08-17T12:07:58-07:00
  planned_at:   2026-08-17T12:34:26-07:00
  finished_at:
  updated_at:   2026-08-17T16:41:12-07:00
-->

# Guideline Strings into I18n

AS an application presenting a guide to a student

I WANT every customer-facing string to be a translatable template populated from the guide item's configuration

SO THAT a guide can be read in the student's language, and "at least eight notes" is one template rather than one Ruby string per threshold

Story 3 of the [Style Assessment Model](../epics/style-assessment-model.md).
Depends on story 2: every template is populated from a `GuideItem`'s config, and
there is no `GuideItem` before then. Independent of story 4.

## Background

Customer-facing English is currently scattered across the style layer in four
different shapes:

| Shape | Count | Example |
| --- | --- | --- |
| A `MESSAGE` constant | 45 guidelines | `ConsonantClimax::MESSAGE` |
| A `#message` override interpolating config | 9 guidelines | `"Write at least #{minimum.humanize} notes."` |
| Neither — inherited or abstract | 9 guidelines | `MinimumThreshold`, `FourPerBar` |
| **A literal English string in a guide file** | 1 | `fux_cantus_firmus.rb:16` |

That last one is the tell. `SingableIntervals` and `LargeLeaps` both accept a
`message:` configuration option, and `FuxCantusFirmus` uses it:

```ruby
HeadMusic::Style::Guidelines::LargeLeaps.with(
  ...,
  message: "Recover large leaps by step in the opposite direction.",
)
```

A guide overriding a guideline's default violation text is exactly right as a
concept — and it is currently done by passing an English sentence through the
config hash into a Ruby string. The gem already ships seven locale files and a
`Named` mixin for internationalization; the style layer is the one part that
opted out.

There is no `name` or `instruction` anywhere. `Guide.display_name_for` derives a
display name from the guide key, and guidelines have nothing at all — a consumer
that wants to *show* a rubric has only the violation message, which is phrased
for a voice that got it wrong.

## Scope

Three keys, one renderer, and forty-five constants into a locale file.

### Templates, populated from `config`

All three keys name templates, and all three interpolate the `GuideItem`'s
config. A guideline's name is no more fixed than its violation: `MinimumNotes` is
"minimum of eight notes" in one guide and "minimum of three" in another.

```yaml
head_music:
  style:
    guides:
      first_species_melody:
        name: "First Species Melody"
        instruction: "Write a melody in first species."
    guidelines:
      minimum_notes:
        name: "Minimum of %{minimum} notes"
        instruction: "Write at least %{minimum} notes."
        violations:
          too_few: "Write at least %{minimum} notes."
      consonant_climax:
        name: "Consonant climax"
        instruction: "Peak on a consonant high or low note one time or twice with a step between."
        violations:
          default: "Peak on a consonant high or low note one time or twice with a step between."
```

`name_key` and `instruction_key` derive from the class key by convention, the way
`Guide.display_name_for` already derives display names. A guideline declares one
only to override.

### Rendering, in one place

```ruby
class HeadMusic::Style::GuideItem
  def name        = render(guideline.name_key)
  def instruction = render(guideline.instruction_key)

  private

  def render(key, **extra) = I18n.t(key, **interpolations.merge(extra))

  # Numbers humanize so "at least eight notes" survives; the humanize gem takes
  # a locale, so it survives translation too.
  def interpolations
    config.transform_values { |value| value.is_a?(Integer) ? value.humanize : value }
  end
end
```

`GuideItemAssessment#message` is the same call with `violation_key` and
`violation_values` merged over the item's interpolations.

### `violation_key` replaces `MESSAGE`

The 45 static constants become `violations.default` entries. The 9 dynamic
overrides become templates:

| Guideline | Today | Template |
| --- | --- | --- |
| `MinimumNotes` | `"Write at least #{minimum.humanize} notes."` | `"Write at least %{minimum} notes."` |
| `MinimumMelodicIntervals` | `"Write at least #{minimum.humanize} melodic intervals."` | `"Write at least %{minimum} melodic intervals."` |
| `MaximumNotes` | `"Write up to #{maximum.humanize} notes."` | `"Write up to %{maximum} notes."` |
| `Contoured` | `"Write a melody with the #{contour} contour."` | `"Write a melody with the %{contour} contour."` |
| `NoteCountPerBar` | ternary on `note`/`notes` | I18n pluralization on `count` |
| `LimitOctaveLeaps` | ternary on `leap`/`leaps` | I18n pluralization on `count` |
| `SingableIntervals` | `config[:message] \|\| "Use only …"` | `violation_key:` config, defaulting |
| `LargeLeaps` | `config.fetch(:message)` | `violation_key:` config, defaulting |
| `SingableRange` | `"Limit melodic range to #{indefinite_article} #{maximum_range.ordinalize}."` | `"Limit melodic range to %{range}."`, `range` a localized noun phrase |

**The two `message:` options become `violation_key:` options,** and the English
sentence in `fux_cantus_firmus.rb:16` becomes a locale entry that the guide names
by key. This is the mechanism the epic wants — a guide overriding a guideline's
default violation — with the string in the place strings belong.

**Pluralization is an upgrade, not a translation.** `"#{count} #{(count == 1) ? "note" : "notes"}"` is a
correct English rule and a wrong rule in most other languages. I18n's `count:`
pluralization is locale-correct, so `NoteCountPerBar` and `LimitOctaveLeaps` get
`one:`/`other:` keys and become translatable rather than merely translated.

It also fixes English that is wrong today. `MinimumMelodicIntervals` renders
"Write at least one melodic interval**s**" for a minimum of one, because it
interpolates a humanized number into a hard-coded plural. Guidelines that
already read correctly should keep their wording; guidelines that do not should
be fixed here rather than faithfully reproduced and left for later.

### Guides get names and instructions

`Guide.display_name_for`'s flat key → string map becomes nested under `name:`,
which is a one-line change to its single entry
(`salzer_schachter_cantus_firmus`). Guides gain `instruction`.

Guide templates take an **empty** interpolation set. `ContourMelody.with(contour: :arch)`
reaches the registry under its own key (`arch_contour_melody`), so its name is a
plain string, not a template over the guide's options.

### English only

English is the default and the fallback. The other six locale files
(`de`, `en_GB`, `es`, `fr`, `it`, `ru`) get no style entries and fall back until
someone translates them. `en_GB` may want a handful of entries; that is a
judgment call at implementation time, not a requirement here.

## Acceptance Criteria

- No customer-facing English string remains in `lib/head_music/style/`, in a
  constant, a method, or a guide's configuration.
- Every guideline answers `name_key`, `instruction_key`, and a default
  `violation_key`, derived by convention unless overridden.
- `GuideItem#name` and `#instruction` render from `config`; integers humanize.
- `GuideItemAssessment#message` renders `violation_key` with
  `violation_values` merged over the item's interpolations, and is `nil` when
  adherent.
- English improves where the move makes it easy, and every change is
  deliberate. Identical output is **not** the bar: this story is infrastructure,
  and taking the gains it puts within reach is part of the point. In particular
  `MinimumMelodicIntervals` renders "Write at least one melodic interval**s**"
  today, and I18n pluralization fixes it rather than faithfully reproducing it.
- Every English string that *does* change is listed, with the old and new text,
  so the change is a decision rather than a side effect.
- `I18n.locale = :de` produces English for every style string, via fallback, and
  raises nothing.
- A template naming a key absent from `config` is caught at load, not at render.
- `bundle exec rubocop` is clean and coverage stays above 90%.

## Scenarios

### Scenario: A static message becomes a locale entry

Given `Guidelines::ConsonantClimax`, which has a `MESSAGE` constant today

When a voice violates it

Then the assessment's `message` is the same sentence, now read from `en.yml`

And `ConsonantClimax::MESSAGE` no longer exists

### Scenario: A template is populated from the item's config

Given one guide declaring `MinimumNotes.with(8)` and another declaring `MinimumNotes.with(3)`

When I read each item's `name` and `instruction`

Then one reads "eight" and the other "three", from a single template

### Scenario: A guide overrides a guideline's violation by key

Given `FuxCantusFirmus`, which today passes a literal English sentence as `message:`

When it declares `LargeLeaps.with(..., violation_key: "…large_leaps.violations.fux")`

Then the assessment renders that entry, and no English appears in the guide file

### Scenario: Pluralization follows the locale

Given `OnePerBar` and `FourPerBar`

When each produces a violation

Then one reads "note" and the other "notes", from `one:` and `other:` keys rather than a Ruby ternary

### Scenario: An unpopulated template fails loudly at load

Given a guideline whose instruction template names `%{minimum}`

When a guide declares it with no `minimum` in config

Then loading the guide raises, naming the guideline and the missing key

### Scenario: A missing translation falls back to English

Given `I18n.locale = :fr`

When I read any guide item's name, instruction, or message

Then I receive the English string, and nothing raises

## Design notes

**Why the violation lives on the assessment and the name and instruction live on
the item.** Which violation fired is decided during analysis and may vary — this
story does not add a second violation to any guideline, but the shape allows it,
so `ConsonantClimax` can later distinguish a dissonant climax from a repeated
one. Name and instruction are properties of the item, known before any voice
exists, and a consumer building a lesson needs them without running an analysis.

**Gates are not instructions.** A gate's instruction renders "Write at least
three notes," which is a precondition rather than the lesson. Consumers should
read `primary_items` as the lesson and `secondary_items` as background; the three
lists make that a one-line choice. Nothing in this story needs to enforce it.

**`violation_key` defaults to `violations.default`,** so 45 of the 63 guidelines
declare nothing at all and the convention carries them.

**`SingableRange`'s indefinite article moves into the locale.**
`"Limit melodic range to #{indefinite_article} #{maximum_range.ordinalize}."`
computes "a" or "an" in Ruby — English grammar that no other locale wants and
that an interpolation cannot express. The article belongs to the *noun*, not the
sentence, so the interpolated value becomes a localized noun phrase:

```yaml
singable_range:
  violations:
    default: "Limit melodic range to %{range}."
  ranges:
    octave: "an octave"
    tenth: "a tenth"
    twelfth: "a twelfth"
```

English carries its articles, and a locale needing declension, gender agreement,
or no article at all writes what its grammar requires. Only the ranges actually
configured need entries; anything else falls back to the bare ordinal. This keeps
grammar in locale files, changes no user-visible English, and stays contained —
no cross-cutting work on interval naming, which has its own `article` handling in
`Analysis::DiatonicInterval::Naming` for a different purpose.

## Open questions

- **`en_GB`.** It exists and currently carries spelling differences elsewhere in
  the gem. Whether any style string needs a British variant is worth one pass at
  implementation time.

## Implementation Plan

Nine commits. The story's stated mechanism does not work, so the plan's central
change is that the interpolation set is a class-level `template_values(config)`
rather than `config` itself.

### ⚠️ The correction that reshapes the story

**`I18n.t(key, **config)` fails silently for seven of the sixty-seven distinct
guide items.** Those seven declare `config == {}` and read their message values
from class constants instead:

| Item | reads from |
| --- | --- |
| `OnePerBar`, `TwoPerBar`, `ThreePerBar`, `FourPerBar` | `COUNT` / `RHYTHMIC_VALUE` |
| `LimitOctaveLeaps` | `MAXIMUM_LEAPS` |
| `SingableRange` | `MAXIMUM_RANGE` |
| `SingableIntervals` (unconfigured) | `DEFAULTS` |

Verified: `I18n.t(key, raise: true)` with **no** interpolation arguments returns
the raw template with `%{}` intact and does not raise, while supplying a partial
set *does* raise. So `LargeLeaps` would fail loudly in development and
`OnePerBar` would ship `"Use %{number} %{rhythmic_unit} notes in each middle
bar."` to a student with a green suite.

Three further silent modes, all verified:

```
I18n.t(:vp, raise: true)          => "Use %{number} %{unit} notes."   # empty hash, no raise
I18n.t(:vq, n: "one")             => Hash {one:…, other:…}            # plural key, no count:
I18n.t(:vr, default: "d")         => "d"                              # RESERVED_KEYS hijack
I18n.t("…missing")                => "Translation missing: en.…"      # not a raise
```

Every check must assert `String` **and** the absence of `%{`, never a rescued
exception, and every render passes `raise: true`.

### Steps

**1. Pin the current strings before anything moves** *(green, additive, first)*

`bin/guide_item_strings.rb` emits one row per distinct `(guideline, config)` —
67 of them — and runs unmodified at the merge-base; the discriminator is
`item.respond_to?(:instruction)`, false before and true after. `#name` cannot
discriminate: it already exists. Plus a spec pinning all 67 messages as a
literal table, committed **before** any lib change, so the Changed list is a
measurement rather than a description of the diff.

**2. `Style::Template` and the `Guideline` class-method surface** *(green, additive)*

`render`, `number_word`, `humanize_locale`, `verify!`; `Guideline.template_key`,
`.name_key`, `.instruction_key`, `.violation_scope`, `.template_values`,
`.pluralize_by`, `.violation_value_keys`. `template_values(config)` defaults to
`config.except(:violation_key)`; five guidelines override it.

**3. The 46 `MESSAGE` constants into `en.yml`** *(green, mechanical, largest diff)*

`instruction_key` defaults to `violation_key`: all 46 constants are already
phrased imperatively ("Peak on…", "Use only…", "Avoid…"), which halves the
new-prose bill.

**4. The nine dynamic templates** *(⚠️ riskiest — the whole design lands here)*

`template_values` on five guidelines, `pluralize_by` on six,
`template_key :note_count_per_bar` on the four `*_per_bar` classes so one
template renders four distinct names. Deletes `VOWEL_SOUND_ORDINALS` and
`#indefinite_article`, the English inside `#describe_shorthand`, and
`DEFAULTS[:message]` in both configurable guidelines. Riskiest because every
interpolation name, plural selector and reserved-key decision is exercised at
once — and step 1's spec goes red on exactly two rows, **which are the
deliverable**.

**5. `violation_key` / `violation_values` replace `message` on the seam** *(green)*

`Guideline.assess` passes both and strips `:violation_key` from the analyzer's
options. `fux_cantus_firmus.rb:23`'s `message:` becomes `violation_key:`.
`ConsonantClimax` gains its second and third violation here.

**6. `GuideItem#name` and `#instruction`** *(green)*

`#name` becomes the rendered string; `inspect`/`to_s` become a config signature
— strictly better than today, which prints `OnePerBar, OnePerBar` with no way to
tell two configurations apart. `guides/base.rb:133` moves to `map(&:inspect)` so
a declaration-time error never renders a template. Derived guideline names are
sentence case, not `display_name_for`'s title case.

**7. Guides get names and instructions** *(green)* — `en.yml`'s flat
`salzer_schachter_cantus_firmus:` nests under `name:`. 23 instructions are the
only wholly new prose in the story.

**8. Load-time verification and property specs** *(green)*

`Template.verify!` beside the registry warm-up, wrapped in
`I18n.with_locale(:en)` so a host application's locale cannot make load
nondeterministic. Measured at ~0.8 ms against a 96.5 ms require. Property spec
over 67 items × 3 templates × 8 locales — non-empty `String`, no `%{`, no raise.

**9. `en_GB`, evidence, docs** *(green)* — four `en_GB` entries, the regenerated
strings table, `CHANGELOG.md`, and `references/fourth-species-counterpoint.md`,
which still teaches `MESSAGE = "Description of the rule."`

### Design decisions

**Keep `config` as the equality key; do not expand it.** `spec_helper.rb:39`
builds `an_object_having_attributes(config: config)` — an exact hash match used
at 16 sites — and expanding config would also change `hash`, which
`reject_duplicates` depends on. `template_values` leaves both byte-identical.

**`violation_key:` stays inside `config`.** Two items differing only in rendered
violation genuinely are two items. Guarded twice: excluded from
`template_values`, and stripped before the analyzer. A load-check guards against
`I18n::RESERVED_KEYS + [:count]` — `separator`, `format` and `default` are all
plausible future guideline options and each would silently hijack the call.

**Humanizing follows the fallback chain, never `I18n.locale` directly.**
`8.humanize(locale: :it)` and `(locale: :en_GB)` both raise `RuntimeError` — the
gem ships neither, and both are shipped locales here. Resolve to the first
locale in `I18n.fallbacks[locale]` that humanize knows.

**`count:` is the raw Integer; the spoken word gets its own name.** I18n reserves
`count` as both selector and value, and `I18n.t(key, count: "one")` silently
selects `:other` — "one whole note**s**". No template value may be called
`count`.

### English that changes — deliberately

| Guideline | Old | New |
| --- | --- | --- |
| `MinimumMelodicIntervals(1)` | Write at least one melodic interval**s**. | Write at least one melodic interval. |
| `SingableRange` | Limit melodic range to a 10th. | Limit melodic range to a tenth. |
| `ConsonantClimax` (dissonant) | Peak on a consonant high or low note one time or twice with a step between. | Peak on a note that is consonant with the tonic. |
| `ConsonantClimax` (repeated) | *(the same sentence)* | Peak once, or twice with a step between. |

The `MinimumMelodicIntervals` defect ships live in `ascending_contour_melody` and
`descending_contour_melody` — verified. The sweep found two latent instances of
the same bug: `minimum_notes.rb:11` and `maximum_notes.rb:15` are both wrong at
count 1, and `MinimumNotes.with(1)` is a legal call. `note_count_per_bar` and
`limit_octave_leaps` ternary correctly at every integer; they move to
`one:`/`other:` for translatability, not for correctness.

**`SingableRange` keys by the integer**, since `maximum_range` is never
configured. **No `ordinalize` fallback** — the story's "falls back to the bare
ordinal" would leave untranslatable English in Ruby forever; a missing entry
should raise at load, which is what the criteria want.

**`ConsonantClimax` splits — recommended on merits.** It already decomposes into
the two conjuncts a consumer wants distinguished, so the split is ~15 lines and
two sentences. The seam has to be built regardless, so omitting it leaves the
mechanism unexercised and unfalsifiable. One fixture moves —
"Fux C with dissonant climax" gets the dissonant-specific text, which its own
name says it is testing. The split must branch on `descending_melody?` first.

### Strings the story never counted

- `singable_intervals.rb:43` builds `"m6 (ascending)"` — English inside a
  computation. Needs `directions:` keys plus a `list_separator`.
- `note_count_per_bar.rb:15` interpolates `:whole`/`:quarter`; `contoured.rb:34`
  interpolates `:arch`/`:wave`. Symbols in a constant, English on the screen, and
  permanently untranslatable even after someone translates the sentence. Do not
  reuse `head_music.rudiments`, which is a flat map of *type* names and whose
  `RhythmicUnit#name` returns `"whole"` under `:de` anyway.
- `large_leaps.rb:19` `DEFAULTS[:message]` is a lowercase hash value, so it is in
  neither the 46 constants nor the one guide-file literal.

Developer-facing `ArgumentError` text is out of scope — raised at declaration
time, never seen by a student. Worth saying so explicitly.

### Testing strategy

The pinned table of 67 strings is the regression net. The property spec over the
whole registry catches the `en_GB` plural landmine and covers the nine
guidelines no fixture ever violates — story 4's learning was that property specs
outlive captured artifacts. `bin/guide_grade_corpus.rb` runs unmodified as a
zero-cost confirmation that no fitness moved; do **not** extend it, since its
`message_count` is invariant here. The 19 `expected_message:` fixtures need
exactly **two** changes. Watch `maximum_coverage_drop` after step 3, not at the
end — deleting 46 covered constant lines moves coverage in both directions.

### Commit granularity

One per step, with three constraints. Step 1 is its own commit and comes first;
story 2's oracle expired with its session and this is the fix for that. **Do not
merge steps 3 and 4** — 46 mechanical deletions a reviewer skims would swallow
nine designed templates a reviewer must read one at a time. **Do not split step
4**: splitting by guideline leaves intermediates where the interpolation
contract is half-defined, each passing `git bisect` while shipping `%{}`.

### Decisions taken

**`en_GB` stays mid-chain.** It is closer to international English than `en_US`
is, so German, French, Italian and Russian readers falling through it is the
right default rather than a hazard. The four British spellings are a CHANGELOG
line, not a problem to design around.

**Pluralization falls back to Ruby when the locale data cannot answer.** Rather
than letting a missing or partial plural hash raise, `Template` rescues
`I18n::InvalidPluralizationData` and a missing translation and pluralizes in
Ruby — `String#pluralize` is available. This defuses both landmines at once: the
partial-`en_GB`-hash trap, and the day someone writes correct Russian `few:`/
`many:` without `I18n::Backend::Pluralization` included. A wrong plural in a
language the gem has no rule for is a better outcome than an exception in a
student's face.

The fallback must be visible, not silent: log nothing, but have the load-time
`verify!` report which keys fell through to Ruby, so missing plural data is a
known gap rather than an invisible one.

**The 23 guide instructions are drafted here** rather than shipped as nil. A
first draft that a musician can correct beats an empty method, and the
alternative is dead code sitting under a coverage-drop guard. Succinct — one
imperative sentence each, saying what to write, not how it is graded:

| Guide | Instruction |
| --- | --- |
| `fux_cantus_firmus` | Write a cantus firmus: a singable line of eight to fourteen whole notes that begins and ends on the tonic. |
| `salzer_schachter_cantus_firmus` | Write a cantus firmus with a single clear climax and stepwise motion away from every leap. |
| `diatonic_melody` | Write a singable diatonic melody that stays in one key. |
| `first_species_melody` | Write one whole note against each note of the cantus firmus. |
| `first_species_harmony` | Set your line against the cantus firmus in consonances, moving mostly in contrary motion. |
| `second_species_melody` | Write two half notes in each bar against the cantus firmus. |
| `second_species_harmony` | Place a consonance on each downbeat, and pass through dissonance only by step on the weak beat. |
| `third_species_melody` | Write four quarter notes in each bar against the cantus firmus. |
| `third_species_harmony` | Keep the downbeats consonant, and treat the quarter-note dissonances as passing or neighbour tones. |
| `third_species_triple_meter_melody` | Write three quarter notes in each bar against the cantus firmus. |
| `third_species_triple_meter_harmony` | Keep the downbeats consonant in triple meter, and resolve every dissonance by step. |
| `fourth_species_melody` | Tie each note across the barline, suspending it into the next bar. |
| `fourth_species_harmony` | Prepare each suspension as a consonance and resolve it downward by step. |
| `combined_first_second_third_species_melody` | Combine whole, half and quarter notes in one line, changing rhythm between phrases. |
| `combined_first_second_third_species_harmony` | Set a mixed-rhythm line against the cantus firmus, keeping each downbeat consonant. |
| `fifth_species_melody` | Write florid counterpoint: mix note values and ties as the line requires. |
| `fifth_species_harmony` | Write florid counterpoint against the cantus firmus, treating every dissonance as its figure demands. |
| `arch_contour_melody` | Write a melody that rises to a single peak and falls back. |
| `ascending_contour_melody` | Write a melody that begins at its lowest note and ends at its highest. |
| `descending_contour_melody` | Write a melody that begins at its highest note and ends at its lowest. |
| `static_contour_melody` | Write a melody that stays within a narrow range and returns to where it began. |
| `valley_contour_melody` | Write a melody that falls to a single low point and rises back. |
| `wave_contour_melody` | Write a melody that changes direction three or more times. |

These are a draft by a non-musician and should be read as such. The rhythmic
ones restate what each species *is*, which is the part a student needs before
the rubric means anything; the contour ones restate the shape. Anything wrong
here is cheap to fix once it is in a locale file.

### Open questions

1. ~~The `en_GB` mid-chain question.~~ **Decided: it stays.**
2. ~~Write the guide instructions or ship nil?~~ **Decided: drafted above.**
3. **`DirectionChanges` and `EndOnPerfectConsonance` carry `MESSAGE` constants
   and appear in no registry entry** — their locale entries can never be
   exercised by the property spec. Two guidelines are dead code. Worth a line in
   the story; deleting them is a separate decision.
4. ~~`I18n::Backend::Pluralization` is not included.~~ **Decided: the Ruby
   fallback covers it**, so the missing backend is no longer a latent failure.
   Including it properly is still a reasonable follow-up.

### Landmines

- **`en_GB` sits mid-chain.** `de`, `fr`, `it` and `ru` all route through it
  before `en`. A partial plural hash there yields `I18n::InvalidPluralizationData`
  — the fallback does not continue past a present-but-incomplete hash. Any
  pluralized `en_GB` entry must carry the full set, pinned by spec rather than
  by discipline.
- **Version is 20.0.0, not 21.0.** `version.rb` is still `19.0.0` and stories 1,
  2 and 4 are all unreleased in `[Unreleased]`. This story joins that block.

### Note on the planning itself

Two specialists contradicted each other on `en_GB` and the one that had actually
checked was right: a word-frequency scan reported "zero divergences" and missed
`neighbor` in three files. The second time in this epic that a plausible scan
lost to checking.

The best-practices review had not returned when the plan was assembled, so the
design-critique axis — whether rendering duplicated across two frozen value
objects wants extraction, and whether `GuideItem` reaching into a guideline's
class constants is a Demeter problem — is covered only indirectly.

## Review

Reviewed 2026-08-17 at `dc82b79`, against the merge-base `e3f0b3f`. Working tree
clean; everything committed. `bundle exec rake`: 6578 examples, 0 failures, line
coverage 99.60%, branch 96.97%. `bundle exec rubocop`: 500 files, no offenses.

Two reviewers worked independently and converged on the same three defects, each
reproduced by execution rather than inference.

### Acceptance criteria

| # | Criterion | Verdict |
| --- | --- | --- |
| 1 | No customer-facing English in `lib/head_music/style/` | ⚠️ mostly — see below |
| 2 | Every guideline answers `name_key`, `instruction_key`, `violation_key` | ✅ all 63 subclasses |
| 3 | `GuideItem#name`/`#instruction` render from config; integers humanize | ✅ |
| 4 | `GuideItemAssessment#message` renders, `nil` when adherent | ✅ 0 adherent items with a message, 0 violating items without |
| 5 | English improves where the move makes it easy | ✅ |
| 6 | Every changed English string is listed, old and new | ✅ measured, exactly the four planned |
| 7 | `I18n.locale = :de` produces English, raises nothing | ❌ at review → ✅ fixed |
| 8 | A template naming an absent key is caught at load | ⚠️ at review → ✅ fixed |
| 9 | Rubocop clean, coverage above 90% | ✅ |

**Criterion 6 is the best-evidenced thing in the branch.** `bin/guide_item_strings.rb`
ran unmodified in a worktree at the merge-base and at HEAD — 67 rows each side —
and the diff is exactly the planned four sentences and nothing else.
`bin/guide_grade_corpus.rb` returned 3266 identical rows at both revisions,
confirming the CHANGELOG's claim that the string move did not touch grading.

**Criterion 1's remainder.** Every string the plan flagged as uncounted was
fixed: `singable_intervals.rb`'s `"m6 (ascending)"`, `note_count_per_bar.rb`'s
`:whole`/`:quarter`, `contoured.rb`'s `:arch`/`:wave`, `large_leaps.rb`'s
`DEFAULTS[:message]`, and `SingableRange`'s indefinite article. Zero `MESSAGE`
constants survive. Two things remain, both introduced by the move rather than
missed by it: five `violation_singular` methods returning bare English nouns
(`"note"`, `"octave leap"`, `"melodic interval"`), and `guideline.rb:63`, which
generates a name in Ruby from the class key when no `name:` entry exists — which
is most guidelines. `"Allowed rhythmic values for combined123"` is a class name
on a student's screen, and it reads identically under every locale.

### Findings, most severe first

**1. Load-time verification is inert for exactly the templates most likely to be
wrong.** `template.rb:69-74` rescues `MissingTemplate`, but `render` raises
`MissingTemplate` for *every* failure it detects — including the surviving `%{}`
that is the whole point of the check (`template.rb:32`). So a bogus interpolation
in a pluralized template falls through to the Ruby plural path and the sentence
silently disappears. Reproduced in-process:

```
non-pluralized bogus key: RAISED MissingTemplate      # verify! works
pluralized bogus key    : LOADED CLEAN                # verify! blind
what the student reads  : "three notes"               # sentence gone
```

`verify!` protects 50 guidelines and is blind for the 6 pluralized ones. The
rescue should name `I18n::InvalidPluralizationData` and missing-translation
specifically; an unfilled interpolation must keep propagating.

**2. Non-English locales get mixed-language output.** `Template.number_word`
(`template.rb:50`) humanizes into `I18n.locale` while the sentence falls back to
`en`, so the two halves resolve in different languages:

```
de: "Minimum of Drei notes"   | "Write at least Drei notes."
fr: "Minimum of trois notes"  | "Write at least trois notes."
ru: "Minimum of три notes"    | "Write at least три notes."
fr: "Use un whole note in each middle bar."
```

This is criterion 7 outright. Nothing raises — 8384 renders across 8 locales,
0 failures — but "Write at least Acht notes." is worse than either pure option,
and the German capitalization reads as a typo. `guide_strings_spec.rb`'s property
check is structurally blind to it: it asserts String, non-empty, no `%{}`, never
*in the expected language*. The fix is one line — resolve the humanize locale
against the locale the template resolved in, not the requested one.

**3. `GuideItemAssessment#message` bypasses the plural fallback.** Every other
render routes through `Guideline.render_template` (`guideline.rb:81-85`), which
sends `:count` to `Template.pluralize`. The assessment — the one path a student
actually reads — calls `Template.render` directly (`guide_item_assessment.rb:41`),
so it has no fallback and `InvalidPluralizationData` is not in `render`'s rescue
list. Reproduced with the partial `en_GB` plural hash the plan names as its
landmine:

```
GuideItem#violation_preview  => "eight notes"                  # fallback worked
GuideItemAssessment#message  => RAISED InvalidPluralizationData
```

The protected path is the preview; the unprotected one is the student's. Latent
today because no locale ships plural data, and `guide_strings_spec.rb:65` guards
against introducing one — but the runtime net the plan designed does not cover
the primary path. This is also the concrete answer to the plan's open design
question about rendering duplicated across two value objects: the duplication has
already diverged into different behavior. Delegating to `render_template` closes
it in one line.

**4. The Ruby plural fallback drops the sentence.** `template.rb:73` returns
`"#{number_word(count)} #{singular}"` — a bare noun phrase, not the sentence. The
plan promised "a wrong plural is better than an exception"; what it delivers is a
missing sentence, which is arguably worse than either.

**5. `warn_about_ruby_plurals` is a no-op.** `template.rb:102-106` computes
`fell_back_to_ruby.uniq` and returns it to `verify!`, which discards the value
(`guide.rb:113`). The plan's "the fallback must be visible, not silent" is not
implemented. The project's no-stdout rule means `warn` is not the answer either,
so this may want to be an accessor the suite asserts on — but then the method
should not be named for warning. Related: `fell_back_to_ruby` is unbounded
module-level state, never cleared; one `verify!` pass over a locale missing
plural data appended 64 entries.

**6. The removed `message:` option fails silently.** Both `LargeLeaps` and
`SingableIntervals` documented `message:` as public config. It is now
unrecognized but not rejected — it lands in `config`, flows through as an unused
interpolation, and a downstream consumer's custom sentence vanishes with no
error. The CHANGELOG describes `violation_key:` as an addition but never says
`message:` was removed.

**7. `GuideItemAssessment#name` still returns the Ruby class path.**
`guide_item_assessment.rb:56-59` returns `guideline.name` →
`"HeadMusic::Style::Guidelines::MinimumNotes"`, aliased to `to_s`, while
`assessment.guide_item.name` returns `"Minimum of three notes"`. Untouched by the
diff, so pre-existing — but the story's purpose is that a consumer can display a
rubric, and the object a consumer holds is the assessment. Separately,
`GuideItem#name` and `#to_s` now disagree on the same value object.

**8. Dead code left by the move.** Confirmed against the coverage report:
`singable_intervals.rb:51-66` (`permitted_descriptions`, `describe_shorthand`,
`both_directions?` — no caller in `lib`, `spec`, or `bin`; superseded by the
class-level `describe`); `guideline.rb:74` (the `instruction_key` branch, which
no guideline reaches because none has an `instruction:` entry); and
`guideline.rb:151-153` (`Guideline#message`, kept alive only by
`bin/guide_item_strings.rb`). Step 4 said it would delete the English inside
`describe_shorthand`; the English went and the method stayed.

**9. Unresolved open question.** Plan open question 3 — `DirectionChanges` and
`EndOnPerfectConsonance` are in no registry entry — is still unresolved and
unnoted. Both now carry working locale entries that `verify!` can never exercise.
It wants one durable sentence, in the story or the backlog.

**10. Smaller notes.** `verify!` costs ~9.8 ms against a ~114 ms require, not the
0.8 ms the plan measured — fine, but the figure should not carry into the finish
notes. `String#pluralize` is available only transitively via
`integer/inflections`; one explicit require removes the risk. Three spec-hygiene
items: top-level constants leaking from `guide_strings_spec.rb`,
`I18n.backend.send(:translations)` reaching a private method, and the
now-permanently-true `respond_to?` discriminators left over from the
before/after measurement.

### What held up well

`en_GB` was handled thoroughly: four British violation entries, the mid-chain
hazard documented in the file itself, a spec pinning the complete-plural-forms
requirement *and* testing the guard, and British note names deferred to the
backlog as a separate decision. Scope creep is essentially nil — every file
outside `lib/` traces to a plan step. And the pinned table of 67 strings is not
tautological: it asserts composed output, so a wrong interpolation name, plural
selector, or dropped `humanize` all fail it.

### Blocking `finish`

Findings 1, 2, and 3. Each is small — a rescue list, a locale resolution, a
delegation — and each defeats something the story asked for by name.

## Fixes applied

Findings 1–3 are fixed, in working-tree changes to three files plus two specs.
All 67 pinned strings are byte-identical before and after — checked by running
`bin/guide_item_strings.rb` at `dc82b79` in a worktree and against the fix, and
diffing. Suite 6585 examples, 0 failures, 99.60% line coverage; rubocop clean.

**1. The rescue narrowed to what Ruby is actually covering.**
`Template.pluralize` now rescues `I18n::InvalidPluralizationData` alone, not
`MissingTemplate` as well. A locale that cannot pluralize still falls back; a
template that is simply wrong now propagates to `verify!`. The same probe that
loaded clean before:

```
before: LOADED CLEAN — student reads "three notes", sentence gone
after:  RAISED MissingTemplate: guidelines.minimum_notes.violations.default:
        missing interpolation argument :bogus
```

**2. A template and its values render in one locale.** `Template.resolved_locale`
names the first locale in the reader's fallback chain that carries the entry
itself — `I18n.exists?` consults the chain and so answers true for every locale,
which is why this needs `fallback: false`. `Template.in_locale_of` wraps the
render, and `Guideline.render_template` now takes the **config** rather than
finished values, so `template_values` — where the humanizing happens — runs
inside that locale:

```
de: "Minimum of three notes" | "Write at least three notes."
ru: "Minimum of three notes" | "Write at least three notes."
fr: "Use one whole note in each middle bar."
```

**3. One rendering seam.** `GuideItemAssessment#message` now calls
`guideline.render_template(violation_key, config, violation_values)` instead of
reaching for `Template.render` itself, so the student-facing path gets the plural
routing and fallback the preview already had. With the partial `en_GB` plural
hash the plan names as its landmine, read under `:de`:

```
before:  preview "eight notes" | assessment RAISED InvalidPluralizationData
after:   preview "eight notes" | assessment "eight notes"
```

This also closes the gap the review noted under criterion 4: `violation_values`
is now what one violation *adds*, and the item's own interpolations are rebuilt
from config when the message renders — so an assessment made under one locale
still reads correctly under another. That is what the criterion said all along
("`violation_values` merged over the item's interpolations"); it previously *was*
the item's interpolations, frozen at assess time.

Three regression tests were added and two rewritten. The rewritten pair had used
an absent key as its stand-in for "the locale cannot answer" — which is now
correctly an error — so they use a plural hash with forms English cannot select
from, the shape a correct Russian entry has without
`I18n::Backend::Pluralization`. The new ones pin: a broken plural template
raises rather than falling back; `resolved_locale` picks the right locale; every
registry string under `:de` is identical to the same string under `:en_GB`; and
the assessment renders through the same seam as the preview.

### Still open

Findings 4–10 are untouched and none of them block. Worth noting that finding 4
is now more visible: the Ruby plural fallback still returns a bare noun phrase
("eight notes") rather than the sentence, which is what both paths agree on
above. It is a smaller problem than it was — the fallback is now reached only
when a locale genuinely cannot pluralize, not whenever a template is broken —
but it is still the wrong output for that case.
