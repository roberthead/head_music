require "spec_helper"

describe HeadMusic::Notation::MEI::MeasureLength do
  let(:meter) { HeadMusic::Rudiment::Meter.get("4/4") }

  def measure(index, implicit: false)
    HeadMusic::Notation::MEI::PartReading::Measure.new(index: index, meter: meter, implicit: implicit, clefs: {})
  end

  def content(extent, kind: :note)
    entry = HeadMusic::Notation::MEI::LayerReader::Entry.new(kind: kind)
    HeadMusic::Notation::MEI::LayerReader::Content.new(entries: [entry], extent: extent)
  end

  def element(xml)
    REXML::Document.new(xml).root
  end

  describe ".extent" do
    let(:beside_a_rest) { [content(Rational(1, 2)), content(nil, kind: :m_rest)] }

    it "is how far the part's longest layer reaches" do
      expect(described_class.extent([content(Rational(1, 2)), content(Rational(3, 4))], measure(1))).to eq Rational(3, 4)
    end

    it "pads a short layer beside a whole-bar rest to the meter" do
      expect(described_class.extent(beside_a_rest, measure(1))).to eq 1
    end

    it "pads neither the first measure nor a short one" do
      expect([described_class.extent(beside_a_rest, measure(0)), described_class.extent(beside_a_rest, measure(1, implicit: true))])
        .to eq [Rational(1, 2), Rational(1, 2)]
    end

    it "has no extent for a part with no layers" do
      expect(described_class.extent([], measure(1))).to be_nil
    end
  end

  describe ".short?" do
    it "is a measure after the first with metcon=\"false\"" do
      short = element(%(<measure metcon="false"/>))
      expect([described_class.short?(short, 1), described_class.short?(short, 0), described_class.short?(element("<measure/>"), 1)])
        .to eq [true, false, false]
    end
  end

  describe ".pickup?" do
    it "is a first measure that says it is an upbeat" do
      expect(described_class.pickup?(element(%(<measure type="upbeat"/>)), meter, [1])).to be true
    end

    it "is a first measure whose every part is shorter than its meter" do
      expect([described_class.pickup?(element("<measure/>"), meter, [Rational(1, 4), nil]), described_class.pickup?(element("<measure/>"), meter, [Rational(1, 4), 1])])
        .to eq [true, false]
    end

    it "is not a first measure with no music" do
      expect(described_class.pickup?(element("<measure/>"), meter, [nil])).to be false
    end
  end
end
