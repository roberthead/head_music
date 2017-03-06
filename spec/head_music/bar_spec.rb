require 'spec_helper'

describe Bar do
  let(:composition) { Composition.new(name: 'Song', key_signature: 'D major', meter: '6/8') }
  subject(:bar) { Bar.new(composition) }

  its(:key_signature) { is_expected.to eq 'D major' }
  its(:meter) { is_expected.to eq '6/8' }
end
