# Third-Species Counterpoint: Pedagogical Reference

A survey of third-species counterpoint guidelines from Fux (1725) through contemporary pedagogy, noting points of agreement and disagreement across sources. Intended as a reference for implementing style guidelines in the `head_music` gem.

---

## 1. Fundamental Premise

Third-species counterpoint sets **four quarter notes** in the counterpoint voice against each **whole note** in the cantus firmus, creating a 4:1 rhythmic ratio. This species introduces several concepts beyond second species:

1. **Richer metric hierarchy** -- four distinct beat levels (strong, weak, moderately strong, weak) vs. the two-level hierarchy of second species
2. **New dissonance types** -- the neighbor tone, double neighbor, and nota cambiata join the passing tone
3. **Greater melodic fluency** -- the faster rhythm demands even more stepwise motion and careful shaping
4. **Compound parallel-consonance checking** -- perfect consonances must be monitored between many more beat-position combinations

Third species is the primary vehicle for teaching melodic fluency and ornamentation within the species framework. Where second species introduces dissonance in its simplest form (the passing tone), third species expands the vocabulary of acceptable dissonant figures while maintaining strict control over their deployment.

---

## 2. Sources Surveyed

| Abbreviation | Source | Orientation |
|---|---|---|
| **Fux** | Johann Joseph Fux, *Gradus ad Parnassum* (1725); trans. Alfred Mann | Ostensibly Palestrina style; actually reflects 18th-century practice |
| **Albrechtsberger** | Johann Georg Albrechtsberger, *Grundliche Anweisung zur Composition* (1790) | Extended Fuxian method; teacher of Beethoven |
| **Cherubini** | Luigi Cherubini, *A Treatise on Counterpoint and Fugue* (1835) | French conservatory codification of Fuxian species |
| **Bellermann** | Heinrich Bellermann, *Der Contrapunkt* (1862) | Systematic Fuxian treatment; used by Schoenberg |
| **Schenker** | Heinrich Schenker, *Kontrapunkt* (1910/1922); trans. Rothgeb & Thym | Abstract voice-leading principles underlying tonal music |
| **Jeppesen** | Knud Jeppesen, *Counterpoint: The Polyphonic Vocal Style of the 16th Century* (1931) | Closest to actual Palestrina/Renaissance practice |
| **S&S** | Felix Salzer & Carl Schachter, *Counterpoint in Composition* (1969) | Schenkerian -- species as foundation for prolongational voice-leading |
| **Kennan** | Kent Kennan, *Counterpoint*, 4th ed. (1999) | 18th-century tonal counterpoint (Bach-oriented) |
| **Gauldin** | Robert Gauldin, *A Practical Approach to 16th-Century Counterpoint* / *18th-Century Counterpoint* | Separate treatments for Renaissance and Baroque styles |
| **A&S** | Edward Aldwell & Carl Schachter, *Harmony and Voice Leading*, 4th ed. | Tonal harmony with Schenkerian foundation |
| **Schubert** | Peter Schubert, *Modal Counterpoint: Renaissance Style*, 2nd ed. (2008) | Renaissance modal; draws directly on Renaissance treatises; divides rules into "hard" and "soft" |
| **Laitz** | Steven Laitz, *The Complete Musician*, 4th ed. | Comprehensive tonal theory with species counterpoint |
| **Kostka** | Stefan Kostka, *Materials and Techniques of Post-Tonal Music* / *Tonal Harmony* (with Payne/Almen) | Standard theory pedagogy with counterpoint chapters |
| **C&M** | Jane Piper Clendinning & Elizabeth West Marvin, *The Musician's Guide to Theory and Analysis* | Contemporary comprehensive theory |
| **BHN** | Thomas Benjamin, Michael Horvit, Robert Nelson, *Music for Analysis* / *Counterpoint in the Style of J.S. Bach* | Practical analysis and composition orientation |
| **OMT** | Open Music Theory (Shaffer, Hughes, Gotham, et al.) | Contemporary open-source online pedagogy |

---

## 3. Guideline Synthesis

### 3.1 Rhythmic Structure

**Universal agreement.** Four quarter notes against each whole note in the cantus firmus. The final measure is a whole note.

| Bar position | Rhythmic content |
|---|---|
| **First bar** | Four quarter notes, OR quarter rest followed by three quarter notes |
| **Middle bars** | Four quarter notes (no exceptions) |
| **Final bar** | One whole note |

**Source variations on the first bar:**
- **Fux, Bellermann, Schenker:** Prefer beginning with a rest on beat 1 followed by three quarter notes, mirroring second species.
- **OMT, Gauldin:** Allow either option. Four quarter notes are acceptable.
- **Cherubini:** Insists on beginning with a rest.
- **Swindale, Kennan:** Some preference for beginning on beat 2 (with rest).

### 3.2 Beginning

**Pitch (universal agreement):**
- Above the cantus firmus: begin on *do* (unison/octave) or *sol* (fifth).
- Below the cantus firmus: begin on *do* (unison/octave).

**Intervallic rule:** The first sounding note must form a perfect consonance (unison, fifth, or octave) with the cantus firmus, following first-species conventions for opening intervals.

**Unison:** Permitted at the opening only. If starting with a rest, the first sounding note (beat 2) may be a unison. If starting with four quarter notes, the downbeat of bar 1 may be a unison.

### 3.3 Beat Hierarchy

The 4:1 ratio creates a four-level metric hierarchy that governs dissonance placement:

