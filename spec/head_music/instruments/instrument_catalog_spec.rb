require "spec_helper"

describe HeadMusic::Instruments::InstrumentCatalog do
  subject(:catalog) { described_class.new(records) }

  let(:records) do
    {
      "violin" => {"family_key" => "violin"},
      "clarinet_in_a" => {"parent_key" => "clarinet", "alias_name_keys" => ["a_clarinet"]}
    }
  end

  describe "#record_for" do
    it "finds a record by its key and merges in the name_key" do
      expect(catalog.record_for("violin")).to eq("family_key" => "violin", "name_key" => "violin")
    end

    it "matches a key regardless of the name's formatting" do
      expect(catalog.record_for("Violin")).to include("name_key" => "violin")
    end

    it "finds a record by one of its aliases" do
      expect(catalog.record_for("a_clarinet")).to include("name_key" => "clarinet_in_a")
    end

    it "returns nil when nothing matches" do
      expect(catalog.record_for("theremin")).to be_nil
    end
  end
end
