require "spec_helper"

describe HeadMusic::Analysis::PitchSpeller::KeyCenters do
  let(:input) { HeadMusic::Analysis::NoteInput.for([[60, 0, 1], [61, 1, 1]], meter: "4/4") }

  def region(bar_number, onset, key)
    HeadMusic::Analysis::KeyRegion.new(bar_number: bar_number, onset: onset, key: key)
  end

  describe "#at" do
    it "answers the center of the region in force at an onset" do
      key_centers = described_class.new(input, key: [region(1, 0r, "C major"), region(2, 1r, "D major")])
      expect([key_centers.at(1r / 2).center, key_centers.at(1r).center]).to eq [2, 4]
    end

    it "answers C major's center where there are no regions" do
      empty = HeadMusic::Analysis::NoteInput.for([[60, 0, 0]], meter: "4/4")
      expect(described_class.new(empty, key: :infer).at(0r).center).to eq 2
    end
  end

  describe "#regions" do
    it "places a single key at the first bar" do
      regions = described_class.new(input, key: "A minor").regions
      expect(regions.map { |each| [each.bar_number, each.onset, each.key.name] }).to eq [[1, 0r, "A minor"]]
    end

    it "infers regions with the key finder's options" do
      expect(described_class.new(input, key: :infer, window: 1).regions)
        .to eq HeadMusic::Analysis::KeyFinder.new(input, window: 1).regions
    end

    it "refuses the key finder's options for a key given" do
      expect { described_class.new(input, key: "C major", window: 1) }.to raise_error(ArgumentError, /apply only to key: :infer/)
    end

    it "refuses an unknown key" do
      expect { described_class.new(input, key: "H major") }.to raise_error(ArgumentError)
    end
  end
end
