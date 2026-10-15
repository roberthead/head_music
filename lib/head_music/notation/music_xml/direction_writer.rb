# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Serializes a flow's dynamic events and hairpin ends as <direction>
  # elements, a hairpin as a <wedge> start and stop. Directions add
  # no duration, so placing them changes no <backup> or <forward> a Writer
  # computes; each carries its own exact position instead, as an <offset> in
  # divisions from wherever in the measure it is written. Which slot of the
  # DirectionPlan a mark is written in is the plan's to say.
  class DirectionWriter
    include HeadMusic::Notation::XmlText

    def initialize(plan)
      @plan = plan
    end

    # A part event carries neither <voice> nor <staff>: other software
    # defaults it to staff 1.
    def slot_lines(slot, voice_number: nil, staff_number: nil)
      direction_plan = plan.direction_plan(slot.part)
      direction_plan.marks(slot).flat_map do |mark|
        offset = offset_from(direction_plan.start(slot), slot, mark)
        direction_lines(direction_type(slot.part, mark), offset, voice_number: voice_number, staff_number: staff_number)
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

    # A mark on the final barline is written in the last bar, at its end.
    def offset_from(start, slot, mark)
      bar_number = slot.bar_number
      return plan.whole_measure_duration(bar_number) - start unless mark.position.bar_number == bar_number

      fraction = Divisions.mark_offset(plan.flow, mark.position, mark_voices(slot)) * 4 * divisions
      unless fraction.denominator == 1
        raise RenderError,
          "cannot express the offset of the #{label(mark)} at #{mark.position} in #{divisions} divisions per quarter note"
      end
      fraction.numerator - start
    end

    def mark_voices(slot)
      slot.voice ? [slot.voice] : slot.part.voices
    end

    def label(mark)
      case mark.type
      when :dynamic then "dynamic #{mark.item.name_key}"
      when :start then "#{mark.item.name_key} start"
      else "#{mark.item.name_key} end"
      end
    end

    def direction_type(part, mark)
      return "<dynamics><#{mark.item.name_key}/></dynamics>" if mark.type == :dynamic

      type = (mark.type == :start) ? mark.item.name_key : "stop"
      %(<wedge type="#{type}" number="#{plan.wedge_numbers(part).number(mark.item)}"/>)
    end

    def direction_lines(direction_type, offset, voice_number: nil, staff_number: nil)
      [
        %(#{INDENT * 3}<direction placement="below">),
        "#{INDENT * 4}<direction-type>#{direction_type}</direction-type>",
        offset.positive? ? "#{INDENT * 4}<offset>#{offset}</offset>" : nil,
        voice_number && "#{INDENT * 4}<voice>#{voice_number}</voice>",
        staff_number && "#{INDENT * 4}<staff>#{staff_number}</staff>",
        "#{INDENT * 3}</direction>"
      ].compact
    end
  end
end
