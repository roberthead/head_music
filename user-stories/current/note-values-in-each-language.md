<!--
metadata:
  created_at:   2026-08-19T14:45:24-07:00
  activated_at: 2026-08-28T11:57:55-07:00
  planned_at:
  finished_at:
  updated_at:   2026-08-28T12:31:07-07:00
-->

# Story: Note Values in Each Language

## Summary

AS a German, French, Italian or Russian reader of a style guideline
I WANT note values named as my own teacher names them
SO THAT I am not reading someone else's English for a word my language has

## Notes

`British Note Names` gave `en_GB` its own note vocabulary, and `de`, `fr`, `it`
and `ru` inherited it by routing through `en_GB` on their way to `en`. That was
decided deliberately and recorded there, but it is a stopgap: it hands four
readerships a fourth language's words.

**The terminology splits three ways, and English sits in two of them.**

| Family | Logic | Languages |
| --- | --- | --- |
| Fractional | arithmetic division of the whole | German, Russian, Dutch, Polish, Czech, Japanese, Turkish — and **American** English |
| Mensural-Latin | inherited from mensural notation | **British** English, Italian, Portuguese |
| Shape / colour | what the notehead looks like | French, Spanish, Catalan |

So no choice of English serves all four. British helps Italian, costs German and
Russian the word-for-word correspondence their own names have with the American
ones, and actively misleads French.

**The false friend is why this story exists rather than a chain reordering.**
French *croche* is the **eighth** note; English *crotchet* is the **quarter**.
They are cognates from the same hooked-note root that drifted apart by a factor
of two, so a French reader meets a familiar-looking word attached to the wrong
duration. Italian *croma* and Spanish *corchea* are eighths too — *croma* only
looks like the others, being usually traced to Greek *khrôma*, the blackened
noteheads, rather than the hook. Three families' lookalikes mean eighth and only
English's means quarter. No English is safe for them — only their own is.

| Locale (`rhythmic_units`) | whole | half | quarter | eighth |
| --- | --- | --- | --- | --- |
| `de` | Ganze | Halbe | Viertel | Achtel |
| `fr` | ronde | blanche | noire | croche |
| `it` | semibreve | minima | semiminima | croma |
| `ru` | целая | половинная | четвертная | восьмая |
| `es` | redonda | blanca | negra | corchea |

Checked and correct. German takes the nominalized short forms rather than
*ganze Note* / *Viertelnote*: they are what musicians say, and they capitalize
as nouns. The structure below resolves the rest of that question on its own —
the short form *is* `rhythmic_units` and the compound *is* `note_values`, so
German no longer has to choose between them.

**The vocabulary moved and grew before this story starts.** It lives at
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
*crotchet rest*, never a bare *crotchet*. Neither is a property of English.
Both questions come up again in each of the five, and neither answer follows
from the note-value table above.

**How each family builds the other six.** The four columns checked above are the
anchors; the rest derive, and the derivations are where a find-and-replace goes
wrong.

- **German** suffixes the fraction: *Sechzehntel*, *Zweiunddreißigstel*,
  *Vierundsechzigstel*, *Hundertachtundzwanzigstel*. Notes compound with
  *-note*, rests with *-pause*.
- **Russian** does the same with ordinals: *шестнадцатая*, *тридцать вторая*,
  *шестьдесят четвёртая*, *сто двадцать восьмая*; rests take *пауза*.
- **Italian** and **Spanish** modify the eighth: *semicroma*, *biscroma*,
  *semibiscroma*; *semicorchea*, *fusa*, *semifusa*, *garrapatea*. Rests are
  *pausa di X* and *silencio de X*.
- **French counts hooks**: *double croche* (16th), *triple croche* (32nd),
  *quadruple croche* (64th). A second trap on top of the *croche*/*crotchet*
  one: *double croche* is a **sixteenth**, not a doubled eighth.

**French rests are a separate vocabulary, not a derivation.** Every other
language here names the rest from the note. French does not: *pause* (whole),
*demi-pause* (half), *soupir* (quarter), *demi-soupir* (eighth), *quart de
soupir* (16th), *huitième de soupir* (32nd). A French `rest_values` built by
suffixing its note names would be wrong in every row, and it is the one group
that cannot lean on the note-value table at all.

**The extremes are where sources disagree.** `quadruple_whole`, `double_whole`
and `hundred_twenty_eighth` are rare enough that each language has competing or
missing names — German *Brevis* against *Doppelganze*, Spanish *cuadrada*
against *breve*, no confident Italian 128th. Derive the middle six; check these
three against a native source.

**The pin decides the shape of the work.** `render_template` resolves values in
the locale that carries *the sentence*
(`lib/head_music/style/guideline/wording.rb:62-63`), so a locale cannot get its
own note words by overriding `rhythmic_units` alone — the entry is never
consulted unless that locale also carries the sentence. This is the same finding
that settled `British Note Names`, and it means each locale needs the ~30 style
leaves that name a note value **on top of** its 30 vocabulary entries. The
vocabulary alone is never read.

That makes this the first story to give `de`, `fr`, `it` or `ru` **any** style
string at all. Everything in `HeadMusic::Style` is English fallback for them
today. Expect the first locale to cost more than the three that follow, and
expect it to surface whatever the fallback has been hiding.

**Watch the plural forms.** Russian pluralizes on `one`/`few`/`many`/`other`,
not `one`/`other`. `partial_plurals_in` in `guide_strings_spec.rb` currently
guards `en_GB` only, because `en_GB` was the only mid-chain locale; `de`, `fr`
and `it` are all leaves, but Russian's form set is genuinely different and the
Ruby fallback at `template.rb` exists precisely for this.

**Russian needs cases, not only plurals.** `%{rhythmic_unit}` is interpolated by
exactly one guideline — `note_count_per_bar`, three strings — where nominative
and accusative carry it: *одна половинная*, *две половинные*, *пять половинных*.
Everywhere else the word lands in an oblique case: "open the first bar with
minims" wants the instrumental *половинными*. Because each locale writes its own
leaves, Russian inlines the declined form directly in those ~29 sentences, and
`rhythmic_units` carries only the four forms `note_count_per_bar` needs. Do not
add a case dimension to the vocabulary hash for the sake of one template.

**Scope: five locales.** `es` is in. Spanish is shape-based like French, so its
vocabulary and its sweep pattern come nearly free once French is done, and the
*corchea*/*crotchet* false friend closes in the same pass. It differs from the
other four in one way worth remembering: `es: [es, en]` skips `en_GB`, so
Spanish reads American today and was never regressed by `British Note Names` —
it is here for the gap, not for a regression.

Five locales x (30 vocabulary entries + the ~30 leaves `British Note Names`
enumerated). Its census and
its noun-drop rules transfer directly. Its vocabulary-ownership sweep was
written in the general shape — *no locale carries note vocabulary from a family
it does not own* — so this story adds a vocabulary pattern per language and
moves the `de`, `fr`, `it` and `ru` rows of `LOCALE_NOTE_VOCABULARY` off
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
