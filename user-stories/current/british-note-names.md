<!--
metadata:
  created_at:   2026-08-17T15:14:53-07:00
  activated_at: 2026-08-19T13:12:32-07:00
  planned_at:   2026-08-19T13:30:41-07:00
  finished_at:
  updated_at:   2026-08-19T13:30:41-07:00
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

**Scope.** Sixteen touchpoints:

| Kind | Count | Which |
| --- | --- | --- |
| Hardcode an American note value | 12 | 5 guideline violations — `allowed_rhythmic_values_for_combined123`, `allowed_rhythmic_values_for_fifth_species`, `first_bar_half_notes`, `first_bar_quarter_notes`, `first_bar_whole_note` — and 7 of the 23 guide instructions |
| Interpolate `%{rhythmic_unit}` | 4 | `note_count_per_bar` name and violation, each `one:`/`other:` |
| Vocabulary entries | 3 | `rhythmic_units.half`, `.quarter`, `.whole` |

`rhythmic_units` has no `eighth`, though
`allowed_rhythmic_values_for_fifth_species` names eighth notes in prose. Adding
one is part of this work if the vocabulary route is taken.

Worth deciding first: whether the British vocabulary belongs to the style scope
or to `Rudiment::RhythmicUnit`, which is where the gem names these values for
every other purpose. If the latter, this story is smaller than it looks and the
notation module benefits too.

## Acceptance Criteria

- A British reader gets British note values in every style string that names one
- Every pluralized `en_GB` entry carries the complete set of forms, and the
  existing guard proves it rather than discipline
- `de`, `fr`, `it` and `ru` still render every string, since they route through
  `en_GB` — the property spec in `guide_strings_spec.rb` already covers this
- The decision about `rhythmic_units` versus `Rudiment::RhythmicUnit` is recorded

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

Add the dialect-purity sweep and the two pinned `NoteCountPerBar` sentences to
`spec/head_music/style/guide_strings_spec.rb`. Run and confirm the sweep fails
naming 33 strings — that failure list is the work queue for steps 3-5.

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

- **Dialect purity** — the executable form of acceptance criterion 1. Sweep
  `strings_in(:en_GB)` for American note values and rests; sweep `strings_in(:en)`
  for British ones. A negative sweep beats an enumerated table because it catches
  a *future* guideline that names a note value and never gets a British
  counterpart. The regex must cover rests and the adjectival `quarter-note`. This
  is the spec that fails today naming 33 strings.
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

1. **Do `de`, `fr`, `it` and `ru` readers get crotchets?**
   `guideline-strings-into-i18n.md:468` **already records** "`en_GB` stays
   mid-chain… closer to international English than `en_US` is" — so this extends a
   recorded decision rather than making a new one. But that decision was about
   *spelling*, and vocabulary is a bigger claim. The honest cost: Italian
   (*semibreve, minima*) and French (*ronde, blanche, noire*) sit close to the
   British system, while German (*Viertelnote*) and Russian (*четвертная*) are
   fractional and map word-for-word onto the **American** names. So this actively
   moves German and Russian readers away from their own vocabulary. Still
   defensible — they are reading an untranslated English stopgap, and the real fix
   is `de.yml` — but it is a call to make. Reordering to `de: [de, en, en_GB]` is
   *not* a cheap escape: it would hand those four readers "neighbor", "meter" and
   "measure", undoing the previous story's entire deliverable.
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