| Beat | Metric weight | Consonance requirement |
|---|---|---|
| **Beat 1** (downbeat) | Strong | Must be consonant; never a unison (except at opening/closing) |
| **Beat 2** | Weak | May be consonant or dissonant |
| **Beat 3** | Moderately strong | Must be consonant (most sources) or may be dissonant with restrictions (some sources) |
| **Beat 4** | Weak | May be consonant or dissonant |

#### Beat 3 Controversy

This is one of the most significant areas of disagreement:

| Source | Beat 3 dissonance? | Conditions |
|---|---|---|
| **Fux** | Allowed (as passing tone) | Stepwise, same direction |
| **Bellermann** | Allowed | As passing tone |
| **Jeppesen** | Allowed sparingly | As passing or neighbor tone |
| **S&S** | Allowed sparingly | "Very sparingly in the 3rd quarter" for neighbor tones |
| **Schenker** | Restricted | Prefers consonance on beat 3 |
| **OMT (Gotham et al.)** | Allowed | Beats 2, 3, and 4 all permit dissonance |
| **OMT (Shaffer)** | Beat 3 consonant | Treats beat 3 as "moderately strong," consonance preferred |
| **Gauldin** | Generally consonant | Beat 3 should generally be consonant |
| **Kennan** | Allowed | As passing tone in stepwise motion |

**Practical consensus:** Most sources allow dissonance on beat 3 if it functions as a properly handled passing tone. The stricter sources (Schenker, some interpretations of Gauldin) treat beat 3 as a secondary strong beat requiring consonance.

### 3.4 Strong Beats (Downbeats)

**Universal agreement.** Every downbeat must be **consonant** with the cantus firmus. Permissible consonances: unison, third, fifth, sixth, octave, and compound equivalents. The perfect fourth is a dissonance in two-voice counterpoint (all sources agree).

**Preference.** Imperfect consonances (thirds, sixths) are preferred over perfect consonances (fifths, octaves, unisons) -- carried forward from first and second species.

**Consecutive downbeat constraints (OMT):**
- No three consecutive bars may begin with the same perfect interval (two in a row acceptable).
- No more than three consecutive bars should start with the same imperfect consonance.
- Consecutive downbeat pitches in the counterpoint must not form a dissonant melodic interval.

**Additional constraint (OMT):**
- If a downbeat contains a perfect fifth, neither beat 3 nor beat 4 of the previous bar may also be a fifth.
- If a downbeat contains an octave, beats 2, 3, and 4 of the previous bar should not be octaves.

### 3.5 Dissonance Treatment

All sources agree that dissonance in third species must follow specific, named patterns. The permitted dissonance types are:

#### 3.5.1 Dissonant Passing Tone

**Universal agreement.** The dissonant passing tone is carried forward from second species and remains the most basic dissonance type.

**Definition:** Fills in the space of a melodic third via stepwise motion. The note before and the note after the passing tone must both be consonant with the cantus firmus.

**Requirements:**
- Approached by step
- Left by step
- Approach and departure in the **same direction** (ascending or descending)
- May occur on beats 2, 3, or 4 (never beat 1)

**Two consecutive dissonant passing tones:**

| Source | Consecutive dissonant PTs? | Conditions |
|---|---|---|
| **Fux** | Not explicitly addressed | His examples show mostly single PTs |
| **OMT (Gotham)** | Allowed | P4-d5 or d5-P4 patterns; must be unidirectional stepwise; no downbeat dissonance |
| **S&S** | Allowed | In rapid stepwise passages |
| **Jeppesen** | Allowed | In Palestrina's practice |
| **Bellermann** | Allowed cautiously | |

**Practical consensus:** Two consecutive dissonant passing tones are acceptable when they fill in a larger stepwise passage, provided no dissonance falls on beat 1 and the passage is stepwise throughout.

#### 3.5.2 Dissonant Neighbor Tone (Auxiliary)

**Definition:** Ornaments a consonant tone by stepping away and stepping back to the original consonance. The neighbor note itself is dissonant with the cantus firmus.

**Requirements:**
- Approached by step from a consonance
- Left by step back to the same consonance (or to a different consonance by step in the opposite direction from the approach)
- The note before and after must be consonant

**Pattern example:** consonance - step up to dissonance - step down back to consonance (e.g., intervals 6-7-6 over the CF).

| Source | Dissonant neighbor? | Conditions |
|---|---|---|
| **Fux** | Not explicitly discussed | Neighbor figures appear in his examples |
| **Bellermann** | Allowed | "Enters by step and continues by step in the opposite direction" |
| **Jeppesen** | Allowed | Present in Palestrina's practice |
| **S&S** | Allowed | "Freely on 2nd and 4th quarters, very sparingly on 3rd quarter" |
| **Schenker** | Allowed cautiously | |
| **OMT** | Allowed | "Most effective on weak beats (2 or 4)" |
| **Gauldin** | Allowed | |
| **Kennan** | Allowed | |

**Key distinction from second species:** The dissonant neighbor tone is **not** permitted in second species but **is** permitted in third species. This is a major expansion of the dissonance vocabulary.

#### 3.5.3 Nota Cambiata (Changing Tone / Cambiata Figure)

The nota cambiata is the most distinctive ornamental figure in third-species counterpoint and the subject of the most detailed scholarly discussion.

