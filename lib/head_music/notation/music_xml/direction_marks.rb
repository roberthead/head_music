# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # The marks one part writes as directions, by owner: the part's own and each
  # voice's dynamics and hairpin ends, and, in the first part's first voice,
  # the flow's tempo marks. Each owner's marks are in writing order: by
  # position, and at one position tempo marks first, then hairpin stops, then
  # dynamics, then hairpin starts.
  class DirectionMarks
    Mark = Data.define(:type, :position, :item) do
      def label
        return TEMPO_LABELS.fetch(item.kind) if type == :tempo

        format(LABELS.fetch(type), item.name_key)
      end
    end

    ORDER = %i[tempo stop dynamic start].freeze
    LABELS = {dynamic: "dynamic %s", start: "%s start", stop: "%s end"}.freeze
    TEMPO_LABELS = {tempo: "tempo change", ramp_start: "tempo ramp start", ramp_end: "tempo ramp end", a_tempo: %("a tempo")}.freeze

    def initialize(part, plan)
      @part = part
      @plan = plan
    end

    # Each owner, the part then its voices, with its marks.
    def by_owner
      [@part, *@part.voices].map { |owner| [owner, in_writing_order(marks_of(owner))] }
    end

    private

    def marks_of(owner)
      owner.dynamic_events.map { |event| Mark.new(:dynamic, event.position, event) } +
        owner.spans.select(&:hairpin?).flat_map { |span| [Mark.new(:stop, span.to, span), Mark.new(:start, span.from, span)] } +
        (owner.equal?(tempo_owner) ? tempo_marks : [])
    end

    def tempo_owner
      @part.voices.first || @part if @part.equal?(@plan.flow.parts.first)
    end

    def tempo_marks
      @plan.tempo_writer.marks.map { |mark| Mark.new(:tempo, mark.position, mark) }
    end

    def in_writing_order(marks)
      marks.each_with_index.sort_by { |mark, index| [mark.position, ORDER.index(mark.type), index] }.map(&:first)
    end
  end
end
