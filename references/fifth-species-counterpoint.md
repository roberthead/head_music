# Fifth-Species Counterpoint: Pedagogical Reference

A survey of fifth-species (florid) counterpoint guidelines from Fux (1725) through contemporary pedagogy, noting points of agreement and disagreement across sources. Intended as a reference for implementing style guidelines in the `head_music` gem.

---

## 1. Fundamental Premise

Fifth species, universally called "florid counterpoint," combines all four previous species into a single contrapuntal line set against a cantus firmus in whole notes. It is the closest that species counterpoint comes to free composition.

The florid line may use:

- Whole notes (1st species behavior) -- reserved for the final bar only
- Half notes (2nd species behavior)
- Quarter notes (3rd species behavior)
- Tied half notes across barlines (4th species behavior / suspensions)
- Pairs of eighth notes (new to 5th species)

No new contrapuntal "rules" are introduced per se -- the student combines what has been learned from all previous species, with the addition of eighth-note figures and embellished suspensions. The challenge is primarily aesthetic: achieving what Fux calls "liveliness of movement, and beauty and variety of form."

### Historical Perspectives

**Fux (1725):** Describes fifth species with the famous metaphor: "As a garden is full of flowers, so this species of counterpoint should be full of excellences of all kinds." The student combines all previously learned techniques, with some new ornamental possibilities.

**Schenker (1910/1922):** Reframes fifth species as the culmination of strict counterpoint, where the concept of *diminution* -- the decoration of a simple structural progression by more elaborate surface motion -- becomes fully manifest. By decorating a basic progression (e.g., a chain of 7-6 suspensions) with intervening notes, the progression is "prolonged" through time.

**Jeppesen (1931):** Grounds fifth species in actual Palestrina practice, noting that Renaissance music is fundamentally florid counterpoint -- the earlier species are pedagogical abstractions extracted from it. Fifth species is therefore the most "authentic" species.

**Salzer & Schachter (1969):** Extend Schenker's view: fifth species demonstrates how the voice-leading principles of the simpler species operate together in prolongational contexts. The mixture of species must serve the goal of a coherent, directed melodic line with clear harmonic underpinning.

**Schubert (2008):** Treats fifth species under "Mixed Values," emphasizing the distinction between "hard" rules (never violated) and "soft" rules (stylistic preferences). Draws directly on Renaissance treatises.

**Gauldin:** Takes a "non-species" or "direct" approach in his 16th-century text, teaching florid writing early with "black notes" (shorter values) alongside "white notes" (longer values), rather than strictly following the species progression.

**Open Music Theory (Gotham/Shaffer):** Frames fifth species as "combining the tricks developed in species 1-4 with only a few additions," noting that "the challenge is to balance not only types of consonance but also types of counterpoint."

---

## 2. Sources Surveyed

| Abbreviation | Source | Orientation |
|---|---|---|
| **Fux** | Johann Joseph Fux, *Gradus ad Parnassum* (1725); trans. Alfred Mann | Ostensibly Palestrina style; actually reflects 18th-century practice |
| **Schenker** | Heinrich Schenker, *Kontrapunkt* (1910/1922); trans. Rothgeb & Thym | Abstract voice-leading principles underlying tonal music |
| **Jeppesen** | Knud Jeppesen, *Counterpoint: The Polyphonic Vocal Style of the 16th Century* (1931) | Closest to actual Palestrina/Renaissance practice |
| **S&S** | Felix Salzer & Carl Schachter, *Counterpoint in Composition* (1969) | Schenkerian -- species as foundation for prolongational voice-leading |
| **Kennan** | Kent Kennan, *Counterpoint*, 4th ed. (1999) | 18th-century tonal counterpoint (Bach-oriented) |
| **Gauldin** | Robert Gauldin, *A Practical Approach to 16th-Century Counterpoint* / *18th-Century Counterpoint* | Separate treatments for Renaissance and Baroque styles |
| **Schubert** | Peter Schubert, *Modal Counterpoint: Renaissance Style*, 2nd ed. (2008) | Renaissance modal; draws directly on Renaissance treatises |
| **OMT** | Open Music Theory (Shaffer, Hughes, Gotham, et al.) | Contemporary open-source online pedagogy |

---

## 3. Guideline Synthesis

### 3.1 Rhythmic Structure

