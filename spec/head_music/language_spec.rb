# frozen_string_literal: true

require 'spec_helper'

describe Language do
  specify { expect(Language.default).to eq Language.english }
  specify { expect(Language.english).to eq Language.american_english }

  context '.default' do
    subject(:language) { Language.default }

    it { is_expected.to eq Language.english }
  end

  context '.english' do
    subject(:language) { Language.english }

    it { is_expected.to eq Language.american_english }
  end

  context '.british_english' do
    subject(:language) { Language.british_english }

    it { is_expected.not_to eq Language.american_english }
  end

  context '.french' do
    subject(:language) { Language.french }

    its(:native_name) { is_expected.to eq 'Français' }
  end
end
