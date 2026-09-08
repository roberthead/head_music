require "spec_helper"

describe HeadMusic::Content::Role do
  describe ".get" do
    it "gets by symbol" do
      expect(described_class.get(:composer).key).to eq :composer
    end

    it "gets by string" do
      expect(described_class.get("composer").key).to eq :composer
    end

    it "gets by a translated name" do
      expect(described_class.get("Komponist").key).to eq :composer
    end

    it "gets by a translated name in another locale" do
      expect(described_class.get("orchestrateur").key).to eq :orchestrator
    end

    it "gets by a translated name regardless of case" do
      expect(described_class.get("herausgeber").key).to eq :editor
    end

    it "answers a role given a role" do
      role = described_class.get(:engraver)

      expect(described_class.get(role)).to be role
    end

    it "memoizes one instance per key" do
      expect(described_class.get(:lyricist)).to be described_class.get("lyricist")
    end

    it "raises for an unknown identifier rather than minting a role" do
      expect { described_class.get(:producer) }.to raise_error(ArgumentError, /unknown credit role/)
    end

    it "raises for nil" do
      expect { described_class.get(nil) }.to raise_error(ArgumentError, /unknown credit role/)
    end
  end

  describe "#level" do
    specify { expect(described_class.get(:composer).level).to eq :work }
    specify { expect(described_class.get(:songwriter).level).to eq :work }
    specify { expect(described_class.get(:arranger).level).to eq :project }
    specify { expect(described_class.get(:transcriber).level).to eq :project }
    specify { expect(described_class.get(:author).level).to eq :publication }
    specify { expect(described_class.get(:publisher).level).to eq :publication }
  end

  describe ".for_level" do
    it "answers the work roles" do
      expect(described_class.for_level(:work).map(&:key))
        .to eq %i[composer songwriter lyricist librettist]
    end

    it "answers the project roles" do
      expect(described_class.for_level("project").map(&:key))
        .to eq %i[arranger transcriber orchestrator reconstructor]
    end

    it "answers the publication roles" do
      expect(described_class.for_level(:publication).map(&:key))
        .to eq %i[author editor engraver publisher]
    end

    it "raises for an unknown level" do
      expect { described_class.for_level(:layout) }.to raise_error(ArgumentError, /unknown credit level/)
    end
  end

  describe "#name" do
    subject(:role) { described_class.get(:composer) }

    specify { expect(role.name).to eq "composer" }
    specify { expect(role.name(locale_code: :de)).to eq "Komponist" }
    specify { expect(role.name(locale_code: :fr)).to eq "compositeur" }
    specify { expect(role.to_s).to eq "composer" }
  end

  describe "translations" do
    %i[en de es fr it ru].each do |locale_code|
      it "names every role in #{locale_code}" do
        names = described_class.all.map { |role| role.name(locale_code: locale_code) }

        expect(names).to all(be_a(String).and(satisfy { |name| !name.start_with?("Translation missing") }))
      end

      it "names every role distinctly in #{locale_code}" do
        names = described_class.all.map { |role| role.name(locale_code: locale_code) }

        expect(names.uniq.size).to eq described_class::KEYS.size
      end
    end
  end

  describe "equality" do
    specify { expect(described_class.get(:composer)).to eq described_class.get("Komponist") }
    specify { expect(described_class.get(:composer)).to eq :composer }
    specify { expect(described_class.get(:composer)).to eq "composer" }
    specify { expect(described_class.get(:composer)).not_to eq :lyricist }
    specify { expect(described_class.get(:composer)).not_to eq 42 }

    it "hashes by key" do
      expect([described_class.get(:composer), described_class.get("composer")].uniq.size).to eq 1
    end
  end

  describe "the vocabulary" do
    specify { expect(described_class::KEYS.size).to eq 12 }
    specify { expect(described_class::LEVELS).to eq %i[work project publication] }
    specify { expect(described_class::KEYS_BY_LEVEL).to be_frozen }
  end

  it "does not expose .new" do
    expect { described_class.new(:composer) }.to raise_error(NoMethodError)
  end
end
