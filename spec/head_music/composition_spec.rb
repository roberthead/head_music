# frozen_string_literal: true

require 'spec_helper'

describe Composition do
  subject(:composition) { Composition.new(name: 'Fruit Salad') }

  it 'assigns a name' do
    expect(composition.name).to eq 'Fruit Salad'
  end

  it 'defaults to the key of C major' do
    expect(composition.key_signature).to eq 'C major'
  end

  it 'defaults to 4/4' do
    expect(composition.meter).to eq '4/4'
  end

  context 'when the meter changes' do
    before do
      composition.change_meter(9, '6/8')
    end

    it 'starts in the original meter' do
      expect(composition.meter_at(1)).to eq '4/4'
    end

    it 'remains in the original meter before the change' do
      expect(composition.meter_at(8)).to eq '4/4'
    end

    it 'switches to the new meter at the change' do
      expect(composition.meter_at(9)).to eq '6/8'
    end

    it 'continues on with the new meter after the change' do
      expect(composition.meter_at(15)).to eq '6/8'
    end
  end

  context 'when the key signature changes' do
    before do
      composition.change_key_signature(9, 'G major')
    end

    it 'starts in the original key signature' do
      expect(composition.key_signature_at(1)).to eq 'C major'
    end

    it 'remains in the original key signature before the change' do
      expect(composition.key_signature_at(8)).to eq 'C major'
    end

    it 'switches to the new key signature at the change' do
      expect(composition.key_signature_at(9)).to eq 'G major'
    end

    it 'continues on with the new key signature after the change' do
      expect(composition.key_signature_at(15)).to eq 'G major'
    end
  end
end