**Fux's original formulation:** A five-note figure spanning two bars. The second note is dissonant, entered by step, and then -- uniquely -- **leaps a third** in the same direction to a consonance, after which the melody returns stepwise in the opposite direction.

**Two forms of the figure:**

| Form | Intervallic motion | Direction |
|---|---|---|
| **Descending** | Step down, leap down a 3rd, step up, step up | Net motion: step down from downbeat to downbeat |
| **Ascending** | Step up, leap up a 3rd, step down, step down | Net motion: step up from downbeat to downbeat |

**Structural diagram (descending form):**
```
Beat:    1    2    3    4    | 1
Note:    C    B    G    A    | B
         cons dis  cons cons | cons
         ↓s   ↓3rd ↑s   ↑s
```

**Requirements (universal):**
- Notes 1, 3, and 5 (the downbeats and the middle note) must be consonant with the CF
- Note 2 is dissonant, approached by step
- Note 2 leaps a third to note 3 (the only permitted leap from a dissonance in species counterpoint)
- Notes 3-4-5 are stepwise
- The surrounding stepwise motion minimizes the effect of the leap from dissonance

**Source variations:**

| Source | Treatment |
|---|---|
| **Fux** | Presents as a standard ornamental figure; descending form is the primary example |
| **Jeppesen** | Traces the figure to actual Palestrina practice; emphasizes its historical authenticity |
| **Schenker** | Treats as a legitimate but carefully controlled figure |
| **S&S** | Integrates into prolongational analysis |
| **OMT** | Presents both ascending and descending forms as standard |
| **Bellermann** | Includes as an "advanced" dissonant formation |
| **Kennan** | Presents primarily the descending form |
| **Schubert** | Includes as standard Renaissance practice |

**Historical note:** The nota cambiata is the only figure in species counterpoint where a leap from a dissonance is permitted. This exception is universally acknowledged. Later theorists sometimes restrict the figure to the descending form only, but Fux's own examples and Renaissance practice support both directions.

#### 3.5.4 Double Neighbor (Changing Tones / Double Auxiliary)

**Definition:** A four-note figure where beats 1 and 4 contain the same pitch (or the same consonance), and beats 2 and 3 are the upper and lower neighbors (or vice versa). Both beats 2 and 3 may be dissonant.

**Two orderings:**
```
Form A: C - D - B - C  (upper neighbor first)
Form B: C - B - D - C  (lower neighbor first)
```

**Requirements:**
- Beat 1 consonant with CF
- Beats 2 and 3 are the two neighbors (one step above, one step below)
- Beat 4 returns to the same pitch as beat 1
- A leap of a third occurs between beats 2 and 3 (this is permitted because the figure is understood as an ornament of a single tone)
- Motion from beat 3 to beat 4 should continue in the same direction as from beat 4 to the following downbeat (OMT)

| Source | Double neighbor? | Notes |
|---|---|---|
| **Fux** | Not explicitly named | Some scholars identify it in his examples |
| **Jeppesen** | Recognized | Present in Palestrina's music |
| **S&S** | Allowed | |
| **OMT (Gotham)** | Allowed | Detailed treatment with motion constraints |
| **Ars Nova** | Noted | "Not known in the Palestrina style" (disputed) |
| **Gauldin** | Allowed | |
| **Bellermann** | Recognized | As a legitimate formation |

**Controversy:** Some scholars question whether the double neighbor is truly a separate figure or merely a combination of upper and lower neighbor tones. The practical distinction is that in the double neighbor, the leap between beats 2 and 3 is permitted even though one or both may be dissonant -- a license that would not be available if they were analyzed as independent neighbor tones.

#### 3.5.5 Escape Tone (Echappee)

**Definition:** An unaccented dissonance approached by step and left by leap in the opposite direction. The escape tone "escapes" from stepwise motion via a leap.

**Pattern:** Consonance - step to dissonance - leap (opposite direction) to consonance.

| Source | Escape tone? | Notes |
|---|---|---|
| **Fux** | Not discussed | |
| **Jeppesen** | Not a standard Palestrina figure | Rare in 16th-century practice |
| **S&S** | Allowed | As an embellishment on beats 2 and 4 |
| **OMT (Shaffer)** | Allowed | Listed as a valid weak-beat dissonance |
| **Ars Nova** | Allowed | "Approached by step and left by downward leap" |
| **Kennan** | Allowed cautiously | |
| **Gauldin** | Mixed | Depends on style orientation (16th-c. vs. 18th-c.) |
| **Schenker** | Not standard | |
| **Schubert** | Not standard in Renaissance | |

**This is the most controversial dissonance type in third species.** Sources oriented toward Renaissance/Palestrina practice generally exclude it. Sources oriented toward 18th-century tonal counterpoint or contemporary pedagogy often include it. For a strict Fuxian implementation, the escape tone should be excluded or treated as a soft-rule violation.

#### 3.5.6 Appoggiatura (Accented Dissonance)

**Definition:** A dissonance on a strong beat, approached by leap and resolved by step.

| Source | Appoggiatura in third species? | Notes |
|---|---|---|
| **Fux** | No | Beat 1 must be consonant |
| **Jeppesen** | No | Not in Palestrina practice for this species |
| **S&S** | Mentioned | But only on beats 2 and 4 (effectively making it a different figure) |
| **Most sources** | No | Accented dissonances belong to fourth species (suspensions) and free counterpoint |

