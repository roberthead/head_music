require 'spec_helper'

describe HeadMusic::Style::Annotations::PermittedIntervals do
  let(:composition) { Composition.new(name: "CF in C Major", key_signature: 'C Major') }
  let(:voice) { Voice.new(composition: composition) }
  subject { described_class.new(voice) }

  context 'with no notes' do
    its(:fitness) { is_expected.to eq 1 }
  end

  context 'with one note' do
    before do
      voice.place("1:1", :whole, 'C')
    end

    its(:fitness) { is_expected.to eq 1 }
    its(:marks) { are_expected.to be_empty }
  end

  context 'with only permitted intervals' do
    before do
      %w[C E D G F E D A G B C5].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq 1 }
    its(:marks) { are_expected.to be_empty }
  end

  context 'with an octave leap' do
    before do
      %w[C D E C C5 B A F G E F D C].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq 1 }
    its(:marks) { are_expected.to be_empty }
  end

  context 'with an ascending minor sixth' do
    before do
      %w[C D E C5 B A G E F D C].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq 1 }
    its(:marks) { are_expected.to be_empty }
  end

  context 'with a descending minor sixth' do
    before do
      %w[C E G A B C5 E D C].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq PENALTY_FACTOR }
    its(:first_mark_code) { is_expected.to eq "6:1:000 to 8:1:000" }
  end

  context 'with a major sixth' do
    before do
      %w[C D E D B A G E F D C].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq PENALTY_FACTOR }
    its(:first_mark_code) { is_expected.to eq "4:1:000 to 6:1:000" }
  end

  context 'with a tritone' do
    before do
      %w[C D E F B A B C5].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq PENALTY_FACTOR }
    its(:first_mark_code) { is_expected.to eq "4:1:000 to 6:1:000" }
  end
end
