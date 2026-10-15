module HeadMusic::Notation::MEI
  # Adds the flow's parts, one for each part the staff groups define, in
  # score order, each with its player, its instrument, and a staff for each
  # <staffDef>, opening with that staff's clef and lines. A single staff
  # with no clef is left to the part's fallback system, so that nothing
  # unauthored is serialized.
  class PartRoster
    def initialize(flow, identity, groups, opening, editorial)
      @flow = flow
      @identity = identity
      @groups = groups
      @opening = opening
      @editorial = editorial
    end

    def add(reading)
      definition = reading.definition
      @flow.add_part(
        player: @identity.player(definition),
        instrument: @identity.instrument(definition),
        staff_system: staff_system(definition)
      )
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
  end
end
