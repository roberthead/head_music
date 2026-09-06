# Parses and renders ABC notation as HeadMusic::Content flows
module HeadMusic::Notation::ABC
  # Renders a HeadMusic::Content::Flow as an ABC tune string.
  #
  # Whole-flow problems (multiple voices, mid-piece meter or key
  # changes, positional gaps) raise before any string assembly, and #to_s
  # only returns a fully assembled document, so callers never receive a
  # truncated tune.
  #
  # Repeat barlines and voltas are deliberately not rendered; bars carrying
  # repeat flags degrade to plain bar lines.
  class Writer
    # A fixed unit note length keeps the L: field and the duration
    # multiplier arithmetic in sync.
    UNIT_NOTE_LENGTH = Rational(1, 8)
    BARS_PER_LINE = 4

    include HeadMusic::Notation::PlacementValidation
    include HeadMusic::Notation::PreflightChecks

    attr_reader :flow, :reference_number

    def initialize(flow, reference_number: 1)
      @flow = flow
      @reference_number = reference_number
    end

    def to_s
      validate!
      (header_lines + body_lines).join("\n") + "\n"
    end

    private

    def validate!
      ensure_single_voice
      ensure_no_mid_piece_changes
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

    def placements
      voice = flow.voices.first
      voice ? voice.placements : []
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
      "K:#{KeyMapper.abc_value(flow.key_signature)}"
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
      pitch_writer = PitchWriter.new(flow.key_signature)
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

    # Suppresses the inter-token space only where the following placement was
    # authored as beamed to its predecessor (beam_break_before == false).
    # A true or nil flag keeps the space, so programmatic (nil-flag)
    # flows render with today's every-token spacing. Every bar token
    # (note, rest, or [..] chord) re-lexes unambiguously with no separator, so
    # dropping the space is safe.
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
      # Pitches are emitted low-to-high, and the oracle sees them in that
      # same order, so the writer's bar-accidental state cannot diverge from
      # what a re-parse of the emitted brackets accumulates.
      pitch_tokens = placement.pitches.sort.map { |pitch| pitch_writer.token(pitch) }
      "[#{pitch_tokens.join}]#{multiplier}"
    end

    def render_error_class
      RenderError
    end
  end
end
