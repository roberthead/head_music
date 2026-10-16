# A module for visual music notation
module HeadMusic::Notation
  # Changes a part's clefs where its measures name a clef that differs from
  # the one in force, each keyed by staff number. Only a downbeat can carry a
  # change, so one in the middle of a split bar is skipped.
  module ClefChanges
    module_function

    def apply(part, measures, bar_map)
      measures.each do |measure|
        bar = bar_map.downbeat_bar(measure.index)
        next unless bar

        measure.clefs.each do |number, clef|
          staff = part.staff_system_at(bar).staves[number - 1]
          staff.change_clef(bar, clef) if clef && staff && staff.clef_at(bar) != clef
        end
      end
    end
  end
end
