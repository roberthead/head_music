# A namespace for **kern rendering helpers
module HeadMusic::Notation::Kern
  # Converts a pitch into a kern pitch: its letter repeated for register,
  # lowercase from middle C up, followed by its accidental.
  module PitchWriter
    ACCIDENTALS = {0 => "", 1 => "#", 2 => "##", -1 => "-", -2 => "--"}.freeze

    module_function

    def token(pitch)
      letter = pitch.letter_name.to_s
      letters = (pitch.register >= 4) ? letter.downcase * (pitch.register - 3) : letter.upcase * (4 - pitch.register)
      "#{letters}#{accidental(pitch)}"
    end

    # The model alters by at most two semitones, and kern spells all five.
    def accidental(pitch)
      ACCIDENTALS.fetch(pitch.alteration_semitones.to_i)
    end
  end
end
