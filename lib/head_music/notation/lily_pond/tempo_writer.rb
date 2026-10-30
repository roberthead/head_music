# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # Writes a tempo as a \tempo command, with its text, its metronome mark, or
  # both, and the words of a ramp or an "a tempo" as italic markup above the
  # staff, which the TempoReader and MarkReader read back.
  module TempoWriter
    # A flow with no tempo written reads at this one.
    DEFAULT_TEMPO = HeadMusic::Rudiment::Tempo.new("quarter", 120)

    module_function

    def token(tempo)
      text = %("#{StringText.escape(tempo.text)}") if tempo.text
      metronome = "#{DurationWriter.token(tempo.beat_value)} = #{tempo.beats_per_minute.round}" if tempo.metronome_mark? || !text
      ["\\tempo", text, metronome].compact.join(" ")
    end

    def text_mark(text)
      %(^\\markup \\italic "#{StringText.escape(text)}")
    end

    # What a \tempo cannot write: a count of beats that is not whole, or a
    # beat no single dotted note value is.
    def problem(tempo)
      beat_value = tempo.beat_value
      if beat_value.tuplet_ratio || !DurationWriter::DURATIONS_BY_UNIT_NAME.key?(beat_value.unit_name)
        "the tempo beat of a #{beat_value}"
      elsif tempo.beats_per_minute != tempo.beats_per_minute.round && (tempo.metronome_mark? || !tempo.text)
        "the fractional tempo of #{tempo.beats_per_minute} beats per minute"
      end
    end
  end
end
