require 'spec_helper'

describe HeadMusic::Style::Rulesets::FuxCantusFirmus do
  subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, voice) }

  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::AlwaysMove }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::AtLeastEightNotes }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::ConsonantClimax }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::Diatonic }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::DirectionChanges }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::EndOnTonic }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::LimitOctaveLeaps }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::MostlyConjunct }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::NoRests }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::NotesSameLength }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::RecoverLargeLeaps }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::SingableIntervals }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::SingableRange }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::StartOnTonic }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::StepDownToFinalNote }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::UpToFourteenNotes }

  context 'with Fux examples' do
    fux_cantus_firmus_examples.each do |cf_example|
      context "#{cf_example[:pitches].join(' ')} in #{cf_example[:key]}" do
        let(:composition) { Composition.new(name: "CF in #{cf_example[:key]}", key_signature: cf_example[:key]) }
        let(:voice) { Voice.new(composition: composition) }
        before do
          cf_example[:pitches].each.with_index(1) do |pitch, bar|
            voice.place("#{bar}:1", :whole, pitch)
          end
        end

        it { is_expected.to be_adherent }
        its(:messages) { are_expected.to eq [] }
      end
    end
  end

  context 'with Davis and Lybbert examples' do
    davis_and_lybbert_cantus_firmus_examples.each do |cf_example|
      context "#{cf_example[:pitches].join(' ')} in #{cf_example[:key]}" do
        let(:composition) { Composition.new(name: "CF in #{cf_example[:key]}", key_signature: cf_example[:key]) }
        let(:voice) { Voice.new(composition: composition) }

        before do
          cf_example[:pitches].each.with_index(1) do |pitch, bar|
            voice.place("#{bar}:1", :whole, pitch)
          end
        end

        its(:fitness) { is_expected.to be >= PENALTY_FACTOR }
      end
    end
  end
end
