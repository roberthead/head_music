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
    Reading = Struct.new(:document_part, :measures, :tracks, :staves, :records) do
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
      @staves = 1
      @most_staves = 1
      @transposition = ConcertTransposition.new
      @records = []
    end

    def read
      measures = @document_part.measures.each_with_index.map { |measure, index| read_measure(measure, index) }
      Reading.new(document_part: @document_part, measures: measures, tracks: @tracks.values, staves: @most_staves, records: @records)
    end

    private

    def read_measure(measure, index)
      @where = {measure: measure.number, part: @document_part.id}
      @measure = Measure.new(index: index, number: measure.number, implicit: measure.implicit?, meter: @meter, clefs: {})
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
      when "sound" then read_measure_sound(element)
      when "barline" then note_record(:barline, element)
      end
    end

    def note_record(kind, element, **attributes)
      @records << MarkRecords::Pending.new(kind: kind, element: element, measure_index: @measure.index, **attributes)
    end

    # The timeline changes only at a downbeat, so a key or time in the
    # middle of a bar is skipped; its divisions still apply from there on.
    def read_attributes(element)
      attributes = AttributesReader.read(element, **@where)
      raise UnsupportedFeatureError.new("A <measure-repeat> is not supported", **@where) if attributes.measure_repeat

      @divisions = attributes.divisions if attributes.divisions
      @staves = attributes.staves if attributes.staves
      @most_staves = [@most_staves, @staves].max
      attributes.transpositions.each { |number, step| @transposition.change(number, step) }
      return unless @cursor.zero?

      @measure.clefs.merge!(attributes.clefs)
      @measure.key = concert_key(attributes.key) if attributes.key
      @meter = @measure.meter = attributes.meter if attributes.meter
    end

    def read_direction(element)
      note_record(:direction, element, cursor: @cursor, divisions: @divisions)
      sound = first_child(element, "sound")
      offset = text(element, "offset", **@where)
      read_sound(sound) if sound && (offset.nil? || rational(offset, "<offset>", **@where).zero?)
    end

    def read_measure_sound(element)
      note_record(:direction, element, cursor: @cursor, divisions: @divisions)
      read_sound(element)
    end

    def read_sound(element)
      tempo = rational(attribute(element, "tempo", **@where), "tempo", **@where)
      return unless tempo&.positive? && @cursor.zero?

      @measure.tempo ||= HeadMusic::Rudiment::Tempo.new("quarter", tempo)
    end

    def read_note(element)
      note = NoteReader.read(element, **@where)
      return read_grace(note) if note.grace
      return add_to_chord(note) if note.chord

      duration = duration_of(note.duration)
      measure_rest = note.rest && (note.measure_rest || duration == bar_length)
      @lead = track_for(note.voice).add(
        measure_index: @measure.index, cursor: @cursor, tolerance: division, fills_bar: measure_rest,
        rhythmic_value: measure_rest ? nil : rhythmic_value(note, duration), duration: duration,
        sounds: (note.rest || note.cue) ? [] : [sound(note)], cue: note.cue, tie_starts: [], tie_stops: [],
        staff: staff(note)
      )
      note_record(:note, element, event: @lead, chord: false)
      add_ties(@lead, note)
      add_tuplet_marks(track_for(note.voice), @lead, note)
      move(duration)
      reach(@cursor) unless measure_rest
    end

    def add_tuplet_marks(track, event, note)
      note.tuplets.each do |type, _number|
        track.tuplet_marks << VoiceTrack::TupletMark.new(event, type, note.normal_type, note.normal_dots)
      end
    end

    # A grace note takes no time. It waits for its voice's next main note,
    # and a grace chord's tones join the grace note before them. One with no
    # <type> is an eighth.
    def read_grace(note)
      return if note.rest || note.cue

      track = track_for(note.voice)
      tie_starts = if (note.ties.any? ? note.ties : note.tied).include?("start")
        [sound(note).to_s]
      else
        []
      end
      grace = track.queued_graces.last
      chord = (note.chord && grace) ? true : false
      if chord
        grace.sounds |= [sound(note)]
        grace.tie_starts |= tie_starts
      else
        grace = track.queue_grace(
          sounds: [sound(note)], rhythmic_value: grace_value(note), slashed: note.slashed,
          articulations: note.articulations.filter_map { |element| MarkingElements.articulation(element) }, tie_starts: tie_starts
        )
      end
      note_record(:note, note.element, grace: grace, chord: chord)
    end

    def grace_value(note)
      return HeadMusic::Rudiment::RhythmicValue.get(:eighth) unless note.type

      written = NoteReader.written_value(note, **@where)
      HeadMusic::Rudiment::RhythmicValue.new(written.unit, dots: written.dots)
    end

    # A chord tone sounds with the note before it, which must be as long. A
    # cue chord's tones are dropped with it.
    def add_to_chord(note)
      raise ParseError.new("A <chord/> rest is not supported", **@where) if note.rest
      raise ParseError.new("A <chord/> has no note before it", **@where) if @lead.nil? || (@lead.rest? && !@lead.cue)

      note_record(:note, note.element, event: @lead, chord: true)
      return if @lead.cue || note.cue

      duration = duration_of(note.duration)
      unless duration == @lead.duration && rhythmic_value(note, duration) == @lead.rhythmic_value
        raise UnsupportedFeatureError.new("Chord tones of different lengths are not supported", **@where)
      end
      @lead.sounds |= [sound(note)]
      add_ties(@lead, note)
    end

    # <tie> is what sounds, so it wins over <tied>, which is what is drawn.
    # A let-ring or continue says nothing about where a tie ends.
    def add_ties(event, note)
      return if event.rest?

      types = note.ties.any? ? note.ties : note.tied
      key = sound(note).to_s
      event.tie_starts << key if types.include?("start")
      event.tie_stops << key if types.include?("stop")
    end

    def staff(note)
      number = note.staff || 1
      raise ParseError.new("A <staff> of #{number} is beyond the part's #{@staves} staves", **@where) if number > @staves

      number
    end

    # A transposing part's key lands in concert pitch, as its notes do.
    def concert_key(key)
      fifths, mode = key
      [@transposition.concert_fifths(fifths), mode]
    end

    # A pitch sounds where its staff's transposition puts it. An unpitched
    # note is a sound of the part's instrument, or an unpitched sound of
    # none.
    def sound(note)
      return @transposition.concert(note.pitch, note.staff || 1) unless note.unpitched

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
