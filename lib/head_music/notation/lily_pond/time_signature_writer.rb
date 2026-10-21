# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # Writes a rendering's \time commands, each with the style command before it
  # where the style changes there. LilyPond prints a plain \time 4/4 or 2/2 as
  # common or cut time, so a numeric one asks for its numerals, until a symbol
  # returns.
  class TimeSignatureWriter
    STYLES = SettingReader::TIME_SIGNATURE_STYLES.invert.freeze

    def initialize(plan)
      @first_bar_number = plan.bar_numbers.first
      @meters = plan.measure_time_changes.merge(first_bar_number => plan.first_measure_meter).sort.to_h
      @styles = styles_by_bar
    end

    # The command at the opening or where the meter changes, or nil.
    def command(bar_number)
      meter = meters[bar_number]
      meter && [styles[bar_number], "\\time #{meter}"].compact.join(" ")
    end

    # A staff nobody is written on takes its meter changes from the others,
    # but its style is its own.
    def style(bar_number)
      styles[bar_number] unless bar_number == first_bar_number
    end

    private

    attr_reader :first_bar_number, :meters, :styles

    def styles_by_bar
      numeric = false
      meters.to_h do |bar_number, meter|
        wanted = meter.symbol.nil? && (numeric || SettingReader::SYMBOLS_BY_METER.key?(meter.to_s))
        style = "\\#{STYLES.fetch(wanted)}" unless wanted == numeric
        numeric = wanted
        [bar_number, style]
      end
    end
  end
end
