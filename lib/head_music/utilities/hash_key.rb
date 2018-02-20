# frozen_string_literal: true

module HeadMusic::Utilities; end

# Util for converting an object to a consistent hash key
module HeadMusic::Utilities::HashKey
  def self.for(identifier)
    identifier.to_s.downcase.gsub(/\W+/, '_').to_sym
  end
end
