module HeadMusic
  module Notation
    # The members of a chord that share a letter and octave with another
    # member under a different alteration, as F4 does with F♯4. Each shows its
    # accidental, whatever the key and the bar imply.
    module ChordClashes
      module_function

      def among(pitches)
        pitches.group_by { |pitch| place(pitch) }.values
          .select { |same_place| same_place.map { |pitch| pitch.alteration_semitones.to_i }.uniq.size > 1 }
          .flatten
      end

      def place(pitch)
        [pitch.letter_name.to_s, pitch.register]
      end
    end
  end
end
