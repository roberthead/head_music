# Motion defines the relative pitch direction of the upper and lower voices of subsequence intervals.
class HeadMusic::Motion
  attr_reader :first_harmonic_interval, :second_harmonic_interval

  def initialize(first_harmonic_interval, second_harmonic_interval)
    @first_harmonic_interval = first_harmonic_interval
    @second_harmonic_interval = second_harmonic_interval
  end

  def repetition?
    upper_melodic_interval.repetition? && lower_melodic_interval.repetition?
  end

  def oblique?
    upper_melodic_interval.repetition? && lower_melodic_interval.moving? ||
      lower_melodic_interval.repetition? && upper_melodic_interval.moving?
  end

  def direct?
    parallel? || similar?
  end

  def parallel?
    upper_melodic_interval.moving? &&
      upper_melodic_interval.direction == lower_melodic_interval.direction &&
      upper_melodic_interval.steps == lower_melodic_interval.steps
  end

  def similar?
    upper_melodic_interval.direction == lower_melodic_interval.direction &&
      upper_melodic_interval.steps != lower_melodic_interval.steps
  end

  def contrary?
    upper_melodic_interval.moving? &&
      lower_melodic_interval.moving? &&
      upper_melodic_interval.direction != lower_melodic_interval.direction
  end

  def notes
    upper_notes + lower_notes
  end

  def contrapuntal_motion
    %i[parallel similar oblique contrary repetition].detect do |motion_type|
      send("#{motion_type}?")
    end
  end

  def to_s
    return "repetition of a #{second_harmonic_interval}" unless contrapuntal_motion != :repetition

    "#{contrapuntal_motion} motion from a #{first_harmonic_interval} to a #{second_harmonic_interval}"
  end

  private

  def upper_melodic_interval
    HeadMusic::MelodicInterval.new(upper_notes.first, upper_notes.last)
  end

  def lower_melodic_interval
    HeadMusic::MelodicInterval.new(lower_notes.first, lower_notes.last)
  end

  def upper_notes
    [first_harmonic_interval, second_harmonic_interval].map(&:upper_note)
  end

  def lower_notes
    [first_harmonic_interval, second_harmonic_interval].map(&:lower_note)
  end
end
