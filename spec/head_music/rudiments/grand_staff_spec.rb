# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::GrandStaff do
  describe '.get' do
    context 'given an instance' do
      let(:instance) { described_class.get('#') }

      it 'returns that instance' do
        expect(described_class.get(instance)).to be instance
      end
    end

    context 'given :piano' do
      subject(:grand_staff) { described_class.get(:piano) }

      its(:instrument) { is_expected.to eq :piano }

      specify { expect(grand_staff.staves.length).to eq 2 }

      specify { expect(grand_staff.staves[0].clef).to eq :treble_clef }
      specify { expect(grand_staff.staves[1].clef).to eq :bass_clef }

      specify { expect(grand_staff.staves[0].instrument).to eq :piano }
      specify { expect(grand_staff.staves[1].instrument).to eq :piano }

      specify { expect(grand_staff.brace_staves_index_first).to eq 0 }
      specify { expect(grand_staff.brace_staves_index_last).to eq 1 }
    end

    context 'given :organ' do
      subject(:grand_staff) { described_class.get(:organ) }

      its(:instrument) { is_expected.to eq :organ }

      specify { expect(grand_staff.staves.length).to eq 3 }

      specify { expect(grand_staff.staves[0].clef).to eq :treble_clef }
      specify { expect(grand_staff.staves[1].clef).to eq :bass_clef }
      specify { expect(grand_staff.staves[2].clef).to eq :bass_clef }

      specify { expect(grand_staff.staves[0].instrument).to eq :organ }
      specify { expect(grand_staff.staves[1].instrument).to eq :organ }
      specify { expect(grand_staff.staves[2].instrument).to eq :pedals }

      specify { expect(grand_staff.brace_staves_index_first).to eq 0 }
      specify { expect(grand_staff.brace_staves_index_last).to eq 1 }
    end
  end
end
