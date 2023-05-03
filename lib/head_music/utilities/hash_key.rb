# frozen_string_literal: true

# A namespace for utilities classes and modules
module HeadMusic::Utilities; end

# Util for converting an object to a consistent hash key
module HeadMusic::Utilities::HashKey
  def self.for(identifier)
    I18n.transliterate(identifier.to_s).downcase.gsub(/\W+/, "_").to_sym
  end
end
