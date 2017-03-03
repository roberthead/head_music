require 'spec_helper'

describe Measure do
  let(:composition) { Composition.new(name: 'Song', key_signature: 'D major', meter: '6/8') }
  subject(:measure) { Measure.new(composition) }

  its(:key_signature) { is_expected.to eq 'D major' }
  its(:meter) { is_expected.to eq '6/8' }
end
