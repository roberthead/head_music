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

    LABELS = {dynamic: "dynamic %s", start: "%s start", stop: "%s end"}.freeze

    def initialize(plan)
      @plan = plan
    end

    # A part event carries neither <voice> nor <staff>: other software
    # defaults it to staff 1.
    def slot_lines(slot, voice_number: nil, staff_number: nil)
      direction_plan = plan.direction_plan(slot.part)
      marks = direction_plan.marks(slot)
      return [] if marks.empty?

      start = direction_plan.start(slot)
      numbers = [voice_number && "#{INDENT * 4}<voice>#{voice_number}</voice>", staff_number && "#{INDENT * 4}<staff>#{staff_number}</staff>"]
      marks.flat_map { |mark| direction_lines(direction_type(slot.part, mark), offset_from(start, slot, mark), numbers) }
    end

    private

    attr_reader :plan

    delegate :divisions, to: :plan

    # A mark on the final barline is written in the last bar, at its end.
    def offset_from(start, slot, mark)
      bar_number = slot.bar_number
      return plan.whole_measure_duration(bar_number) - start unless mark.position.bar_number == bar_number

      fraction = HeadMusic::Notation::BarSplitter.mark_offset(plan.flow, mark.position, mark_voices(slot)) * 4 * divisions
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
      format(LABELS.fetch(mark.type), mark.item.name_key)
    end

    def direction_type(part, mark)
      return "<dynamics><#{mark.item.name_key}/></dynamics>" if mark.type == :dynamic

      type = (mark.type == :start) ? mark.item.name_key : "stop"
      %(<wedge type="#{type}" number="#{plan.wedge_numbers(part).number(mark.item)}"/>)
    end

    def direction_lines(direction_type, offset, numbers)
      [
        %(#{INDENT * 3}<direction placement="below">),
        "#{INDENT * 4}<direction-type>#{direction_type}</direction-type>",
        offset.positive? ? "#{INDENT * 4}<offset>#{offset}</offset>" : nil,
        *numbers,
        "#{INDENT * 3}</direction>"
      ].compact
    end
  end
end
