# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Classifies one tandem interpretation of a **kern spine as the kind of
  # thing it sets and its value. Interpretations the gem does not model
  # (expansion labels, stem and beam directions, *met, and the rest) read
  # as nil and are ignored.
  module InterpretationReader
    Interpretation = Data.define(:kind, :value, :field)

    PART = /\A\*part(\d+)\z/
    STAFF = /\A\*staff(\d+)\z/
    CROSS_STAFF = %r{\A\*staff\d+/}

    module_function

    def read(field, line_number: nil)
      context = {line_number: line_number, snippet: field}
      if InstrumentCodes.transposition?(field)
        raise UnsupportedFeatureError.new("Transposed spines are not supported (#{field})", **context)
      end
      raise UnsupportedFeatureError.new("Cross-staff spines are not supported (#{field})", **context) if CROSS_STAFF.match?(field)

      kind, value = classify(field, line_number)
      kind && Interpretation.new(kind: kind, value: value, field: field)
    end

    def classify(field, line_number)
      if TempoReader.tempo?(field) then [:tempo, TempoReader.tempo(field)]
      elsif MeterReader.meter?(field) then [:meter, MeterReader.meter(field, line_number: line_number)]
      elsif KeyReader.signature?(field) then [:signature, KeyReader.fifths(field, line_number: line_number)]
      elsif KeyReader.designation?(field) then [:designation, KeyReader.tonal_context(field, line_number: line_number)]
      elsif ClefCodes.clef?(field) then [:clef, ClefCodes.clef(field)]
      elsif InstrumentCodes.name?(field) then [:name, InstrumentCodes.name(field)]
      elsif InstrumentCodes.code?(field) then [:code, InstrumentCodes.code(field)]
      elsif PART.match?(field) then [:part, PART.match(field)[1].to_i]
      elsif STAFF.match?(field) then [:staff, STAFF.match(field)[1].to_i]
      end
    end
  end
end
