require "spec_helper"

describe HeadMusic::Notation::Kern::TempoReader do
  it "reads quarter notes per minute" do
    tempo = described_class.tempo("*MM100")
    expect([tempo.beat_value.to_s, tempo.beats_per_minute]).to eq ["quarter", 100.0]
  end

  it "reads a fractional tempo" do
    expect(described_class.tempo("*MM72.5").beats_per_minute).to eq 72.5
  end

  it "recognizes a numeric tempo only" do
    expect(%w[*MM100 *MM[Andante] *M4/4].map { |field| described_class.tempo?(field) }).to eq [true, false, false]
  end

  it "writes a quarter-note tempo" do
    expect(described_class.tempo_field(HeadMusic::Rudiment::Tempo.new("quarter", 100))).to eq "*MM100"
  end

  it "converts another beat value to quarter notes per minute" do
    expect(described_class.tempo_field(HeadMusic::Rudiment::Tempo.new("dotted quarter", 60))).to eq "*MM90"
  end

  it "keeps a fractional tempo" do
    expect(described_class.tempo_field(HeadMusic::Rudiment::Tempo.new("half", 36.25))).to eq "*MM72.5"
  end
end
