# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Where each of one part's directions is written, in document order. A part
  # writes a bar's own directions first, then each voice in turn after a
  # <backup>, then closes the bar, so a mark goes in the slot nearest its
  # position along that path and carries an <offset> from the slot's start.
  #
  # Per bar: the part's slot; for each voice, a slot before each of its
  # segments, or one before the whole-measure rest that fills an empty bar,
  # and a trailing slot after its last content; and, in the last bar, a
  # closing slot after every voice. Within a slot, marks at one position go
  # hairpin stops first, then dynamics, then hairpin starts.
  class DirectionPlan
    Slot = Data.define(:kind, :part, :voice, :bar_number, :segment)
    Mark = Data.define(:type, :position, :item)
    Bar = Data.define(:bar_number, :part_slot, :voice_slots, :closing_slot) do
      def slots
        [part_slot, *voice_slots.flat_map(&:last), closing_slot].compact
      end
    end

    MARK_ORDER = %i[stop dynamic start].freeze

    attr_reader :part

    def initialize(part, plan)
      @part = part
      @plan = plan
      @bars = {}
    end

    def bar(bar_number)
      @bars[bar_number] ||= Bar.new(
        bar_number: bar_number,
        part_slot: Slot.new(:part, part, nil, bar_number, nil),
        voice_slots: voices.map { |voice| [voice, voice_slots(voice, bar_number)] },
        closing_slot: (bar_number == plan.bar_numbers.last) ? Slot.new(:closing, part, nil, bar_number, nil) : nil
      )
    end

    def slots
      plan.bar_numbers.flat_map { |bar_number| bar(bar_number).slots }
    end

    def marks(slot)
      marks_by_slot.fetch(slot, [])
    end

    # Where the document's cursor stands when the slot is written, in
    # divisions from the start of its measure.
    def start(slot)
      case slot.kind
      when :segment then segment_start(slot)
      when :trailing then plan.written_duration(slot.voice, slot.bar_number)
      when :closing then closing_start(slot.bar_number)
      else 0
      end
    end

    private

    attr_reader :plan

    def voices
      part.voices.empty? ? [nil] : part.voices
    end

    def voice_slots(voice, bar_number)
      return [Slot.new(:whole_measure_rest, part, nil, bar_number, nil)] unless voice

      segments = plan.segments_by_bar(voice)[bar_number]
      leading = segments ? segments.map { |segment| Slot.new(:segment, part, voice, bar_number, segment) } : [Slot.new(:whole_measure_rest, part, voice, bar_number, nil)]
      [*leading, Slot.new(:trailing, part, voice, bar_number, nil)]
    end

    def segment_start(slot)
      plan.segments_by_bar(slot.voice)[slot.bar_number]
        .take_while { |segment| segment != slot.segment }
        .sum { |segment| plan.components_by_segment[segment].sum(&:duration) }
    end

    def closing_start(bar_number)
      voice = part.voices.last
      voice ? plan.written_duration(voice, bar_number) : plan.whole_measure_duration(bar_number)
    end

    def marks_by_slot
      @marks_by_slot ||= [part, *part.voices]
        .flat_map { |owner| marks_of(owner).map { |mark| [slot_at(owner, mark.position), mark] } }
        .group_by(&:first)
        .transform_values { |pairs| in_writing_order(pairs.map(&:last)) }
    end

    def marks_of(owner)
      hairpins = owner.spans.select(&:hairpin?)
      owner.dynamic_events.map { |event| Mark.new(:dynamic, event.position, event) } +
        hairpins.map { |span| Mark.new(:stop, span.to, span) } +
        hairpins.map { |span| Mark.new(:start, span.from, span) }
    end

    def in_writing_order(marks)
      marks.each_with_index.sort_by { |mark, index| [mark.position, MARK_ORDER.index(mark.type), index] }.map(&:first)
    end

    def slot_at(owner, position)
      return final_barline_slot(owner) if position == plan.flow.final_barline_position
      return Slot.new(:part, part, nil, position.bar_number, nil) if owner.equal?(part)

      voice_slot_at(owner, position)
    end

    # A hairpin ending where the music ends is written in the last bar, after
    # all its owner has written there.
    def final_barline_slot(owner)
      bar_number = plan.bar_numbers.last
      return Slot.new(:closing, part, nil, bar_number, nil) if owner.equal?(part)

      Slot.new(:trailing, part, owner, bar_number, nil)
    end

    # The voice event sounding at the position holds it, whether a held note
    # or a rest; past the voice's last event, its trailing slot does.
    def voice_slot_at(voice, position)
      bar_number = position.bar_number
      return Slot.new(:whole_measure_rest, part, voice, bar_number, nil) unless plan.segments_by_bar(voice)[bar_number]

      segment = holding_segment(voice, position)
      return Slot.new(:trailing, part, voice, bar_number, nil) unless segment

      Slot.new(:segment, part, voice, bar_number, segment)
    end

    def holding_segment(voice, position)
      voice_event = voice.voice_event_sounding_at(position)
      return nil unless voice_event

      HeadMusic::Notation::BarSplitter.segments_of(voice_event).find { |segment| segment.bar_number == position.bar_number }
    end
  end
end
