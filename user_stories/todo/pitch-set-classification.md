# Pitch Set Classification

As a music theorist

I want to classify pitch sets by their size and properties

So that I can analyze and categorize harmonic structures

Note: A PitchSet is unlike a PitchClassSet in that the pitches have spellings with octaves rather than Spellings only or octave-less 0-11 designations.

✅ **Already Implemented**: All scenarios below are complete in `pitch_set.rb`

All size-based classification methods (`monad?`, `dyad?`, `trichord?`, `tetrachord?`, etc.) are delegated to `PitchClassSet` which implements them.

The distinction between `triad?` (stacked thirds) and `trichord?` (any 3-pitch set) is properly implemented.
