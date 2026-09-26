# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Reads the dynamics on one row of a file's **dynam spines, each with the
  # kern track whose part it belongs to: the nearest kern spine on its left,
  # since a **dynam spine cannot say which voice of the part it means.
  #
  # Hairpins and their continuations are skipped, as are dynamics the
  # catalog does not hold; any other text is rejected.
  class DynamicReader
    Dynamic = Data.define(:track, :dynamic, :column)
    HAIRPIN_MARKS = /[<>()\[\]]/
    DROPPED = %w[pppp ppppp ffff fffff fz sfp sffz sff spp rf mfz].freeze

    def initialize(row)
      @row = row
      @tracks = row.tracks
    end

    def dynamics
      @tracks.each_index.flat_map do |index|
        next [] unless @tracks[index].dynam?

        read(index, @row.record.fields[index])
      end
    end

    private

    def read(index, field)
      field.split(" ").filter_map do |text|
        text = text.gsub(HAIRPIN_MARKS, "")
        next if text.empty? || text == "." || DROPPED.include?(text)

        Dynamic.new(track: @tracks[nearest_kern_index(index)], dynamic: catalog_dynamic(text, field), column: index + 1)
      end
    end

    def catalog_dynamic(text, field)
      dynamic = HeadMusic::Rudiment::Dynamic.get(text) if text.match?(/\A[a-z]+\z/)
      return dynamic if dynamic

      raise UnsupportedFeatureError.new(
        %(Unsupported dynamic "#{text}" in **dynam), line_number: @row.record.line, snippet: field
      )
    end

    def nearest_kern_index(index)
      kern_index = (index - 1).downto(0).find { |candidate| @tracks[candidate].kern? }
      return kern_index if kern_index

      raise ParseError.new("A **dynam spine must follow the **kern spine of its part", line_number: @row.record.line)
    end
  end
end
