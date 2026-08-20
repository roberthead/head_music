<!--
metadata:
  created_at:   2026-08-17T15:14:53-07:00
  activated_at: 2026-08-19T13:12:32-07:00
  planned_at:   2026-08-19T13:30:41-07:00
  finished_at:  2026-08-19T20:08:02-07:00
  updated_at:   2026-08-19T20:08:02-07:00
-->

# Story: British Note Names

## Summary

AS a British reader of a style guideline
I WANT note values named as semibreves, minims, crotchets and quavers
SO THAT the guidance reads as my teacher would say it, not as a translation

## Notes

`Guideline Strings into I18n` gave `en_GB` the five strings whose *spelling*
differs — `neighbour`, `metre`, and a bar rather than a measure. It stopped
there. British readers still get "Use four quarter notes in each middle bar."

This was left out deliberately rather than missed, because it is not the same
kind of change and it carries a live hazard.

**A vocabulary swap does not survive the sentence.** The obvious fix is to
override the three `rhythmic_units` entries — `whole`, `half`, `quarter` — and
let the templates pick them up. It does not work. The template reads:

```yaml
note_count_per_bar:
  violations:
    default:
      other: "Use %{number} %{rhythmic_unit} notes in each middle bar."
```

Substituting the vocabulary alone yields "Use four crotchet notes in each middle
bar." British drops the noun: "Use four crotchets in each middle bar." So the
`en_GB` side needs its own *sentences*, not its own words — and that is a
translation job, not a find-and-replace.

**Those sentences are pluralized, and `en_GB` sits mid-chain.** `de`, `fr`, `it`
and `ru` all resolve through `en_GB` before reaching `en`. I18n stops at a plural
hash that is present but incomplete rather than continuing past it, so a British
entry carrying only `other:` raises for those four languages and never for the
British reader who wrote it. `guide_strings_spec.rb` guards this
(`partial_plurals_in`), which is what makes the work safe to pick up — but it is
the reason not to do it in passing at the end of another story.

**Scope.** Thirty `en.yml` leaves, which a British reader meets as 33 distinct
strings. (This table first read "Sixteen touchpoints" over rows summing to 19.
Both figures were guesses from reading the file; the census below came from
probing the loaded gem, and the gap is the whole reason for `### A note on
method` at the end of this story.)

| Kind | Leaves | Which |
| --- | --- | --- |
| Hardcode an American note value | 21 | 14 across 5 guidelines — `allowed_rhythmic_values_for_combined123`, `allowed_rhythmic_values_for_fifth_species`, `first_bar_half_notes`, `first_bar_quarter_notes`, `first_bar_whole_note` — and 7 of the 23 guide instructions |
| Interpolate `%{rhythmic_unit}` | 6 | `note_count_per_bar`'s name, instruction and violation, each `one:`/`other:` |
| Vocabulary entries | 3 | `rhythmic_units.half`, `.quarter`, `.whole` |

The 21 prose leaves are 21 strings; the `note_count_per_bar` family renders 12
(four subclasses × name, instruction, violation). Hence 33.

`rhythmic_units` has no `eighth`, though
`allowed_rhythmic_values_for_fifth_species` names eighth notes in prose —
deferred, since nothing interpolates it; see `## Decisions taken`.

Worth deciding first: whether the British vocabulary belongs to the style scope
or to `Rudiment::RhythmicUnit`, which is where the gem names these values for
every other purpose. If the latter, this story is smaller than it looks and the
notation module benefits too. **Decided: the style scope** — and it does not make
the story smaller, because the pin means a vocabulary override alone renders
nothing. See `## Decisions taken`.

## Acceptance Criteria

- A British reader gets British note values in every style string that names one
- Every pluralized `en_GB` entry carries the complete set of forms, and the
  existing guard proves it rather than discipline
- `de`, `fr`, `it` and `ru` still render every string, since they route through
  `en_GB` — the property spec in `guide_strings_spec.rb` already covers this
- The decision about `rhythmic_units` versus `Rudiment::RhythmicUnit` is recorded

## Decisions taken

**The British note vocabulary belongs to the style scope, in `en_GB.yml`, not to
`Rudiment::RhythmicUnit`.** Two reasons, one mechanical and one about ownership.

Mechanically, the vocabulary alone cannot reach a reader. `render_template` pins
value-building to the locale that carries the sentence
(`lib/head_music/style/guideline/wording.rb:62-63`), so a British
`rhythmic_units` entry is never consulted unless `en_GB` also carries the
sentence. Storing British words with no British sentence leaves every string
unchanged — the override is not merely awkward, it is inert. Once `en_GB` carries
the sentence, the vocabulary can live anywhere, so its home stops being the
deciding question and proximity to the sentences wins.

On ownership, `RhythmicUnit#name` is an identifier, not a label. `flags`
(`rhythmic_unit.rb:106`), `common?` (`:115`) and the numerator/denominator
derivation (`:157-159`) all index the American name arrays by it;
`AllowedRhythmicValuesForFifthSpecies` compares `unit_name` against a literal
`%w[whole half quarter eighth]`; MusicXML export raises on a miss
(`duration_writer.rb:72`); and `Placement#to_h` serializes it into composition
JSON (`placement.rb:124`). Making `#name` follow `I18n.locale` would make
duration arithmetic, grading and export depend on the reader's language.
`Named#name` takes an explicit `locale_code:` defaulting to the constant `:en_US`
and never reads `I18n.locale` (`named.rb:26`), so it is a separate locale system,
not an I18n seam. `RhythmicUnit#british_name` and `rhythmic_units.yml` keep
serving the notation module unchanged; the two mechanisms stay deliberately
separate, and a future reader should not "improve" that.

