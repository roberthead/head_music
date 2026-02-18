# Module for guides
module HeadMusic::Style::Guides; end

# Base class for species melody guides providing shared analysis behavior
class HeadMusic::Style::Guides::SpeciesMelody
  def self.analyze(voice)
    self::RULESET.map { |rule| rule.new(voice) }
  end
end
