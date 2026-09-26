require "spec_helper"

describe HeadMusic::Rudiment::Ornament do
  describe ".all" do
    it "lists the ornaments in catalog order" do
      expect(described_class.all.map(&:name_key)).to eq %w[trill mordent inverted_mordent turn]
    end
  end

  describe ".get" do
    it "finds an ornament from a kebab-case string" do
      expect(described_class.get("inverted-mordent").name_key).to eq "inverted_mordent"
    end

    %w[lower_mordent mordent_lower].each do |alias_key|
      it "finds the lower mordent as #{alias_key}" do
        expect(described_class.get(alias_key)).to be described_class.get(:mordent)
      end
    end

    %w[upper_mordent pralltriller Pralltriller].each do |alias_key|
      it "finds the upper mordent as #{alias_key}" do
        expect(described_class.get(alias_key)).to be described_class.get(:inverted_mordent)
      end
    end
  end

  describe "#name" do
    it "names the inverted mordent in English" do
      expect(described_class.get(:inverted_mordent).name).to eq "inverted mordent"
    end

    it "names the trill in each language" do
      trill = described_class.get(:trill)
      names = %i[de es fr it ru].map { |locale_code| trill.name(locale_code: locale_code) }
      expect(names).to eq %w[Triller trino trille trillo трель]
    end
  end
end
