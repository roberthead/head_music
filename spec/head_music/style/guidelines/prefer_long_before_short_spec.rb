require "spec_helper"

describe HeadMusic::Style::Guidelines::PreferLongBeforeShort do
  subject(:guideline) { assess(described_class, voice) }

  def counterpoint(abc, meter: "4/4", cantus_firmus: "D4|F4|E4|D4|]")
    HeadMusic::Notation::ABC.parse(
      species_abc(source: "example", meter: meter, cantus_firmus: cantus_firmus, counterpoint: abc)
    ).counterpoint_voice
  end

  it "is weak" do
    expect(described_class.strength).to eq :weak
  end

  context "with no notes" do
    let(:voice) { HeadMusic::Content::Flow.new.add_voice(role: :counterpoint) }

    it { is_expected.to be_adherent }
  end

  context "with two quarters and a half that closes the bar" do
    let(:voice) { counterpoint("z2 A2|c B A2|B2 c2|d4|]") }

    its(:marks_count) { is_expected.to eq 1 }
    its(:first_mark_code) { is_expected.to eq "2:1:000 to 3:1:000" }
  end

  context "with the half tied forward" do
    let(:voice) { counterpoint("z2 A2|c B A2-|A2 G2|A4|]") }

    it { is_expected.to be_adherent }
  end

  context "with a half before the quarters" do
    let(:voice) { counterpoint("z2 A2|B2 c B|A2 c2|d4|]") }

    it { is_expected.to be_adherent }
  end

  context "with a bar entered by a tie" do
    let(:voice) { counterpoint("z2 A2-|A B c2|B2 c2|d4|]") }

    it { is_expected.to be_adherent }
  end

  context "with a triple-meter bar" do
    let(:voice) { counterpoint("z A B|c B A|B c d|e3|]", meter: "3/4", cantus_firmus: "D3|F3|E3|D3|]") }

    it { is_expected.to be_adherent }
  end

  context "with Fux's figure 88a" do
    let(:voice) { fux_fifth_species_example("88a").counterpoint_voice }

    it "marks the bar Fux marks N.B." do
      expect(guideline.marks.map(&:code)).to eq ["5:1:000 to 6:1:000"]
    end
  end

  context "with every other Fux fifth-species figure" do
    it "finds no static point" do
      fux_fifth_species_examples.reject { |example| example.source.end_with?("88a") }.each do |example|
        expect(assess(described_class, example.counterpoint_voice)).to be_adherent, example.source
      end
    end
  end
end
