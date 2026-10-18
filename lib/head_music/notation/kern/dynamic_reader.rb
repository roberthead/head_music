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
      @readings ||= @row.fields_on(:dynam).filter_map { |field, index| read(index, field) }
    end

    def read(index, field)
      kern_index = @row.kern_index_before(index)
      return unless kern_index

      track = @tracks[kern_index]
      texts = field.split(" ").map { |text| [text, text.gsub(MARKS, "")] }
      dynamics = texts.filter_map { |_text, residue| catalog_dynamic(residue) }
      by_role = texts.flat_map { |text, residue| mark_roles(text, residue) }.group_by(&:first)
      [
        dynamics.map { |dynamic| Dynamic.new(track: track, dynamic: dynamic, column: index + 1) },
        ROLES.flat_map { |role| by_role.fetch(role, []) }.map do |role, kind|
          HairpinMark.new(spine: @tracks[index], track: track, role: role, kind: kind)
        end
      ]
    end

    # Letters left after the marks are an interrupt.
    def mark_roles(text, residue)
      opened = false
      interrupt = residue.match?(/[a-z]/i) ? [[:interrupt, nil]] : []
      interrupt + text.scan(MARKS).filter_map do |mark|
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
