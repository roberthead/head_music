# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads a <pitch> (step, alter, octave) as a pitch spelled as written.
  module PitchReader
    module_function

    def pitch(element, **where)
      step = XmlReading.text(element, "step", **where)
      raise ParseError.new(%(Unrecognized <step> "#{step}"), **where) unless HeadMusic::Notation::PitchSpelling::STEPS.include?(step)

      alter = XmlReading.rational(XmlReading.text(element, "alter", **where), "<alter>", **where) || 0
      raise UnsupportedFeatureError.new("Microtonal <alter> #{alter.to_f} is not supported", **where) unless alter.denominator == 1

      octave = XmlReading.integer(XmlReading.text(element, "octave", **where), "<octave>", **where)
      raise ParseError.new("A <pitch> has no <octave>", **where) unless octave

      HeadMusic::Notation::PitchSpelling.spelled(step, alter.to_i, octave, errors: HeadMusic::Notation::MusicXML, **where)
    end
  end
end
