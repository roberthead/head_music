# Second-Species Counterpoint: Pedagogical Reference

A survey of second-species counterpoint guidelines from Fux (1725) through contemporary pedagogy, noting points of agreement and disagreement across sources. Intended as a reference for implementing style guidelines in the `head_music` gem.

---

## 1. Fundamental Premise

Second-species counterpoint sets **two half notes** in the counterpoint voice against each **whole note** in the cantus firmus, creating a 2:1 rhythmic ratio. This species introduces two concepts absent from first species:

1. **Metric differentiation** -- strong beats (downbeats) vs. weak beats (upbeats)
2. **Dissonance** -- the passing tone, in a highly controlled context

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
| **OMT** | Open Music Theory (Shaffer, Hughes, et al.) | Contemporary online pedagogy |

---

## 3. Guideline Synthesis

### 3.1 Rhythmic Structure

**Universal agreement.** Two half notes against each whole note. The final measure is a whole note.

### 3.2 Beginning

**Pitch (universal):**
- Above the cantus firmus: begin on the tonic (unison/octave) or the fifth.
- Below the cantus firmus: begin on the tonic (unison/octave).

**Rhythm (two options):**
1. **Half rest followed by a half note** -- the standard Fuxian approach; preferred by most modern sources because it establishes the 2:1 rhythmic profile immediately.
2. **Two half notes** -- permitted by most sources.

### 3.3 Strong Beats (Downbeats)

**Universal agreement.** Every downbeat must be **consonant** with the cantus firmus. Permissible consonances: unison, third, fifth, sixth, octave, and compound equivalents. The perfect fourth is a dissonance in two-voice counterpoint (all sources agree).

**Preference.** Imperfect consonances (thirds, sixths) are preferred over perfect consonances (fifths, octaves, unisons) -- carried forward from first species.

### 3.4 Weak Beats (Upbeats)

**Core agreement.** The weak beat may be consonant or dissonant.

**If dissonant:** Must be a **passing tone** -- approached by step and left by step **in the same direction**. This is the only dissonance type permitted in second species. All sources agree.

**If consonant:** May be reached by step or by leap. Open Music Theory names specific weak-beat consonant patterns:

| Pattern | Description |
|---|---|
| **Consonant passing tone** | Two steps in the same direction, outlining a third |
| **Substitution** | Leap a fourth, then step in the opposite direction |
| **Skipped passing tone** | A third and a step in the same direction, outlining a fourth |
| **Interval subdivision** | Two leaps in the same direction dividing a larger interval |
| **Change of register** | A large consonant leap (P5, 6th, or octave) followed by a step opposite |
| **Melodic delay** | Leap a third, then step in the opposite direction |
| **Consonant neighbor tone** | Step in one direction, then step back (see disagreement below) |

#### Neighbor Tone Disagreement (the largest area of divergence)

| Source | Dissonant Neighbor | Consonant Neighbor |
|---|---|---|
| Fux | Not discussed; implicitly forbidden | Not discussed |
| Schenker | **Explicitly forbidden** | **Forbidden** ("highlights a single pitch") |
| Jeppesen | Forbidden | Permitted occasionally |
| S&S | Generally forbidden | Permitted with care |
| OMT | Forbidden | **Explicitly permitted** (named pattern) |

No source permits **dissonant** neighbor tones in second species. The disagreement is over **consonant** neighbor tones -- Schenker's ban is the strictest; contemporary pedagogy is the most permissive.

### 3.5 Ending / Cadence

**Universal agreement.** End with a clausula vera: stepwise contrary motion into a perfect consonance (unison or octave).

**Final bar:** Always a whole note on the tonic, forming a unison or octave with the cantus firmus.

**Penultimate bar** may contain two half notes or one whole note.

**Specific cadential formulas:**

| Cantus firmus position | Penultimate intervals | Scale degrees in counterpoint |
|---|---|---|
| CF below, counterpoint above | Fifth then major sixth resolving to octave | 6-7-8 against CF scale degree 2 |
| CF above, counterpoint below | Fifth then minor third resolving to unison/octave | 5-3-1 against CF scale degree 2 |

**Phrygian exception (Puget Sound):** When the CF is above in Phrygian mode, use a sixth to a third (scale degrees 4-b7 against b2).

### 3.6 Melodic Guidelines

These carry forward from first species with modifications:

- **Primarily stepwise motion** -- even more so than first species, since the doubled note count and passing tones make conjunct motion easier.
- **Single overall climax** -- with one or two secondary climaxes permitted given the greater number of notes.
- **Singable range** -- generally not exceeding a tenth.
- **Diatonic** -- stay within the mode/key.
- **Recover large leaps** -- follow leaps with stepwise motion in the opposite direction.
- **Prefer leaping within the bar** (strong to weak) rather than across the barline (weak to strong), as the metric position diminishes the perceptual weight of the leap.
- **No repeated notes** (see 3.10 below).

