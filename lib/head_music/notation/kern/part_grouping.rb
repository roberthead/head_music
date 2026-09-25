# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Groups the kern tracks live at the first data row into parts and
  # staves, from the *partN and *staffN tags read before it.
  #
  # Kern lays parts, and the staves within a part, out bottom to top from
  # the left, so parts are ordered top-down by their rightmost spine, and
  # *staff1 is the top staff. Within one staff the leftmost spine is the
  # upper voice, following Verovio's layer convention. Spines with no
  # *part tag each form a part of their own.
  class PartGrouping
    PartPlan = Data.define(:staves, :code, :name)
    StaffPlan = Data.define(:number, :clef, :tracks)

    def initialize(tracks, tags)
      @tracks = tracks
      @tags = tags
    end

    def parts
      groups = @tracks.group_by { |track| @tags.fetch(track).part || track }.values
      groups.sort_by { |group| -@tracks.index(group.last) }.map { |group| plan(group) }
    end

    private

    def plan(group)
      PartPlan.new(
        staves: staves(group),
        code: agreed(group, :code, "*I codes"),
        name: agreed(group, :name, "*I\" names")
      )
    end

    def staves(group)
      by_number = group.group_by { |track| @tags.fetch(track).staff }
      if by_number.key?(nil) && by_number.length > 1
        raise error("Spines of *part#{@tags.fetch(group.first).part} must all have *staff tags or none", group, :staff)
      end

      by_number.keys.sort_by(&:to_i).map do |number|
        tracks = by_number.fetch(number)
        StaffPlan.new(number: number, clef: agreed(tracks, :clef, "*clef"), tracks: tracks)
      end
    end

    # The value the spines agree on, whichever of them states it.
    def agreed(tracks, kind, noun)
      values = tracks.filter_map { |track| @tags.fetch(track)[kind] }.uniq { |value| comparable(value) }
      raise error("Spines of one #{(kind == :clef) ? "staff" : "part"} disagree on their #{noun}", tracks, kind) if values.length > 1

      values.first
    end

    def comparable(value)
      value.respond_to?(:name_key) ? value.name_key : value
    end

    def error(message, tracks, kind)
      line = tracks.filter_map { |track| @tags.fetch(track).lines[kind] }.max
      UnsupportedFeatureError.new(message, line_number: line)
    end
  end
end
