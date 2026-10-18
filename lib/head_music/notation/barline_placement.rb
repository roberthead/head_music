# A module for visual music notation
module HeadMusic::Notation
  # Where a reader's barline record falls: in the last bar, and inside a bar,
  # as the right barline of a measure that the next one completes. Its
  # record answers last and mid_bar.
  module BarlinePlacement
    def last?
      last
    end

    def mid_bar?
      mid_bar
    end
  end
end
