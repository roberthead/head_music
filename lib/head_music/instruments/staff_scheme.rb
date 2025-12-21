require_relative "staff"

module HeadMusic::Instruments; end

class HeadMusic::Instruments::StaffScheme
  attr_reader :instrument, :key, :list

  # For backward compatibility, also alias as variant
  alias_method :variant, :instrument

  def initialize(key:, list:, instrument: nil, variant: nil)
    @instrument = instrument || variant
    @key = key || "default"
    @list = list
  end

  def default?
    key.to_s == "default"
  end

  def staves
    @staves ||= list.map do |attributes|
      HeadMusic::Instruments::Staff.new(self, attributes)
    end
  end
end
