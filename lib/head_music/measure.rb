class HeadMusic::Measure
  attr_reader :composition

  delegate :key_signature, :meter, to: :composition

  def initialize(composition)
    @composition = composition
  end

  # TODO: encapsulate key changes and meter changes
  # Assume the key and meter of the previous measure
  # all the way back to the first measure,
  # which defaults to the key and meter of the composition
end
