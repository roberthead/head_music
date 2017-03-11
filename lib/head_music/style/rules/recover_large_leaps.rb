module HeadMusic::Style::Rules
end

# Ok, so a rule might be that after the first leap (after previous steps)
# one should normally move by step in the opposite direction
# unless another leap (in either direction) creates a consonant triad.
# - Brian
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
        unless spelling_consonant_triad?(previous_interval, interval)
          fitness *= HeadMusic::PENALTY_FACTOR unless direction_changed?(previous_interval, interval)
          fitness *= HeadMusic::SMALL_PENALTY_FACTOR unless interval.step?
          unless direction_changed?(previous_interval, interval) && interval.step?
            marks << HeadMusic::Style::Mark.for_all((previous_interval.notes + interval.notes).uniq)
          end
        end
      end
    end
    [marks, fitness]
  end

  def self.direction_changed?(first_interval, second_interval)
    first_interval.ascending? && second_interval.descending? ||
      first_interval.descending? && second_interval.ascending?
  end

  def self.spelling_consonant_triad?(first_interval, second_interval)
    return false if first_interval.step? || second_interval.step?
    pitches = (first_interval.pitches + second_interval.pitches).uniq
    return false if pitches.length < 3
    HeadMusic::Chord.new(pitches).consonant_triad?
  end
end
