module HeadMusic::Notation::MEI
  # The tempo a <tempo> states: @mm beats a minute of its @mm.unit and
  # @mm.dots, a quarter where it names none, or else its @midi.bpm in
  # quarter notes. A tempo with text only states none.
  module TempoReading
    module_function

    def tempo(element, **where)
      mm = AttributeValues.read(element, "mm", **where, element: element)
      return ScoreDefValues.tempo(element, **where) unless mm

      unit = AttributeValues.read(element, "mm.unit", **where, element: element) || "quarter"
      dots = AttributeValues.read(element, "mm.dots", **where, element: element) || 0
      HeadMusic::Rudiment::Tempo.new(HeadMusic::Rudiment::RhythmicValue.new(unit, dots: dots), ScoreDefValues.number(mm))
    end
  end
end
