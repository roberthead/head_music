require "spec_helper"

describe HeadMusic::MIDI::TempoSteps do
  subject(:steps) { described_class.new(flow) }

  let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nT:Steps\nM:#{meter}\nL:1/4\nK:C\n#{music}|]\n") }
  let(:meter) { "4/4" }
  let(:music) { "CDEF|GABc|cBAG|FEDC|C4" }

  def tempo(bpm, beat = "quarter")
    HeadMusic::Rudiment::Tempo.new(beat, bpm)
  end

  # Seconds from the first step to +to+ whole notes past the bar's
  # downbeat, as a file plays the bar's steps.
  def seconds(bar_steps, to)
    microseconds = bar_steps.each_cons(2).sum { |(from, rate), (finish, _)| (finish - from) * 4 * rate }
    (microseconds + (to - bar_steps.last.first) * 4 * bar_steps.last.last) / 1e6
  end

  def clock_between(from, to)
    conductor = flow.conductor
    (conductor.musical_to_clock(flow.position(to)).nanoseconds - conductor.musical_to_clock(flow.position(from)).nanoseconds) / 1e9
  end

  before { flow.change_tempo(1, tempo(120)) }

  context "with no ramps or fermatas" do
    it "steps once, at the downbeat, at the bar's tempo" do
      expect((1..5).map { |bar| steps.in_bar(bar) }).to eq [[[0, 500_000]]] * 5
    end

    it "touches no bar" do
      expect(steps.touched_bar_numbers).to eq []
    end

    it "steps at the given offset, past a pickup's silence" do
      expect(steps.in_bar(1, from: Rational(1, 8))).to eq [[Rational(1, 8), 500_000]]
    end
  end

  context "with a bar ramping from 120 to 80" do
    before { flow.add_tempo_ramp(from: "2:1", to: "3:1", to_tempo: tempo(80), text: "rit.") }

    let(:bar_steps) { steps.in_bar(2) }

    it "steps at each count, and at the barline with the target" do
      expect(bar_steps.map(&:first)).to eq [0, Rational(1, 4), Rational(1, 2), Rational(3, 4), 1]
      expect(bar_steps.last).to eq [1, 750_000]
    end

    it "slows at every step" do
      expect(bar_steps.map(&:last).each_cons(2).all? { |one, other| one < other }).to be true
    end

    it "lasts as long as the Conductor says, to the microsecond" do
      expect(seconds(bar_steps.first(4), 1)).to be_within(1e-6).of(2.432790649)
    end

    it "keeps time with the Conductor at every step" do
      expect(seconds(bar_steps.first(2), Rational(1, 2))).to be_within(1e-6).of(clock_between("2:1", "2:3"))
    end

    it "steps once at the next downbeat, at the target" do
      expect(steps.in_bar(3)).to eq [[0, 750_000]]
    end
  end

  context "with a ramp ending in the middle of a bar" do
    before { flow.add_tempo_ramp(from: "2:3", to: "3:2", to_tempo: tempo(60)) }

    it "steps at its end with the target" do
      expect(steps.in_bar(3).map(&:first)).to eq [0, Rational(1, 4)]
      expect(steps.in_bar(3).last).to eq [Rational(1, 4), 1_000_000]
    end

    it "keeps the tempo before it until it starts" do
      expect(steps.in_bar(2).first(2)).to eq [[0, 500_000], [Rational(1, 2), steps.in_bar(2)[1].last]]
    end
  end

  context "with a ramp across a meter change" do
    let(:flow) do
      HeadMusic::Content::Flow.new(meter: "4/4").tap do |changing|
        changing.add_voice.place("1:1", :whole, "C4")
        changing.change_meter(3, "3/4")
      end
    end

    before { flow.add_tempo_ramp(from: "2:1", to: "4:1", to_tempo: tempo(60)) }

    it "steps at the counts of each bar's own meter, and at the barline it ends on" do
      expect(steps.in_bar(3).map(&:first)).to eq [0, Rational(1, 4), Rational(1, 2), Rational(3, 4)]
    end

    it "keeps time with the Conductor across the change" do
      expect(seconds(steps.in_bar(3).first(3), Rational(3, 4))).to be_within(1e-6).of(clock_between("3:1", "4:1"))
    end
  end

  context "with a fermata in the middle of a bar in 3/4 at 100" do
    let(:meter) { "3/4" }
    let(:music) { "GAB|cBA|G3" }

    before do
      flow.change_tempo(1, tempo(100))
      flow.add_fermata("2:2", :quarter)
    end

    it "halves the tempo over its span, then restores it" do
      expect(steps.in_bar(2)).to eq [[0, 600_000], [Rational(1, 4), 1_200_000], [Rational(1, 2), 600_000]]
    end
  end

  context "with a fermata on the final bar" do
    before { flow.add_fermata("5:1", :whole, stretch: 1.5) }

    it "restores the tempo at the closing barline" do
      expect(steps.in_bar(5)).to eq [[0, 750_000], [1, 500_000]]
    end
  end

  context "with a fermata at the start of a bar" do
    before { flow.add_fermata("3:1", :half) }

    it "adds no step at the barline before it" do
      expect(steps.in_bar(2)).to eq [[0, 500_000]]
    end
  end

  context "with a fermata inside a ramp" do
    before do
      flow.add_tempo_ramp(from: "2:1", to: "4:1", to_tempo: tempo(60))
      flow.add_fermata("2:3", :quarter)
    end

    it "keeps time with the Conductor through the hold" do
      expect(seconds(steps.in_bar(2), 1)).to be_within(1e-6).of(clock_between("2:1", "3:1"))
    end
  end

  context "with an a tempo in the middle of a bar after a ramp" do
    before do
      flow.add_tempo_ramp(from: "2:1", to: "3:1", to_tempo: tempo(80))
      flow.add_a_tempo("3:3")
    end

    it "restores the tempo the ramp began from" do
      expect(steps.in_bar(3)).to eq [[0, 750_000], [Rational(1, 2), 500_000]]
    end

    it "touches the bars of the ramp and the a tempo" do
      expect(steps.touched_bar_numbers).to eq [2, 3]
    end
  end
end
