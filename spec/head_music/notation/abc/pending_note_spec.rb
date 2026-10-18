require "spec_helper"

describe HeadMusic::Notation::ABC::PendingNote do
  subject(:note) { described_class.new(pitches: [pitch("C#4")], length: "2", scale: Rational(1), slur_marks: [:open], beam_break: true) }

  let(:duration_resolver) { HeadMusic::Notation::ABC::DurationResolver.new("1/8") }

  def pitch(name)
    HeadMusic::Rudiment::Pitch.get(name)
  end

  it "resolves its own length" do
    expect(note.rhythmic_value(duration_resolver).to_s).to eq "quarter"
  end

  it "ties to the same letters in the same octaves, whatever their accidentals" do
    expect([note.ties_to?([pitch("C4")]), note.ties_to?([pitch("C5")])]).to eq [true, false]
  end

  describe "#tied_to" do
    subject(:tied) { note.tied_to(link, prefix, [:fixed]) }

    let(:link) { described_class.new(pitches: [pitch("C4")], length: "1", scale: Rational(1), slur_marks: [:close], tuplet_ends: [:link_end]) }
    let(:prefix) { note.rhythmic_value(duration_resolver) }

    it "keeps its own pitches and beam break" do
      expect([tied.pitches, tied.beam_break]).to eq [[pitch("C#4")], true]
    end

    it "renders the whole chain as one value" do
      expect(tied.rhythmic_value(duration_resolver).to_s).to eq "quarter tied to eighth"
    end

    it "gathers the link's marks after its own" do
      expect([tied.slur_marks, tied.tuplet_ends]).to eq [%i[open close], %i[fixed link_end]]
    end
  end
end
