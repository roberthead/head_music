require "yaml"

module HeadMusic::Instruments; end

class HeadMusic::Instruments::PlayingTechnique
  include HeadMusic::Named

  RECORDS = YAML.load_file(File.expand_path("playing_techniques.yml", __dir__)).freeze

  attr_reader :name_key, :scopes, :origin, :meaning, :notations

  class << self
    def get(identifier)
      return identifier if identifier.is_a?(self)

      name_key = HeadMusic::Utilities::Case.to_snake_case(identifier)
      @instances ||= {}
      @instances[name_key] ||= new(name_key)
    end

    def all
      @all ||= technique_keys.map { |key| get(key) }
    end

    def for_scope(scope)
      scope = scope.to_s
      all.select { |technique| technique.scopes&.include?(scope) }
    end

    private

    def technique_keys
      RECORDS["playing_techniques"]&.keys || []
    end
  end

  def name(locale_code: HeadMusic::Named::Locale::DEFAULT_CODE)
    I18n.translate(name_key, scope: "head_music.playing_techniques", locale: locale_code, default: inferred_name)
  end

  def to_s
    name
  end

  def ==(other)
    return false unless other.is_a?(self.class)

    name_key == other.name_key
  end

  def hash
    name_key.hash
  end

  alias_method :eql?, :==

  private_class_method :new

  private

  def initialize(name_key)
    @name_key = name_key.to_s
    record = RECORDS.dig("playing_techniques", @name_key)
    return unless record

    @scopes = record["scopes"]
    @origin = record["origin"]
    @meaning = record["meaning"]
    @notations = record["notations"]
  end

  def inferred_name
    name_key.to_s.tr("_", " ")
  end
end
