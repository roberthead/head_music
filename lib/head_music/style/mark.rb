class HeadMusic::Style::Mark
  attr_reader :start_position, :end_position, :placements

  def self.for(placement)
    new(placement.position, placement.next_position, placement)
  end

  def self.for_all(placements)
    placements = [placements].flatten
    start_position = placements.map { |placement| placement.position }.sort.first
    end_position = placements.map { |placement| placement.next_position }.sort.last
    new(start_position, end_position, placements)
  end

  def self.for_each(placements)
    placements = [placements].flatten
    placements.map { |placement| new(placement.position, placement.next_position, placement) }
  end

  def initialize(start_position, end_position, placements = [])
    @start_position = start_position
    @end_position = end_position
    @placements = [placements].flatten
  end

  def code
    [start_position, end_position].join(' to ')
  end
end
