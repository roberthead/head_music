# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Style::Analysis do
  let(:voice) { HeadMusic::Voice.new }
  let(:guide) { HeadMusic::Style::Guides::FuxCantusFirmus }
  subject(:analysis) { HeadMusic::Style::Analysis.new(guide, voice) }

  its(:guide) { is_expected.to eq HeadMusic::Style::Guides::FuxCantusFirmus }
  its(:voice) { is_expected.to be voice }
  its(:annotations) { are_expected.to be_an(Array) }
  its(:fitness) { is_expected.to be_a(Float) }
end
