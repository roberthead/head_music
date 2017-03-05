class HeadMusic::Style::Rule
  # returns a score between 0 and 1
  def fitness(object)
    raise NotImplementedError, 'A fitness method is required for all style rules.'
  end

  def self.annotations(object)
    raise NotImplementedError, 'An annotations method is required for all style rules.'
  end
end
