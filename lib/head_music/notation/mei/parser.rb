require "rexml/document"

module HeadMusic::Notation::MEI
  # Interprets an MEI string as a REXML document and then as flows.
  #
  # REXML reads the encoding from a byte order mark or the XML declaration,
  # so UTF-8, UTF-16, and binary strings from File.binread all parse. It
  # never fetches a schema or an external entity, and ParsePreflight refuses
  # any entity a document declares before a word of its text is read.
  # @meiversion is never checked, since 4.0.1, 5.1, and 5.1+basic all occur.
  class Parser
    ROOTS = %w[mei meiCorpus music].freeze

    def initialize(string)
      @string = string.to_s
    end

    def document
      @document ||= build_document
    end

    # A score with no music makes no flow, unless no score has music.
    def flows
      found = document.sources.filter_map { |source| FlowBuilder.new(source).music }
      raise ParseError, "MEI input contains no music" if found.empty?

      found
    end

    def flow
      sources = document.sources
      if sources.length > 1
        raise ParseError, "MEI input holds #{sources.length} scores; MEI.parse_book reads each of them"
      end

      FlowBuilder.new(sources.first).flow
    end

    private

    def build_document
      Document.new(HeadMusic::Notation::ParsePreflight.read!(@string, roots: ROOTS, format: "MEI", error_class: ParseError))
    end
  end
end
