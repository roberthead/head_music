require "spec_helper"

describe HeadMusic::Named::LocalizedName do
  describe "constructor" do
    context "when given only a name" do
      subject(:localized_name) { described_class.new(name: "whiz") }

      its(:name) { is_expected.to eq "whiz" }
      its(:language) { is_expected.to eq "en" }
      its(:region) { is_expected.to eq "US" }
      its(:abbreviation) { is_expected.to be_nil }
    end

    context "when given a name and a locale code" do
      subject(:localized_name) { described_class.new(name: "flitzen", locale_code: "de_CH") }

      its(:name) { is_expected.to eq "flitzen" }
      its(:language) { is_expected.to eq "de" }
      its(:region) { is_expected.to eq "CH" }
      its(:abbreviation) { is_expected.to be_nil }
    end

    context "when given a name, locale code, and abbreviation" do
      subject(:localized_name) { described_class.new(name: "whiz", locale_code: "fr_fr", abbreviation: "wz") }

      its(:name) { is_expected.to eq "whiz" }
      its(:language) { is_expected.to eq "fr" }
      its(:region) { is_expected.to eq "FR" }
      its(:abbreviation) { is_expected.to eq "wz" }
    end
  end
end