#### Permitted Rhythmic Values

**Universal agreement.** The counterpoint line may use whole notes, half notes, quarter notes, tied half notes across barlines, and pairs of eighth notes.

| Value | Species origin | Constraints |
|---|---|---|
| Whole note | 1st species | Final bar only; forbidden in the body of the exercise |
| Half note | 2nd species | Primary structural value; carries the fundamental voice-leading |
| Quarter note | 3rd species | Ornamental; must follow 3rd-species dissonance rules |
| Tied half note | 4th species | Creates suspensions; preparation on beat 3, suspension on beat 1 |
| Eighth-note pair | New to 5th species | Always in pairs, only on weak beats, only stepwise |

**Dotted notes** are not used in strict species counterpoint (S&S, Ars Nova, ntoll.org all concur). The dotted rhythm is considered characteristic of later styles.

#### Eighth Notes

Eighth notes are the only genuinely new rhythmic element in fifth species. All sources agree on tight constraints:

- Always occur in **pairs** (never singly)
- Only on **weak beats**: the 2nd or 4th quarter of the bar
- Only **one pair per bar**
- Must be **approached and left by step**
- Should not be overused

| Source | Eighth-note constraints |
|---|---|
| **Fux** | Introduces eighth notes between 4th and 5th species; always in pairs on weak beats |
| **S&S** | Pairs only; on weak beats; stepwise only; sparingly |
| **Ars Nova** | "Only in pairs, and in common time these can occur only on the second and fourth beats" |
| **ntoll.org** | "Do not over use quaver figures. Do not use them more than once every three bars" |
| **Girton** | "Only one pair per bar; care should be taken not to overuse this note value" |

**Eighth-note figures (two types):**

1. **Neighbor-note figure:** step away from a consonant note and step back (e.g., C-D-C or C-B-C)
2. **Passing-note figure:** connecting two consonant notes a third apart by stepwise motion

#### How Rhythmic Values Combine Within Bars

**S&S** provide the most systematic treatment:

- The "most natural figuration" places longer values on stronger metric positions and shorter values on weaker positions (e.g., half note on beat 1, two quarters on beats 3-4)
- A quarter note beginning a half note on the 2nd quarter "draws too much attention to a single note, halting the flow"
- Quarter-quarter-half within a bar is problematic because the half note after two short notes "constitutes a static point in the discourse"

**Key rhythmic constraints across sources:**

| Pattern | Permitted? | Source |
|---|---|---|
| Half + two quarters (h q q) | Yes | S&S, universal |
| Two quarters + half (q q h) | Only if the half ties forward | ntoll.org, S&S |
| Quarter + half + quarter (q h q) | No -- excessive syncopation | Ars Nova, Hansen Media |
| Half + half (h h) | Yes -- 2nd species behavior | Universal |
| Four quarters (q q q q) | Yes -- 3rd species behavior | Universal |

**Syncopation constraint (Girton):** "Syncopation only occurs at the half-note level of meter. Quarter-note syncopation (beginning a half note on the second quarter of a measure, or tying a quarter from the fourth beat of one measure over the barline to another quarter on the first beat of the next measure) is not permitted."

### 3.2 Beginning

**Universal agreement.** Begin with a perfect consonance, after a rest.

**Pitch constraints (carried from 1st species):**
- Counterpoint above CF: begin on unison, fifth, or octave
- Counterpoint below CF: begin on unison or octave

| Source | First bar requirements |
|---|---|
| **Fux** | Same conventions as 4th species: half rest, then half note |
| **ntoll.org** | "The opening note of fifth species counterpoint should use the same conventions as the fourth species starting note" |
| **Ars Nova** | "Begin with a rest, but it can be either a half or a quarter rest" |
| **Girton** | "Begin slowly with a suspension figure" -- half rest followed by a half note |
| **Hansen Media** | Beginning can use any species, but preference for starting with 2nd or 4th species behavior |

**Avoid beginning with rapid notes** (Ars Nova: "Avoid beginning a passage with rapid notes, unless the first note is offbeat"). The line should begin with longer values and gradually introduce shorter ones.

### 3.3 Beat Hierarchy and Consonance Requirements

The metric hierarchy is the same as in 3rd species:

