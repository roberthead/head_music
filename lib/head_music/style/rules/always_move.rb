module HeadMusic::Style::Rules
end

class HeadMusic::Style::Rules::AlwaysMove < HeadMusic::Style::Rule
  def self.analyze(voice)
    marks = marks(voice)
    fitness = HeadMusic::GOLDEN_RATIO_INVERSE**marks.length
    message = "Always move to another note." if fitness < 1
    HeadMusic::Style::Annotation.new(subject: voice, fitness: fitness, marks: marks, message: message)
  end

  def self.marks(voice)
    voice.melodic_intervals.map.with_index do |interval, i|
      if interval.shorthand == 'PU'
        HeadMusic::Style::Mark.for_all(voice.notes[i..i+1])
      end
    end.reject(&:nil?)
  end
end
