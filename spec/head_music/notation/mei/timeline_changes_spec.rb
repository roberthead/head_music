require "spec_helper"

describe HeadMusic::Notation::MEI::TimelineChanges do
  def whole_notes(count, **options)
    HeadMusic::Content::Flow.new(**options).tap do |flow|
      voice = flow.add_voice
      count.times { |index| voice.place("#{index + 1}:1", :whole, "C4") }
    end
  end

  def transposed(project)
    layout = project.add_layout(concert_pitch: false)
    parse_mei(HeadMusic::Notation::MEI.render(layout.realize(project.flows.first), transposed: true))
  end

  describe "a key and meter change" do
    let(:document) { parse_mei(LilyPondFixtures.key_and_meter_change.to_mei) }

    it "writes a score definition before the changed bar" do
      expect(mei_attributes(document, "//mei:section/mei:scoreDef", "xml:id", "keysig", "meter.count", "meter.unit"))
        .to eq [%w[m1-scoredef-b3 2s 3 4]]
    end

    it "places it just before that bar's measure" do
      expect(mei_element(document, "//mei:section/mei:scoreDef/following-sibling::mei:measure[1]").attributes["n"]).to eq "3"
    end

    it "writes no staff definition where no staff changes" do
      expect(mei_elements(document, "//mei:section/mei:staffDef")).to eq []
    end
  end

  it "writes a meter change alone without a key" do
    flow = whole_notes(2).tap { |meter_flow| meter_flow.change_meter(2, "2/4") }
    expect(mei_attributes(parse_mei(flow.to_mei), "//mei:section/mei:scoreDef", "keysig", "meter.count")).to eq [[nil, "2"]]
  end

  describe "clef changes" do
    let(:document) { parse_mei(MuseScoreFixtures.clef_changes.to_mei) }

    it "writes a staff definition with the new clef for the staff that changes" do
      expect(mei_attributes(document, "//mei:section/mei:staffDef", "xml:id", "n"))
        .to eq [%w[m1-staffdef-b3s2 2], %w[m1-staffdef-b5s2 2]]
      expect(mei_attributes(document, "//mei:section/mei:staffDef/mei:clef", "shape", "line")).to eq [%w[C 4], %w[F 4]]
    end
  end

  describe "a tempo change" do
    let(:flow) do
      whole_notes(3, tempo: "q = 100").tap { |flow| flow.change_tempo(2, "dotted quarter = 60") }
    end

    let(:document) { parse_mei(flow.to_mei) }

    it "writes a tempo control event in quarters per minute and in the tempo's own unit" do
      expect(mei_attributes(document, "//mei:measure[@n='2']/mei:tempo", "tstamp", "staff", "midi.bpm", "mm", "mm.unit", "mm.dots"))
        .to eq [%w[1 1 90 60 4 1]]
    end

    it "leaves the opening tempo to the score definition" do
      expect(mei_elements(document, "//mei:tempo").length).to eq 1
    end

    it "writes no dots for an undotted unit" do
      flow.change_tempo(3, "q = 72")
      expect(mei_attributes(parse_mei(flow.to_mei), "//mei:measure[@n='3']/mei:tempo", "mm", "mm.dots")).to eq [["72", nil]]
    end
  end

  describe "instrument changes" do
    let(:project) { MuseScoreFixtures.clarinet_changes }

    context "with concert pitch" do
      let(:document) { parse_mei(project.flows.first.to_mei) }

      it "writes a staff definition with the new instrument" do
        expect(mei_attributes(document, "//mei:section/mei:staffDef/mei:instrDef", "xml:id", "midi.instrnum"))
          .to eq [%w[m1-instrdef-b3s1 71], %w[m1-instrdef-b5s1 73]]
      end

      it "writes no transposition or staff key" do
        expect(mei_elements(document, "//mei:staffDef[@trans.semi or @trans.diat or @keysig]")).to eq []
      end
    end

    context "when transposed" do
      let(:document) { transposed(project) }

      it "opens with the B-flat clarinet's written key and transposition" do
        expect(mei_attributes(document, "//mei:scoreDef/mei:staffGrp/mei:staffDef", "keysig", "trans.diat", "trans.semi"))
          .to eq [%w[2s -1 -2]]
      end

      it "keeps the score definition's key at concert pitch" do
        expect(mei_attributes(document, "//mei:score/mei:scoreDef", "keysig")).to eq ["0"]
      end

      it "changes the written key and transposition with each instrument, and resets them for the flute" do
        expect(mei_attributes(document, "//mei:section/mei:staffDef", "n", "keysig", "trans.diat", "trans.semi"))
          .to eq [%w[1 3f -2 -3], %w[1 0 0 0]]
      end
    end

    it "writes the octaves of a bass clarinet's transposition" do
      document = transposed(LayoutFixtures.clarinet_project(instrument: "bass_clarinet"))
      expect(mei_attributes(document, "//mei:staffDef", "trans.diat", "trans.semi")).to eq [%w[-8 -14]]
    end

    it "writes no staff definition for a concert change to an instrument with no MIDI program" do
      flow = whole_notes(2).tap { |flutes| flutes.parts.first.change_instrument(2, "flute") }
      allow(HeadMusic::Notation::MEI::ScoreDefWriter).to receive(:instr_def_attributes).and_return(nil)
      expect(mei_elements(parse_mei(flow.to_mei), "//mei:section/mei:staffDef")).to eq []
    end
  end

  describe "a key change in a transposed trio" do
    let(:project) { LayoutFixtures.trio.tap { |trio| trio.flows.first.change_key_signature(2, "G major") } }
    let(:document) { transposed(project) }

    it "writes the concert key on the score definition" do
      expect(mei_attributes(document, "//mei:section/mei:scoreDef", "keysig")).to eq ["1s"]
    end

    it "restates the key of each staff that reads in another" do
      expect(mei_attributes(document, "//mei:section/mei:staffDef", "n", "keysig")).to eq [%w[2 3s], %w[3 2s]]
    end

    it "opens each transposing staff in its own key" do
      expect(mei_attributes(document, "//mei:scoreDef/mei:staffGrp/mei:staffDef", "keysig")).to eq [nil, "2s", "1s"]
    end
  end
end
