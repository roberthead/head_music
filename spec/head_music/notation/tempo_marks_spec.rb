require "spec_helper"

describe HeadMusic::Notation::TempoMarks do
  subject(:marks) { described_class.new(flow) }

  let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/4\nK:C\nC D E F|G A B c|c B A G|F E D C|\n") }
  let(:slower) { HeadMusic::Rudiment::Tempo.new("quarter", 80) }
  let(:allegro) { HeadMusic::Rudiment::Tempo.new("quarter", 120, text: "Allegro") }

  def summary
    marks.map { |mark| [mark.kind, mark.position.to_s, mark.tempo&.beats_per_minute, mark.text] }
  end

  it "answers the opening tempo" do
    flow = HeadMusic::Content::Flow.new(tempo: allegro)
    expect(described_class.new(flow).opening).to eq allegro
  end

  context "with a tempo change, a ramp, and an \"a tempo\"" do
    before do
      flow.change_tempo(4, allegro)
      flow.add_tempo_ramp(from: "2:3", to: "3:1", to_tempo: slower, text: "rit.")
      flow.add_a_tempo("3:3")
    end

    it "answers them in time order" do
      expect(summary).to eq [
        [:ramp_start, "2:3:000", nil, "rit."], [:ramp_end, "3:1:000", 80.0, nil],
        [:a_tempo, "3:3:000", nil, "a tempo"], [:tempo, "4:1:000", 120.0, "Allegro"]
      ]
    end

    it "reads back through TempoMarkReading" do
      reread = HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/4\nK:C\nC D E F|G A B c|c B A G|F E D C|\n")
      reading = HeadMusic::Notation::TempoMarkReading.new
      marks.each { |mark| reading.add(mark.position.to_s, mark.tempo, (mark.text unless mark.kind == :tempo)) }
      reading.apply(reread)
      expect(reread.timeline.to_h).to eq flow.timeline.to_h
    end
  end

  it "orders a ramp's end, an \"a tempo\", a change, and a ramp's start at one position" do
    flow.add_tempo_ramp(from: "2:1", to: "3:1", text: "rit.")
    flow.add_a_tempo("3:1")
    flow.change_tempo(3, allegro)
    flow.add_tempo_ramp(from: "3:1", to: "4:1", text: "accel.")
    expect(summary.map(&:first).drop(1)).to eq %i[ramp_end a_tempo tempo ramp_start ramp_end]
  end

  it "writes once a change that a ramp's target already writes" do
    flow.add_tempo_ramp(from: "2:1", to: "3:1", to_tempo: slower, text: "rit.")
    flow.change_tempo(3, slower)
    expect(summary.map(&:first)).to eq %i[ramp_start ramp_end]
  end

  it "names a ramp with no text by its direction" do
    flow.add_tempo_ramp(from: "1:1", to: "2:1", to_tempo: slower)
    flow.add_tempo_ramp(from: "3:1", to: "4:1", to_tempo: allegro)
    expect(summary.select { |kind, *| kind == :ramp_start }.map(&:last)).to eq ["rit.", "accel."]
  end

  describe "#unreadable_ramps" do
    {
      "a target" => ->(flow) { flow.add_tempo_ramp(from: "1:1", to: "2:1", to_tempo: HeadMusic::Rudiment::Tempo.new("quarter", 80), text: "rit.") },
      "an \"a tempo\"" => ->(flow) { flow.add_tempo_ramp(from: "2:1", to: "2:3", text: "accel.").tap { flow.add_a_tempo("2:3") } },
      "a fermata" => ->(flow) { flow.add_tempo_ramp(from: "3:1", to: "3:4", text: "rit.").tap { flow.add_fermata("3:4", :quarter) } },
      "the next ramp" => ->(flow) { flow.add_tempo_ramp(from: "3:1", to: "3:4", text: "rit.").tap { flow.add_tempo_ramp(from: "3:4", to: "5:1") } },
      "a tempo change" => ->(flow) { flow.add_tempo_ramp(from: "3:1", to: "4:1", text: "rit.").tap { flow.change_tempo(4, HeadMusic::Rudiment::Tempo.new("quarter", 60)) } },
      "the end of the music" => ->(flow) { flow.add_tempo_ramp(from: "4:1", to: "5:1", text: "rall.") }
    }.each do |description, ramp|
      it "is empty for a ramp ending at #{description}" do
        ramp.call(flow)
        expect(marks.unreadable_ramps).to be_empty
      end
    end

    it "answers a ramp whose text is no ramp word" do
      ramp = flow.add_tempo_ramp(from: "1:1", to: "2:1", to_tempo: slower, text: "allarg.")
      expect(marks.unreadable_ramps).to eq [ramp]
    end

    it "answers a ramp with a fermata beginning inside it" do
      ramp = flow.add_tempo_ramp(from: "1:1", to: "2:1", to_tempo: slower, text: "rit.")
      flow.add_fermata("1:4", :quarter)
      expect(marks.unreadable_ramps).to eq [ramp]
    end

    it "answers a ramp with no target that ends where nothing would end it" do
      ramp = flow.add_tempo_ramp(from: "1:1", to: "2:1", text: "rit.")
      expect(marks.unreadable_ramps).to eq [ramp]
    end
  end
end
