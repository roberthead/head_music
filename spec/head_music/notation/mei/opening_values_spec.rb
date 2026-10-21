require "spec_helper"

describe HeadMusic::Notation::MEI::OpeningValues do
  def flow(score_def, music: mei_note("C4", "1"))
    HeadMusic::Notation::MEI.parse(mei_document(mei_staff(1, music), score_def: score_def))
  end

  def staff_grp(attributes = "", inside = "")
    %(<staffGrp><staffDef n="1" lines="5"#{attributes}>#{inside}<clef shape="G" line="2"/></staffDef></staffGrp>)
  end

  describe "the key" do
    {
      %(keysig="2f") => "B♭ major",
      %(key.sig="3s") => "A major",
      %(keysig="1f" key.mode="minor") => "D minor",
      %(keysig="0" key.mode="dorian") => "D dorian",
      %(keysig="1s" key.pname="e") => "E minor"
    }.each do |attributes, name|
      it "reads #{attributes} as #{name}" do
        expect(flow(%(<scoreDef #{attributes} meter.count="4" meter.unit="4">#{staff_grp}</scoreDef>)).key_signature.name).to eq name
      end
    end

    it "reads a <keySig> child" do
      expect(flow(%(<scoreDef><keySig sig="1f" mode="minor"/>#{staff_grp}</scoreDef>)).key_signature.name).to eq "D minor"
    end

    it "reads the first staff definition's key where the scoreDef states none" do
      expect(flow(%(<scoreDef>#{staff_grp(%( keysig="4s"))}</scoreDef>)).key_signature.name).to eq "E major"
    end
  end

  describe "the meter" do
    it "reads @meter.count and @meter.unit, and a <meterSig>" do
      meters = [%(<scoreDef meter.count="6" meter.unit="8">), %(<scoreDef><meterSig count="3" unit="2"/>)].map do |opening|
        flow("#{opening}#{staff_grp}</scoreDef>", music: "<mRest/>").meter.to_s
      end
      expect(meters).to eq %w[6/8 3/2]
    end

    it "reads it from the staff definitions, as MuseScore writes it" do
      expect(flow(%(<scoreDef>#{staff_grp(%( meter.count="2" meter.unit="4"))}</scoreDef>), music: "<mRest/>").meter.to_s).to eq "2/4"
    end

    it "reads a meter symbol alone as 4/4 or 2/2, keeping the symbol" do
      meters = %w[common cut].map { |symbol| flow(%(<scoreDef meter.sym="#{symbol}">#{staff_grp}</scoreDef>)).meter }
      expect(meters.map { |meter| [meter.to_s, meter.symbol] }).to eq [["4/4", :common], ["2/2", :cut]]
    end

    it "keeps @meter.sym beside the numerals it agrees with, and a <meterSig @sym>" do
      meters = [%(<scoreDef meter.count="4" meter.unit="4" meter.sym="common">), %(<scoreDef><meterSig count="2" unit="2" sym="cut"/>)].map do |opening|
        flow("#{opening}#{staff_grp}</scoreDef>").meter
      end
      expect(meters.map { |meter| [meter.to_s, meter.symbol] }).to eq [["4/4", :common], ["2/2", :cut]]
    end

    it "keeps the numerals and drops a symbol that disagrees with them, or that names no meter" do
      meters = [%(<scoreDef meter.count="3" meter.unit="4" meter.sym="common">), %(<scoreDef meter.count="4" meter.unit="4" meter.sym="norm">)].map do |opening|
        flow("#{opening}#{staff_grp}</scoreDef>", music: "<mRest/>").meter
      end
      expect(meters.map { |meter| [meter.to_s, meter.symbol] }).to eq [["3/4", nil], ["4/4", nil]]
    end
  end

  it "reads @midi.bpm as a quarter-note tempo" do
    tempo = flow(%(<scoreDef midi.bpm="72.5">#{staff_grp}</scoreDef>)).tempo
    expect([tempo.beat_value.to_s, tempo.beats_per_minute]).to eq ["quarter", 72.5]
  end
end
