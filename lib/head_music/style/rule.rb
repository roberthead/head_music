class HeadMusic::Style::Rule
  # returns a score between 0 and 1
  # Note: absence of a problem or 'not applicable' should score as a 1.
  # for example, if the rule is to end on the tonic,
  #   a composition with no notes should count as a 1.
  def fitness(object)
    raise NotImplementedError, 'A fitness method is required for all style rules.'
  end

  def self.annotations(object)
    raise NotImplementedError, 'An annotations method is required for all style rules.'
  end
end
