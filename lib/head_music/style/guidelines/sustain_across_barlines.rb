# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# The syncopated texture of fourth species: the note sounding at a downbeat
# began before it. Judged over the voice's own bars rather than the cantus
# firmus's, so a solo line is held to it too. Notation-agnostic, so a whole
# note on beat three and a half tied to a half count the same.
class HeadMusic::Style::Guidelines::SustainAcrossBarlines < HeadMusic::Style::Guideline
  include HeadMusic::Style::Guideline::BarSpan

  MAX_BREAK_RATIO = 0.25

  def marks
    return [] if notes.empty?
    return [] if breaks.length <= allowed_breaks

    breaks.map { |bar_number| mark_bar(bar_number) }
  end

  private

  def max_break_ratio
    options.fetch(:max_break_ratio) { self.class::MAX_BREAK_RATIO }
  end

  # Fux allows the ligature to be dropped where none will fit, so a few breaks
  # are free. Past that, every break is marked rather than only the ones past
  # the allowance, so which bars a student sees flagged does not depend on
  # where the free ones happened to fall.
  def breaks
    @breaks ||= middle_bar_numbers.reject { |bar_number| sustained_into?(bar_number) }
  end

  def allowed_breaks
    (middle_bar_numbers.length * max_break_ratio).floor
  end

  def sustained_into?(bar_number)
    downbeat = downbeat_of(bar_number)
    held = voice.note_at(downbeat)
    !held.nil? && held.position < downbeat
  end
end
