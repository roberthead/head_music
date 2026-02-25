# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline for fourth species counterpoint.
# The syncopated texture is occasionally broken: the counterpoint moves on the
# downbeat instead of sustaining. When this happens, a dissonant off-beat note
# is permitted only if it is a passing tone. Breaks should be infrequent.
class HeadMusic::Style::Guidelines::SecondSpeciesBreak < HeadMusic::Style::Annotation
  MESSAGE = "Use only passing tones when breaking the syncopated texture. Breaks should be infrequent."

  MAX_BREAK_RATIO = 0.25

  def marks
    return [] unless cantus_firmus&.notes&.any?

    dissonance_marks + frequency_marks
  end

  private

  def dissonance_marks
    break_bar_off_beat_notes
      .select { |note| dissonant_with_cantus?(note) }
      .reject { |note| passing_tone?(note) }
      .map { |note| HeadMusic::Style::Mark.for(note) }
  end

  def frequency_marks
    return [] if total_bars <= 0
    return [] if break_bars.length <= total_bars * MAX_BREAK_RATIO

    break_bar_notes = break_bars.flat_map { |bar| notes_in_bar(bar) }
    [HeadMusic::Style::Mark.for_all(break_bar_notes, fitness: HeadMusic::SMALL_PENALTY_FACTOR)]
  end

  def break_bars
    @break_bars ||= (first_bar..last_bar).select { |bar| break_bar?(bar) }
  end

  def break_bar?(bar)
    bar_notes = notes_in_bar(bar)
    has_downbeat = bar_notes.any? { |note| downbeat_position?(note.position) }
    has_off_beat = bar_notes.any? { |note| !downbeat_position?(note.position) }
    has_downbeat && has_off_beat
  end

  def break_bar_off_beat_notes
    break_bars.flat_map { |bar| notes_in_bar(bar).reject { |note| downbeat_position?(note.position) } }
  end

  def notes_in_bar(bar)
    notes.select { |note| note.position.bar_number == bar }
  end

  def total_bars
    last_bar - first_bar + 1
  end

  def first_bar
    cantus_firmus.notes.first.position.bar_number
  end

  def last_bar
    cantus_firmus.notes.last.position.bar_number
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
