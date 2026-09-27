# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # The flow's parts, one to each part the header's spines declare, with
  # the instrument code and name each was declared with and its staves by
  # their *staffN numbers.
  #
  # One player per part, even where two parts share a name: kern has no
  # way to say two spines are one chair.
  class PartRoster
    Declaration = Data.define(:code, :name, :staves_by_number)

    def initialize(flow)
      @flow = flow
      @declarations = {}
    end

    # Yields each of the plan's kern tracks with its part and staff.
    def add(plan)
      part = @flow.add_part(
        player: plan.name && HeadMusic::Content::Player.new(name: plan.name),
        instrument: plan.code && InstrumentCodes.instrument(plan.code),
        staff_system: staff_system_for(plan)
      )
      staves = part.staff_system.staves
      @declarations[part] = Declaration.new(
        code: plan.code, name: plan.name, staves_by_number: plan.staves.map(&:number).zip(staves).to_h
      )
      plan.staves.zip(staves).each do |staff_plan, staff|
        staff_plan.tracks.each { |track| yield track, part, staff }
      end
    end

    def declared(part, kind)
      @declarations.fetch(part).public_send(kind)
    end

    def staff(part, number)
      declared(part, :staves_by_number)[number]
    end

    # A split adds its voice to the part when it happens, after any voice on
    # a lower staff, so a part's voices are put back top staff first, in the
    # order they appeared, as they are for the spines of the header.
    def order_voices_by_staff
      first_bar = @flow.earliest_bar_number
      @flow.parts.each do |part|
        staves = part.staff_system_at(first_bar).staves
        ordered = part.voices.each_with_index.sort_by do |voice, index|
          [staves.index { |staff| staff.equal?(voice.staff_at(first_bar)) }, index]
        end
        part.voices.replace(ordered.map(&:first))
      end
    end

    private

    # A single staff with no clef is left to the part's fallback system, so
    # that nothing unauthored is serialized.
    def staff_system_for(plan)
      clefs = plan.staves.map(&:clef)
      return if clefs.length == 1 && clefs.first.nil?

      HeadMusic::Content::StaffSystem.new(
        staves: clefs.map { |clef| HeadMusic::Content::Staff.new(clef: clef) },
        bracket: (clefs.length > 1) ? :brace : :none
      )
    end
  end
end
