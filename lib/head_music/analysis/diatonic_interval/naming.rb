# Accepts a number and number of semitones and privides the naming methods.
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
    starting_quality = QUALITY_SEMITONES[simple_number_name.to_sym].keys.first
    delta = simple_semitones - (QUALITY_SEMITONES[simple_number_name.to_sym][starting_quality] % 12)
    delta -= 12 while delta >= 6
    HeadMusic::Rudiment::Quality.from(starting_quality, delta)
  end

  def simple_number_name
    NUMBER_NAMES[simple_number - 1]
  end

  def number_name
    NUMBER_NAMES[number - 1] || (number.to_s + NAME_SUFFIXES[number % 10])
  end

  def name
    if named_number?
      [quality_name, number_name].join(" ")
    elsif simple_name == "perfect octave"
      "#{octaves.humanize} octaves"
    else
      "#{octaves.humanize} octaves and #{quality.article} #{simple_name}"
    end
  end

  def shorthand
    step_shorthand = (number == 1) ? "U" : number
    [quality.shorthand, step_shorthand].join
  end

  private

  def simple_semitones
    @simple_semitones ||= semitones % 12
  end

  def named_number?
    number < NUMBER_NAMES.length
  end

  def quality
    @quality ||= HeadMusic::Rudiment::Quality.get(quality_name)
  end

  def octaves
    @octaves ||= semitones / 12
  end

  def octave_equivalent?
    number > 1 && ((number - 1) % 7).zero?
  end
end
