require 'spec_helper'

describe HeadMusic::Style::Rulesets::FuxCantusFirmus do
  subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, voice) }


  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::AlwaysMove }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::AtLeastEightNotes }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::ConsonantClimax }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::Diatonic }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::EndOnTonic }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::FrequentDirectionChanges }
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

  describe 'Population A — Correct' do
    context 'from Fux' do
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
  end

  describe 'Population B — Incorrect' do

  end

  describe 'Population C — Error introduced' do
    context 'modified from Fux' do
      fux_cantus_firmus_examples_with_errors.each do |cf_example|
        context "#{cf_example[:pitches].join(' ')} in #{cf_example[:key]} when #{cf_example[:modification]}" do
          let(:composition) { Composition.new(name: "CF in #{cf_example[:key]}", key_signature: cf_example[:key]) }
          let(:voice) { Voice.new(composition: composition) }

          before do
            cf_example[:pitches].each.with_index(1) do |pitch, bar|
              voice.place("#{bar}:1", :whole, pitch)
            end
          end

          it { is_expected.not_to be_adherent }
          its(:messages) { are_expected.to include(cf_example[:expected_message]) }
        end
      end
    end
  end

  context 'from other authors' do
    # context 'with Theory and Analysis examples' do
    #   theory_and_analysis_cantus_firmus_examples.each do |cf_example|
    #     context "#{cf_example[:pitches].join(' ')} in #{cf_example[:key]}" do
    #       let(:composition) { Composition.new(name: "CF in #{cf_example[:key]}", key_signature: cf_example[:key]) }
    #       let(:voice) { Voice.new(composition: composition) }
    #
    #       before do
    #         cf_example[:pitches].each.with_index(1) do |pitch, bar|
    #           voice.place("#{bar}:1", :whole, pitch)
    #         end
    #       end
    #
    #       its(:messages) { are_expected.to eq [] }
    #     end
    #   end
    # end
    #
    # context 'with Schoenberg examples' do
    #   schoenberg_cantus_firmus_examples.each do |cf_example|
    #     context "#{cf_example[:pitches].join(' ')} in #{cf_example[:key]}" do
    #       let(:composition) { Composition.new(name: "CF in #{cf_example[:key]}", key_signature: cf_example[:key]) }
    #       let(:voice) { Voice.new(composition: composition) }
    #
    #       before do
    #         cf_example[:pitches].each.with_index(1) do |pitch, bar|
    #           voice.place("#{bar}:1", :whole, pitch)
    #         end
    #       end
    #
    #       its(:messages) { are_expected.to eq [] }
    #     end
    #   end
    # end
    #
    # context 'with Davis and Lybbert examples' do
    #   davis_and_lybbert_cantus_firmus_examples.each do |cf_example|
    #     context "#{cf_example[:pitches].join(' ')} in #{cf_example[:key]}" do
    #       let(:composition) { Composition.new(name: "CF in #{cf_example[:key]}", key_signature: cf_example[:key]) }
    #       let(:voice) { Voice.new(composition: composition) }
    #
    #       before do
    #         cf_example[:pitches].each.with_index(1) do |pitch, bar|
    #           voice.place("#{bar}:1", :whole, pitch)
    #         end
    #       end
    #
    #       its(:messages) { are_expected.to eq [] }
    #     end
    #   end
    # end
  end
end
