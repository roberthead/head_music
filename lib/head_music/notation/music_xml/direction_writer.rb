require_relative "xml_text"

# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Serializes a flow's dynamic events as <direction> elements. Directions add
  # no duration, so placing them changes no <backup> or <forward> a Writer
  # computes; each carries its own exact position instead, as an <offset> in
  # divisions from wherever in the measure it is written.
  class DirectionWriter
    include XmlText

    def initialize(plan)
      @plan = plan
    end

    # A part's dynamic events landing in this bar, written before any voice's
    # notes, so each is offset from the bar's own start. A part event carries
    # neither <voice> nor <staff>: other software defaults it to staff 1.
    def part_lines(part, bar_number)
      events_in_bar(part.dynamic_events, bar_number).flat_map do |event|
        direction_lines(event, offset_from(bar_start(bar_number), event.position))
      end
    end

    # A voice's dynamic events landing on one segment: the written fragment,
    # of possibly several a crossing note splits into, whose sounding note or
    # rest holds each event's position.
    def voice_lines(voice, bar_number, segment, voice_number: nil, staff_number: nil)
      events_for_segment(voice, bar_number, segment).flat_map do |event|
        direction_lines(event, offset_from(segment_start(segment), event.position),
          voice_number: voice_number, staff_number: staff_number)
      end
    end

    # A voice's dynamic events landing in a bar the voice fills with a single
    # whole-measure rest, so there is no segment to interleave them among.
    def voice_rest_lines(voice, bar_number, voice_number: nil, staff_number: nil)
      events_in_bar(voice.dynamic_events, bar_number).flat_map do |event|
        direction_lines(event, offset_from(bar_start(bar_number), event.position),
          voice_number: voice_number, staff_number: staff_number)
      end
    end

    # A voice's dynamic events landing after its last voice event, in the bar
    # where it ends, so there is no segment to hold them.
    def trailing_lines(voice, bar_number, voice_number: nil, staff_number: nil)
      events_in_bar(voice.dynamic_events, bar_number).select { |event| event.position >= voice.next_position }.flat_map do |event|
        direction_lines(event, offset_from(voice.next_position, event.position),
          voice_number: voice_number, staff_number: staff_number)
      end
    end

    private

    attr_reader :plan

    delegate :divisions, :flow, to: :plan

    def events_in_bar(dynamic_events, bar_number)
      dynamic_events.select { |event| event.position.bar_number == bar_number }
    end

    def events_for_segment(voice, bar_number, segment)
      events_in_bar(voice.dynamic_events, bar_number).select do |event|
        holding_segment(voice, event.position) == segment
      end
    end

    # The written fragment, in the position's own bar, of whichever voice
    # event is sounding at that position -- a held note or a rest, as a
    # voice's dynamic may fall under either.
    def holding_segment(voice, position)
      voice_event = voice.voice_event_sounding_at(position)
      return nil unless voice_event

      HeadMusic::Notation::BarSplitter.segments_of(voice_event).find { |segment| segment.bar_number == position.bar_number }
    end

    # A segment starts at its voice event's own position if this is the bar
    # that voice event began in, or at the bar's own start if the segment is
    # a tied continuation carried over from an earlier bar.
    def segment_start(segment)
      voice_event = segment.voice_event
      return voice_event.position if segment.bar_number == voice_event.position.bar_number

      bar_start(segment.bar_number)
    end

    def bar_start(bar_number)
      HeadMusic::Content::Position.new(flow, bar_number, 1, 0)
    end

    def offset_from(start_position, position)
      fraction = (offset_in_bar(position) - offset_in_bar(start_position)) * 4 * divisions
      unless fraction.denominator == 1
        raise RenderError,
          "cannot express a dynamic's offset from #{start_position} to #{position} in #{divisions} divisions per quarter note"
      end
      fraction.numerator
    end

    def offset_in_bar(position)
      HeadMusic::Notation::BarSplitter.offset_in_bar(position)
    end

    def direction_lines(event, offset, voice_number: nil, staff_number: nil)
      [
        %(#{INDENT * 3}<direction placement="below">),
        "#{INDENT * 4}<direction-type><dynamics><#{event.name_key}/></dynamics></direction-type>",
        offset.positive? ? "#{INDENT * 4}<offset>#{offset}</offset>" : nil,
        voice_number && "#{INDENT * 4}<voice>#{voice_number}</voice>",
        staff_number && "#{INDENT * 4}<staff>#{staff_number}</staff>",
        "#{INDENT * 3}</direction>"
      ].compact
    end
  end
end