**`de`, `fr`, `it` and `ru` inherit the British vocabulary, and a follow-up gives
them their own.** Recorded in full under Open questions below, with the
three-family survey that shows why no choice of English serves all four. The
follow-up is `user-stories/backlog/note-values-in-each-language.md`.

**One planned guard was dropped, not forgotten.** The plan called for a
"complete-or-not-at-all overrides" spec asserting that an `en_GB` entry
overriding one leaf overrides all its siblings. It is wrong: four existing
entries -- `allowed_rhythmic_values_for_fifth_species`,
`florid_dissonance_treatment`, `no_rests` and
`third_species_dissonance_treatment` -- override `instruction` and
`violations.default` but not `name`, correctly, because those names carry no
British divergence to make. Only
siblings that actually differ need overriding, so the property is unwritable as
stated -- and unnecessary, since item names are in `strings_in` and the
vocabulary sweep already catches a sibling left in American. The
`en_GB`-only-overrides-existing-keys guard it was paired with survives, compared
at template-key rather than leaf granularity: the two locales pluralize
different entries deliberately, and neither shape is a new key.

**`third_species_harmony`'s spelling repair belongs to this story, not to its
predecessor.** The entry needs an `en_GB` override for the note value regardless
-- it is the 21st note-value string -- so the escaped `neighbour` comes along at
no extra cost. Attributing it here rather than filing it as a defect against
`Guideline Strings into I18n` keeps the changelog honest: the string changed in
this story's diff, and splitting one entry's history across two changelog
sections would serve nobody. Worth naming why it escaped: the predecessor's
word-frequency scan reported zero divergences because it read the file rather
than the rendered strings, which is the same failure `### A note on method`
records.

**Deferred, deliberately.** No `eighth`/`quaver` vocabulary entry: nothing
interpolates it, and it would have to be added to `en.yml` too. The two
pre-existing English prose defects found while drafting the British copy (the
misplaced final-bar qualifier and the inconsistent Oxford comma) stay unfixed on
both sides, so the British copy mirrors the American shape and the diff stays
honest. `rudiments.meter` stays American; it sits outside the style scope.

## Implementation Plan

### Overview

Give `en_GB` its own note-value **sentences** and a **pluralized vocabulary**,
leaving `en.yml` untouched and `Rudiment::RhythmicUnit` alone. One Ruby line
changes (`render` → `pluralize` at `note_count_per_bar.rb:24`); everything else
is locale YAML.

The framing above is right, but the scope count is low by about half, and the
stated hazard is not the one that actually forecloses the design.

### The decision, and the mechanism the notes did not name

`render_template` wraps value-building in `Template.in_locale_of(key)`
(`lib/head_music/style/guideline/wording.rb:62-63`), which pins the render to
whichever locale carries **the sentence**. The nested
`Template.render("rhythmic_units.#{unit}")` at `note_count_per_bar.rb:24`
therefore resolves in that same pinned locale.
`resolved_locale("guidelines.note_count_per_bar.name", locale: :en_GB)` returns
`:en` today. Storing a British `rhythmic_units` override and rendering all four
`note_count_per_bar` items in `:en_GB` yields, unchanged:

```
Use one whole note in each middle bar.
Use two half notes in each middle bar.
Use four quarter notes in each middle bar.
Use three quarter notes in each middle bar.
```

**A vocabulary override alone is not merely awkward — it is inert.** The
noun-drop is a style argument; the pin is a mechanical one, and it is what rules
out every vocabulary-only shortcut, including the tempting
`rhythmic_units.plural.quarter: "crotchets"` middle route. Do not "fix" the pin:
it exists to prevent the "Write at least Acht notes." bug documented at
`template.rb:55-57`.

### Decision to record

> The British note vocabulary belongs to the style scope, in `en_GB.yml`, not to
> `Rudiment::RhythmicUnit`. Two reasons, one mechanical and one about ownership.
>
> Mechanically, the vocabulary alone cannot reach a reader. `render_template`
> pins value-building to the locale that carries the sentence
> (`guideline/wording.rb:62-63`), so a British `rhythmic_units` entry is never
> consulted unless `en_GB` also carries the sentence. Once `en_GB` carries the
> sentence, the vocabulary can live anywhere — so the vocabulary's home stops
> being the deciding question, and proximity to the sentences wins.
>
> On ownership, `RhythmicUnit#name` is an identifier, not a label. `flags`
> (`rhythmic_unit.rb:106`), `common?` (`:115`) and the numerator/denominator
> derivation (`:157-159`) all index the American name arrays by it;
> `AllowedRhythmicValuesForFifthSpecies` compares `unit_name` against a literal
> `%w[whole half quarter eighth]`
> (`allowed_rhythmic_values_for_fifth_species.rb:8`); MusicXML export raises on
> a miss (`duration_writer.rb:72`); and `Placement#to_h` serializes it into
> composition JSON (`placement.rb:124`). Making `#name` follow `I18n.locale`
> would make duration arithmetic, grading and export depend on the reader's
> language. `Named#name` takes an explicit `locale_code:` defaulting to the
> constant `:en_US` and never reads `I18n.locale` (`named.rb:26`,
> `named/locale.rb:4`), so it is a separate locale system, not an I18n seam.
>
> The route also saves almost nothing: the noun-drop forces `en_GB` to carry its
> own sentences for the whole `note_count_per_bar` family regardless, plus 14
> guideline strings and 7 guide instructions that name a note value in prose.
> The vocabulary is 3 entries out of 30. `RhythmicUnit#british_name` and
> `rhythmic_units.yml` keep serving the notation module unchanged; the two
> mechanisms stay deliberately separate.

