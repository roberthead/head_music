class HeadMusic::Instrument::StaffScheme
  attr_reader :pitch_configuration, :key, :list

  def initialize(pitch_configuration:, key:, list:)
    @pitch_configuration = pitch_configuration
    @key = key || "default"
    @list = list
  end

  def default?
    key.to_s == "default"
  end

  def staves
    @staves ||= list.map do |attributes|
      HeadMusic::Instrument::Staff.new(self, attributes)
    end
  end
end
