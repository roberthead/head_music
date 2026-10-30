# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # The marks a voice places at a position rather than on a note: its own
  # dynamics and hairpin starts and ends, and its part's when it writes them,
  # and the flow's tempo marks, as Q: fields and annotations, when it is the
  # lead voice. In each bar, a mark goes on the note or rest that attacks at
  # its position, on an invisible rest in an overlay of the bar when it falls
  # inside one, or on an invisible rest after the music when it follows the
  # last note. A hairpin or ramp end on the final barline closes the last
  # bar, on a spacer.
  #
  # At one position, hairpin ends come first, then levels, then starts, so a
  # hairpin is closed before the next one opens, and then the tempo marks in
  # their order.
  class PositionMarks
    HAIRPIN_SIGNS = {crescendo: "<", diminuendo: ">"}.freeze
    END_RANK = 0
    LEVEL_RANK = 1
    START_RANK = 2
    TEMPO_RANK = 3
    TEMPO_LABELS = {tempo: "tempo change", ramp_start: "tempo ramp start", ramp_end: "tempo ramp end", a_tempo: %("a tempo")}.freeze

    Mark = Data.define(:position, :decoration, :label, :rank) do
      def offset
        PositionMarks.offset(position)
      end

      # Rests can reach any offset in binary note values, but none inside a
      # tuplet. One starts on the downbeat.
      def reachable?
        offset.zero? || !HeadMusic::Notation::DottedDuration.rhythmic_duration_for(offset).nil?
      end

      # An inline field stands only where a note starts or the music ends.
      def inline_field?
        decoration.start_with?("[")
      end
    end

    # One bar's marks by how each is written, with where its music ends and
    # its written length, as fractions of a whole note.
    BarMarks = Data.define(:attacks, :overlay, :trailing, :closing, :music_end, :length) do
      def decorations_at(position)
        attacks.fetch(position, []).map(&:decoration).join
      end

      def unreachable
        (overlay + trailing).find { |mark| !mark.reachable? }
      end

      def inline_field_between_attacks
        (overlay + trailing).find(&:inline_field?)
      end
    end

    # The fraction of a whole note from the start of the bar.
    def self.offset(position)
      meter = position.meter
      ticks = position.tick + Rational(position.subtick, HeadMusic::Time::SUBTICKS_PER_TICK)
      (position.count - 1 + ticks / Rational(meter.ticks_per_count)) / meter.bottom_number
    end

    def initialize(voice, lead: true, part: true)
      @flow = voice&.flow
      @marks = voice ? marks(voice, lead, part).sort_by { |mark| [mark.position, mark.rank] } : []
    end

    def bar_marks(bar_segments)
      bar_number = bar_segments.first.bar_number
      starts = bar_segments.map { |segment| segment_start(segment) }
      music_end = segment_end(bar_segments.last)
      attacks, others = @marks.select { |mark| mark.position.bar_number == bar_number }
        .partition { |mark| starts.include?(mark.position) }
      overlay, trailing = others.partition { |mark| mark.position < music_end }
      length = bar_length(bar_number)
      music_end_offset = (music_end.bar_number > bar_number) ? length : self.class.offset(music_end)
      BarMarks.new(attacks.group_by(&:position), overlay, trailing, closing_marks(bar_number), music_end_offset, length)
    end

    # A bar the voice is silent in, where every mark follows its music.
    def silent_bar_marks(bar_number)
      marks = @marks.select { |mark| mark.position.bar_number == bar_number }
      BarMarks.new({}, [], marks, closing_marks(bar_number), 0r, bar_length(bar_number))
    end

    private

    def marks(voice, lead, part)
      holders = [voice, *(voice.part if part)]
      dynamic_marks(holders) + hairpin_marks(holders) + (lead ? tempo_marks : [])
    end

    # A voice and its part with the same level at one position write it once.
    def dynamic_marks(holders)
      holders.flat_map(&:dynamic_events)
        .map { |event| Mark.new(event.position, "!#{event.name_key}!", "dynamic #{event.name_key}", LEVEL_RANK) }
        .uniq { |mark| [mark.position, mark.decoration] }
    end

    # The same hairpin from the voice and its part is written once.
    def hairpin_marks(holders)
      holders.flat_map(&:spans).select(&:hairpin?).uniq(&:to_h).flat_map do |hairpin|
        sign = HAIRPIN_SIGNS.fetch(hairpin.kind)
        [
          Mark.new(hairpin.from, "!#{sign}(!", "#{hairpin.name_key} start", START_RANK),
          Mark.new(hairpin.to, "!#{sign})!", "#{hairpin.name_key} end", END_RANK)
        ]
      end
    end

    def tempo_marks
      HeadMusic::Notation::TempoMarks.new(@flow).each_with_index.filter_map do |mark, index|
        decoration = tempo_decoration(mark)
        Mark.new(mark.position, decoration, TEMPO_LABELS.fetch(mark.kind), TEMPO_RANK + index) if decoration
      end
    end

    def tempo_decoration(mark)
      return %("^#{mark.text}") if mark.text && mark.kind != :tempo

      "[Q:#{TempoField.write(mark.tempo)}]" if mark.tempo
    end

    def closing_marks(bar_number)
      final_barline = @flow.final_barline_position
      return [] unless bar_number == final_barline.bar_number - 1

      @marks.select { |mark| mark.position == final_barline }
    end

    def segment_start(segment)
      position = segment.voice_event.position
      return position if segment.bar_number == position.bar_number

      @flow.position(segment.bar_number, 1, 0)
    end

    def segment_end(segment)
      segment.continues ? @flow.position(segment.bar_number + 1, 1, 0) : segment.voice_event.next_position
    end

    def bar_length(bar_number)
      meter = @flow.meter_at(bar_number)
      Rational(meter.top_number, meter.bottom_number)
    end
  end
end
