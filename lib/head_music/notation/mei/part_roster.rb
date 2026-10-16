module HeadMusic::Notation::MEI
  # Adds the flow's parts, one for each part the staff groups define, in
  # score order, each with its player, its instrument, and a staff for each
  # <staffDef>, opening with that staff's clef and lines. A single staff
  # with no clef is left to the part's fallback system, so that nothing
  # unauthored is serialized.
  #
  # A later clef or instrument on a downbeat is a change, where it differs
  # from what is in force; one in the middle of a split bar is skipped.
  class PartRoster
    def initialize(flow, identity, groups, bar_map, editorial)
      @flow = flow
      @identity = identity
      @groups = groups
      @bar_map = bar_map
      @editorial = editorial
    end

    def add(reading)
      definition = reading.definition
      part = @flow.add_part(
        player: @identity.player(definition),
        instrument: @identity.instrument(definition),
        staff_system: staff_system(definition)
      )
      HeadMusic::Notation::ClefChanges.apply(part, reading.measures, @bar_map)
      change_instruments(part, reading)
      part
    end

    private

    def staff_system(definition)
      staves = definition.staff_defs.values.map { |staff_def| staff(staff_def) }
      return if staves.one? && staves.first.clef.nil?

      HeadMusic::Content::StaffSystem.new(staves: staves, bracket: @groups.bracket(definition))
    end

    def staff(staff_def)
      where = {staff: AttributeValues.read(staff_def, "n", element: staff_def)}
      lines = AttributeValues.read(staff_def, "lines", **where, element: staff_def)
      clef = ClefReading.staff_def_clef(staff_def, @editorial, **where)
      HeadMusic::Content::Staff.new(clef: clef, **(lines ? {line_count: lines} : {}))
    end

    def change_instruments(part, reading)
      reading.instrument_changes.each do |index, instrument|
        bar = @bar_map.downbeat_bar(index)
        part.change_instrument(bar, instrument) unless bar.nil? || part.instrument_at(bar) == instrument
      end
    end
  end
end
