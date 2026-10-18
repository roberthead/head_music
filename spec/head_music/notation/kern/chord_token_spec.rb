require "spec_helper"

describe HeadMusic::Notation::Kern::ChordToken do
  def tokens(*fields)
    fields.map { |field| HeadMusic::Notation::Kern::TokenReader.read(field) }
  end

  it "answers a lone note's token as it is" do
    note = tokens("4c'").first
    expect(described_class.of_notes([note], field: "4c'")).to equal note
  end

  it "sounds a chord's pitches together with all their markings" do
    chord = described_class.of_notes(tokens("4c'", "4eT", "4g"), field: "4c' 4eT 4g")
    expect([chord.pitches.map(&:to_s), chord.articulations, chord.ornaments]).to eq [
      %w[C4 E4 G4], [:staccato], [:trill]
    ]
  end

  it "counts a slur as often as any one note has it" do
    expect(described_class.of_notes(tokens("(4c", "(4e"), field: "(4c (4e").span_marks).to eq ["("]
  end

  it "refuses chord notes of different durations, naming the field and line" do
    expect { described_class.of_notes(tokens("4c", "8e"), field: "4c 8e", line_number: 7) }
      .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /different durations are not supported: "4c 8e" \(line 7\)/)
  end

  it "ties a grace chord only where all its notes are tied" do
    expect([
      described_class.of_graces(tokens("8qc[", "8qe["), field: "8qc[ 8qe[").tie,
      described_class.of_graces(tokens("8qc[", "8qe"), field: "8qc[ 8qe").tie
    ]).to eq [:start, nil]
  end
end
