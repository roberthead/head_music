# Module for guides
module HeadMusic::Style::Guides; end

# Base class for style guides. A guide analyzes a voice against its RULESET,
# producing one annotation per rule.
class HeadMusic::Style::Guides::Base
  def self.analyze(voice)
    self::RULESET.map { |rule| rule.new(voice) }
  end
end
