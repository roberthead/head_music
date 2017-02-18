require 'spec_helper'

describe Quality do
  describe '.get' do
    specify { expect(Quality.get(:major)).to be }
    specify { expect(Quality.get(:minor)).to be }
    specify { expect(Quality.get(:diminished)).to be }
    specify { expect(Quality.get(:augmented)).to be }
    specify { expect(Quality.get(:salad)).to be_nil }
  end

  describe 'equality' do
    specify { expect(Quality.get(:major)).to eq :major }
  end
end
