require "spec_helper"

describe HeadMusic::Notation::Kern::BarClock do
  subject(:clock) { described_class.new { |_bar_number| HeadMusic::Rudiment::Meter.get("3/4") } }

  def barline(field)
    HeadMusic::Notation::Kern::BarlineReader.read(field)
  end

  it "right-aligns a pickup in the bar before the first barline" do
    clock.barline(barline("=1"), Rational(1, 4), 3)
    expect(clock.bars.map(&:to_h)).to eq [{number: 0, start: Rational(-1, 2)}, {number: 1, start: Rational(1, 4)}]
  end

  it "finds the bar containing a time" do
    clock.barline(barline("=1"), Rational(1, 4), 3)
    expect([clock.bar_containing(0).number, clock.bar_containing(Rational(1, 4)).number]).to eq [0, 1]
  end

  it "finds the next bar's start" do
    clock.barline(barline("=1"), Rational(1, 4), 3)
    expect([clock.next_bar_start(0), clock.next_bar_start(Rational(1, 4))]).to eq [Rational(1, 4), nil]
  end

  it "keeps a mid-bar repeat's bar open" do
    clock.barline(barline("=1"), 0, 3)
    clock.barline(barline("=:|!"), Rational(1, 2), 5)
    expect([clock.number, clock.repeat_ends]).to eq [1, [1]]
  end

  it "applies a change waiting for the next downbeat to the bar it opens" do
    changed = []
    clock.barline(barline("=1"), 0, 3)
    clock.at_downbeat(Rational(1, 2), "*M2/4", 4) { |bar_number| changed << bar_number }
    clock.barline(barline("=2"), Rational(3, 4), 5)
    expect(changed).to eq [2]
  end
end
