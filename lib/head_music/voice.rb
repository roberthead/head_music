class HeadMusic::Voice
  include Comparable

  attr_reader :composition, :placements, :role

  def initialize(composition: nil, role: nil)
    @composition = composition || Composition.new(name: "Composition")
    @role = role
    @placements = []
  end

  def place(position, rhythmic_value, pitch = nil)
    HeadMusic::Placement.new(self, position, rhythmic_value, pitch).tap { |placement|
      insert_into_placements(placement)
    }
  end

  def notes
    @placements.select(&:note?)
  end

  def pitches
    notes.map(&:pitch)
  end

  def rests
    @placements.select(&:rest?)
  end

  def melodic_intervals
    intervals = []
    last_pitch = nil
    pitches.each_with_index do |pitch, i|
      if i > 0
        intervals << FunctionalInterval.new(last_pitch, pitch)
      end
      last_pitch = pitch
    end
    intervals
  end

  private

  def insert_into_placements(placement)
    @placements << placement
    @placements = @placements.sort
  end
end