### The scope is roughly double the table above

That table is internally inconsistent — it announces "Sixteen touchpoints" over
rows summing to 19 — and both figures undercount, because they count *entries*
where the work is *leaf strings*.

| | Stated | Actual |
| --- | --- | --- |
| Hardcode an American note value | 12 | **21** leaves (14 guideline + 7 guide) |
| Interpolate `%{rhythmic_unit}` | 4 | **6** leaves (the `instruction` pair was omitted) |
| Vocabulary entries | 3 | 3 |
| **YAML leaves total** | 16/19 | **30** |
| **Unique strings a British reader reads in American today** | — | **33** |

Two specific misses:

- **`en.yml:923` `guides.third_species_harmony`** — "treat the **quarter-note**
  dissonances as passing or **neighbor** tones" — has no `en_GB` override. It is
  both the 21st note-value string *and* an escaped `neighbour` miss from
  `Guideline Strings into I18n`; it is the only American spelling in the file
  with no British counterpart. One entry repairs both.
- **`en.yml:548` `rudiments.meter: meter`** — outside the style scope, but the
  same class of gap: the glossary says "meter" while
  `triple_meter_dissonance_treatment.name` says "metre".

### Steps

**1. Record the decision in the story**

Add `### Decisions taken` using the text above; mirror
`user-stories/done/guideline-strings-into-i18n.md:468`. Correct the touchpoint
table to the census.

**2. Write the failing guards first**

Add the vocabulary-ownership sweep and the two pinned `NoteCountPerBar`
sentences to `spec/head_music/style/guide_strings_spec.rb`. Write the sweep in
its general shape — *no locale carries note vocabulary from a family it does not
own* — not as a British-versus-American pair; see Testing strategy for the form
and for the two regex traps. Run it and confirm it fails naming 33 strings, which
is the work queue for steps 3-5.

**3. The vocabulary and the `note_count_per_bar` family** (one step — the pin
couples them)

`note_count_per_bar.rb:24`: `render(...)` →
`HeadMusic::Style::Template.pluralize("rhythmic_units.#{unit}", count: count)`.
`count` is already in scope at line 19, and `guard_value_keys!` explicitly
permits it (`template.rb:115`).

Add to `en_GB.yml` a **pluralized** vocabulary and **flat** sentences. `en.yml`
is not touched: its scalar entries stay scalar (I18n ignores `count:` on a
String), so the pinned English table cannot move.

```yaml
      rhythmic_units:
        whole:
          one: "semibreve"
          other: "semibreves"
        half:
          one: "minim"
          other: "minims"
        quarter:
          one: "crotchet"
          other: "crotchets"
      guidelines:
        note_count_per_bar:
          name: "%{number} %{rhythmic_unit} per bar"
          instruction: "Write %{number} %{rhythmic_unit} in each middle bar."
          violations:
            default: "Use %{number} %{rhythmic_unit} in each middle bar."
```

Verified end to end — English byte-identical, British correct in both plural
branches, no Ruby plural fallback triggered:

```
en     quarter 4 -> Use four quarter notes in each middle bar.
en     whole   1 -> Use one whole note in each middle bar.
en_GB  quarter 4 -> Use four crotchets in each middle bar.
en_GB  whole   1 -> Use one semibreve in each middle bar.
es     quarter 4 -> Use four quarter notes in each middle bar.
en_US  quarter 4 -> Use four quarter notes in each middle bar.
fell_back_to_ruby: []
```

Flat sentences rather than mirroring `en`'s `one:`/`other:`, because the noun has
moved into the interpolated value and the British sentence genuinely does not
inflect. This keeps the entries honestly different from `en`, avoids baking
`%{rhythmic_unit}s` English morphology into a template, and means **this story
adds no pluralized British *sentence* entry at all**. The plural burden moves to
`rhythmic_units`, where all three hashes are complete — giving the existing
`partial_plurals_in` guard real data to walk for the first time.

**4. The five guideline entries that name a value in prose** (14 leaves) — in
`en_GB.yml`

```yaml
        allowed_rhythmic_values_for_combined123:
          name: "Semibreves, minims, and crotchets only"
          instruction: "Write in semibreves, minims, and crotchets."
          violations:
            default: "Use only semibreves, minims, and crotchets."
        allowed_rhythmic_values_for_fifth_species:
          instruction: "Write in minims, crotchets, and paired stepwise quavers on weak beats, saving the semibreve for the final bar."
          violations:
            default: "Use only semibreves in the final bar, minims, crotchets, and paired stepwise quavers on weak beats."
        first_bar_half_notes:
          name: "Minims in the first bar"
          instruction: "Open the first bar with minims, or enter after a minim rest."
          violations:
            default: "Begin the first bar with minims, or enter after a minim rest."
        first_bar_quarter_notes:
          name: "Crotchets in the first bar"
          instruction: "Open the first bar with crotchets, or enter after a crotchet rest."
          violations:
            default: "Begin the first bar with crotchets, or enter after a crotchet rest."
        first_bar_whole_note:
          name: "Semibreve in the first bar"
          instruction: "Open with a semibreve in the first bar."
          violations:
            default: "Begin with a semibreve in the first bar."
```

