# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Reads a barline token: its bar number, if any, whether it is the final
  # barline (==), the repeats its style marks, and the style of the bar it
  # closes. A colon before the lines ends a repeat (:|!) and one after them
  # starts one (!|:). A repeat sign is drawn as a repeat whatever its lines,
  # so only a barline without colons is double (||) or final (|! or ==);
  # the other style marks are presentational.
  module BarlineReader
    Barline = Data.define(:number, :final, :ends_repeat, :starts_repeat, :style)
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
        ends_repeat: style.start_with?(":"), starts_repeat: style.length > 1 && style.end_with?(":"),
        style: barline_style(final, style)
      )
    end

    def barline_style(final, style)
      return :regular if style.include?(":")
      return :final if final || style.include?("|!")

      style.include?("||") ? :double : :regular
    end
  end
end
