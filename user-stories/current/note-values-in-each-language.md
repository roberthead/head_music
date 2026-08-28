<!--
metadata:
  created_at:   2026-08-19T14:45:24-07:00
  activated_at: 2026-08-28T11:57:55-07:00
  planned_at:   2026-08-28T13:04:15-07:00
  finished_at:
  updated_at:   2026-08-28T13:10:55-07:00
-->

# Story: Note Values in Each Language

## Summary

AS a German, French, Italian, Russian or Spanish reader of a style guideline
I WANT note values named as my own teacher names them
SO THAT I am not reading someone else's English for a word my language has

## Notes

### Why no English serves them

`British Note Names` gave `en_GB` its own note vocabulary, and `de`, `fr`, `it`
and `ru` inherited it by routing through `en_GB` on their way to `en`. That was
decided deliberately and recorded there, but it is a stopgap: it hands four
readerships a fourth language's words.

The vocabulary splits three ways — fractional, mensural-Latin, and shape — and
English sits in two of them, so no choice of English serves all four inheritors.
British helps Italian, costs German and Russian the word-for-word correspondence
their own names have with the American ones, and actively misleads French:
*croche* is the **eighth**, where its cognate *crotchet* is the **quarter**. No
English is safe for them — only their own is.

**The words themselves live in `references/note-values-by-language.md`**, which
carries the full grid, the derivation rules, the plural behaviour and the
sources that disagree. This story is the decisions and the traps; that file is
the vocabulary.

German takes the nominalized short forms — *Ganze*, *Halbe*, *Viertel*,
*Achtel*. The structure below resolves the rest of that question on its own: the
short form *is* `rhythmic_units` and the compound *is* `note_values`, so German
no longer has to choose between them.

### What the vocabulary is now

**It moved and grew before this story starts.** It lives at
`head_music.rudiments` now, not `head_music.style`: the words belong to the
rudiment and the style sentences borrow them. And it is three groups of ten
units, not one group of three.

| Group | `en` | `en_GB` | Shape |
| --- | --- | --- | --- |
| `rhythmic_units` | quarter | crotchet | pluralized in `en_GB` — `note_count_per_bar` counts it |
| `note_values` | quarter note | crotchet | scalar |
| `rest_values` | quarter rest | crotchet rest | scalar |

The ten units, in the key names the locale files use: `longa`, `double_whole`,
`whole`, `half`, `quarter`, `eighth`, `sixteenth`, `thirty_second`,
`sixty_fourth`, `hundred_twenty_eighth`.

So the vocabulary side is **30 entries per language, not 3** — 150 across the
five. The sentence side is unchanged.

**Two asymmetries the English pair already shows, which every language answers
for itself.** British collapses `note_values` into `rhythmic_units` — a crotchet
is both the unit and the note — where American needs the noun to tell them
apart. And British keeps the noun for rests after dropping it for notes: a
*crotchet rest*, never a bare *crotchet*. Neither is a property of English: both
questions come up again in each of the five, and neither answer follows from the
vocabulary grid.

**Two traps in the grid, called out because they survive a careful reading.**
French *double croche* is a **sixteenth**, not a doubled eighth — the multiplier
counts flags, so it runs opposite to *double whole*. And French rests are a
separate vocabulary rather than a derivation: *pause*, *demi-pause*, *soupir*,
*demi-soupir*, anchored on the whole and the quarter where the note names anchor
on the eighth. A French `rest_values` built by suffixing its note names would be
wrong in every row. The reference marks both, along with the rows no source
confirms.

### What makes it expensive

**The pin decides the shape of the work.** `render_template` resolves values in
the locale that carries *the sentence*
(`lib/head_music/style/guideline/wording.rb:62-63`), so a locale cannot get its
own note words by overriding `rhythmic_units` alone — the entry is never
consulted unless that locale also carries the sentence. This is the same finding
that settled `British Note Names`, and it means each locale needs the ~30 style
leaves that name a note value **on top of** its 30 vocabulary entries. The
vocabulary alone is never read.

