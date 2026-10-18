class HeadMusic::Rudiment::RhythmicValue
  # Reads a rhythmic value from its name: links tied with "tied to", a
  # leading tuplet ratio word on each link, and the plain or dotted name the
  # Parser reads, with the older underscored word form as a fallback.
  class NameReader
    def self.read(name)
      # Handle tied values first, so "half tied to eighth" round-trips through #to_s
      from_tied_words(name) || from_tuplet_words(name) || from_plain_name(name)
    end

    # Splits on the first " tied to " and recurses on the remainder,
    # so chained ties ("half tied to eighth tied to sixteenth") nest naturally.
    def self.from_tied_words(identifier)
      head, tail = identifier.split(/\s+tied\s+to\s+/, 2)
      return nil unless tail

      head_value = HeadMusic::Rudiment::RhythmicValue.get(head)
      tied_value = HeadMusic::Rudiment::RhythmicValue.get(tail)
      return nil unless head_value && tied_value && !head_value.tied_value

      HeadMusic::Rudiment::RhythmicValue.new(head_value.unit, dots: head_value.dots, tied_value: tied_value, tuplet: head_value.tuplet_ratio)
    end

    # Strips a leading ratio word before the other parsers see it, since they
    # match a unit anywhere and would read "triplet" as triple-dotted.
    def self.from_tuplet_words(name)
      match = name.match(TUPLET_PREFIX)
      return unless match

      ratio = ratio_from_word(match[1])
      value = ratio && from_plain_name(match[2].strip)
      value.with_tuplet(ratio) if value&.unit && !value.tuplet?
    end

    def self.ratio_from_word(word)
      HeadMusic::Rudiment::TupletRatio.get(word)
    rescue ArgumentError
      nil
    end

    def self.from_plain_name(name)
      return if name.match?(TUPLET_PREFIX) || name.match?(TUPLET_WORD)

      Parser.parse(name) || from_snake_case_words(name)
    end

    def self.from_snake_case_words(name)
      from_words(HeadMusic::Utilities::Case.to_snake_case(name))
    rescue
      nil
    end

    def self.from_words(identifier)
      HeadMusic::Rudiment::RhythmicValue.new(unit_from_words(identifier), dots: dots_from_words(identifier))
    end

    def self.unit_from_words(identifier)
      identifier.gsub(/^\w*dotted_/, "")
    end

    def self.dots_from_words(identifier)
      return 0 unless identifier.match?(/dotted/)

      modifier, = identifier.split(/_*dotted_*/)
      case modifier
      when /tripl\w/
        3
      when /doubl\w/
        2
      else
        1
      end
    end

    private_class_method :from_tuplet_words, :ratio_from_word, :from_plain_name, :from_snake_case_words
  end
end
