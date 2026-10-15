# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads a <pitch> (step, alter, octave) as a pitch spelled as written.
  module PitchReader
    STEPS = %w[C D E F G A B].freeze
    SEMITONES_BY_STEP = {"C" => 0, "D" => 2, "E" => 4, "F" => 5, "G" => 7, "A" => 9, "B" => 11}.freeze

    module_function

    def pitch(element, **where)
      step = XmlReading.text(element, "step", **where)
      raise ParseError.new(%(Unrecognized <step> "#{step}"), **where) unless STEPS.include?(step)

      alter = XmlReading.rational(XmlReading.text(element, "alter", **where), "<alter>", **where) || 0
      raise UnsupportedFeatureError.new("Microtonal <alter> #{alter.to_f} is not supported", **where) unless alter.denominator == 1

      octave = XmlReading.integer(XmlReading.text(element, "octave", **where), "<octave>", **where)
      raise ParseError.new("A <pitch> has no <octave>", **where) unless octave

      spelled(step, alter.to_i, octave, where)
    end

    def spelled(step, alter, octave, where)
      number = (octave + 1) * 12 + SEMITONES_BY_STEP.fetch(step) + alter
      pitch = HeadMusic::Rudiment::Pitch.from_number_and_letter(number, step)
      return pitch if pitch && pitch.midi_note_number == number && pitch.letter_name.to_s == step

      raise UnsupportedFeatureError.new("The pitch #{step} altered by #{alter} in octave #{octave} has no spelling", **where)
    end
  end
end
