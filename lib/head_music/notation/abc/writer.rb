# Parses and renders ABC notation as HeadMusic::Content compositions
module HeadMusic::Notation::ABC
  # Renders a HeadMusic::Content::Composition as an ABC tune string.
  #
  # Whole-composition problems (multiple voices, mid-piece meter or key
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

    attr_reader :composition, :reference_number

    def initialize(composition, reference_number: 1)
      @composition = composition
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
      ensure_contiguous_placements
    end

    def ensure_single_voice
      return if composition.voices.length <= 1

      raise RenderError, "multi-voice ABC output is not supported"
    end

    def ensure_no_mid_piece_changes
      composition.bars.each_with_index do |bar, index|
        bar_number = composition.earliest_bar_number + index
        if bar.meter
          raise RenderError, "cannot render the meter change at bar #{bar_number} in ABC output"
        end
        next unless bar.key_signature

        raise RenderError, "cannot render the key signature change at bar #{bar_number} in ABC output"
      end
    end

    def ensure_contiguous_placements
      first = placements.first
      return unless first

      ensure_placement_starts_bar(first)
      placements.each_cons(2) do |previous, current|
        next if current.position == previous.next_position

        raise RenderError, "expected a placement at #{previous.next_position}, " \
          "found one at #{current.position}; insert explicit rests to fill gaps"
      end
    end

    def ensure_placement_starts_bar(placement)
      position = placement.position
      return if position.count == 1 && position.tick.zero?

      raise RenderError, "the first placement must start its bar " \
        "(found #{position}); insert explicit rests to fill the gap"
    end

    def placements
      voice = composition.voices.first
      voice ? voice.placements : []
    end

    def header_lines
      [
        "X:#{reference_number}",
        "T:#{composition.name}",
        composition.composer && "C:#{composition.composer}",
        composition.origin && "O:#{composition.origin}",
        "M:#{composition.meter}",
        "L:#{UNIT_NOTE_LENGTH.numerator}/#{UNIT_NOTE_LENGTH.denominator}",
        # The parser requires K: to terminate the header.
        "K:#{KeyMapper.abc_value(composition.key_signature)}"
      ].compact
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
      pitch_writer = PitchWriter.new(composition.key_signature)
      duration_writer = DurationWriter.new(UNIT_NOTE_LENGTH)
      bar_groups = placements.chunk_while do |previous, current|
        previous.position.bar_number == current.position.bar_number
      end
      bar_groups.each_with_index.map do |bar_placements, index|
        # Accidental state must mirror what a re-parse accumulates bar by bar.
        pitch_writer.start_new_bar if index.positive?
        bar_placements.map { |placement| token(placement, pitch_writer, duration_writer) }.join(" ")
      end
    end

    def token(placement, pitch_writer, duration_writer)
      ensure_pitched_sounds(placement)
      raise RenderError, "chords are not yet supported by the ABC writer" if placement.chord?

      multiplier = duration_writer.multiplier_string(placement.rhythmic_value)
      return "z#{multiplier}" if placement.rest?

      "#{pitch_writer.token(placement.pitch)}#{multiplier}"
    end

    def ensure_pitched_sounds(placement)
      unpitched = placement.sounds.find { |sound| !sound.pitched? }
      return unless unpitched

      raise RenderError, "cannot render unpitched sound \"#{unpitched}\" at #{placement.position}: " \
        "percussion rendering is not yet supported"
    end
  end
end