**Consensus:** The appoggiatura is not a standard third-species figure. Beat 1 must always be consonant. Some sources allow what they call "appoggiaturas" on beats 2 and 4, but these are better understood as approached dissonances that function like incomplete neighbor tones.

### 3.6 Ending / Cadence

**Universal agreement.** End with a clausula vera: stepwise contrary motion into a perfect consonance (unison or octave).

**Final bar:** Always a whole note on the tonic, forming a unison or octave with the cantus firmus.

**Penultimate bar:** Four quarter notes, with the last quarter note (beat 4) functioning as the leading tone or supertonic approach to the final note.

**Specific cadential formulas:**

| CF position | Penultimate bar approach | Scale degrees in CP | Interval pattern |
|---|---|---|---|
| CF below, CP above | CP's beat 4 = leading tone (*ti*) | ...6-7-8 | ...6th - M6th - 8ve |
| CF above, CP below | CP's beat 4 = supertonic (*re*) | ...4-3-1 or ...5-4-3m-1 | ...varies - m3rd - unison |

**Additional cadential options (Fux):**
- Above CF: Cambiata formula 8-7-5-6-8, or scale run 3-4-5-6-8
- Below CF: 3m-5-4-3m-1

**Penultimate note specifics:**
- If the CF has *re* (scale degree 2): the counterpoint's beat 4 should be *ti* (scale degree 7, raised if necessary)
- If the CF has *ti* (scale degree 7): the counterpoint's beat 4 should be *re* (scale degree 2)

### 3.7 Melodic Guidelines

These carry forward from first and second species with modifications appropriate to the faster rhythm:

#### 3.7.1 Stepwise Motion

**Universal agreement.** Third species should be **even more dominated by stepwise motion** than first or second species. The 4:1 ratio provides ample room for stepwise passage work, and the dissonance types (passing tone, neighbor tone) all require stepwise motion.

**Quantitative guidance:** While most sources do not give exact percentages, the expectation is that conjunct motion should constitute a large majority (roughly 75-85% or more) of melodic intervals.

#### 3.7.2 Melodic Shape and Climax

- **Single overall climax** that does not coincide with the climax of the cantus firmus.
- **One or two secondary climaxes** (local high points) permitted, given the greater number of notes (OMT, S&S).
- Avoid aimless scalar passages -- even stepwise motion should have direction and purpose.
- The line should have an overall arch or wave shape.

#### 3.7.3 Leap Treatment

- **All leaps must be melodic consonances** (m3, M3, P4, P5, m6 ascending only in 16th-c. style, P8).
- **Forbidden leaps:** tritone (d5/A4), M6 (in Renaissance style), 7ths, any augmented or diminished interval.
- **Recover from leaps** by moving stepwise in the opposite direction.
- **Prefer leaps within the bar** (e.g., beat 1 to beat 2, or beat 2 to beat 3) rather than across the barline (beat 4 to the next beat 1). This is a stronger preference in third species than in second species (OMT, S&S).
- **Avoid consecutive leaps** in the same direction. Most sources limit consecutive same-direction leaps to two at most, and only if they outline a consonant triad.
- **Large leaps** (P5 or greater) should be followed by stepwise motion in the opposite direction.

#### 3.7.4 No Repeated Notes

**Universal agreement.** Repeating the same pitch on consecutive quarter notes is **forbidden**, both within the bar and across the barline. This is even more critical in third species than in second species, as repetition at the quarter-note level completely arrests the forward motion the species is designed to cultivate.

#### 3.7.5 Range

- **Singable range** -- generally not exceeding a tenth (some sources allow up to a twelfth).
- Stay within a single voice register; avoid extreme register changes.

#### 3.7.6 Direction Changes

- **Frequent direction changes** are needed to maintain interest and avoid aimless scalar runs.
- However, the faster rhythm means that short ascending or descending runs (3-5 notes) are natural and acceptable.
- Avoid extended passages of more than about 5-6 notes in the same direction without a change.

### 3.8 Parallel Perfect Consonances

This is significantly more complex in third species than in first or second species because there are four attack points per bar that can form intervals with the cantus firmus.

#### 3.8.1 Core Rule

**Universal agreement.** Parallel perfect fifths and octaves are forbidden. The question is: between which beat positions must they be checked?

#### 3.8.2 Beat Positions to Check

| Pair | Check for parallels? | Source agreement |
|---|---|---|
| Beat 1 to next Beat 1 (downbeat to downbeat) | **Yes** | Universal |
| Beat 4 to next Beat 1 (across barline) | **Yes** | Universal |
| Beat 3 to next Beat 1 | **Yes** (most sources) | Strong consensus |
| Beats within the same bar (1-2, 2-3, 3-4) | **Yes** | Most sources |
| Beat 3 to Beat 3 across bars | Debated | Some sources |
| Beat 2 to Beat 2 across bars | Generally no | Most sources |

**Rothfarb (UCSB) rule:** "No parallel perfect consonances between the third quarter of one bar and the first quarter of the next." This is the most commonly cited cross-barline parallel check beyond the simple beat-4-to-beat-1 check.

**OMT (Gotham) rule:** If a downbeat contains a perfect fifth, neither beat 3 nor beat 4 of the previous bar can also be a fifth. If a downbeat contains an octave, beats 2, 3, and 4 of the previous bar should not be octaves.

