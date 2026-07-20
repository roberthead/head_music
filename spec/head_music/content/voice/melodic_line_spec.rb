require "spec_helper"

describe HeadMusic::Content::Voice::MelodicLine do
  subject(:melodic_line) { described_class.new(voice.notes) }

  let(:voice) do
    HeadMusic::Content::Voice.new.tap do |voice|
      %w[G3 C4 D4 Eb4 F4 Eb4 G3].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end
  end

  it "pairs consecutive notes" do
    expect(melodic_line.melodic_note_pairs.length).to eq 6
    expect(melodic_line.melodic_note_pairs.first.pitches.map(&:to_s)).to eq %w[G3 C4]
  end

  it "reuses the same pair objects across calls" do
    expect(melodic_line.melodic_note_pairs).to equal melodic_line.melodic_note_pairs
  end

  it "spans an interval for each pair" do
    expect(melodic_line.melodic_intervals.map(&:shorthand)).to eq %w[P4 M2 m2 M2 M2 m6]
  end

  it "selects the leaps" do
    expect(melodic_line.leaps).to eq [melodic_line.melodic_note_pairs[0], melodic_line.melodic_note_pairs[5]]
  end

  it "selects the large leaps" do
    expect(melodic_line.large_leaps).to eq [melodic_line.melodic_note_pairs[0], melodic_line.melodic_note_pairs[5]]
  end

  context "with fewer than two notes" do
    let(:voice) { HeadMusic::Content::Voice.new.tap { |voice| voice.place("1:1", :whole, "C4") } }

    it "has no pairs" do
      expect(melodic_line.melodic_note_pairs).to eq []
    end
  end
end
