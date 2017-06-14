require 'spec_helper'

describe Interval do
  describe '.get' do
    context 'when given an instance' do
      let(:instance) { described_class.get(7) }

      it 'returns that instance' do
        expect(described_class.get(instance)).to be instance
      end
    end
  end

  context 'given a simple interval' do
    subject(:interval) { Interval.get(2) }

    it { is_expected.to be == 2 }
    it { is_expected.to be_simple }
    it { is_expected.to eq interval.simple }
    it { is_expected.not_to be_compound }
  end

  let(:perfect_unison) { Interval.get(:perfect_unison) }
  let(:major_third) { Interval.get(:major_third) }
  let(:minor_third) { Interval.get(:minor_third) }
  let(:perfect_fourth) { Interval.get(:perfect_fourth) }
  let(:perfect_fifth) { Interval.get(:perfect_fifth) }
  let(:perfect_octave) { Interval.get(:perfect_octave) }
  let(:perfect_11th) { Interval.get(17) }

  specify { expect(major_third).to be > minor_third }

  specify { expect(major_third + minor_third).to eq perfect_fifth }

  specify { expect(perfect_fifth - minor_third).to eq major_third }

  specify { expect(perfect_unison).to be_simple }
  specify { expect(major_third).to be_simple }
  specify { expect(perfect_octave).to be_simple }
  specify { expect(perfect_11th).not_to be_simple }

  specify { expect(perfect_unison).not_to be_compound }
  specify { expect(major_third).not_to be_compound }
  specify { expect(perfect_octave).not_to be_compound }
  specify { expect(perfect_11th).to be_compound }

  specify { expect(perfect_11th.simple).to eq(perfect_fourth) }
end
