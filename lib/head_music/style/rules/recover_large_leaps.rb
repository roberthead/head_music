module HeadMusic::Style::Rules
end

class HeadMusic::Style::Rules::RecoverLargeLeaps < HeadMusic::Style::Rule
  def self.analyze(voice)
    marks, fitness = check(voice)
    if fitness < 1
      message = "Recover leaps by step in the opposite direction."
    end
    HeadMusic::Style::Annotation.new(subject: voice, fitness: fitness, marks: marks, message: message)
  end

  def self.check(voice)
    marks = []
    fitness = 1
    voice.melodic_intervals[1..-1].to_a.each.with_index do |interval, i|
      previous_interval = voice.melodic_intervals[i]
      if previous_interval.leap?
        fitness *= HeadMusic::PENALTY_FACTOR unless direction_changed?(previous_interval, interval)
        fitness *= HeadMusic::SMALL_PENALTY_FACTOR unless interval.step?
        unless direction_changed?(previous_interval, interval) && interval.step?
          marks << HeadMusic::Style::Mark.for_all((previous_interval.notes + interval.notes).uniq)
        end
      end
    end
    [marks, fitness]
  end

  def self.direction_changed?(first_interval, second_interval)
    first_interval.ascending? && second_interval.descending? ||
      first_interval.descending? && second_interval.ascending?
  end
end
