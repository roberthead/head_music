# Fourth-Species Counterpoint: Developer Reference

A concise reference for implementing fourth-species counterpoint guidelines in the `head_music` gem. Covers pedagogical foundations, music theory rules, and architectural mapping.

---

## 1. Historical Context

### Fux (1725)

Johann Joseph Fux's *Gradus ad Parnassum* establishes the species framework that remains canonical. Fourth species introduces the **suspension**: the counterpoint voice ties across the barline, causing the previously consonant pitch to become dissonant against the cantus firmus on the downbeat, then resolving by step downward on the upbeat. Fux treats suspensions as the defining idiom of Renaissance vocal counterpoint.

### Schenker (1910/1922)

Schenker reframes fourth species as a study in **voice-leading prolongation**. The suspension is not merely an ornament but a structural event: the tied note delays (prolongs) the resolution, creating tension that drives forward motion. He emphasizes the three-phase structure (preparation, suspension, resolution) as fundamental to understanding tonal prolongation at all structural levels.

### Contemporary Pedagogy (Salzer & Schachter, Schubert, OMT)

Modern treatments preserve the Fuxian suspension taxonomy while clarifying edge cases: when ties break (the "second species break"), how to handle the final cadence, and the treatment of the 2-3 suspension in the bass. Open Music Theory and Schubert's *Modal Counterpoint* both codify the rule that when the syncopated texture is interrupted, the off-beat note reverts to second-species behavior and may be a dissonant passing tone.

---

## 2. The Syncopated Texture

Fourth species is built on **rhythmic syncopation**: notes begin on the weak beat of one bar and sustain through the downbeat of the next.

In 4/4 or cut time (the typical cantus firmus meter):

```
Beat:     1         2         3         4
CF:       o---------                    (whole note)
CPT:                o---------o---------
                    ^weak     ^weak
                    preparation         resolution
                              ^strong
                              suspension (may be dissonant)
```

The **sounding duration** is what matters for analysis. A pitch that begins on beat 3 and sustains through beat 1 of the next bar is sounding on that downbeat regardless of how it is notated. See section 6 on notation.

---

## 3. Suspension Types

Suspensions are named by the interval sequence: **dissonant interval on the downbeat -- resolved interval on the upbeat**.

### Upper Voice Suspensions (counterpoint above cantus firmus)

| Name | Suspension | Resolution | Notes |
|------|-----------|------------|-------|
| 7-6  | 7th (dissonant) | 6th | Most common; smooth resolution to imperfect consonance |
| 4-3  | 4th (dissonant) | 3rd | The 4th is dissonant in two-voice counterpoint |
| 9-8  | 9th (dissonant) | Octave | Resolves to perfect consonance; use with care |
| 2-1  | 2nd (dissonant) | Unison | Rare; treated as a form of 9-8 at the octave |

### Lower Voice Suspensions (counterpoint below cantus firmus)

| Name | Suspension | Resolution | Notes |
|------|-----------|------------|-------|
| 2-3  | 2nd (dissonant) | 3rd | The "bass suspension"; resolution moves downward by step |
| 4-5  | 4th (dissonant) | 5th | Less common than 2-3 |
| 9-10 | 9th (dissonant) | 10th (3rd) | Compound form of 2-3 |

**Key constraint for all suspensions:** The resolution must move **by step downward** (in the resolving voice) from the suspended pitch. Upward resolution is not permitted in strict species counterpoint.

---

## 4. Suspension Structure: Preparation, Suspension, Resolution

Every suspension consists of three phases:

1. **Preparation** -- The pitch to be suspended is heard on a **weak beat** as a **consonance** with the cantus firmus. This establishes the pitch as stable before it becomes dissonant.

2. **Suspension** -- The same pitch is held (or re-articulated as tied) into the **strong beat** (downbeat) of the next bar, where it is now **dissonant** with the cantus firmus.

3. **Resolution** -- On the following **weak beat**, the suspended pitch moves **by step downward** to a consonance.