**Practical synthesis:** The safest approach checks for parallel perfect consonances between any two notes where the second is on a beat of equal or greater metric weight (i.e., no parallel P5-P5 or P8-P8 from any beat to a subsequent equal-or-stronger beat). At minimum:
1. Consecutive downbeats (bar-to-bar)
2. Beat 4 to next beat 1 (across barline)
3. Beat 3 to next beat 1 (across barline, if beat 3 is treated as metrically significant)
4. Between consecutive notes within or across bars where the interval is the same perfect consonance

**Minimum separation rule (Swindale, some others):** Parallel perfect consonances require at least three notes of separation -- i.e., if a P5 occurs on one note, the next P5 must not occur until at least three notes later.

#### 3.8.3 Consecutive Downbeat Perfect Consonances

Following the same rule as in second species: no two consecutive downbeats should form the same perfect consonance (P5-P5 or P8-P8). Three consecutive downbeats with the same perfect consonance is universally forbidden.

### 3.9 Direct (Hidden) Fifths and Octaves

| Context | Treatment |
|---|---|
| Beat 4 to next Beat 1 (across barline) | Treated as in first species: **approach perfect consonances by contrary motion** (universal) |
| Within the bar | More lenient; stepwise approach in the upper voice generally suffices |
| Downbeat to downbeat | **Permitted** by most modern sources ("the effect is weakened by intervening notes") |

**OMT (Shaffer):** Direct/hidden fifths and octaves between successive downbeats are generally allowed in third species.

### 3.10 Unison Treatment

| Position | Treatment |
|---|---|
| Opening note | Permitted (unison or octave) |
| Final note | Permitted (unison or octave) |
| Interior downbeats (beat 1) | **Forbidden** (universal) |
| Interior weak beats (2, 3, 4) | Permitted when necessary for good voice-leading (OMT, S&S) |

**Rothfarb:** "The unison may occur anywhere in the bar except on the first quarter."

**Approach/departure:** When a unison occurs on a weak beat, step out of it (do not leap to or from a unison).

### 3.11 Voice Crossing and Overlap

| Source | Voice Crossing |
|---|---|
| **Fux** | Occasionally permits |
| **Schenker** | Strictly forbidden |
| **S&S** | Strictly forbidden |
| **Modern pedagogy** | Generally forbidden; rarely tolerated |

