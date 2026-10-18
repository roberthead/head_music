module HeadMusic::Notation::MEI
  # The clefs each part's measures open with, by staff in the part: a clef
  # that closes a layer of the bar before, at the barline after it, a clef
  # that opens a layer, or a change between measures, each later one
  # winning. Only a layer that reaches as far as its part's music in the
  # bar closes with its clef. The first measure opens with the staff
  # definitions' clefs.
  class MeasureClefs
    def initialize
      @closing = {}.compare_by_identity
    end

    def open(reading, measure, changes, contents)
      return if measure.index.zero?

      clefs = measure.clefs
      clefs.merge!(@closing.fetch(reading, {}), first_by_staff(reading, contents, &:opening_clef))
      changes.clefs.each do |number, clef|
        staff = reading.definition.staff_index(number)
        clefs[staff] = clef if staff
      end
    end

    def close(reading, measure, contents)
      reach = measure.extent
      @closing[reading] = first_by_staff(reading, contents) { |content| content.closing_clef if content.extent == reach }
    end

    private

    def first_by_staff(reading, contents)
      contents.each_with_object({}) do |content, clefs|
        clef = yield(content)
        clefs[reading.definition.staff_index(content.staff_number)] ||= clef if clef
      end
    end
  end
end
