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

  describe "the opening key's mode" do
    def key_mode(key_signature)
      flow = HeadMusic::Content::Flow.new(key_signature: key_signature).tap { |modal| modal.add_voice.place("1:1", :whole, "D4") }
      mei_attributes(score_def(flow), "//mei:scoreDef", "keysig", "key.mode")
    end

    it "writes a key's quality" do
      expect(key_mode("Eb major")).to eq [%w[3f major]]
    end

    it "writes a mode by name" do
      expect(key_mode("D dorian")).to eq [%w[0 dorian]]
    end
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

  describe "parts" do
    let(:flow) do
      HeadMusic::Content::Flow.new.tap do |flow|
        piano = flow.add_part(player: HeadMusic::Content::Player.new(name: "Pianist"), instrument: "piano",
          staff_system: HeadMusic::Content::StaffSystem.grand_staff)
        piano.add_voice(role: "right hand").place("1:1", :whole, "C5")
        flow.add_part(player: HeadMusic::Content::Player.new(name: "Clarinetist"), instrument: "clarinet")
          .add_voice.place("1:1", :whole, "D5")
      end
    end

    let(:document) { score_def(flow) }

    it "groups a part's staves under its bracket and label" do
      group = mei_element(document, "//mei:staffGrp/mei:staffGrp")
      expect([group.attributes["symbol"], group.elements["label"].text, group.get_elements("staffDef").length])
        .to eq ["brace", "Pianist", 2]
    end

    it "labels a one-staff part's staff" do
      expect(mei_element(document, "//mei:staffDef[@n='3']/mei:label").text).to eq "Clarinetist"
    end

    it "labels no staff of a part on several staves" do
      expect(mei_elements(document, "//mei:staffGrp/mei:staffGrp/mei:staffDef/mei:label")).to eq []
    end

    it "numbers each staff's General MIDI instrument from 0" do
      expect(mei_attributes(document, "//mei:staffDef/mei:instrDef", "midi.instrnum")).to eq %w[0 0 71]
    end

    it "labels each staff's instrument with its name key" do
      expect(mei_attributes(document, "//mei:staffDef/mei:instrDef", "label")).to eq %w[piano piano clarinet]
    end

    it "names each voice's role on the staff it opens on" do
      expect(mei_attributes(document, "//mei:staffDef[@n='1']/mei:layerDef", "n")).to eq ["1"]
      expect(mei_element(document, "//mei:layerDef/mei:label").text).to eq "right hand"
    end

    it "leaves the symbol out of a group with no bracket" do
      flow = HeadMusic::Content::Flow.new
      staves = Array.new(2) { HeadMusic::Content::Staff.new }
      flow.add_part(staff_system: HeadMusic::Content::StaffSystem.new(staves: staves)).add_voice.place("1:1", :whole, "C4")
      expect(mei_attributes(score_def(flow), "//mei:staffGrp/mei:staffGrp", "symbol")).to eq [nil]
    end
  end

  it "merges the attributes of its staff definition sources" do
    allow(described_class).to receive(:staff_def_attribute_sources).and_return([MEIExtensionStubs::EveryHook])
    expect(mei_attributes(score_def(flow), "//mei:staffDef", "trans.semi")).to eq ["-1"]
  end

  describe ".instr_def_attributes" do
    it "is nil for no instrument" do
      expect(described_class.instr_def_attributes(nil)).to be_nil
    end

    it "labels an instrument with no General MIDI program, and gives it none" do
      castanets = HeadMusic::Instruments::Instrument.get("castanets")
      expect(described_class.instr_def_attributes(castanets)).to eq("label" => "castanets", "midi.instrnum" => nil)
    end
  end

  describe ".clef_element and .instr_def_element" do
    let(:ids) { HeadMusic::Notation::MEI::Ids.new(1) }

    it "keys a staff definition's clef as the definition is keyed" do
      element = described_class.clef_element(ids, "s2", clef(:bass_clef))
      expect([element.name, element.id, element.attributes["shape"]]).to eq ["clef", "m1-clef-s2", "F"]
    end

    it "keys a staff definition's instrument as the definition is keyed" do
      element = described_class.instr_def_element(ids, "s1", HeadMusic::Instruments::Instrument.get("violin"))
      expect([element.name, element.id, element.attributes["label"]]).to eq ["instrDef", "m1-instrdef-s1", "violin"]
    end

    it "makes nothing for no clef or no instrument" do
      expect([described_class.clef_element(ids, "s1", nil), described_class.instr_def_element(ids, "s1", nil)]).to eq [nil, nil]
    end
  end

  describe ".clef_attributes" do
    it "writes an octave clef's displacement" do
      expect(described_class.clef_attributes(clef(:vocal_tenor_clef)))
        .to eq("shape" => "G", "line" => 2, "dis" => "8", "dis.place" => "below")
    end

    it "writes a clef an octave up as displaced above" do
      clef = instance_double(HeadMusic::Rudiment::Clef, pitch: HeadMusic::Rudiment::Pitch.get("G5"), line: 2)
      expect(described_class.clef_attributes(clef)).to include("dis" => "8", "dis.place" => "above")
    end

    it "writes a C clef on its line" do
      expect(described_class.clef_attributes(clef(:alto_clef))).to eq("shape" => "C", "line" => 3, "dis" => nil, "dis.place" => nil)
    end

    it "writes a neutral clef as percussion" do
      expect(described_class.clef_attributes(clef(:neutral_clef))).to eq("shape" => "perc")
    end
  end
end
