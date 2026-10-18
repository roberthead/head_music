require "spec_helper"

describe HeadMusic::Analysis::PitchSpeller::Successors do
  def note(number, onset, duration = 1r / 4, voice = nil)
    HeadMusic::Analysis::UnspelledNote.new(number: number, onset: onset, duration: duration, voice: voice)
  end

  describe "#[]" do
    it "answers the key numbers at the voice's next onset" do
      notes = [[60, 0], [62, 1r / 4], [65, 1r / 4], [67, 1r / 2]].map { |number, onset| note(number, onset, 1r / 4, :a) }
      successors = described_class.new(notes)
      expect([successors[0], successors[1], successors[3]]).to eq [[62, 65], [67], nil]
    end

    it "leads a grace note to its main note" do
      successors = described_class.new([note(61, 0, 0r, :a), note(62, 0, 1r / 4, :a), note(64, 1r / 4, 1r / 4, :a)])
      expect(successors[0]).to eq [62]
    end

    it "follows each voice separately" do
      successors = described_class.new([note(60, 0, 1r / 4, :a), note(48, 0, 1r / 4, :b), note(61, 1r / 4, 1r / 4, :a)])
      expect([successors[0], successors[1]]).to eq [[61], nil]
    end

    it "follows no voice where unvoiced notes overlap" do
      successors = described_class.new([note(60, 0, 1r / 2), note(62, 1r / 4)])
      expect(successors[0]).to be_nil
    end
  end

  describe "#semitone_step" do
    it "answers the direction of a semitone to a following note" do
      successors = described_class.new([note(61, 0), note(62, 1r / 4), note(61, 1r / 2), note(65, 3r / 4)])
      expect((0..3).map { |position| successors.semitone_step(position) }).to eq [1, -1, nil, nil]
    end
  end
end
