require "spec_helper"

describe HeadMusic::Style::Analysis do
  subject(:analysis) { described_class.new(guide, voice) }

  let(:voice) { HeadMusic::Content::Voice.new }
  let(:guide) { HeadMusic::Style::Guides::FuxCantusFirmus }

  its(:guide) { is_expected.to eq HeadMusic::Style::Guides::FuxCantusFirmus }
  its(:voice) { is_expected.to be voice }
  its(:annotations) { are_expected.to be_an(Array) }
  its(:fitness) { is_expected.to be_a(Float) }
end
