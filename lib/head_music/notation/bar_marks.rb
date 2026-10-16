# A module for visual music notation
module HeadMusic::Notation
  # Sets the navigation marks a reader collected by bar number, each a hash
  # of bar fields and their values. A mark on a bar the music does not reach
  # is dropped.
  module BarMarks
    module_function

    def apply(flow, marks_by_bar)
      bar_numbers = flow.earliest_bar_number..flow.latest_bar_number
      marks_by_bar.each do |number, marks|
        next unless bar_numbers.cover?(number)

        bar = flow.bar(number)
        marks.each { |field, value| bar.public_send(:"#{field}=", value) }
      end
    end
  end
end
