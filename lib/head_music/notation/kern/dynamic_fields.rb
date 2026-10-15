# A namespace for **kern rendering helpers
module HeadMusic::Notation::Kern
  # What a part's **dynam spine holds, by bar and offset: its own levels,
  # its voices' levels, the accents a kern token cannot carry, and the
  # hairpin marks of the part and its voices.
  #
  # The spine holds one value per row and cannot say which voice it means.
  # An accent outranks a level at its row; the preflight refuses different
  # levels at one position, so the levels that meet there are all the same.
  #
  # Verovio drops a hairpin that a level or accent interrupts, so each
  # hairpin is written as touching pieces cut wherever one falls inside it,
  # and a field holds its closes, then its value, then its opens, as `]p<`.
  # A piece ending on the final barline is closed apart, by the writer.
  class DynamicFields
    # sfz is written in the token, as z.
    SPINE_ACCENTS = %w[sf rfz fp].freeze
    OPENS = {crescendo: "<", diminuendo: ">"}.freeze
    CLOSES = {crescendo: "[", diminuendo: "]"}.freeze

    def initialize(part)
      @part = part
    end

    def empty?
      by_bar.empty? && hairpins.empty?
    end

    # The offsets in the bar that carry a dynamic or hairpin mark, each with
    # its field.
    def in_bar(bar_number)
      by_bar.fetch(bar_number, {})
    end

    # The pieces the spine writes, the same piece from several owners once.
    def hairpins
      @hairpins ||= HeadMusic::Notation::HairpinSegments.split(
        [part, *part.voices].flat_map(&:spans).select(&:hairpin?),
        candidates.map(&:first)
      ).uniq(&:to_h).sort
    end

    # The piece ending on the final barline, closed by a doubled close.
    def final_hairpin
      hairpins.find { |hairpin| hairpin.to == part.flow.final_barline_position }
    end

    def final_close
      final_hairpin && CLOSES.fetch(final_hairpin.kind) * 2
    end

    private

    attr_reader :part

    def by_bar
      @by_bar ||= marks.each_with_object({}) do |(position, mark), fields|
        bar_fields = fields[position.bar_number] ||= {}
        offset = MarkOffset.in_bar(position, part.voices)
        bar_fields[offset] ||= {}
        mark.each { |piece, text| bar_fields[offset][piece] ||= text }
      end.transform_values do |bar_fields|
        bar_fields.transform_values { |field| field.values_at(:closes, :value, :opens).join }
      end
    end

    def marks
      [
        *candidates.map { |position, dynamic| [position, {value: dynamic.name_key}] },
        *hairpins.map { |hairpin| [hairpin.from, {opens: OPENS.fetch(hairpin.kind)}] },
        *(hairpins - [final_hairpin]).map { |hairpin| [hairpin.to, {closes: CLOSES.fetch(hairpin.kind)}] }
      ]
    end

    def candidates
      @candidates ||= [
        *part.voices.flat_map { |voice| accent_positions(voice) },
        *level_positions(part),
        *part.voices.flat_map { |voice| level_positions(voice) }
      ]
    end

    def level_positions(owner)
      owner.dynamic_events.map { |dynamic_event| [dynamic_event.position, dynamic_event.level] }
    end

    def accent_positions(voice)
      voice.note_events.filter_map do |note_event|
        [note_event.position, note_event.note_dynamic] if SPINE_ACCENTS.include?(note_event.note_dynamic&.name_key)
      end
    end
  end
end
