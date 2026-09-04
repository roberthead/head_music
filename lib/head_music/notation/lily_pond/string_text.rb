# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # Escapes text for a double-quoted LilyPond string, and reads it back.
  # LilyPond embeds executable Scheme, so an unescaped quote in a header
  # field could break out of the string into code that runs at compile
  # time; the backslash must double first so it cannot re-open what the
  # quote escape closed.
  module StringText
    def self.escape(text)
      text.to_s.gsub("\\", "\\\\\\\\").gsub('"', "\\\"")
    end

    # The inverse of escape: the text a double-quoted string's body denotes.
    def self.unescape(text)
      text.to_s.gsub(/\\(["\\])/, '\1')
    end
  end
end
