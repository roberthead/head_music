# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Groups a placed voice's tuplets from the <tuplet> starts and stops its
  # track read, after placement, since a voice refuses a note placed inside
  # a group. A bracket runs from the first link of the event it starts on to
  # the last link of the one it stops on, so a bracket ending on the first
  # piece of a tied note groups by link. Its unit is the <normal-type> of
  # its first note, or failing that that note's own written value.
  #
  # A start whose <time-modification> run has ended, at an event of no
  # ratio or one no multiple of its own, has no stop, and is abandoned. A start while a
  # bracket's run goes on in the same voice is a nested tuplet, which
  # raises. A start or stop with no partner, and a bracket the voice
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
        open = nil if open && run_ended?(open, mark)
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

    # A nested tuplet's <time-modification> is the product of its own ratio
    # and its outer one's, so a run goes on into a start whose ratio is a
    # multiple of the run's.
    def run_ended?(start, mark)
      ratio = start.event.ratio
      @track.events[index(start.event)...index(mark.event)].any? { |event| event.ratio != ratio } ||
        !within?(mark.event.ratio, ratio)
    end

    def within?(inner, outer)
      return inner == outer unless inner && outer

      (inner.actual % outer.actual).zero? && (inner.normal % outer.normal).zero?
    end

    def index(event)
      @indexes ||= @track.events.each_with_index.with_object({}.compare_by_identity) { |(track_event, at), indexes| indexes[track_event] = at }
      @indexes.fetch(event)
    end

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
