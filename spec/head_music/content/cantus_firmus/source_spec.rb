require "spec_helper"

describe HeadMusic::Content::CantusFirmus::Source do
  describe ".all" do
    subject(:sources) { described_class.all }

    it "returns an array of sources" do
      expect(sources).to be_an(Array)
      expect(sources).to all(be_a(described_class))
    end

    it "includes expected sources" do
      keys = sources.map(&:key)
      expect(keys).to include(:fux)
      expect(keys).to include(:schoenberg)
      expect(keys).to include(:davis_and_lybbert)
      expect(keys).to include(:clendinning_and_marvin)
    end
  end

  describe ".get" do
    context "with a symbol key" do
      subject(:source) { described_class.get(:fux) }

      it "returns the matching source" do
        expect(source).to be_a(described_class)
        expect(source.key).to eq(:fux)
      end
    end

    context "with a string key" do
      subject(:source) { described_class.get("fux") }

      it "returns the matching source" do
        expect(source.key).to eq(:fux)
      end
    end

    context "with a capitalized name" do
      subject(:source) { described_class.get("Fux") }

      it "normalizes and returns the matching source" do
        expect(source.key).to eq(:fux)
      end
    end

    context "with an ampersand name format" do
      subject(:source) { described_class.get("Clendinning & Marvin") }

      it "normalizes and returns the matching source" do
        expect(source.key).to eq(:clendinning_and_marvin)
      end
    end

    context "with a Source instance" do
      let(:original) { described_class.get(:fux) }

      it "returns the same instance" do
        expect(described_class.get(original)).to eq(original)
      end
    end

    context "with an unknown source" do
      subject(:source) { described_class.get("unknown") }

      it "returns nil" do
        expect(source).to be_nil
      end
    end
  end

  describe ".keys" do
    subject(:keys) { described_class.keys }

    it "returns an array of symbols" do
      expect(keys).to be_an(Array)
      expect(keys).to all(be_a(Symbol))
    end

    it "includes expected keys" do
      expect(keys).to include(:fux, :schoenberg)
    end
  end

  describe "instance attributes" do
    subject(:source) { described_class.get(:fux) }

    describe "#key" do
      it "returns the source key" do
        expect(source.key).to eq(:fux)
      end
    end

    describe "#publication_name" do
      it "returns the publication name" do
        expect(source.publication_name).to eq("Gradus ad Parnassum")
      end
    end

    describe "#author_names" do
      it "returns an array of author names" do
        expect(source.author_names).to eq(["Johann Joseph Fux"])
      end
    end

    describe "#notes" do
      it "returns the notes about the source" do
        expect(source.notes).to include("foundational text on counterpoint")
      end
    end

    describe "#publication_edition" do
      context "when edition is specified" do
        subject(:source) { described_class.get(:clendinning_and_marvin) }

        it "returns the edition" do
          expect(source.publication_edition).to eq("3rd")
        end
      end

      context "when edition is not specified" do
        subject(:source) { described_class.get(:fux) }

        it "returns nil" do
          expect(source.publication_edition).to be_nil
        end
      end
    end
  end

  describe "#to_s" do
    subject(:source) { described_class.get(:fux) }

    it "returns the publication name" do
      expect(source.to_s).to eq("Gradus ad Parnassum")
    end
  end
end
