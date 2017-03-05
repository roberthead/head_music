module HeadMusic::Style::Rules
end

class HeadMusic::Style::Rules::NoRests < HeadMusic::Style::Rule
  def self.fitness(voice)
    rests_count = voice.rests.length
    1 * HeadMusic::GOLDEN_RATIO_INVERSE**rests_count
  end

  def self.annotations(voice)
    list = []
    voice.rests.each do |rest|
      start_position = rest.position
      end_position = rest.next_position
      list << HeadMusic::Style::Annotation.new(voice, start_position, end_position, "Change rest to note.")
    end
    list
  end
end
