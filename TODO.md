# TODO

dyad
triad

open consonance (P5 P8)
soft consonance (m3 M3 m6 M6)
mild dissonance (M2 m7)
sharp dissonance (m2 M7)

P4 (consonant or dissonant)
T (neutral or restless)


Make a new basic class called a PitchGroup, which can be analyzed as a dyad, triad, larger chord, etc.
Replaces Chord?
PitchList? Does it need to be ordered? I think yes, groups of pitches are inherently sortable from low to high. In which case PitchGroup is fine.
A PitchGroup is unlike a Pitch Set in that the pitches have spellings with octaves rather than octave-less 0-11 designations.

PitchGroup
.size?
.single_pitch?
.dyad?
.triad? (must be stacked thirds to be a 'triad')

Should every group of pitches have one or more strategies for describing it? Such as Dyad?


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
    When instantiating a FunctionalInterval
    When passing an abbreviation, such as 'P5' or 'm2'
    I want to receive that instance.

    As a developer
    Given a pitch
    I want to be able to add a functional interval to get another pitch.

FunctionalInterval
  - def above(pitch) -> pitch
FunctionalInterval
  - def below(pitch) -> pitch

Pitch addition and subtraction
  - define `Pitch#+`, `Pitch#-`
  - use FunctionalInterval methods
