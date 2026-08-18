class HeadMusic::Rudiment::Pitch
  # The number of diatonic steps from one pitch to another, signed: the letter
  # steps between them, plus seven for each octave crossed.
  #
  # The letter steps already carry one wrap of the scale, so a register
  # difference counts one octave short whenever the starting letter sits above
  # the ending letter -- C4 to A4 is five steps, not twelve.
  class StepDistance
    STEPS_PER_OCTAVE = 7

    attr_reader :from_pitch, :to_pitch

    def initialize(from_pitch, to_pitch)
      @from_pitch = from_pitch
      @to_pitch = HeadMusic::Rudiment::Pitch.get(to_pitch)
    end

    def steps
      from_pitch.letter_name_steps_to(to_pitch) + STEPS_PER_OCTAVE * octave_changes
    end

    private

    def octave_changes
      to_pitch.register - from_pitch.register - octave_adjustment
    end

    def octave_adjustment
      pitch_class_above? ? 1 : 0
    end

    def pitch_class_above?
      from_pitch.natural_pitch_class_number > to_pitch.natural_pitch_class_number
    end
  end
end
