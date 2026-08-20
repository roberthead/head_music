require "spec_helper"

describe HeadMusic::Analysis::DiatonicInterval::Localization do
  subject(:localization) { described_class.new(computed_name, locale_code) }

  let(:computed_name) { "major third" }

  context "when no locale is asked for" do
    let(:locale_code) { nil }

    its(:name) { is_expected.to eq "major third" }
  end

  context "when the locale has the interval translated" do
    let(:locale_code) { :fr }

    its(:name) { is_expected.to eq "tierce majeure" }
  end

  context "when the locale is loaded but has no entry for the name" do
    let(:locale_code) { :en_GB }

    it "leaves the computed name standing" do
      expect(localization.name).to eq "major third"
    end
  end

  context "when the locale has no translations at all" do
    let(:locale_code) { :xx }

    it "leaves the computed name standing" do
      expect(localization.name).to eq "major third"
    end
  end

  context "when the name is only listed among the chromatic intervals" do
    let(:computed_name) { "tritone" }
    let(:locale_code) { :fr }

    it "falls through to that heading" do
      expect(localization.name).not_to be_nil
    end
  end
end
