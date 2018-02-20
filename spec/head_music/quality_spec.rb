# frozen_string_literal: true

require 'spec_helper'

describe Quality do
  describe '.get' do
    specify { expect(Quality.get(:major)).to be }
    specify { expect(Quality.get(:minor)).to be }
    specify { expect(Quality.get(:diminished)).to be }
    specify { expect(Quality.get(:augmented)).to be }
    specify { expect(Quality.get(:salad)).to be_nil }

    context 'when given an instance' do
      let(:instance) { described_class.get(:diminished) }

      it 'returns that instance' do
        expect(described_class.get(instance)).to be instance
      end
    end
  end

  describe 'equality' do
    specify { expect(Quality.get(:major)).to eq :major }
  end

  describe 'predicate_methods' do
    specify { expect(Quality.get(:major)).to be_major }
    specify { expect(Quality.get(:major)).not_to be_minor }
  end
end
