require "spec_helper"

describe HeadMusic::MIDI::RampTurn do
  it "finds the tempo at a turn from the means its last two steps hold" do
    turn, change = 90.0, 6.0
    last = described_class.logarithmic_mean(turn + change, turn)
    before = described_class.logarithmic_mean(turn + 2 * change, turn + change)
    expect(described_class.per_minute(last, before)).to be_within(0.001).of(turn)
  end

  it "is the tempo itself when the steps hold one tempo" do
    expect(described_class.per_minute(100, 100)).to eq 100
  end

  it "takes the mean of a tempo with itself as that tempo" do
    expect(described_class.logarithmic_mean(80.0, 80.0)).to eq 80.0
  end
end
