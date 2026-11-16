# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline. With `restruck_suspensions: true`, a note may be
# struck again as a suspension: on a stronger beat, dissonant with the other
# voice.
class HeadMusic::Style::Guidelines::AlwaysMove < HeadMusic::Style::Guideline
  include HeadMusic::Style::Guideline::BarSpan
  include HeadMusic::Style::Guideline::RestruckSuspensions

  def marks
    melodic_note_pairs
      .select { |pair| pair.perfect? && pair.unison? }
      .reject { |pair| anticipated_resolution?(pair) || restruck_suspension?(pair.notes.last) }
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
    return false unless suspension
    return false unless suspension.position < downbeat_of(bar_number) || restruck_suspension?(suspension)

    interval = HeadMusic::Analysis::MelodicInterval.new(suspension, anticipation)
    interval.step? && interval.descending?
  end

  def restruck_suspension?(note)
    return false unless restruck_suspensions? && cantus_firmus && restruck_on_stronger_beat?(note)

    interval = HeadMusic::Analysis::HarmonicInterval.new(cantus_firmus, voice, note.position)
    interval.notes.length == 2 && interval.dissonance?(:two_part_harmony)
  end

  def on_beat?(note, count)
    note.position.count == count && note.position.tick.zero?
  end

  # A tied note is judged by its attack.
  def undotted_quarter?(note)
    attack = note.rhythmic_duration.values.first
    attack.unit_name == "quarter" && attack.dots.zero?
  end
end
