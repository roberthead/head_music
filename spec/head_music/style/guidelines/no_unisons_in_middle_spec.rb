# frozen_string_literal: true

require "spec_helper"

describe HeadMusic::Style::Guidelines::NoUnisonsInMiddle do
  subject { described_class.new(counterpoint) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian") }
  let(:cantus_firmus_pitches) { %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4] }
  let(:counterpoint) do
    composition.add_voice(role: :counterpoint).tap do |voice|
      counterpoint_pitches.each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1:0", :whole, pitch)
      end
    end
  end

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

  context "with no unisons" do
    let(:counterpoint_pitches) { %w[D5 A4 C5 B4 D5 A4 E5 D5 A4 C5 D5] }

    it { is_expected.to be_adherent }
  end

  context "with a unison at the beginning and end" do
    let(:counterpoint_pitches) { %w[D4 A4 C5 B4 D5 A4 E5 D5 A4 G4 D4] }

    it { is_expected.to be_adherent }
  end

  context "with a unison in the middle" do
    let(:counterpoint_pitches) { %w[D5 A4 C5 B4 D5 C5 A4 D5 A4 C5 D5] }

    its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
  end
end
