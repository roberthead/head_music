# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Interprets an ABC tune string as a HeadMusic::Content::Flow.
  #
  # Everything that can be validated up front (blank input, header
  # problems, lexing errors, unsupported features) raises before the
  # flow is constructed, so callers never receive a reference to
  # a partially built flow.
  class Parser
    # Broken-rhythm scales: the mark's side gets the dot (x 3/2) and the
    # other side is halved.
    BROKEN_RHYTHM_SCALES = {
      :> => [Rational(3, 2), Rational(1, 2)],
      :< => [Rational(1, 2), Rational(3, 2)]
    }.freeze

    HANDLERS = {
      note: :handle_note, chord: :handle_chord, rest: :handle_rest, tie: :handle_tie,
      broken_rhythm: :handle_broken_rhythm, bar_line: :handle_bar_line, volta: :handle_volta,
      voice_change: :handle_voice_change, beam_break: :handle_beam_break, decoration: :handle_decoration,
      slur_start: :handle_slur_start, slur_end: :handle_slur_end, part_label: :handle_part_label
    }.freeze

    # start_line offsets reported line numbers, so a tune parsed out of a
    # larger book raises errors with book-relative line numbers.
    def initialize(abc_string, start_line: 1)
      @abc_string = abc_string
      @start_line = start_line
    end

    def flow
      @flow ||= build_flow
    end

    private

    attr_reader :header, :duration_resolver

    # Per-voice interpretation state and note-assembly live in VoiceState.

    def build_flow
      Preflight.ensure_input_present(@abc_string)
      @header = Header.new(@abc_string, start_line: @start_line)
      Preflight.reject_content_after_tune(header)
      tokens = BodyLexer.new(header.body, start_line: header.body_start_line).tokens
      Preflight.reject_unsupported_tokens(tokens)
      Preflight.reject_unrecognized_decorations(tokens)
      @duration_resolver = DurationResolver.new(header.unit_note_length)
      interpret(tokens)
    end

    def interpret(tokens)
      @building = HeadMusic::Content::Flow.new(**header.flow_attributes)
      setup_voices(tokens)
      tokens.each { |token| handle(token) }
      finish
      @building
    end

    def setup_voices(tokens)
      @voices = VoiceRegistry.new(@building, header.key_signature, duration_resolver)
      @voices.declare(header.voice_ids, default: tokens.none? { |token| token.type == :voice_change })
    end

    def current_state
      @voices.current
    end

    def handle(token)
      handler = HANDLERS[token.type]
      send(handler, token) if handler
    end

    def handle_slur_start(_token)
      current_state.open_slur
    end

    def handle_slur_end(_token)
      current_state.close_slur
    end

    # A decoration waits for the note, chord, or rest after it.
    def handle_decoration(token)
      current_state.decorate(Decoration.from_token(token))
    end

    def handle_note(token)
      state = current_state
      navigation_tagger.record_at_note(state)
      pitch = state.pitch_builder.pitch(token.letter, token.octave_marks, token.accidental)
      state.defer_voice_event([pitch], token.length)
    end

    def handle_chord(token)
      state = current_state
      navigation_tagger.record_at_note(state)
      pitches, inner_length = chord_reader.read(token, state.pitch_builder)
      state.defer_voice_event(pitches, token.length, inner_length)
    end

    # The lexer only emits :beam_break after a music token, so a voice
    # state already exists; the flag is consumed by the next deferred note.
    def handle_beam_break(_token)
      current_state.mark_beam_break
    end

    # A tie (`-`) after a note or chord fuses it to the next note of the
    # same pitch. The left note stays pending; the tie is only closed once
    # its right note arrives.
    def handle_tie(token)
      state = current_state
      line = token.line
      raise ParseError.new("A tie must follow a note", line_number: line, snippet: "-") unless state.after_note?

      state.reject_dangling_decorations
      state.open_tie(line)
    end

    # The waiting decorations are the rest's own, so they are not dangling.
    def handle_rest(token)
      state = current_state
      navigation_tagger.record_at_note(state)
      end_notes(state, token.line)
      state.place(token.length, nil)
    end

    # A rest, a voice change, or the end of the tune ends a run of notes:
    # nothing after it can complete a broken rhythm or close a tie.
    def end_notes(state, line)
      state.ensure_not_awaiting_note(line)
      state.reject_open_tie(line)
      state.flush_pending_note
      state.reset_beam_adjacency
    end

    # Nothing further in the voice can take a decoration either.
    def end_voice(state, line)
      end_notes(state, line)
      state.reject_dangling_decorations
    end

    # A bar line or volta is not a terminator: a tied note stays pending
    # across it and closes on the next note.
    def cross_bar_line(state, line)
      state.ensure_not_awaiting_note(line)
      state.reject_dangling_decorations
      state.flush_pending_note unless state.tie_open?
      state.reset_beam_adjacency
    end

    def handle_broken_rhythm(token)
      state = current_state
      line = token.line
      direction = token.direction
      state.reject_open_tie(line)
      state.reject_dangling_decorations
      unless state.after_note?
        raise ParseError.new("Broken rhythm must appear between two notes", line_number: line, snippet: direction.to_s)
      end

      state.break_rhythm(*BROKEN_RHYTHM_SCALES.fetch(direction), line)
    end

    # A note tied across the bar line is left pending rather than flushed, so
    # the note after the bar line fuses onto it the way an in-bar tie does,
    # keeping the pending note's pitch: the bar's accidental reset below
    # would otherwise strip the sharp or flat the tie carries.
    def handle_bar_line(token)
      state = current_state
      navigation_tagger.record_at_bar_line(state)
      cross_bar_line(state, token.line)
      repeat_tagger.bar_line(state, token.style)
      state.pitch_builder.start_new_bar
    end

    def handle_volta(token)
      state = current_state
      line = token.line
      state.ensure_not_awaiting_note(line)
      passes = token.passes
      raise ParseError.new("Volta has no passes", line_number: line) if passes.empty?

      navigation_tagger.record_at_bar_line(state)
      cross_bar_line(state, line)
      repeat_tagger.open_volta(state, passes)
    end

    # Guarded so a leading V: line doesn't force a default voice into existence.
    def handle_voice_change(token)
      if @voices.any?
        state = current_state
        navigation_tagger.record_at_bar_line(state, entering: false)
        end_voice(state, token.line)
      end
      @voices.switch_to(token.voice_id)
    end

    # A part label marks the bar it opens. One before any voice has music
    # opens the first bar.
    def handle_part_label(token)
      label = token.lexeme
      return if label.empty?

      state = current_state if @voices.any?
      bar_number = state ? state.entered_bar_number : HeadMusic::Time::MusicalPosition::DEFAULT_FIRST_BAR
      navigation_tagger.record_part_label(state, label, bar_number)
    end

    def finish
      @voices.each do |state|
        navigation_tagger.record_at_bar_line(state, entering: false)
        end_voice(state, nil)
        repeat_tagger.tag_completed_bar(state)
      end
      navigation_tagger.apply
      imply_final_barline
    end

    # The last bar's final barline is implied, and writers draw it.
    def imply_final_barline
      last_bar = @building.bar(@building.last_sounding_bar_number)
      last_bar.barline = :regular if last_bar.barline == :final
    end

    def chord_reader
      @chord_reader ||= ChordReader.new(duration_resolver)
    end

    def repeat_tagger
      @repeat_tagger ||= RepeatTagger.new(@building)
    end

    def navigation_tagger
      @navigation_tagger ||= NavigationTagger.new(@building)
    end
  end
end
