require "rexml/document"

# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Interprets a MusicXML string as a REXML document and then a flow.
  #
  # REXML reads the encoding from a byte order mark or the XML declaration,
  # so UTF-8, UTF-16, and binary strings from File.binread all parse. It
  # never fetches a DTD or an external entity, and ParsePreflight refuses any
  # entity a document declares before a word of its text is read.
  class Parser
    COMPRESSED_SIGNATURE = "PK".b

    def initialize(string)
      @string = string.to_s
    end

    def document
      @document ||= build_document
    end

    def flow
      @flow ||= FlowBuilder.new(document).flow
    end

    private

    def build_document
      ensure_not_compressed
      ensure_input_present
      xml = parse_xml
      ParsePreflight.check!(xml)
      Document.new(xml)
    end

    def ensure_not_compressed
      return unless @string.b.start_with?(COMPRESSED_SIGNATURE)

      raise UnsupportedFeatureError, "Compressed MusicXML (.mxl) is not supported yet; unzip it and read its score file"
    end

    # Checked on the raw bytes, since String#strip raises on invalid UTF-8.
    def ensure_input_present
      raise ParseError, "MusicXML input is blank" if @string.b.strip.empty?
    end

    def parse_xml
      REXML::Document.new(@string)
    rescue REXML::ParseException => error
      raise ParseError.new("Malformed MusicXML: #{error.message.lines.first.strip}", line_number: error.line)
    rescue Encoding::CompatibilityError, Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError, ArgumentError => error
      raise ParseError, "Unreadable MusicXML: #{error.message}"
    end
  end
end
