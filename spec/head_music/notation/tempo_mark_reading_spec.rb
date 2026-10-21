require "spec_helper"

describe HeadMusic::Notation::TempoMarkReading do
  subject(:reading) { described_class.new }

  let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/4\nK:C\nC D E F|G A B c|c B A G|F E D C|\n") }
  let(:allegro) { HeadMusic::Rudiment::Tempo.new("quarter", 120, text: "Allegro") }
  let(:slower) { HeadMusic::Rudiment::Tempo.new("quarter", 80) }

  def ramps
    flow.tempo_ramps.map { |ramp| [ramp.from.to_s, ramp.to.to_s, ramp.to_tempo&.beats_per_minute, ramp.text] }
  end

  describe ".word" do
    {
      "rit." => :ramp, "ritard." => :ramp, "ritardando" => :ramp, "rall." => :ramp, "rallentando" => :ramp,
      "accel." => :ramp, "Accelerando" => :ramp, "stringendo" => :ramp, "poco rit." => :ramp, "molto rall." => :ramp,
      "a tempo" => :a_tempo, "Tempo primo" => :a_tempo, "Tempo I" => :a_tempo,
      "dolce" => nil, "Tempo II" => nil, "ritmico" => nil, "" => nil
    }.each do |text, kind|
      it "reads #{text.inspect} as #{kind.inspect}" do
        expect(described_class.word(text)).to eq kind
      end
    end
  end

  describe "a tempo mark at a downbeat" do
    it "changes the tempo" do
      reading.add(flow.position("2:1"), slower)
      reading.apply(flow)
      expect(flow.tempo_changes).to eq(2 => slower)
    end

    it "makes no change where it restates the tempo in force" do
      reading.add(flow.position("1:1"), HeadMusic::Rudiment::Tempo.new("quarter", 120))
      reading.apply(flow)
      expect(flow.tempo_changes).to be_empty
    end

    it "keeps its text" do
      reading.add(flow.position("3:1"), allegro)
      reading.apply(flow)
      expect(flow.tempo_at(3).text).to eq "Allegro"
    end
  end

  it "drops a tempo mark in the middle of a bar that ends no ramp" do
    reading.add(flow.position("2:3"), slower)
    reading.apply(flow)
    expect(flow.tempo_changes).to be_empty
  end

  it "drops other free text" do
    reading.add(flow.position("2:3"), nil, "dolce")
    reading.apply(flow)
    expect([flow.tempo_changes, flow.tempo_ramps, flow.a_tempos]).to all(be_empty)
  end

  describe "a ramp word" do
    it "starts a ramp that ends at the next tempo mark, its target" do
      reading.add(flow.position("2:3"), nil, "rit.")
      reading.add(flow.position("3:1"), slower)
      reading.apply(flow)
      expect([ramps, flow.tempo_changes]).to eq [[["2:3:000", "3:1:000", 80.0, "rit."]], {}]
    end

    it "ends at a target in the middle of a bar" do
      reading.add(flow.position("2:1"), nil, "rit.")
      reading.add(flow.position("2:3"), slower)
      reading.apply(flow)
      expect(ramps).to eq [["2:1:000", "2:3:000", 80.0, "rit."]]
    end

    it "ends at the next \"a tempo\", which restores the tempo before it" do
      reading.add(flow.position("2:1"), nil, "rall.")
      reading.add(flow.position("3:2"), nil, "a tempo")
      reading.apply(flow)
      expect([ramps, flow.a_tempos.map { |a_tempo| [a_tempo.position.to_s, a_tempo.text] }])
        .to eq [[["2:1:000", "3:2:000", nil, "rall."]], [["3:2:000", "a tempo"]]]
    end

    it "ends at the next fermata" do
      flow.add_fermata("3:4", :quarter)
      reading.add(flow.position("3:1"), nil, "rit.")
      reading.apply(flow)
      expect(ramps).to eq [["3:1:000", "3:4:000", nil, "rit."]]
    end

    it "ends at the next ramp word" do
      reading.add(flow.position("2:1"), nil, "accel.")
      reading.add(flow.position("3:1"), nil, "rit.")
      reading.apply(flow)
      expect(ramps).to eq [["2:1:000", "3:1:000", nil, "accel."], ["3:1:000", "5:1:000", nil, "rit."]]
    end

    it "ends at the end of the music" do
      reading.add(flow.position("4:3"), nil, "rit.")
      reading.apply(flow)
      expect(ramps).to eq [["4:3:000", "5:1:000", nil, "rit."]]
    end

    it "starts after a tempo mark at the same position, which sets its starting tempo" do
      reading.add(flow.position("2:1"), nil, "rit.")
      reading.add(flow.position("2:1"), slower)
      reading.apply(flow)
      expect([ramps, flow.tempo_changes]).to eq [[["2:1:000", "5:1:000", nil, "rit."]], {2 => slower}]
    end

    it "reads from a tempo of words alone" do
      reading.add(flow.position("4:1"), HeadMusic::Rudiment::Tempo.for_text("rit."))
      reading.apply(flow)
      expect([ramps, flow.tempo_changes]).to eq [[["4:1:000", "5:1:000", nil, "rit."]], {}]
    end

    it "ends at a written end" do
      reading.add(flow.position("2:1"), nil, "rit.")
      reading.add_ramp_end(flow.position("3:2"))
      reading.apply(flow)
      expect(ramps).to eq [["2:1:000", "3:2:000", nil, "rit."]]
    end

    it "takes its target from a tempo mark at its written end" do
      reading.add(flow.position("2:1"), nil, "rit.")
      reading.add_ramp_end(flow.position("3:1"))
      reading.add(flow.position("3:1"), slower)
      reading.apply(flow)
      expect([ramps, flow.tempo_changes]).to eq [[["2:1:000", "3:1:000", 80.0, "rit."]], {}]
    end

    it "is dropped at the end of the music, where no ramp can run" do
      reading.add(flow.final_barline_position, nil, "rit.")
      reading.apply(flow)
      expect(ramps).to be_empty
    end
  end

  it "keeps a tempo change after a ramp that differs from its target" do
    reading.add(flow.position("2:1"), nil, "rit.")
    reading.add(flow.position("3:1"), slower)
    reading.add(flow.position("3:1"), allegro)
    reading.apply(flow)
    expect([ramps, flow.tempo_changes]).to eq [[["2:1:000", "3:1:000", 80.0, "rit."]], {3 => allegro}]
  end

  it "takes positions as codes" do
    reading.add("2:1", slower)
    reading.apply(flow)
    expect(flow.tempo_changes.keys).to eq [2]
  end
end
