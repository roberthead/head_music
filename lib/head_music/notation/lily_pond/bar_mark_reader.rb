# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads the commands that mark a bar rather than sound in it: \bar styles,
  # rehearsal marks and section labels, segno and coda signs, \fine, and
  # \jump. A valid mark the model cannot hold, such as a repeat bar type or a
  # \markup rehearsal mark, is consumed and dropped.
  class BarMarkReader
    # A marking for a bar: the Bar attribute it sets and the value it sets.
    BarMark = Data.define(:attribute, :value) do
      def opening?
        OPENING_ATTRIBUTES.include?(attribute)
      end
    end

    OPENING_ATTRIBUTES = %i[rehearsal_mark segno coda].freeze
    COMMANDS = %w[bar mark segnoMark codaMark textMark jump textEndMark fine section sectionLabel].freeze
    SIGN_GLYPHS = {"scripts.segno" => :segno, "scripts.coda" => :coda}.freeze
    BARLINES_BY_TYPE = {"||" => :double, "|." => :final, "!" => :dashed, ";" => :dotted}.freeze
    TO_CODA = "To Coda"
    FINE = "Fine"
    # LilyPond's default rehearsal letters skip I.
    LETTERS = (("A".."Z").to_a - ["I"]).freeze

    def self.letters(number)
      prefix = (number > LETTERS.length) ? letters((number - 1) / LETTERS.length) : ""
      prefix + LETTERS[(number - 1) % LETTERS.length]
    end

    def initialize(cursor)
      @cursor = cursor
    end

    def read(stream = nil)
      command = cursor.advance
      bar_mark = read_command(command, stream)
      stream&.bar_mark(bar_mark, command.line) if bar_mark
    end

    private

    attr_reader :cursor

    def read_command(command, stream)
      case command.lexeme
      when "bar" then read_bar
      when "mark" then read_mark(command, stream)
      when "segnoMark" then read_sign(command, :segno)
      when "codaMark" then read_sign(command, :coda)
      when "textMark" then read_text_mark(command)
      when "jump", "textEndMark" then read_closing_text(command)
      when "fine" then BarMark.new(:fine, true)
      when "section" then BarMark.new(:barline, :double)
      when "sectionLabel" then read_section_label
      end
    end

    def read_bar
      bar_type = cursor.expect(:string, "\\bar expects a quoted bar type")
      barline = BARLINES_BY_TYPE[bar_type.lexeme]
      barline && BarMark.new(:barline, barline)
    end

    def read_mark(command, stream)
      token = cursor.peek
      case token&.type
      when :string then BarMark.new(:rehearsal_mark, cursor.advance.lexeme)
      when :number then numbered_mark(stream, cursor.advance.lexeme.to_i)
      when :command then read_mark_command(stream)
      else raise cursor.error("\\mark expects \\default, a number, or a string", token || command)
      end
    end

    # A \textEndMark is how the writer puts a Fine before the last bar, and
    # the words of any other navigation read the same as a \jump's.
    def read_closing_text(command)
      return skip_markup if markup?(cursor.peek)

      text = cursor.expect(:string, "\\#{command.lexeme} expects a quoted instruction").lexeme.strip
      return BarMark.new(:to_coda, true) if text.casecmp?(TO_CODA)
      return BarMark.new(:fine, true) if text.casecmp?(FINE)

      jump = HeadMusic::Content::Jump.get(text)
      jump && BarMark.new(:jump, jump)
    end

    def read_section_label
      return skip_markup if markup?(cursor.peek)

      BarMark.new(:rehearsal_mark, cursor.expect(:string, "\\sectionLabel expects a quoted label").lexeme)
    end

    def read_mark_command(stream)
      token = cursor.peek
      return skip_markup if markup?(token)
      raise cursor.error("\\mark expects \\default, a number, or a string", token) unless token.lexeme == "default"

      cursor.advance
      numbered_mark(stream, nil)
    end

    # The letter a \mark \default or a numbered \mark prints, counted per
    # voice, since the writer repeats each mark in every voice.
    def numbered_mark(stream, number)
      return unless stream

      BarMark.new(:rehearsal_mark, self.class.letters(stream.rehearsal_number(number)))
    end

    def read_sign(command, attribute)
      token = cursor.advance
      return BarMark.new(attribute, true) if token&.type == :number && token.lexeme.to_i.positive?
      return BarMark.new(attribute, true) if token&.type == :command && token.lexeme == "default"

      raise cursor.error("\\#{command.lexeme} expects \\default or a number", token || command)
    end

    # A \textMark of the segno or coda glyph is how the writer puts both signs
    # on one bar; other text is dropped.
    def read_text_mark(command)
      sign = sign_glyph
      if sign
        3.times { cursor.advance }
        return BarMark.new(sign, true)
      end
      return skip_markup if markup?(cursor.peek)

      cursor.expect(:string, "\\#{command.lexeme} expects a string or a markup")
      nil
    end

    def sign_glyph
      glyph = cursor.peek(2)
      return unless markup?(cursor.peek) && cursor.peek(1)&.lexeme == "musicglyph" && glyph&.type == :string

      SIGN_GLYPHS[glyph.lexeme]
    end

    def markup?(token)
      token&.type == :command && token.lexeme == "markup"
    end

    # A markup is free text the model cannot hold as a rehearsal mark or
    # jump: its function commands, then a string, a word, or a block.
    def skip_markup
      cursor.advance
      cursor.advance while cursor.peek&.type == :command
      token = cursor.peek
      case token&.type
      when :open_brace then skip_braces
      when :string, :word then cursor.advance
      else raise cursor.error("\\markup expects a string or a block", token || cursor.peek(-1))
      end
      nil
    end

    def skip_braces
      cursor.advance
      depth = 1
      while depth.positive?
        token = cursor.advance
        depth += 1 if token.type == :open_brace
        depth -= 1 if token.type == :close_brace
      end
    end
  end
end
