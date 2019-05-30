# TODO

open consonance (P5 P8)
soft consonance (m3 M3 m6 M6)
mild dissonance (M2 m7)
sharp dissonance (m2 M7)

P4 (consonant or dissonant)
T (neutral or restless)

Sets
DurationSet?

Sonority
- #valid?
- symbol
- long symbol
- root
- pitch_classes

SonorityName
> Sonority
name (for example, "major minor seventh" or "dominant seventh")
abbreviation



PitchSetAnalysis
- Strategy pattern
Make new analysis classes:
Dyad
  .interval
  .implied_triad (if a third)
  .possible_triads
    - returns major and minor if a perfect fifth
    - returns minor and diminished if minor third
    - returns major and augmented if major third
    - returns augmented if augmented fifth
    - returns diminished if diminished fifth
    - should it take into account enharmonics? I think yes.
  .possible_seventh_chords
    - as above, with either seventh added
    - returns 3rd inversion if second
  .possible_chords
    possible_triads + possible_seventh_chords
  .possible_enharmonic_triads
  .possible_enharmonic_seventh_chords
  .possible_enharmonic_chords

the dyad will be super helpful in analyzing two-part counterpoint.

Triad
SeventhChord
Don't need anything beyond seventh chords to analyze pre-Romantic music.


## User stories


### Done

    As a developer
    When instantiating a DiatonicInterval
    When passing an abbreviation, such as 'P5' or 'm2'
    I want to receive that instance.

    As a developer
    Given a pitch
    I want to be able to add a diatonic interval to get another pitch.

DiatonicInterval
  - def above(pitch) -> pitch
DiatonicInterval
  - def below(pitch) -> pitch

Pitch addition and subtraction
  - define `Pitch#+`, `Pitch#-`
  - use DiatonicInterval methods

PitchSet

A PitchSet is unlike a PitchClassSet in that the pitches have spellings with octaves rather than Spellings only or octave-less 0-11 designations.

PitchClassSet
.size?
.monad?
.dyad?
.triad? (must be stacked thirds to be a 'triad')
.trichord? (all 3-pitch sets)

Should every group of pitches have one or more strategies for describing it? Such as Dyad?

Set (superclass?)
PitchSet
  EmptySet
  Monad
  Dyad
  Trichord (or Triad)
    - triad?
  Tetrachord (or Tetrad)
    - seventh_chord?
  Pentachord (or Pentad)
  Hexachord (or Hexad)
  Heptachords (or Heptad or, sometimes, mixing Latin and Greek roots, "Septachord")
  Octachords (Octad)
  Nonachords (Nonad)
  Decachords (Decad)
  Undecachords
  Dodecachord

PitchClassSet
  .normal_form? (most compact)
  .prime_form (most compact normal form of the original or any inversion)
