class HeadMusic::Instrument::Variant
  attr_reader :key, :attributes

  def initialize(key, attributes = {})
    @key = key.to_s.to_sym
    @attributes = attributes
  end

  def pitch_designation
    return unless attributes["pitch_designation"].to_s != ""

    @pitch_designation ||=
      HeadMusic::Spelling.get(attributes["pitch_designation"])
  end

  def staff_schemes
    @staff_schemes ||=
      (attributes["staff_schemes"] || {}).map do |key, list|
        HeadMusic::Instrument::StaffScheme.new(
          key: key,
          variant: self,
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
