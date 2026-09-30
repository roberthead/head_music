# Parses and renders ABC notation as HeadMusic::Content flows
module HeadMusic::Notation::ABC
  # Writes the tokens of one bar of a voice after another, carrying the
  # accidental state a re-parse accumulates from bar to bar.
  class BarWriter
    include HeadMusic::Notation::VoiceEventValidation

    def initialize(voice, key_signature, unit_note_length, slur_writer)
      @pitch_writer = PitchWriter.new(key_signature)
      @duration_writer = DurationWriter.new(unit_note_length)
      @decoration_writer = DecorationWriter.new(voice)
      @slur_writer = slur_writer
    end

    # The inter-token space is dropped only where the voice event was authored as
    # beamed to its predecessor; a true or nil beam_break_before keeps it, so
    # programmatic flows render with every-token spacing. Every bar token
    # re-lexes unambiguously with no separator, so dropping it is safe.
    def bar(bar_segments)
      @pitch_writer.start_new_bar
      bar_segments.map do |segment|
        token = token(segment)
        (segment.voice_event.beam_break_before == false) ? token : " #{token}"
      end.join.lstrip
    end

    private

    # A voice event split across bar lines is marked only where it starts,
    # and a slur closes after its last part. A slur opens before the
    # decorations, since ".(" would be a dotted slur.
    def token(segment)
      voice_event = segment.voice_event
      body = token_body(segment)
      body += @slur_writer.closes(voice_event) unless segment.continues
      return body unless segment.bar_number == voice_event.position.bar_number

      @slur_writer.opens(voice_event) + @decoration_writer.prefix(voice_event) + body
    end

    def token_body(segment)
      voice_event = segment.voice_event
      ensure_pitched_sounds(voice_event)

      multiplier = multiplier_for(segment)
      tie = segment.continues ? "-" : ""
      return "z#{multiplier}" if voice_event.rest?
      return chord_token(voice_event, multiplier) + tie if voice_event.chord?

      "#{@pitch_writer.token(voice_event.pitch)}#{multiplier}#{tie}"
    end

    def multiplier_for(segment)
      rhythmic_value = segment.voice_event.rhythmic_value
      return @duration_writer.multiplier_string(rhythmic_value) unless segment.fraction

      @duration_writer.multiplier_string_for_fraction(segment.fraction, rhythmic_value)
    end

    # Pitches are emitted low-to-high so the writer's bar-accidental state
    # cannot diverge from what a re-parse of the brackets accumulates.
    def chord_token(voice_event, multiplier)
      pitch_tokens = voice_event.pitches.sort.map { |pitch| @pitch_writer.token(pitch) }
      "[#{pitch_tokens.join}]#{multiplier}"
    end

    def render_error_class
      RenderError
    end
  end
end
