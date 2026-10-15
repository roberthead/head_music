require "spec_helper"

# xmllint's RelaxNG pass skips MEI's Schematron rules, so the ids and the
# references to them are checked here, for every fixture.
describe HeadMusic::Notation::MEI do
  MEIHelpers.sample_flows.each do |name, build|
    refusal = MEIHelpers::REFUSED_SAMPLES[name]

    if refusal
      it "refuses #{name}" do
        expect { described_class.render(instance_exec(&build)) }.to raise_error(described_class::RenderError, refusal)
      end

      next
    end

    describe name do
      let(:document) { parse_mei(described_class.render(instance_exec(&build))) }

      it "gives every element from the mdiv down a unique id that every reference resolves to" do
        expect([mei_elements_without_ids(document), mei_reference_problems(document)]).to eq [[], []]
      end

      it "writes only ids of lowercase letters, digits, and hyphens, starting with a letter" do
        expect(mei_ids(document).grep_v(/\A[a-z][a-z0-9-]*\z/)).to eq []
      end
    end
  end
end
