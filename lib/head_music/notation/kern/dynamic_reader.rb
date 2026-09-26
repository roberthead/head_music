# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Reads the dynamics on one row of a file's **dynam spines, each with the
  # kern track whose part it belongs to: the nearest kern spine on its left,
  # since a **dynam spine cannot say which voice of the part it means.
  #
  # Hairpins, text such as "cresc.", dynamics the catalog does not hold, and a
  # spine with no kern spine on its left are all skipped: the reader ignored
  # **dynam spines entirely before it read dynamics, and a file that imported
  # then still imports.
  class DynamicReader
    Dynamic = Data.define(:track, :dynamic, :column)
    HAIRPIN_MARKS = /[<>()\[\]]/

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
      kern_index = (index - 1).downto(0).find { |candidate| @tracks[candidate].kern? }
      return [] unless kern_index

      field.split(" ").filter_map do |text|
        dynamic = catalog_dynamic(text.gsub(HAIRPIN_MARKS, ""))
        Dynamic.new(track: @tracks[kern_index], dynamic: dynamic, column: index + 1) if dynamic
      end
    end

    def catalog_dynamic(text)
      HeadMusic::Rudiment::Dynamic.get(text) if text.match?(/\A[a-z]+\z/)
    end
  end
end
