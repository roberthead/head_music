module HeadMusic
  module Notation
    # The marks of a flow's parts and voices that sit at a time: dynamic
    # levels and the starts and ends of hairpins, each with the voices it
    # marks.
    class FlowTimedMarks
      include Enumerable

      Mark = Data.define(:voices, :label, :position, :ending) do
        def to_s
          "#{label} at #{position}"
        end

        # A hairpin may end on the final barline, as one ending with the
        # music does.
        def after?(last_bar_number, final_barline)
          ending ? position > final_barline : position.bar_number > last_bar_number
        end

        # A note of the marked voices that holds the mark strictly inside it
        # and whose ratio rounds it onto the subtick grid.
        def rounded_note
          voices.lazy.filter_map { |voice| rounded_note_holding(voice) }.first
        end

        private

        def rounded_note_holding(voice)
          voice_event = voice.voice_event_sounding_at(position)
          return unless voice_event && voice_event.position < position

          voice_event if voice_event.rhythmic_value.tied_chain.any? { |link| rounds?(link) }
        end

        def rounds?(link)
          (link.link_fraction * HeadMusic::Rudiment::Rhythm::SUBTICKS_PER_WHOLE).denominator != 1
        end
      end

      def initialize(flow)
        owners = [*flow.parts.map { |part| [part, part.voices] }, *flow.voices.map { |voice| [voice, [voice]] }]
        @marks = owners.flat_map { |owner, voices| marks_of(owner, voices) }
      end

      def each(&)
        @marks.each(&)
      end

      private

      def marks_of(owner, voices)
        hairpins = owner.spans.select(&:hairpin?)
        [
          *owner.dynamic_events.map { |event| ["dynamic #{event.name_key}", event.position, false] },
          *hairpins.map { |span| ["#{span.name_key} start", span.from, false] },
          *hairpins.map { |span| ["#{span.name_key} end", span.to, true] }
        ].map { |label, position, ending| Mark.new(voices, label, position, ending) }
      end
    end
  end
end
