# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::AlwaysMove < HeadMusic::Style::Guideline
  include HeadMusic::Style::Guideline::BarSpan

  def marks
    melodic_note_pairs
      .select { |pair| pair.perfect? && pair.unison? }
      .reject { |pair| anticipated_resolution?(pair) }
      .map { |pair| HeadMusic::Style::Mark.for_all(pair.notes) }
  end

  private

  # A suspension's resolution struck early as a quarter on beat two and again
  # on beat three, which Salzer and Schachter list among the decorations of
  # the resolution (p. 104).
  def anticipated_resolution?(pair)
    anticipation, resolution = pair.notes
    bar_number = anticipation.position.bar_number
    return false unless on_beat?(anticipation, 2) && on_beat?(resolution, 3)
    return false unless undotted_quarter?(anticipation) && resolution.position.bar_number == bar_number

    suspension = voice.note_at(downbeat_of(bar_number))
    return false unless suspension && suspension.position < downbeat_of(bar_number)

    interval = HeadMusic::Analysis::MelodicInterval.new(suspension, anticipation)
    interval.step? && interval.descending?
  end

  def on_beat?(note, count)
    note.position.count == count && note.position.tick.zero?
  end

  def undotted_quarter?(note)
    note.rhythmic_value.unit_name == "quarter" && note.rhythmic_value.dots.zero?
  end
end
