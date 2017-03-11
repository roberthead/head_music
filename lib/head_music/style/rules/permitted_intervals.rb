module HeadMusic::Style::Rules
end

class HeadMusic::Style::Rules::PermittedIntervals < HeadMusic::Style::Rule
  PERMITTED_ASCENDING = %w[m2 M2 m3 M3 P4 P5 m6 P8]
  PERMITTED_DESCENDING = %w[m2 M2 m3 M3 P4 P5 P8]

  def self.analyze(voice)
    marks = marks(voice)
    fitness = PENALTY_FACTOR**marks.count
    if fitness < 1
      message = "Use only m2, M2, m3, M3, P4, P5, m6 (ascending only), P8."
    end
    HeadMusic::Style::Annotation.new(subject: voice, fitness: fitness, marks: marks, message: message)
  end

  def self.marks(voice)
    voice.melodic_intervals.reject { |interval| permitted?(interval) }.map do |unpermitted_interval|
      HeadMusic::Style::Mark.for_all([unpermitted_interval.first_note, unpermitted_interval.second_note])
    end
  end

  def self.permitted?(melodic_interval)
    whitelist_for_interval(melodic_interval).include?(melodic_interval.shorthand)
  end

  def self.whitelist_for_interval(melodic_interval)
    melodic_interval.ascending? ? PERMITTED_ASCENDING : PERMITTED_DESCENDING
  end
end
