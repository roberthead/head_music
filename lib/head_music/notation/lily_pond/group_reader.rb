# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads a \new PianoStaff or \new StaffGroup once its type is known. A group
  # is one part, so it holds staves, and the dynamics between them, and
  # nothing else, and one group cannot hold another. Each member is read by
  # the ContextReader that calls this one.
  class GroupReader
    MEMBER_TYPES = %w[Staff Dynamics].freeze

    def initialize(cursor, document, music, contexts)
      @cursor = cursor
      @document = document
      @music = music
      @contexts = contexts
    end

    def read(opener, type, context)
      if context.group || context.group_staff
        raise cursor.unsupported(%(\\new #{type.lexeme} inside another staff group is not supported), type)
      end

      group = document.add_group(ContextReader::BRACKETS_BY_GROUP_TYPE.fetch(type.lexeme))
      group_context = VoiceContext.new(document, nil, explicit: false, group: group)
      music.nested(opener) { read_staves(group_context, type) }
      group_context.close
      context.preceding_staff = group
    end

    private

    attr_reader :cursor, :document, :music, :contexts

    def read_staves(group_context, type)
      opener = cursor.expect(:open_parallel, %(\\new #{type.lexeme} expects its staves inside << >>), unsupported: true)
      raise cursor.unsupported("Simultaneous music inside \\relative is not supported", opener) if music.relative?

      until cursor.peek.type == :close_parallel
        unless member?
          raise cursor.unsupported(%(Only \\new Staff and \\new Dynamics contexts are supported inside \\new #{type.lexeme}), cursor.peek)
        end

        contexts.read_new(group_context)
      end
      cursor.advance
    end

    def member?
      cursor.peek.type == :command && cursor.peek.lexeme == "new" && MEMBER_TYPES.include?(cursor.peek(1)&.lexeme)
    end
  end
end
