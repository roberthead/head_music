module HeadMusic::Notation::MEI
  # The tempo a <tempo> states, with its text: @mm beats a minute of its
  # @mm.unit and @mm.dots, a quarter where it names none; else, for text
  # alone, the tempo its words name, recorded as no metronome mark, at its
  # @midi.bpm in quarter notes where that differs; else its @midi.bpm alone.
  # A <tempo> with neither states none.
  module TempoReading
    module_function

    # +text+ is the element's text as the editorial rule reads it.
    def tempo(element, text = nil, **where)
      text = text.to_s.strip
      text = nil if text.empty?
      mm = AttributeValues.read(element, "mm", **where, element: element)
      return metronome_mark(element, mm, text, **where) if mm
      return ScoreDefValues.tempo(element, **where) unless text

      words(element, text, **where)
    end

    # A gradual change, rather than a tempo.
    def continuous?(element, **where)
      XmlReading.attribute(element, "func", **where, element: element) == "continuous"
    end

    def metronome_mark(element, mm, text, **where)
      unit = AttributeValues.read(element, "mm.unit", **where, element: element) || "quarter"
      dots = AttributeValues.read(element, "mm.dots", **where, element: element) || 0
      HeadMusic::Rudiment::Tempo.new(HeadMusic::Rudiment::RhythmicValue.new(unit, dots: dots), ScoreDefValues.number(mm), text: text)
    end

    def words(element, text, **where)
      named = HeadMusic::Rudiment::Tempo.for_text(text)
      played = ScoreDefValues.tempo(element, **where)
      return named unless played && played.beats_per_minute != named.beats_per_minute * named.beat_value.fraction * 4

      HeadMusic::Rudiment::Tempo.new("quarter", played.beats_per_minute, text: text, metronome_mark: false)
    end
  end
end