That makes this the first story to give any of the five **any** style string at
all — everything in `HeadMusic::Style` is English fallback for them today.
Expect the first locale to cost more than the four that follow, and expect it to
surface whatever the fallback has been hiding.

**The plural guard covers `en_GB` only.** `partial_plurals_in` in
`guide_strings_spec.rb` guards it because it was the only mid-chain locale;
`de`, `fr`, `it` and `es` are all leaves, so a partial hash there hurts only
themselves. Russian is the exception worth widening for: it pluralizes on
`one`/`few`/`many`/`other`, and the Ruby fallback at `template.rb` exists
precisely for a form set that different.

**Write the plural forms out; do not derive them.** The `en_GB` hashes are
load-bearing — collapsed to scalars, `note_count_per_bar` renders "Use four
crotchet in each middle bar", because I18n reads a scalar past the count and the
British sentence has dropped the noun that would otherwise carry the plural.
`en` depends on that same read-past behaviour, so `Template.pluralize` cannot
inflect scalars as a general rule without breaking English.

Nor should it inflect for one locale. ActiveSupport is already a dependency and
pluralizes all ten British names correctly, but `en_GB` and `es` are the only
two of the six where `-s` is right — German is invariant after a numeral,
Italian takes `-e`/`-i`, French inflects both words of a *double croche*, and
Russian has four forms. The reference tabulates all seven.

German's `one` and `other` will be the same string — *zwei Halbe*, *vier
Viertel*. That is correct, not a copy-paste slip.

**Russian needs cases, not only plurals.** `%{rhythmic_unit}` is interpolated by
exactly one guideline — `note_count_per_bar`, three strings — where nominative
and accusative carry it: *одна половинная*, *две половинные*, *пять половинных*.
Everywhere else the word lands in an oblique case: "open the first bar with
minims" wants the instrumental *половинными*. Because each locale writes its own
leaves, Russian inlines the declined form directly in those ~29 sentences, and
`rhythmic_units` carries only the four forms `note_count_per_bar` needs. Do not
add a case dimension to the vocabulary hash for the sake of one template.

### Scope

