# Parses and renders ABC notation as HeadMusic::Content flows
module HeadMusic::Notation::ABC
  # Writes one voice as a string per bar it sounds in, each with its bar lines.
  class VoiceWriter
    attr_reader :voice, :plan

    def initialize(voice, plan)
      @voice = voice
      @plan = plan
    end

    # Raises on what the voice cannot write before any bar is assembled.
    def validate!
      ensure_marks_reachable
      slur_writer
    end

    def bars
      bars = written_bars
      bars.each_with_index.map do |(bar, music), index|
        previous = bars[index - 1]&.first if index.positive?
        following = bars[index + 1]&.first
        BarLineWriter.opening(bar, previous) + music + BarLineWriter.closing(bar, following)
      end
    end

    private

    # A mark inside a note or after the music is reached by invisible rests,
    # which need a binary note value to span its offset, and which cannot
    # carry a Q: field.
    def ensure_marks_reachable
      segments_by_bar.each_value do |bar_segments|
        bar_marks = position_marks.bar_marks(bar_segments)
        mark = bar_marks.unreachable
        if mark
          raise RenderError, "cannot place the #{mark.label} at #{mark.position} in ABC output: " \
            "no binary note value reaches it"
        end
        field = bar_marks.inline_field_between_attacks
        raise RenderError, "cannot place the #{field.label} at #{field.position} in ABC output, where no note starts" if field
      end
    end

    # The key its part reads, which in a transposed plan is the part's own
    # written key.
    def key_signature
      plan.first_measure_key(voice.part).key_signature
    end

    # Each bar the voice sounds in, with its music.
    def written_bars
      bar_writer = BarWriter.new(
        key_signature, Writer::UNIT_NOTE_LENGTH, slur_writer, position_marks, tuplet_writer, plan.fermata_carriers
      )
      segments_by_bar.map { |bar_number, bar_segments| [plan.bar(bar_number), bar_writer.bar(bar_segments)] }
    end

    # A voice event sounding across a bar line is written as one note per bar,
    # tied, since ABC has no other way to cross the line.
    def segments_by_bar
      plan.segments_by_bar(voice)
    end

    def segments
      segments_by_bar.values.flatten
    end

    def position_marks
      @position_marks ||= PositionMarks.new(voice)
    end

    def slur_writer
      @slur_writer ||= SlurWriter.new(voice)
    end

    def tuplet_writer
      TupletWriter.new(voice, segments)
    end
  end
end
