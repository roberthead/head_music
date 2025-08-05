module HeadMusic::Parsable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def matcher
      self::MATCHER
    end

    def parse(input)
      return input if input.is_a?(self)

      parse_pitched_item(input) || parse_string(input) || parse_other(input)
    end

    def from_pitched_item(input)
      from_note(input) ||
        from_pitch(input) ||
        from_pitch_class(input) ||
        from_spelling(input) ||
        from_letter_name(input)
    end

    def from_note(input)
      nil
    end

    def from_pitch(input)
      nil
    end

    def from_pitch_class(input)
      nil
    end

    def from_spelling(input)
      nil
    end

    def from_letter_name(input)
      nil
    end

    def parse_string(string)
      return nil unless string.to_s.match?(matcher)

      from_string(string)
    end

    def from_string(string)
      nil
    end

    def parse_other(input)
      nil
    end
  end
end
