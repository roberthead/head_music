# Parses and renders ABC notation as HeadMusic::Content flows
module HeadMusic::Notation::ABC
  # Renders a flow as an ABC tune string. Whole-flow problems raise before any
  # string assembly, so callers never receive a truncated tune. Repeat barlines
  # and voltas are deliberately not rendered; bars carrying repeat flags degrade
  # to plain bar lines.
  class Writer
    # A fixed unit note length keeps the L: field and the duration
    # multiplier arithmetic in sync.
    UNIT_NOTE_LENGTH = Rational(1, 8)
    BARS_PER_LINE = 4

    include HeadMusic::Notation::PreflightChecks

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
      ensure_single_voice
      ensure_no_mid_piece_changes
      ensure_no_instrument_change
      ensure_contiguous_voices(flow)
      slur_writer
    end

    def ensure_single_voice
      return if flow.voices.length <= 1

      raise RenderError, "multi-voice ABC output is not supported"
    end

    def ensure_no_mid_piece_changes
      refuse_change("meter", flow.meter_changes.keys)
      refuse_change("key signature", flow.key_signature_changes.keys)
    end

    # A tune has one K: field, so a part that picks up an instrument reading in
    # another key cannot be written -- the same limit as a mid-piece key change.
    def ensure_no_instrument_change
      return unless transposed

      refuse_change("instrument", flow.parts.flat_map { |part| part.instrument_changes.keys })
    end

    def refuse_change(subject, bar_numbers)
      bar_number = bar_numbers.min
      return unless bar_number

      raise RenderError, "cannot render the #{subject} change at bar #{bar_number} in ABC output"
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
      lines = bar_strings.each_slice(BARS_PER_LINE).map { |line_bars| "#{line_bars.join("|")}|" }
      lines.last&.concat("]")
      lines
    end

    def bar_strings
      @bar_strings ||= build_bar_strings
    end

    def build_bar_strings
      bar_writer = BarWriter.new(flow.voices.first, written_key_signature, UNIT_NOTE_LENGTH, slur_writer)
      segments_by_bar.map { |bar_segments| bar_writer.bar(bar_segments) }
    end

    # A voice event sounding across a bar line is written as one note per bar,
    # tied, since ABC has no other way to cross the line.
    def segments_by_bar
      HeadMusic::Notation::BarSplitter.segments(voice_events)
        .chunk_while { |previous, current| previous.bar_number == current.bar_number }
    end

    def render_error_class
      RenderError
    end
  end
end
