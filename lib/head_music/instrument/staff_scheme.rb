class HeadMusic::Instrument::StaffScheme
  attr_reader :pitch_variant, :key, :list

  def initialize(pitch_variant:, key:, list:)
    @pitch_variant = pitch_variant
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
