# frozen_string_literal: true

require 'spec_helper'

class GenericNamedRudiment
  include HeadMusic::NamedRudiment
end

describe HeadMusic::NamedRudiment do
  context 'when passing a string to the constructor' do
    subject(:rudiment) { GenericNamedRudiment.new('Nuclear Transmogrifier') }

    its(:name) { is_expected.to eq 'Nuclear Transmogrifier' }
    its(:hash_key) { is_expected.to eq :nuclear_transmogrifier }
  end
end
