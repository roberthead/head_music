# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Placement do
  let(:composition) { HeadMusic::Composition.new.tap(&:add_voice) }
  let(:voice) { composition.voices.first }
  let(:position) { '2:2:240' }
  let(:pitch) { HeadMusic::Pitch.get('F#4') }
  let(:rhythmic_value) { HeadMusic::RhythmicValue.new(:eighth) }

  subject(:placement) { described_class.new(voice, position, rhythmic_value, pitch) }

  its(:composition) { is_expected.to eq composition }
  its(:voice) { is_expected.to eq voice }
  its(:position) { is_expected.to eq HeadMusic::Position.new(composition, '2:2:240') }
  its(:pitch) { is_expected.to eq 'F#4' }

  context 'when pitch is omitted' do
    let(:pitch) { nil }

    it { is_expected.to be_rest }

    context 'when the rhythmic value is a thirty-second note' do
      let(:rhythmic_value) { HeadMusic::RhythmicValue.new(:'thirty-second') }

      its(:rhythmic_value) { is_expected.to eq 'thirty-second' }
    end
  end

  describe '#next_position' do
    specify { expect(placement.next_position).to eq '2:2:720' }

    context 'when the rhythmic value is longer than a measure' do
      let(:rhythmic_value) { HeadMusic::RhythmicValue.new(:breve) }

      specify { expect(placement.next_position).to eq '4:2:240' }
    end

    context 'when the value occurs at a fractional position' do
      let(:position) { '5:1:001' }
      let(:rhythmic_value) { HeadMusic::RhythmicValue.new(:'thirty-second') }

      specify { expect(placement.next_position).to eq '5:1:121' }
    end
  end

  describe '#during?' do
    let(:other_placement) { described_class.new(voice, '2:2:000', :quarter) }

    subject(:placement) { described_class.new(voice, position, rhythmic_value, pitch) }

    context 'when it starts before the other placement and ends at the start' do
      let(:position) { '2:1:000' }
      let(:rhythmic_value) { :quarter }

      specify do
        expect(placement.send(:starts_during?, other_placement)).to be_falsey
        expect(placement.send(:ends_during?, other_placement)).to be_falsey
        expect(placement.send(:wraps?, other_placement)).to be_falsey
      end

      it { is_expected.not_to be_during(other_placement) }
    end

    context 'when it starts at the same time as the other placement' do
      let(:position) { '2:2:000' }
      let(:rhythmic_value) { :eighth }

      specify do
        expect(placement.send(:starts_during?, other_placement)).to be_truthy
        expect(placement.send(:ends_during?, other_placement)).to be_truthy
        expect(placement.send(:wraps?, other_placement)).to be_falsey
      end

      it { is_expected.to be_during(other_placement) }
    end

    context 'when it starts during the other placement' do
      let(:position) { '2:2:480' }
      let(:rhythmic_value) { :quarter }

      specify do
        expect(placement.send(:starts_during?, other_placement)).to be_truthy
        expect(placement.send(:ends_during?, other_placement)).to be_falsey
        expect(placement.send(:wraps?, other_placement)).to be_falsey
      end

      it { is_expected.to be_during(other_placement) }
    end

    context 'when it starts after and ends before the other placement' do
      let(:position) { '2:2:240' }
      let(:rhythmic_value) { :sixteenth }

      specify do
        expect(placement.send(:starts_during?, other_placement)).to be_truthy
        expect(placement.send(:ends_during?, other_placement)).to be_truthy
        expect(placement.send(:wraps?, other_placement)).to be_falsey
      end

      it { is_expected.to be_during(other_placement) }
    end

    context 'when it starts before and ends after the other placement' do
      let(:position) { '2:1:000' }
      let(:rhythmic_value) { :whole }

      specify do
        expect(placement.send(:starts_during?, other_placement)).to be_falsey
        expect(placement.send(:ends_during?, other_placement)).to be_falsey
        expect(placement.send(:wraps?, other_placement)).to be_truthy
      end

      it { is_expected.to be_during(other_placement) }
    end

    context 'when it ends during the other placement' do
      let(:position) { '2:1:480' }
      let(:rhythmic_value) { :quarter }

      specify do
        expect(placement.send(:starts_during?, other_placement)).to be_falsey
        expect(placement.send(:ends_during?, other_placement)).to be_truthy
        expect(placement.send(:wraps?, other_placement)).to be_falsey
      end

      it { is_expected.to be_during(other_placement) }
    end

    context 'when it starts at the end of the other placement' do
      let(:position) { '2:3' }
      let(:rhythmic_value) { :quarter }

      specify do
        expect(placement.send(:starts_during?, other_placement)).to be_falsey
        expect(placement.send(:ends_during?, other_placement)).to be_falsey
        expect(placement.send(:wraps?, other_placement)).to be_falsey
      end

      it { is_expected.not_to be_during(other_placement) }
    end
  end
end
