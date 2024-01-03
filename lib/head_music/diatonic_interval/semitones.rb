# Accepts a name and a quality and returns the number of semitones
class HeadMusic::DiatonicInterval::Semitones
  QUALITY_SEMITONES = HeadMusic::DiatonicInterval::QUALITY_SEMITONES

  attr_reader :count

  def initialize(name, quality_name)
    @count = self.class.degree_quality_semitones.dig(name, quality_name)
  end

  def self.degree_quality_semitones
    @degree_quality_semitones ||= {}.tap do |degree_quality_semitones|
      QUALITY_SEMITONES.each do |degree_name, qualities|
        default_quality = qualities.keys.first
        default_semitones = qualities[default_quality]
        degree_quality_semitones[degree_name] = _semitones_for_degree(default_quality, default_semitones)
      end
    end
  end

  def self._semitones_for_degree(quality, default_semitones)
    {}.tap do |semitones|
      _degree_quality_modifications(quality).each do |current_quality, delta|
        semitones[current_quality] = default_semitones + delta
      end
    end
  end

  def self._degree_quality_modifications(quality)
    if quality == :perfect
      HeadMusic::Quality::PERFECT_INTERVAL_MODIFICATION.invert
    else
      HeadMusic::Quality::MAJOR_INTERVAL_MODIFICATION.invert
    end
  end
end
