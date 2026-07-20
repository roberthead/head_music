# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline for fourth species suspension treatment.
# A suspension has three parts:
# 1. Preparation: The note is consonant with the current cantus firmus note.
# 2. Suspension: The cantus firmus moves; the counterpoint sustains, becoming dissonant.
# 3. Resolution: The counterpoint resolves by step down to a consonance.
class HeadMusic::Style::Guidelines::SuspensionTreatment < HeadMusic::Style::Annotation
  MESSAGE = "Treat suspensions with proper preparation and downward stepwise resolution."

  def marks
    return [] unless cantus_firmus&.notes&.any?

    improperly_treated_suspensions.map do |note|
      HeadMusic::Style::Mark.for(note)
    end
  end

  private

  def improperly_treated_suspensions
    dissonant_suspensions.reject { |note, cf_note| properly_treated?(note, cf_note) }.map(&:first)
  end

  def dissonant_suspensions
    cantus_firmus.notes[1..].filter_map do |cf_note|
      cp_note = suspended_cp_note(cf_note)
      [cp_note, cf_note] if cp_note && dissonant_at?(cf_note.position)
    end
  end

  # The counterpoint note sounding under the cantus firmus note, but only when it
  # began earlier (a note held over, i.e. a suspension).
  def suspended_cp_note(cf_note)
    cp_note = voice.note_at(cf_note.position)
    cp_note if cp_note && cp_note.position < cf_note.position
  end

  def properly_treated?(cp_note, cf_note)
    prepared?(cp_note, cf_note) && resolved?(cp_note, cf_note)
  end

  def prepared?(cp_note, cf_note)
    prev_cf = previous_cf_note(cf_note)
    return false unless prev_cf

    consonant_at?(cp_note.position)
  end

  def resolved?(cp_note, _cf_note)
    next_cp = voice.note_following(cp_note.position)
    return false unless next_cp

    melodic = HeadMusic::Analysis::MelodicInterval.new(cp_note, next_cp)
    return false unless melodic.step? && melodic.descending?

    consonant_at?(next_cp.position)
  end

  def dissonant_at?(position)
    interval = harmonic_interval_at(position)
    two_part?(interval) && interval.dissonance?(:two_part_harmony)
  end

  def consonant_at?(position)
    interval = harmonic_interval_at(position)
    two_part?(interval) && interval.consonance?(:two_part_harmony)
  end

  def harmonic_interval_at(position)
    HeadMusic::Analysis::HarmonicInterval.new(cantus_firmus, voice, position)
  end

  def two_part?(interval)
    interval.notes.length == 2
  end

  def previous_cf_note(cf_note)
    index = cantus_firmus.notes.index(cf_note)
    cantus_firmus.notes[index - 1] if index && index > 0
  end
end