`allowed_rhythmic_values_for_fifth_species.name` ("Fifth species note values")
takes **no** override — "note value" is standard British. Do not miss the
**rests**: "half rest" → "minim rest", "quarter rest" → "crotchet rest". These
are the only attributive uses, and a sweep written for "half note" alone passes
them silently.

**5. The seven guide instructions** — in `en_GB.yml` (the `guides:` block
already exists)

```yaml
      guides:
        fux_cantus_firmus:
          instruction: "Write a cantus firmus: a singable line of eight to fourteen semibreves that begins and ends on the tonic."
        first_species_melody:
          instruction: "Write one semibreve against each note of the cantus firmus."
        second_species_melody:
          instruction: "Write two minims in each bar against the cantus firmus."
        third_species_melody:
          instruction: "Write four crotchets in each bar against the cantus firmus."
        third_species_harmony:
          instruction: "Keep the downbeats consonant, and treat the crotchet dissonances as passing or neighbour tones."
        third_species_triple_meter_melody:
          instruction: "Write three crotchets in each bar against the cantus firmus."
        combined_first_second_third_species_melody:
          instruction: "Combine semibreves, minims and crotchets in one line, changing rhythm between phrases."
```

**6. Update the stale comment and the file header**

`guide_strings_spec.rb:157-158` — "There are no pluralized British entries yet,
so the guard above would pass on an empty tree" becomes false in step 3.
Re-motivate the fixture as proving the *detector* fires, and add a companion
example asserting the walk actually reaches the real British plural entries —
otherwise a typo dropping the whole `rhythmic_units` block leaves the guard green
over nothing again.

`en_GB.yml:5-9` — extend the comment to say the file now carries note
**vocabulary** as well as spelling, why it lives here rather than in
`RhythmicUnit`, and that `de`/`fr`/`it`/`ru` inherit it deliberately.

**7. Verify and lint**

`bundle exec rspec spec/head_music/style/guide_item_strings_spec.rb` — the ~67-row
American table must be byte-identical. Any diff means a British string leaked
into `en.yml`. Wrap that table's `it` body in `I18n.with_locale(:en)`
(`guide_item_strings_spec.rb:83-92` relies on the ambient default, and
`spec_helper.rb` sets no reset hook) — harmless when the dialects differed by
five strings, a real hazard once they differ by thirty. Then
`bundle exec rubocop -a` and `bundle exec rake validate`.

### The noun-drop rule, precisely

American note-value words are *adjectives* requiring the head noun "note";
British words are *nouns* taking none. Wherever `en` reads `<value> note(s)`,
`en_GB` reads `<british-noun>(s)`. This holds in the singular exactly as in the
plural — "one semibreve per bar", never "one semibreve note". Three exceptions
where a noun survives:

1. **Attributive before a different head noun** — "half rest" → "minim rest";
   "quarter-note dissonances" → "crotchet dissonances". The American hyphen goes
   with the compound: "crotchet dissonances", not "crotchet-dissonances".
2. **"note" doing generic work** — in "Write one semibreve against each **note**
   of the cantus firmus", the second "note" is a real note, not half a compound.
   It stays.
3. **"note value(s)"** — standard in both dialects.

Register is confirmed by the repo's own sources.
`references/fifth-species-counterpoint.md:264` quotes ntoll.org — "Do not make
use of **semibreves** in any part of the counterpoint except the last bar" — and
`:381` — "The rhythm of two **crotchets** and a **minim** in one bar". Bare
nouns, no "note", exactly the drafted register. `:87` shows the attributive form
without a hyphen ("quaver figures").

Guideline names stay parallel and article-less — "Semibreve in the first bar"
rather than the more natural "A semibreve in the first bar", so it matches its
two siblings. Precedent already exists in the file: `en_GB.yml:4` reads
`grand_staff: great staff`, a pure vocabulary swap already living in the locale
file.

### Testing strategy

The 90% coverage floor is **neither threatened nor informative** here — steps 3-5
are almost entirely YAML, and the one Ruby change replaces a line in place.
Coverage will pass whatever you write; the property specs *are* the regression
protection. (A single-file `rspec` run reports ~49% and fails SimpleCov — judge
coverage only from `bundle exec rake`.)

All additions go in `spec/head_music/style/guide_strings_spec.rb`, using its
collect-then-assert idiom.

