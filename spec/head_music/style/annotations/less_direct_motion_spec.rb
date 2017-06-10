require 'spec_helper'

describe HeadMusic::Style::Annotations::LessDirectMotion do
  let(:composition) { Composition.new(key_signature: 'D dorian') }

  let(:cantus_firmus_pitches) { %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4] }
  let(:counterpoint_pitches) { [] }

  let!(:cantus_firmus) do
    composition.add_voice(role: :cantus_firmus).tap do |voice|
      cantus_firmus_pitches.each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1:0", :whole, pitch)
      end
    end
  end

  let(:counterpoint) do
    composition.add_voice(role: :counterpoint).tap do |voice|
      counterpoint_pitches.each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1:0", :whole, pitch)
      end
    end
  end

  subject { described_class.new(counterpoint) }

  context 'with no notes' do
    let(:counterpoint_pitches) { [] }

    its(:fitness) { is_expected.to eq 1 }
  end

  context 'with one note' do
    let(:counterpoint_pitches) { %w[F4] }

    its(:fitness) { is_expected.to eq 1 }
  end

  context 'with all parallel motion' do
    let(:counterpoint_pitches) { %w[F4 A4 G4 F4 B4 A4 C5 B4 A4 G4 F4] }

    its(:fitness) { is_expected.to be < HeadMusic::PENALTY_FACTOR }
  end

  context 'with half direct motion' do
    let(:counterpoint_pitches) { %w[D5 A4 G4 B4 D5 F5 A5 D5 A4 C5 D5] }
    let(:cantus_firmus_pitches) {%w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4] }

    its(:fitness) { is_expected.to eq 1 }
  end

  context 'with a little more than half direct motion' do
    let(:counterpoint_pitches) { %w[D5 A4 G4 B4 D5 C5 E5 D5 A4 C5 D5] }

    its(:fitness) { is_expected.to be < 1 }
  end

  context 'with mostly contrary motion' do
    let(:counterpoint_pitches) { %w[D5 A4 B4 C5 B4 D5 C5 D5 A4 C5 D5] }

    its(:fitness) { is_expected.to eq 1 }
  end
end
