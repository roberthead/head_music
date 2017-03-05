require 'spec_helper'

describe Position do
  subject(:position) { Position.new(composition, measure_number, count, tick) }
  let(:composition) { Composition.new(name: 'Back Beat') }
  let(:measure_number) { 3 }
  let(:count) { 2 }
  let(:tick) { 480 }

  its(:composition) { is_expected.to eq composition }
  its(:measure_number) { is_expected.to eq 3 }
  its(:count) { is_expected.to eq 2 }
  its(:tick) { is_expected.to eq 480 }
  its(:to_s) { is_expected.to eq "3:2:480" }
  its(:start_of_next_measure) { is_expected.to eq "4:1:000" }

  context 'when there are a small number of ticks' do
    let(:tick) { 60 }

    its(:code) { is_expected.to eq "3:2:060" }
  end

  context 'when there are no ticks' do
    let(:tick) { 0 }

    its(:code) { is_expected.to eq "3:2:000" }
  end

  describe '#strength' do
    context 'for the downbeat' do
      let(:count) { 1 }
      let(:tick) { 0 }

      its(:strength) { is_expected.to eq 100 }
      it { is_expected.to be_strong }
      it { is_expected.not_to be_weak }
    end

    context 'for the middle beat' do
      let(:count) { 3 }
      let(:tick) { 0 }

      its(:strength) { is_expected.to eq 80 }
      it { is_expected.to be_strong }
      it { is_expected.not_to be_weak }
    end

    context 'for an off-beat' do
      let(:count) { 4 }
      let(:tick) { 0 }

      its(:strength) { is_expected.to eq 60 }
      it { is_expected.not_to be_strong }
      it { is_expected.to be_weak }
    end

    context 'for a division' do
      let(:count) { 1 }
      let(:tick) { RhythmicUnit.get(:eighth).ticks }

      its(:strength) { is_expected.to eq 40 }
      it { is_expected.not_to be_strong }
      it { is_expected.to be_weak }
    end

    context 'for a division' do
      let(:count) { 1 }
      let(:tick) { RhythmicUnit.get('thirty-second').ticks }

      its(:strength) { is_expected.to eq 20 }
      it { is_expected.not_to be_strong }
      it { is_expected.to be_weak }
    end
  end

  describe 'value rollover' do
    context 'in 4/4' do
      context 'given too many ticks' do
        let(:measure_number) { 3 }
        let(:count) { 2 }
        let(:tick) { 1000 }

        it 'rolls over to the next count' do
          expect(position).to eq Position.new(composition, 3, 3, 40)
        end
      end

      context 'given too many counts' do
        let(:measure_number) { 3 }
        let(:count) { 9 }
        let(:tick) { 0 }

        it 'rolls over to a subsequent measure' do
          expect(position).to eq Position.new(composition, "5:1:0")
        end
      end
    end

    context 'in 6/8' do
      let(:composition) { Composition.new(name: 'Sway', meter: '6/8') }

      context 'given too many ticks' do
        let(:measure_number) { 3 }
        let(:count) { 4 }
        let(:tick) { 720 }

        it 'rolls over to a subsequent count' do
          expect(composition.meter).to eq '6/8'
          expect(position.meter).to eq '6/8'
          expect(position).to eq Position.new(composition, 3, 5, 240)
        end
      end

      context 'given too many counts' do
        let(:measure_number) { 3 }
        let(:count) { 9 }
        let(:tick) { 0 }

        it 'rolls over to a subsequent measure' do
          expect(position).to eq Position.new(composition, "4:3:0")
        end
      end
    end
  end

  describe 'addition' do
    context 'when adding a rhythmic unit' do
      context 'within a measure' do
        let(:expected_position) { Position.new(composition, measure_number, count+1, tick) }

        specify { expect(position + RhythmicUnit.get(:quarter)).to eq expected_position }
      end

      context 'across a measure' do
        let(:expected_position) { Position.new(composition, measure_number+1, count, tick) }

        specify { expect(position + RhythmicUnit.get(:whole)).to eq expected_position }
      end
    end

    context 'when adding a rhythmic value' do
      context 'within a measure' do
        let(:expected_position) { Position.new(composition, '3.4.480') }

        specify { expect(position + RhythmicValue.new(:half)).to eq expected_position }
      end

      context 'across a measure' do
        let(:expected_position) { Position.new(composition, '4.1.480') }

        specify { expect(RhythmicValue.new(:half, dots: 1).relative_value).to eq 0.75 }
        specify { expect(RhythmicValue.new(:half, dots: 1).ticks).to eq 960 * 3 }

        specify { expect(position + RhythmicValue.new(:half, dots: 1)).to eq expected_position }
      end
    end
  end

  describe 'comparison' do
    context 'when the measures are unequal' do
      let(:position1) { Position.new(composition, 1, 4, tick) }
      let(:position2) { Position.new(composition, 2, 1, tick) }

      specify { expect(position1).to be < position2 }
      specify { expect([position2, position1].sort).to eq [position1, position2] }
    end

    context 'when the measures are equal' do
      context 'when the counts are unequal' do
        let(:position1) { Position.new(composition, measure_number, 3, 0) }
        let(:position2) { Position.new(composition, measure_number, 2, 120) }

        specify { expect(position1).to be > position2 }
        specify { expect([position1, position2].sort).to eq [position2, position1] }
      end

      context 'when the counts are equal' do
        context 'when the ticks are unequal' do
          let(:position1) { Position.new(composition, measure_number, count, 0) }
          let(:position2) { Position.new(composition, measure_number, count, 120) }

          specify { expect(position1).to be < position2 }
          specify { expect([position2, position1].sort).to eq [position1, position2] }
        end

        context 'when the ticks are equal' do
          let(:position1) { Position.new(composition, measure_number, count, tick) }
          let(:position2) { Position.new(composition, measure_number, count, tick) }

          specify { expect(position1).to be == position2 }
        end
      end
    end
  end
end
