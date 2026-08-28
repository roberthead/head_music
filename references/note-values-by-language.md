# Note Values by Language: Vocabulary Reference

The words each language uses for note values, rest values and bare rhythmic units, for the seven locales the gem ships. Intended as a reference for filling in `head_music.rudiments.note_values`, `rest_values` and `rhythmic_units` in `lib/head_music/locales/`.

Every cell is filled. Two languages leave their family partway down the table; §6 records where and why, because both break a mechanical fill-in.

---

## 1. The Three Naming Families

Note-value vocabulary splits three ways, and English sits in two of them. This is why no single English can serve as a fallback for the others.

| Family | Logic | Languages |
|---|---|---|
| **Fractional** | arithmetic division of the whole | German, Russian, Dutch, Polish, Czech, Japanese, Turkish — and **American** English |
| **Mensural-Latin** | inherited from mensural notation | **British** English, Italian, Portuguese |
| **Shape / colour** | what the notehead looks like | French, Spanish, Catalan |

**The false friend.** French *croche* is the eighth; English *crotchet* is the quarter. They are cognates from the same hooked-note root that drifted apart by a factor of two. Italian *croma* and Spanish *corchea* are eighths too — *croma* only looks like the rest, being usually traced to Greek *khrôma*, the blackened noteheads, rather than the hook. Three of the four lookalikes mean eighth; only English's means quarter.

---

## 2. Rhythmic Units

The bare unit word, with no noun attached.

| Key | `en` | `en_GB` | `de` | `fr` | `it` | `ru` | `es` |
|---|---|---|---|---|---|---|---|
| `longa` | quadruple whole | longa | Longa | longue | longa | лонга | longa |
| `double_whole` | double whole | breve | Brevis | brève | breve | бревис | breve |
| `whole` | whole | semibreve | Ganze | ronde | semibreve | целая | redonda |
| `half` | half | minim | Halbe | blanche | minima | половинная | blanca |
| `quarter` | quarter | crotchet | Viertel | noire | semiminima | четвертная | negra |
| `eighth` | eighth | quaver | Achtel | croche | croma | восьмая | corchea |
| `sixteenth` | sixteenth | semiquaver | Sechzehntel | double croche | semicroma | шестнадцатая | semicorchea |
| `thirty_second` | thirty-second | demisemiquaver | Zweiunddreißigstel | triple croche | biscroma | тридцать вторая | fusa |
| `sixty_fourth` | sixty-fourth | hemidemisemiquaver | Vierundsechzigstel | quadruple croche | semibiscroma | шестьдесят четвёртая | semifusa |
| `hundred_twenty_eighth` | hundred twenty-eighth | semihemidemisemiquaver | Hundertachtundzwanzigstel | quintuple croche | centoventottavo | сто двадцать восьмая | garrapatea |

**German** takes the nominalized short forms — *Ganze*, *Halbe*, *Viertel*, *Achtel* — rather than *ganze Note* / *Viertelnote*. They are what musicians say, and they capitalize as nouns.

**The two units above the whole keep their Latin names.** *Longa* and *brevis* are mensural terms every one of these languages borrowed rather than translated, each adapting the Latin to its own morphology — German keeps it whole (*Longa*, *Brevis*), French inflects it (*longue*, *brève*), Russian transliterates it (*лонга*, *бревис*), Italian and Spanish take it unchanged. The competing names reported by sources turn out to be variant spellings of one word rather than different words, which is why a single rule settles all ten cells.

**Vernacular alternatives, deliberately not used:** German *Doppelganze*; French *carrée*; Spanish *cuadrada*. Each is attested and each would be defensible; they are set aside so the row is decided by one principle rather than five independent judgements. A native reviewer who prefers the vernacular should flip the whole row, not one cell.

### 2.1 Derivation Rules

The four middle rows (whole through eighth) are the anchors. The rest follow a rule per family, and the rules are where a find-and-replace goes wrong.

- **German** suffixes the fraction: *Sechzehntel*, *Zweiunddreißigstel*, *Vierundsechzigstel*, *Hundertachtundzwanzigstel*. The rule keeps going indefinitely.
- **Russian** does the same with ordinals: *шестнадцатая*, *тридцать вторая*, *шестьдесят четвёртая*, *сто двадцать восьмая*.
- **Italian** and **Spanish** modify the eighth: *semicroma*, *biscroma*, *semibiscroma*; *semicorchea*, *fusa*, *semifusa*, *garrapatea*. Italian's rule stops at the 64th and the 128th changes system entirely — see §6.
- **French counts hooks**: *double croche* (16th), *triple croche* (32nd), *quadruple croche* (64th), *quintuple croche* (128th).

> **Trap.** *Double croche* is a **sixteenth**, not a doubled eighth. The multiplier counts flags, not duration — it runs the opposite direction from *double whole*.

---

## 3. Note Values

Whether the language attaches a noun to the unit word, and which.

| Locale | Noun | Quarter note |
|---|---|---|
| `en` | keeps *note* | quarter note |
| `en_GB` | **drops it** | crotchet |
| `de` | **splits** — see below | Viertelnote |
| `fr` | **drops it** | noire |
| `it` | **drops it** | semiminima |
| `it` (128th) | **drops it** | centoventottavo |
| `ru` | keeps *нота* | четвертная нота |
| `es` | **drops it** | negra |

Four of the seven make the note value identical to the rhythmic unit. German is the reason the two groups exist separately rather than one serving both: *Viertel* the unit, *Viertelnote* the note.

**German does not compound uniformly.** *Ganz* and *halb* are adjectives and stay separate words with the noun capitalized — *ganze Note*, *halbe Note*. *Viertel* and *Achtel* are nouns and compound — *Viertelnote*, *Achtelnote*, *Sechzehntelnote*. The split falls between the half and the quarter, and it applies to rests identically.

