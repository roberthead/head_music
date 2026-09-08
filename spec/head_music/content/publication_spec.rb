require "spec_helper"

describe HeadMusic::Content::Publication do
  subject(:publication) do
    described_class.new(
      title: "Gradus ad Parnassum",
      edition: "2nd",
      year: 1725,
      publisher: "Van Ghelen",
      abbreviation: "Fux",
      notes: "A foundational text on counterpoint.",
      credits: [HeadMusic::Content::Credit.new(person: "Johann Joseph Fux", role: :author)]
    )
  end

  its(:title) { is_expected.to eq "Gradus ad Parnassum" }
  its(:edition) { is_expected.to eq "2nd" }
  its(:year) { is_expected.to eq 1725 }
  its(:publisher) { is_expected.to eq "Van Ghelen" }
  its(:abbreviation) { is_expected.to eq "Fux" }
  its(:to_s) { is_expected.to eq "Gradus ad Parnassum" }
  its(:authors) { is_expected.to eq ["Johann Joseph Fux"] }

  it "is frozen" do
    expect(publication).to be_frozen
  end

  describe "a publication given only a title" do
    subject(:publication) { described_class.new(title: "Untitled") }

    its(:edition) { is_expected.to be_nil }
    its(:authors) { is_expected.to eq [] }
    its(:credits) { is_expected.to be_empty }
  end

  describe "value equality" do
    let(:twin) do
      described_class.new(
        title: "Gradus ad Parnassum",
        edition: "2nd",
        year: 1725,
        publisher: "Van Ghelen",
        abbreviation: "Fux",
        notes: "A foundational text on counterpoint.",
        credits: [HeadMusic::Content::Credit.new(person: "Johann Joseph Fux", role: :author)]
      )
    end

    it "equals a publication with the same fields" do
      expect(publication).to eq twin
    end

    it "differs from a publication with a different edition" do
      expect(publication).not_to eq described_class.new(title: "Gradus ad Parnassum", edition: "1st")
    end

    it "dedupes through uniq" do
      expect([publication, twin].uniq.size).to eq 1
    end
  end

  describe "the level constraint" do
    it "rejects a composer credit" do
      expect {
        described_class.new(title: "Anything", credits: [{"role" => "composer", "person" => {"full_name" => "Bach"}}])
      }.to raise_error(ArgumentError, "composer is a work role, not a publication role")
    end

    it "accepts editor, engraver, publisher, and author" do
      credits = %i[author editor engraver publisher].map do |role|
        HeadMusic::Content::Credit.new(person: "A. Person", role: role)
      end
      expect(described_class.new(title: "Anything", credits: credits).credits.size).to eq 4
    end
  end

  describe "serialization" do
    it "writes all seven keys" do
      expect(publication.to_h.keys).to contain_exactly(
        "title", "edition", "year", "publisher", "abbreviation", "notes", "credits"
      )
    end

    it "round-trips" do
      expect(described_class.from_h(publication.to_h)).to eq publication
    end

    it "round-trips through JSON" do
      expect(described_class.from_h(JSON.parse(publication.to_h.to_json))).to eq publication
    end
  end
end
