<!--
metadata:
  created_at:   2026-08-16T00:00:00-07:00
  activated_at: 2026-08-17T12:07:58-07:00
  planned_at:
  finished_at:
  updated_at:   2026-08-17T12:07:58-07:00
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
- Every message produced today is produced identically under `I18n.locale = :en`,
  including the humanized numerals and the pluralized nouns.
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

[to be filled in by /stories plan]
