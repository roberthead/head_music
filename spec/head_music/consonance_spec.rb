# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Consonance do
  describe 'predicate_methods' do
    specify { expect(described_class.get(:imperfect)).not_to be_perfect }
    specify { expect(described_class.get(:imperfect)).to be_imperfect }
    specify { expect(described_class.get(:imperfect)).not_to be_dissonant }
  end

  context 'when given an instance' do
    let(:instance) { described_class.get('#') }

    it 'returns that instance' do
      expect(described_class.get(instance)).to be instance
    end
  end
end
