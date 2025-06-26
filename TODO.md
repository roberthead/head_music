# TODO

May 7, 2023

Robert Head:
	Hey, Brian. You have a sec for a music question? I’m trying to come up with different terms for the way “family” is used. “Woodwind family” vs. “Oboe family”.

Brian Head:
	Those are good, I’d say.  In what context?

Robert Head:
	In my software project, I’m trying to define those relationships. One is a section of the orchestra and the other is species of instrument. But usually people, in my experience, just say “family”.
	Is there some more precise terminology or adjective that can disambiguate those two terms?

Brian Head:
	Hmmm. Already “family” is informal. Blatter distinguishes between “choir” and “family” as in the  trumpet family” within the “brass choir”.

Robert Head:
	Ah, yes! I do like that.
	But does it apply to percussion?
	“Section” is another candidate, but that gets used for string parts as well.

Brian Head:
	Strings and percussion probably don’t think of themselves as a choir, but if you’re mainly looking for a taxonomically consistent word, that’s the feat I can think of at the moment.
	Section is a good word, too, which easily flows between smaller and larger meanings.

Robert Head:
	Obviously, the four “families” is a garbage way to classify all instruments and it really is more applicable to the orchestral context, so maybe “orchestra family” or “orchestra section”.

Brian Head:
	I’d say that “family” is best used at the instrument level, as in “saxophone family”. Choir or section are better for larger collections. Still, both of those words connote membership in an orchestra. Or large ensemble.  “Woodwinds” or “percussion” describe the class of instruments themselves.

Robert Head:
	Cool

Action Item: Call them orchestra_section
DONE

Add Score Order

Orchestral Score Order

# So, in orchestral scores, the groupings are by instrumental 'family':
# woodwinds on top of the page, and below them, in descending order,
# brass,
# percussion,
# harp and keyboards,
# soloists (instrumental or vocal),
# voices,
# strings

(Notice the different placement of percussion in orchestra and band scores)

Flutes (Fl or Fls)
Oboes (Ob or Obs)
Clarinets (Cl or Cls)
Bassoons (Bsn or Bsns)
Horns (Hn or Hns)
Trumpets (Tpt or Tpts)
Trombones (Trb or Trbs)
Tuba (Tuba)
Timpani (Timp)
Percussion (Perc)
Other Instruments
harp and keyboards
soloists
voices
Violins I (Vlns)
Violins II
Viola (Vla)
Violoncellos (Vcl)
Double Bass (DB)

Band Score Order

Flutes (Fl or Fls)
Oboes (Ob or Obs)
Bassoons (Bsn or Bsns)
Clarinets (Cl or Cls)
Saxophones (AS, or TS, or BS)
Cornets (Cor)
Trumpets (Tpt or Tpts)
Horns (Hn or Hns)
Trombones (Trb or Trbs)
Euphoniums (Euph)
Tubas (Tubas)
Timpani (Timp)
Percussion (Perc)

Brass Quintet

Trumpet I
Trumpet II
Horn
Trombone
Tuba

Woodwind Quintet

Flute
Oboe
Clarinet
Horn
Bassoon



Disambiguate PitchSet and Sonority

Sonority should be a name for a specific set of intervals
Sonority.get(identifier)
Sonority.for(pitch_set)
Sonority.pitch_set_for(root_pitch:, inversion:)

    class PitchSet
      def sonority
        @sonority ||= Sonority.for(self)
      end
    end



open consonance (P5 P8)
soft consonance (m3 M3 m6 M6)
mild dissonance (M2 m7)
sharp dissonance (m2 M7)

P4 (consonant or dissonant)
T (neutral or restless)

Sets
DurationSet?


Make new analysis classes:
Dyad
  .interval
  .implied_triad (if a third)
    - returns most likely of possible triads
  .possible_triads
    - returns major and minor if a perfect fifth
    - returns minor and diminished if minor third
    - returns major and augmented if major third
    - returns inverted major and root augmented if augmented fifth
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