| Beat | Metric weight | Consonance requirement |
|---|---|---|
| **Beat 1** (downbeat) | Strong | Must be consonant, OR a properly prepared suspension |
| **Beat 2** | Weak | May be consonant or dissonant |
| **Beat 3** | Moderately strong | Generally consonant; dissonance permitted as passing tone (see 3rd-species beat-3 controversy) |
| **Beat 4** | Weak | May be consonant or dissonant |

The only exception to beat-1 consonance is a properly prepared suspension: a pitch that was consonant on the previous beat 3, held (tied) across the barline, and now dissonant against the new CF note.

### 3.4 Dissonance Treatment

Fifth species inherits all dissonance types from the previous four species. The key principle is that each dissonance must follow the rules of the species from which it derives.

#### 3.4.1 Passing Tones (from 2nd species)

**Universal agreement.** Approached by step, left by step in the same direction, on a weak beat. May occur on the 2nd or 4th quarter of the bar. May also occur on the 3rd quarter if the surrounding context is stepwise (see 3rd-species beat-3 controversy).

#### 3.4.2 Neighbor Tones (from 3rd species)

**Universal agreement.** Approached by step from a consonance, returns by step to the original pitch (or steps to a different consonance in the opposite direction). On weak beats (2nd or 4th quarters preferred).

#### 3.4.3 Nota Cambiata (from 3rd species)

**Universal agreement.** The characteristic five-note figure where the 2nd note is dissonant, entered by step, then leaps a third in the same direction to a consonance, followed by stepwise return. This is the only figure in species counterpoint where a leap from a dissonance is permitted. Both ascending and descending forms are accepted.

#### 3.4.4 Suspensions (from 4th species)

**Universal agreement on the three-phase structure:**

1. **Preparation:** consonant, on a weak beat (beat 3), half note or longer
2. **Suspension:** same pitch held (tied) into the strong beat (downbeat), where it becomes dissonant against the new CF note
3. **Resolution:** step downward to a consonance on the next weak beat (beat 3)

**Upper voice suspensions:** 7-6 (most common), 4-3, 9-8 (used with care), 2-1 (rare)

**Lower voice (bass) suspensions:** 2-3 (primary), 4-5 (very rare)

**Resolution is always by step downward** -- upward resolution is not permitted in strict species counterpoint.

#### 3.4.5 Embellished Suspensions (new to 5th species)

This is the most significant new element in fifth species. The basic suspension structure (preparation on beat 3, suspension on beat 1, resolution on beat 3) is preserved, but the surface between suspension and resolution may be ornamented. Sources describe several types:

**Type 1 -- Anticipated resolution.** The resolution arrives a quarter note early (on beat 2 rather than beat 3). The suspension occupies beat 1 as a quarter note, the resolution appears on beat 2, then is sustained as a half note on beat 3.

```
Beat:    1       2       3       4
         susp    resol   (held)  ...
         q       q       h
```

**Type 2 -- Anticipated resolution with eighth-note neighbor.** Same as Type 1, but the early resolution on beat 2 is decorated with an eighth-note lower neighbor-note figure.

```
Beat:    1       2       3       4
         susp    res LN  (held)  ...
         q       ee      h
```

**Type 3 -- Escape tone (echappee) embellishment.** The suspension is on beat 1, followed on beat 2 by a consonant quarter note that steps *up* from the suspended pitch, then the resolution steps down to the expected note on beat 3.

```
Beat:    1       2       3       4
         susp    step up resol   ...
         q       q       h
```

**Type 4 -- Consonant leap from suspension.** The suspension on beat 1 is "temporarily abandoned" with a descending consonant leap to a consonant note on beat 2, then leaps back up to the expected resolution on beat 3. Both the leapt-to note and the resolution must be consonant with the CF.

**Type 5 -- Delayed resolution (Fux).** The resolution is delayed by one intervening consonant note. "In Fifth Species you'll be allowed to delay by one note the resolution of a suspension... The intervening note must be a concord" (Ars Nova, paraphrasing Fux).

| Source | Embellished suspension types discussed |
|---|---|
| **Fux** | Types 1-5 (introduces all between 4th and 5th species) |
| **Girton** | Types 1, 2, 3, 4 (detailed treatment with notation examples) |
| **OMT** | Types 1, 2, and eighth-note embellishments |
| **Ars Nova** | Types 1, 3, 4, and delayed resolution |
| **ntoll.org** | Types 1, 3, 4 |
| **S&S** | Ornamental treatment with examples |

