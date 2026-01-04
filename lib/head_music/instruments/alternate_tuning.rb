module HeadMusic::Instruments; end

# An alternate tuning for a stringed instrument.
#
# Tunings are defined as semitone adjustments from the standard tuning.
# For example, "Drop D" tuning lowers the low E string by 2 semitones.
#
# Examples:
#   drop_d = HeadMusic::Instruments::AlternateTuning.get("guitar", "drop_d")
#   drop_d.semitones  # => [-2, 0, 0, 0, 0, 0]
#
# When applying a tuning:
#   - First element applies to the lowest course
#   - Missing elements are treated as 0 (no change)
#   - Extra elements are ignored
class HeadMusic::Instruments::AlternateTuning
  TUNINGS = YAML.load_file(File.expand_path("alternate_tunings.yml", __dir__)).freeze

  attr_reader :instrument_key, :name_key, :semitones

  class << self
    # Get an alternate tuning by instrument and name
    # @param instrument [HeadMusic::Instruments::Instrument, String, Symbol] The instrument
    # @param name [String, Symbol] The tuning name (e.g., "drop_d")
    # @return [AlternateTuning, nil]
    def get(instrument, name)
      instrument_key = normalize_instrument_key(instrument)
      name_key = name.to_s

      data = TUNINGS.dig(instrument_key, name_key)
      return nil unless data

      new(
        instrument_key: instrument_key,
        name_key: name_key,
        semitones: data["semitones"] || []
      )
    end

    # Get all alternate tunings for an instrument
    # @param instrument [HeadMusic::Instruments::Instrument, String, Symbol] The instrument
    # @return [Array<AlternateTuning>]
    def for_instrument(instrument)
      instrument_key = normalize_instrument_key(instrument)
      return [] unless TUNINGS.key?(instrument_key)

      TUNINGS[instrument_key].map do |name_key, data|
        new(
          instrument_key: instrument_key,
          name_key: name_key,
          semitones: data["semitones"] || []
        )
      end
    end

    private

    def normalize_instrument_key(instrument)
      case instrument
      when HeadMusic::Instruments::Instrument
        instrument.name_key.to_s
      else
        instrument.to_s
      end
    end
  end

  def initialize(instrument_key:, name_key:, semitones:)
    @instrument_key = instrument_key.to_sym
    @name_key = name_key.to_sym
    @semitones = Array(semitones)
  end

  # The instrument this tuning applies to
  # @return [HeadMusic::Instruments::Instrument]
  def instrument
    HeadMusic::Instruments::Instrument.get(instrument_key)
  end

  # Human-readable name for the tuning
  # @return [String]
  def name
    name_key.to_s.tr("_", " ").split.map(&:capitalize).join(" ")
  end

  # Apply this tuning to a stringing's standard pitches
  # @param stringing [Stringing] The stringing to apply to
  # @return [Array<HeadMusic::Rudiment::Pitch>]
  def apply_to(stringing)
    stringing.pitches_with_tuning(self)
  end

  def ==(other)
    return false unless other.is_a?(self.class)

    instrument_key == other.instrument_key && name_key == other.name_key
  end

  def to_s
    "#{name} (#{instrument_key})"
  end
end
