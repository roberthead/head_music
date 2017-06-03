require 'spec_helper'

describe HeadMusic::Style::Annotations::OneToOne do
  let(:composition) { Composition.new(key_signature: 'D dorian') }
  let(:counterpoint) { composition.add_voice(role: 'counterpoint') }

  subject { described_class.new(counterpoint) }

  context 'without another voice' do
    its(:fitness) { is_expected.to eq 1 }
  end

  context 'with another voice' do
    let!(:cantus_firmus) do
      counterpoint.composition.add_voice(role: "cantus firmus").tap do |cantus|
        %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4].each_with_index do |pitch, bar|
          cantus.place("#{bar + 1}:1", :whole, pitch)
        end
      end
    end

    context 'with no notes' do
      its(:fitness) { is_expected.to be_within(0.01).of(HeadMusic::PENALTY_FACTOR**11) }
    end

    context 'with only one note' do
      before do
        counterpoint.place("1:1", :whole, 'D5')
      end

      its(:fitness) { is_expected.to be < HeadMusic::PENALTY_FACTOR }
    end

    context 'with a whole note for each whole note in the Cantus' do
      before do
        %w[D5 C5 B4 A4 G4 A4 B4 C5 B4 C5 D5].each_with_index do |pitch, bar|
          counterpoint.place("#{bar + 1}:1", :whole, pitch)
        end
      end

      its(:fitness) { is_expected.to eq 1 }
    end

    context 'with an extra note' do
      before do
        %w[D5 C5 B4 A4 G4 A4 B4 C5 A4 B4 C5 D5].each_with_index do |pitch, bar|
          counterpoint.place("#{bar + 1}:1", :whole, pitch)
        end
      end

      its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
    end

    context 'with a missing note' do
      before do
        %w[D5 C5 B4 G4 A4 B4 C5 A4 C5 D5].each_with_index do |pitch, bar|
          counterpoint.place("#{bar + 1}:1", :whole, pitch)
        end
      end

      its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
    end

    context 'with half notes' do
      before do
        %w[D5 C5 B4 G4 A4 B4 C5 A4 C5 D5 C5 B4 G4 A4 B4 C5 A4 C5 D5].each_with_index do |pitch, pulse|
          counterpoint.place("#{pulse / 2 + 1}:#{(pulse % 2) * 2 + 1}", :half, pitch)
        end
      end

      its(:fitness) { is_expected.to be < HeadMusic::PENALTY_FACTOR }
    end
  end
end