**Critical constraint (Girton):** "Just as in 4th species, both the suspension's preparation and its resolution occur in the middle of the measure, on the third quarter note, whether or not the resolution is anticipated, or the suspension figure otherwise embellished, on the measure's second quarter note." The structural framework of preparation on beat 3, suspension on beat 1, resolution on beat 3 is preserved even when embellishments alter the surface.

#### 3.4.6 Eighth-Note Dissonances

Eighth notes follow the same dissonance rules as quarter notes: if dissonant with the CF, they must function as passing tones or neighbor tones (approached and left by step). Since eighth notes are always stepwise, this is inherently satisfied when they are part of a neighbor-note or passing-note figure.

### 3.5 Suspension Rules in Florid Context

**Preparation requirements (universal):**
- Must be a consonance
- Must begin on a weak beat (beat 3)
- Must be at least a half note in duration
- The preparation and the suspended pitch are the same pitch (tied across the barline)

**Suspension requirements:**
- Occupies the downbeat (strong beat)
- Dissonant with the CF (if consonant, it is a syncopation, not a suspension)
- Duration: in pure 4th species, a half note; in 5th species, may be shortened to a quarter note when the resolution is anticipated (embellished suspensions)

**Resolution requirements:**
- Always by step downward
- Must arrive on a consonance
- Structurally occurs on beat 3, even if surface embellishment places notes on beat 2

**Tied note proportions (Ars Nova):** "When you tie a note forward in the Fourth Species style, you should make the second note half the value of the first except at a final cadence." In fifth species, this means a tied whole note across the barline should have the second portion as a half note.

### 3.6 Ending / Cadence

**Universal agreement.** End with a clausula vera: stepwise contrary motion into a perfect consonance (unison or octave).

**Final bar:** Always a whole note on the tonic, forming a unison or octave with the cantus firmus.

**Penultimate bar:** Uses a 4th-species suspension figure. The line should slow rhythmically as it approaches the cadence.

| Source | Penultimate bar requirements |
|---|---|
| **Fux** | Same conventions as 4th species: suspension into the leading tone, resolving to tonic |
| **ntoll.org** | "The penultimate and final bars should also use the same conventions as the fourth species" |
| **Girton** | "The last two measures should emulate 4th species by providing a suspension into the leading tone in the penultimate measure" |

**Specific cadential formulas:**

| CF position | Suspension | Resolution | Final |
|---|---|---|---|
| CF below, CP above | 7th on downbeat | 6th on beat 3 (raised leading tone) | Octave |
| CF above, CP below | 2nd on downbeat | 3rd on beat 3 | Unison |

**Whole notes forbidden in the body:** Whole notes are reserved for the final bar only. ntoll.org: "Do not make use of semibreves in any part of the counterpoint except the last bar. To do so would cause the counterpoint to sound empty and dilatory."

### 3.7 Rhythmic Variety

**Universal agreement.** Fifth species requires a mixture of note values. No single species should dominate.

| Source | Variety requirements |
|---|---|
| **Ars Nova** | "Try to have as much variety as possible within the limits of the first four species" |
| **ntoll.org** | "A liberal mixture of all the previous species will produce the best results" |
| **Hansen Media** | "No more than two consecutive measures with identical rhythmic patterns" |
| **Girton** | "Try to avoid rhythmic sequences, or the repetition of a rhythmic figure" |

**Rhythmic arc:** Several sources describe a characteristic rhythmic shape:

1. Begin with longer values (half notes, suspension figures -- 2nd/4th species textures)
2. Gradually introduce shorter values (quarters, then eighth-note pairs -- 3rd species texture)
3. Slow down again toward the cadence (return to 4th species suspension for the clausula vera)

**Girton:** "The 5th species counterpoint line will often exhibit a rhythmic crescendo: longer note values and conjunct motion prevail at the very beginning of the exercise, with gradual introduction of quarter and eighth note values, and disjunct motion, as the exercise gets underway."

### 3.8 Melodic Guidelines

All melodic guidelines from previous species carry forward, with adjustments for the mixed-rhythm context:

