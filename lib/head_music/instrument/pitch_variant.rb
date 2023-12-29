class HeadMusic::Instrument::PitchVariant
  attr_reader :key, :attributes

  def initialize(key, attributes = {})
    @key = key.to_s.to_sym
    @attributes = attributes
  end

  def fundamental_pitch_spelling
    return unless attributes["fundamental_pitch_spelling"].to_s != ""

    @fundamental_pitch_spelling ||=
      HeadMusic::Spelling.get(attributes["fundamental_pitch_spelling"])
  end

  def staff_schemes
    @staff_schemes ||=
      (attributes["staff_schemes"] || {}).map do |key, list|
        HeadMusic::Instrument::StaffScheme.new(
          key: key,
          pitch_variant: self,
          list: list
        )
      end
  end

  def default?
    key.to_s == "default"
  end

  def default_staff_scheme
    @default_staff_scheme ||=
      staff_schemes.find(&:default?) || staff_schemes.first
  end
end
