# A module for music rudiments
module HeadMusic::Rudiment; end

# An Ornament adds notes around the written one, such as a trill or a turn.
class HeadMusic::Rudiment::Ornament
  include HeadMusic::Rudiment::KeyedCatalog

  load_catalog(File.expand_path("ornaments.yml", __dir__), "ornaments")
end
