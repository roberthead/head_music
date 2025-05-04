class HeadMusic::Analysis::DiatonicInterval::Parser
  NUMBER_NAMES = HeadMusic::Analysis::DiatonicInterval::NUMBER_NAMES

  attr_reader :identifier

  def initialize(identifier)
    @identifier = expand(identifier)
  end

  def words
    identifier.to_s.split(/[_ ]+/)
  end

  def quality_name
    words[0..-2].join(" ").to_sym
  end

  def degree_name
    words.last
  end

  def steps
    NUMBER_NAMES.index(degree_name)
  end

  def higher_letter
    HeadMusic::Rudiment::Pitch.middle_c.letter_name.steps_up(steps)
  end

  def expand(identifier)
    if /[A-Z]\d{1,2}/i.match?(identifier)
      number = NUMBER_NAMES[identifier.gsub(/[A-Z]/i, "").to_i - 1]
      return [quality_for(identifier[0]), number].join("_").to_sym
    end
    identifier
  end

  def quality_abbreviations
    HeadMusic::Analysis::DiatonicInterval::QUALITY_ABBREVIATIONS
  end

  def quality_for(abbreviation)
    quality_abbreviations[abbreviation.to_sym] ||
      quality_abbreviations[abbreviation.upcase.to_sym] ||
      quality_abbreviations[abbreviation.downcase.to_sym]
  end
end
