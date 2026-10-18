require "spec_helper"

describe HeadMusic::Notation::MEI::TupletSpans do
  describe described_class::Run do
    let(:triplet) { HeadMusic::Rudiment::TupletRatio.get([3, 2]) }
    let(:track) { Object.new }
    let(:quintuplet) { HeadMusic::Rudiment::TupletRatio.get([5, 4]) }
    let(:entry_class) { Struct.new(:rhythmic_value, :track, :event) }
    let(:value_class) { Struct.new(:tuplet_ratio) }

    def entry(ratio = triplet, track: self.track, event: Object.new)
      entry_class.new(value_class.new(ratio), track, event)
    end

    describe "#scaling" do
      it "is its own ratio where it has one" do
        expect(described_class.new(triplet, [entry(nil)]).scaling).to eq triplet
      end

      it "is the ratio every entry shares where it has none" do
        expect(described_class.new(nil, [entry, entry]).scaling).to eq triplet
      end

      it "is nil for entries scaled differently, or for none" do
        expect([described_class.new(nil, [entry, entry(quintuplet)]).scaling, described_class.new(triplet, []).scaling]).to eq [nil, nil]
      end

      it "is nil where only some entries are scaled, in either order" do
        expect([[entry, entry(nil)], [entry(nil), entry]].map { |entries| described_class.new(nil, entries).scaling }).to eq [nil, nil]
      end
    end

    describe "#placed?" do
      it "is true where one voice reads every entry" do
        expect(described_class.new(nil, [entry, entry]).placed?).to be true
      end

      it "is false where a voice reads one entry and not another" do
        expect(described_class.new(nil, [entry, entry(event: nil)]).placed?).to be false
      end
    end

    it "answers its track and its first and last events" do
      first = entry
      last = entry
      run = described_class.new(nil, [first, entry, last])
      expect([run.track, run.ends]).to eq [track, [first.event, last.event]]
    end
  end
end
