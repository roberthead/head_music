module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::StepUpToFinalNote < HeadMusic::Style::Annotation
  MESSAGE = 'Step up to final note.'

  def marks
    if !last_melodic_interval.nil?
      fitness = 1
      fitness *= HeadMusic::PENALTY_FACTOR unless step?
      fitness *= HeadMusic::PENALTY_FACTOR unless ascending?
      if fitness < 1
        HeadMusic::Style::Mark.for_all(notes[-2..-1], fitness: fitness)
      end
    end
  end

  private

  def ascending?
    last_melodic_interval && last_melodic_interval.ascending?
  end

  def step?
    last_melodic_interval && last_melodic_interval.step?
  end

  def last_melodic_interval
    @last_melodic_interval ||= melodic_intervals.last
  end
end
