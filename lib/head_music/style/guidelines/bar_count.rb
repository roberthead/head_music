# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Holds a passage to a number of bars, counted from the first entry of either
# voice to the last note of either, so a staggered entry is no missing bar.
# Configure with an Integer for an exact count or any Range, e.g.
# BarCount.with(8), BarCount.with(8..12), BarCount.with(8..),
# BarCount.with(..12).
#
# A short passage marks every note, with fitness actual / minimum, as
# MinimumNotes does. A long one marks the graded voice's notes in the bars
# past the limit, scored by their share of the notes, as MaximumNotes does.
class HeadMusic::Style::Guidelines::BarCount < HeadMusic::Style::Guideline
  def self.with(bars, **options)
    super(bars: range_for(bars), **options)
  end

  def self.range_for(bars)
    range = bars.is_a?(Integer) ? (bars..bars) : bars
    raise ArgumentError, "BarCount takes an Integer or a Range of bars, not #{bars.inspect}" unless range.is_a?(Range)

    range
  end

  def self.limits(range)
    maximum = range.end && (range.exclude_end? ? range.end - 1 : range.end)
    [range.begin, maximum]
  end

  def self.form(config)
    minimum, maximum = limits(config.fetch(:bars))
    if minimum == maximum then :exact
    elsif maximum.nil? then :at_least
    elsif minimum.nil? then :at_most
    else :between
    end
  end

  def self.violation_key(config = {})
    "guidelines.#{template_key}.violations.#{form(config)}"
  end

  def self.render_instruction(config)
    render_template("guidelines.#{template_key}.instruction.#{form(config)}", config)
  end

  def self.template_values(config)
    minimum, maximum = limits(config.fetch(:bars))
    case form(config)
    when :exact, :at_least then count_values(minimum)
    when :at_most then count_values(maximum)
    else {minimum: HeadMusic::Style::Template.number_word(minimum), maximum: HeadMusic::Style::Template.number_word(maximum)}
    end
  end

  def marks
    return [] if notes.empty?
    return short_mark if minimum && bar_count < minimum

    HeadMusic::Style::Mark.for_each(notes_past_limit) if maximum && bar_count > maximum
  end

  protected

  def fitness_denominator
    (minimum && bar_count < minimum) ? 1 : notes.length
  end

  private

  def minimum
    self.class.limits(options.fetch(:bars)).first
  end

  def maximum
    self.class.limits(options.fetch(:bars)).last
  end

  def short_mark
    HeadMusic::Style::Mark.for_all(notes, fitness: bar_count.to_f / minimum)
  end

  def notes_past_limit
    last_allowed_bar = first_bar + maximum - 1
    notes.select { |note| note.position.bar_number > last_allowed_bar }
  end

  def bar_count
    @bar_count ||= last_bar - first_bar + 1
  end

  def sounding_notes
    @sounding_notes ||= voices.flat_map(&:notes)
  end

  def first_bar
    sounding_notes.map { |note| note.position.bar_number }.min
  end

  def last_bar
    sounding_notes.map { |note| note.position.bar_number }.max
  end
end
