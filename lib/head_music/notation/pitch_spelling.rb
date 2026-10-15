# A module for visual music notation
module HeadMusic::Notation
  # Spells a pitch from a letter, an alteration, and an octave, raising the
  # reader's +errors+ UnsupportedFeatureError where the catalog has none.
  module PitchSpelling
    STEPS = %w[C D E F G A B].freeze
    SEMITONES_BY_STEP = {"C" => 0, "D" => 2, "E" => 4, "F" => 5, "G" => 7, "A" => 9, "B" => 11}.freeze

    module_function

    # The catalog spells octaves -1 through 9, altered by up to two semitones.
    def spelled(step, alter, octave, errors:, **where)
      if octave.between?(-1, 9) && alter.abs <= 2
        number = (octave + 1) * 12 + SEMITONES_BY_STEP.fetch(step) + alter
        pitch = HeadMusic::Rudiment::Pitch.from_number_and_letter(number, step)
        return pitch if pitch && pitch.midi_note_number == number && pitch.letter_name.to_s == step
      end

      raise errors::UnsupportedFeatureError.new("The pitch #{step} altered by #{alter} in octave #{octave} has no spelling", **where)
    end

    # The pitch of a number spelled with a letter, in the octave that puts
    # its natural nearest.
    def from_number_and_letter(number, step, errors:, **where)
      octave = ((number - SEMITONES_BY_STEP.fetch(step)) / 12.0).round - 1
      spelled(step, number - (octave + 1) * 12 - SEMITONES_BY_STEP.fetch(step), octave, errors: errors, **where)
    end
  end
end
