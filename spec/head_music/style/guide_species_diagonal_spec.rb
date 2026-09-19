require "spec_helper"

# Each species composite grades its own species highest. A composite that
# cannot tell its species from another has a melody guide that never asks for
# the rhythm the species teaches, which is the defect FourthSpeciesMelody had.
#
# The fixtures are parsed once and every guide grades every voice once, so the
# examples read cells of one matrix rather than each regrading the corpus.
describe HeadMusic::Style::Guide do
  fixtures_by_species = {
    "first_species" => :fux_first_species_examples,
    "second_species" => :fux_second_species_examples,
    "third_species" => :fux_third_species_examples,
    "third_species_triple_meter" => :third_species_triple_meter_examples,
    "fourth_species" => :fux_fourth_species_examples,
    "fifth_species" => :fux_fifth_species_examples
  }.freeze

  voices_by_species = fixtures_by_species.transform_values do |fixture_method|
    send(fixture_method).reject { |context| context.expected_messages.any? }.map(&:counterpoint_voice)
  end.freeze

  fitness_by_guide = Hash.new do |memo, guide_key|
    guide = described_class.get!(guide_key)
    memo[guide_key] = voices_by_species.transform_values { |voices| voices.map { |voice| guide.assess(voice).fitness } }
  end

  own_and_others = lambda do |guide_key, species|
    by_species = fitness_by_guide[guide_key]
    [by_species.fetch(species).min, by_species.except(species).values.flatten.max]
  end

  # first_three_species is a union of species rather than one, so it has no
  # diagonal to sit on.
  it "has a fixture for every species composite" do
    expect(fixtures_by_species.keys.sort)
      .to eq((described_class::COMPOSITE_MEMBERS.keys - ["first_three_species"]).sort)
  end

  fixtures_by_species.each_key do |species|
    context "for #{species}" do
      it "grades its own species at least as high as any other on the composite" do
        # Fux delays the resolution of the bar 9 suspension by an interpolated
        # consonance, which SuspensionTreatment does not yet recognize, so the
        # harmony side grades his florid line below a fourth-species one. See
        # user-stories/backlog/embellish-fifth-species-suspensions.md.
        pending "fifth species harmony rejects Fux's delayed resolution" if species == "fifth_species"
        own, others = own_and_others.call(species, species)
        expect(own).to be >= others
      end

      it "grades its own species at least as high as any other on the melody guide" do
        own, others = own_and_others.call("#{species}_melody", species)
        expect(own).to be >= others
      end
    end
  end

  it "discounts a first-species line on the fourth-species composite" do
    expect(fitness_by_guide["fourth_species"].fetch("first_species").max).to be <= 0.85
  end
end
