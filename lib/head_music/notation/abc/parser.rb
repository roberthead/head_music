# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Interprets an ABC tune string as a HeadMusic::Content::Flow.
  #
  # Everything that can be validated up front (blank input, header
  # problems, lexing errors, unsupported features) raises before the
  # flow is constructed, so callers never receive a reference to
  # a partially built flow.
  class Parser
    HANDLERS = {
      note: :handle_note, chord: :handle_chord, rest: :handle_rest, tie: :handle_tie,
      invisible_rest: :handle_invisible_rest, spacer: :handle_spacer, overlay: :handle_overlay,
      broken_rhythm: :handle_broken_rhythm, bar_line: :handle_bar_line, volta: :handle_volta,
      beam_break: :handle_beam_break, decoration: :handle_decoration,
      slur_start: :handle_slur_start, slur_end: :handle_slur_end, part_label: :handle_part_label,
      tuplet: :handle_tuplet, grace: :handle_grace, tempo: :handle_tempo, annotation: :handle_annotation,
      meter: :handle_timeline_field, key: :handle_timeline_field
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
      @fermata_marks = HeadMusic::Notation::FermataMarks.new
      @tempo_marks = HeadMusic::Notation::TempoMarkReading.new
      setup_voices(tokens)
      VoiceReplay.new(@voices).each(tokens) { |token| handle(token) }
      finish
      @building
    end

    def setup_voices(tokens)
      @voices = VoiceRegistry.new(@building, header.key_signature, duration_resolver, @fermata_marks)
      @voices.declare(header.voice_ids, default: tokens.none? { |token| token.type == :voice_change })
    end

    def current_state
      @voices.current
    end

    def handle(token)
      current_state.reject_overlay_music(token) if @voices.any?
      handler = HANDLERS[token.type]
      send(handler, token) if handler
    end

    def handle_slur_start(_token)
      current_state.open_slur
    end

    def handle_slur_end(_token)
      current_state.close_slur
    end

    def handle_grace(token)
      state = current_state
      state.add_graces(*grace_reader.read(token, state.pitch_builder_in_key))
    end

    def handle_tuplet(token)
      line = token.line
      compound = @building.meter_at(current_state.entered_bar_number).compound?
      marker = TupletMarker.for(token.tuplet, compound: compound, line: line)
      current_state.open_tuplet(marker, line)
    end

    # A decoration waits for the note, chord, or rest after it.
    def handle_decoration(token)
      current_state.decorate(Decoration.from_token(token))
    end

    def handle_note(token)
      state = current_state
      bar_marks.at_note(state)
      pitch = state.pitch_builder_in_key.pitch(token.letter, token.octave_marks, token.accidental)
      state.defer_voice_event([pitch], token.length)
    end

    def handle_chord(token)
      state = current_state
      bar_marks.at_note(state)
      pitches, inner_length = chord_reader.read(token, state.pitch_builder_in_key)
      state.defer_voice_event(pitches, token.length, inner_length)
    end

    # The lexer only emits :beam_break after a music token, so a voice
    # state already exists; the flag is consumed by the next deferred note.
    def handle_beam_break(_token)
      current_state.beams.mark_break
    end

    def handle_tie(token)
      current_state.open_tie(token.line)
    end

    # The waiting decorations are the rest's own, so they are not dangling.
    def handle_rest(token)
      state = current_state
      bar_marks.at_note(state)
      state.end_notes(token.line)
      state.place(token.length, nil)
    end

    # An invisible rest ends a run of notes as a rest does, and holds only a
    # level. One in an overlay leaves the bar's music alone.
    def handle_invisible_rest(token)
      state = current_state
      unless state.overlay?
        bar_marks.at_note(state)
        state.end_notes(token.line)
      end
      state.skip(token.length)
    end

    def handle_overlay(token)
      current_state.start_overlay(token.line)
    end

    def handle_spacer(token)
      current_state.space(token.line)
    end

    def handle_broken_rhythm(token)
      current_state.break_rhythm(token.direction, token.line)
    end

    def handle_bar_line(token)
      bar_marks.bar_line(current_state, token)
    end

    def handle_volta(token)
      bar_marks.volta(current_state, token)
    end

    def handle_tempo(token)
      tempo = TempoField.read(token.lexeme, header.unit_note_length, line_number: token.line)
      @tempo_marks.add(mark_position, tempo) if tempo
    end

    # A meter or key field, read by TimelineFields#meter or #key.
    def handle_timeline_field(token)
      timeline_fields.public_send(token.type, (current_state if @voices.any?), token)
    end

    # Only an annotation's ramp and "a tempo" words are read.
    def handle_annotation(token)
      @tempo_marks.add(mark_position, nil, token.lexeme)
    end

    # A mark before any voice has begun stands at the start of the music.
    def mark_position
      @voices.any? ? current_state.mark_position : @building.position(HeadMusic::Time::MusicalPosition::DEFAULT_FIRST_BAR)
    end

    def handle_part_label(token)
      bar_marks.part_label((current_state if @voices.any?), token)
    end

    def finish
      @voices.each do |state|
        bar_marks.leave(state)
        state.end_voice(nil)
        bar_marks.close(state)
        state.add_hairpins
      end
      bar_marks.finish(@voices)
      @fermata_marks.apply(@building)
      @tempo_marks.apply(@building)
    end

    def chord_reader
      @chord_reader ||= ChordReader.new(duration_resolver)
    end

    def grace_reader
      @grace_reader ||= GraceReader.new(duration_resolver)
    end

    def timeline_fields
      @timeline_fields ||= TimelineFields.new(@building)
    end

    def bar_marks
      @bar_marks ||= BarMarkReader.new(@building)
    end
  end
end
