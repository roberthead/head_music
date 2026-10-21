require "spec_helper"

describe HeadMusic::Notation::FlowTimedMarks do
  subject(:marks) { described_class.new(flow).to_a }

  let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nL:1/4\nM:4/4\nK:C\nC D E F|G A B c|\n") }
  let(:voice) { flow.voices.first }

  it "answers each dynamic level and each hairpin's start and end" do
    flow.parts.first.place_dynamic("1:1", :p)
    voice.add_span(:crescendo, from: "1:2", to: "2:1")
    expect(marks.map(&:to_s)).to eq ["dynamic p at 1:1:000", "crescendo start at 1:2:000", "crescendo end at 2:1:000"]
  end

  it "marks a part's voices for a part's mark, and only its voice for a voice's" do
    flow.parts.first.place_dynamic("1:1", :p)
    voice.place_dynamic("2:1", :f)
    expect(marks.map(&:voices)).to eq [flow.parts.first.voices, [voice]]
  end

  context "with a fermata, a tempo ramp, and an \"a tempo\"" do
    before do
      flow.add_fermata("1:4", :quarter)
      flow.add_tempo_ramp(from: "2:1", to: "2:3", text: "rit.")
      flow.add_a_tempo("2:4")
    end

    it "answers the fermata's start, the ramp's start and end, and the \"a tempo\"" do
      expect(marks.map(&:to_s)).to eq ["fermata at 1:4:000", "tempo ramp start at 2:1:000", "tempo ramp end at 2:3:000", '"a tempo" at 2:4:000']
    end

    it "marks every voice with each" do
      expect(marks.map(&:voices)).to all(eq flow.voices)
    end
  end

  describe "Mark#after?" do
    it "lets a tempo ramp's end reach the final barline" do
      flow.add_tempo_ramp(from: "2:3", to: "3:1", text: "rit.")
      expect(marks.map { |mark| mark.after?(2, flow.final_barline_position) }).to eq [false, false]
    end

    it "lets only a hairpin's end reach the final barline" do
      voice.add_span(:crescendo, from: "2:1", to: "3:1")
      final_barline = flow.final_barline_position
      expect(marks.map { |mark| mark.after?(2, final_barline) }).to eq [false, false]
    end

    it "places a mark in a later bar after the music" do
      voice.place_dynamic("3:1", :f)
      expect(marks.first.after?(2, flow.final_barline_position)).to be true
    end
  end

  describe "Mark#rounded_note" do
    let(:flow) do
      HeadMusic::Content::Flow.new.tap do |septuplets|
        voice = septuplets.add_voice
        7.times { voice.place(voice.next_position, HeadMusic::Rudiment::RhythmicValue.get(:sixteenth, tuplet: "7:4"), "C4") }
        voice.place(voice.next_position, "dotted half", "D4")
      end
    end

    it "answers the rounded note holding a mark strictly inside it" do
      voice.place_dynamic("1:1:200", :f)
      expect(marks.first.rounded_note.position.to_s).to eq "1:1:137:034"
    end

    it "answers nil for a mark at a note's onset" do
      voice.place_dynamic("1:1", :f)
      expect(marks.first.rounded_note).to be_nil
    end

    it "answers nil inside a note whose ratio lands on whole subticks" do
      voice.place_dynamic("1:3:100", :f)
      expect(marks.first.rounded_note).to be_nil
    end
  end
end
