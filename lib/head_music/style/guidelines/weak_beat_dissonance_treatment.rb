# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::WeakBeatDissonanceTreatment < HeadMusic::Style::Annotation
  MESSAGE = "Use only passing tones for dissonances on the weak beat."

  def marks
    return [] unless cantus_firmus&.notes&.any?

    dissonant_weak_beat_notes.reject { |note| recognized_figure?(note) }.map do |note|
      HeadMusic::Style::Mark.for(note)
    end
  end

  private

  def recognized_figure?(note)
    passing_tone?(note)
  end

  def dissonant_weak_beat_notes
    weak_beat_notes.select { |note| dissonant_with_cantus?(note) }
  end

  def weak_beat_notes
    notes.reject { |note| downbeat_position?(note.position) }
  end

  def downbeat_position?(position)
    cantus_firmus_positions.include?(position.to_s)
  end

  def cantus_firmus_positions
    @cantus_firmus_positions ||= Set.new(cantus_firmus.notes.map { |note| note.position.to_s })
  end

  def dissonant_with_cantus?(note)
    interval = HeadMusic::Analysis::HarmonicInterval.new(cantus_firmus, voice, note.position)
    interval.notes.length == 2 && interval.dissonance?(:two_part_harmony)
  end

  def passing_tone?(note)
    stepwise_figure?(note, same_direction: true)
  end

  def stepwise_figure?(note, same_direction:)
    surrounding = surrounding_notes(note)
    return false unless surrounding

    approach = melodic_interval_between(surrounding.first, note)
    departure = melodic_interval_between(note, surrounding.last)
    approach.step? && departure.step? && (approach.direction == departure.direction) == same_direction
  end

  def surrounding_notes(note)
    prev = preceding_note(note)
    foll = following_note(note)
    [prev, foll] if prev && foll
  end

  def melodic_interval_between(first_note, second_note)
    HeadMusic::Analysis::MelodicInterval.new(first_note, second_note)
  end

  def preceding_note(note)
    index = notes.index(note)
    notes[index - 1] if index && index > 0
  end

  def following_note(note)
    index = notes.index(note)
    notes[index + 1] if index && index < notes.length - 1
  end
end
