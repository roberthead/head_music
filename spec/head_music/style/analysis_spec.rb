require 'spec_helper'

describe HeadMusic::Style::Analysis do
  let(:voice) { Voice.new }
  let(:rule) { HeadMusic::Style::Rules::RequireNotes }
  subject(:analysis) { HeadMusic::Style::Analysis.new(rule, voice) }

  context 'with no notes' do
    its(:score) { is_expected.to eq 0 }
  end
end
