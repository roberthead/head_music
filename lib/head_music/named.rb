# frozen_string_literal: true

# NameRudiment is a module to be included in classes whose instances may be identified by name.
module HeadMusic::Named
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

  # Adds .get_by_name to the including class.
  module ClassMethods
    def get_by_name(name)
      name = name.to_s
      @instances_by_name ||= {}
      key = HeadMusic::Utilities::HashKey.for(name)
      @instances_by_name[key] ||= new(name)
    end

    def aliases
      {}
    end
  end

  # An Alias encapsulates an alternative name for a rudiment.
  class Alias
    attr_reader :key, :name, :abbreviation, :locale

    def initialize(key:, name:, abbreviation: nil, locale: nil)
      @key = key
      @name = name
      @abbreviation = abbreviation
      @locale = locale
    end
  end
end
