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
    Measure = Struct.new(:index, :number, :implicit, :extent, :meter, :key, :tempo, :tolerance, :clefs)
    Reading = Struct.new(:document_part, :measures, :tracks, :staves, :part_symbol, :records) do
      def id
        document_part.id
      end

      def errors
        HeadMusic::Notation::MusicXML
      end

      def where(measure_index)
        {measure: measure_index && measures[measure_index]&.number, part: id}
      end
    end

    def initialize(document_part, instrument: nil)
      @document_part = document_part
      @durations = PartDurations.new
      @staves = PartStaves.new(instrument: instrument)
      @tracks = VoiceTracks.new(@staves)
      @records = []
    end

    def read
      measures = @document_part.measures.each_with_index.map { |measure, index| read_measure(measure, index) }
      Reading.new(document_part: @document_part, measures: measures, tracks: @tracks.to_a, staves: @staves.most, part_symbol: @staves.part_symbol, records: @records)
    end

    private

    def read_measure(measure, index)
      @where = {measure: measure.number, part: @document_part.id}
      @measure = Measure.new(index: index, number: measure.number, implicit: measure.implicit?, meter: @durations.meter, clefs: {})
      @cursor = 0
      @tracks.start_measure(@where)
      @timing = WrittenTiming.new
      measure.element.each_element { |element| read_element(element) }
      @measure.tolerance = @durations.tolerance
      @measure.extent = @timing.extent if @durations.overfull?(@measure.extent) && @timing.retime(@durations.bar_length)
      @measure
    end

    def read_element(element)
      case element.name
      when "attributes" then read_attributes(element)
      when "note" then read_note(element)
      when "backup" then read_move(element, -1)
      when "forward" then read_move(element, 1)
      when "direction" then read_direction(element)
      when "sound" then read_measure_sound(element)
      when "barline" then note_record(:barline, element)
      end
    end

    def read_move(element, sign)
      skip(sign * @durations.of(text(element, "duration", **@where), moving: true, **@where), reaches: sign.positive?)
    end

    def note_record(kind, element, **attributes)
      MarkRecords::Pending.new(kind: kind, element: element, measure_index: @measure.index, **attributes).tap do |pending|
        @records << pending
      end
    end

    # The timeline changes only at a downbeat, so a key or time in the
    # middle of a bar is skipped; its divisions still apply from there on.
    def read_attributes(element)
      attributes = AttributesReader.read(element, **@where)
      raise UnsupportedFeatureError.new("A <measure-repeat> is not supported", **@where) if attributes.measure_repeat

      @durations = @durations.with(divisions: attributes.divisions) if attributes.divisions
      @staves.change(attributes)
      return unless @cursor.zero?

      @measure.clefs.merge!(attributes.clefs)
      @measure.key = @staves.concert_key(attributes.key) if attributes.key
      @durations = @durations.with(meter: @measure.meter = attributes.meter) if attributes.meter
    end

    def read_direction(element)
      record_direction(element)
      sound = first_child(element, "sound")
      offset = text(element, "offset", **@where)
      read_sound(sound) if sound && (offset.nil? || rational(offset, "<offset>", **@where).zero?)
    end

    def read_measure_sound(element)
      record_direction(element)
      read_sound(element)
    end

    def record_direction(element)
      @timing.direction(note_record(:direction, element, cursor: @cursor, divisions: @durations.divisions))
    end

    def read_sound(element)
      tempo = rational(attribute(element, "tempo", **@where), "tempo", **@where)
      return unless tempo&.positive? && @cursor.zero?

      @measure.tempo ||= HeadMusic::Rudiment::Tempo.new("quarter", tempo)
    end

    def read_note(element)
      note = NoteReader.read(element, **@where)
      if note.hidden
        read_hidden(note)
      elsif note.grace
        read_grace(note)
      elsif note.chord
        lead = @tracks.add_chord_tone(note, @durations)
        note_record(:note, element, event: lead, chord: true) if lead
      else
        read_main(note)
      end
    end

    def read_main(note)
      duration = @durations.of(note.duration, **@where)
      measure_rest = @durations.measure_rest?(note, duration)
      event = @tracks.add(note, @durations, measure_index: @measure.index, cursor: @cursor, duration: duration, fills_bar: measure_rest)
      note_record(:note, note.element, event: event, chord: false)
      value = measure_rest ? @durations.bar_length : note.type && event.rhythmic_value.fraction
      advance(duration, reaches: !measure_rest)
      @timing.note(note.voice, value, event, reaches: !measure_rest)
    end

    # A note or rest that does not print is no part of the notation, as the
    # trills music21 realizes in a hidden voice and the rests MuseScore
    # hides beside a crossing hand are not, so it takes its time as a
    # <forward> does, and its chord tones and grace notes go with it.
    def read_hidden(note)
      return if note.grace || note.chord

      @tracks.hide_lead
      duration = @durations.of(note.duration, **@where)
      skip(duration, reaches: !@durations.whole_bar_rest?(note, duration))
    end

    def read_grace(note)
      grace, chord = @tracks.add_grace(note)
      note_record(:note, note.element, grace: grace, chord: chord) if grace
    end

    # Moves the cursor by a time no note is written in.
    def skip(duration, reaches:)
      advance(duration, reaches: reaches)
      @timing.move(duration, reaches: reaches)
    end

    def advance(duration, reaches:)
      @cursor += duration
      raise ParseError.new("A <backup> reaches before the start of its measure", **@where) if @cursor.negative?

      @measure.extent = [@measure.extent, @cursor].compact.max if reaches
    end
  end
end
