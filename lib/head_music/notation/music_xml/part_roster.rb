# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Adds the flow's parts, one to each part read, in document order, each
  # with its player, its instrument, and its staves.
  #
  # <staves> gives a part a staff system joined as its <part-symbol> says,
  # braced as StaffSystem.grand_staff is when it says nothing, each staff
  # opening with the first measure's clef for it. A single
  # staff with no clef is left to the part's fallback system, so that
  # nothing unauthored is serialized. A later clef on a downbeat is a clef
  # change; one in the middle of a bar is skipped.
  class PartRoster
    def initialize(flow, identity, bar_map)
      @flow = flow
      @identity = identity
      @bar_map = bar_map
    end

    def add(reading)
      document_part = reading.document_part
      part = @flow.add_part(
        player: @identity.player(document_part),
        instrument: @identity.instrument(document_part),
        staff_system: staff_system(reading)
      )
      change_clefs(part, reading)
      part
    end

    private

    BRACKETS_BY_PART_SYMBOL = {"bracket" => :bracket, "square" => :bracket, "none" => :none}.freeze

    def staff_system(reading)
      clefs = reading.measures.first.clefs
      return if reading.staves == 1 && clefs[1].nil?

      HeadMusic::Content::StaffSystem.new(
        staves: (1..reading.staves).map { |number| HeadMusic::Content::Staff.new(clef: clefs[number]) },
        bracket: (reading.staves > 1) ? BRACKETS_BY_PART_SYMBOL.fetch(reading.part_symbol.to_s.strip, :brace) : :none
      )
    end

    def change_clefs(part, reading)
      reading.measures.drop(1).each do |measure|
        next unless @bar_map.shift(measure.index).zero?

        bar = @bar_map.bar_number(measure.index)
        measure.clefs.each do |number, clef|
          staff = part.staff_system_at(bar).staves[number - 1]
          staff.change_clef(bar, clef) if clef && staff && staff.clef_at(bar) != clef
        end
      end
    end
  end
end
