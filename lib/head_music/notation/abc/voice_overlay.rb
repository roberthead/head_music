# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # A voice overlay, "&", starts its bar over so that invisible rests can
  # place levels where no note of the bar starts. It is read only for those
  # levels, so it holds nothing but time.
  class VoiceOverlay
    MUSIC = %i[note chord rest tie broken_rhythm slur_start slur_end tuplet grace].freeze

    attr_reader :cursor

    def initialize(voice)
      @voice = voice
    end

    def active?
      !@cursor.nil?
    end

    # The bar an overlay starts over is the one the last bar line opened.
    def bar_line(position)
      @bar_start = position
    end

    def start
      @cursor = @bar_start || HeadMusic::Content::Position.new(@voice.flow, 1, 1, 0)
    end

    def advance(rhythmic_value)
      @cursor += rhythmic_value
    end

    def reject_music(token)
      return unless active? && MUSIC.include?(token.type)

      raise UnsupportedFeatureError.new(
        "Unsupported ABC feature: a voice overlay holding notes or rests, which would be a second voice",
        line_number: token.line, snippet: "&"
      )
    end

    def finish(music_cursor, line)
      if @cursor && @cursor > music_cursor
        raise ParseError.new("A voice overlay must not run past its bar's music", line_number: line, snippet: "&")
      end

      @cursor = nil
    end
  end
end
