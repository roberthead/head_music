# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline for fourth species suspension treatment.
# A suspension has three parts:
# 1. Preparation: The note is consonant with the current cantus firmus note.
# 2. Suspension: The cantus firmus moves; the counterpoint sustains, becoming dissonant.
# 3. Resolution: The counterpoint resolves by step (usually down) to a consonance.
class HeadMusic::Style::Guidelines::SuspensionTreatment < HeadMusic::Style::Annotation
  MESSAGE = "Treat suspensions with proper preparation and stepwise resolution."

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
      cp_note = voice.note_at(cf_note.position)
      next unless cp_note && cp_note.position < cf_note.position

      interval = HeadMusic::Analysis::HarmonicInterval.new(cantus_firmus, voice, cf_note.position)
      next unless interval.notes.length == 2 && interval.dissonance?(:two_part_harmony)

      [cp_note, cf_note]
    end
  end

  def properly_treated?(cp_note, cf_note)
    prepared?(cp_note, cf_note) && resolved?(cp_note, cf_note)
  end

  def prepared?(cp_note, cf_note)
    prev_cf = previous_cf_note(cf_note)
    return false unless prev_cf

    interval = HeadMusic::Analysis::HarmonicInterval.new(cantus_firmus, voice, cp_note.position)
    interval.notes.length == 2 && interval.consonance?(:two_part_harmony)
  end

  def resolved?(cp_note, cf_note)
    next_cp = voice.note_following(cp_note.position)
    return false unless next_cp

    melodic = HeadMusic::Analysis::MelodicInterval.new(cp_note, next_cp)
    return false unless melodic.step?

    resolution_interval = HeadMusic::Analysis::HarmonicInterval.new(cantus_firmus, voice, next_cp.position)
    resolution_interval.notes.length == 2 && resolution_interval.consonance?(:two_part_harmony)
  end

  def previous_cf_note(cf_note)
    index = cantus_firmus.notes.index(cf_note)
    cantus_firmus.notes[index - 1] if index && index > 0
  end
end
