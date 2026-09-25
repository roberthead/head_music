# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Reads the syllables on one row of a file's **text and **silbe spines,
  # each with the kern track it is sung to and its verse.
  #
  # A lyric spine belongs to the nearest kern spine on its left, and to
  # that spine's upper voice (its leftmost sub-spine) when it is split.
  # Successive lyric spines for one kern spine are verses 1, 2, and so on.
  # Kern hyphenates a word across notes as "mei-" then "-nes"; the
  # trailing hyphen is kept as hyphen_after, and the leading one dropped.
  class LyricReader
    Syllable = Data.define(:track, :verse, :text, :hyphen_after, :column)
    SKIPPED = %w[. | _].freeze

    def initialize(row)
      @row = row
      @tracks = row.tracks
    end

    def syllables
      @tracks.each_index.filter_map do |index|
        next unless @tracks[index].lyric?

        syllable(index, @row.record.fields[index])
      end
    end

    private

    def syllable(index, field)
      return if SKIPPED.include?(field)

      kern_index = nearest_kern_index(index)
      text = field.delete_prefix("-")
      Syllable.new(
        track: @tracks[upper_sub_spine_index(kern_index)],
        verse: @tracks[(kern_index + 1)..index].count(&:lyric?),
        text: text.delete_suffix("-"),
        hyphen_after: text.end_with?("-"),
        column: index + 1
      )
    end

    def nearest_kern_index(index)
      kern_index = (index - 1).downto(0).find { |candidate| @tracks[candidate].kern? }
      return kern_index if kern_index

      raise ParseError.new(
        "A #{@tracks[index].exclusive} spine must follow the **kern spine it is sung to", line_number: @row.record.line
      )
    end

    def upper_sub_spine_index(kern_index)
      origin = @tracks[kern_index].origin
      kern_index -= 1 while kern_index.positive? && @tracks[kern_index - 1].kern? && @tracks[kern_index - 1].origin == origin
      kern_index
    end
  end
end
