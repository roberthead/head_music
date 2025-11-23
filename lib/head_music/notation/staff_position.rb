# A module for visual music notation
module HeadMusic::Notation; end

class HeadMusic::Notation::StaffPosition
  attr_reader :index  # Integer, even = line, odd = space; bottom line = 0

  NAMES = {
    -2 => ["ledger line below staff"],
    -1 => ["space below staff"],
    0 => ["bottom line", "line 1"],
    1 => ["bottom space", "space 1"],
    2 => ["line 2"],
    3 => ["space 2"],
    4 => ["middle line", "line 3"],
    5 => ["space 3"],
    6 => ["line 4"],
    7 => ["space 4"],
    8 => ["top line", "line 5"],
    9 => ["space above staff"],
    10 => ["ledger line above staff"]
  }.freeze

  # Accepts a name (string or symbol) and returns the corresponding StaffPosition index (integer), or nil if not found
  def self.name_to_index(name)
    NAMES.each do |index, names|
      if names.map { |n|
        HeadMusic::Utilities::Case.to_snake_case(n)
      }.include?(HeadMusic::Utilities::Case.to_snake_case(name))
        return index
      end
    end
    nil
  end

  def initialize(index)
    @index = index
  end

  def line?
    index.even?
  end

  def space?
    index.odd?
  end

  def line_number
    return nil unless line?
    (index / 2) + 1
  end

  def space_number
    return nil unless space?
    ((index - 1) / 2) + 1
  end

  def to_s
    return NAMES[index].first if NAMES.key?(index)

    line? ? "line #{line_number}" : "space #{space_number}"
  end
end
