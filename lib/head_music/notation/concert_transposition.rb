# A module for visual music notation
module HeadMusic::Notation
  # The transposition in force in a part, by staff: one with a number
  # applies to its staff alone, and one without to every staff. A later
  # transposition replaces the one before it, and one of nothing returns a
  # staff to concert pitch, as after a change to an instrument in C.
  #
  # Sounding = written + transposition, so a written pitch moves by its
  # chromatic and diatonic steps, and its octaves, to sound, keeping a
  # letter name the diatonic steps give. Spelling errors raise the reader's
  # +errors+ UnsupportedFeatureError.
  class ConcertTransposition
    Step = Data.define(:diatonic, :chromatic, :octaves) do
      def identity?
        diatonic.zero? && chromatic.zero? && octaves.zero?
      end

      def semitones
        chromatic + 12 * octaves
      end

      def steps
        diatonic + 7 * octaves
      end

      # How far round the circle of fifths the key moves.
      def fifths
        7 * chromatic - 12 * diatonic
      end
    end

    def initialize(errors:)
      @errors = errors
      @steps = {}
    end

    def change(number, step)
      @steps.clear unless number
      @steps[number] = step
    end

    def concert(pitch, staff, **where)
      step = step_for(staff)
      return pitch unless step && !step.identity?

      letter = PitchSpelling::STEPS[(PitchSpelling::STEPS.index(pitch.letter_name.to_s) + step.steps) % 7]
      PitchSpelling.from_number_and_letter(pitch.midi_note_number + step.semitones, letter, errors: @errors, **where)
    end

    def concert_fifths(fifths, staff = 1)
      fifths + (step_for(staff)&.fifths || 0)
    end

    private

    def step_for(staff)
      @steps.fetch(staff) { @steps[nil] }
    end
  end
end
