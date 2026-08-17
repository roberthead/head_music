<!--
metadata:
  created_at:   2026-08-16T00:00:00-07:00
  activated_at: 2026-08-17T12:07:58-07:00
  planned_at:   2026-08-17T12:34:26-07:00
  finished_at:
  updated_at:   2026-08-17T12:34:26-07:00
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

### Open questions

1. **Four `en_GB` entries change what German, French, Italian and Russian
   readers see**, since all four fall back through it. Harmless, but it should
   either be a CHANGELOG line or `en_GB` stays empty for style. Needs a call.
2. **23 guide instructions are the only wholly new prose and have no oracle.**
   Write them here, or ship `Guide#instruction` returning nil? Recommend writing
   them; the alternative is dead code under a coverage-drop guard.
3. **`DirectionChanges` and `EndOnPerfectConsonance` carry `MESSAGE` constants
   and appear in no registry entry** — their locale entries can never be
   exercised by the property spec. Two guidelines are dead code.
4. **`I18n::Backend::Pluralization` is not included**, only `Fallbacks`.
   English-only `one:`/`other:` ships safely today, but the day someone writes
   correct Russian they get `InvalidPluralizationData`. A backlog item.

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
