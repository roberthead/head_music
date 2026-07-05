module HeadMusic::Notation; end

# A named notation tradition: how instruments are notated (clef, sounding
# transposition, staff structure) for a given context.
#
# `default` lists every instrument. Named styles (british_brass_band,
# concert_pitch, german, italian) are sparse OVERLAYS: they list only the
# instruments whose notation differs, and any instrument they don't mention
# falls back to `default`.
#
#   HeadMusic::Notation::NotationStyle.get(:british_brass_band)
#     .notation_for("euphonium")  #=> treble clef, sounding transposition -14
#
# Uses a lightweight registry rather than the Named mixin: style keys are
# internal identifiers with no translation surface.
class HeadMusic::Notation::NotationStyle
  STYLES = YAML.load_file(File.expand_path("notation_styles.yml", __dir__)).freeze

  attr_reader :key, :name

  class << self
    def get(identifier)
      return identifier if identifier.is_a?(self)

      @styles ||= {}
      hash_key = HeadMusic::Utilities::HashKey.for(identifier)
      @styles[hash_key] ||= new(hash_key)
    end

    def default
      get(:default)
    end

    def all
      STYLES.keys.map { |style_key| get(style_key) }
    end

    private :new
  end

  # Resolve an instrument's notation in this style, falling back to `default`.
  # Accepts an Instrument or any key/name Instrument.get understands.
  # Returns an InstrumentNotation, or nil if the instrument is unknown.
  def notation_for(instrument)
    instrument = HeadMusic::Instruments::Instrument.get(instrument)
    return nil unless instrument&.name_key

    name_key = instrument.name_key.to_s
    data = instrument_notations[name_key] || default_data(name_key)
    return nil unless data

    memo[name_key] ||= HeadMusic::Notation::InstrumentNotation.new(instrument: instrument, data: data)
  end

  protected

  attr_reader :instrument_notations

  private

  def initialize(hash_key)
    @key = hash_key.to_sym
    record = STYLES[@key.to_s]
    raise KeyError, "Unknown notation style: #{@key}" unless record

    @name = record["name"]
    @instrument_notations = record["instrument_notations"] || {}
  end

  def default_data(name_key)
    return nil if @key == :default

    self.class.default.instrument_notations[name_key]
  end

  def memo
    @memo ||= {}
  end
end