**Voice overlap** (approaching beyond the other voice's previous pitch without actually crossing) is universally discouraged.

### 3.12 Approach to Perfect Consonances

**Universal.** Perfect consonances on the downbeat must be approached by contrary motion from the preceding note (beat 4 of the previous bar).

**Rothfarb:** Perfect consonances on beat 1 may be approached "only by contrary motion."

This is a stricter formulation than second species: because there are four notes per bar, the beat-4-to-beat-1 motion into a perfect consonance must be contrary.

### 3.13 Contrary Motion Preference

**Universal.** Contrary motion is preferred throughout, as in all species. This preference is particularly important at barlines (beat 4 to beat 1), where first-species rules apply to the voice-leading.

---

## 4. Special Figures in Detail

### 4.1 Nota Cambiata

The nota cambiata is perhaps the most discussed ornamental figure in the counterpoint literature. Its treatment varies significantly across sources.

**Fux's original:** Presented as a natural ornamental pattern in the dialogue between Aloysius and Josephus. The descending form (step down, leap down a 3rd, step up, step up) is the primary example.

**Jeppesen's contribution:** Demonstrated that the figure is abundantly present in Palestrina's actual music, validating Fux's inclusion of it. Jeppesen provided statistical evidence of its frequency and catalogued its various forms.

**Schenker's treatment:** Analyzed the cambiata as a voice-leading phenomenon -- the leap from dissonance is "understood" as passing through an implied consonance. This connects the figure to Schenker's broader theory of structural levels.

**Modern pedagogy:** Most contemporary textbooks present both ascending and descending forms as standard figures, though some restrict the figure to the descending form (Kennan, for example).

**Key constraint:** The cambiata always spans exactly two bars (five notes: beat 1 through the next beat 1). The second note is the dissonant note, and the leap occurs from beat 2 to beat 3.

### 4.2 Double Neighbor (Changing Tones)

The double neighbor is a within-bar figure (four notes) where the counterpoint ornaments a single consonant pitch by moving to both its upper and lower neighbors before returning.

**Distinction from cambiata:** The double neighbor returns to its starting pitch on beat 4, whereas the cambiata progresses to a new pitch. The double neighbor is essentially a prolongation of a single tone; the cambiata is a progression between two tones.

**Motion constraint (OMT):** The direction of motion from beat 3 to beat 4 should be the same as from beat 4 to the following downbeat. This ensures smooth continuation out of the figure. The barline motion should be stepwise.

### 4.3 Summary of Dissonance Figures

| Figure | Beats | Dissonant beat(s) | Approach to dissonance | Departure from dissonance | Leap involved? |
|---|---|---|---|---|---|
| **Passing tone** | Any weak beat | 2, 3, or 4 | Step | Step (same direction) | No |
| **Neighbor tone** | Any weak beat | 2, 3, or 4 | Step | Step (opposite direction, back) | No |
| **Nota cambiata** | 1-2-3-4-1 | Beat 2 | Step | Leap of 3rd (same direction) | Yes (3rd from dissonance) |
| **Double neighbor** | 1-2-3-4 | Beats 2 and 3 | Step | Step (between 2-3: leap of 3rd) | Yes (3rd between neighbors) |
| **Escape tone** | Weak beat | 2 or 4 | Step | Leap (opposite direction) | Yes (from dissonance) |

---

## 5. Points of Agreement Across All Sources

1. **Beat 1 consonant.** The downbeat of every bar must be consonant with the cantus firmus.
2. **Four quarter notes per bar** (except the first and last bars).
3. **Final bar is a whole note** on the tonic, forming a unison or octave.
4. **Passing tones** are the most basic dissonance, approached and left by step in the same direction.
5. **Neighbor tones** are permitted (step away, step back).
6. **Nota cambiata** is permitted as a five-note figure with a leap of a third from a dissonance.
7. **No repeated notes** within or across the barline.
8. **Stepwise motion predominates** even more than in second species.
9. **Parallel perfect consonances** on consecutive downbeats are forbidden.
10. **Perfect consonances on beat 1** must be approached by contrary motion from beat 4.
11. **Clausula vera** cadence: stepwise contrary motion into a perfect consonance.
12. **Unisons forbidden on interior downbeats.**

## 6. Key Points of Disagreement

| Issue | Strict view | Permissive view |
|---|---|---|
| Beat 3 dissonance | Consonance required (Schenker, some Gauldin) | Dissonance allowed as PT/NT (Fux, OMT, S&S) |
| Escape tone | Not a valid figure (Fux, Jeppesen, Schubert) | Permitted on weak beats (S&S, OMT Shaffer, Kennan) |
| Double neighbor | Disputed as independent figure | Standard figure (OMT, S&S, Gauldin) |
| Ascending cambiata | Descending form only (Kennan) | Both directions (OMT, Jeppesen, Fux) |
| Voice crossing | Occasionally permitted (Fux) | Strictly forbidden (Schenker, S&S) |
| First bar beginning | Must begin with rest (Cherubini, Schenker) | Either option (OMT, Gauldin) |
| Parallel checking scope | Between any consecutive attacks (strictest) | Only at barlines and downbeats (most lenient) |

---

## 7. Mapping to head_music Architecture

The existing `head_music` style system groups guidelines into melody guides and harmony guides. Third species follows the same pattern. Below maps each guideline area to whether it is a **melody** concern (single-voice) or **harmony** concern (two-voice interaction), and notes where existing guidelines can be reused vs. where new guidelines are needed.

### 7.1 Melody Guidelines (ThirdSpeciesMelody)

| Guideline | Status | Notes |
|---|---|---|
| **AlwaysMove** | **Reuse** | No repeated notes; already checks for consecutive unisons |
| **ConsonantClimax** | **Reuse** | Still applies; secondary climaxes may need consideration |
| **Diatonic** | **Reuse** | Stay within key/mode |
| **EndOnTonic** | **Reuse** | Final note is tonic |
| **FrequentDirectionChanges** | **Reuse** | May need threshold adjustment for the greater note count |
| **LimitOctaveLeaps** | **Reuse** | |
| **MostlyConjunct** | **Reuse** (adjust threshold) | Even more stepwise than second species; threshold should be higher (~75-85%) |
| **PrepareOctaveLeaps** | **Reuse** | |
| **SingableIntervals** | **Reuse** | All leaps must be melodic consonances |
| **SingableRange** | **Reuse** | Generally within a tenth |
| **StartOnPerfectConsonance** | **Reuse** | First sounding note forms P1/P5/P8 with CF |
| **StepOutOfUnison** | **Reuse** | Step away from unisons |
| **StepUpToFinalNote** | **Reuse** | Leading tone or supertonic approach |
| **FourToOne** | **New** | Four quarter notes per whole note in CF; first bar allows rest + 3 quarters; final bar is whole note |

#### Guidelines Removed from Second Species

| Second-species guideline | Disposition for third species |
|---|---|
| **TwoToOne** | Replaced by **FourToOne** |

#### Potentially New Melody Guidelines

| Guideline | Priority | Description |
|---|---|---|
| **FourToOne** | Required | Enforces the 4:1 rhythmic structure: 4 quarter notes per bar (or rest + 3 in bar 1), whole note in final bar |
| **PreferLeapsWithinBar** | Soft | Prefer leaps within the bar rather than across the barline |
| **AvoidLongScalarRuns** | Soft | Avoid more than ~5-6 notes in the same direction without a change |
| **RecoverLargeLeaps** | Reuse existing | Already exists; step in opposite direction after large leaps |

### 7.2 Harmony Guidelines (ThirdSpeciesHarmony)

| Guideline | Status | Notes |
|---|---|---|
| **ApproachPerfectionContrarily** | **Reuse** | Approach perfect consonances by contrary motion; applies to beat-4-to-beat-1 motion |
| **AvoidCrossingVoices** | **Reuse** | |
| **AvoidOverlappingVoices** | **Reuse** | |
| **ConsonantDownbeats** | **Reuse** | Every beat 1 must be consonant |
| **NoParallelPerfectOnDownbeats** | **Reuse** | No P5-P5 or P8-P8 on consecutive downbeats |
| **NoParallelPerfectAcrossBarline** | **Reuse** (extend) | Currently checks weak beat to next downbeat; for third species, should check beat 3 and beat 4 to next beat 1 |
| **NoStrongBeatUnisons** | **Reuse** | No unisons on interior downbeats |
| **PreferContraryMotion** | **Reuse** | |
| **PreferImperfect** | **Reuse** | Prefer imperfect consonances on downbeats |

#### New Harmony Guidelines

| Guideline | Priority | Description |
|---|---|---|
| **ThirdSpeciesDissonanceTreatment** | **Required** | Replaces `WeakBeatDissonanceTreatment` from second species. Must validate: (1) passing tones (step in, step out, same direction), (2) neighbor tones (step away, step back), (3) nota cambiata (five-note figure with leap of 3rd from beat 2 dissonance), (4) double neighbor (both neighbors ornament same pitch). Optionally: (5) escape tone (step in, leap out opposite direction). |
| **NoParallelPerfectOnConsecutiveNotes** | **New** (or extend existing) | Check for parallel P5/P8 between any consecutive notes in the counterpoint voice against the CF, not just at barlines. This is more comprehensive than the existing barline-only check. |

#### Guidelines Carried From Second Species (Modified)

| Second-species guideline | Modification for third species |
|---|---|
| **WeakBeatDissonanceTreatment** | Replaced by **ThirdSpeciesDissonanceTreatment** (expanded to handle NT, cambiata, double neighbor, optionally escape tone) |
| **NoParallelPerfectAcrossBarline** | May need to be extended to check beats 3 and 4 to next beat 1, not just the last weak beat |

### 7.3 Proposed RULESET

#### ThirdSpeciesMelody RULESET

```ruby
RULESET = [
  HeadMusic::Style::Guidelines::AlwaysMove,
  HeadMusic::Style::Guidelines::ConsonantClimax,
  HeadMusic::Style::Guidelines::Diatonic,
  HeadMusic::Style::Guidelines::EndOnTonic,
  HeadMusic::Style::Guidelines::FourToOne,               # NEW
  HeadMusic::Style::Guidelines::FrequentDirectionChanges,
  HeadMusic::Style::Guidelines::LimitOctaveLeaps,
  HeadMusic::Style::Guidelines::MostlyConjunct,
  HeadMusic::Style::Guidelines::PrepareOctaveLeaps,
  HeadMusic::Style::Guidelines::SingableIntervals,
  HeadMusic::Style::Guidelines::SingableRange,
  HeadMusic::Style::Guidelines::StartOnPerfectConsonance,
  HeadMusic::Style::Guidelines::StepOutOfUnison,
  HeadMusic::Style::Guidelines::StepUpToFinalNote,
].freeze
```

#### ThirdSpeciesHarmony RULESET

```ruby
RULESET = [
  HeadMusic::Style::Guidelines::ApproachPerfectionContrarily,
  HeadMusic::Style::Guidelines::AvoidCrossingVoices,
  HeadMusic::Style::Guidelines::AvoidOverlappingVoices,
  HeadMusic::Style::Guidelines::ConsonantDownbeats,
  HeadMusic::Style::Guidelines::NoParallelPerfectAcrossBarline,
  HeadMusic::Style::Guidelines::NoParallelPerfectOnDownbeats,
  HeadMusic::Style::Guidelines::NoStrongBeatUnisons,
  HeadMusic::Style::Guidelines::PreferContraryMotion,
  HeadMusic::Style::Guidelines::PreferImperfect,
  HeadMusic::Style::Guidelines::ThirdSpeciesDissonanceTreatment,  # NEW
].freeze
```

### 7.4 New Guideline Specifications

#### FourToOne

**Purpose:** Enforce the 4:1 rhythmic structure of third-species counterpoint.

**Logic:**
```
for each bar aligned with a CF note:
  if first bar:
    accept 4 quarter notes OR (quarter rest + 3 quarter notes)
  elsif last bar (aligned with last CF note):
    accept 1 whole note
  else:
    accept exactly 4 quarter notes
  end
```

**Implementation notes:** Model after `TwoToOne`. Use `HeadMusic::Rudiment::RhythmicValue.get(:quarter)` and `:whole`. Check `notes_in_bar` and `rests_in_bar` for each bar. The CF bar alignment can be determined from `cantus_firmus.notes`.

#### ThirdSpeciesDissonanceTreatment

**Purpose:** Validate that all dissonant notes on weak beats follow one of the permitted dissonance figures.

**Logic:**
```
for each note on beat 2, 3, or 4 that is dissonant with the CF:
  if passing_tone?(note): OK
    - approached by step, left by step, same direction
  elsif neighbor_tone?(note): OK
    - approached by step, left by step, opposite direction (back to original pitch or to another consonance)
  elsif part_of_nota_cambiata?(note): OK
    - five-note figure: beat 2 dissonance, approached by step, left by leap of 3rd (same direction),
      followed by two steps in opposite direction; notes 1, 3, 5 consonant
  elsif part_of_double_neighbor?(note): OK
    - four-note figure: beats 1 and 4 same pitch, beats 2 and 3 are upper and lower neighbors
  else:
    MARK as violation
  end
```

**Implementation notes:** This is the most complex guideline. It should:
1. First identify all dissonant non-downbeat notes
2. For each, check the simplest patterns first (PT, NT)
3. For remaining unresolved dissonances, check if they participate in a cambiata or double neighbor figure
4. Mark any dissonance that does not fit a recognized pattern

**Escape tone option:** The escape tone could be included as an optional check (step in, leap out in opposite direction) or excluded for a strict Fuxian implementation. Consider making this configurable or implementing as a separate soft guideline.

### 7.5 Hard vs. Soft Classification (after Schubert)

**Hard rules** (fitness near 0 for violations):
- Consonant downbeats
- All weak-beat dissonances must fit a recognized pattern (PT, NT, cambiata, double neighbor)
- No parallel perfect consonances on consecutive downbeats
- No parallel perfect consonances across barline (beat 4 to beat 1)
- No repeated notes (AlwaysMove)
- Diatonic
- Singable intervals
- Four-to-one rhythmic structure (FourToOne)

**Soft rules** (penalty but not zero fitness):
- Prefer contrary motion
- Prefer imperfect consonances
- Mostly conjunct (higher threshold than second species)
- Prefer leaps within the bar
- Frequent direction changes
- Avoid interior unisons on strong beats
- Consonant climax
- Singable range

### 7.6 Implementation Priority

1. **FourToOne** -- straightforward adaptation of TwoToOne; required to validate basic rhythmic structure
2. **ThirdSpeciesDissonanceTreatment** -- the core new guideline; complex but essential; handles PT, NT, cambiata, double neighbor
3. **Verify existing guidelines** -- run second-species guidelines against third-species examples to confirm they generalize correctly (AlwaysMove, ConsonantDownbeats, NoParallelPerfectOnDownbeats, etc.)
4. **Adjust thresholds** -- MostlyConjunct may need a higher minimum conjunct portion for third species
5. **Optional: NoParallelPerfectOnConsecutiveNotes** -- more comprehensive parallel checking between all beat positions (beyond just downbeats and barlines)

---

## 8. Sources

### Primary Textbooks

- Fux, J.J. *Gradus ad Parnassum* (1725). Trans. Alfred Mann, *The Study of Counterpoint* (W.W. Norton, 1965).
- Albrechtsberger, J.G. *Grundliche Anweisung zur Composition* (1790).
- Cherubini, L. *A Treatise on Counterpoint and Fugue* (1835).
- Bellermann, H. *Der Contrapunkt* (1862; 4th ed. 1901).
- Schenker, H. *Kontrapunkt* (1910/1922). Trans. Rothgeb & Thym, *Counterpoint* (Musicalia Press, 2001).
- Jeppesen, K. *Counterpoint: The Polyphonic Vocal Style of the Sixteenth Century* (1931; Dover, 1992).
- Salzer, F. & Schachter, C. *Counterpoint in Composition* (Columbia UP, 1969).
- Kennan, K. *Counterpoint*, 4th ed. (Prentice Hall, 1999).
- Gauldin, R. *A Practical Approach to 16th-Century Counterpoint* (Waveland Press).
- Gauldin, R. *A Practical Approach to 18th-Century Counterpoint* (Waveland Press).
- Aldwell, E. & Schachter, C. *Harmony and Voice Leading*, 4th ed. (Cengage, 2011).
- Schubert, P. *Modal Counterpoint: Renaissance Style*, 2nd ed. (Oxford UP, 2008).
- Laitz, S. *The Complete Musician*, 4th ed. (Oxford UP, 2016).
- Kostka, S., Payne, D. & Almen, B. *Tonal Harmony*, 8th ed. (McGraw-Hill, 2018).
- Clendinning, J.P. & Marvin, E.W. *The Musician's Guide to Theory and Analysis*, 4th ed. (W.W. Norton, 2021).
- Benjamin, T., Horvit, M. & Nelson, R. *Counterpoint in the Style of J.S. Bach* (Schirmer).
- Swindale, O. *Polyphonic Composition* (Oxford UP, 1962).

### Online Pedagogy

- [Open Music Theory 2e -- Third-Species Counterpoint (Gotham et al.)](https://human.libretexts.org/Bookshelves/Music/Music_Theory/Open_Music_Theory_2e_(Gotham_et_al.)/02:_Counterpoint_and_Galant_Schemas/2.04:_Third-Species_Counterpoint)
- [Open Music Theory -- Third-Species Counterpoint (Shaffer/Hughes)](https://viva.pressbooks.pub/openmusictheory/chapter/third-species-counterpoint/)
- [Kris Shaffer -- Composing a Third-Species Counterpoint](https://openmusictheory.github.io/thirdSpecies.html)
- [Puget Sound Music Theory -- Third Species](https://musictheory.pugetsound.edu/mt21c/ThirdSpecies.html)
- [Rothfarb (UCSB) -- The Third Species of Counterpoint](https://rothfarb.faculty.music.ucsb.edu/courses/103/Third_Species(2v).html)
- [Ars Nova -- Third Species Counterpoint](https://www.ars-nova.com/cpmanual/thirdspecies.htm)
- [Ars Nova -- Dissonance Handling](https://www.ars-nova.com/cpmanual/dissonancerules.htm)
- [Ars Nova -- Escape Tones](https://www.ars-nova.com/cpmanual/escape.htm)
- [Any Old Music -- How to Write Third Species Counterpoint](https://anyoldmusic.com/how-to-write-third-species-counterpoint-a-comprehensive-guide/)
- [Iowa State -- Third Species Counterpoint Tutorial](https://iastate.pressbooks.pub/comprehensivemusicianship/chapter/9-4-third-species-counterpoint-tutorial/)
- [Irene Girton -- Species Counterpoint: 3rd Species](https://irenegirton.com/irene-montefiore-girton/species-counterpoint-online/species-counterpoint-3rd-species/)
- [Global Music Theory -- 3rd Species Counterpoint](https://globalmusictheory.com/3rd-species-counterpoint-rules-and-steps/)
- [ntoll.org -- Species Counterpoint](https://ntoll.org/article/species-counterpoint/)