### 3.7 Parallel Perfect Consonances

**Strict rule (universal).** Parallel fifths or octaves between adjacent attacks (strong-to-weak or weak-to-strong) are absolutely forbidden.

**Downbeat-to-downbeat parallels:**

| Situation | Treatment |
|---|---|
| P5 on downbeat, P5 on next downbeat | **Forbidden** by virtually all sources |
| P8 on downbeat, P8 on next downbeat | **Forbidden** similarly |
| P5 on weak beat, P5 on next downbeat | **Forbidden** (equivalent to first-species parallels across the barline) |

**Exception (minority).** Some sources tolerate downbeat-to-downbeat parallels if the intervening note leaps by a fourth or more, arguing the large leap masks the effect. Not universally accepted.

**Weak-beat-to-weak-beat parallels** are acceptable (not perceptually audible).

### 3.8 Direct (Hidden) Fifths and Octaves

| Context | Treatment |
|---|---|
| Weak-to-strong (across barline) | Treated as in first species: **approach perfect consonances by contrary or oblique motion** (universal) |
| Strong-to-weak (within the bar) | More lenient; some sources permit direct motion to perfect consonances |
| Downbeat-to-downbeat | **Permitted** by most modern sources ("the effect is weakened by the intervening note") |

This is a significant relaxation from first species. Hidden fifths/octaves between successive downbeats are generally acceptable; hidden fifths/octaves across the barline (weak to strong) remain forbidden.

### 3.9 Unison Treatment

| Source | Interior Unisons |
|---|---|
| Fux | Forbidden in middle (though his own examples occasionally show them) |
| Schenker | Strictly limited |
| Jeppesen | More permissive |
| Modern consensus | Permitted on **weak beats only**, with proper voice-leading |

**Generally agreed:**
- Permitted at first and last dyads.
- Interior unisons (if allowed) occur only on weak beats.
- Do not leap to or from a unison.
- Leave a unison by step in the opposite direction from approach.

### 3.10 Repeated Notes

**Universal agreement.** Repeating the same pitch on consecutive half notes is **forbidden**, both within the bar and across the barline. Repetition undermines the forward motion that second species is designed to cultivate.

### 3.11 Permitted and Forbidden Leaps

**Permitted leaps:**
- Minor third, major third
- Perfect fourth, perfect fifth
- Minor sixth (ascending only in 16th-century style)
- Octave

**Forbidden leaps:**
- Tritone (diminished fifth, augmented fourth)
- Major sixth (in 16th-century style; some 18th-century treatments permit it)
- Seventh
- Any augmented or diminished interval

**Leap treatment:**
- All leaps must be to and from consonances. Cannot leap to or from a dissonant note.
- Recover large leaps by stepwise motion in the opposite direction.
- Limit consecutive leaps in the same direction.

### 3.12 Voice Crossing and Overlap

| Source | Voice Crossing |
|---|---|
| Fux | Occasionally permits |
| Schenker | Strictly forbidden |
| S&S | Strictly forbidden ("weakens polarity between voices") |
| Modern pedagogy | Generally forbidden; rarely tolerated |