- **Vocabulary ownership** — the executable form of acceptance criterion 1, and
  the one spec to write in its general shape from the start: *no locale carries
  note vocabulary from a family it does not own*. Not "no American words in
  `en_GB`", which would have to be rewritten the moment `de` gets its own words.

  ```ruby
  NOTE_VOCABULARIES = {
    american: /\b(whole|half|quarter|eighth|sixteenth)[-\s](note|rest)/i,
    british: /\b(semibreve|minim|crotchet|quaver|semiquaver)s?\b/i
  }.freeze

  # Which vocabulary each locale resolves to. de, fr, it and ru read British by
  # inheritance -- deliberately, and recorded in the decision above. This map is
  # that decision in executable form: change the fallback chain and the sweep
  # fails until this changes with it.
  LOCALE_NOTE_VOCABULARY = {
    en: :american, en_US: :american, es: :american,
    en_GB: :british, de: :british, fr: :british, it: :british, ru: :british
  }.freeze

  it "gives every locale only the note vocabulary it owns" do
    trespasses = I18n.available_locales.flat_map do |locale|
      owned = LOCALE_NOTE_VOCABULARY.fetch(locale)
      foreign = NOTE_VOCABULARIES.except(owned)
      strings_in(locale).flat_map do |string|
        foreign.filter_map { |family, pattern| "#{locale}: #{family} in #{string.inspect}" if pattern.match?(string) }
      end
    end

    expect(trespasses).to be_empty
  end
  ```

  Three things this shape buys that the two-sweep version does not. `fetch` with
  no default means a locale added to the gem fails loudly until someone decides
  which vocabulary it reads, rather than being silently swept as American. The
  map turns a fallback-chain edit into a failing test — the same "says so out
  loud" property the `resolved_locale` pin gives, one level up. And the
  follow-up story changes four rows and a hash rather than rewriting the spec.

  Both patterns are load-bearing in their exact form, verified against the
  corpus:

  - **American must stay scoped to `note|rest`.** A bare
    `/\b(whole|half|quarter)\b/` matches the same 33 strings today, so the
    corpus does not distinguish them — but "half step", "whole tone", "quarter
    tone" and "half cadence" are all ordinary theory terms that would false-fire
    the day one enters the corpus. Scoping costs nothing now and does not need
    revisiting later. It still catches the adjectival `quarter-note dissonances`
    (`en.yml:923`), since the hyphen is followed by `note`.
  - **British must be `\b`-anchored.** An unanchored `/minim/` flags five
    existing strings — "Minimum of three notes", "Minimum of eight notes", and
    three more from `MinimumNotes`. The trailing `s?` inside the boundary covers
    the plurals the vocabulary hash introduces.

  This is the spec that fails today, naming 33 strings, and that failure list is
  the work queue for steps 3-5.
- **The two pinned sentences** — `"Use four crotchets in each middle bar."` and
  `"Use one semibreve in each middle bar."` under `:en_GB`. The one pair worth
  pinning verbatim: the singular/plural boundary *and* the noun-drop, the two
  things a find-and-replace gets wrong.
- **Complete-or-not-at-all overrides** — an `en_GB` entry that overrides
  `instruction` but not its sibling `name` ships a card with an American title and
  a British body, and nothing currently fails. Assert that for every `en_GB`
  guideline key, the leaf-key set matches what `en.yml` declares for it.
- **`en_GB` only overrides, never introduces** — load both YAML files from disk
  (as `declared_violation_keys` already does, to dodge the backend merge) and
  assert `british_key_paths - english_key_paths` is empty. A key present in
  `en_GB` and absent from `en` raises `MissingTemplate` for `es` and `en` readers
  and leaks British terms to `en_US`. This is the concrete argument against adding
  `eighth: "quaver"` to `en_GB` without `eighth: "eighth"` in `en`.
- **Pin the two locales that must not change** — `strings_in(:en_US) == strings_in(:en)`
  and `strings_in(:es) == strings_in(:en)`. These make the `es: [es, en]`
  divergence intentional rather than an oversight.
- **Pin the propagation** —
  `Template.resolved_locale("guidelines.note_count_per_bar.instruction", locale: :de) == :en_GB`,
  so the day the chain changes a test says so out loud.
- **`guide_item_strings_spec.rb` gets no British table.** 58 of 67 rows would
  duplicate the English, doubling the maintenance cost of every future wording
  change against a file whose whole value is that "a diff here is a sentence a
  student reads changing". The nine note-value rows are covered by the sweep plus
  the two pinned sentences.

**Sequencing note:** `Template.verify!` renders in `:en` deliberately
(`template.rb:96-100`), so a malformed `en_GB` template will **not** fail at
`require` — only in the per-locale loop at `guide_strings_spec.rb:52-56`. The
load-time net that catches every English mistake catches none of the British
ones. Steps 3-5 must not be committed without running that file.

### Open questions to decide before implementing

