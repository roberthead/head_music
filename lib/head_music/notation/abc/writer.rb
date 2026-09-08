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

    include HeadMusic::Notation::PlacementValidation
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
    end

    def ensure_single_voice
      return if flow.voices.length <= 1

      raise RenderError, "multi-voice ABC output is not supported"
    end

    def ensure_no_mid_piece_changes
      meter_change_bar = flow.meter_changes.keys.min
      raise RenderError, "cannot render the meter change at bar #{meter_change_bar} in ABC output" if meter_change_bar

      key_change_bar = flow.key_signature_changes.keys.min
      return unless key_change_bar

      raise RenderError, "cannot render the key signature change at bar #{key_change_bar} in ABC output"
    end

    # A tune has one K: field, so a part that picks up an instrument reading in
    # another key cannot be written -- the same limit as a mid-piece key change.
    def ensure_no_instrument_change
      return unless transposed

      change_bar = flow.parts.flat_map { |part| part.instrument_changes.keys }.min
      return unless change_bar

      raise RenderError, "cannot render the instrument change at bar #{change_bar} in ABC output"
    end

    def placements
      voice = flow.voices.first
      voice ? voice.placements : []
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
      return [] if bar_strings.empty?

      lines = bar_strings.each_slice(BARS_PER_LINE).map do |line_bars|
        line_bars.join("|") + "|"
      end
      lines[-1] = lines[-1].sub(/\|\z/, "|]")
      lines
    end

    def bar_strings
      @bar_strings ||= build_bar_strings
    end

    def build_bar_strings
      pitch_writer = PitchWriter.new(written_key_signature)
      duration_writer = DurationWriter.new(UNIT_NOTE_LENGTH)
      placements_by_bar.each_with_index.map do |bar_placements, index|
        # Accidental state must mirror what a re-parse accumulates bar by bar.
        pitch_writer.start_new_bar if index.positive?
        render_bar(bar_placements, pitch_writer, duration_writer)
      end
    end

    def placements_by_bar
      placements.chunk_while do |previous, current|
        previous.position.bar_number == current.position.bar_number
      end
    end

    def render_bar(bar_placements, pitch_writer, duration_writer)
      tokens = bar_placements.map { |placement| token(placement, pitch_writer, duration_writer) }
      join_bar_tokens(bar_placements, tokens)
    end

    # The inter-token space is dropped only where the placement was authored as
    # beamed to its predecessor; a true or nil beam_break_before keeps it, so
    # programmatic flows render with every-token spacing. Every bar token
    # re-lexes unambiguously with no separator, so dropping it is safe.
    def join_bar_tokens(placements, tokens)
      tokens.each_with_index.reduce(+"") do |line, (token, index)|
        separator = (index.zero? || placements[index].beam_break_before == false) ? "" : " "
        line << separator << token
      end
    end

    def token(placement, pitch_writer, duration_writer)
      ensure_pitched_sounds(placement)

      multiplier = duration_writer.multiplier_string(placement.rhythmic_value)
      return "z#{multiplier}" if placement.rest?
      return chord_token(placement, pitch_writer, multiplier) if placement.chord?

      "#{pitch_writer.token(placement.pitch)}#{multiplier}"
    end

    def chord_token(placement, pitch_writer, multiplier)
      # Pitches are emitted low-to-high so the writer's bar-accidental state
      # cannot diverge from what a re-parse of the brackets accumulates.
      pitch_tokens = placement.pitches.sort.map { |pitch| pitch_writer.token(pitch) }
      "[#{pitch_tokens.join}]#{multiplier}"
    end

    def render_error_class
      RenderError
    end
  end
end
