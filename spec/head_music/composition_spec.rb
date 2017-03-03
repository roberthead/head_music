require 'spec_helper'

describe Composition do
  subject(:composition) { Composition.new(name: 'Fruit Salad') }

  it 'assigns a name' do
    expect(composition.name).to eq 'Fruit Salad'
  end

  it 'initializes one measure' do
    expect(composition.measures.length).to eq 1
  end

  it 'defaults to the key of C major' do
    expect(composition.key_signature).to eq 'C major'
  end

  it 'defaults to 4/4' do
    expect(composition.meter).to eq '4/4'
  end
end
