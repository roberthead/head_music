require 'spec_helper'

describe System do
  context 'when given a single staff' do
    let(:instrument) { Instrument.get(:flute) }
    let(:staff) { Staff.new(:treble, instrument: instrument) }
    subject(:system) { System.new(staves: [staff]) }

    its(:instruments) { are_expected.to eq [:flute] }
  end

  context 'when given a grand staff' do
    let(:instrument) { Instrument.get(:piano) }
    let(:treble_staff) { Staff.new(:treble, instrument: instrument) }
    let(:bass_staff) { Staff.new(:bass, instrument: instrument) }
    subject(:system) { System.new(staves: [treble_staff, bass_staff]) }

    its(:instruments) { are_expected.to eq [:piano] }
  end
end
