# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Converts a HeadMusic::Rudiment::RhythmicValue into the <duration>,
  # <type>, dot count, and tie flags MusicXML needs for each link of a
  # tied chain. A value with no tied chain yields a single component.
  class DurationWriter
    Component = Struct.new(:duration, :type, :dots, :tie_start, :tie_stop, keyword_init: true)

    # MusicXML's <type> element uses these fixed names rather than the
    # gem's American duration names.
    TYPES_BY_UNIT_NAME = {
      "maxima" => "maxima",
      "longa" => "long",
      "double whole" => "breve",
      "whole" => "whole",
      "half" => "half",
      "quarter" => "quarter",
      "eighth" => "eighth",
      "sixteenth" => "16th",
      "thirty-second" => "32nd",
      "sixty-fourth" => "64th",
      "hundred twenty-eighth" => "128th",
      "two hundred fifty-sixth" => "256th"
    }.freeze

    attr_reader :divisions

    def initialize(divisions)
      @divisions = divisions
    end

    # A rhythmic value's own duration in quarter notes, ignoring any tied
    # chain. Four quarter notes span a whole note, so the value's fraction
    # of its own unit is scaled by four.
    def self.single_quarter_fraction(rhythmic_value)
      HeadMusic::Notation::DottedDuration.dotted_unit_fraction(rhythmic_value) * 4
    end

    def components(rhythmic_value)
      links = chain(rhythmic_value)
      links.each_with_index.map { |link, index| build_component(link, index, links.length) }
    end

    private

    def chain(rhythmic_value)
      links = [rhythmic_value]
      links << links.last.tied_value while links.last.tied_value
      links
    end

    def build_component(link, index, length)
      Component.new(
        duration: integer_duration(link),
        type: type_for(link),
        dots: link.dots,
        tie_start: index != length - 1,
        tie_stop: index != 0
      )
    end

    def integer_duration(link)
      fraction = self.class.single_quarter_fraction(link) * divisions
      unless fraction.denominator == 1
        raise HeadMusic::Notation::MusicXML::RenderError,
          "cannot express #{link} as an integer duration at #{divisions} divisions per quarter note"
      end
      fraction.numerator
    end

    def type_for(link)
      TYPES_BY_UNIT_NAME.fetch(link.unit_name) do
        raise HeadMusic::Notation::MusicXML::RenderError, "no MusicXML note type is known for #{link.unit_name}"
      end
    end
  end
end
