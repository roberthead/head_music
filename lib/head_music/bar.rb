class HeadMusic::Bar
  attr_reader :composition

  delegate :key_signature, :meter, to: :composition

  def initialize(composition)
    @composition = composition
  end

  # TODO: encapsulate key changes and meter changes
  # Assume the key and meter of the previous bar
  # all the way back to the first bar,
  # which defaults to the key and meter of the composition
end