1. **Do `de`, `fr`, `it` and `ru` readers get crotchets? — decided: yes, and a
   follow-up gives them their own words.** The surveyed terminology splits three
   ways, not two: *fractional* (German, Russian, Dutch, Polish, Japanese — and
   American English), *mensural-Latin* (British English, Italian, Portuguese),
   and *shape-based* (French, Spanish, Catalan). Against that split, British
   helps exactly one of the four locales:

   | Locale | Family | Their quarter note | Effect of British |
   | --- | --- | --- | --- |
   | `it` | mensural-Latin | *semiminima* | mild win — *semibreve* is the same word, *minima* ≈ *minim* |
   | `de` | fractional | *Viertelnote* | mild loss — maps word-for-word onto the **American** names |
   | `ru` | fractional | *четвертная* | mild loss — same |
   | `fr` | shape-based | *noire* | **real loss** — see below |

   French is the sharpest case and the one the first draft of this plan got
   wrong (it filed French alongside Italian as "close to the British system";
   *ronde, blanche, noire* is shape-based and close to neither). French *croche*
   is the **eighth** note where English *crotchet* is the **quarter** — cognates
   from the same hooked-note root that drifted apart by a factor of two. A
   French reader meets a familiar-looking word attached to the wrong duration,
   which is worse than meeting a plainly foreign one. Spanish shares the false
   friend (*corchea* = eighth) but is unaffected: `es: [es, en]` skips `en_GB`.

   So the trade is one mild win, two mild losses and one real loss — weaker than
   "they are reading a stopgap anyway" suggested, and weak enough that accepting
   it silently would be the wrong call.

   Accepted anyway, because of what reframes it: those four locales carry **no
   style strings at all** today. A German reader already gets the entire style
   module in English, so nobody loses their own vocabulary here — the only
   question is which English they get. British serves the reader this story is
   for, and the regression for the other three is bounded and temporary.

   Recorded rather than absorbed: `user-stories/backlog/note-values-in-each-language.md`
   gives `de`, `fr`, `it` and `ru` their own note values. That story fixes French,
   which no choice of English can — option 4 (translating `de` and `ru` inside
   this story) would have left French broken while costing most of the same work.

   Reordering to `de: [de, en, en_GB]` remains rejected: it would hand those four
   readers "neighbor", "meter" and "measure", undoing the previous story's entire
   deliverable. The chain has one ordering to serve two independent axes —
   spelling, where `en_GB` is better for every international reader, and note
   vocabulary, where it depends on the family. Only per-locale entries separate
   them.
2. **Add `eighth`/`quaver` to `rhythmic_units`?** Nothing interpolates it — the
   four subclasses use only `:whole`, `:half`, `:quarter`, and the eighth notes in
   `allowed_rhythmic_values_for_fifth_species` are prose inside a sentence being
   overridden anyway. **Recommendation: drop it**; if added, it must go into
   `en.yml` too. Zero rendered strings change either way.
3. **Two pre-existing `en` prose defects**, found while drafting the British copy.
   (a) `allowed_rhythmic_values_for_fifth_species.violations.default` reads "Use
   only whole notes in the final bar, half notes, quarter notes, and…" — the
   qualifier attaches to item one but sits inside a four-item list, so it scans as
   though everything after it is final-bar-only. (b)
   `allowed_rhythmic_values_for_combined123` uses the Oxford comma while
   `combined_first_second_third_species_melody` does not, for the same three
   values. The drafted British copy preserves each string's existing shape so the
   diff stays honest — but fixing these only in `en_GB` would leave the British
   copy reading *better* than the American, which is the wrong kind of divergence.
   Fix both in `en` (moving the pinned table deliberately), or defer both. Do not
   fix one side only.
4. **Does `third_species_harmony`'s "neighbor" fix belong here?** It needs an
   `en_GB` entry for the note value regardless, so the spelling repair is free.
   Confirm it counts as in scope rather than as a defect filed against the
   predecessor story — it matters for changelog attribution.
5. **Fold in `rudiments.meter` (`en.yml:548`)?** One line, same class of miss, but
   outside the style scope and outside the story's table.

### Risks

