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
    @cantus_firmus_positions ||= Set.new(cantus_firmus.notes.map { |n| n.position.to_s })
  end

  def dissonant_with_cantus?(note)
    interval = HeadMusic::Analysis::HarmonicInterval.new(cantus_firmus, voice, note.position)
    interval.notes.length == 2 && interval.dissonance?(:two_part_harmony)
  end

  def passing_tone?(note)
    prev = preceding_note(note)
    foll = following_note(note)
    return false unless prev && foll

    approach = melodic_interval_between(prev, note)
    departure = melodic_interval_between(note, foll)

    approach.step? && departure.step? && approach.direction == departure.direction
  end

  def melodic_interval_between(note1, note2)
    HeadMusic::Analysis::MelodicInterval.new(note1, note2)
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
