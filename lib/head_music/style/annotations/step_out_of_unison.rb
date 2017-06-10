module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::StepOutOfUnison < HeadMusic::Style::Annotation
  MESSAGE = "Exit a unison by step."

  def marks
    skips_following_unisons.map do |skip|
      HeadMusic::Style::Mark.for_all(skip.notes)
    end.flatten
  end

  private

  def skips_following_unisons
    melodic_intervals_following_unisons.select(&:skip?)
  end

  def melodic_intervals_following_unisons
    unisons.map do |unison|
      note1 = voice.note_at(unison.position)
      note2 = voice.note_following(unison.position)
      MelodicInterval.new(voice, note1, note2) if note2
    end.reject(&:nil?)
  end

  def unisons
    harmonic_intervals.select { |interval| interval.perfect_consonance? && interval.unison? }
  end

  def harmonic_intervals
    positions.map { |position| HarmonicInterval.new(cantus_firmus, voice, position) }
  end

  def positions
    voices.map(&:notes).flatten.map(&:position).sort.uniq(&:to_s)
  end
end
