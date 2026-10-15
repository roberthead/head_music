# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Groups a placed voice's tuplets from the <tuplet> starts and stops its
  # track read, after placement, since a voice refuses a note placed inside
  # a group. A bracket runs from the first link of the event it starts on to
  # the last link of the one it stops on, so a bracket ending on the first
  # piece of a tied note groups by link. Its unit is the <normal-type> of
  # its first note, or failing that that note's own written value.
  #
  # A start while a bracket is open in the same voice is a nested tuplet,
  # which raises. A start or stop with no partner, and a bracket the voice
  # refuses, leave the run ungrouped, its values keeping their ratio, as a
  # <time-modification> with no <tuplet> does.
  class TupletReader
    def initialize(voice, track, reading)
      @voice = voice
      @track = track
      @reading = reading
    end

    def group
      open = nil
      @track.tuplet_marks.each do |mark|
        if mark.type == "start"
          raise_nested(mark) if open
          open = mark
        elsif mark.type == "stop" && open
          add_group(open, mark)
          open = nil
        end
      end
    end

    private

    def add_group(start, stop)
      first = link(start.event, start.event.first_link)
      last = link(stop.event, stop.event.last_link)
      return unless first && last

      @voice.group_tuplet(from: first.start_position, to: last.end_position, unit: unit(start, first))
    rescue ArgumentError
      nil
    end

    def link(event, index)
      voice_event = event.head.voice_event
      voice_event && HeadMusic::Content::TupletGroup.links_of(voice_event)[index]
    end

    def unit(mark, link)
      return HeadMusic::Rudiment::RhythmicValue.new(link.rhythmic_value.unit, dots: link.rhythmic_value.dots) unless mark.normal_type

      unit_name = NoteReader::UNIT_NAMES_BY_TYPE[mark.normal_type]
      unit_name && HeadMusic::Rudiment::RhythmicValue.new(unit_name, dots: mark.normal_dots)
    end

    def raise_nested(mark)
      measure = @reading.measures[mark.event.measure_index]
      raise UnsupportedFeatureError.new("Nested tuplets are not supported", measure: measure.number, part: @reading.id)
    end
  end
end
