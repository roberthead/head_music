require "spec_helper"

# The committed MEI documents in spec/fixtures/notation/mei/, which
# `rake mei:golden_fixtures` regenerates.
describe HeadMusic::Notation::MEI do
  it "pins a golden document for every MEIFixtures render, and only those" do
    committed = Dir[File.join(MEIFixtures::DIRECTORY, "*.mei")].map { |path| File.basename(path, ".mei") }
    expect(committed).to match_array MEIFixtures.names
  end

  MEIFixtures.names.each do |name|
    describe name do
      let(:committed) { File.read(MEIFixtures.path(name)) }
      let(:document) { parse_mei(committed) }

      it "matches a fresh render" do
        expect(MEIFixtures.mei(name)).to eq committed
      end

      it "renders the same document twice" do
        first = MEIFixtures.mei(name)
        expect(MEIFixtures.mei(name)).to eq first
      end

      it "embeds the gem's version" do
        expect(mei_attributes(document, "//mei:application", "version")).to eq [HeadMusic::VERSION]
      end

      it "gives every element from the mdiv down an id" do
        expect(mei_elements_without_ids(document)).to eq []
      end

      it "writes unique ids of lowercase letters, digits, and hyphens, starting with a letter" do
        ids = mei_ids(document)
        expect([ids.grep_v(/\A[a-z][a-z0-9-]*\z/), ids.length - ids.uniq.length]).to eq [[], 0]
      end

      it "resolves every @startid, @endid, and @plist" do
        expect(mei_reference_problems(document)).to eq []
      end
    end
  end
end
