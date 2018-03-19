# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Style::Guidelines::ModerateDirectionChanges do
  let(:composition) { HeadMusic::Composition.new(key_signature: 'D dorian') }
  let(:voice) { HeadMusic::Voice.new(composition: composition) }
  subject { described_class.new(voice) }

  context 'when there are no notes' do
    it { is_expected.to be_adherent }
  end

  context 'when the notes are all ascending' do
    before do
      %w[D4 E4 F4 G4 A4 B4 C5 D5].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to be <= HeadMusic::PENALTY_FACTOR }
    its(:first_mark_code) { is_expected.to eq '1:1:000 to 9:1:000' }
  end

  context 'when the notes are all descending' do
    before do
      %w[D5 C5 B A G F E D].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to be <= HeadMusic::PENALTY_FACTOR }
    its(:first_mark_code) { is_expected.to eq '1:1:000 to 9:1:000' }
  end

  context 'when the direction changes only once' do
    before do
      %w[D4 E4 F4 G4 A4 G4 F4 E4 D4].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to be >= HeadMusic::PENALTY_FACTOR }
  end

  context 'when the direction changes twice' do
    before do
      %w[D4 E4 F4 G4 F4 G4 A4 B4 C5 D5].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    it { is_expected.to be_adherent }
  end

  context 'when the direction changes frequently' do
    before do
      %w[D4 E4 F4 G4 F4 A4 G4 B4 C5 D5].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    it { is_expected.to be_adherent }
  end
end
