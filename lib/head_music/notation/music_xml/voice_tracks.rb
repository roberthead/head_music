# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # A part's voice tracks, by voice label, as its notes fill them. Each
  # main note leads in its measure: the chord tones after it sound with it,
  # and a hidden one's chord tones go with it.
  class VoiceTracks
    def initialize(staves)
      @staves = staves
      @tracks = {}
      start_measure({})
    end

    def to_a
      @tracks.values
    end

    def start_measure(where)
      @where = where
      @lead = nil
      @hidden_lead = false
    end

    def hide_lead
      @hidden_lead = true
    end

    def add(note, durations, measure_index:, cursor:, duration:, fills_bar:)
      @hidden_lead = false
      track = track_for(note.voice)
      @lead = track.add(
        measure_index: measure_index, cursor: cursor, tolerance: durations.division, fills_bar: fills_bar,
        rhythmic_duration: fills_bar ? nil : durations.rhythmic_duration(note, duration, **@where), duration: duration,
        sounds: (note.rest || note.cue) ? [] : [sound(note)], cue: note.cue, tie_starts: [], tie_stops: [],
        staff: @staves.staff(note, **@where), ratio: note.ratio
      )
      add_ties(@lead, note)
      add_tuplet_marks(track, @lead, note)
      @lead
    end

    # A chord tone sounds with the note before it, which must be as long,
    # and in its voice where it names one; many exporters name none on a
    # chord tone. A cue chord's tones are dropped with it. Answers the
    # event it joins, or nil after a hidden note.
    def add_chord_tone(note, durations)
      return if @hidden_lead

      raise ParseError.new("A <chord/> rest is not supported", **@where) if note.rest
      raise ParseError.new("A <chord/> has no note before it", **@where) unless leads?(note)
      return @lead if @lead.cue || note.cue

      duration = durations.of(note.duration, **@where)
      unless duration == @lead.duration && durations.rhythmic_duration(note, duration, **@where) == @lead.rhythmic_duration
        raise UnsupportedFeatureError.new("Chord tones of different lengths are not supported", **@where)
      end
      @lead.sounds |= [sound(note)]
      add_ties(@lead, note)
      @lead
    end

    # A grace note takes no time. It waits for its voice's next main note,
    # and a grace chord's tones join the grace note before them. One with no
    # <type> is an eighth. Answers the grace and whether the note joined it,
    # or nil for a grace rest or cue.
    def add_grace(note)
      return if note.rest || note.cue

      track = track_for(note.voice)
      grace = track.queued_graces.last
      return [join_grace(grace, note), true] if note.chord && grace

      grace = track.queue_grace(
        sounds: [sound(note)], rhythmic_value: grace_value(note), slashed: note.slashed,
        articulations: note.articulations.filter_map { |element| MarkingElements.articulation(element) },
        tie_starts: tie_keys(note, "start")
      )
      [grace, false]
    end

    private

    def leads?(note)
      return false if @lead.nil? || (note.voice_stated && @lead.label != note.voice)

      !@lead.rest? || @lead.cue
    end

    def join_grace(grace, note)
      grace.sounds |= [sound(note)]
      grace.tie_starts |= tie_keys(note, "start")
      grace
    end

    def grace_value(note)
      return HeadMusic::Rudiment::RhythmicValue.get(:eighth) unless note.type

      written = NoteReader.written_value(note, **@where)
      HeadMusic::Rudiment::RhythmicValue.new(written.unit, dots: written.dots)
    end

    def add_ties(event, note)
      return if event.rest?

      event.tie_starts.concat(tie_keys(note, "start"))
      event.tie_stops.concat(tie_keys(note, "stop"))
    end

    # <tie> is what sounds, so it wins over <tied>, which is what is drawn.
    # A let-ring or continue says nothing about where a tie ends.
    def tie_keys(note, type)
      types = note.ties.any? ? note.ties : note.tied
      types.include?(type) ? [sound(note).to_s] : []
    end

    def add_tuplet_marks(track, event, note)
      note.tuplets.each do |type, _number|
        track.tuplet_marks << HeadMusic::Notation::VoiceTrack::TupletMark.new(event, type, note.normal_type, note.normal_dots)
      end
    end

    def sound(note)
      @staves.sound(note, **@where)
    end

    def track_for(label)
      @tracks[label] ||= HeadMusic::Notation::VoiceTrack.new(label)
    end
  end
end
