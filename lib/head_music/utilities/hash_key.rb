module HeadMusic
  module Utilities
    class HashKey
      def self.for(identifier)
        identifier.to_s.downcase.gsub(/\W+/, '_').to_sym
      end
    end
  end
end
