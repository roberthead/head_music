# Instruments can have strings with pitches

Instruments like violins and guitars have strings that are each tuned to a specific pitch.

## Implementation Plan

HeadMusic::Instruments::Instrument

HeadMusic::Instruments::Stringing
> instrument: Instrument
>> stringing_courses: StringingCourse[]

HeadMusic::Instruments::StringingCourse
> stringing: Stringing
> standard_pitch: HeadMusic::Rudiment::Pitch
  for example, the lowest string of a guitar, "E2"
- course_semitones: Integer[]
  Examples:
  a 6-string guitar would be []
  a 12-string guitar would be [12] for the low strings and [0] for the high strings

HeadMusic::Instruments::AlternateTuning
> instrument: Instrument
- name: string
>> semitones: int[]
   lowest to highest string courses in the strings


## Answering questions

> Would it make more sense for Stringing to be associated with InstrumentConfiguration (the variant) rather than Instrument directly?

No, each instrument could have a Stringing object. If not, it would inherit from it's ancestry, just like most Instrument attributes.

> Is the semitone offset approach intentional for simplicity, or would you prefer something more explicit?

It is intentional. That way, the courses are independent of the specific tunings.

> Overlap Between standard_pitch and StringingTuning

The standard pitch is the unconfigured pitch of the string intrinsic to standard practice for that instrument. The Tuning objects configure alternative sets of pitches
