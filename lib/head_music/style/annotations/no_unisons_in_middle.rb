module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::NoUnisonsInMiddle < HeadMusic::Style::Annotation
  MESSAGE = "Unisons may only be used in the first and last note."

  def marks
    unison_pairs.map do |notes|
      HeadMusic::Style::Mark.for_all(notes)
    end.flatten
  end

  private

  def unison_pairs
    middle_unisons.map(&:notes).reject(&:nil?)
  end

  def middle_unisons
    middle_intervals.select { |interval| interval.perfect_consonance? && interval.unison? }
  end

  def middle_intervals
    [harmonic_intervals[1..-2]].flatten.reject(&:nil?)
  end

  def harmonic_intervals
    cantus_firmus.notes.map do |cantus_firmus_note|
      counterpoint_notes = voice.notes_during(cantus_firmus_note)
      counterpoint_notes.map { |note|
        HarmonicInterval.new(cantus_firmus_note.voice, voice, note.position)
      }
    end.flatten
  end

  def positions
    voices.map(:notes).flatten.map(&:position).sort.uniq
  end
end
