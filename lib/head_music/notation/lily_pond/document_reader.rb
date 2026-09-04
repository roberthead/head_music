# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads a token list into a Document by recursive descent.
  #
  # The grammar is the envelope the Writer emits plus the common hand-written
  # shapes: an optional \version, \header, and \score wrapper; \layout and
  # \midi blocks (skipped); and one music expression made of sequential
  # braces, << >> parallels of \new Staff or \new Voice contexts, \relative
  # or \absolute wrappers, and the note, rest, chord, tie, bar-check, \key,
  # \time, and \clef items inside. Every other command raises as
  # unsupported rather than being skipped, because skipping a \transpose or
  # a \tuplet would yield a plausible but wrong composition.
  class DocumentReader
    CONTEXT_TYPES = %w[Staff Voice].freeze
    # The reader recurses per brace level; the lexer and balance check do
    # not, so nesting must be bounded here to stay inside ParseError.
    MAX_NESTING_DEPTH = 1000
    DEFAULT_RELATIVE_REFERENCE = "F3"
    ENVELOPE_COMMANDS = %w[version header score layout midi].freeze

    # A Staff, Voice, or the implicit top level. It yields a voice when it
    # holds music, or when it is an explicit context with no children (an
    # empty \new Staff { } is a legitimate silent voice).
    class Context
      attr_reader :role, :stream, :explicit
      attr_accessor :children

      def initialize(role, stream, explicit)
        @role = role
        @stream = stream
        @explicit = explicit
        @children = 0
      end

      def voice?
        stream.music? || (explicit && children.zero?)
      end
    end

    def initialize(tokens)
      @tokens = tokens
    end

    def document
      @document ||= read
    end

    private

    def read
      @index = 0
      @building = Document.new
      @duration_reader = DurationReader.new
      @readers = [PitchReader.absolute]
      @music_read = false
      @depth = 0
      root = open_context(nil, explicit: false)
      read_document(root)
      close_context(root)
      @building
    end

    # --- document level -------------------------------------------------

    def read_document(context)
      until eos?
        token = peek
        if token.type == :command && ENVELOPE_COMMANDS.include?(token.lexeme)
          read_envelope_command(context)
        elsif token.type == :word && peek(1)&.type == :equals
          raise unsupported(%(Variable assignments such as "#{token.lexeme} =" are not supported), token)
        else
          read_top_level_music(context)
        end
      end
    end

    def read_envelope_command(context)
      case peek.lexeme
      when "version" then read_version
      when "header" then read_header
      when "score" then read_score(context)
      else skip_block
      end
    end

    def read_top_level_music(context)
      raise unsupported("Only one \\score or top-level music expression is supported", peek) if @music_read

      @music_read = true
      read_music_expression(context)
    end

    def read_version
      version = advance
      token = advance
      return if token&.type == :string

      raise error("\\version expects a quoted version string", token || version)
    end

    def read_header
      advance
      expect(:open_brace, "\\header expects a block")
      read_assignments("\\header") do |name, value|
        @building.title = value if name == "title"
        @building.composer = value if name == "composer"
      end
    end

    def read_score(context)
      advance
      expect(:open_brace, "\\score expects a block")
      until peek.type == :close_brace
        token = peek
        if token.type == :command && %w[layout midi].include?(token.lexeme)
          skip_block
        elsif token.type == :command && token.lexeme == "header"
          read_header
        else
          read_top_level_music(context)
        end
      end
      advance
    end

    # Reads `name = "string"` pairs up to the closing brace, yielding each;
    # anything but a string value is outside the supported subset.
    def read_assignments(block_name)
      until peek.type == :close_brace
        name = expect(:word, "#{block_name} expects name = \"value\" assignments", unsupported: true)
        expect(:equals, "#{block_name} expects name = \"value\" assignments", unsupported: true)
        value = advance
        unless value&.type == :string
          raise unsupported("#{block_name} values other than quoted strings are not supported", value || name)
        end

        yield name.lexeme, value.lexeme
      end
      advance
    end

    def skip_block
      advance
      expect(:open_brace, "Expected a block")
      depth = 1
      while depth.positive?
        token = advance
        depth += 1 if token.type == :open_brace
        depth -= 1 if token.type == :close_brace
      end
    end

    # --- music expressions ----------------------------------------------

    def read_music_expression(context)
      token = peek
      case token&.type
      when :open_brace then read_sequential(context)
      when :open_parallel then read_parallel(context)
      when :command then read_music_expression_command(context)
      else raise error("Expected a music expression", token)
      end
    end

    def read_music_expression_command(context)
      token = peek
      case token.lexeme
      when "relative" then read_relative { read_music_expression(context) }
      when "absolute" then read_absolute { read_music_expression(context) }
      when "new" then read_new(context)
      else raise unsupported_command(token)
      end
    end

    def read_sequential(context)
      nested(advance) do
        until peek.type == :close_brace
          read_music_item(context)
        end
      end
      advance
    end

    def read_parallel(context)
      token = advance
      raise unsupported("Simultaneous music inside \\relative is not supported", token) if reader.relative?

      nested(token) do
        until peek.type == :close_parallel
          read_parallel_item(context)
        end
      end
      advance
    end

    def nested(opener)
      @depth += 1
      raise error("Music expressions are nested too deeply", opener) if @depth > MAX_NESTING_DEPTH

      yield
      @depth -= 1
    end

    # Each parallel item must open a context; parallel bare music is voice
    # separation the model cannot represent.
    def read_parallel_item(context)
      token = peek
      case token.type == :command && token.lexeme
      when "new" then read_new(context)
      when "relative" then read_relative { read_parallel_item(context) }
      when "absolute" then read_absolute { read_parallel_item(context) }
      else raise unsupported("Simultaneous music without \\new contexts is not supported", token)
      end
    end

    def read_relative
      advance
      reference = relative_reference
      @readers.push(PitchReader.relative(reference))
      yield
      @readers.pop
    end

    def relative_reference
      return HeadMusic::Rudiment::Pitch.get(DEFAULT_RELATIVE_REFERENCE) unless peek&.type == :note

      token = advance
      raise error("\\relative expects a pitch", token) if token.duration || token.multiplier

      PitchReader.absolute.pitch(token)
    end

    def read_absolute
      advance
      @readers.push(PitchReader.absolute)
      yield
      @readers.pop
    end

    def read_new(context)
      advance
      type = expect(:word, "\\new expects a context type")
      raise unsupported(%(\\new #{type.lexeme} contexts are not supported), type) unless CONTEXT_TYPES.include?(type.lexeme)

      skip_context_name
      role = (peek&.type == :command && peek.lexeme == "with") ? read_with : nil
      role ||= context.role if type.lexeme == "Voice"
      child = open_context(role, explicit: true)
      context.children += 1
      read_music_expression(child)
      close_context(child)
    end

    def skip_context_name
      return unless peek&.type == :equals

      advance
      expect(:string, "A context name must be a quoted string")
    end

    def read_with
      advance
      expect(:open_brace, "\\with expects a block")
      role = nil
      read_assignments("\\with") do |name, value|
        role = value if name == "instrumentName"
      end
      role
    end

    # --- music items ----------------------------------------------------

    def read_music_item(context)
      token = peek
      case token.type
      when :note then read_note(context)
      when :rest then read_rest(context)
      when :whole_bar_rest then read_whole_bar_rest(context)
      when :open_chord then read_chord(context)
      when :tie then context.stream.open_tie(advance.line)
      when :bar_check then context.stream.bar_check(advance.line)
      when :open_brace then read_sequential(context)
      when :open_parallel then read_parallel(context)
      when :command then read_music_command(context)
      else raise error(%(Unexpected token "#{token.lexeme}"), token)
      end
    end

    def read_music_command(context)
      token = peek
      case token.lexeme
      when "key" then read_key(context)
      when "time" then read_time(context)
      when "clef" then read_clef
      when "relative" then read_relative { read_music_expression(context) }
      when "absolute" then read_absolute { read_music_expression(context) }
      when "new" then read_new(context)
      when *ENVELOPE_COMMANDS then raise error(%(Unexpected \\#{token.lexeme} inside music), token)
      else raise unsupported_command(token)
      end
    end

    def read_note(context)
      token = advance
      reject_multiplier(token)
      pitch = reader.pitch(token)
      context.stream.add_note([pitch], @duration_reader.rhythmic_value(token), token.line)
    end

    def read_rest(context)
      token = advance
      reject_multiplier(token)
      context.stream.add_rest(@duration_reader.rhythmic_value(token), token.line)
    end

    def read_whole_bar_rest(context)
      token = advance
      context.stream.add_whole_bar_rest(@duration_reader.whole_bar_fraction(token), token.line)
    end

    def read_chord(context)
      opener = advance
      notes = []
      until peek.type == :close_chord
        notes << chord_note
      end
      closer = advance
      raise error("Empty chord", opener) if notes.empty?

      reject_multiplier(closer)
      pitches = reader.chord_pitches(notes)
      context.stream.add_note(pitches, @duration_reader.rhythmic_value(closer), opener.line)
    end

    def chord_note
      token = advance
      raise error(%(Unexpected token "#{token.lexeme}" inside a chord), token) unless token.type == :note
      raise error("Chord notes cannot carry durations", token) if token.duration

      token
    end

    def reject_multiplier(token)
      return unless token.multiplier

      raise unsupported("Duration multipliers on notes and rests are not supported", token)
    end

    def read_key(context)
      command = advance
      pitch_token = advance
      mode_token = advance
      key_signature = KeyReader.key_signature(pitch_token, mode_token)
      context.stream.change_key_signature(key_signature, command.line)
    rescue ParseError => parse_error
      raise parse_error if parse_error.line_number

      raise error(parse_error.message, command)
    end

    def read_time(context)
      command = advance
      meter = MeterReader.meter(advance)
      context.stream.change_meter(meter, command.line)
    rescue ParseError => parse_error
      raise parse_error if parse_error.line_number

      raise error(parse_error.message, command)
    end

    def read_clef
      command = advance
      token = advance
      return if token && (%i[word string].include?(token.type) || (token.type == :note && token.duration.nil?))

      raise error("\\clef expects a clef name", token || command)
    end

    # --- contexts and helpers -------------------------------------------

    def open_context(role, explicit:)
      Context.new(role, @building.add_stream(role), explicit)
    end

    # A context that yields no voice may still have collected commands;
    # dropping them silently would lose a key or meter, so they raise.
    def close_context(context)
      stream = context.stream.finish
      return if context.voice?

      @building.remove_stream(stream)
      event = stream.events.find { |candidate| %i[key time].include?(candidate.kind) }
      return unless event

      raise UnsupportedFeatureError.new(
        "\\key and \\time outside a voice are not supported", line_number: event.line
      )
    end

    def reader
      @readers.last
    end

    def peek(offset = 0)
      @tokens[@index + offset]
    end

    def advance
      token = @tokens[@index]
      @index += 1 if token
      token
    end

    def eos?
      @index >= @tokens.length
    end

    def expect(type, message, unsupported: false)
      token = advance
      return token if token&.type == type

      raise(unsupported ? unsupported(message, token || peek(-1)) : error(message, token || peek(-1)))
    end

    def error(message, token)
      ParseError.new(message, line_number: token&.line, column: token&.column, snippet: token&.lexeme)
    end

    def unsupported(message, token)
      UnsupportedFeatureError.new(message, line_number: token&.line, column: token&.column, snippet: token&.lexeme)
    end

    def unsupported_command(token)
      UnsupportedFeatureError.new(
        %(Unsupported LilyPond feature "\\#{token.lexeme}"),
        line_number: token.line, column: token.column, snippet: "\\#{token.lexeme}"
      )
    end
  end
end
