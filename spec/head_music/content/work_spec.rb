require "spec_helper"

describe HeadMusic::Content::Work do
  subject(:work) do
    described_class.new(title: "Cello Suite No. 1", catalog_number: "BWV 1007", year: 1720, credits: [composer_credit])
  end

  let(:bach) { HeadMusic::Content::Person.new(full_name: "Johann Sebastian Bach") }
  let(:composer_credit) { HeadMusic::Content::Credit.new(person: bach, role: :composer) }

  its(:title) { is_expected.to eq "Cello Suite No. 1" }
  its(:catalog_number) { is_expected.to eq "BWV 1007" }
  its(:year) { is_expected.to eq 1720 }
  its(:composer) { is_expected.to eq "Johann Sebastian Bach" }
  its(:to_s) { is_expected.to eq "Cello Suite No. 1, BWV 1007" }

  it { is_expected.to be_frozen }

  it "holds work-level credits" do
    expect(work.credits.level).to eq :work
  end

  context "with a title alone" do
    subject(:work) { described_class.new(title: "Sumer Is Icumen In") }

    its(:catalog_number) { is_expected.to be_nil }
    its(:year) { is_expected.to be_nil }
    its(:composer) { is_expected.to be_nil }
    its(:to_s) { is_expected.to eq "Sumer Is Icumen In" }

    it "has empty credits" do
      expect(work.credits).to be_empty
    end
  end

  describe "#composer" do
    it "joins two composers with a comma" do
      requiem = described_class.new(title: "Requiem").with_credit(bach, :composer).with_credit("Süssmayr", :composer)

      expect(requiem.composer).to eq "Johann Sebastian Bach, Süssmayr"
    end

    it "answers nil when the only credit is a lyricist" do
      song = described_class.new(title: "Song").with_credit(bach, :lyricist)

      expect(song.composer).to be_nil
    end
  end

  describe "#with_credit" do
    it "answers a new work" do
      expect(work.with_credit(bach, :lyricist)).not_to eq work
    end

    it "leaves the receiver alone" do
      work.with_credit(bach, :lyricist)

      expect(work.credits.size).to eq 1
    end

    it "keeps the other attributes" do
      expect(work.with_credit(bach, :lyricist).catalog_number).to eq "BWV 1007"
    end
  end

  describe "credit coercion" do
    it "accepts a Credits collection" do
      credits = HeadMusic::Content::Credits.new(:work, [composer_credit])

      expect(described_class.new(title: "X", credits: credits).composer).to eq "Johann Sebastian Bach"
    end

    it "accepts an array of hashes" do
      expect(described_class.new(title: "X", credits: [composer_credit.to_h]).composer)
        .to eq "Johann Sebastian Bach"
    end

    it "rejects an arranger" do
      expect { described_class.new(title: "X", credits: [{"role" => "arranger", "person" => {"full_name" => "Y"}}]) }
        .to raise_error(ArgumentError, "arranger is a project role, not a work role")
    end

    it "rejects a project-level collection" do
      arrangers = HeadMusic::Content::Credits.new(:project).add(bach, :arranger)

      expect { described_class.new(title: "X", credits: arrangers) }
        .to raise_error(ArgumentError, "arranger is a project role, not a work role")
    end
  end

  describe "value semantics" do
    let(:twin) do
      described_class.new(title: "Cello Suite No. 1", catalog_number: "BWV 1007", year: 1720, credits: [composer_credit])
    end

    specify { expect(work).to eq twin }
    specify { expect([work, twin].uniq.size).to eq 1 }
    specify { expect(work).not_to eq described_class.new(title: "Cello Suite No. 2") }
  end

  describe "serialization" do
    specify { expect(work.to_h.keys).to contain_exactly("title", "catalog_number", "year", "credits") }
    specify { expect(work.to_h["credits"]).to eq [composer_credit.to_h] }
    specify { expect(described_class.from_h(work.to_h)).to eq work }

    it "round trips through JSON" do
      expect(described_class.from_h(JSON.parse(work.to_h.to_json))).to eq work
    end

    it "reads a hash with no credits" do
      expect(described_class.from_h("title" => "Untitled").credits).to be_empty
    end
  end
end
