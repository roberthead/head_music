# Namespace for instrument definitions, categorization, and configuration
module HeadMusic::Instruments; end

class HeadMusic::Instruments::Variant
  attr_reader :key, :attributes

  def initialize(key, attributes = {})
    @key = key.to_s.to_sym
    @attributes = attributes
  end

  def pitch_designation
    return if attributes["pitch_designation"].to_s == ""

    @pitch_designation ||=
      HeadMusic::Rudiment::Spelling.get(attributes["pitch_designation"])
  end

  def staff_schemes
    @staff_schemes ||=
      (attributes["staff_schemes"] || {}).map do |key, list|
        HeadMusic::Instruments::StaffScheme.new(
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