- **Partial coverage is the likeliest way this ships half-done**, and today
  nothing fails. Because `in_locale_of` resolves per key, covering a subset
  produces a *mixed-dialect document*, not a partially-improved one — "Write two
  minims in each bar" beside "Write four quarter notes in each bar". The
  dialect-purity and complete-override specs in step 2 exist to close this; write
  them before the YAML. (The same pin makes intra-sentence mixing — "four crotchet
  notes" — mechanically impossible.)
- **`verify!` blindness to `en_GB`** (above). Correct design — a host app's locale
  must not decide whether the gem loads — but it means the suite is the only net.
- **`declared_violation_keys` reads `en.yml` from disk**
  (`guide_strings_spec.rb:88-95`) because the backend merges `en_GB` in. Adding
  `violations.default` to `en_GB` for five guidelines is safe by construction, but
  adding a violation *key that `en.yml` lacks* would make the file-read and
  `swept_violation_keys` disagree confusingly.
- **`RhythmicUnit` blast radius is zero if the recommendation is followed, severe
  if not** — `duration_writer.rb:72` raises, and
  `allowed_rhythmic_values_for_fifth_species.rb:24` silently misgrades. Worth
  stating in the decision record so a future reader does not "improve" it.
- **The resolved locale is not exposed**, so a consumer who sets
  `I18n.locale = :de` receives an `en-GB` string and cannot write a truthful `lang`
  attribute. `Template.resolved_locale` computes the right answer but is not public
  on the string-producing objects, and `:en_GB` is not a valid BCP 47 tag (`en-GB`
  is). Recommend a follow-up story; the propagation spec above documents it in the
  meantime.
- **Known duplication, deliberately not addressed.** `RhythmicUnit` already holds
  British names twice — `BRITISH_*_NAMES` constants matched *positionally* against
  the American arrays (`rhythmic_unit.rb:138-143`), and explicit pairs in
  `rhythmic_units.yml` read only by the parser. Inserting a row into
  `AMERICAN_DIVISIONS_NAMES` shifts every `british_name` below it with nothing to
  catch it. This story adds a third copy in `en_GB.yml`. Defensible separation
  (pedagogical prose vs. rudiment naming), but real — consolidating the constants
  into the YAML is a genuine follow-up worth filing.
- **Sequence this before the two backlog stories that add guidelines** —
  `sixteenth-century-style.md` and `split-counterpoint-species-by-author.md`. Both
  will add strings naming note values. Doing British first means they inherit the
  sweep and cannot silently ship an untranslated sentence.

### A note on method

`guideline-strings-into-i18n.md` records that a word-frequency scan reported "zero
`en_GB` divergences" and had missed `neighbor` in three files. That is how this
story arrived at 16 touchpoints when there are 30, and how `third_species_harmony`
survived a spelling sweep. Every count above came from running a probe against the
loaded gem, not from reading the file.

## Review

Reviewed 2026-08-19 at `5ad03db` (the story's tip; `main` has since moved to
`a6c7909` with three unrelated refactoring commits on top). Diff under review:
`78fd01f..5ad03db`. Suite green — 6678 examples, 0 failures, 99.77% line
coverage; `rubocop` clean across 518 files.

Every claim below was re-derived by running the gem, not by reading the diff.

### Acceptance criteria

| Criterion | Verdict |
| --- | --- |
| A British reader gets British note values in every style string that names one | ✅ met |
| Every pluralized `en_GB` entry carries the complete set of forms, proven by the guard | ✅ met |
| `de`, `fr`, `it` and `ru` still render every string | ✅ met |
| The `rhythmic_units` versus `Rudiment::RhythmicUnit` decision is recorded | ✅ met |

**1 — British note values everywhere.** Sweeping every style string in every
locale gives a clean partition with no mixed-dialect gap, which was this story's
own top-stated risk:

```
en 0/33   en_US 0/33   es 0/33            (british/american)
en_GB 33/0  de 33/0  fr 33/0  it 33/0  ru 33/0
```

`en` names an American value in exactly 33 strings and `en_GB` names a British
one in exactly 33 — a one-for-one replacement, matching the plan's census. The
sweep used a regex deliberately looser than the spec's (bare words and plurals,
dropping the `note|rest` scoping) and still found zero American survivals. Both
`NoteCountPerBar` plural boundaries render correctly: "Use one semibreve in each
middle bar." and "Use four crotchets in each middle bar."

**2 — Complete plural forms.** The only pluralized British entries are the three
`rhythmic_units` hashes, each carrying exactly `one`/`other`. The guard walks the
real backend tree (`guide_strings_spec.rb:256`), a fixture proves the detector
fires (`:263`), and a third example proves the tree is non-empty (`:270`) —
closing the "green over nothing" hole the old comment admitted to.

**3 — The four inheriting locales.** All four produce every string: none empty,
none raising, no surviving `%{}` interpolation. No `I18n::Backend::Pluralization`
is included (`head_music.rb:24` adds only `Fallbacks`), so `one`/`other` is the
complete form set the default backend can select — the British hashes do not
stop the fallback for `de`, `fr`, `it` or `ru`.

**4 — The decision.** Recorded at `:77-103` with both the mechanical argument
(the `in_locale_of` pin makes a vocabulary-only override inert) and the ownership
one, and condensed into `en_GB.yml:18-20` so a reader of the YAML meets it where
they would be tempted to "improve" it.

### Code review findings

**1. The vocabulary sweep is blind to the one leak the noun-drop makes possible.**
`NOTE_VOCABULARIES[:american]` (`guide_strings_spec.rb:19`) requires a
`note|rest` head noun. That scoping is load-bearing and correct for prose — "half
step" and "whole tone" are ordinary theory terms, and the British `\b` boundary
stops `/minim/` firing on the five real "Minimum of eight notes" strings. But the
British sentence *drops that head noun by design*, so an American word arriving
through `%{rhythmic_unit}` arrives bare and the sweep cannot see it. Reproduced
by adding an `eighth` unit to `en` only:

```
en    : "Use eight eighth notes in each middle bar."
en_GB : "Use eight eighth in each middle bar."
american sweep flags the en_GB string? false
```

Not a live defect — only `whole`, `half` and `quarter` units exist, and nothing
leaks in any locale today. But this is exactly the regression the sweep was added
to catch, and it bites on the next unit added. A key-parity guard over the
vocabulary closes it without depending on any sentence rendering it:
`template_keys(:en).grep(/\Arhythmic_units\./) - template_keys(:en_GB)...` is
empty today.

**2. `strings_in` does not sweep guide display names.** It collects
`guides.map(&:instruction)` (`:84-88`) but not `guide.name`, which exists. No
guide name names a note value today, so this is a blind spot rather than a miss —
it matters because the plan sequences `sixteenth-century-style.md` and
`split-counterpoint-species-by-author.md` behind this story precisely so they
inherit the sweep.

**3. Nitpick — `:279` pins the exact unit list.** `match_array %i[whole half
quarter]` couples the example to today's vocabulary, so adding a `quaver` entry
later fails with a message that reads like a regression. The key-parity guard
above would carry the intent without the coupling.

**4. Nitpick — the comment at `:270` overstates.** "And proves it fires at the
real tree" describes an example that never calls `partial_plurals_in`. It proves
the tree that guard walks is non-empty and well-formed, which is the useful
thing; only the wording claims more.

### Verified correct, no action

