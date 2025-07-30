# TODO

## Completed User Stories

The following user stories have been completed and are documented in the codebase:

### DiatonicInterval

    As a developer
    When instantiating a DiatonicInterval
    When passing an abbreviation, such as 'P5' or 'm2'
    I want to receive that instance.

    As a developer
    Given a pitch
    I want to be able to add a diatonic interval to get another pitch.

DiatonicInterval
  - def above(pitch) -> pitch
  - def below(pitch) -> pitch

Pitch addition and subtraction
  - define `Pitch#+`, `Pitch#-`
  - use DiatonicInterval methods


## Text Conversation with Brian Head (May 7, 2023)

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
