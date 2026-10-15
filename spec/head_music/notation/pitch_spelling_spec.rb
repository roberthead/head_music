require "spec_helper"

describe HeadMusic::Notation::PitchSpelling do
  let(:errors) do
    Module.new.tap do |errors|
      errors.const_set(:UnsupportedFeatureError, Class.new(HeadMusic::Notation::ParseError) {
        attr_reader :measure

        def initialize(message, measure: nil)
          @measure = measure
          super(message)
        end
      })
    end
  end

  it "spells a pitch as written" do
    expect(described_class.spelled("F", 1, 4, errors: errors).to_s).to eq "F♯4"
  end

  it "spells a number with a letter in the octave nearest its natural" do
    expect(described_class.from_number_and_letter(59, "C", errors: errors).to_s).to eq "C♭4"
  end

  it "raises the reader's error, with its location, where the catalog has no spelling" do
    expect { described_class.spelled("C", 3, 4, errors: errors, measure: "7") }
      .to raise_error(errors::UnsupportedFeatureError, "The pitch C altered by 3 in octave 4 has no spelling") { |error| expect(error.measure).to eq "7" }
  end
end
