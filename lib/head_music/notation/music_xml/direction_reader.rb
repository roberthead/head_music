require_relative "mark_reader"

# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads dynamics and wedges from <direction>s, each at its cursor plus its
  # <offset>, clamped to its bar. A direction belongs to the voice its
  # <voice> names, or else to its part. A level is placed as a dynamic event,
  # the first at a position winning; an accent goes to the notes its owner
  # attacks there, or to none.
  #
  # Wedges pair per part by number in document order, as MusicXML numbers
  # them: a start on an open number replaces the one before, and a wedge
  # still open at the end is dropped, as is a hairpin its owner refuses. A
  # stop with nothing open waits for a later start of its number that sounds
  # before it, since MuseScore can write a stop ahead of its own start; one
  # that finds none is dropped.
  class DirectionReader < MarkReader
    Mark = Data.define(:owner, :bar_number, :onset, :type, :key) do
      def part
        part? ? owner : owner.part
      end

      def voices
        part? ? owner.voices : [owner]
      end

      def part?
        owner.is_a?(HeadMusic::Content::Part)
      end
    end

    WEDGE_KINDS = {"crescendo" => :crescendo, "diminuendo" => :diminuendo}.freeze

    def initialize
      @marks = []
    end

    def direction(record)
      element = record.element
      return unless element.name == "direction"

      onset = onset_of(record)
      return unless onset

      mark = Mark.new(owner_of(record), record.bar_number, onset, nil, nil)
      XmlReading.children(element, "direction-type").each do |direction_type|
        direction_type.each_element do |child|
          case child.name
          when "dynamics" then read_dynamics(child, mark)
          when "wedge" then read_wedge(child, mark, record.measure)
          end
        end
      end
    end

    def apply(flow)
      dynamics, wedges = @marks.partition { |mark| mark.type == :dynamic }
      dynamics.each { |mark| apply_dynamic(flow, mark) }
      wedges.group_by(&:part).each_value { |part_wedges| pair(flow, part_wedges) }
    end

    private

    def onset_of(record)
      measure = record.measure
      divisions = record.divisions
      text = XmlReading.text(record.element, "offset", measure: measure)
      offset = (text && divisions) ? XmlReading.rational(text, "<offset>", measure: measure) / (4 * divisions) : 0
      (record.cursor + offset).clamp(0, bar_length(record.part.flow, record.bar_number))
    rescue ParseError
      nil
    end

    def owner_of(record)
      label = XmlReading.text(record.element, "voice", measure: record.measure)
      (label && record.voice_for(label)) || record.part
    end

    def read_dynamics(dynamics, mark)
      dynamics.each_element do |child|
        dynamic = HeadMusic::Rudiment::Dynamic.get(child.name)
        @marks << mark.with(type: :dynamic, key: dynamic) if dynamic
      end
    end

    def read_wedge(wedge, mark, measure)
      type = XmlReading.attribute(wedge, "type", measure: measure)
      kind = (type == "stop") ? :stop : WEDGE_KINDS[type]
      @marks << mark.with(type: kind, key: XmlReading.attribute(wedge, "number", measure: measure) || "1") if kind
    end

    def apply_dynamic(flow, mark)
      position = position_of(flow, mark)
      dynamic = mark.key
      dynamic.level? ? mark.owner.place_dynamic(position, dynamic) : accent(mark, position)
    rescue ArgumentError
      nil
    end

    def accent(mark, position)
      mark.voices.filter_map { |voice| voice.voice_event_at(position) }.reject(&:rest?).each do |voice_event|
        voice_event.note_dynamic ||= mark.key.name_key
      end
    end

    def pair(flow, wedges)
      open = {}
      waiting = {}
      wedges.each do |mark|
        position = position_of(flow, mark)
        number = mark.key
        if mark.type == :stop
          start, from = open.delete(number)
          start ? add_hairpin(start, from, position) : waiting[number] = position
        else
          to = waiting.delete(number)
          (to && position < to) ? add_hairpin(mark, position, to) : open[number] = [mark, position]
        end
      end
    end

    def add_hairpin(start, from, to)
      start.owner.add_span(start.type, from: from, to: to)
    rescue ArgumentError
      nil
    end

    def position_of(flow, mark)
      bar_number = mark.bar_number
      if bar_number == flow.last_sounding_bar_number && mark.onset >= bar_length(flow, bar_number)
        return flow.final_barline_position
      end

      HeadMusic::Notation::BarSplitter.position_at(flow, bar_number, mark.onset)
    end

    def bar_length(flow, bar_number)
      meter = flow.meter_at(bar_number)
      Rational(meter.top_number, meter.bottom_number)
    end
  end
end