```
Phase:    PREPARATION     SUSPENSION     RESOLUTION
Beat:     weak            strong         weak
Harmony:  consonant       dissonant      consonant
Motion:   (arrival)       (sustained)    step down
```

### Preparation Requirements

- The preparation must be a consonance (not a dissonance, not a rest).
- The preparation pitch and the suspended pitch are the same pitch -- this is the defining feature of a suspension (vs. an appoggiatura, which arrives unprepared).
- In head_music terms: the `Placement` on the weak beat must produce a consonant `HarmonicInterval` with the cantus firmus at that position.

### Resolution Requirements

- Resolution is **always** by **step downward** in the voice containing the suspension.
- Resolution arrives on a **consonance** with the cantus firmus.
- The cantus firmus does not move during the suspension (it is a whole note): the resolution step belongs to the counterpoint voice alone.

---

## 5. The "Second Species Break"

The syncopated texture is sometimes interrupted -- the tie does not occur and the voice articulates a new pitch on the weak beat without sustaining into the next downbeat. This moment is called a **second species break** (some sources call it a "cambiata" context or simply describe it as reverting to second-species behavior).

**Rule:** When the texture breaks and the off-beat note does not tie into the next downbeat, that off-beat note may be a **dissonant passing tone**, subject to the same conditions as second species:
- Approached by step.
- Left by step **in the same direction**.
- The dissonance falls on the weak beat only.

This is the only context in fourth species where a dissonance may appear without being a suspension. The break allows the voice to redirect melodically when a suspension would produce forbidden parallels or other violations.

**Implementation note:** Detecting a second species break requires knowing whether a `Placement` at a weak beat position ties into the next downbeat. If `placement.next_position` falls on a downbeat and `voice.note_at(next_downbeat)` returns a different pitch (or no pitch), the tie has broken.

---

## 6. Notation-Agnostic Analysis Principle

**Ties are a display concern only.** For analytical purposes, a pitch that sounds continuously from position A to position B is a single sounding event, regardless of how many notated note heads or tie symbols represent it.

These two notations are analytically identical in fourth species:

- A whole note C4 beginning at beat 3 of bar 1, sustained through beat 1 of bar 2.
- A half note C4 at beat 3 of bar 1, tied to a half note C4 at beat 1 of bar 2.

**Guidelines operate on sounding durations, not on notated note heads.**

In head_music, this principle is already encoded in the data model:

- A `Placement` represents a single sounding event with a `position` (when it starts) and a `rhythmic_value` (how long it lasts).
- `Placement#next_position` computes when the sound ends: `position + rhythmic_value`.
- The display layer (ties, beaming, notation symbols) is a separate concern handled by the `HeadMusic::Notation` module.

Analytical guidelines should never count note heads or detect ties in the notated score. Instead, they should query `voice.note_at(position)` for any given position to determine what is sounding.

---

## 7. Mapping to head_music Architecture

### Voice and Placement Model

```
Voice
  #placements       -> [Placement, ...]   all sounding events (notes and rests)
  #notes            -> [Placement, ...]   only pitched placements
  #note_at(pos)     -> Placement | nil    what is sounding at a given Position
  #note_preceding(pos) -> Placement | nil the note whose position is before pos
  #note_following(pos) -> Placement | nil the note whose position is after pos

Placement
  #position         -> Position           when the event begins
  #rhythmic_value   -> RhythmicValue      how long it lasts
  #next_position    -> Position           position + rhythmic_value (when it ends)
  #pitch            -> Pitch | nil        nil for rests
  #note?            -> bool
  #rest?            -> bool
```

### Position

```
Position
  #within_placement?(placement) -> bool   true if self >= placement.position
                                          AND self < placement.next_position
  #strong?          -> bool               downbeat (strength >= 80)
  #weak?            -> bool               not strong
  #bar_number       -> Integer
  #count            -> Integer            beat within bar
```

