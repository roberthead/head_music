class HeadMusic::Voice
  include Comparable

  attr_reader :composition, :placements

  def initialize(composition = nil)
    @composition = composition || Composition.new(name: "Unnamed")
    @placements = []
  end

  def place(position, rhythmic_value, pitch = nil)
    HeadMusic::Placement.new(self, position, rhythmic_value, pitch).tap { |placement|
      insert_into_placements(placement)
    }
  end

  private

  def insert_into_placements(placement)
    @placements << placement
    @placements = @placements.sort
  end
end
