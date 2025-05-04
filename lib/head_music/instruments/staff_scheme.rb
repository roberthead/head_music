require_relative "staff"

# Namespace for instrument definitions, categorization, and configuration
module HeadMusic::Instruments; end

class HeadMusic::Instruments::StaffScheme
  attr_reader :variant, :key, :list

  def initialize(variant:, key:, list:)
    @variant = variant
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
