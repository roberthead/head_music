require_relative "xml_text"

# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Serializes a flow's dynamic events as <direction> elements. Directions add
  # no duration, so placing them changes no <backup> or <forward> a Writer
  # computes; each carries its own exact position instead, as an <offset> in
  # divisions from wherever in the measure it is written. Which slot of the
  # DirectionPlan a mark is written in is the plan's to say.
  class DirectionWriter
    include XmlText

    def initialize(plan)
      @plan = plan
    end

    # A part event carries neither <voice> nor <staff>: other software
    # defaults it to staff 1.
    def slot_lines(slot, voice_number: nil, staff_number: nil)
      direction_plan = plan.direction_plan(slot.part)
      direction_plan.marks(slot).flat_map do |mark|
        offset = offset_from(direction_plan.start(slot), mark)
        direction_lines(mark.item, offset, voice_number: voice_number, staff_number: staff_number)
      end
    end

    # A part's dynamic events landing in this bar, written before any voice's
    # notes, so each is offset from the bar's own start.
    def part_lines(part, bar_number)
      slot_lines(plan.direction_plan(part).bar(bar_number).part_slot)
    end

    # A voice's dynamic events landing on one segment: the written fragment,
    # of possibly several a crossing note splits into, whose sounding note or
    # rest holds each event's position.
    def voice_lines(voice, bar_number, segment, voice_number: nil, staff_number: nil)
      slot_lines(voice_slot(:segment, voice, bar_number, segment), voice_number: voice_number, staff_number: staff_number)
    end

    # A voice's dynamic events landing in a bar the voice fills with a single
    # whole-measure rest, so there is no segment to interleave them among.
    def voice_rest_lines(voice, bar_number, voice_number: nil, staff_number: nil)
      slot_lines(voice_slot(:whole_measure_rest, voice, bar_number), voice_number: voice_number, staff_number: staff_number)
    end

    # A voice's dynamic events landing after its last voice event, in the bar
    # where it ends, so there is no segment to hold them.
    def trailing_lines(voice, bar_number, voice_number: nil, staff_number: nil)
      slot_lines(voice_slot(:trailing, voice, bar_number), voice_number: voice_number, staff_number: staff_number)
    end

    private

    attr_reader :plan

    delegate :divisions, to: :plan

    def voice_slot(kind, voice, bar_number, segment = nil)
      DirectionPlan::Slot.new(kind, voice.part, voice, bar_number, segment)
    end

    def offset_from(start, mark)
      fraction = HeadMusic::Notation::BarSplitter.offset_in_bar(mark.position) * 4 * divisions
      unless fraction.denominator == 1
        raise RenderError,
          "cannot express the offset of the #{label(mark)} at #{mark.position} in #{divisions} divisions per quarter note"
      end
      fraction.numerator - start
    end

    def label(mark)
      "dynamic #{mark.item.name_key}"
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