- **Primarily stepwise motion** -- even more so than in any single species, because the mixture of values gives many opportunities for conjunct motion.
- **Single overall climax** that does not coincide with the CF climax. One or two secondary climaxes permitted.
- **Singable range** -- generally not exceeding a tenth.
- **Diatonic** -- stay within the mode/key.
- **Recover large leaps** by stepwise motion in the opposite direction.
- **No repeated notes** -- same pitch on consecutive notes is forbidden.
- **Frequent direction changes** -- avoid extended passages of more than 5-6 notes in the same direction.

**Leap restrictions with shorter note values:**

- All leaps must be to consonant intervals (m3, M3, P4, P5, ascending m6 in Renaissance style, P8)
- **Large leaps restricted to longer note values:** "Large leaps are not allowed between notes less than half the value of the c.f.'s notes" (Ars Nova). In practice, leaps between quarter notes should not exceed a fifth.
- **Eighth notes must be entirely stepwise** -- no leaps within or into/out of eighth-note pairs.

**Forbidden leaps (carried from previous species):**
- Tritone (d5/A4)
- Major sixth (in Renaissance style; some 18th-century treatments permit it)
- Seventh
- Any augmented or diminished interval

### 3.9 Parallel Perfect Consonances

**Core rule (universal).** Parallel fifths and octaves are forbidden between adjacent attacks.

**How checking works in mixed rhythms:**

The general principle is that parallel perfect consonances are checked according to the species that the rhythmic context represents at that moment.

| Context | Treatment |
|---|---|
| Consecutive downbeats (bar-to-bar) | **Forbidden** (same as 2nd species) |
| Adjacent note attacks | **Forbidden** regardless of rhythmic value |
| Weak-beat-to-weak-beat across bars | Generally acceptable (not perceptually salient) |

**Ars Nova:** "Avoid parallel fifths or octaves between the downbeat (accented) notes of two successive measures, unless the faster voice leaps by more than a third from the first perfect interval, or if an intervening note is consonant."

**S&S (via WKMT):** "Octaves and fifths on successive first beats (accented ones) are valid as long as they are separated by three crotchets."

**Hansen Media:** "The use of parallel perfect intervals is determined by those governing the species used at any given time."

### 3.10 Direct (Hidden) Fifths and Octaves

| Context | Treatment |
|---|---|
| Across barline (last note to next downbeat) | Approach perfect consonances by **contrary motion** (universal) |
| Within the bar | More lenient; stepwise approach in the upper voice generally suffices |
| Downbeat to downbeat | **Permitted** by most modern sources (intervening notes weaken the effect) |

### 3.11 Unison Treatment

| Position | Treatment |
|---|---|
| Opening note | Permitted |
| Final note | Permitted |
| Interior downbeats (beat 1) | **Forbidden** (universal) |
| Interior weak beats (2, 3, 4) | Permitted when necessary for good voice-leading |

Approach and departure: step out of unisons (do not leap to or from a unison).

### 3.12 Voice Crossing and Overlap

| Source | Voice crossing |
|---|---|
| **Schenker** | Strictly forbidden |
| **S&S** | Strictly forbidden |
| **Ars Nova** | "Upper voices can sometimes cross if necessary, but avoid overlapping" |
| **Modern pedagogy** | Generally forbidden |

