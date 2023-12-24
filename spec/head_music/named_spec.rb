require "spec_helper"

class GenericNamedRudiment
  include HeadMusic::Named
end

describe HeadMusic::Named do
  subject(:rudiment) { GenericNamedRudiment.new }

  context "when assigned a name" do
    before do
      rudiment.name = "David"
    end

    its(:name) { is_expected.to eq "David" }

    context "when given any locale" do
      specify { expect(rudiment.name(locale_code: :fr_CH)).to eq "David" }
      specify { expect(rudiment.name(locale_code: :en_NZ)).to eq "David" }
      specify { expect(rudiment.name(locale_code: nil)).to eq "David" }
    end

    it "stores the name as a localized name in the default locale" do
      expect(rudiment.localized_name.locale_code).to eq "en_US"
    end
  end

  describe "name keys" do
    it { is_expected.to respond_to(:name_key) }
    it { is_expected.to respond_to(:alias_name_keys) }
  end
end
