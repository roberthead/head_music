module HeadMusic::Style::Rules
end

class HeadMusic::Style::Rules::AlwaysMove < HeadMusic::Style::Rule
  def self.fitness(voice)
    return 1 unless voice.notes.length > 1
    repeats = voice.melodic_intervals.map(&:shorthand).select { |shorthand| shorthand == 'PU' }.length
    HeadMusic::GOLDEN_RATIO_INVERSE**repeats
  end

  def self.annotations(voice)
    list = []
    if fitness(voice) < 1
      previous_note = nil
      voice.notes.each_with_index do |note, i|
        if previous_note
          if note.pitch == previous_note.pitch
            start_position = previous_note.position
            end_position = note.next_position
            list << HeadMusic::Style::Annotation.new(voice, start_position, end_position, "Always move to another note.")
          end
        end
        previous_note = note
      end
    end
    list
  end
end
