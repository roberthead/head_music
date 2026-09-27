# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # What each kern spine's interpretations said before the first data row,
  # and the line each was read on, from which the header's spines are
  # grouped into parts and staves. A sub-spine a split starts inherits its
  # sibling's tags.
  class SpineTags
    Tags = Struct.new(:clef, :code, :name, :part, :staff, :lines)

    def initialize(tracks)
      @tags = tracks.to_h { |track| [track, Tags.new(lines: {})] }
    end

    def fetch(track)
      @tags.fetch(track)
    end

    def read(interpretations, line)
      interpretations.each do |track, interpretation|
        tags = fetch(track)
        tags[interpretation.kind] = interpretation.value
        tags.lines[interpretation.kind] = line
      end
    end

    def split(left, right)
      @tags[right] = fetch(left).dup.tap { |tags| tags.lines = tags.lines.dup }
    end
  end
end
