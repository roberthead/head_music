module HeadMusic::Instruments; end

# A configurable aspect of an instrument, such as a leadpipe, mute, or attachment.
#
# Examples:
#   - Piccolo trumpet "leadpipe" configuration with options: b_flat (default), a
#   - Trumpet "mute" configuration with options: open (default), straight, cup, harmon
#   - Bass trombone "f_attachment" with options: disengaged (default), engaged
class HeadMusic::Instruments::InstrumentConfiguration
  CONFIGURATIONS = YAML.load_file(File.expand_path("instrument_configurations.yml", __dir__)).freeze

  attr_reader :name_key, :instrument_key, :options

  class << self
    def for_instrument(instrument_key)
      instrument_key = instrument_key.to_s
      return [] unless CONFIGURATIONS.key?(instrument_key)

      CONFIGURATIONS[instrument_key].map do |config_name, config_data|
        new(
          name_key: config_name,
          instrument_key: instrument_key,
          options_data: config_data["options"] || {}
        )
      end
    end
  end

  def initialize(name_key:, instrument_key:, options_data: {})
    @name_key = name_key.to_sym
    @instrument_key = instrument_key.to_sym
    @options = build_options(options_data)
  end

  def default_option
    @default_option ||= options.find(&:default?) || options.first
  end

  def option(option_key)
    options.find { |opt| opt.name_key == option_key.to_sym }
  end

  def ==(other)
    return false unless other.is_a?(self.class)

    name_key == other.name_key && instrument_key == other.instrument_key
  end

  def to_s
    name_key.to_s
  end

  private

  def build_options(options_data)
    options_data.map do |option_name, option_attrs|
      attrs = option_attrs || {}
      HeadMusic::Instruments::InstrumentConfigurationOption.new(
        name_key: option_name,
        default: attrs["default"],
        transposition_semitones: attrs["transposition_semitones"],
        lowest_pitch_semitones: attrs["lowest_pitch_semitones"]
      )
    end
  end
end