**Five locales.** `es` is in. Spanish is shape-based like French, so its
vocabulary and its sweep pattern come nearly free once French is done, and the
*corchea*/*crotchet* false friend closes in the same pass. It differs from the
other four in one way worth remembering: `es: [es, en]` skips `en_GB`, so
Spanish reads American today and was never regressed by `British Note Names` —
it is here for the gap, not for a regression.

Five locales x (30 vocabulary entries + the ~30 style leaves that name a note
value). `British Note Names` enumerated those leaves, and its census and its
noun-drop rules transfer directly. Its vocabulary-ownership sweep was written in
the general shape — *no locale carries note vocabulary from a family it does not
own* — so this story adds a vocabulary pattern per language and moves the `de`,
`fr`, `it` and `ru` rows of `LOCALE_NOTE_VOCABULARY` off
`:british` and the `es` row off `:american`, rather than rewriting the spec.
Those rows are where the inheritance decision lives; the sweep fails until they
move.

**The sweep needs rebuilding, but not for the reason assumed here.** The
worry was that French *ronde*, *blanche* and *noire* are ordinary words —
round, white, black — with no `note|rest` anchor available, since French drops
the noun. Measured against the 303-string English corpus, all three score zero
hits: they are fully detectable and need no escape hatch. What actually resists
attribution is the shared mensural root — *semibreve*, *breve* and *longa* are
spelled identically in `en_GB` and `it`, and *longa* in `es` and `de` as well.
Those rows have to be exempted by name. See the plan.

### Settled before starting

These three came up while the vocabulary was being extended. All are decided;
each lands before any locale is filled in, because each changes what "filled in
correctly" means.

**Widen the tree walks to all three groups — first.** They span `style` and
`rudiments.rhythmic_units` only, so in `note_values` and `rest_values` an
`en_GB` key with no `en` counterpart leaks to `en_US` silently and a partial
plural hash breaks the mid-chain locales without failing. Merge all three groups
into the tree the guards already read, and rename `guide_string_tree` — it no
longer walks only guide strings. The four existing guards then cover the new
groups unchanged: the en_GB-introduces-no-new-key comparison, the every-English-
unit-has-a-British-name check, the complete-plural-forms guard and its
walks-what-it-guards companion.

**Key by the identifier.** `quadruple_whole` becomes `longa`, and the `en` value
stays "quadruple whole note". The rule is that every key is the snake_cased
`american_name` from `rudiment/rhythmic_units.yml`, so a lookup built the way
`note_count_per_bar` builds one always resolves; `quadruple_whole` was the only
key breaking it. The rule is additive-safe: `maxima` (8.0) and
`two_hundred_fifty_sixth` can join the ten later without disturbing it.

**The sweep gains a data-level check; the prose scan stays.** Neither alone
covers both failures. Only the prose scan catches vocabulary hard-coded into a
*sentence* — the way `en_GB` writes "quavers" into
`allow_fifth_species_rhythmic_values` — while only the data check reaches the
mensural rows the prose scan cannot attribute, by comparing each locale's
vocabulary values against its own family. Build both; let the prose patterns
cover what they can and exempt the rest by name.

## Acceptance Criteria

**Ships in this story:**

- `quadruple_whole` no longer resolves to the whole note; `%{number}` reads in
  the reader's language in all five locales; Russian's plural forms are
  reachable and proven against counts above four
- A German reader gets their own note values in every style string that names
  one, with the declined form in the sentence and the nominative in the hash
- All three groups — `rhythmic_units`, `note_values`, `rest_values` — carry all
  ten units for German, keyed by the `RhythmicUnit` identifier
- The spec's tree walks cover all three groups, so a key or a plural form missing
  from `note_values` or `rest_values` fails the way one missing from
  `rhythmic_units` does
- No locale inherits another language's note vocabulary — the sweep pairs a
  prose scan with a data-level check, exempting the shared mensural rows by name
- `en`, `en_GB` and `en_US` render exactly as they did before, pinned against a
  snapshot taken before step 1
- The go/no-go for `fr`, `it`, `ru` and `es` is recorded against real German
  output

**When the remaining four land:** the same, per locale, with French's rests
written as their own vocabulary rather than derived from its note names, and
Russian's oblique cases in the sentences rather than the vocabulary hash.

## Implementation Plan

Planned 2026-08-28. Every figure below was re-run directly against the gem.
Claims that could not be reproduced were dropped rather than carried forward.

### Three defects block this, and none of them was in the story

Rendering a single locale surfaced all three. That is the argument for the
sequencing that follows: the first locale pays for infrastructure the other four
inherit.

**1. `quadruple_whole` does not merely miss — it resolves to the whole note.**
`RhythmicUnit::PATTERN` is a `Regexp.union`, and `"quadruple_whole"` contains
`"whole"`:

```
RhythmicValue.get(:quadruple_whole)  ->  "whole",  duration 1.0
RhythmicValue.get(:longa)            ->  "longa",  duration 4.0
```

A guideline configured with that key would analyse whole notes while rendering
"quadruple whole note". This upgrades the already-decided rename from tidiness
to a bug fix.

**2. `%{number}` is wrong in all five locales.** `Template.number_word` reaches
the `humanize` gem, which ships no Italian:

| locale | 1 / 2 / 3 / 4 | fault |
| --- | --- | --- |
| `de` | Eins / Zwei / Drei / Vier | capitalized mid-sentence |
| `fr` | un / deux / trois / quatre | wants feminine *une* |
| `it` | **one / two / three / four** | English, inside an Italian sentence |
| `ru` | один / два / три / четыре | wants feminine *одна*, *две* |
| `es` | uno / dos / tres / cuatro | wants feminine *una* |

Italian would render *"Scrivi four semiminime"* — the same class of failure as
the *"Write at least Acht notes."* bug the pin exists to prevent, arriving from
the other side. `spec/head_music/style/template_spec.rb:114-118` pins the
Italian behaviour as correct today and has to be inverted.

All four counted units are feminine in all five languages, so no gender
dimension is needed — the same reasoning that kept cases out of the Russian
vocabulary hash.

**3. Russian's four-form plurals are unreachable.** The gem loads
`I18n::Backend::Simple` with `Fallbacks` and no `Pluralization`, so a
`{one, few, many, other}` hash renders `other` for every count but one:

```
1=ONE  2=OTHER  3=OTHER  5=OTHER  11=OTHER  21=OTHER
```

Nothing raises, `fell_back_to_ruby` stays empty, and every existing guard stays
green. This is the one wrongness the suite cannot currently see, and the
acceptance criterion "proven rather than assumed" is unachievable until it is
fixed.

### Correction: the story is wrong about *noire*

Measured against the 303 distinct `en` + `en_GB` strings:

```
fr  /\bnoires?\b/    0      it  /\bminima\b/       0
fr  /\brondes?\b/    0      it  /\bcromas?\b/      0
fr  /\bblanches?\b/  0      GB  /\bsemibreves?\b/ 16
```

The shape words are fully detectable; *noire* needs no escape hatch. What
actually resists attribution is the **shared mensural root** — *semibreve*,
*breve* and *longa* are spelled identically in `en_GB` and `it`, and *longa* in
`es` and `de` too. Under per-family patterns this hides, because `en_GB` and
`it` both own mensural. Under per-language patterns those rows cannot be
attributed at all. Exempt them by name and let the data-level check cover them.

### Steps

Steps 1–5 are a gate: no locale data lands until they are green. Steps 6–10 are
one locale each and independent once the gate passes.

1. **Rename `quadruple_whole` to `longa`** in all three groups in `en.yml` and
   `en_GB.yml`; value stays "quadruple whole". Add `maxima` — it is a real
   identifier, so `RhythmicValue.get("maxima")` reaching `NoteCountPerBar`
   raises `MissingTemplate` today. Leave `two_hundred_fifty_sixth` out and
   record why. Add the guard that would have caught this: every vocabulary key
   names a real `RhythmicUnit` identifier. Do **not** rename the data file —
   `RhythmicUnit#name` is an identifier indexed by duration arithmetic, grading
   and MusicXML export.
2. **Fix `%{number}`.** Add `number_words` for counts 1–4 to the five locale
   files; `Template.number_word` consults them with `fallback: false` before
   falling through to `humanize`, leaving `en`/`en_GB`/`en_US` untouched. Invert
   `template_spec.rb:114-118`.
3. **Make Russian's plural forms reachable.** Add a `PLURAL_RULES` seam
   consulted inside the existing `I18n::InvalidPluralizationData` rescue, and
   ship Russian with `one`/`few`/`many` and no `other` — the absent `other` is
   what triggers the seam, and CLDR reaches `other` for `ru` only on floats.
   Split the rescue so a *known rule* is not recorded in `fell_back_to_ruby`,
   or `guide_strings_spec.rb:387` goes red on every Russian render.
4. **Widen the tree walks** to `%w[rhythmic_units note_values rest_values]` and
   rename `guide_string_tree`. Make `partial_plurals_in` an **exact-set** match
   with a `LOCALE_PLURAL_FORMS` map (`ru: %i[one few many]`) — a subset test
   cannot catch the Russian `other` trap, since the wrong hash is a superset.
   Justified today by `en_GB`'s 20 already-unguarded entries.
5. **Rebuild the sweep** as prose scan plus data-level check, per the settled
   decision, with the mensural rows exempted by name.
6. **German, as the pilot.** It is the only one of the five where `note_values`
   differs from `rhythmic_units`, so it exercises the two-group structure that
   `fr`/`it`/`es` collapse; its plural is invariant, the cheapest non-English
   shape.
7. **Russian**, second — the only consumer of step 3, best proven while that
   change is fresh.
8. **French**, then **Spanish**, then **Italian** last (it needs step 2 most and
   carries the `semibreve` collision).

Each locale is: 10 `rhythmic_units` with plural forms, the 26 literal sentences,
the `note_count_per_bar` family, 4 numerals, one row in each spec constant, and
two pinned sentences. Each must also decide its own `note_count_per_bar` shape —
`en` is a plural hash keeping the noun, `en_GB` is scalar dropping it, and that
is a per-language question rather than a precedent.

### Scope, measured

| | Count |
| --- | --- |
| `en` style leaves | 224 |
| …naming a note value | **32** (26 literal + 6 interpolated) |
| Distinct rendered strings per locale | 255 |
| …naming a note value | **38** |
| Unit/count pairs ever rendered | **4** — whole/1, half/2, quarter/3, quarter/4 |

Only four unit/count pairs are ever rendered, so the sweep reaches six of ten
`rhythmic_units` keys, none of the 20 `note_values`/`rest_values` keys, and
never Russian's `many`. A direct vocabulary-rendering example over all groups ×
units × locales is required; the prose guards cannot substitute.

**The Spanish leak no prose guard can see:** `es: [es, en]` means a missing
Spanish word falls through to a bare American *"quarter"*, which
`NOTE_VOCABULARIES[:american]` cannot match because it is anchored to
`note|rest`. Only the direct check catches it.

**Specs that break and need replacing rather than deleting:** `:136` (whole-
string language property), `:298` (the `es` half; keep the `en_US` assertion),
`:305` (the five now resolve `note_count_per_bar` to themselves but still route
through `en_GB` for spelling-only leaves), `:333`, and
`template_spec.rb:114-118`. Snapshot `strings_in(:en) + strings_in(:en_GB)`
before step 1 and assert against it throughout — nothing currently pins
`en_GB`'s `name`/`instruction` strings.

**No YAML anchors.** `YAML.load_file` raises `Psych::AliasesNotEnabled`, which
would kill the tree walks step 4 widens. Write the duplicate groups out.

### Decisions

**German is a gate, not just a first step.** Land steps 1–5 and German only.
Then read a real First Species guide rendered in German — 7 German sentences
among 44 English ones, with British note names still in the strings this story
does not touch — and decide about `fr`, `it`, `ru` and `es` with that in front
of you. The other four are conditional on that reading.

**All three groups ship.** `note_values` and `rest_values` are written for each
locale that lands, not deferred, so a later consumer finds the words waiting
rather than needing another translation pass per language. For German that is
30 entries; the reference document already carries them.

**Register: infinitive / nominal, in every locale.** *In Halben, Vierteln und
paarweise schrittweise Achteln auf unbetonten Zählzeiten schreiben.* This
sidesteps the formality axis entirely — no `Sie`/`du`, no `tú`/`usted` — which
matters because no spec can check a register choice and a later contributor
would otherwise "fix" it. It departs from English's imperative voice
deliberately; record that, or the first reviewer will read it as a translation
error.

> **Consequence: German declines too.** *Halben*, *Vierteln*, *Achteln* are
> dative plurals. The story attributes oblique cases to Russian alone; German
> has them under any phrasing, imperative or infinitive. So German follows the
> same rule already settled for Russian — the declined form is written into each
> sentence, and `rhythmic_units` carries the nominative only. This makes German
> a better pilot than assumed: it exercises the declension path as well as the
> two-group structure.

**Numerals live at `head_music.number_words`**, top level beside
`head_music.locales`. A numeral is neither a rudiment nor a style string, and
anything later needing a spelled-out number can reach it without importing
style vocabulary.

### Still open

1. **The `(check)` rows.** Omit an unresolved key rather than guessing — a
   fallback arrives as a bare American word with no head noun, invisible to the
   sweep by construction. Make omissions an explicit allowlist so the guard
   becomes the ledger. Italian's `hundred_twenty_eighth` likely never resolves.
2. **Who reviews the German, and later the Russian?** The declined forms are the
   highest-risk data here and the only part no spec can check. The pilot is the
   cheap moment to find that reviewer, while it is one language rather than five.
