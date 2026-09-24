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
      lines = bar_strings.each_slice(BARS_PER_LINE).map { |line_bars| "#{line_bars.join("|")}|" }
      lines.last&.concat("]")
      lines
    end

    def bar_strings
      @bar_strings ||= build_bar_strings
    end

    def build_bar_strings
      pitch_writer = PitchWriter.new(written_key_signature)
      duration_writer = DurationWriter.new(UNIT_NOTE_LENGTH)
      segments_by_bar.map do |bar_segments|
        # Accidental state must mirror what a re-parse accumulates bar by bar.
        pitch_writer.start_new_bar
        render_bar(bar_segments, pitch_writer, duration_writer)
      end
    end

    # A placement sounding across a bar line is written as one note per bar,
    # tied, since ABC has no other way to cross the line. A fraction of nil
    # means the placement fits its bar and renders from its own rhythmic
    # value, which keeps the exporter's canonical collapse of tied chains.
    Segment = Data.define(:placement, :bar_number, :fraction, :continues)

    def segments_by_bar
      placements.flat_map { |placement| segments_of(placement) }
        .chunk_while { |previous, current| previous.bar_number == current.bar_number }
    end

    def segments_of(placement)
      start = placement.position
      finish = placement.next_position
      segments = []
      while finish > start.start_of_next_bar
        segments << Segment.new(placement, start.bar_number, fraction_to_bar_end(start), true)
        start = start.start_of_next_bar
      end
      fraction = segments.empty? ? nil : fraction_within_bar(start, finish)
      segments << Segment.new(placement, start.bar_number, fraction, false)
    end

    def fraction_to_bar_end(position)
      meter = position.meter
      Rational(meter.top_number, meter.bottom_number) - offset_in_bar(position)
    end

    def fraction_within_bar(from, to)
      offset_in_bar(to) - offset_in_bar(from)
    end

    def offset_in_bar(position)
      meter = position.meter
      (position.count - 1 + Rational(position.tick, meter.ticks_per_count)) / meter.bottom_number
    end

    # The inter-token space is dropped only where the placement was authored as
    # beamed to its predecessor; a true or nil beam_break_before keeps it, so
    # programmatic flows render with every-token spacing. Every bar token
    # re-lexes unambiguously with no separator, so dropping it is safe.
    def render_bar(bar_segments, pitch_writer, duration_writer)
      bar_segments.map do |segment|
        token = token(segment, pitch_writer, duration_writer)
        (segment.placement.beam_break_before == false) ? token : " #{token}"
      end.join.lstrip
    end

    def token(segment, pitch_writer, duration_writer)
      placement = segment.placement
      ensure_pitched_sounds(placement)

      multiplier = multiplier_for(segment, duration_writer)
      tie = segment.continues ? "-" : ""
      return "z#{multiplier}" if placement.rest?
      return chord_token(placement, pitch_writer, multiplier) + tie if placement.chord?

      "#{pitch_writer.token(placement.pitch)}#{multiplier}#{tie}"
    end

    def multiplier_for(segment, duration_writer)
      return duration_writer.multiplier_string(segment.placement.rhythmic_value) unless segment.fraction

      duration_writer.multiplier_string_for_fraction(segment.fraction, segment.placement.rhythmic_value)
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
