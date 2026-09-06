require "spec_helper"

describe HeadMusic::Content::Position do
  # rubocop:disable RSpec/MultipleMemoizedHelpers
  subject(:position) { described_class.new(flow, bar_number, count, tick) }

  let(:flow) { HeadMusic::Content::Flow.new }
  let(:bar_number) { 3 }
  let(:count) { 2 }
  let(:tick) { 480 }

  its(:flow) { is_expected.to eq flow }
  its(:bar_number) { is_expected.to eq 3 }
  its(:count) { is_expected.to eq 2 }
  its(:tick) { is_expected.to eq 480 }
  its(:to_s) { is_expected.to eq "3:2:480" }
  its(:start_of_next_bar) { is_expected.to eq "4:1:000" }

  context "when there are a small number of ticks" do
    let(:tick) { 60 }

    its(:code) { is_expected.to eq "3:2:060" }
  end

  context "when there are no ticks" do
    let(:tick) { 0 }

    its(:code) { is_expected.to eq "3:2:000" }
  end

  describe "#strength" do
    context "for the downbeat" do
      let(:count) { 1 }
      let(:tick) { 0 }

      its(:strength) { is_expected.to eq 100 }
      it { is_expected.to be_strong }
      it { is_expected.not_to be_weak }
    end

    context "for the middle beat" do
      let(:count) { 3 }
      let(:tick) { 0 }

      its(:strength) { is_expected.to eq 80 }
      it { is_expected.to be_strong }
      it { is_expected.not_to be_weak }
    end

    context "for an off-beat" do
      let(:count) { 4 }
      let(:tick) { 0 }

      its(:strength) { is_expected.to eq 60 }
      it { is_expected.not_to be_strong }
      it { is_expected.to be_weak }
    end

    context "for an eighth division" do
      let(:count) { 1 }
      let(:tick) { HeadMusic::Rudiment::RhythmicUnit.get(:eighth).ticks }

      its(:strength) { is_expected.to eq 40 }
      it { is_expected.not_to be_strong }
      it { is_expected.to be_weak }
    end

    context "for a sixteenth division" do
      let(:count) { 1 }
      let(:tick) { HeadMusic::Rudiment::RhythmicUnit.get("thirty-second").ticks }

      its(:strength) { is_expected.to eq 20 }
      it { is_expected.not_to be_strong }
      it { is_expected.to be_weak }
    end
  end

  describe "value rollover" do
    context "when in 4/4" do
      context "given too many ticks" do
        let(:bar_number) { 3 }
        let(:count) { 2 }
        let(:tick) { 1000 }

        it "rolls over to the next count" do
          expect(position).to eq described_class.new(flow, 3, 3, 40)
        end
      end

      context "given exactly one beat worth of ticks" do
        let(:bar_number) { 3 }
        let(:count) { 2 }
        let(:tick) { 960 }

        it "rolls over to the next count" do
          expect(position).to eq "3:3:000"
        end
      end

      context "given too many counts" do
        let(:bar_number) { 3 }
        let(:count) { 9 }
        let(:tick) { 0 }

        it "rolls over to a subsequent bar" do
          expect(position).to eq described_class.new(flow, "5:1:0")
        end
      end
    end

    context "when in 6/8" do
      let(:flow) { HeadMusic::Content::Flow.new(meter: "6/8") }

      context "given too many ticks" do
        let(:bar_number) { 3 }
        let(:count) { 4 }
        let(:tick) { 720 }

        specify { expect(flow.meter).to eq "6/8" }
        specify { expect(position.meter).to eq "6/8" }
        specify { expect(position).to eq described_class.new(flow, 3, 5, 240) }
      end

      context "given too many counts" do
        let(:bar_number) { 3 }
        let(:count) { 9 }
        let(:tick) { 0 }

        it "rolls over to a subsequent bar" do
          expect(position).to eq described_class.new(flow, "4:3:0")
        end
      end
    end
  end

  describe "addition" do
    context "when adding a rhythmic unit within a bar" do
      let(:expected_position) { described_class.new(flow, bar_number, count + 1, tick) }

      specify { expect(position + HeadMusic::Rudiment::RhythmicUnit.get(:quarter)).to eq expected_position }
    end

    context "when adding a rhythmic unit across a bar" do
      let(:expected_position) { described_class.new(flow, bar_number + 1, count, tick) }

      specify { expect(position + HeadMusic::Rudiment::RhythmicUnit.get(:whole)).to eq expected_position }
    end

    context "when adding a rhythmic value within a bar" do
      let(:expected_position) { described_class.new(flow, "3.4.480") }

      specify { expect(position + HeadMusic::Rudiment::RhythmicValue.new(:half)).to eq expected_position }
    end

    context "when adding a rhythmic value across a bar" do
      let(:expected_position) { described_class.new(flow, "4.1.480") }

      specify { expect(HeadMusic::Rudiment::RhythmicValue.new(:half, dots: 1).relative_value).to eq 0.75 }
      specify { expect(HeadMusic::Rudiment::RhythmicValue.new(:half, dots: 1).ticks).to eq 960 * 3 }

      specify { expect(position + HeadMusic::Rudiment::RhythmicValue.new(:half, dots: 1)).to eq expected_position }
    end
  end

  describe "comparison" do
    context "when the bars are unequal" do
      let(:bar_one_beat_four) { described_class.new(flow, 1, 4, tick) }
      let(:bar_two_beat_one) { described_class.new(flow, 2, 1, tick) }

      specify { expect(bar_one_beat_four).to be < bar_two_beat_one }
      specify { expect([bar_two_beat_one, bar_one_beat_four].sort).to eq [bar_one_beat_four, bar_two_beat_one] }
    end

    context "when the bars are equal" do
      context "when the counts are unequal" do
        let(:beat_three) { described_class.new(flow, bar_number, 3, 0) }
        let(:beat_two_and_some) { described_class.new(flow, bar_number, 2, 120) }

        specify { expect(beat_three).to be > beat_two_and_some }
        specify { expect([beat_three, beat_two_and_some].sort).to eq [beat_two_and_some, beat_three] }
      end

      context "when the counts are equal and the ticks are unequal" do
        let(:count_zero) { described_class.new(flow, bar_number, count, 0) }
        let(:count_120) { described_class.new(flow, bar_number, count, 120) }

        specify { expect(count_zero).to be < count_120 }
        specify { expect([count_120, count_zero].sort).to eq [count_zero, count_120] }
      end

      context "when the counts are equal and the ticks are equal" do
        let(:a_position) { described_class.new(flow, bar_number, count, tick) }
        let(:the_same_tick) { described_class.new(flow, bar_number, count, tick) }

        specify { expect(a_position).to eq the_same_tick }
      end
    end
  end

  describe "#within_placement?" do
    let!(:placement) do
      HeadMusic::Content::Placement.new(flow.add_voice, "3:2:000", :quarter)
    end

    context "when the position is before the start of the placement" do
      subject(:position) { described_class.new(flow, 3, 1, 0) }

      it { is_expected.not_to be_within_placement(placement) }
    end

    context "when the position is at the start of the placement" do
      subject(:position) { described_class.new(flow, 3, 2, 0) }

      it { is_expected.to be_within_placement(placement) }
    end

    context "when the position is with the placement" do
      subject(:position) { described_class.new(flow, 3, 2, 240) }

      it { is_expected.to be_within_placement(placement) }
    end

    context "when at the end of the placement" do
      subject(:position) { described_class.new(flow, 3, 3, 0) }

      it { is_expected.not_to be_within_placement(placement) }
    end

    context "when after the end of the placement" do
      subject(:position) { described_class.new(flow, 3, 4, 0) }

      it { is_expected.not_to be_within_placement(placement) }
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  describe "subticks" do
    let(:flow) { HeadMusic::Content::Flow.new }

    it "parses all four components" do
      expect(flow.position("2:3:480:120").to_a).to eq [2, 3, 480, 120]
    end

    it "omits them from the code when there are none" do
      expect(flow.position("2:3:480").code).to eq "2:3:480"
    end

    it "emits them when there are some" do
      expect(flow.position("2:3:480:120").code).to eq "2:3:480:120"
    end

    it "carries a full tick of them into a tick" do
      expect(flow.position(1, 1, 0, 240).to_a).to eq [1, 1, 1, 0]
    end
  end

  describe "immutability" do
    let(:flow) { HeadMusic::Content::Flow.new }

    it "is frozen" do
      expect(flow.position("1:1")).to be_frozen
    end

    it "does not expose the value it wraps" do
      expect(flow.position("1:1")).not_to respond_to :value
    end
  end

  describe "equality" do
    let(:flow) { HeadMusic::Content::Flow.new }
    let(:other_flow) { HeadMusic::Content::Flow.new(name: "Another") }

    it "serves as a hash key" do
      expect({flow.position("2:3:480") => :note}[flow.position("2:3:480")]).to eq :note
    end

    it "distinguishes positions differing in any component" do
      expect(flow.position("2:3:480")).not_to eql flow.position("2:3:481")
    end

    # Positions in different flows have always compared equal here, and
    # Voice#placement_at guards with exactly that comparison.
    it "ignores the flow" do
      expect(flow.position("2:3:480")).to eq other_flow.position("2:3:480")
    end
  end

  describe "normalizing across a meter change" do
    let(:flow) do
      HeadMusic::Content::Flow.new(meter: "4/4").tap { |flow| flow.change_meter(2, "3/4") }
    end

    # Ten quarter notes from 1:1 fill four counts of bar 1 and three each of
    # bars 2 and 3, landing on the downbeat of bar 4 -- which a single divmod
    # over one meter would put at 3:3 instead.
    it "spends each crossed bar at that bar's own count" do
      expect(flow.position(1, 1, 960 * 10).code).to eq "4:1:000"
    end

    # The tick carry was done under the origin bar's count unit. Landing in a
    # bar whose count is an eighth, a leftover half-count of ticks is a whole
    # count there, so the position is carried again under that bar's meter.
    context "when the destination bar has a different count unit" do
      let(:flow) do
        HeadMusic::Content::Flow.new(meter: "4/4").tap { |flow| flow.change_meter(2, "6/8") }
      end

      it "respells the leftover ticks in the destination bar's counts" do
        expect((flow.position("1:4:480") + :quarter).code).to eq "2:2:000"
      end

      it "gives one instant one spelling, so equality and hashing agree" do
        rolled = flow.position("1:4:480") + :quarter
        expect([rolled == flow.position("2:2"), rolled.hash == flow.position("2:2").hash]).to eq [true, true]
      end

      it "merges a placement rolled into the bar with one authored there" do
        voice = flow.add_voice
        voice.place("1:4:480", :quarter, "F4")
        voice.place(voice.next_position, :eighth, "G4")
        voice.place(flow.position("2:2"), :eighth, "A4")
        expect(voice.placements.map { |placement| placement.position.code }).to eq %w[1:4:480 2:2:000]
      end
    end

    it "leaves a position within the opening bar alone" do
      expect(flow.position(1, 1, 960 * 2).code).to eq "1:3:000"
    end
  end
end
