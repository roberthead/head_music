# frozen_string_literal: true

require 'spec_helper'

# A Solmization is a system of attributing a distinct syllable to each note in a musical scale.
describe HeadMusic::Solmization do
  describe 'construction' do
    context 'without an argument' do
      subject(:solmization) { described_class.get }

      it 'assumes modern solfège' do
        expect(solmization.name).to eq 'solfège'
      end

      its(:syllables) { are_expected.to eq %w[do re mi fa sol la ti] }
    end
  end
end
