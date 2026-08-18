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

  describe "#name and #instruction" do
    # A guideline's name is no more fixed than its violation: the same
    # guideline is called different things by the guides that configure it
    # differently.
    it "says what this guide configured, not what the guideline is in general" do
      expect(guidelines::MinimumNotes.with(8).name).to eq "Minimum of eight notes"
      expect(guidelines::MinimumNotes.with(3).name).to eq "Minimum of three notes"
    end

    # Every shipped guideline carries a name now, so this is what a newly added
    # one reads as until somebody writes it a label.
    it "reads the class name as a sentence when the locale has nothing better" do
      expect(probe_guideline(nil).with(minimum: "eight").name).to eq "Spec probe bare"
    end

    # One locale value, two readings: the label wants a capital and the
    # sentence that embeds the same word mid-clause does not.
    it "upcases a name that leads with an interpolated value" do
      item = guidelines::Contoured.with(:arch)

      expect(item.name).to eq "Arch contour"
      expect(item.violation_preview).to eq "Write a melody with the arch contour."
    end

    it "says what the locale gives it, which is not the violation" do
      item = probe_guideline("Write a melody of at least %{minimum} notes.").with(minimum: "eight")

      expect(item.instruction).to eq "Write a melody of at least eight notes."
      expect(item.violation_preview).to eq "Write at least eight notes."
    end

    # Guidelines are already phrased imperatively, so one with nothing more
    # specific to say instructs with the sentence it would complain with. Every
    # shipped guideline carries an instruction now, so this is what a newly
    # added one does until somebody writes it a sentence.
    it "instructs with the violation when there is no separate instruction" do
      item = probe_guideline(nil).with(minimum: "eight")

      expect(item.instruction).to eq "Write at least eight notes."
      expect(item.instruction).to eq item.violation_preview
    end

    # Anonymous and keyed to a stored entry, so that borrowing a shipped
    # guideline cannot change what every other spec reads for it.
    # A key of its own for each case: store_translations merges, so one entry
    # reused would keep the instruction the other example gave it.
    def probe_guideline(instruction)
      key = instruction ? "spec_probe_instructed" : "spec_probe_bare"
      entry = {violations: {default: "Write at least %{minimum} notes."}}
      entry[:instruction] = instruction if instruction
      I18n.backend.store_translations(:en, {head_music: {style: {guidelines: {key.to_sym => entry}}}})
      Class.new(HeadMusic::Style::Guideline) do
        define_singleton_method(:template_key) { key }
      end
    end
  end

  describe "removed options" do
    # An unrecognized key rides along in config and is dropped at render, so
    # ignoring message: would let a consumer's custom sentence disappear
    # without a word. It says what replaces it instead.
    it "refuses the message: option that violation_key: replaced" do
      expect { guidelines::LargeLeaps.with(message: "Recover the leap by step.") }
        .to raise_error(ArgumentError, /violation_key/)
    end

    it "still takes the option that replaced it" do
      item = guidelines::LargeLeaps.with(violation_key: "guidelines.large_leaps.violations.fux_cantus_firmus")

      expect(item.violation_preview).to eq "Recover large leaps by step in the opposite direction."
    end
  end

  describe "#inspect" do
    # Printing the class name could not tell two configurations apart.
    it "distinguishes two configurations of one guideline" do
      expect(guidelines::MinimumNotes.with(8).inspect).to include "minimum"
      expect(guidelines::MinimumNotes.with(8).inspect).not_to eq guidelines::MinimumNotes.with(3).inspect
    end
  end
end
