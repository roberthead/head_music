# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Reads the dynamics and hairpin marks on one row of a file's **dynam
  # spines, each with the kern track whose part it belongs to: the nearest
  # kern spine on its left, since a **dynam spine cannot say which voice of
  # the part it means.
  #
  # Text such as "cresc.", dynamics the catalog does not hold, and a spine
  # with no kern spine on its left are all skipped: the reader ignored
  # **dynam spines entirely before it read dynamics, and a file that imported
  # then still imports.
  #
  # Hairpin marks are read as Verovio reads them: `<` (or `o<`) opens a
  # crescendo and `[` closes one, `>` opens a diminuendo and `]` closes one.
  # In one field, closes come first, then anything with letters in it, then
  # opens, whatever order they are written in. A doubled close, `[[` or `]]`,
  # or a close written after an open in one token, ends where its row ends.
  class DynamicReader
    Dynamic = Data.define(:track, :dynamic, :column)

    # A role is :close, :interrupt, :open, or :close_at_row_end. An
    # interrupt is any level, accent, or text, which drops an open hairpin.
    HairpinMark = Data.define(:spine, :track, :role, :kind)

    MARKS = /o<|\[\[|\]\]|[<>\[\]()]/
    KINDS = {"<" => :crescendo, "o<" => :crescendo, "[" => :crescendo, "[[" => :crescendo,
             ">" => :diminuendo, "]" => :diminuendo, "]]" => :diminuendo}.freeze
    OPENS = ["<", "o<", ">"].freeze
    ROW_END_CLOSES = ["[[", "]]"].freeze
    ROLES = %i[close interrupt open close_at_row_end].freeze

    def initialize(row)
      @row = row
      @tracks = row.tracks
    end

    def dynamics
      readings.flat_map(&:first)
    end

    def hairpin_marks
      readings.flat_map(&:last)
    end

    private

    def readings
      @readings ||= @tracks.each_index.filter_map do |index|
        next unless @tracks[index].dynam?

        read(index, @row.record.fields[index])
      end
    end

    def read(index, field)
      kern_index = (index - 1).downto(0).find { |candidate| @tracks[candidate].kern? }
      return unless kern_index

      track = @tracks[kern_index]
      dynamics = []
      roles = []
      field.split(" ").each do |text|
        residue = text.gsub(MARKS, "")
        dynamic = catalog_dynamic(residue)
        dynamics << Dynamic.new(track: track, dynamic: dynamic, column: index + 1) if dynamic
        roles << [:interrupt, nil] if residue.match?(/[a-z]/i)
        roles.concat(mark_roles(text))
      end
      marks = ROLES.flat_map { |role| roles.select { |candidate, _kind| candidate == role } }.map do |role, kind|
        HairpinMark.new(spine: @tracks[index], track: track, role: role, kind: kind)
      end
      [dynamics, marks]
    end

    def mark_roles(text)
      opened = false
      text.scan(MARKS).filter_map do |mark|
        kind = KINDS[mark]
        next unless kind

        if OPENS.include?(mark)
          opened = true
          [:open, kind]
        else
          [(opened || ROW_END_CLOSES.include?(mark)) ? :close_at_row_end : :close, kind]
        end
      end
    end

    def catalog_dynamic(text)
      HeadMusic::Rudiment::Dynamic.get(text) if text.match?(/\A[a-z]+\z/)
    end
  end
end
