require 'spec_helper'

describe Voice do
  let(:composition) { Composition.new(name: 'Invention') }

  subject(:voice) { Voice.new(composition) }

  its(:composition) { is_expected.to eq composition }
end
