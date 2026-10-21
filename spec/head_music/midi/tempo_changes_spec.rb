require "spec_helper"

describe HeadMusic::MIDI::TempoChanges do
  let(:layout) { HeadMusic::MIDI::BarLayout.new([], division: 96, end_tick: 96 * 4 * 3) }

  def changes(*pairs)
    described_class.new(layout, 500_000, pairs)
  end

  describe "#<<" do
    it "keeps only a change to another tempo than the one in force" do
      tempos = changes
      [[0r, 500_000], [1/4r, 600_000], [1/2r, 600_000], [3/4r, 500_000]].each { |change| tempos << change }
      expect(tempos.to_a).to eq [[1/4r, 600_000], [3/4r, 500_000]]
    end
  end

  describe "#tempo_before" do
    it "is the opening tempo before the first change, and the last one after the last" do
      tempos = changes([1/4r, 600_000], [1/2r, 700_000])
      expect([tempos.tempo_before(0), tempos.tempo_before(1), tempos.tempo_before]).to eq [500_000, 600_000, 700_000]
    end
  end

  describe "#with" do
    it "answers the changes with one more, leaving these as they are" do
      tempos = changes([1/4r, 600_000])
      expect([tempos.with([1/2r, 700_000]).to_a, tempos.to_a]).to eq [[[1/4r, 600_000], [1/2r, 700_000]], [[1/4r, 600_000]]]
    end
  end

  describe "#run" do
    subject(:tempos) { changes([1/4r, 550_000], [1/2r, 600_000], [3/4r, 650_000], [1r, 600_000]) }

    it "walks later through changes in one direction, each a count or less after the one before" do
      expect(tempos.run(0, 1)).to eq 0..2
    end

    it "walks earlier to the run's first change" do
      expect(tempos.run(2, -1)).to eq 0..2
    end

    it "stops at a change more than a count after the one before" do
      expect(changes([1/4r, 550_000], [3/4r, 600_000]).run(0, 1)).to eq 0..0
    end

    it "starts a new run where the direction turns" do
      expect(tempos.run(3, -1)).to eq 3..3
    end
  end

  describe "#ramp?" do
    it "is a run with at least two of its changes within bars" do
      tempos = changes([1/4r, 550_000], [1/2r, 600_000], [1r, 650_000])
      expect([tempos.ramp?(0..1), tempos.ramp?(1..2)]).to eq [true, false]
    end
  end

  describe "#next_step" do
    it "carries a run of two or more on in a straight line in quarters a minute" do
      expect(changes([1/4r, 600_000], [1/2r, 750_000]).next_step(3/4r)).to eq 1_000_000
    end

    it "is nil after a single change" do
      expect(changes([1/4r, 600_000]).next_step(1/2r)).to be_nil
    end

    it "is nil more than a count after the run" do
      expect(changes([1/4r, 600_000], [1/2r, 750_000]).next_step(1r)).to be_nil
    end

    it "is nil where the line falls to no tempo" do
      expect(changes([1/4r, 600_000], [1/2r, 1_200_000]).next_step(3/4r)).to be_nil
    end
  end
end
