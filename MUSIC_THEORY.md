# Music Theory
Domain-specific knowledge for this project.

## Rudiments

The rudiments of music theory are built up piece-by-piece.

letter name
  - C, D, E, F, G, A, B, …
  - equivalent to:
   - do, re, mi, fa, sol, la, si/ti, …

alteration
  - sharp, flat, double sharp, double flat
  - optional
  - none is same as 'natural'
  - found in key signatures
  - found in bars as accidentals

spelling
  - letter name + alteration
  - example: "E♭"

register
  - an integer typically between 0 and 8
  - represents the octaves of an 88-key piano
  - scientific pitch notation
    - middle C is C4
    - increments between B and C
      - a half step below C4 is B3.

pitch
  - spelling + register
  - example: "E♭3"

rhythmic unit
  - duration
  - expressed in fractions (or multiples) of a standard whole note
    - whole, half, quarter, eighth, sixteenth, …
    - breve, …

rhythmic value (duration)
  - a rhythmic unit plus optional augmentation dots
  - augmentation dots extend the duration of the rhythmic unit
    - one dot extends the rhythmic value 50%
    - two dots extend the rhythmic value 75%
    - two dots extend the rhythmic value 87.5%

rest
  - a rhythmic value that passes in silence

note
  - pitch + rhythmic value
  - example: "E♭3 dotted quarter"

unpitched note
  - an unpitched percussion note, such as a drum hit
  - a sounded rhythmic value without a specific pitch

tied duration
  - combines multiple rhythmic values into one longer note
  - ties allow rhythmic values to be combined across barlines or strong beats

articulation
  - a category of expressions that modify how one or more notes are performed.
  - level of connection
    - staccatissimo - the most staccato, even shorted and more clipped
    - staccato – detatched (shortened to lease space between adjacent notes)
    - tenuto - held of the full value
    - legato - smoothly connected
  - emphasis
    - accent - play with emphasis or a stronger attack
    - marcato - markedly emphasized
  - instrument specific
    - bowings
    - breath mark
    - roll mark

## Instrument Families

There are several ways that people talk about families and other categorizations of instruments. For example, the "string family" or "woodwind family", but also more specifically, the word family is applied more specifically (e.g. the "oboe family").

### Text Conversation with Brian Head (May 7, 2023)

Brian Head, brother and faculty at USC Thornton School of Music
https://music.usc.edu/brian-head/

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
