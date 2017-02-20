require 'spec_helper'

describe FunctionalInterval do
  describe '.between' do
    subject { FunctionalInterval.between('A', 'E') }

    its(:name) { is_expected.to eq 'perfect fifth' }
  end
end
