require "spec_helper"

describe HeadMusic::MIDI::PartSource do
  let(:part_key) { HeadMusic::MIDI::PartKey.new(track: 0, channel: 0) }

  def note(key, onset, release)
    HeadMusic::MIDI::QuantizedNote.new(part_key: part_key, key: key, onset: Rational(onset), release: Rational(release))
  end

  def part(notes)
    described_class::Part.new(part_key, notes, [], nil, [], nil)
  end

  describe "Part#voices" do
    it "separates its notes into voices of chords" do
      voices = part([note(60, 0, "1/2"), note(64, 0, "1/2"), note(62, "1/2", 1)]).voices
      expect(voices.map { |voice| voice.map(&:keys) }).to eq [[[60, 64], [62]]]
    end

    it "is one empty voice for a part of rests" do
      expect(part([]).voices).to eq [[]]
    end
  end
end
