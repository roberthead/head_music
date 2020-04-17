# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Utilities::HashKey do
  describe '.for' do
    it 'strips diacritics' do
      expect(described_class.for('Violinschlüssel')).to eq :violinschlussel
    end
  end
end
