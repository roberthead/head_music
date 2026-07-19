# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Interprets an ABC tune string as a HeadMusic::Content::Composition.
  #
  # Everything that can be validated up front (blank input, header
  # problems, lexing errors, unsupported features) raises before the
  # composition is constructed, so callers never receive a reference to
  # a partially built composition.
  class Parser
    # Broken-rhythm scales: the mark's side gets the dot (x 3/2) and the
    # other side is halved.
    BROKEN_RHYTHM_SCALES = {
      :> => [Rational(3, 2), Rational(1, 2)],
      :< => [Rational(1, 2), Rational(3, 2)]
    }.freeze

    # Bar styles that end a repeated section, terminating any volta.
    REPEAT_ENDING_STYLES = [":|", "::"].freeze
    REPEAT_STARTING_STYLES = ["|:", "::"].freeze
    SECTION_ENDING_STYLES = ["||", "|]", "[|"].freeze

    # start_line offsets reported line numbers, so a tune parsed out of a
    # larger book raises errors with book-relative line numbers.
    def initialize(abc_string, start_line: 1)
      @abc_string = abc_string
      @start_line = start_line
    end

    def composition
      @composition ||= build_composition
    end

    private

    attr_reader :header, :duration_resolver

    # A note or chord whose placement is deferred until we know whether
    # a broken-rhythm mark follows it. The pitches are computed eagerly
    # so bar-line accidental resets cannot corrupt them.
    PendingNote = Data.define(:pitches, :length, :scale)

    # Per-voice interpretation state. Accidentals, the deferred note,
    # and volta tracking are all independent between voices.
    class VoiceState
      attr_reader :voice, :pitch_builder
      attr_accessor :pending_note, :awaiting_scale, :broken_line,
        :active_passes, :volta_start_bar

      def initialize(voice, pitch_builder)
        @voice = voice
        @pitch_builder = pitch_builder
      end

      def completed_bar_number
        voice.last_placement&.position&.bar_number
      end

      def entered_bar_number
        voice.next_position.bar_number
      end
    end

    def build_composition
      ensure_input_present
      @header = Header.new(@abc_string, start_line: @start_line)
      reject_content_after_tune
      tokens = BodyLexer.new(header.body, start_line: header.body_start_line).tokens
      reject_unsupported_tokens(tokens)
      @duration_resolver = DurationResolver.new(header.unit_note_length)
      interpret(tokens)
    end

    def ensure_input_present
      return unless @abc_string.to_s.strip.empty?

      raise ParseError, "ABC input is blank"
    end

    # The lexer treats a blank line as the end of the tune, so anything
    # after it would be silently dropped — most likely another tune.
    def reject_content_after_tune
      lines = header.body.lines
      blank_index = lines.find_index { |line| line.strip.empty? }
      return unless blank_index

      extra_lines = lines[(blank_index + 1)..]
      extra_index = extra_lines.find_index do |line|
        stripped = line.strip
        !stripped.empty? && !stripped.start_with?("%")
      end
      return unless extra_index

      raise ParseError.new(
        "Content after the tune body; parse a book of tunes with ABC.parse_book",
        line_number: header.body_start_line + blank_index + 1 + extra_index,
        snippet: extra_lines[extra_index].strip[0, BodyLexer::SNIPPET_LENGTH]
      )
    end

    def reject_unsupported_tokens(tokens)
      token = tokens.find { |candidate| candidate.type == :unsupported }
      return unless token

      raise UnsupportedFeatureError.new(
        "Unsupported ABC feature #{token.lexeme.inspect}",
        line_number: token.line, snippet: token.lexeme
      )
    end

    def interpret(tokens)
      @building = HeadMusic::Content::Composition.new(
        name: header.title,
        key_signature: header.key_signature,
        meter: header.meter,
        composer: header.composer,
        origin: header.origin,
        comments: header.annotations
      )
      setup_voices(tokens)
      tokens.each { |token| handle(token) }
      finish
      @building
    end

    def setup_voices(tokens)
      @voice_states = {}
      header.voice_ids.each { |voice_id| voice_state(voice_id) }
      if @voice_states.empty? && tokens.none? { |token| token.type == :voice_change }
        voice_state(nil)
      end
      @current_state = @voice_states.values.first
    end

    def voice_state(role)
      @voice_states[role] ||= VoiceState.new(
        @building.add_voice(role: role),
        PitchBuilder.new(header.key_signature)
      )
    end

    # Body music before any V: line falls into a default unnamed voice.
    def current_state
      @current_state ||= voice_state(nil)
    end

    def handle(token)
      case token.type
      when :note then handle_note(token)
      when :chord then handle_chord(token)
      when :rest then handle_rest(token)
      when :broken_rhythm then handle_broken_rhythm(token)
      when :bar_line then handle_bar_line(token)
      when :volta then handle_volta(token)
      when :voice_change then handle_voice_change(token)
      end
    end

    def handle_note(token)
      state = current_state
      pitch = state.pitch_builder.pitch(token.letter, token.octave_marks, token.accidental)
      defer_placement(state, [pitch], token.length)
    end

    # Chord pitches resolve in bracket order, so an explicit accidental
    # inside a chord persists for the rest of the bar like any other.
    def handle_chord(token)
      state = current_state
      pitches = token.notes.map do |note|
        state.pitch_builder.pitch(note.letter, note.octave_marks, note.accidental)
      end
      ensure_unique_chord_pitches(pitches, token)
      inner_length = uniform_chord_length(token)
      defer_placement(state, pitches, token.length, inner_length)
    end

    def ensure_unique_chord_pitches(pitches, token)
      return if pitches.uniq.length == pitches.length

      raise ParseError.new(
        "Chord pitches must be unique",
        line_number: token.line, snippet: chord_snippet(token)
      )
    end

    # ABC 2.1 sec. 4.17 allows per-note lengths only when they agree; the
    # shared inner length then multiplies with any outer length. Unequal
    # lengths (whose ABC meaning is "the duration of the first note") would
    # need silent reinterpretation to fit one rhythmic value, so we reject.
    def uniform_chord_length(token)
      fractions = token.notes.map { |note| duration_resolver.length_fraction(note.length) }
      return fractions.first if fractions.uniq.length == 1

      raise ParseError.new(
        'Chord notes must share one length; write it after the bracket ("[CEG]2") ' \
        'or repeat it on every note ("[C2E2G2]")',
        line_number: token.line, snippet: chord_snippet(token)
      )
    end

    def chord_snippet(token)
      inner = token.notes.map do |note|
        "#{note.accidental}#{note.letter}#{note.octave_marks}#{note.length}"
      end.join
      "[#{inner}]"
    end

    def defer_placement(state, pitches, length, inner_scale = Rational(1))
      scale = (state.awaiting_scale || Rational(1)) * inner_scale
      state.awaiting_scale = nil
      flush_pending_note(state)
      state.pending_note = PendingNote.new(pitches: pitches, length: length, scale: scale)
    end

    def handle_rest(token)
      ensure_not_awaiting_note(token)
      state = current_state
      flush_pending_note(state)
      place(state, token.length, nil)
    end

    def handle_broken_rhythm(token)
      state = current_state
      if state.awaiting_scale || state.pending_note.nil?
        raise ParseError.new(
          "Broken rhythm must appear between two notes",
          line_number: token.line, snippet: token.direction.to_s
        )
      end
      left_scale, right_scale = BROKEN_RHYTHM_SCALES.fetch(token.direction)
      state.pending_note = state.pending_note.with(scale: state.pending_note.scale * left_scale)
      state.awaiting_scale = right_scale
      state.broken_line = token.line
    end

    def handle_bar_line(token)
      ensure_not_awaiting_note(token)
      state = current_state
      flush_pending_note(state)
      tag_completed_bar(state)
      apply_repeat_flags(state, token.style)
      clear_passes_if_over(state, token.style)
      state.pitch_builder.start_new_bar
    end

    def handle_volta(token)
      ensure_not_awaiting_note(token)
      if token.passes.empty?
        raise ParseError.new("Volta has no passes", line_number: token.line)
      end
      state = current_state
      flush_pending_note(state)
      state.active_passes = token.passes
      state.volta_start_bar = state.entered_bar_number
    end

    def handle_voice_change(token)
      # Guarded so a leading V: line doesn't force a default voice into existence.
      if @current_state
        ensure_not_awaiting_note(token, state: @current_state)
        flush_pending_note(@current_state)
      end
      @current_state = voice_state(token.voice_id)
    end

    def finish
      @voice_states.each_value do |state|
        ensure_not_awaiting_note(nil, state: state)
        flush_pending_note(state)
        tag_completed_bar(state)
      end
    end

    def ensure_not_awaiting_note(token, state: current_state)
      return unless state.awaiting_scale

      raise ParseError.new(
        "Broken rhythm must be followed by a note",
        line_number: token&.line || state.broken_line
      )
    end

    def flush_pending_note(state)
      pending = state.pending_note
      return unless pending

      state.pending_note = nil
      place(state, pending.length, pending.pitches, scale: pending.scale)
    end

    def place(state, length, pitches, scale: Rational(1))
      rhythmic_value = duration_resolver.rhythmic_value(length, scale: scale)
      state.voice.place(state.voice.next_position, rhythmic_value, pitches)
    end

    def apply_repeat_flags(state, style)
      if REPEAT_ENDING_STYLES.include?(style)
        completed = state.completed_bar_number
        bar(completed).ends_repeat_after_num_plays = 2 if completed
      end
      return unless REPEAT_STARTING_STYLES.include?(style)

      bar(state.entered_bar_number).starts_repeat = true
    end

    # A volta covers every bar from its opening bracket through the bar
    # line that ends it, so each completed bar in that span gets tagged.
    def tag_completed_bar(state)
      return unless state.active_passes

      completed = state.completed_bar_number
      return unless completed && completed >= state.volta_start_bar

      bar(completed).plays_on_passes = state.active_passes
    end

    def clear_passes_if_over(state, style)
      return unless REPEAT_ENDING_STYLES.include?(style) || SECTION_ENDING_STYLES.include?(style)

      state.active_passes = nil
      state.volta_start_bar = nil
    end

    def bar(bar_number)
      @building.bars(bar_number).last
    end
  end
end
