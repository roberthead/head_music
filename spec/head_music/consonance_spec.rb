# frozen_string_literal: true

require 'spec_helper'

describe Consonance do
  describe 'predicate_methods' do
    specify { expect(Consonance.get(:imperfect)).not_to be_perfect }
    specify { expect(Consonance.get(:imperfect)).to be_imperfect }
    specify { expect(Consonance.get(:imperfect)).not_to be_dissonant }
  end

  context 'when given an instance' do
    let(:instance) { described_class.get('#') }

    it 'returns that instance' do
      expect(described_class.get(instance)).to be instance
    end
  end
end
