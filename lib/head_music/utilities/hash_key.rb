module HeadMusic
  module Utilities
    class HashKey
      def self.for(name)
        name.to_s.downcase.gsub(/\W+/, '_').to_sym
      end
    end
  end
end
