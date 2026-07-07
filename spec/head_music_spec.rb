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
        expect(I18n.translate(:grand_staff, scope: %i[head_music rudiments], locale: :en)).to eq "grand staff"
      end
    end

    context "when requesting a translation in British English" do
      it "returns the regionalized translation" do
        expect(I18n.translate(:grand_staff, scope: %i[head_music rudiments], locale: :en_GB)).to eq "great staff"
      end
    end
  end

  describe "idempotent I18n configuration" do
    # Re-loading the entry point exercises the configuration guards in their
    # already-configured state: the fallbacks backend is not re-included and
    # existing fallback chains are left untouched.
    def reload_entry_point
      original_verbose = $VERBOSE
      $VERBOSE = nil
      load File.expand_path("../lib/head_music.rb", __dir__)
    ensure
      $VERBOSE = original_verbose
    end

    it "leaves the fallbacks backend included when loaded again" do
      reload_entry_point
      expect(I18n::Backend::Simple.included_modules).to include(I18n::Backend::Fallbacks)
    end

    it "leaves existing fallback chains untouched when loaded again" do
      before_fallbacks = I18n.fallbacks[:de].dup
      reload_entry_point
      expect(I18n.fallbacks[:de]).to eq(before_fallbacks)
    end
  end
end
