<!--
metadata:
  created_at:   2026-08-19T14:45:24-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-08-19T14:45:24-07:00
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

**French is why this story exists rather than a chain reordering.** French
*croche* is the **eighth** note; English *crotchet* is the **quarter**. They are
cognates from the same hooked-note root that drifted apart by a factor of two,
so a French reader meets a familiar-looking word attached to the wrong duration.
No English is safe for French — only French is.

| Locale | whole | half | quarter | eighth |
| --- | --- | --- | --- | --- |
| `de` | ganze Note | halbe Note | Viertelnote | Achtelnote |
| `fr` | ronde | blanche | noire | croche |
| `it` | semibreve | minima | semiminima | croma |
| `ru` | целая | половинная | четвертная | восьмая |

Verify each against a native source before shipping — this table is a starting
point, not an authority, and the whole point of the story is that borrowed
vocabulary is what it is replacing.

**The pin decides the shape of the work.** `render_template` resolves values in
the locale that carries *the sentence*
(`lib/head_music/style/guideline/wording.rb:62-63`), so a locale cannot get its
own note words by overriding `rhythmic_units` alone — the entry is never
consulted unless that locale also carries the sentence. This is the same finding
that settled `British Note Names`, and it means each locale needs the ~30 style
leaves that name a note value, not 3 vocabulary entries.

That makes this the first story to give `de`, `fr`, `it` or `ru` **any** style
string at all. Everything in `HeadMusic::Style` is English fallback for them
today. Expect the first locale to cost more than the three that follow, and
expect it to surface whatever the fallback has been hiding.

**Watch the plural forms.** Russian pluralizes on `one`/`few`/`many`/`other`,
not `one`/`other`. `partial_plurals_in` in `guide_strings_spec.rb` currently
guards `en_GB` only, because `en_GB` was the only mid-chain locale; `de`, `fr`
and `it` are all leaves, but Russian's form set is genuinely different and the
Ruby fallback at `template.rb` exists precisely for this.

**Scope.** Four locales x the ~30 leaves `British Note Names` enumerated. Its
census, its noun-drop rules and its dialect-purity sweep all transfer; the sweep
generalizes from "no American words in `en_GB`" to "no borrowed words in any
locale that has its own".

Worth deciding first: whether `es` joins. Spanish is shape-based
(*redonda, blanca, negra, corchea*) and shares the *corchea*/*crotchet* false
friend, but `es: [es, en]` skips `en_GB`, so Spanish reads American today and is
not regressed by `British Note Names`. It has the same underlying gap and none
of the urgency.

## Acceptance Criteria

- A German, French, Italian or Russian reader gets their own note values in every
  style string that names one
- No locale inherits another language's note vocabulary — the dialect-purity
  sweep generalizes to cover every locale that carries its own words
- Every pluralized entry carries the complete set of forms for its locale, and
  Russian's four-form set is proven rather than assumed
- `en`, `en_GB` and `es` render exactly as they did before, pinned by spec
- The decision about whether `es` is in scope is recorded
