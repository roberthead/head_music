# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # A kern file checked for structure, before any flow exists: the spines
  # its header declares, every later spine record paired with the tracks
  # its fields belong to, and the reference records a work citation is
  # built from.
  #
  # Every row must have one field per live spine, and the file must end by
  # terminating every spine, with nothing after that but global records.
  class Document
    # A spine record and the tracks live when it was read, one per field.
    # A manipulator row also carries what it changed.
    Row = Data.define(:record, :tracks, :manipulations)

    attr_reader :header_tracks, :rows

    def initialize(records)
      @references = []
      @rows = []
      @layout = nil
      records.each { |record| read(record) }
      ensure_complete(records)
    end

    def kern_tracks
      header_tracks.select(&:kern?)
    end

    def title
      reference("OTL") || @references.find { |key, _value| key.match?(/\AOTL@@\w+\z/) }&.[](1)
    end

    def composers
      references("COM")
    end

    def composer_dates
      reference("CDT")
    end

    def catalog_number
      reference("SCT")
    end

    def date
      reference("ODT")
    end

    private

    attr_reader :layout

    def reference(key)
      references(key).first
    end

    def references(key)
      @references.filter_map { |candidate, value| value if candidate == key && !value.empty? }
    end

    def read(record)
      return read_global(record) if record.global?
      return read_header(record) if record.kind == :exclusive

      ensure_live(record)
      layout.ensure_width(record)
      tracks = layout.tracks
      manipulations = SpineLayout.manipulator_row?(record) ? layout.apply(record) : []
      @rows << Row.new(record: record, tracks: tracks, manipulations: manipulations)
    end

    def read_global(record)
      @references << [record.reference_key, record.reference_value] if record.reference_key
    end

    def read_header(record)
      raise ParseError.new("Unexpected exclusive interpretation", line_number: record.line) if layout

      @layout = SpineLayout.new(record)
      @header_tracks = layout.tracks
      return if header_tracks.any?(&:kern?)

      raise ParseError.new("kern input has no **kern spine", line_number: record.line, snippet: record.fields.join("\t"))
    end

    def ensure_live(record)
      return unless layout.empty?

      raise ParseError.new("Spine record after every spine was terminated", line_number: record.line)
    end

    def ensure_complete(records)
      raise ParseError, "kern input has no **kern spine" unless layout
      return if layout.empty?

      raise ParseError.new("kern input must end with a *- row terminating every spine", line_number: records.last.line)
    end
  end
end
