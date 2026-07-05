require "spec_helper"
require "json"

# Characterization guard: proves the NotationStyle refactor did not drift any
# instrument's resolved default notation. The fixture was captured from the
# pre-refactor code (each instrument's `default` staff scheme). Every value
# here must still match after notation moved into NotationStyle.
describe "HeadMusic::Notation::NotationStyle" do
  fixture_path = File.expand_path("../../fixtures/notation/legacy_default_notation.json", __dir__)
  legacy = JSON.parse(File.read(fixture_path))

  def notation_tuple(instrument)
    {
      "clefs" => instrument.default_clefs.map(&:to_s),
      "sounding_transposition" => instrument.sounding_transposition,
      "staves_count" => instrument.default_staves.length,
      "single_staff" => instrument.single_staff?,
      "multiple_staves" => instrument.multiple_staves?,
      "pitched" => instrument.pitched?,
      "transposing" => instrument.transposing?,
      "transposing_at_the_octave" => instrument.transposing_at_the_octave?
    }
  end

  it "covers every instrument" do
    expect(legacy.size).to eq(HeadMusic::Instruments::Instrument::INSTRUMENTS.size)
  end

  legacy.each do |name_key, expected|
    it "resolves the same default notation as before the refactor for #{name_key}" do
      expect(notation_tuple(HeadMusic::Instruments::Instrument.get(name_key))).to eq(expected)
    end
  end
end
