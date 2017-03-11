module HeadMusic::Style::Rules
end

class HeadMusic::Style::Rules::NotesSameLength < HeadMusic::Style::Rule
  def self.analyze(voice)
    fitness = fitness(voice)
    if fitness < 1
      message = "Use consistent rhythmic unit."
    end
    marks = marks(voice)
    HeadMusic::Style::Annotation.new(subject: voice, fitness: fitness, marks: marks, message: message)
  end

  def self.fitness(voice)
    distinct_values = [distinct_values(voice), 1].max
    HeadMusic::PENALTY_FACTOR**(distinct_values-1)
  end

  def self.distinct_values(voice)
    voice.notes[0..-2].map(&:rhythmic_value).uniq.length
  end

  def self.marks(voice)
    preferred_value = first_most_common_rhythmic_value(voice)
    wrong_length_notes = voice.notes.select { |note| note.rhythmic_value != preferred_value }
    HeadMusic::Style::Mark.for_each(wrong_length_notes)
  end

  def self.first_most_common_rhythmic_value(voice)
    candidates = most_common_rhythmic_values(voice)
    first_match = voice.notes.detect { |note| candidates.include?(note.rhythmic_value) }
    first_match ? first_match.rhythmic_value : nil
  end

  def self.most_common_rhythmic_values(voice)
    return [] if voice.notes.empty?
    occurrences = occurrences_by_rhythmic_value(voice)
    highest_count = occurrences.values.sort.last
    occurrences.select { |rhythmic_value, count| count == highest_count }.keys
  end

  def self.occurrences_by_rhythmic_value(voice)
    rhythmic_values(voice).inject(Hash.new(0)) { |hash, value| hash[value] += 1; hash }
  end

  def self.rhythmic_values(voice)
    voice.notes.map(&:rhythmic_value)
  end
end
