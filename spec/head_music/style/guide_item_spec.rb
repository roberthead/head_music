require "spec_helper"

describe HeadMusic::Style::GuideItem do
  let(:guidelines) { HeadMusic::Style::Guidelines }

  describe ".wrap" do
    it "coerces a bare guideline class, so a declaration can mix the two forms" do
      wrapped = described_class.wrap(guidelines::ConsonantClimax)

      expect(wrapped).to be_a described_class
      expect(wrapped.guideline).to eq guidelines::ConsonantClimax
      expect(wrapped.config).to eq({})
    end

    it "passes an item through unchanged" do
      item = guidelines::MinimumNotes.with(8)

      expect(described_class.wrap(item)).to be item
    end
  end

  describe "equality" do
    # By value rather than by identity: matching by object is what let
    # `CORE - [SomeGuideline]` silently remove nothing once the core held a
    # configured entry instead of a bare class.
    it "is equal to a separately built item over the same guideline and configuration" do
      one = guidelines::MinimumNotes.with(8)
      another = guidelines::MinimumNotes.with(8)

      expect(one).to eq another
      expect(one).not_to be another
    end

    it "differs when the configuration differs" do
      expect(guidelines::MinimumNotes.with(8)).not_to eq guidelines::MinimumNotes.with(3)
    end

    it "differs when the guideline differs" do
      expect(guidelines::MinimumNotes.with(8)).not_to eq guidelines::MaximumNotes.with(8)
    end

    it "hashes by value, so equal items collapse in a set" do
      items = [guidelines::MinimumNotes.with(8), guidelines::MinimumNotes.with(8)]

      expect(items.uniq.length).to eq 1
    end
  end

  describe "immutability" do
    subject(:item) do
      guidelines::LargeLeaps.with(
        minimum: :perfect_fourth,
        recovery: %i[consonant_triad any_step],
        descending: {minimum: :perfect_fourth}
      )
    end

    it { is_expected.to be_frozen }

    # Freezing the item alone would be a promise it does not keep. Items are
    # built once at load and shared between guides, so a mutable value inside
    # config would let one caller corrupt every guide reusing a core -- and
    # change the hash of an object that reports itself frozen.
    it "freezes the configuration through nested values" do
      expect(item.config).to be_frozen
      expect(item.config[:recovery]).to be_frozen
      expect(item.config[:descending]).to be_frozen
    end

    it "refuses a mutation that would corrupt every guide sharing it" do
      expect { item.config[:recovery] << :injected }.to raise_error(FrozenError)
    end
  end

  describe "#name" do
    it "reports the guideline it wraps" do
      expect(guidelines::MinimumNotes.with(8).name).to eq guidelines::MinimumNotes.name
    end
  end
end
