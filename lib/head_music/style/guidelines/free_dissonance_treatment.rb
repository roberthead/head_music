# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Dissonance between two composed voices, neither of them a cantus firmus.
# Fifth species' treatment, with either voice able to explain a dissonance.
#
# At each moment the voices form a dissonance:
# - an attacking voice explains it with a figure in its own line, unless the
#   moment is a downbeat, which forbids an attacked dissonance;
# - otherwise a note held into a strong beat from a weaker one, or struck
#   again there, owns it as a suspension, and is marked if not prepared and
#   resolved down by step within two strong beats;
# - otherwise every voice that attacked into it is marked.
#
# A passing or neighbor figure runs from consonance to consonance, so two
# lines stepping in parallel dissonances explain nothing.
class HeadMusic::Style::Guidelines::FreeDissonanceTreatment < HeadMusic::Style::Guideline
  def marks
    return [] unless companion&.notes&.any?

    HeadMusic::Style::Mark.for_each(faulty_notes.select { |note| note.voice == voice }.uniq.sort_by(&:position))
  end

  private

  def companion
    cantus_firmus
  end

  def faulty_notes
    dissonant_positions.flat_map { |position| faults_at(position) }
  end

  def dissonant_positions
    positions.select { |position| dissonant_at?(position) }
  end

  def faults_at(position)
    sounding = sounding_notes(position)
    attackers = sounding.select { |note| note.position == position }
    return [] if !downbeat_position?(position) && attackers.any? { |note| explained_by_figure?(note) }

    suspended = sounding.detect { |note| suspension?(note, position) }
    return (properly_suspended?(suspended, position) ? [] : [suspended]) if suspended

    attackers
  end

  def sounding_notes(position)
    [voice, companion].filter_map { |part| part.note_at(position) }
  end

  # Held into a strong beat from a weaker one, or struck again there.
  def suspension?(note, position)
    return false unless strong_beat_position?(position)
    return restruck_on_stronger_beat?(note) if note.position == position

    note.position.strength < position.strength
  end

  def properly_suspended?(note, position)
    consonant_note?(preparation(note, position)) && resolution(note, position)
  end

  def preparation(note, position)
    return note if note.position < position

    line = note.voice.notes
    line[line.index(note) - 1]
  end

  # The first note a step below, consonant with the other voice, by the second
  # strong beat after the suspension. Whatever comes between is judged as a
  # dissonance of its own.
  def resolution(note, position)
    deadline = next_strong_beat(next_strong_beat(position))
    line = note.voice.notes
    line[(line.index(note) + 1)..]
      .take_while { |later| later.position <= deadline }
      .detect { |later| resolves?(note, later) }
  end

  def resolves?(suspension, later)
    melodic = HeadMusic::Analysis::MelodicInterval.new(suspension, later)
    melodic.step? && melodic.descending? && consonant_note?(later)
  end

  def explained_by_figure?(note)
    line = note.voice
    return consonant_run?(note) if after_dotted_quarter?(note)

    consonant_run?(note) ||
      figures_for(line).cambiata_dissonance?(note) ||
      figures_for(line).double_neighbor_member?(note)
  end

  # A passing or neighbor figure: the stepwise run through the note, out to
  # the nearest notes consonant with the other voice in both directions,
  # moving in one direction (passing) or returning to its starting pitch
  # (neighbor). A rest breaks the run.
  def consonant_run?(note)
    line_notes = unbroken_notes_around(note)
    index = line_notes.index(note)
    first = (0...index).reverse_each.detect { |i| consonant_note?(line_notes[i]) }
    last = ((index + 1)...line_notes.length).detect { |i| consonant_note?(line_notes[i]) }
    return false unless first && last

    run = line_notes[first..last]
    intervals = run.each_cons(2).map { |pair| HeadMusic::Analysis::MelodicInterval.new(*pair) }
    return false unless intervals.all?(&:step?)

    intervals.map(&:direction).uniq.one? || run.first.pitch == run.last.pitch
  end

  def unbroken_notes_around(note)
    phrases = note.voice.notes.slice_when { |earlier, later| earlier.next_position < later.position }
    phrases.detect { |phrase| phrase.include?(note) }
  end

  def after_dotted_quarter?(note)
    return false unless attack_value(note).unit_name == "eighth"

    index = note.voice.notes.index(note)
    return false unless index&.positive?

    previous_value = attack_value(note.voice.notes[index - 1])
    previous_value.unit_name == "quarter" && previous_value.dots == 1
  end

  def attack_value(note)
    note.rhythmic_duration.values.first
  end

  def figures_for(line)
    @figures ||= {}
    @figures[line] ||= HeadMusic::Style::Guideline::DissonanceFigures.new(
      notes: line.notes,
      melodic_intervals: line.melodic_intervals,
      dissonant: ->(note) { !consonant_note?(note) }
    )
  end

  def consonant_note?(note)
    !dissonant_between?(note.voice, note.position)
  end

  def dissonant_at?(position)
    dissonant_between?(voice, position)
  end

  # Nil-safe: where either voice is silent, nothing is dissonant.
  def dissonant_between?(line, position)
    other = (line == voice) ? companion : voice
    interval = HeadMusic::Analysis::HarmonicInterval.new(other, line, position)
    interval.notes.length == 2 && interval.dissonance?(:two_part_harmony)
  end
end
