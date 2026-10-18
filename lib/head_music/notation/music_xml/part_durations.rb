require_relative "xml_reading"

# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # The divisions and meter in force within a part, by which a <duration>
  # is read as a fraction of a whole note, Rational(duration, 4 *
  # divisions), and checked against a bar and a note's written value.
  PartDurations = Data.define(:divisions, :meter) do
    include XmlReading

    def initialize(divisions: nil, meter: HeadMusic::Rudiment::Meter.default)
      super
    end

    # A <backup> or <forward> of nothing moves nothing, as music21 writes
    # some, so only a note's duration must be positive.
    def of(text, moving: false, **where)
      raise ParseError.new("A <duration> is missing", **where) unless text
      raise ParseError.new("A <duration> has no <divisions> in force", **where) unless divisions

      duration = rational(text, "<duration>", **where)
      if duration.negative? || (duration.zero? && !moving)
        raise ParseError.new("A <duration> must be positive", **where)
      end

      duration / (4 * divisions)
    end

    def division
      1 / (4 * divisions)
    end

    # The rounding a measure's extent may carry, nothing before any
    # <divisions> is read.
    def tolerance
      divisions ? division : 0
    end

    def bar_length
      Rational(meter.top_number, meter.bottom_number)
    end

    def overfull?(extent)
      divisions && extent && extent - bar_length >= division
    end

    def whole_bar_rest?(note, duration)
      note.rest && (note.measure_rest || duration == bar_length)
    end

    # A rest with no <type> over the bar by no more than a division is the
    # whole-measure rest music21 writes, its <duration> the sum of the
    # rounded ones the bar's notes would have.
    def measure_rest?(note, duration)
      whole_bar_rest?(note, duration) || (note.rest && !note.type && duration > bar_length && duration - bar_length <= division)
    end

    def rhythmic_value(note, duration, **where)
      written = NoteReader.written_value(note, **where)
      return value_from_duration(note, duration, **where) unless written

      if (written.link_fraction - duration).abs > division
        raise ParseError.new(
          "A <duration> of #{note.duration} disagrees with its #{written} at #{divisions} divisions", **where
        )
      end
      written
    end

    private

    # A note with no <type> takes its value from its <duration>, under its
    # <time-modification> or, failing that, the ratio its length implies.
    def value_from_duration(note, duration, **where)
      value = if note.ratio
        HeadMusic::Notation::DottedDuration.rhythmic_value_for(duration, tuplet: note.ratio)
      else
        HeadMusic::Notation::DottedDuration.rest_value(duration)
      end
      value || raise(UnsupportedFeatureError.new("No note value spans a <duration> of #{note.duration}", **where))
    end
  end
end
