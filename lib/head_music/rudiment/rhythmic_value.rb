# A module for musical content
module HeadMusic::Rudiment; end

# A rhythmic value is a duration composed of a rhythmic unit, any number of dots, and a tied value.
class HeadMusic::Rudiment::RhythmicValue
  include Comparable

  RhythmicUnit = HeadMusic::Rudiment::RhythmicUnit

  attr_reader :unit, :dots, :tied_value

  delegate :name, to: :unit, prefix: true
  delegate :to_s, to: :name

  def self.get(identifier)
    case identifier
    when HeadMusic::Rudiment::RhythmicValue
      identifier
    when HeadMusic::Rudiment::RhythmicUnit
      new(identifier)
    when Symbol, String
      original_identifier = identifier.to_s.strip
      # Handle tied values first, so "half tied to eighth" round-trips through #to_s
      tied = from_tied_words(original_identifier)
      return tied if tied

      # Then try the new parser which handles all formats
      parsed = Parser.parse(original_identifier)
      return parsed if parsed

      # Then try the word-based approach as fallback
      identifier = HeadMusic::Utilities::Case.to_snake_case(original_identifier)
      begin
        from_words(identifier)
      rescue
        nil
      end
    end
  end

  # Splits on the first " tied to " and recurses on the remainder,
  # so chained ties ("half tied to eighth tied to sixteenth") nest naturally.
  def self.from_tied_words(identifier)
    head, tail = identifier.split(/\s+tied\s+to\s+/, 2)
    return nil unless tail

    head_value = get(head)
    tied_value = get(tail)
    return nil unless head_value && tied_value

    new(head_value.unit, dots: head_value.dots, tied_value: tied_value)
  end

  def self.from_words(identifier)
    new(unit_from_words(identifier), dots: dots_from_words(identifier))
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

  def initialize(unit, dots: nil, tied_value: nil)
    @unit = HeadMusic::Rudiment::RhythmicUnit.get(unit)
    @dots = [0, 1, 2, 3].include?(dots) ? dots : 0
    @tied_value = tied_value
  end

  def unit_value
    unit.relative_value
  end

  def relative_value
    unit_value * multiplier
  end

  def total_value
    relative_value + (tied_value ? tied_value.total_value : 0)
  end

  def multiplier
    (0..dots).reduce(0) { |sum, i| sum + 0.5**i }
  end

  def ticks
    HeadMusic::Rudiment::Rhythm::PPQN * 4 * total_value
  end

  def per_whole
    1.0 / relative_value
  end

  def name_modifier_prefix
    case dots
    when 1
      "dotted"
    when 2
      "double-dotted"
    when 3
      "triple-dotted"
    end
  end

  def single_value_name
    [name_modifier_prefix, unit_name].compact.join(" ")
  end

  def name
    if tied_value
      [single_value_name, tied_value.name].compact.join(" tied to ")
    else
      single_value_name
    end
  end

  def ==(other)
    to_s == other.to_s
  end

  def to_s
    name.tr("_", "-")
  end

  def <=>(other)
    total_value <=> other.total_value
  end
end
