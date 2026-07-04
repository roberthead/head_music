# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A configurable guideline for the treatment of large melodic leaps.
#
# Options:
# - minimum: the smallest interval (compared by diatonic number) treated as a large leap
# - ascending/descending: per-direction override; an interval shorthand or {minimum:, forbidden:}
# - recovery: symbols naming the acceptable recovery gestures
# - maximum_consecutive_leaps: cap on a run of consecutive qualifying leaps
# - message: the annotation message
class HeadMusic::Style::Guidelines::LargeLeaps < HeadMusic::Style::Annotation
  DEFAULTS = {
    minimum: :perfect_fourth,
    ascending: nil,
    descending: nil,
    recovery: %i[consonant_triad any_step repetition opposite_leap_within],
    maximum_consecutive_leaps: nil,
    message: "Recover leaps by step, repetition, opposite direction, or spelling triad."
  }.freeze

  def message
    config.fetch(:message)
  end

  def marks
    @marks ||= recovery_marks + consecutive_leap_marks
  end

  private

  def config
    @config ||= DEFAULTS.merge(options)
  end

  def recovery_marks
    melodic_note_pairs.each_cons(3).map do |first, second, third|
      if unrecovered_leap?(first, second, third)
        HeadMusic::Style::Mark.for_all((first.notes + second.notes).uniq)
      end
    end.compact
  end

  def consecutive_leap_marks
    return [] if maximum_consecutive_leaps.nil?

    melodic_note_pairs.chunk { |pair| qualifies?(pair) }
      .select { |qualifying, _run| qualifying }
      .map { |_qualifying, run| run }
      .select { |run| run.length > maximum_consecutive_leaps }
      .map { |run| HeadMusic::Style::Mark.for_all(run.flat_map(&:notes).uniq) }
  end

  def maximum_consecutive_leaps
    config.fetch(:maximum_consecutive_leaps)
  end

  def unrecovered_leap?(first, second, third)
    return false unless qualifies?(first)
    return true if forbidden?(first)

    !recovered?(first, second, third)
  end

  def qualifies?(pair)
    pair.melodic_interval.number >= minimum_number_for(direction_of(pair))
  end

  def forbidden?(pair)
    ceiling = forbidden_number_for(direction_of(pair))
    !ceiling.nil? && pair.melodic_interval.number >= ceiling
  end

  def recovered?(first, second, third)
    recovery_modes.any? { |mode| send(:"recovered_by_#{mode}?", first, second, third) }
  end

  def recovery_modes
    config.fetch(:recovery)
  end

  def recovered_by_consonant_triad?(first, second, third)
    first.spells_consonant_triad_with?(second) || second.spells_consonant_triad_with?(third)
  end

  def recovered_by_opposite_step?(first, second, _third)
    direction_changed?(first, second) && second.step?
  end

  def recovered_by_any_step?(_first, second, _third)
    second.step?
  end

  def recovered_by_repetition?(_first, second, _third)
    second.repetition?
  end

  def recovered_by_opposite_leap?(first, second, _third)
    direction_changed?(first, second) && second.leap?
  end

  def recovered_by_opposite_leap_within?(first, second, third)
    recovered_by_opposite_leap?(first, second, third) &&
      second.melodic_interval.number <= first.melodic_interval.number
  end

  def direction_changed?(first, second)
    first.ascending? && second.descending? ||
      first.descending? && second.ascending?
  end

  def direction_of(pair)
    return :ascending if pair.ascending?
    return :descending if pair.descending?

    :none
  end

  def minimum_number_for(direction)
    minimum_numbers[direction] ||=
      interval_number(direction_settings(direction)[:minimum] || config.fetch(:minimum))
  end

  def forbidden_number_for(direction)
    return forbidden_numbers[direction] if forbidden_numbers.key?(direction)

    forbidden = direction_settings(direction)[:forbidden]
    forbidden_numbers[direction] = forbidden && interval_number(forbidden)
  end

  def minimum_numbers
    @minimum_numbers ||= {}
  end

  def forbidden_numbers
    @forbidden_numbers ||= {}
  end

  def direction_settings(direction)
    setting = config[direction]
    return {} if setting.nil?

    setting.is_a?(Hash) ? setting : {minimum: setting}
  end

  def interval_number(value)
    HeadMusic::Analysis::DiatonicInterval.get(value).number
  end
end