The `render` → `pluralize` change is right and `count` is plumbed properly
(`guard_value_keys!` explicitly permits a lone `:count`). The British is
internally consistent, including every attributive use — "minim rest", "crotchet
rest", "crotchet dissonances" — and leaving
`allowed_rhythmic_values_for_fifth_species.name` un-overridden is correct, since
"note values" is idiomatic in both dialects. Reading YAML from disk rather than
the backend in `template_keys` and `declared_violation_keys` is load-bearing for
a second reason the comments do not name: `template_spec.rb:5` and
`guide_item_spec.rb:125` both `store_translations` into `:en` permanently within
the suite process. The `I18n.with_locale(:en)` wrap in `guide_item_strings_spec.rb`
is defensive rather than fixing a live failure — the repo sets no ambient locale —
which is the right call for a locale-sensitive pin.

### Story hygiene

**Step 1 half-landed.** `### Decisions taken` was written, but "Correct the
touchpoint table to the census" was not: the Notes section still announces
"Sixteen touchpoints" (`:51`) over rows summing to 19, and still poses "Worth
deciding first: whether the British vocabulary belongs to the style scope or to
`Rudiment::RhythmicUnit`" (`:63-66`) as open — fifteen lines before
`### Decisions taken` answers it. A future reader meets the stale framing first.

**One stale count.** `:112` reads "three existing entries override `instruction`
and `violations.default` but not `name`". It is four as of this diff:
`allowed_rhythmic_values_for_fifth_species` joined `florid_dissonance_treatment`,
`no_rests` and `third_species_dissonance_treatment`. The argument is unaffected.

**Open question 4 was resolved in code but not in prose.** The
`third_species_harmony` entry landed (`en_GB.yml:95-96`), repairing both the note
value and the escaped `neighbour` spelling. But the question asked for an explicit
in-scope confirmation *because it matters for changelog attribution*, and no such
line exists in `### Decisions taken` or in the changelog.

**The `rudiments.meter` deferral is right but its stated reason is not.**
"Outside the style scope" is true as a key path, yet `en_GB.yml:3-4` already
overrides `rudiments.grand_staff` (pinned by `head_music_spec.rb:25`), so a
`rudiments` override is established practice in this very file rather than a scope
crossing. `de` localizes the key (`"Takt"`), so it is meant to be localized, and
the result is a within-reader inconsistency: a British reader gets `"meter"` in
the glossary and `"Triple metre dissonance treatment"` one scope over. Still
correctly out of the acceptance criteria — but the honest reason is that no
reader path consumes it, not that the scope forbids it.

### Verdict

Nothing blocks finishing. Findings 1 and 2 are latent rather than live and can be
one follow-up; the hygiene items are story-file edits.

## Learnings

**Counting by reading the file was wrong twice in the same lineage.** The Notes
section claimed 16 touchpoints over rows summing to 19; probing the loaded gem
found 30 leaves and 33 strings. The predecessor story's word-frequency scan had
already made the identical mistake, reporting zero `en_GB` divergences while
missing `neighbor` in three files -- one of which this story had to repair. Every
count that came from a probe held up under review; every count that came from
reading the file did not. That is what `### A note on method` is for, and it
earned its place.

**The stylistic argument was right; the mechanical one was decisive.** The Notes
framed the design question as the noun-drop -- "four crotchets", not "four
crotchet notes" -- which is a translation argument. Planning found the real
constraint: `in_locale_of` pins value-building to whichever locale carries the
sentence, so a British vocabulary with no British sentence is not merely awkward,
it renders nothing at all. Same conclusion, but only the second reason rules out
the tempting middle route of `rhythmic_units.plural.quarter`. When a design
choice feels settled on taste, it is worth asking whether some mechanism already
settled it harder.

**Writing the guard before the YAML worked, and the commit order proves it**
rather than merely asserting it: `Write the vocabulary sweep in its general
shape` precedes `Give British readers British note values`. Writing it in
*general* shape -- ownership per locale, `fetch` with no default -- turned the
fallback-chain decision into executable form, so a locale added later fails until
someone decides which vocabulary it reads.

**A guard inherits the assumptions of the dialect it was written against.** The
sweep requires a `note|rest` head noun, which is correct and load-bearing for
prose -- "half step" and "whole tone" would otherwise false-fire. But this
story's whole point is that British *drops that noun*, so the one leak the new
design makes possible is precisely the one the guard cannot see. The change
altered the shape of the string and the guard's pattern was never re-checked
against the new shape. Found in review, not in implementation, and filed as
`guard-the-vocabulary-sweep-itself.md`.

**Abandoning a planned guard needs a recorded reason, or it comes back.** The
complete-or-not-at-all overrides spec was unwritable as stated, because four
entries correctly override `instruction` and `violations.default` but not `name`.
Writing down *why* it was dropped is what stops the next reader re-proposing it.

**Deferrals need reasons re-derived, not inherited.** Every deferral here was the
right call, but `rudiments.meter`'s stated reason -- "outside the style scope" --
did not survive checking: `en_GB` already overrides `rudiments.grand_staff`. The
decision was right and the justification was wrong, which is the harder kind of
error to catch.

**Story prose ages against its own diff.** Step 1's second half silently did not
land, and the "three entries" count went stale as the implementation grew a
fourth. A story that documents its own reasoning at length needs the same review
pass as the code.
