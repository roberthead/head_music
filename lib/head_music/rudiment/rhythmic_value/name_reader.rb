class HeadMusic::Rudiment::RhythmicValue
  # Reads a rhythmic value from its name: a leading tuplet ratio word, and
  # the plain or dotted name the Parser reads, with the older underscored
  # word form as a fallback. A tied name is a RhythmicDuration's, so it reads
  # as nil, as any name it cannot read does.
  class NameReader
    def self.read(name)
      return if name.match?(TIE)

      from_tuplet_words(name) || from_plain_name(name)
    end

    # Strips a leading ratio word before the other parsers see it, since they
    # match a unit anywhere and would read "triplet" as triple-dotted.
    def self.from_tuplet_words(name)
      match = name.match(TUPLET_PREFIX)
      return unless match

      ratio = ratio_from_word(match[1])
      value = ratio && from_plain_name(match[2].strip)
      value.with_tuplet(ratio) if value && !value.tuplet?
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
      unit = HeadMusic::Rudiment::RhythmicUnit.get(unit_from_words(identifier))
      HeadMusic::Rudiment::RhythmicValue.new(unit, dots: dots_from_words(identifier)) if unit
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
