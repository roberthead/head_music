# frozen_string_literal: true

# A module for style analysis and rules.
module HeadMusic::Style; end

# An analysis of music according to a ruleset.
class HeadMusic::Style::Analysis
  attr_reader :ruleset, :subject, :annotations

  def initialize(ruleset, subject)
    @ruleset = ruleset
    @subject = subject
  end

  def messages
    annotations.reject(&:adherent?).map(&:message)
  end
  alias annotation_messages messages

  def annotations
    @annotations ||= @ruleset.analyze(subject)
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
