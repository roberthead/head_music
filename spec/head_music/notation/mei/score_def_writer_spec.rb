require "spec_helper"

describe HeadMusic::Notation::MEI::ScoreDefWriter do
  def score_def(flow)
    plan = HeadMusic::Notation::MEI::RenderPlan.new(flow)
    lines = HeadMusic::Notation::MEI::Markup.lines(described_class.new(plan).element)
    parse_mei(%(<mei xmlns="http://www.music-encoding.org/ns/mei">#{lines.join}</mei>))
  end

  def clef(name)
    HeadMusic::Rudiment::Clef.get(name)
  end

  let(:flow) do
    HeadMusic::Content::Flow.new(key_signature: "Eb major", meter: "6/8", tempo: "dotted quarter = 60").tap do |flow|
      flow.add_voice.place("1:1", :dotted_half, "G4")
    end
  end

  it "writes the opening key, meter, and tempo" do
    expect(mei_attributes(score_def(flow), "//mei:scoreDef", "keysig", "meter.count", "meter.unit", "midi.bpm"))
      .to eq [%w[3f 6 8 90]]
  end

  it "writes a staff definition with its clef for each staff" do
    document = score_def(LilyPondFixtures.piano_and_melody)
    expect(mei_attributes(document, "//mei:staffDef", "n", "lines")).to eq [%w[1 5], %w[2 5], %w[3 5]]
    expect(mei_attributes(document, "//mei:staffDef/mei:clef", "shape", "line")).to eq [%w[G 2], %w[F 4], %w[G 2]]
  end

  it "chooses a clef from the range of the voices on an unauthored staff" do
    low = HeadMusic::Content::Flow.new.tap { |flow| flow.add_voice.place("1:1", :whole, "C3") }
    expect(mei_attributes(score_def(low), "//mei:clef", "shape")).to eq ["F"]
  end

  describe ".clef_attributes" do
    it "writes an octave clef's displacement" do
      expect(described_class.clef_attributes(clef(:vocal_tenor_clef)))
        .to eq("shape" => "G", "line" => 2, "dis" => "8", "dis.place" => "below")
    end

    it "writes a C clef on its line" do
      expect(described_class.clef_attributes(clef(:alto_clef))).to eq("shape" => "C", "line" => 3, "dis" => nil, "dis.place" => nil)
    end

    it "writes a neutral clef as percussion" do
      expect(described_class.clef_attributes(clef(:neutral_clef))).to eq("shape" => "perc")
    end
  end
end
