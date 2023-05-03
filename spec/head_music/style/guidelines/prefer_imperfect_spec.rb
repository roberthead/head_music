# frozen_string_literal: true

require "spec_helper"

describe HeadMusic::Style::Guidelines::PreferImperfect do
  subject { described_class.new(counterpoint) }

  let(:composition) { HeadMusic::Composition.new(key_signature: "D dorian") }
  let(:counterpoint) do
    composition.add_voice(role: :counterpoint).tap do |voice|
      counterpoint_pitches.each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1:0", :whole, pitch)
      end
    end
  end
  let(:cantus_firmus_pitches) { %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4] }

  before do
    composition.add_voice(role: :cantus_firmus).tap do |voice|
      cantus_firmus_pitches.each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1:0", :whole, pitch)
      end
    end
  end

  context "with no notes" do
    let(:counterpoint_pitches) { [] }

    it { is_expected.to be_adherent }
  end

  context "with mostly imperfect consonances" do
    let(:counterpoint_pitches) { %w[D5 A4 C5 B4 E5 A4 C5 D5 A4 C5 D5] }

    it { is_expected.to be_adherent }
  end

  context "with half perfect consonances in the middle" do
    let(:counterpoint_pitches) { %w[D5 C5 B4 D5 E5 C5 C5 D5 F5 C5 D5] }
    let(:cantus_firmus_pitches) { %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4] }

    its(:fitness) { is_expected.to be < 1 }
  end
end
