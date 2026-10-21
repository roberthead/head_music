require "spec_helper"

describe HeadMusic::Notation::Kern::TempoReader do
  it "reads quarter notes per minute" do
    tempo = described_class.tempo("*MM100")
    expect([tempo.beat_value.to_s, tempo.beats_per_minute]).to eq ["quarter", 100.0]
  end

  it "reads a fractional tempo" do
    expect(described_class.tempo("*MM72.5").beats_per_minute).to eq 72.5
  end

  it "recognizes a tempo in numbers or words, but not words that would start a ramp or restore a tempo" do
    expect(["*MM100", "*MM[Andante]", "*MM[rit.]", "*MM[a tempo]", "*MM[ ]", "*M4/4"].map { |field| described_class.tempo?(field) })
      .to eq [true, true, false, false, false, false]
  end

  it "reads tempo words as a tempo with text and no written number" do
    tempo = described_class.tempo("*MM[Andante con moto]")
    expect([tempo.text, tempo.metronome_mark?, tempo.beats_per_minute]).to eq ["Andante con moto", false, 78.0]
  end

  it "writes a tempo's words before its number" do
    expect(described_class.tempo_fields(HeadMusic::Rudiment::Tempo.new("quarter", 96, text: "Meno mosso"))).to eq ["*MM[Meno mosso]", "*MM96"]
  end

  it "writes only the words of a tempo whose number was not written" do
    expect(described_class.tempo_fields(HeadMusic::Rudiment::Tempo.for_text("Adagio [sic]\tassai"))).to eq ["*MM[Adagio (sic) assai]"]
  end

  it "writes only the number of a tempo with no words" do
    expect(described_class.tempo_fields(HeadMusic::Rudiment::Tempo.new("quarter", 100))).to eq ["*MM100"]
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
