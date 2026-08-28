<!--
metadata:
  created_at:   2026-08-19T14:45:24-07:00
  activated_at: 2026-08-28T11:57:55-07:00
  planned_at:
  finished_at:
  updated_at:   2026-08-28T12:52:33-07:00
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

The ten units, in the key names the locale files use: `quadruple_whole`,
`double_whole`, `whole`, `half`, `quarter`, `eighth`, `sixteenth`,
`thirty_second`, `sixty_fourth`, `hundred_twenty_eighth`.

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

**The sweep's patterns will false-fire.** `NOTE_VOCABULARIES` works today
because *semibreve*/*crotchet*/*quaver* are technical-only words and the
American pattern anchors to `note|rest`. Neither property holds for the new
families: French *ronde*, *blanche* and *noire* are round, white and black;
Italian *minima* is "least"; Russian *целая* is "whole/entire" and *восьмая* is
any one-eighth fraction. The `note|rest` anchor does not transfer either, since
French, Italian and Spanish drop the noun — *une ronde*, not *une note ronde*.
Expect each new pattern to need its own escape hatch, and expect *noire* to
resist detection outright; budget for asserting that row some other way.

### Settle before filling anything in

**`note_values` and `rest_values` are unguarded today.** The spec's tree walks
span `style` and `rudiments.rhythmic_units` only, so in the other two groups an
`en_GB` key with no `en` counterpart leaks to `en_US` silently, and a partial
plural hash breaks the mid-chain locales without failing. That was right while
the walks guarded guide strings and nothing renders these yet — but this story
puts five locales into all three groups. Widen the walk before filling them in,
not after.

**`quadruple_whole` is not an identifier.** `rudiment/rhythmic_units.yml` names
the 4.0 unit `longa` in both dialects, so its snake_cased identifier is `longa`
and a lookup built the way `note_count_per_bar` builds one —
`rhythmic_units.#{unit}` — would miss it. `double_whole` matches its identifier;
this one does not. Nothing consumes these yet, so nothing is broken, but settle
it before five languages fill the key in. While deciding: `maxima` (8.0) and
`two_hundred_fifty_sixth` are in the data file and in none of the three groups.

## Acceptance Criteria

- A German, French, Italian, Russian or Spanish reader gets their own note values
  in every style string that names one
- All three groups — `rhythmic_units`, `note_values`, `rest_values` — carry all
  ten units in all five locales, with French's rests written as their own
  vocabulary rather than derived from its note names
- The spec's tree walks cover all three groups, so a key or a plural form missing
  from `note_values` or `rest_values` fails the way one missing from
  `rhythmic_units` does
- No locale inherits another language's note vocabulary — the dialect-purity
  sweep generalizes to cover every locale that carries its own words
- Every pluralized entry carries the complete set of forms for its locale, and
  Russian's four-form set is proven rather than assumed
- Russian's oblique cases live in the sentences that need them, not in the
  vocabulary hash
- `en` and `en_GB` render exactly as they did before, pinned by spec