---

## 4. Rest Values

| Locale | Pattern | Quarter rest |
|---|---|---|
| `en` | *X rest* | quarter rest |
| `en_GB` | *X rest* — keeps the noun it dropped for notes | crotchet rest |
| `de` | **splits** — *ganze Pause*, *halbe Pause*, then compounds | Viertelpause |
| `fr` | **its own vocabulary**, except the breve | soupir |
| `it` | *pausa di X* | pausa di semiminima |
| `ru` | *X пауза* | четвертная пауза |
| `es` | *silencio de X* | silencio de negra |

### 4.1 French Rests Are Not Derived

Every other language here names the rest from the note. French does not — it has a separate vocabulary anchored on *pause* (whole) and *soupir* (quarter), halving in both directions:

| Key | French rest |
|---|---|
| `double_whole` | pause de brève |
| `whole` | pause |
| `half` | demi-pause |
| `quarter` | soupir |
| `eighth` | demi-soupir |
| `sixteenth` | quart de soupir |
| `thirty_second` | huitième de soupir |
| `sixty_fourth` | seizième de soupir |
| `hundred_twenty_eighth` | trente-deuxième de soupir |

Note the anchors differ from the note vocabulary: *pause* is the **whole** rest, while *croche* is the **eighth** note. A French `rest_values` built by suffixing the note names would be wrong in every row.

---

## 5. Plural Behaviour

`rhythmic_units` is pluralized wherever the sentence drops the noun and the word itself has to carry the count.

| Locale | Rule | Quarter, singular → plural |
|---|---|---|
| `en` | scalar; the *sentence* pluralizes | quarter → quarter |
| `en_GB` | `-s` | crotchet → crotchets |
| `de` | **invariant after a numeral** | Viertel → Viertel |
| `fr` | `-s`, and multi-word forms inflect **both** words | double croche → doubles croches |
| `it` | `-e` / `-i`, by gender | semiminima → semiminime; centoventottav**o** → centoventottav**i** |
| `ru` | four forms: `one`/`few`/`many`/`other` | четвертная / четвертные / четвертных |
| `es` | `-s` | negra → negras |

Only `en_GB` and `es` follow the English `-s` rule, so an inflector serves two of the seven. German's `one` and `other` are the same string — *zwei Halbe*, *vier Viertel* — which reads as a copy-paste slip and is not one.

---

## 6. Family Crossovers

Two languages leave their own family partway down the table. Both are places where deriving the next row from the last one produces a word that does not exist.

**Italian is mensural-Latin down to the 64th, then fractional.** *Croma*, *semicroma*, *biscroma*, *semibiscroma* — and then the modifier rule stops. The 128th is **centoventottavo**, literally "one hundred twenty-eighth": the fractional logic German and Russian use throughout, appearing in one row of an otherwise mensural language. Nothing was available to borrow — *fusa* and *semifusa* are Spanish's 32nd and 64th, and in mensural usage *fusa* was the eighth.

This carries a grammatical consequence. Italian's note words are feminine (*la semibreve*, *la croma*, plural *-e*); *centoventottavo* is masculine, plural *-i*. So the one row that changes family also changes gender, and pluralizes the other way. A find-and-replace over the Italian column gets this wrong in both directions.

**French rests are their own vocabulary — except the breve.** *Pause*, *demi-pause*, *soupir*, *demi-soupir* and the fractions of a *soupir* owe nothing to the note names. The breve rest breaks the pattern: **pause de brève**, derived from the note after all. So §4.1's rule holds from the whole downward and inverts at the top of the table. (Of the attested alternatives — *double-pause*, *bâton de pause*, *silence de brève* — *pause de brève* is the one chosen here; *bâton de pause* is properly the multi-measure rest.)

It is also the one French rest that depends on §2's Latin rule: *brève* rather than the vernacular *carrée*. Flipping that row to the vernacular would require *pause de carrée*, which is why the two decisions have to move together.

**Russian's mensural pair** (*бревис*, *лонга*) is transliterated rather than translated, which is normal for these two terms.

---

## 7. Mapping to head_music Architecture

The vocabulary lives under `head_music.rudiments`, not `head_music.style`: the words belong to the rudiment, and the style sentences borrow them.

| Group | Reached by | Shape |
|---|---|---|
| `rhythmic_units` | `Template.pluralize(..., scope: RUDIMENT_SCOPE)` from `NoteCountPerBar` | pluralized where the sentence drops the noun |
| `note_values` | not yet consumed | scalar |
| `rest_values` | not yet consumed | scalar |

Ten keys per group, largest first: `longa`, `double_whole`, `whole`, `half`, `quarter`, `eighth`, `sixteenth`, `thirty_second`, `sixty_fourth`, `hundred_twenty_eighth`.

**Keys are identifiers.** Every key is the snake_cased `american_name` from `lib/head_music/rudiment/rhythmic_units.yml`, so a lookup built the way `NoteCountPerBar` builds one always resolves. This is why the 4.0 unit is keyed `longa` and not `quadruple_whole`, even though its `en` value reads "quadruple whole note". The rule is additive-safe: `maxima` (8.0) and `two_hundred_fifty_sixth` can join the ten later without disturbing it.

**The pin.** `render_template` resolves values in the locale carrying *the sentence* (`lib/head_music/style/guideline/wording.rb:62-63`), so a locale gets its own note words only if it also carries the style strings that name them. Vocabulary alone is never read.

**The pin, restated for translators.** Filling in a locale's vocabulary is necessary but never sufficient. Until that locale also carries the style sentences that name a note value, every one of these words is unreachable.
