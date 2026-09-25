# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Reads a barline token: its bar number, if any, whether it is the final
  # barline (==), and the repeats its style marks. A colon before the
  # lines ends a repeat (:|!) and one after them starts one (!|:); the
  # other style marks are presentational.
  module BarlineReader
    Barline = Data.define(:number, :final, :ends_repeat, :starts_repeat)
    PATTERN = /\A=(=)?(\d+)?([a-z])?(.*)\z/

    module_function

    def read(field, line_number: nil)
      _, final, number, variant, style = *PATTERN.match(field)
      if variant
        raise UnsupportedFeatureError.new(
          "Bar number variants are not supported (#{field})", line_number: line_number, snippet: field
        )
      end

      Barline.new(
        number: number&.to_i, final: !final.nil?,
        ends_repeat: style.start_with?(":"), starts_repeat: style.length > 1 && style.end_with?(":")
      )
    end
  end
end
