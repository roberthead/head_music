module HeadMusic
  module NamedRudiment
    attr_reader :name
    delegate :to_s, to: :name

    def initialize(name)
      @name = name.to_s
    end

    def hash_key
      HeadMusic::Utilities::HashKey.for(name)
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def get_by_name(name)
        name = name.to_s
        @instances_by_name ||= {}
        key = HeadMusic::Utilities::HashKey.for(name)
        @instances_by_name[key] ||= new(name)
      end
    end
  end
end