`Position#within_placement?` is the key predicate for "is this pitch sounding at this moment?" It returns true for any position that falls during the placement's duration -- including the middle of a long note. This is the mechanism that makes sustained notes invisible to position-based queries.

### HarmonicInterval

```
HarmonicInterval.new(voice1, voice2, position)
```

Internally calls `voice.note_at(position)` for each voice. Because `note_at` uses `position.within_placement?`, it correctly finds notes that **began earlier and are still sounding**, not only notes that **start at** the given position.

This means `HarmonicInterval` already handles sustained pitches correctly. A suspended note that began on beat 3 and is still sounding on beat 1 of the next bar will be found and evaluated as a harmonic interval at beat 1 without any special casing in the guideline code.

### Identifying Suspension Phases in Guidelines

To analyze a suspension at a given downbeat position:

```ruby
# The suspended note: sounding at the downbeat but started earlier
suspended_note = counterpoint_voice.note_at(downbeat_position)

# It is a suspension only if it started before the downbeat
is_suspension = suspended_note && suspended_note.position < downbeat_position

# Preparation: the same placement, evaluated at the previous weak beat
# (suspended_note itself IS the preparation placement)
preparation_harmonic_interval = HarmonicInterval.new(
  cantus_firmus, counterpoint_voice, suspended_note.position
)

# Suspension: harmonic interval at the downbeat
suspension_harmonic_interval = HarmonicInterval.new(
  cantus_firmus, counterpoint_voice, downbeat_position
)

# Resolution: the note that follows the sustained note
resolution_note = counterpoint_voice.note_following(downbeat_position)
```

### Guidelines: Annotation and Mark

Guidelines inherit from `HeadMusic::Style::Annotation` and override the `marks` method, returning an array of `HeadMusic::Style::Mark` objects.

```ruby
class MyGuideline < HeadMusic::Style::Annotation
  MESSAGE = "Description of the rule."

  def marks
    # Collect placements that violate the rule.
    # Return Mark objects for each violation.
    violating_placements.map do |placement|
      HeadMusic::Style::Mark.for(placement, fitness: 0)
    end
  end
end
```

`Mark.for(placement)` creates a mark spanning `placement.position` to `placement.next_position`. `Mark.for_all(placements)` creates a single mark spanning a group. `Mark.for_each(placements)` creates one mark per placement.

Fitness of `0` signals a hard violation (forbidden). The default `HeadMusic::PENALTY_FACTOR` is used for soft violations (discouraged but not forbidden).

### Guideline Classification for Fourth Species

**Hard violations (fitness: 0):**
- Suspension not prepared as a consonance (preparation must be consonant).
- Suspension resolution not by step downward.
- Suspension resolution not to a consonance.
- Dissonance on a downbeat that is not a valid suspension.
- Off-beat dissonance in a second-species break that is not a passing tone (approached and left by step in same direction).

**Soft penalties (PENALTY_FACTOR):**
- Failure to use suspensions where they are available (too many direct consonances reduces interest).
- Resolution to a perfect consonance (prefer imperfect).
- Parallel perfect consonances on successive downbeats.

---

## 8. Sources

- Fux, J.J. *Gradus ad Parnassum* (1725). Trans. Alfred Mann, *The Study of Counterpoint* (W.W. Norton, 1965).
- Schenker, H. *Kontrapunkt* (1910/1922). Trans. Rothgeb & Thym (Musicalia Press, 2001).
- Salzer, F. & Schachter, C. *Counterpoint in Composition* (Columbia UP, 1969).
- Schubert, P. *Modal Counterpoint: Renaissance Style*, 2nd ed. (Oxford UP, 2008).
- [Open Music Theory -- Fourth-Species Counterpoint](https://viva.pressbooks.pub/openmusictheory/chapter/fourth-species-counterpoint/)
- [Puget Sound Music Theory -- Fourth Species](https://musictheory.pugetsound.edu/mt21c/FourthSpecies.html)