Voice overlap (approaching beyond the other voice's previous pitch without crossing) is universally discouraged.

### 3.13 Contrary Motion Preference

**Universal.** Contrary motion is preferred throughout, especially when approaching perfect consonances. Perfect consonances on the downbeat must be approached by contrary or oblique motion from the preceding note across the barline.

---

## 4. Mapping to head_music Architecture

The existing `head_music` style system groups guidelines into melody guides and harmony guides. Second species will follow the same pattern. Below maps each guideline area to whether it is a **melody** concern (single-voice) or **harmony** concern (two-voice interaction), and notes where existing first-species guidelines can be reused vs. where new guidelines are needed.

### Melody Guidelines (SecondSpeciesMelody)

| Guideline | Status | Notes |
|---|---|---|
| Diatonic | **Reuse** from first species | |
| SingableRange | **Reuse** | |
| SingableIntervals | **Reuse** | |
| MostlyConjunct | **Reuse** (may need threshold adjustment) | Even more stepwise than first species |
| ConsonantClimax | **Reuse** | Secondary climaxes may need consideration |
| FrequentDirectionChanges | **Reuse** | |
| LimitOctaveLeaps | **Reuse** | |
| PrepareOctaveLeaps | **Reuse** | |
| NoRests | **Reuse** | |
| EndOnTonic | **Reuse** | |
| NotesSameLength | **Remove/Replace** | Not applicable; replaced by TwoToOne ratio |
| **TwoToOne** | **New** | Two half notes per whole note in CF (except final bar) |
| **NoRepeatedNotes** | **New** (or reuse AlwaysMove) | No consecutive identical pitches |
| **BeginWithRestOrConsonance** | **New** | Half rest + half note, or two half notes starting on P1/P5/P8 |
| **StepUpToFinalNote** | **Reuse** or adapt | Penultimate note approaches tonic by step |
| **PreferLeapsWithinBar** | **New** (soft) | Leap from strong to weak preferred over weak to strong |

### Harmony Guidelines (SecondSpeciesHarmony)

| Guideline | Status | Notes |
|---|---|---|
| ConsonantDownbeats | **Reuse** | |
| PreferImperfect | **Reuse** | |
| PreferContraryMotion | **Reuse** | |
| ApproachPerfectionContrarily | **Reuse** (across barline) | Weak-to-strong motion into perfect consonance |
| AvoidCrossingVoices | **Reuse** | |
| AvoidOverlappingVoices | **Reuse** | |
| NoUnisonsInMiddle | **Adapt** | Allow unisons on weak beats; forbid on strong beats |
| OneToOne | **Remove** | Not applicable; replaced by TwoToOne |
| **WeakBeatDissonanceTreatment** | **New** | Dissonant weak beats must be passing tones (step in, step out, same direction) |
| **NoParallelPerfectOnDownbeats** | **New** | No P5-P5 or P8-P8 on consecutive downbeats |
| **NoParallelPerfectAcrossBarline** | **New** | No parallel perfect consonances from weak beat to next strong beat |
| **CadentialFormula** | **New** | Proper clausula vera approach (5-6-8 above; 5-3-1 below) |

### Hard vs. Soft Classification (after Schubert)

**Hard rules** (fitness near 0 for violations):
- Consonant downbeats
- Passing tone as the only dissonance type
- No parallel perfect consonances on adjacent attacks
- No repeated notes
- Diatonic
- Singable intervals

**Soft rules** (penalty but not zero fitness):
- Prefer contrary motion
- Prefer imperfect consonances
- Mostly conjunct
- Prefer leaps within the bar
- Avoid consecutive downbeat perfect consonances
- Avoid interior unisons on strong beats

---

## 5. Sources

### Primary Textbooks

- Fux, J.J. *Gradus ad Parnassum* (1725). Trans. Alfred Mann, *The Study of Counterpoint* (W.W. Norton, 1965).
- Schenker, H. *Kontrapunkt* (1910/1922). Trans. Rothgeb & Thym, *Counterpoint* (Musicalia Press, 2001).
- Jeppesen, K. *Counterpoint: The Polyphonic Vocal Style of the Sixteenth Century* (1931; Dover, 1992).
- Salzer, F. & Schachter, C. *Counterpoint in Composition* (Columbia UP, 1969).
- Kennan, K. *Counterpoint*, 4th ed. (Prentice Hall, 1999).
- Gauldin, R. *A Practical Approach to 16th-Century Counterpoint* (Waveland Press).
- Gauldin, R. *A Practical Approach to 18th-Century Counterpoint* (Waveland Press).
- Schubert, P. *Modal Counterpoint: Renaissance Style*, 2nd ed. (Oxford UP, 2008).
- Roig-Francoli, M. *Harmony in Context*, 3rd ed. (McGraw-Hill, 2020).

### Online Pedagogy

- [Open Music Theory -- Second-Species Counterpoint](https://viva.pressbooks.pub/openmusictheory/chapter/second-species-counterpoint/)
- [Kris Shaffer -- Composing a Second-Species Counterpoint](http://kshaffer.github.io/musicianshipResources/secondSpecies.html)
- [Puget Sound Music Theory -- Second Species](https://musictheory.pugetsound.edu/mt21c/SecondSpecies.html)
- [Rothfarb (UCSB) -- The Second Species of Counterpoint](https://rothfarb.faculty.music.ucsb.edu/courses/103/Second_Species(2v).html)
- [Ars Nova -- Second Species Counterpoint](https://www.ars-nova.com/cpmanual/secondspecies.htm)
- [Todd Tarantino -- Basic Rules for Second Species Counterpoint (PDF)](http://www.toddtarantino.com/fundamentals/SecondSpeciesRules.pdf)
- [Clark Ross -- 16th Century Counterpoint Rules (PDF, based on Jeppesen)](https://www.clarkross.ca/16thC-100-SpeciesRules.3.pdf)
- [Hansen Media -- Second Species Guidelines 2:1](https://hansenmedia.net/courses/counterpoint/lessons/second-species-guidelines-21/)
