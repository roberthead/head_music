# frozen_string_literal: true

require 'spec_helper'

class GenericNamedRudiment
  include HeadMusic::Named
end

describe HeadMusic::Named do
  context 'when passing a string to the constructor' do
    subject(:rudiment) { GenericNamedRudiment.new('Nuclear Transmogrifier') }

    its(:name) { is_expected.to eq 'Nuclear Transmogrifier' }
    its(:hash_key) { is_expected.to eq :nuclear_transmogrifier }

    context 'when the named rudiment exists' do
      subject(:rudiment) { GenericNamedRudiment.get_by_name('Nuclear Transmogrifier') }

      it 'is fetchable by name' do
        expect(GenericNamedRudiment.get_by_name('Nuclear Transmogrifier')).to eq rudiment
      end
    end
  end
end
