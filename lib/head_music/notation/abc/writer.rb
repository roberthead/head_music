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

    include HeadMusic::Notation::VoiceEventValidation
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

    def voice_events
      voice = flow.voices.first
      voice ? voice.voice_events : []
    end

    def decoration_writer
      @decoration_writer ||= DecorationWriter.new(flow.voices.first)
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

    # A voice event sounding across a bar line is written as one note per bar,
    # tied, since ABC has no other way to cross the line.
    def segments_by_bar
      HeadMusic::Notation::BarSplitter.segments(voice_events)
        .chunk_while { |previous, current| previous.bar_number == current.bar_number }
    end

    # The inter-token space is dropped only where the voice event was authored as
    # beamed to its predecessor; a true or nil beam_break_before keeps it, so
    # programmatic flows render with every-token spacing. Every bar token
    # re-lexes unambiguously with no separator, so dropping it is safe.
    def render_bar(bar_segments, pitch_writer, duration_writer)
      bar_segments.map do |segment|
        token = token(segment, pitch_writer, duration_writer)
        (segment.voice_event.beam_break_before == false) ? token : " #{token}"
      end.join.lstrip
    end

    # A voice event split across bar lines is marked only where it starts.
    def token(segment, pitch_writer, duration_writer)
      voice_event = segment.voice_event
      body = token_body(segment, pitch_writer, duration_writer)
      return body unless segment.bar_number == voice_event.position.bar_number

      decoration_writer.prefix(voice_event) + body
    end

    def token_body(segment, pitch_writer, duration_writer)
      voice_event = segment.voice_event
      ensure_pitched_sounds(voice_event)

      multiplier = multiplier_for(segment, duration_writer)
      tie = segment.continues ? "-" : ""
      return "z#{multiplier}" if voice_event.rest?
      return chord_token(voice_event, pitch_writer, multiplier) + tie if voice_event.chord?

      "#{pitch_writer.token(voice_event.pitch)}#{multiplier}#{tie}"
    end

    def multiplier_for(segment, duration_writer)
      return duration_writer.multiplier_string(segment.voice_event.rhythmic_value) unless segment.fraction

      duration_writer.multiplier_string_for_fraction(segment.fraction, segment.voice_event.rhythmic_value)
    end

    def chord_token(voice_event, pitch_writer, multiplier)
      # Pitches are emitted low-to-high so the writer's bar-accidental state
      # cannot diverge from what a re-parse of the brackets accumulates.
      pitch_tokens = voice_event.pitches.sort.map { |pitch| pitch_writer.token(pitch) }
      "[#{pitch_tokens.join}]#{multiplier}"
    end

    def render_error_class
      RenderError
    end
  end
end
