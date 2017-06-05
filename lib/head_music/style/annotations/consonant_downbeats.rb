module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::ConsonantDownbeats < HeadMusic::Style::Annotation
  MESSAGE = "Use consonant harmonic intervals."

  def marks
    if cantus_firmus && cantus_firmus != voice
      dissonant_pairs = cantus_firmus.notes.map do |cantus_firmus_note|
        counterpoint = voice.note_at(cantus_firmus_note.position)
        [cantus_firmus_note, counterpoint] if counterpoint && FunctionalInterval.new(cantus_firmus_note.pitch, counterpoint.pitch).dissonance?(:two_part_harmony)
      end.compact
      dissonant_pairs.map do |dissonant_pair|
        HeadMusic::Style::Mark.for_all(dissonant_pair)
      end.flatten
    end
  end
end
