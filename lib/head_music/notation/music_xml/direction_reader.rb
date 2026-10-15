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
        owner.is_a?(HeadMusic::Content::Part) ? owner : owner.part
      end
    end

    WEDGE_KINDS = {"crescendo" => :crescendo, "diminuendo" => :diminuendo}.freeze

    def initialize
      @marks = []
    end

    def direction(record)
      return unless record.element.name == "direction"

      onset = onset_of(record)
      return unless onset

      owner = owner_of(record)
      XmlReading.children(record.element, "direction-type").each do |direction_type|
        direction_type.each_element do |child|
          case child.name
          when "dynamics" then read_dynamics(child, record, owner, onset)
          when "wedge" then read_wedge(child, record, owner, onset)
          end
        end
      end
    end

    def apply(flow)
      @marks.each { |mark| apply_dynamic(flow, mark) if mark.type == :dynamic }
      @marks.reject { |mark| mark.type == :dynamic }.group_by(&:part).each_value { |wedges| pair(flow, wedges) }
    end

    private

    def onset_of(record)
      text = XmlReading.text(record.element, "offset", measure: record.measure)
      offset = (text && record.divisions) ? XmlReading.rational(text, "<offset>", measure: record.measure) / (4 * record.divisions) : 0
      length = bar_length(record.part.flow, record.bar_number)
      (record.cursor + offset).clamp(0, length)
    rescue ParseError
      nil
    end

    def owner_of(record)
      label = XmlReading.text(record.element, "voice", measure: record.measure)
      (label && record.voice_for(label)) || record.part
    end

    def read_dynamics(dynamics, record, owner, onset)
      dynamics.each_element do |child|
        dynamic = HeadMusic::Rudiment::Dynamic.get(child.name)
        next unless dynamic

        @marks << Mark.new(owner, record.bar_number, onset, :dynamic, dynamic)
      end
    end

    def read_wedge(wedge, record, owner, onset)
      type = XmlReading.attribute(wedge, "type", measure: record.measure)
      kind = (type == "stop") ? :stop : WEDGE_KINDS[type]
      return unless kind

      number = XmlReading.attribute(wedge, "number", measure: record.measure) || "1"
      @marks << Mark.new(owner, record.bar_number, onset, kind, number)
    end

    def apply_dynamic(flow, mark)
      position = position_of(flow, mark)
      if mark.key.level?
        mark.owner.place_dynamic(position, mark.key)
      else
        accent(mark.owner, position, mark.key)
      end
    rescue ArgumentError
      nil
    end

    def accent(owner, position, dynamic)
      voices = owner.is_a?(HeadMusic::Content::Part) ? owner.voices : [owner]
      voices.each do |voice|
        voice_event = voice.voice_event_at(position)
        next if voice_event.nil? || voice_event.rest?

        voice_event.note_dynamic ||= dynamic.name_key
      end
    end

    def pair(flow, wedges)
      open = {}
      waiting = {}
      wedges.each do |mark|
        position = position_of(flow, mark)
        if mark.type == :stop
          start, from = open.delete(mark.key)
          start ? add_hairpin(start, from, position) : waiting[mark.key] = position
        else
          to = waiting.delete(mark.key)
          (to && position < to) ? add_hairpin(mark, position, to) : open[mark.key] = [mark, position]
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
