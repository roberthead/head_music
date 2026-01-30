require "spec_helper"

describe HeadMusic::Content::CantusFirmus::Example do
  describe ".all" do
    subject(:examples) { described_class.all }

    it "returns an array of examples" do
      expect(examples).to be_an(Array)
      expect(examples).to all(be_a(described_class))
    end

    it "includes examples from multiple sources" do
      sources = examples.map(&:source).uniq
      expect(sources.length).to be > 1
    end

    it "returns 23 examples" do
      expect(examples.length).to eq(23)
    end
  end

  describe ".by_source" do
    context "with a Source object" do
      let(:source) { HeadMusic::Content::CantusFirmus::Source.get(:fux) }
      subject(:examples) { described_class.by_source(source) }

      it "returns examples from that source" do
        expect(examples).to all(have_attributes(source: source))
      end

      it "returns 7 examples from Fux" do
        expect(examples.length).to eq(7)
      end
    end

    context "with a source identifier string" do
      subject(:examples) { described_class.by_source("Fux") }

      it "returns examples from that source" do
        expect(examples.length).to eq(7)
      end
    end

    context "with a source key symbol" do
      subject(:examples) { described_class.by_source(:schoenberg) }

      it "returns examples from that source" do
        expect(examples.length).to eq(2)
      end
    end

    context "with an unknown source" do
      subject(:examples) { described_class.by_source("unknown") }

      it "returns an empty array" do
        expect(examples).to eq([])
      end
    end
  end

  describe ".sources" do
    subject(:sources) { described_class.sources }

    it "returns unique sources from examples" do
      expect(sources).to be_an(Array)
      expect(sources).to all(be_a(HeadMusic::Content::CantusFirmus::Source))
    end

    it "returns 4 unique sources" do
      expect(sources.length).to eq(4)
    end
  end

  describe ".by_mode" do
    context "with a string mode name" do
      subject(:examples) { described_class.by_mode("dorian") }

      it "returns examples in that mode" do
        expect(examples).to all(have_attributes(mode: :dorian))
      end

      it "returns at least one example" do
        expect(examples.length).to be >= 1
      end
    end

    context "with a symbol mode name" do
      subject(:examples) { described_class.by_mode(:ionian) }

      it "returns examples in that mode" do
        expect(examples).to all(have_attributes(mode: :ionian))
      end
    end

    context "with capitalized mode name" do
      subject(:examples) { described_class.by_mode("Dorian") }

      it "normalizes and returns matching examples" do
        expect(examples).to all(have_attributes(mode: :dorian))
      end
    end
  end

  describe ".by_tonal_center" do
    subject(:examples) { described_class.by_tonal_center("D") }

    it "returns examples with that tonal center" do
      expect(examples).to all(have_attributes(tonal_center: "D"))
    end

    it "returns at least one example" do
      expect(examples.length).to be >= 1
    end
  end

  describe "instance attributes" do
    subject(:example) { described_class.all.first }

    describe "#source" do
      it "returns a Source object" do
        expect(example.source).to be_a(HeadMusic::Content::CantusFirmus::Source)
      end
    end

    describe "#tonal_center" do
      it "returns the tonal center" do
        expect(example.tonal_center).to be_a(String)
      end
    end

    describe "#mode" do
      it "returns the mode as a symbol" do
        expect(example.mode).to be_a(Symbol)
      end
    end

    describe "#pitches" do
      it "returns an array of pitch strings" do
        expect(example.pitches).to be_an(Array)
        expect(example.pitches).to all(be_a(String))
      end

      it "contains valid pitch names" do
        expect(example.pitches.first).to match(/^[A-G]/)
      end
    end

    describe "#length" do
      it "returns the number of pitches" do
        expect(example.length).to eq(example.pitches.length)
      end
    end
  end

  describe "#to_s" do
    subject(:example) { described_class.all.first }

    it "returns a descriptive string" do
      expect(example.to_s).to include(example.tonal_center)
      expect(example.to_s).to include(example.mode.to_s)
      expect(example.to_s).to include(example.source.to_s)
    end
  end

  describe "first Fux example (D dorian)" do
    subject(:example) { described_class.by_source(:fux).first }

    it "has the expected attributes" do
      expect(example.tonal_center).to eq("D")
      expect(example.mode).to eq(:dorian)
      expect(example.pitches).to eq(%w[D F E D G F A G F E D])
      expect(example.length).to eq(11)
    end
  end
end
