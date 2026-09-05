# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads a token list into a Document.
  #
  # This reader is the envelope the Writer emits plus the common
  # hand-written shapes around it: an optional \version, \header, and
  # \score wrapper, and \layout and \midi blocks, which are skipped. The one
  # music expression the document holds is read by the MusicReader.
  class DocumentReader
    HEADER_FIELDS = %w[title composer].freeze
    SCORE_SKIPPED_COMMANDS = %w[layout midi].freeze

    def initialize(tokens)
      @cursor = TokenCursor.new(tokens)
    end

    def document
      @document ||= read
    end

    private

    attr_reader :cursor

    def read
      @building = Document.new
      @music = MusicReader.new(cursor, @building)
      @music_read = false
      root = VoiceContext.new(@building, nil, explicit: false)
      read_document(root)
      root.close
      @building
    end

    def read_document(context)
      until cursor.eos?
        token = cursor.peek
        if token.type == :command && ENVELOPE_COMMANDS.include?(token.lexeme)
          read_envelope_command(context)
        elsif token.type == :word && cursor.peek(1)&.type == :equals
          raise cursor.unsupported(%(Variable assignments such as "#{token.lexeme} =" are not supported), token)
        else
          read_top_level_music(context)
        end
      end
    end

    def read_envelope_command(context)
      case cursor.peek.lexeme
      when "version" then read_version
      when "header" then read_header
      when "score" then read_score(context)
      else cursor.skip_block
      end
    end

    def read_top_level_music(context)
      raise cursor.unsupported("Only one \\score or top-level music expression is supported", cursor.peek) if @music_read

      @music_read = true
      @music.read_expression(context)
    end

    def read_version
      version = cursor.advance
      token = cursor.advance
      return if token&.type == :string

      raise cursor.error("\\version expects a quoted version string", token || version)
    end

    def read_header
      cursor.advance
      cursor.expect(:open_brace, "\\header expects a block")
      AssignmentReader.new(cursor, "\\header", HEADER_FIELDS).read do |name, value|
        @building.title = value if name == "title"
        @building.composer = value if name == "composer"
      end
    end

    def read_score(context)
      cursor.advance
      cursor.expect(:open_brace, "\\score expects a block")
      read_score_item(context) until cursor.peek.type == :close_brace
      cursor.advance
    end

    def read_score_item(context)
      token = cursor.peek
      return cursor.skip_block if token.type == :command && SCORE_SKIPPED_COMMANDS.include?(token.lexeme)
      return read_header if token.type == :command && token.lexeme == "header"

      read_top_level_music(context)
    end
  end
end
