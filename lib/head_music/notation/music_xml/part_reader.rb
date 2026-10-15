require_relative "xml_reading"

# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Walks one part's measures in document order into exact Rational records:
  # each voice's events at the measure and cursor they were read at, and what
  # each measure states and how far its music reaches. Every time is a
  # fraction of a whole note, a <duration> being Rational(duration, 4 *
  # divisions), with the divisions in force within this part.
  class PartReader
    include XmlReading

    # The key, meter, and tempo a measure states on its downbeat; the extent
    # its notes and forwards reach; and one division where it ends, the
    # rounding its extent may carry.
    Measure = Struct.new(:index, :number, :implicit, :extent, :meter, :key, :tempo, :tolerance)
    Reading = Struct.new(:document_part, :measures, :tracks) do
      def id
        document_part.id
      end
    end

    def initialize(document_part, instrument: nil)
      @document_part = document_part
      @instrument = instrument
      @tracks = {}
      @divisions = nil
      @meter = HeadMusic::Rudiment::Meter.default
    end

    def read
      measures = @document_part.measures.each_with_index.map { |measure, index| read_measure(measure, index) }
      Reading.new(document_part: @document_part, measures: measures, tracks: @tracks.values)
    end

    private

    def read_measure(measure, index)
      @where = {measure: measure.number, part: @document_part.id}
      @measure = Measure.new(index: index, number: measure.number, implicit: measure.implicit?, meter: @meter)
      @cursor = 0
      @lead = nil
      measure.element.each_element { |element| read_element(element) }
      @measure.tolerance = @divisions ? division : 0
      @measure
    end

    def read_element(element)
      case element.name
      when "attributes" then read_attributes(element)
      when "note" then read_note(element)
      when "backup" then move(-duration_of(text(element, "duration", **@where)))
      when "forward" then reach(move(duration_of(text(element, "duration", **@where))))
      when "direction" then read_direction(element)
      when "sound" then read_sound(element)
      end
    end

    # The timeline changes only at a downbeat, so a key or time in the
    # middle of a bar is skipped; its divisions still apply from there on.
    def read_attributes(element)
      attributes = AttributesReader.read(element, **@where)
      raise UnsupportedFeatureError.new("A <measure-repeat> is not supported", **@where) if attributes.measure_repeat

      @divisions = attributes.divisions if attributes.divisions
      return unless @cursor.zero?

      @measure.key = attributes.key if attributes.key
      @meter = @measure.meter = attributes.meter if attributes.meter
    end

    def read_direction(element)
      sound = first_child(element, "sound")
      offset = text(element, "offset", **@where)
      read_sound(sound) if sound && (offset.nil? || rational(offset, "<offset>", **@where).zero?)
    end

    def read_sound(element)
      tempo = rational(attribute(element, "tempo", **@where), "tempo", **@where)
      return unless tempo&.positive? && @cursor.zero?

      @measure.tempo ||= HeadMusic::Rudiment::Tempo.new("quarter", tempo)
    end

    def read_note(element)
      note = NoteReader.read(element, **@where)
      return add_to_chord(note) if note.chord

      duration = duration_of(note.duration)
      measure_rest = note.rest && (note.measure_rest || duration == bar_length)
      @lead = track_for(note.voice).add(
        measure_index: @measure.index, cursor: @cursor, tolerance: division, fills_bar: measure_rest,
        rhythmic_value: measure_rest ? nil : rhythmic_value(note, duration), duration: duration,
        sounds: (note.rest || note.cue) ? [] : [sound(note)], cue: note.cue
      )
      move(duration)
      reach(@cursor) unless measure_rest
    end

    # A chord tone sounds with the note before it, which must be as long. A
    # cue chord's tones are dropped with it.
    def add_to_chord(note)
      raise ParseError.new("A <chord/> rest is not supported", **@where) if note.rest
      raise ParseError.new("A <chord/> has no note before it", **@where) if @lead.nil? || (@lead.rest? && !@lead.cue)
      return if @lead.cue || note.cue

      duration = duration_of(note.duration)
      unless duration == @lead.duration && rhythmic_value(note, duration) == @lead.rhythmic_value
        raise UnsupportedFeatureError.new("Chord tones of different lengths are not supported", **@where)
      end
      @lead.sounds |= [sound(note)]
    end

    # An unpitched note is a sound of the part's instrument, or an unpitched
    # sound of none.
    def sound(note)
      return note.pitch unless note.unpitched

      HeadMusic::Rudiment::UnpitchedSound.get(@instrument) || HeadMusic::Rudiment::UnpitchedSound.get(nil)
    end

    def move(duration)
      @cursor += duration
      raise ParseError.new("A <backup> reaches before the start of its measure", **@where) if @cursor.negative?

      @cursor
    end

    def rhythmic_value(note, duration)
      written = NoteReader.written_value(note, **@where)
      return value_from_duration(note, duration) unless written

      if (written.link_fraction - duration).abs > division
        raise ParseError.new(
          "A <duration> of #{note.duration} disagrees with its #{written} at #{@divisions} divisions", **@where
        )
      end
      written
    end

    # A note with no <type> takes its value from its <duration>, under its
    # <time-modification> or, failing that, the ratio its length implies.
    def value_from_duration(note, duration)
      value = if note.ratio
        HeadMusic::Notation::DottedDuration.rhythmic_value_for(duration, tuplet: note.ratio)
      else
        HeadMusic::Notation::DottedDuration.rest_value(duration)
      end
      value || raise(UnsupportedFeatureError.new("No note value spans a <duration> of #{note.duration}", **@where))
    end

    def duration_of(text)
      raise ParseError.new("A <duration> is missing", **@where) unless text
      raise ParseError.new("A <duration> has no <divisions> in force", **@where) unless @divisions

      duration = rational(text, "<duration>", **@where)
      raise ParseError.new("A <duration> must be positive", **@where) unless duration.positive?

      duration / (4 * @divisions)
    end

    def division
      1 / (4 * @divisions)
    end

    def bar_length
      Rational(@meter.top_number, @meter.bottom_number)
    end

    def reach(cursor)
      @measure.extent = [@measure.extent, cursor].compact.max
    end

    def track_for(label)
      @tracks[label] ||= VoiceTrack.new(label)
    end
  end
end
