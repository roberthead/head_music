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
  #
  # As Verovio reads it, a trailing underscore, as in "Lord_", starts a line
  # over the notes after it, whose rows are null, so the syllable is kept as
  # extended. A lone "_" or "|" marks a held note itself; one with no note
  # attacking under it is skipped.
  class LyricReader
    Syllable = Data.define(:track, :verse, :text, :hyphen_after, :extended, :column) do
      def held?
        text.nil?
      end
    end
    NULL = "."
    HELD = %w[_ |].freeze

    def initialize(row)
      @row = row
      @tracks = row.tracks
    end

    def syllables
      @row.fields_on(:lyric).filter_map { |field, index| syllable(index, field) }
    end

    # Gives each syllable to the note its kern spine attacks on the row.
    def sing(events)
      syllables.each do |syllable|
        event = events[syllable.track]
        next if syllable.held? && !event&.pitches&.any?

        unless event&.pitches&.any?
          raise ParseError.new(
            %(The syllable "#{syllable.text}" in spine #{syllable.column} has no note under it), line_number: @row.record.line
          )
        end
        event.syllables << syllable
      end
    end

    private

    def syllable(index, field)
      return if field == NULL

      kern_index = nearest_kern_index(index)
      text = field.delete_prefix("-")
      held = HELD.include?(text)
      extended = !held && text.end_with?("_")
      text = text.delete_suffix("_") if extended
      Syllable.new(
        track: @tracks[upper_sub_spine_index(kern_index)],
        verse: @tracks[(kern_index + 1)..index].count(&:lyric?),
        text: held ? nil : text.delete_suffix("-"),
        hyphen_after: text.end_with?("-"),
        extended: extended,
        column: index + 1
      )
    end

    def nearest_kern_index(index)
      kern_index = @row.kern_index_before(index)
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
