# Renders a composition to LilyPond, re-parses the output, and asserts that
# the round trip preserves the musical content.
#
# The writer pads a voice's missing bars with whole-bar rests, so the
# reparsed composition may hold rests the original did not; every original
# placement must come back at its position with its pitches and value, and
# every extra reparsed placement must be such a rest.
module LilyPondRoundTripHelper
  def expect_lily_pond_round_trip(composition)
    rendered = HeadMusic::Notation::LilyPond.render(composition)
    reparsed = HeadMusic::Notation::LilyPond.parse(rendered)

    expect(reparsed.key_signature).to eq composition.key_signature
    expect(reparsed.meter.to_s).to eq composition.meter.to_s
    expect(reparsed.name).to eq composition.name
    expect(reparsed.composer).to eq composition.composer
    expect(reparsed.voices.map(&:role)).to eq composition.voices.map(&:role)

    expect_equivalent_bar_changes(reparsed, composition)
    reparsed.voices.zip(composition.voices).each do |actual, expected|
      expect_equivalent_voice_placements(actual, expected)
    end
    reparsed
  end

  private

  def expect_equivalent_bar_changes(reparsed, composition)
    (composition.earliest_bar_number..composition.latest_bar_number).each do |bar_number|
      expect(reparsed.key_signature_at(bar_number)).to eq composition.key_signature_at(bar_number)
      expect(reparsed.meter_at(bar_number).to_s).to eq composition.meter_at(bar_number).to_s
    end
  end

  def expect_equivalent_voice_placements(actual_voice, expected_voice)
    actual_by_position = actual_voice.placements.to_h { |placement| [placement.position.to_s, placement] }
    expected_voice.placements.each do |expected|
      actual = actual_by_position.delete(expected.position.to_s)
      expect(actual).not_to be_nil, "no placement came back at #{expected.position}"
      expect(actual.pitches.sort.map(&:to_s)).to eq expected.pitches.sort.map(&:to_s)
      expect(actual.rhythmic_value.to_s).to eq expected.rhythmic_value.to_s
    end
    expect(actual_by_position.values).to all(be_rest)
  end
end

RSpec.configure do |config|
  config.include LilyPondRoundTripHelper
end
