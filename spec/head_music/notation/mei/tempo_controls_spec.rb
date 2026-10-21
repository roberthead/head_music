require "spec_helper"

describe HeadMusic::Notation::MEI::TempoControls do
  def whole_notes(count, **options)
    HeadMusic::Content::Flow.new(**options).tap do |flow|
      voice = flow.add_voice
      count.times { |index| voice.place("#{index + 1}:1", :whole, "C4") }
    end
  end

  def tempos(flow, *names)
    mei_attributes(parse_mei(flow.to_mei), "//mei:tempo", *names)
  end

  def texts(flow)
    mei_elements(parse_mei(flow.to_mei), "//mei:tempo").map(&:text)
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

    it "leaves an opening quarter-note tempo with no text to the score definition" do
      expect(mei_elements(document, "//mei:tempo").length).to eq 1
    end

    it "writes no dots for an undotted unit" do
      flow.change_tempo(3, "q = 72")
      expect(mei_attributes(parse_mei(flow.to_mei), "//mei:measure[@n='3']/mei:tempo", "mm", "mm.dots")).to eq [["72", nil]]
    end
  end

  describe "tempo text" do
    it "writes a change's text, with its @mm" do
      flow = whole_notes(2).tap { |changed| changed.change_tempo(2, HeadMusic::Rudiment::Tempo.new("quarter", 96, text: "Meno mosso")) }
      expect([tempos(flow, "mm", "midi.bpm"), texts(flow)]).to eq [[%w[96 96]], ["Meno mosso"]]
    end

    it "leaves @mm out where the number was not written" do
      flow = whole_notes(2).tap { |changed| changed.change_tempo(2, HeadMusic::Rudiment::Tempo.for_text("Andante")) }
      expect([tempos(flow, "mm", "mm.unit", "midi.bpm"), texts(flow)]).to eq [[[nil, nil, "78"]], ["Andante"]]
    end

    it "writes a <tempo> in the first bar for an opening tempo with text" do
      flow = whole_notes(1, tempo: HeadMusic::Rudiment::Tempo.new("quarter", 120, text: "Allegro"))
      expect([mei_attributes(parse_mei(flow.to_mei), "//mei:measure[@n='1']/mei:tempo", "tstamp", "mm"), texts(flow)]).to eq [[%w[1 120]], ["Allegro"]]
    end

    it "writes a <tempo> in the first bar for an opening tempo in a beat other than a quarter" do
      flow = whole_notes(1, meter: "6/8", tempo: "dotted quarter = 60")
      expect(tempos(flow, "mm", "mm.unit", "mm.dots")).to eq [%w[60 4 1]]
    end
  end

  describe "ramps" do
    let(:flow) do
      whole_notes(3).tap do |ramped|
        ramped.add_tempo_ramp(from: "1:3", to: "2:1", to_tempo: HeadMusic::Rudiment::Tempo.new("quarter", 80), text: "rit.")
        ramped.add_a_tempo("2:3")
        ramped.add_tempo_ramp(from: "3:1", to: "4:1")
      end
    end

    it "writes a ramp as a continuous <tempo> to its @tstamp2, and its target where it ends" do
      expect(tempos(flow, "xml:id", "func", "tstamp", "tstamp2", "mm")).to eq [
        ["m1-tempo-ramp-b1c3", "continuous", "3", "1m+1", nil], ["m1-tempo-b2c1", nil, "1", nil, "80"],
        ["m1-tempo-atempo-b2c3", nil, "3", nil, nil], ["m1-tempo-ramp-b3c1", "continuous", "1", "0m+5", nil]
      ]
    end

    it "writes each ramp's text, a ramp with none as its direction, and \"a tempo\"" do
      expect(texts(flow)).to eq ["rit.", nil, "a tempo", "rit."]
    end

    it "writes a target at the final barline in the last bar, at the beat after its last" do
      flow = whole_notes(1).tap { |ramped| ramped.add_tempo_ramp(from: "1:3", to: "2:1", to_tempo: HeadMusic::Rudiment::Tempo.new("quarter", 80)) }
      expect(mei_attributes(parse_mei(flow.to_mei), "//mei:measure[@n='1']/mei:tempo", "tstamp", "mm")).to eq [["3", nil], %w[5 80]]
    end
  end
end
