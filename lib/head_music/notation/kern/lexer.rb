# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Splits a Humdrum file into records and classifies each one.
  #
  # The lexer knows nothing of spines: whether a row has the right number
  # of fields, and whether the file ends by terminating every spine, depend
  # on the spine layout, which the Document follows.
  class Lexer
    GLOBAL_PREFIXES = {"!!!!" => :universal, "!!!" => :reference, "!!" => :global_comment}.freeze
    SPINE_PREFIXES = {"**" => :exclusive, "*" => :interpretation, "=" => :barline, "!" => :local_comment}.freeze

    def initialize(kern_string)
      @kern_string = kern_string
    end

    def records
      @records ||= read
    end

    private

    def read
      header_seen = false
      normalized_lines.filter_map do |text, line_number|
        next if text.empty?

        record = classify(text, line_number)
        ensure_after_header(record, header_seen)
        header_seen ||= record.kind == :exclusive
        record
      end
    end

    # Humdrum files are UTF-8, but older KernScores files are Latin-1, and
    # File.read tags those UTF-8 anyway; the invalid bytes must not escape
    # as an Encoding error from some later string operation.
    def normalized_lines
      text = @kern_string.to_s
      text = text.dup.force_encoding(Encoding::UTF_8) unless text.encoding == Encoding::UTF_8
      raise ParseError, "kern input is not valid UTF-8" unless text.valid_encoding?

      text.delete_prefix("﻿").split("\n").each_with_index.map { |line, index| [line.delete_suffix("\r"), index + 1] }
    end

    def classify(text, line_number)
      global_kind = GLOBAL_PREFIXES.find { |prefix, _kind| text.start_with?(prefix) }&.last
      return Record.new(kind: global_kind, line: line_number, fields: [text]) if global_kind

      fields = text.split("\t", -1)
      ensure_fields_present(fields, text, line_number)
      kind = kind_of(fields.first)
      ensure_uniform(fields, kind, text, line_number)
      Record.new(kind: kind, line: line_number, fields: fields)
    end

    def kind_of(field)
      SPINE_PREFIXES.find { |prefix, _kind| field.start_with?(prefix) }&.last || :data
    end

    def ensure_fields_present(fields, text, line_number)
      index = fields.index(&:empty?)
      return unless index

      raise ParseError.new("Empty field in column #{index + 1}", line_number: line_number, snippet: text)
    end

    # Every field of a row is the same kind of record: a barline row is
    # all barlines, a data row all data.
    def ensure_uniform(fields, kind, text, line_number)
      stray = fields.find { |field| kind_of(field) != kind }
      return unless stray

      raise ParseError.new(%(Field "#{stray}" does not match its row), line_number: line_number, snippet: text)
    end

    def ensure_after_header(record, header_seen)
      return if header_seen || record.global? || record.kind == :exclusive

      raise ParseError.new(
        "Spine records must follow an exclusive interpretation such as **kern",
        line_number: record.line, snippet: record.fields.join("\t")
      )
    end
  end
end
