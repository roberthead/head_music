# frozen_string_literal: true

require "spec_helper"

describe HeadMusic::Circle do
  subject(:circle) { described_class.of_fifths }

  describe "#pitch_classes" do
    it "lists all the pitch classes starting at C" do
      expect(circle.pitch_class_set).to eq HeadMusic::PitchClassSet.new([0, 7, 2, 9, 4, 11, 6, 1, 8, 3, 10, 5])
    end
  end

  describe "#index" do
    specify { expect(circle.index("Eb")).to eq 9 }
    specify { expect(circle.index("Db")).to eq 7 }
    specify { expect(circle.index("C#")).to eq 7 }
    specify { expect(circle.index("A")).to eq 3 }
  end

  describe "#spellings_up" do
    it "uses sharp spellings" do
      expect(circle.spellings_up.map(&:to_s)).to eq(%w[C G D A E B F♯ C♯ A♭ E♭ B♭ F])
    end
  end

  describe "#spellings_down" do
    it "uses flat spellings" do
      expect(circle.spellings_down.map(&:to_s)).to eq(%w[C F B♭ E♭ A♭ D♭ G♭ C♭ E A D G])
    end
  end

  describe "#key_signatures_up" do
    specify { expect(circle.key_signatures_up.map(&:num_sharps)).to eq [0, 1, 2, 3, 4, 5, 6, 7, 0, 0, 0, 0] }
    specify { expect(circle.key_signatures_up.map(&:num_flats)).to eq [0, 0, 0, 0, 0, 0, 0, 0, 4, 3, 2, 1] }
  end

  describe "#key_signatures_down" do
    specify { expect(circle.key_signatures_down.map(&:num_sharps)).to eq [0, 0, 0, 0, 0, 0, 0, 0, 4, 3, 2, 1] }
    specify { expect(circle.key_signatures_down.map(&:num_flats)).to eq [0, 1, 2, 3, 4, 5, 6, 7, 0, 0, 0, 0] }
  end
end
