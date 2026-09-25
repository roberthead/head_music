# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Reads a barline token: its bar number, if any, and whether it is the
  # final barline (==). Style marks after the number are presentational.
  module BarlineReader
    Barline = Data.define(:number, :final)
    PATTERN = /\A=(=)?(\d+)?([a-z])?(.*)\z/

    module_function

    def read(field, line_number: nil)
      _, final, number, variant, = *PATTERN.match(field)
      if variant
        raise UnsupportedFeatureError.new(
          "Bar number variants are not supported (#{field})", line_number: line_number, snippet: field
        )
      end

      Barline.new(number: number&.to_i, final: !final.nil?)
    end
  end
end
