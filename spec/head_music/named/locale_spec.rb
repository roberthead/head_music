require "spec_helper"

describe HeadMusic::Named::Locale do
  describe ".default_locale" do
    subject(:locale) { described_class.default_locale }

    its(:code) { is_expected.to eq "en_US" }
    its(:language) { is_expected.to eq "en" }
    its(:region) { is_expected.to eq "US" }
  end

  describe ".get" do
    context "when a code is passed in as a lowercase string" do
      subject(:locale) { described_class.get("en_gb") }

      its(:code) { is_expected.to eq "en_GB" }
      its(:language) { is_expected.to eq "en" }
      its(:region) { is_expected.to eq "GB" }
    end

    context "when a code is passed in as a symbol" do
      context "when the code has only a language" do
        subject(:locale) { described_class.get(:de) }

        its(:code) { is_expected.to eq "de" }
        its(:language) { is_expected.to eq "de" }
        its(:region) { is_expected.to be_nil }
      end

      context "when the code has a language and a region" do
        subject(:locale) { described_class.get(:de_de) }

        its(:code) { is_expected.to eq "de_DE" }
        its(:language) { is_expected.to eq "de" }
        its(:region) { is_expected.to eq "DE" }
      end
    end
  end

  describe ".new" do
    it "throws an exception" do
      expect { described_class.new(language: "en") }.to raise_error(NoMethodError)
    end
  end
end
