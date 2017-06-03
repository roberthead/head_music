require 'spec_helper'

describe Voice do
  let(:composition) { Composition.new }
  subject(:voice) { Voice.new(composition: composition) }

  its(:composition) { is_expected.to eq composition }

  describe '#place' do
    it 'adds a placement' do
      position = Position.new(composition, "5:1:0")
      expect {
        voice.place(position, :quarter)
      }.to change {
        voice.placements.length
      }.by 1
    end

    describe 'sorting' do
      let!(:placement1) { voice.place(Position.new(composition, "5:1:0"), :quarter) }
      let!(:placement2) { voice.place(Position.new(composition, "4:3:0"), :quarter) }

      it 'sorts by position' do
        expect(voice.placements).to eq [placement2, placement1]
      end
    end
  end

  describe '#notes and #rests' do
    let!(:note1) { voice.place(Position.new(composition, "1:1:0"), :quarter, 'D') }
    let!(:rest1) { voice.place(Position.new(composition, "1:2:0"), :quarter) }
    let!(:note2) { voice.place(Position.new(composition, "1:3:0"), :quarter, 'G') }
    let!(:rest2) { voice.place(Position.new(composition, "1:4:0"), :quarter) }

    its(:notes) { are_expected.to eq [note1, note2] }
    its(:rests) { are_expected.to eq [rest1, rest2] }
  end

  describe '#notes_not_in_key' do
    context 'with some accidentals' do
      before do
        %w[C D E F# G E C Bb3 C].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      it 'returns the notes not in the key' do
        expect(voice.notes_not_in_key.length).to eq 2
        expect(voice.notes_not_in_key.map(&:pitch)).to eq %w[F#4 Bb3]
      end
    end
  end

  describe 'melody' do
    before do
      %w[G3 C4 D4 Eb4 F4 Eb G3].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    it 'determines the intervals' do
      expect(voice.melodic_intervals.map(&:shorthand)).to eq %w[P4 M2 m2 M2 M2 m6]
    end

    its(:range) { is_expected.to eq 'minor seventh' }
    its(:highest_pitch) { is_expected.to eq 'F4' }
    its(:lowest_pitch) { is_expected.to eq 'G3' }
    its(:highest_notes) { are_expected.to eq [voice.notes[4]] }
    its(:lowest_notes) { is_expected.to eq [voice.notes.first, voice.notes.last] }
  end

  context 'when a role is provided' do
    subject(:voice) { Voice.new(composition: composition, role: 'Cantus Firmus') }

    its(:role) { is_expected.to eq 'Cantus Firmus' }
    it { is_expected.to be_cantus_firmus }
  end
end
