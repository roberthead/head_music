# Module for guides
module HeadMusic::Style::Guides; end

# Rules for fifth species (florid) melodies
class HeadMusic::Style::Guides::FifthSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  moving_melody(
    HeadMusic::Style::Guidelines::AllowFifthSpeciesRhythmicValues,
    HeadMusic::Style::Guidelines::MixSpeciesTextures,
    background: [HeadMusic::Style::Guidelines::PreferLongBeforeShort]
  )
end
