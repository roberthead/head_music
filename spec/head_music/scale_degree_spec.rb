require "spec_helper"

describe HeadMusic::ScaleDegree do
  subject(:scale_degree) { described_class.new(key_signature, spelling) }

  context "when given the key of C minor" do
    let(:key_signature) { HeadMusic::KeySignature.get("C minor") }

    context "and the spelling 'D'" do
      let(:spelling) { HeadMusic::Spelling.get("D") }

      its(:degree) { is_expected.to eq 2 }
      its(:alteration) { is_expected.to be_nil }
      its(:name_for_degree) { is_expected.to eq "supertonic" }

      it { is_expected.to eq "2" }

      specify do
        third_scale_degree = described_class.new(key_signature, HeadMusic::Spelling.get("Eb"))
        expect(scale_degree).to be < third_scale_degree
      end
    end

    context "and the spelling 'Db'" do
      let(:spelling) { HeadMusic::Spelling.get("Db") }

      it { is_expected.to eq "♭2" }
    end

    context "and the spelling 'B'" do
      let(:spelling) { HeadMusic::Spelling.get("B") }

      it { is_expected.to eq "♯7" }
      its(:degree) { is_expected.to eq 7 }
      its(:alteration) { is_expected.to eq "♯" }
      its(:name_for_degree) { is_expected.to eq "leading tone" }

      it { is_expected.to be > described_class.new(key_signature, "E") }
    end
  end
end
