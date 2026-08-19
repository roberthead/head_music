require "spec_helper"

describe HeadMusic::Rudiment::QualifiedDiatonicContext do
  describe "the contract it leaves to subclasses" do
    it "has no default qualifier of its own" do
      expect { described_class.default_qualifier }.to raise_error(NotImplementedError)
    end

    it "has no valid qualifiers of its own" do
      expect { described_class.valid_qualifiers }.to raise_error(NotImplementedError)
    end

    it "has no message for an invalid qualifier of its own" do
      expect { described_class.invalid_qualifier_message }.to raise_error(NotImplementedError)
    end

    it "cannot be fetched directly, since it cannot name a default qualifier" do
      expect { described_class.get("C") }.to raise_error(NotImplementedError)
    end
  end

  describe "the behavior it gives its subclasses" do
    subject(:context) { subclass.get("D lydian") }

    let(:subclass) do
      stub_const("ExampleContext", Class.new(described_class) do
        def self.default_qualifier
          :ionian
        end

        def self.valid_qualifiers
          %i[ionian dorian lydian]
        end

        def self.invalid_qualifier_message
          "Qualifier must be ionian, dorian, or lydian"
        end
      end)
    end

    its(:tonic_spelling) { is_expected.to eq "D" }
    its(:qualifier) { is_expected.to eq :lydian }
    its(:name) { is_expected.to eq "D lydian" }
    its(:to_s) { is_expected.to eq "D lydian" }
    its(:scale_type) { is_expected.to eq HeadMusic::Rudiment::ScaleType.get(:lydian) }

    it "returns the same instance for the same identifier" do
      expect(subclass.get("D lydian")).to be context
    end

    it "returns the instance it is given" do
      expect(subclass.get(context)).to be context
    end

    it "tolerates surrounding and repeated whitespace" do
      expect(subclass.get("  D   lydian  ")).to eq context
    end

    it "reads the qualifier case-insensitively" do
      expect(subclass.get("D LYDIAN").qualifier).to eq :lydian
    end

    context "when the qualifier is omitted" do
      it "falls back to the default qualifier" do
        expect(subclass.get("D").qualifier).to eq :ionian
      end
    end

    context "when the qualifier is not one the subclass allows" do
      it "raises with the subclass's message" do
        expect { subclass.new("D", "phrygian") }
          .to raise_error(ArgumentError, "Qualifier must be ionian, dorian, or lydian")
      end
    end

    describe "#==" do
      it "equals another context with the same tonic and qualifier" do
        expect(context).to eq subclass.new("D", "lydian")
      end

      it "equals the identifier it was built from" do
        expect(context).to eq "D lydian"
      end

      it "differs from the same tonic under another qualifier" do
        expect(context).not_to eq "D dorian"
      end

      it "differs from the same qualifier on another tonic" do
        expect(context).not_to eq "E lydian"
      end
    end
  end
end
