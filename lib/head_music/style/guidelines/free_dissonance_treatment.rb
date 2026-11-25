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
  include HeadMusic::Style::Guideline::FigurePlacement

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

  # A dissonant half note may only pass, and only a quarter note may be the
  # dissonance of a cambiata or a double neighbor, which rules out the eighth
  # after a dotted quarter along with every other.
  def explained_by_figure?(note)
    figures = figures_for(note.voice)
    return figures.passing_run?(note) if half_note_or_longer?(note)

    figures.consonant_run?(note) || leaping_figure?(figures, note, quarter_dissonances: true)
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
