require 'spec_helper'

describe HeadMusic::Style::Annotation do
  let(:voice) { Voice.new }

  context 'when the voice is compliant' do
    subject(:annotation) { HeadMusic::Style::Annotations::UpToThirteenNotes.new(voice) }

    it { is_expected.to be_perfect }
  end

  context 'when the voice is not compliant' do
    subject(:annotation) { HeadMusic::Style::Annotations::AtLeastEightNotes.new(voice) }

    it { is_expected.not_to be_perfect }
  end
end
