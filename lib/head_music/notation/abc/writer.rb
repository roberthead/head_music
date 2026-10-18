# Parses and renders ABC notation as HeadMusic::Content flows
module HeadMusic::Notation::ABC
  # Renders a flow as an ABC tune string. Whole-flow problems raise before any
  # string assembly, so callers never receive a truncated tune. A repeat played
  # more than twice is written as a plain ":|", which ABC reads back as two
  # plays unless its endings name more passes.
  class Writer
    # A fixed unit note length keeps the L: field and the duration
    # multiplier arithmetic in sync.
    UNIT_NOTE_LENGTH = Rational(1, 8)
    BARS_PER_LINE = 4

    attr_reader :flow, :reference_number, :transposed

    def initialize(flow, reference_number: 1, transposed: false)
      @flow = flow
      @reference_number = reference_number
      @transposed = transposed
    end

    def to_s
      validate!
      (header_lines + body_lines).join("\n") + "\n"
    end

    private

    def validate!
      RenderPreflight.check!(flow, transposed: transposed)
      ensure_marks_reachable
      slur_writer
    end

    # A mark inside a note or after the music is reached by invisible rests,
    # which need a binary note value to span its offset.
    def ensure_marks_reachable
      segments_by_bar.each do |bar_segments|
        mark = position_marks.bar_marks(bar_segments).unreachable
        next unless mark

        raise RenderError, "cannot place the #{mark.label} at #{mark.position} in ABC output: " \
          "no binary note value reaches it"
      end
    end

    def position_marks
      @position_marks ||= PositionMarks.new(flow.voices.first)
    end

    def voice_events
      voice = flow.voices.first
      voice ? voice.voice_events : []
    end

    def slur_writer
      @slur_writer ||= SlurWriter.new(flow.voices.first)
    end

    # No %%transpose directive is emitted: the pitches are already written, and
    # abcm2ps would move them a second time.
    def written_key_signature
      @written_key_signature ||= transposition.key_signature(flow.key_signature)
    end

    def transposition
      instrument = transposed ? (flow.voices.first&.part || flow.parts.first)&.instrument : nil
      HeadMusic::Content::Layout::Transposition.for(instrument)
    end

    def header_lines
      [
        "X:#{reference_number}",
        "T:#{flow.name}",
        optional_field("C", flow.composer),
        optional_field("O", flow.origin),
        "M:#{flow.meter}",
        unit_note_length_field,
        key_field
      ].compact
    end

    def optional_field(letter, value)
      "#{letter}:#{value}" if value
    end

    def unit_note_length_field
      "L:#{UNIT_NOTE_LENGTH.numerator}/#{UNIT_NOTE_LENGTH.denominator}"
    end

    def key_field
      # The parser requires K: to terminate the header.
      "K:#{KeyMapper.abc_value(written_key_signature)}"
    end

    def body_lines
      bar_strings.each_slice(BARS_PER_LINE).map(&:join)
    end

    def bar_strings
      bars = written_bars
      bars.each_with_index.map do |(bar, music), index|
        previous = bars[index - 1]&.first if index.positive?
        following = bars[index + 1]&.first
        BarLineWriter.opening(bar, previous) + music + BarLineWriter.closing(bar, following)
      end
    end

    # Each bar the voice sounds in, with its music.
    def written_bars
      bar_writer = BarWriter.new(written_key_signature, UNIT_NOTE_LENGTH, slur_writer, position_marks, tuplet_writer)
      segments = segments_by_bar.to_a
      return [] if segments.empty?

      segments.map { |bar_segments| [flow.bar(bar_segments.first.bar_number), bar_writer.bar(bar_segments)] }
    end

    # A voice event sounding across a bar line is written as one note per bar,
    # tied, since ABC has no other way to cross the line.
    def segments_by_bar
      segments.chunk_while { |previous, current| previous.bar_number == current.bar_number }
    end

    def segments
      @segments ||= HeadMusic::Notation::BarSplitter.segments(voice_events)
    end

    def tuplet_writer
      TupletWriter.new(flow.voices.first, segments)
    end
  end
end
