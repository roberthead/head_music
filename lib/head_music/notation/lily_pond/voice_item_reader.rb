# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads one item of a voice's music, handing it to the reader for its
  # kind: a MusicItemReader for notes, rests, chords, and \change Staff, a
  # SettingReader for \key, \time, and \clef, a BarMarkReader for \bar,
  # \mark, and navigation, and a TupletReader for \tuplet and \times. An
  # \after, \afterGrace, or \tuplet wraps the one item that follows it.
  # Braces, parallels, and the commands that wrap an expression belong to
  # the MusicReader that calls this one.
  class VoiceItemReader
    WRAPPABLE_MUSIC = %i[note rest whole_bar_rest spacer open_chord open_brace after tuplet].freeze

    def initialize(cursor, music, items:, settings:, bar_marks:, contexts:, tuplets:)
      @cursor = cursor
      @music = music
      @items = items
      @settings = settings
      @bar_marks = bar_marks
      @contexts = contexts
      @tuplets = tuplets
    end

    def read(context)
      token = cursor.peek
      case token.type
      when :note then items.read_note(context)
      when :rest then items.read_rest(context)
      when :whole_bar_rest then read_whole_bar_rest(context)
      when :spacer then items.read_spacer(context)
      when :after then read_after(context)
      when :tuplet then tuplets.read(context) { music.nested(token) { read(context) } }
      when :tuplet_span then tuplets.read_span(context)
      when :open_chord then items.read_chord(context)
      when :tie then items.read_tie(context)
      when :bar_check then items.read_bar_check(context)
      when :open_brace, :open_parallel then music.read_expression(context)
      when :command then read_command(context, token)
      when :unsupported then raise cursor.unsupported_token(token)
      else raise cursor.error(%(Unexpected token "#{token.lexeme}"), token)
      end
    end

    private

    attr_reader :cursor, :music, :items, :settings, :bar_marks, :contexts, :tuplets

    def read_command(context, token)
      case token.lexeme
      when *SettingReader::COMMANDS then settings.read(context.stream)
      when *BarMarkReader::COMMANDS then bar_marks.read(context.stream)
      when "change" then items.read_staff_change(context)
      when *MarkReader::HAIRPIN_STYLE_COMMANDS then cursor.advance
      when *GraceReader::COMMANDS then items.read_grace(context)
      when "afterGrace" then read_after_grace(context)
      when "new" then contexts.read_sequential_new(context)
      when *ENVELOPE_COMMANDS then raise cursor.error(%(Unexpected \\#{token.lexeme} inside music), token)
      else music.read_expression(context)
      end
    end

    def read_whole_bar_rest(context)
      music.reject_inside_tuplet(context, "A whole-bar rest", cursor.peek)
      items.read_whole_bar_rest(context)
    end

    def read_after(context)
      token = cursor.peek
      items.read_after(context)
      read_wrapped(context, token, "\\after")
    end

    # \afterGrace [fraction] main { graces } reads its main note as any other.
    def read_after_grace(context)
      token = cursor.advance
      cursor.advance if cursor.peek&.type == :number
      read_wrapped(context, token, "\\afterGrace")
      items.skip_grace(token)
    end

    def read_wrapped(context, command, name)
      raise cursor.error("#{name} expects music", cursor.peek || command) unless WRAPPABLE_MUSIC.include?(cursor.peek&.type)

      music.nested(command) { read(context) }
    end
  end
end
