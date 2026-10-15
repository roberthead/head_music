require "spec_helper"

# Every ABC, LilyPond, kern, tuplet, hairpin, and MuseScore-render fixture
# renders as MEI, or is refused for the reason listed in
# MEIHelpers::REFUSED_SAMPLES.
describe HeadMusic::Notation::MEI do
  fixtures = MEIFixtures.every_fixture

  it "lists only refusals of fixtures that exist" do
    expect(MEIHelpers::REFUSED_SAMPLES.keys - fixtures.keys).to eq []
  end

  fixtures.each do |name, build|
    refusal = MEIHelpers::REFUSED_SAMPLES[name]

    if refusal
      it "refuses #{name}, matching #{refusal.inspect}" do
        expect { instance_exec(&build).to_mei }.to raise_error(described_class::RenderError, refusal)
      end
    else
      it "renders #{name} as an MEI document" do
        expect(parse_mei(instance_exec(&build).to_mei).root.name).to eq "mei"
      end
    end
  end
end
