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
      ensure_input_present
      xml = parse_xml
      HeadMusic::Notation::ParsePreflight.check!(xml, roots: ROOTS, format: "MEI", error_class: ParseError)
      Document.new(xml)
    end

    # Checked on the raw bytes, since String#strip raises on invalid UTF-8.
    def ensure_input_present
      raise ParseError, "MEI input is blank" if @string.b.strip.empty?
    end

    def parse_xml
      REXML::Document.new(@string)
    rescue REXML::ParseException => error
      raise ParseError.new("Malformed MEI: #{error.message.lines.first.strip}", line_number: error.line)
    rescue Encoding::CompatibilityError, Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError, ArgumentError => error
      raise ParseError, "Unreadable MEI: #{error.message}"
    end
  end
end
