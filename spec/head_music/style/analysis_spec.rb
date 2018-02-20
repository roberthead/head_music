# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Style::Analysis do
  let(:voice) { Voice.new }
  let(:ruleset) { HeadMusic::Style::Rulesets::FuxCantusFirmus }
  subject(:analysis) { HeadMusic::Style::Analysis.new(ruleset, voice) }

  its(:ruleset) { is_expected.to eq HeadMusic::Style::Rulesets::FuxCantusFirmus }
  its(:subject) { is_expected.to be voice }
  its(:annotations) { are_expected.to be_an(Array) }
  its(:fitness) { is_expected.to be_a(Float) }
end
