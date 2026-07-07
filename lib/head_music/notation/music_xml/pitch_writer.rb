# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Converts pitches into the trio of values MusicXML's <pitch> element needs.
  #
  # Unlike ABC, MusicXML's <alter> is absolute rather than bar-persistent, so
  # no oracle or mutable state is required: each pitch maps to its attributes
  # independent of any other pitch that came before it.
  class PitchWriter
    # Returns a Hash of the step, alter, and octave for the pitch's
    # <pitch> element. Alter is nil when the pitch is natural, in which
    # case the caller should omit the <alter> element entirely.
    def self.attributes(pitch)
      pitch = HeadMusic::Rudiment::Pitch.get(pitch)
      {
        step: pitch.letter_name.to_s,
        alter: pitch.alteration_semitones,
        octave: pitch.register
      }
    end
  end
end
