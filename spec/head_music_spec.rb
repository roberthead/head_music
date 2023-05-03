# frozen_string_literal: true

require "spec_helper"

describe HeadMusic do
  it "has a three-digit version number" do
    expect(HeadMusic::VERSION).to be =~ /\d+\.\d+\.\d+/
  end

  it "defines the golden ratio" do
    expect(HeadMusic::GOLDEN_RATIO).to be_within(0.001).of(1.618)
  end

  it "sets the 'penalty factor' to the inverse of the golden ratio" do
    expect(HeadMusic::PENALTY_FACTOR).to be_within(0.001).of(0.618)
  end

  describe "I18n" do
    context "when requesting a translation in English" do
      it "returns the translation" do
        expect(I18n.translate(:grand_staff, scope: :rudiments, locale: :en)).to eq "grand staff"
      end
    end

    context "when requesting a translation in British English" do
      it "returns the regionalized translation" do
        expect(I18n.translate(:grand_staff, scope: :rudiments, locale: :en_GB)).to eq "great staff"
      end
    end
  end
end
