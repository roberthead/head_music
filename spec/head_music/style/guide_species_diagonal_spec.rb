require "spec_helper"

# Each species composite grades its own species highest. A composite that
# cannot tell its species from another has a melody guide that never asks for
# the rhythm the species teaches, which is the defect FourthSpeciesMelody had.
describe HeadMusic::Style::Guide do
  fixtures_by_species = {
    "first_species" => :fux_first_species_examples,
    "second_species" => :fux_second_species_examples,
    "third_species" => :fux_third_species_examples,
    "third_species_triple_meter" => :third_species_triple_meter_examples,
    "fourth_species" => :fux_fourth_species_examples,
    "fifth_species" => :fux_fifth_species_examples
  }.freeze

  # first_three_species is a union of species rather than one, so it has no
  # diagonal to sit on.
  it "has a fixture for every species composite" do
    expect(fixtures_by_species.keys.sort)
      .to eq((described_class::COMPOSITE_MEMBERS.keys - ["first_three_species"]).sort)
  end

  def valid_voices(fixture_method)
    send(fixture_method).reject { |context| context.expected_messages.any? }.map(&:counterpoint_voice)
  end

  def fitnesses(guide_key, voices)
    guide = described_class.get!(guide_key)
    voices.map { |voice| guide.assess(voice).fitness }
  end

  fixtures_by_species.each do |species, fixture_method|
    context "for #{species}" do
      let(:own_voices) { valid_voices(fixture_method) }
      let(:other_voices) do
        fixtures_by_species.except(species).values.flat_map { |method| valid_voices(method) }
      end

      it "grades its own species at least as high as any other on the composite" do
        # Fux delays the resolution of the bar 9 suspension by an interpolated
        # consonance, which SuspensionTreatment does not yet recognize, so the
        # harmony side grades his florid line below a fourth-species one. See
        # user-stories/backlog/embellish-fifth-species-suspensions.md.
        pending "fifth species harmony rejects Fux's delayed resolution" if species == "fifth_species"
        expect(fitnesses(species, own_voices).min).to be >= fitnesses(species, other_voices).max
      end

      it "grades its own species at least as high as any other on the melody guide" do
        melody_key = "#{species}_melody"
        expect(fitnesses(melody_key, own_voices).min).to be >= fitnesses(melody_key, other_voices).max
      end
    end
  end

  describe "fourth species" do
    let(:first_species_voices) { valid_voices(:fux_first_species_examples) }
    let(:fourth_species_voice) { valid_voices(:fux_fourth_species_examples).first }

    it "discounts a first-species line on the melody guide" do
      expect(fitnesses("fourth_species_melody", first_species_voices).max).to be <= 0.75
    end

    it "discounts a first-species line on the composite" do
      expect(fitnesses("fourth_species", first_species_voices).max).to be <= 0.85
    end

    it "grades Fux's fourth-species line highly on the melody guide" do
      expect(fitnesses("fourth_species_melody", [fourth_species_voice]).first).to be >= 0.95
    end

    it "finds Fux's fourth-species line adherent to SustainAcrossBarlines" do
      assessment = assess(HeadMusic::Style::Guidelines::SustainAcrossBarlines, fourth_species_voice)
      expect(assessment).to be_adherent
    end
  end
end
