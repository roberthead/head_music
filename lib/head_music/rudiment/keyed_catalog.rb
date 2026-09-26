# A module for music rudiments
module HeadMusic::Rudiment; end

# A KeyedCatalog is a closed list of named markings read from YAML, such as
# the articulations. Each key has one frozen instance, found by its key or an
# alias in any case, and an unknown key finds nothing.
module HeadMusic::Rudiment::KeyedCatalog
  # Included here rather than into each catalog, so this module's #name, which
  # translates the key, comes before Named's.
  include HeadMusic::Named

  def self.included(base)
    base.extend(ClassMethods)
    base.private_class_method :new
  end

  module ClassMethods
    attr_reader :records, :translation_scope

    def get(identifier)
      return identifier if identifier.is_a?(self)

      name_key = canonical_key(identifier)
      return unless name_key

      instances[name_key] ||= new(name_key, records[name_key]).freeze
    end

    alias_method :get_by_name, :get

    def all
      @all ||= records.keys.map { |key| get(key) }
    end

    private

    def load_catalog(file_path, root_key)
      @records = YAML.load_file(file_path).fetch(root_key).freeze
      @translation_scope = "head_music.#{root_key}"
    end

    def canonical_key(identifier)
      key = HeadMusic::Utilities::Case.to_snake_case(identifier)
      records.key?(key) ? key : aliases[key]
    end

    def aliases
      @aliases ||= records.each_with_object({}) do |(key, record), aliases|
        Array(record&.fetch("aliases", nil)).each { |alias_key| aliases[alias_key] = key }
      end
    end

    def instances
      @instances ||= {}
    end
  end

  def initialize(name_key, _record)
    @name_key = name_key
  end

  def name(locale_code: HeadMusic::Named::Locale::DEFAULT_CODE)
    I18n.translate(name_key, scope: self.class.translation_scope, locale: locale_code, default: name_key.tr("_", " "))
  end

  def to_s
    name
  end

  def inspect
    "#<#{self.class.name} #{name_key}>"
  end
end
