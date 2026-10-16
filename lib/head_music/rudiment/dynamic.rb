# A module for music rudiments
module HeadMusic::Rudiment; end

# A Dynamic is a marking of loudness. A level, such as p or ff, governs the
# music after it; an accent, such as sfz, lasts one note.
class HeadMusic::Rudiment::Dynamic
  include HeadMusic::Rudiment::KeyedCatalog

  load_catalog(File.expand_path("dynamics.yml", __dir__), "dynamics")

  attr_reader :kind

  def self.levels
    all.select(&:level?)
  end

  def self.accents
    all.select(&:accent?)
  end

  KINDS_WITH_ARTICLES = {"level" => "a level", "accent" => "an accent"}.freeze

  # The dynamic of a kind an identifier names, raising for any other, with a
  # hint at where a dynamic of the other kind goes.
  def self.fetch(identifier, kind:, hint:)
    dynamic = get(identifier)
    raise ArgumentError, "unknown dynamic: #{identifier.inspect}" unless dynamic
    return dynamic if dynamic.kind == kind

    raise ArgumentError, "#{dynamic.name_key} is #{KINDS_WITH_ARTICLES.fetch(dynamic.kind)}, " \
      "not #{KINDS_WITH_ARTICLES.fetch(kind)}; #{hint}"
  end

  def initialize(name_key, record)
    super
    @kind = record.fetch("kind")
    @level_after_key = record["level_after"]
  end

  def level?
    kind == "level"
  end

  def accent?
    kind == "accent"
  end

  # The level an accent leaves in force after its note, as fp leaves p.
  def level_after
    self.class.get(@level_after_key) if @level_after_key
  end
end