Voice overlap (approaching beyond the other voice's previous pitch without actually crossing) is universally discouraged.

### 3.13 Contrary Motion Preference

**Universal.** Contrary motion is preferred throughout, as in all species. Particularly important at barlines (last note of bar to first note of next bar) and when approaching perfect consonances.

### 3.14 The Role of the Half Note

The half note occupies a special structural role in fifth species:

**As a structural backbone:** Half notes carry the fundamental voice-leading. The underlying harmonic framework of fifth species is best understood by extracting only the half-note level, which reveals 2nd/4th species patterns. Schenker and S&S emphasize this: quarter notes and eighth notes are *diminutions* of a half-note framework.

**Preparation and resolution of suspensions:** Suspensions are prepared with half notes on beat 3 and resolve on half-note positions. This is the primary rhythmic unit for the 4th-species component.

**Half note before quarters (S&S):** "In a measure containing both long and short values, half notes should precede quarter notes unless a half note is suspended into the following measure." The pattern half-quarter-quarter is natural; quarter-quarter-half is not (unless the half ties forward).

### 3.15 Interaction Between Species Textures

The florid line is not random alternation between species. Sources describe principles for how the different species-like textures should interact:

**Balance and variety (all sources):** No single species should dominate. The student should strive for a balanced mixture of 2nd-species half-note motion, 3rd-species quarter-note motion, and 4th-species suspension figures.

**Smooth transitions:** Moving from quarter-note motion to a suspension should feel natural. The rhythm should not lurch between species abruptly.

**ntoll.org** provides a specific constraint: "The rhythm of two crotchets and a minim in one bar is not good unless it is preceded by a bar ending with two crotchets." This governs transitions from 3rd-species texture to 2nd-species texture.

**Species identification at each moment (Hansen Media):** "The use of parallel perfect intervals is determined by those governing the species used at any given time." The analyst must identify what species-like behavior is in effect at each point to apply the correct checking rules.

---

## 4. Points of Agreement Across All Sources

1. **Combines all four previous species** into a single line against the CF.
2. **Begin with a perfect consonance, after a rest** (following 4th-species conventions preferred).
3. **End with a clausula vera;** final bar is a whole note; penultimate bar uses a suspension.
4. **Eighth notes** occur only in pairs, only on weak beats, only stepwise.
5. **All dissonance types** from previous species retain their original treatment rules.
6. **Suspensions may be embellished** with anticipated resolutions and neighboring figures.
7. **Strong beats** must be consonant or properly suspended.
8. **Parallel perfect consonances** forbidden between adjacent attacks.
9. **No whole notes in the body** of the exercise (reserved for final bar).
10. **A mixture of rhythmic values** is required -- no single species should dominate.
11. **Melodic guidelines** (stepwise preference, singable range, leap recovery, single climax) carry forward.
12. **Voice crossing and overlap** are forbidden or strongly discouraged.
13. **The nota cambiata** is the only figure permitting a leap from a dissonance.
14. **Resolution of suspensions** is always by step downward.

---

## 5. Key Points of Disagreement

| Issue | Strict view | Permissive view |
|---|---|---|
| First bar | Must use 4th-species conventions: half rest + half note (Fux, ntoll.org, Girton) | May use any species; quarter rest permitted (Ars Nova, Hansen Media) |
| Rhythmic patterns within bars | Highly specific forbidden patterns: anapest, q-q-h without tie-forward, q-note syncopation (ntoll.org, Ars Nova, Girton) | "No specific rules different than the previous species" (Global Music Theory) |
| Eighth-note frequency | "No more than once every three bars" (ntoll.org) | Simply "sparingly" (most other sources) |
| Number of embellished suspension types | Five or more types (Fux, Girton) | Primarily anticipated resolution (Hansen Media) |
| Leap restrictions between quarters | "Large leaps not allowed between notes less than half the value of the CF" (Ars Nova) | No specific quantitative restriction (most sources) |
| Eighth-note leaps | Always stepwise -- no exceptions (Renaissance-oriented sources) | Consonant skips within 8th-note pairs permitted (Attwood-Mozart studies, per Girton) |
| Hard/soft rule distinction | Explicitly maintained (Schubert) | Binary permitted/forbidden (most sources) |
| Gauldin's approach | Non-species "direct" approach rather than building species by species | Traditional species progression (all other sources) |

---

## 6. Mapping to head_music Architecture

The existing `head_music` style system groups guidelines into melody guides and harmony guides. Fifth species follows the same pattern. Below maps each guideline area to whether it is a **melody** concern (single-voice) or **harmony** concern (two-voice interaction), and notes where existing guidelines can be reused vs. where new guidelines are needed.

### 6.1 Current Implementation

The fifth-species guides are already implemented in `head_music`:

**FifthSpeciesMelody** (`lib/head_music/style/guides/fifth_species_melody.rb`):

```ruby
RULESET = [
  HeadMusic::Style::Guidelines::AlwaysMove,
  HeadMusic::Style::Guidelines::ConsonantClimax,
  HeadMusic::Style::Guidelines::Diatonic,
  HeadMusic::Style::Guidelines::EndOnTonic,
  HeadMusic::Style::Guidelines::FrequentDirectionChanges,
  HeadMusic::Style::Guidelines::LimitOctaveLeaps,
  HeadMusic::Style::Guidelines::MostlyConjunct,
  HeadMusic::Style::Guidelines::PrepareOctaveLeaps,
  HeadMusic::Style::Guidelines::SingableIntervals,
  HeadMusic::Style::Guidelines::SingableRange,
  HeadMusic::Style::Guidelines::StartOnPerfectConsonance,
  HeadMusic::Style::Guidelines::StepUpToFinalNote,
  HeadMusic::Style::Guidelines::AllowedRhythmicValuesForFifthSpecies,
  HeadMusic::Style::Guidelines::MixedRhythmicValues,
  HeadMusic::Style::Guidelines::NoRestsAfterNote
].freeze
```

**FifthSpeciesHarmony** (`lib/head_music/style/guides/fifth_species_harmony.rb`):

```ruby
RULESET = [
  HeadMusic::Style::Guidelines::ApproachPerfectionContrarily,
  HeadMusic::Style::Guidelines::AvoidCrossingVoices,
  HeadMusic::Style::Guidelines::AvoidOverlappingVoices,
  HeadMusic::Style::Guidelines::ConsonantDownbeats,
  HeadMusic::Style::Guidelines::NoParallelPerfectOnDownbeats,
  HeadMusic::Style::Guidelines::NoParallelPerfectWithSyncopation,
  HeadMusic::Style::Guidelines::PreferContraryMotion,
  HeadMusic::Style::Guidelines::PreferImperfect,
  HeadMusic::Style::Guidelines::FloridDissonanceTreatment,
  HeadMusic::Style::Guidelines::SuspensionTreatment
].freeze
```

### 6.2 Existing Guideline Analysis

#### Melody Guidelines -- Assessment

| Guideline | Status | Notes |
|---|---|---|
| **AlwaysMove** | Correct | No repeated notes |
| **ConsonantClimax** | Correct | Single climax not on same pitch as CF climax |
| **Diatonic** | Correct | Stay within mode/key |
| **EndOnTonic** | Correct | Final note is tonic |
| **FrequentDirectionChanges** | Correct | Avoid extended runs in one direction |
| **LimitOctaveLeaps** | Correct | |
| **MostlyConjunct** | Correct | Stepwise motion predominates |
| **PrepareOctaveLeaps** | Correct | Recover from large leaps by step |
| **SingableIntervals** | Correct | All leaps must be consonant |
| **SingableRange** | Correct | Generally within a tenth |
| **StartOnPerfectConsonance** | Correct | First note forms P1/P5/P8 with CF |
| **StepUpToFinalNote** | Correct | Leading tone approach to tonic |
| **AllowedRhythmicValuesForFifthSpecies** | Placeholder | Currently always passes (returns `[]`); should validate permitted values |
| **MixedRhythmicValues** | Correct | Requires at least 2 different rhythmic value durations |
| **NoRestsAfterNote** | Correct | No rests after the first note has sounded |

#### Harmony Guidelines -- Assessment

| Guideline | Status | Notes |
|---|---|---|
| **ApproachPerfectionContrarily** | Correct | Approach perfect consonances by contrary motion |
| **AvoidCrossingVoices** | Correct | |
| **AvoidOverlappingVoices** | Correct | |
| **ConsonantDownbeats** | Correct | Beat 1 must be consonant or properly suspended |
| **NoParallelPerfectOnDownbeats** | Correct | No P5-P5 or P8-P8 on consecutive downbeats |
| **NoParallelPerfectWithSyncopation** | Correct | Handles parallel checking with tied notes |
| **PreferContraryMotion** | Correct | |
| **PreferImperfect** | Correct | Prefer imperfect consonances on downbeats |
| **FloridDissonanceTreatment** | Correct | Validates passing tones, neighbor tones, and suspension treatment |
| **SuspensionTreatment** | Correct | Validates preparation, suspension, resolution phases |

### 6.3 Potential Enhancements

Based on the pedagogical survey, the following enhancements could strengthen the fifth-species implementation:

#### Melody Enhancements

| Enhancement | Priority | Description |
|---|---|---|
| **AllowedRhythmicValuesForFifthSpecies** | Medium | Currently a no-op placeholder. Could validate: no dotted notes, eighth notes only in pairs on weak beats, no values shorter than eighth |
| **EighthNoteConstraints** | New (soft) | Enforce: pairs only, weak beats only, stepwise only, one pair per bar max |
| **NoWholeNotesInBody** | New (hard) | Whole notes forbidden except in the final bar |
| **RhythmicVariety** | New (soft) | No more than two consecutive bars with identical rhythmic patterns (Hansen Media) |
| **PreferLongBeforeShort** | New (soft) | Within a bar, half notes should precede quarter notes (S&S) |
| **LeapSizeByRhythmicValue** | New (soft) | Restrict large leaps to longer note values; quarters limited to P5 or less |
| **FirstBarEntry** | Verify | Confirm it enforces rest + half note or rest + quarter note at opening |

#### Harmony Enhancements

| Enhancement | Priority | Description |
|---|---|---|
| **EmbellishedSuspensionTreatment** | New (medium) | Validate the five embellished suspension types: anticipated resolution, eighth-note neighbor, escape tone embellishment, consonant leap, delayed resolution |
| **NoParallelPerfectBetweenAdjacentAttacks** | New (hard) | Check parallel perfect consonances between any two consecutive note attacks, regardless of rhythmic value |

### 6.4 Hard vs. Soft Classification (after Schubert)

**Hard rules** (fitness near 0 for violations):
- Consonant downbeats (or properly prepared suspension)
- All dissonances must fit a recognized pattern (PT, NT, cambiata, or suspension with proper treatment)
- No parallel perfect consonances on adjacent attacks
- No repeated notes (AlwaysMove)
- Diatonic
- Singable intervals
- Whole notes only in final bar
- Eighth notes in pairs, on weak beats, stepwise
- Suspension resolution by step downward

**Soft rules** (penalty but not zero fitness):
- Prefer contrary motion
- Prefer imperfect consonances on downbeats
- Mostly conjunct
- Mixed rhythmic values (at least 2 different durations)
- Rhythmic variety (avoid repeating patterns)
- Consonant climax
- Singable range
- Frequent direction changes
- Half notes before quarter notes within a bar
- No more than one eighth-note pair every three bars

---

## 7. Sources

### Primary Textbooks

- Fux, J.J. *Gradus ad Parnassum* (1725). Trans. Alfred Mann, *The Study of Counterpoint* (W.W. Norton, 1965).
- Schenker, H. *Kontrapunkt* (1910/1922). Trans. Rothgeb & Thym, *Counterpoint* (Musicalia Press, 2001).
- Jeppesen, K. *Counterpoint: The Polyphonic Vocal Style of the Sixteenth Century* (1931; Dover, 1992).
- Salzer, F. & Schachter, C. *Counterpoint in Composition* (Columbia UP, 1969).
- Kennan, K. *Counterpoint*, 4th ed. (Prentice Hall, 1999).
- Gauldin, R. *A Practical Approach to 16th-Century Counterpoint* (Waveland Press).
- Gauldin, R. *A Practical Approach to 18th-Century Counterpoint* (Waveland Press).
- Schubert, P. *Modal Counterpoint: Renaissance Style*, 2nd ed. (Oxford UP, 2008).

### Online Pedagogy

- [Open Music Theory -- Fifth-Species Counterpoint (Gotham/Shaffer)](https://viva.pressbooks.pub/openmusictheory/chapter/fifth-species-counterpoint/)
- [Puget Sound Music Theory -- Fifth Species](https://musictheory.pugetsound.edu/mt21c/FifthSpecies.html)
- [Ars Nova -- Fifth Species Counterpoint](https://www.ars-nova.com/cpmanual/fifthspecies.htm)
- [Hansen Media -- Fifth Species Guidelines](https://hansenmedia.net/courses/counterpoint/lessons/fourth-species-guidelines-41/)
- [ntoll.org -- Species Counterpoint](https://ntoll.org/article/species-counterpoint/)
- [Irene Girton -- Species Counterpoint: 5th Species](https://irenegirton.com/irene-montefiore-girton/species-counterpoint-online/species-counterpoint-5th-species/)
- [Global Music Theory -- Rules of Counterpoint](https://globalmusictheory.com/the-rules-of-counterpoint-cantus-firmus-through-5th-species/)
- [WKMT -- Counterpoint Fifth Species](https://www.piano-composer-teacher-london.co.uk/counterpoint-fifth-species)
- [Clark Ross -- 16th Century Counterpoint Rules (based on Jeppesen)](https://www.clarkross.ca/16thC-100-SpeciesRules.3.pdf)
