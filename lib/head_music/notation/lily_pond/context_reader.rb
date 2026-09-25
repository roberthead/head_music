# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads the declaration of a Staff or Voice context — \new, the optional
  # context name, and the \with block that can name the instrument — and
  # the rules about where a context may appear. The music inside it is read
  # by the MusicReader that opened this one. A \new PianoStaff or \new
  # StaffGroup holds the staves of one part.
  class ContextReader
    BRACKETS_BY_GROUP_TYPE = {"PianoStaff" => :brace, "StaffGroup" => :bracket}.freeze
    CONTEXT_TYPES = (%w[Staff Voice] + BRACKETS_BY_GROUP_TYPE.keys).freeze
    WITH_FIELDS = %w[instrumentName].freeze

    def initialize(cursor, document, music)
      @cursor = cursor
      @document = document
      @music = music
    end

    def read_new(context)
      opener = cursor.advance
      type = cursor.expect(:word, "\\new expects a context type")
      unless CONTEXT_TYPES.include?(type.lexeme)
        raise cursor.unsupported(%(\\new #{type.lexeme} contexts are not supported), type)
      end

      name = context_name
      context.children += 1
      return read_group(opener, type, context) if BRACKETS_BY_GROUP_TYPE.key?(type.lexeme)

      child = VoiceContext.new(
        document, role(context, type, name), explicit: true, group_staff: group_staff(context, type, name)
      )
      music.nested(opener) { music.read_expression(child) }
      child.close
    end

    # Each parallel item must open a context; parallel bare music is voice
    # separation the model cannot represent.
    def read_parallel_item(context)
      token = cursor.peek
      raise cursor.unsupported_token(token) if token.type == :unsupported

      case token.type == :command && token.lexeme
      when "new" then read_new(context)
      when "relative" then music.read_relative { read_parallel_item(context) }
      when "absolute" then music.read_absolute { read_parallel_item(context) }
      else raise cursor.unsupported("Simultaneous music without \\new contexts is not supported", token)
      end
    end

    # LilyPond starts a context where the sequence around it has reached,
    # but a stream always starts at bar one, so a context inside a sequence
    # is only placed correctly when it is the whole of that sequence.
    def read_sequential_new(context)
      raise cursor.unsupported("A \\new context that follows music in a sequence is not supported", cursor.peek) if context.stream.music?

      read_new(context)
      return if cursor.peek&.type == :close_brace

      raise cursor.unsupported("Music that follows a \\new context in a sequence is not supported", cursor.peek)
    end

    private

    attr_reader :cursor, :document, :music

    # A group is one part, so it holds staves and nothing else, and one group
    # cannot hold another.
    def read_group(opener, type, context)
      if context.group || context.group_staff
        raise cursor.unsupported(%(\\new #{type.lexeme} inside another staff group is not supported), type)
      end

      group = document.add_group(BRACKETS_BY_GROUP_TYPE.fetch(type.lexeme))
      group_context = VoiceContext.new(document, nil, explicit: false, group: group)
      music.nested(opener) { read_group_staves(group_context, type) }
      group_context.close
    end

    def read_group_staves(group_context, type)
      opener = cursor.expect(:open_parallel, %(\\new #{type.lexeme} expects its staves inside << >>), unsupported: true)
      raise cursor.unsupported("Simultaneous music inside \\relative is not supported", opener) if music.relative?

      until cursor.peek.type == :close_parallel
        unless cursor.peek.type == :command && cursor.peek.lexeme == "new" && cursor.peek(1)&.lexeme == "Staff"
          raise cursor.unsupported(%(Only \\new Staff contexts are supported inside \\new #{type.lexeme}), cursor.peek)
        end

        read_new(group_context)
      end
      cursor.advance
    end

    def group_staff(context, type, name)
      return context.group_staff if type.lexeme == "Voice"

      context.group && document.add_group_staff(context.group, name)
    end

    # A Voice with no name of its own belongs to the staff that holds it. In
    # a staff group, where staves carry no instrument name, a Voice's context
    # name is its role.
    def role(context, type, name)
      with_role || (voice_role(context, name) if type.lexeme == "Voice")
    end

    def voice_role(context, name)
      (context.group_staff && name) || context.role
    end

    def context_name
      return unless cursor.peek&.type == :equals

      cursor.advance
      cursor.expect(:string, "A context name must be a quoted string").lexeme
    end

    def with_role
      return unless cursor.peek&.type == :command && cursor.peek.lexeme == "with"

      cursor.advance
      cursor.expect(:open_brace, "\\with expects a block")
      role = nil
      AssignmentReader.new(cursor, "\\with", WITH_FIELDS).read do |name, value|
        role = value if name == "instrumentName"
      end
      role
    end
  end
end
