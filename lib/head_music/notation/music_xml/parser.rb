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
      Document.new(ParsePreflight.read!(@string))
    end

    def ensure_not_compressed
      return unless @string.b.start_with?(COMPRESSED_SIGNATURE)

      raise UnsupportedFeatureError, "Compressed MusicXML (.mxl) is not supported yet; unzip it and read its score file"
    end
  end
end
