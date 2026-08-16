# A module for style analysis and guidelines.
module HeadMusic::Style; end

# An analysis of music according to a style guide.
class HeadMusic::Style::Analysis
  attr_reader :guide, :voice

  # Any object answering analyze(voice) is a guide here -- a guide class, a
  # Guides::Configured, or a test double. Checking at construction keeps a
  # missed Guide.get lookup from surfacing as NoMethodError on nil far away.
  def initialize(guide, voice)
    unless guide.respond_to?(:analyze)
      raise ArgumentError, "guide must respond to #analyze (got #{guide.inspect})"
    end

    @guide = guide
    @voice = voice
  end

  def messages
    annotations.reject(&:adherent?).map(&:message)
  end

  def annotations
    @annotations ||= @guide.analyze(voice)
  end

  # The grade: sufficiency gates multiply against a weighted average of the
  # rubric rules, so an insufficient exercise scales the whole grade down
  # while ordinary rules trade off against each other by weight.
  def fitness
    return 1.0 if annotations.empty?

    @fitness ||= gate_factor * rubric_fitness
  end

  def adherent?
    annotations.all?(&:adherent?)
  end

  private

  def gate_factor
    gates.map(&:fitness).reduce(1, :*)
  end

  def rubric_fitness
    rubric = annotations.reject(&:gate?)
    total_weight = rubric.sum(&:weight)
    return 1.0 if rubric.empty? || total_weight.zero?

    rubric.sum { |guideline| guideline.weight * guideline.fitness } / total_weight
  end

  def gates
    annotations.select(&:gate?)
  end
end
