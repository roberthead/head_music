# A module for music rudiments
module HeadMusic::Rudiment; end

# An Articulation is how a single note is attacked, held, or released, such as
# staccato or tenuto.
class HeadMusic::Rudiment::Articulation
  include HeadMusic::Rudiment::KeyedCatalog

  load_catalog(File.expand_path("articulations.yml", __dir__), "articulations")
end
