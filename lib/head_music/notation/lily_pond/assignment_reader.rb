# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads a block of `name = value` assignments — a \header or a \with — up
  # to its closing brace, yielding the fields the caller named. A field the
  # caller did not name carries no musical meaning and is commonly Scheme
  # (tagline = ##f), so its value is skipped by balance; a field the caller
  # reads must be a quoted string.
  class AssignmentReader
    def initialize(cursor, block_name, fields)
      @cursor = cursor
      @block_name = block_name
      @fields = fields
    end

    def read
      until cursor.peek.type == :close_brace
        name = cursor.expect(:word, message, unsupported: true)
        cursor.expect(:equals, message, unsupported: true)
        if fields.include?(name.lexeme)
          yield name.lexeme, string_value(name)
        else
          skip_value(name)
        end
      end
      cursor.advance
    end

    private

    attr_reader :cursor, :block_name, :fields

    def message
      "#{block_name} expects name = \"value\" assignments"
    end

    def string_value(name)
      value = cursor.advance
      return value.lexeme if value&.type == :string

      raise cursor.unsupported("#{block_name} values other than quoted strings are not supported", value || name)
    end

    # The value runs to the next assignment or the closing brace, whichever
    # comes first at the outermost level. A value of no tokens is a
    # malformed assignment rather than an empty one.
    def skip_value(name)
      depth = 0
      consumed = 0
      until cursor.eos?
        token = cursor.peek
        break if depth.zero? && (next_assignment? || token.type == :close_brace)

        depth += 1 if token.type == :open_brace
        depth -= 1 if token.type == :close_brace
        cursor.advance
        consumed += 1
      end
      raise cursor.unsupported(message, name) if consumed.zero?
    end

    def next_assignment?
      cursor.peek&.type == :word && cursor.peek(1)&.type == :equals
    end
  end
end
