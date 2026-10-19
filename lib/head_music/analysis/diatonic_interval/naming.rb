# Accepts a number and number of semitones and provides the naming methods.
class HeadMusic::Analysis::DiatonicInterval::Naming
  QUALITY_SEMITONES = HeadMusic::Analysis::DiatonicInterval::QUALITY_SEMITONES
  NUMBER_NAMES = HeadMusic::Analysis::DiatonicInterval::NUMBER_NAMES
  NAME_SUFFIXES = HeadMusic::Analysis::DiatonicInterval::NAME_SUFFIXES

  attr_reader :number, :semitones

  def initialize(number:, semitones:)
    @number = number
    @semitones = semitones
  end

  def simple_number
    @simple_number ||= octave_equivalent? ? 8 : (number - 1) % 7 + 1
  end

  def simple_name
    [quality_name, simple_number_name].join(" ")
  end

  def quality_name
    starting_quality, starting_semitones = QUALITY_SEMITONES[simple_number_name.to_sym].first
    HeadMusic::Rudiment::Quality.from(starting_quality, semitones - starting_semitones - 12 * compound_octaves)
  end

  def simple_number_name
    NUMBER_NAMES[simple_number - 1]
  end

  def number_name
    NUMBER_NAMES[number - 1] || (number.to_s + NAME_SUFFIXES[number % 10])
  end

  # Past the named numbers, an interval is so many octaves and a simple
  # interval. An octave altered upward adds an octave and alters the unison.
  def name
    return [quality_name, number_name].join(" ") if named_number?

    octaves, remainder = octaves_and_remainder
    return "#{octaves.humanize} octaves" unless remainder

    "#{octaves.humanize} octaves and #{remainder.start_with?(/[aeiou]/) ? "an" : "a"} #{remainder}"
  end

  def shorthand
    [quality.shorthand, number].join
  end

  private

  def named_number?
    number <= NUMBER_NAMES.length
  end

  # The octaves added to the simple interval.
  def compound_octaves
    (number - simple_number) / 7
  end

  def quality
    @quality ||= HeadMusic::Rudiment::Quality.get(quality_name)
  end

  def octaves_and_remainder
    return [compound_octaves, simple_name] unless simple_number == 8 && !quality_name.include?("diminished")

    [compound_octaves + 1, ("#{quality_name} unison" unless quality_name == "perfect")]
  end

  def octave_equivalent?
    number > 1 && ((number - 1) % 7).zero?
  end
end
