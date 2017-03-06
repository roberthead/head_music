require 'spec_helper'

describe HeadMusic::Style::Analysis do
  let(:voice) { Voice.new }
  let(:rule) { HeadMusic::Style::Rules::AtLeastEightNotes }
  subject(:analysis) { HeadMusic::Style::Analysis.new(rule, voice) }

  context 'with no notes' do
    its(:fitness) { is_expected.to be 0 }
  end
end
