require 'spec_helper'

describe Consonance do
  describe 'predicate_methods' do
    specify { expect(Consonance.get(:imperfect)).not_to be_perfect }
    specify { expect(Consonance.get(:imperfect)).to be_imperfect }
    specify { expect(Consonance.get(:imperfect)).not_to be_dissonant }
  end
end