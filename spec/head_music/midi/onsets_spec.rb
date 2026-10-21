require "spec_helper"

describe HeadMusic::MIDI::Onsets do
  subject(:onsets) { described_class.new([1r, 1/2r, 1r, 3/2r]) }

  describe "#between?" do
    it "finds a note starting after the first time and before the second" do
      expect([onsets.between?(0r, 1r), onsets.between?(1/4r, 3/4r)]).to eq [true, true]
    end

    it "leaves out a note starting at either time" do
      expect([onsets.between?(1/2r, 1r), onsets.between?(1r, 3/2r)]).to eq [false, false]
    end

    it "counts a note starting at the first time when asked" do
      expect(onsets.between?(1/2r, 1r, including_from: true)).to be true
    end

    it "finds nothing past the last note" do
      expect(onsets.between?(3/2r, 4r)).to be false
    end
  end
end
