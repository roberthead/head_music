# Renders a composition to ABC, re-parses the output, and asserts that the
# round trip preserves the musical content.
#
# Durations are compared through DurationWriter's exact Rational arithmetic
# rather than RhythmicValue's Float relative_value.
module ABCRoundTripHelper
  def expect_abc_round_trip(composition)
    rendered = HeadMusic::Notation::ABC.render(composition)
    reparsed = HeadMusic::Notation::ABC.parse(rendered)

    expect(reparsed.key_signature).to eq composition.key_signature
    expect(reparsed.meter.to_s).to eq composition.meter.to_s
    expect(reparsed.name).to eq composition.name
    expect(reparsed.composer).to eq composition.composer

    expect_equivalent_placements(reparsed, composition)
  end

  private

  def expect_equivalent_placements(reparsed, composition)
    original_placements = composition.voices.flat_map(&:placements)
    reparsed_placements = reparsed.voices.flat_map(&:placements)
    expect(reparsed_placements.length).to eq original_placements.length

    duration_writer = HeadMusic::Notation::ABC::DurationWriter.new(Rational(1, 8))
    reparsed_placements.zip(original_placements).each do |actual, expected|
      expect(actual.pitch.to_s).to eq expected.pitch.to_s
      expect(actual.position.to_s).to eq expected.position.to_s
      expect(duration_writer.multiplier_string(actual.rhythmic_value))
        .to eq duration_writer.multiplier_string(expected.rhythmic_value)
    end
  end
end

RSpec.configure do |config|
  config.include ABCRoundTripHelper
end
