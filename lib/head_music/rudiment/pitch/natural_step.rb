class HeadMusic::Rudiment::Pitch
  # Computes where a signed number of diatonic (letter-name) steps lands
  # relative to a starting letter name: the destination letter and how many
  # octaves the move crosses. Register-agnostic — it works purely from the
  # letter name's position in the scale, so the Pitch supplies the register.
  class NaturalStep
    attr_reader :letter_name, :num_steps

    def initialize(letter_name, num_steps)
      @letter_name = letter_name
      @num_steps = num_steps
    end

    def target_letter_name
      @target_letter_name ||= letter_name.steps_up(num_steps)
    end

    def octaves_delta
      whole_octaves = (num_steps.abs / 7) * (num_steps.negative? ? -1 : 1)
      return whole_octaves - 1 if wrapped_down?
      return whole_octaves + 1 if wrapped_up?

      whole_octaves
    end

    private

    def wrapped_down?
      num_steps.negative? && target_letter_name.position > letter_name.position
    end

    def wrapped_up?
      num_steps.positive? && target_letter_name.position < letter_name.position
    end
  end
end
