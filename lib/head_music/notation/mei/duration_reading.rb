module HeadMusic::Notation::MEI
  # The rhythmic value of a layer's <note>, <chord>, <rest>, or <space>: its
  # @dur and @dots, else for a chord those its notes all share, else the
  # @dur.default in force. A grace note with none is an eighth; anything
  # else with none raises.
  class DurationReading
    def initialize(editorial, duration_default, **where)
      @editorial = editorial
      @duration_default = duration_default
      @where = where
    end

    # A rest or space with no length of its own and no default to fall back on.
    def open?(element)
      value(element, "dur").nil? && @duration_default.nil?
    end

    def rhythmic_value(element, grace: false, ratio: nil)
      stated = stated_durations(element)
      unit = stated.filter_map(&:first).first || @duration_default
      unit ||= "eighth" if grace
      raise ParseError.new("A <#{element.name}> has no @dur, and no @dur.default is in force", **@where, element: element) unless unit

      HeadMusic::Rudiment::RhythmicValue.new(unit, dots: stated.filter_map(&:last).first || 0, tuplet: ratio)
    end

    private

    def stated_durations(element)
      own = duration(element)
      [own, shared_duration(element, own)].compact
    end

    def duration(element)
      [value(element, "dur"), value(element, "dots")]
    end

    def shared_duration(element, own)
      return unless element.name == "chord" && own.first.nil?

      durations = @editorial.children_named(element, "note").map { |note| duration(note) }.uniq
      durations.first if durations.one? && durations.first.first
    end

    def value(element, name)
      AttributeValues.read(element, name, **@where, element: element)
    end
  end
end
