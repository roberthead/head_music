require "spec_helper"

describe HeadMusic::Analysis::PitchSpeller::Sounding do
  def note(number, onset, duration)
    HeadMusic::Analysis::UnspelledNote.new(number: number, onset: onset, duration: duration)
  end

  describe "#at" do
    it "answers the positions of the notes sounding at each onset asked for in turn" do
      sounding = described_class.new([note(60, 0, 1r / 2), note(64, 1r / 4, 1r / 4), note(67, 1r / 2, 1r / 4)])
      expect([sounding.at(0).dup, sounding.at(1r / 4).dup, sounding.at(1r / 2).dup]).to eq [[0], [0, 1], [2]]
    end
  end
end
