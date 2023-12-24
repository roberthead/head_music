# A module for style analysis and guidelines.
module HeadMusic::Style; end

# An analysis of music according to a style guide.
class HeadMusic::Style::Analysis
  attr_reader :guide, :voice

  def initialize(guide, voice)
    @guide = guide
    @voice = voice
  end

  def messages
    annotations.reject(&:adherent?).map(&:message)
  end
  alias_method :annotation_messages, :messages

  def annotations
    @annotations ||= @guide.analyze(voice)
  end

  def fitness
    return 1.0 if annotations.empty?

    @fitness ||= fitness_scores.inject(:+).to_f / fitness_scores.length
  end

  def adherent?
    fitness == 1
  end

  private

  def fitness_scores
    @fitness_scores ||= annotations.map(&:fitness)
  end
end
