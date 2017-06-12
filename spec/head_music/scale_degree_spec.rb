require 'spec_helper'

describe ScaleDegree do
  describe '.for' do
    subject(:scale_degree) { ScaleDegree.new(key_signature, spelling) }

    context 'when given the key of C minor' do
      let(:key_signature) { KeySignature.get('C minor') }

      context "and the spelling 'D'" do
        let(:spelling) { Spelling.get('D') }

        its(:degree) { is_expected.to eq 2 }
        its(:accidental) { is_expected.to eq nil }
        its(:name_for_degree) { is_expected.to eq 'supertonic' }

        it { is_expected.to eq '2' }
      end

      context "and the spelling 'Db'" do
        let(:spelling) { Spelling.get('Db') }

        it { is_expected.to eq 'b2' }
      end

      context "and the spelling 'B'" do
        let(:spelling) { Spelling.get('B') }

        it { is_expected.to eq '#7' }
        its(:degree) { is_expected.to eq 7 }
        its(:accidental) { is_expected.to eq '#' }
        its(:name_for_degree) { is_expected.to eq 'leading tone' }
      end
    end
  end
end
