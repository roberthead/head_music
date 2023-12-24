class HeadMusic::Instrument::PitchConfiguration
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

  def staff_configurations
    @staff_configurations ||=
      (attributes["staff_configurations"] || {}).map do |key, list|
        HeadMusic::Instrument::StaffConfiguration.new(
          key: key,
          pitch_configuration: self,
          list: list
        )
      end
  end

  def default?
    key.to_s == "default"
  end

  def default_staff_configuration
    @default_staff_configuration ||=
      staff_configurations.find(&:default?) || staff_configurations.first
  end
end
