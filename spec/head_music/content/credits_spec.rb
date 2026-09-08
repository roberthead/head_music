require "spec_helper"

describe HeadMusic::Content::Credits do
  subject(:credits) { described_class.new(:work, [composer_credit]) }

  let(:bach) { HeadMusic::Content::Person.new(full_name: "Johann Sebastian Bach") }
  let(:segovia) { HeadMusic::Content::Person.new(full_name: "Andrés Segovia") }
  let(:composer_credit) { HeadMusic::Content::Credit.new(person: bach, role: :composer) }

  its(:level) { is_expected.to eq :work }
  its(:size) { is_expected.to eq 1 }
  its(:to_a) { is_expected.to eq [composer_credit] }

  it { is_expected.to be_frozen }
  it { is_expected.not_to be_empty }

  it "is enumerable" do
    expect(credits.map { |credit| credit.person.full_name }).to eq ["Johann Sebastian Bach"]
  end

  context "when empty" do
    subject(:credits) { described_class.new(:project) }

    it { is_expected.to be_empty }
    its(:size) { is_expected.to eq 0 }
    its(:to_h) { is_expected.to eq [] }
  end

  describe "level constraint" do
    it "rejects a project role at the work level" do
      arranger = HeadMusic::Content::Credit.new(person: segovia, role: :arranger)

      expect { described_class.new(:work, [arranger]) }
        .to raise_error(ArgumentError, "arranger is a project role, not a work role")
    end

    it "rejects a work role at the project level" do
      expect { described_class.new(:project, [composer_credit]) }
        .to raise_error(ArgumentError, "composer is a work role, not a project role")
    end

    it "rejects a publication role at the project level" do
      engraver = HeadMusic::Content::Credit.new(person: segovia, role: :engraver)

      expect { described_class.new(:project, [engraver]) }
        .to raise_error(ArgumentError, "engraver is a publication role, not a project role")
    end

    it "rejects a work role at the publication level" do
      expect { described_class.new(:publication, [composer_credit]) }
        .to raise_error(ArgumentError, "composer is a work role, not a publication role")
    end

    it "rejects the role when added" do
      expect { credits.add(segovia, :arranger) }.to raise_error(ArgumentError, /project role, not a work role/)
    end

    it "rejects an unknown level" do
      expect { described_class.new(:layout) }.to raise_error(ArgumentError, /unknown credit level/)
    end

    HeadMusic::Content::Role::KEYS_BY_LEVEL.each do |level, keys|
      keys.each do |key|
        it "accepts #{key} at the #{level} level" do
          expect(described_class.new(level).add(bach, key).size).to eq 1
        end
      end
    end
  end

  describe "#add" do
    it "answers a new collection" do
      expect(credits.add(bach, :lyricist)).not_to be credits
    end

    it "leaves the receiver alone" do
      credits.add(bach, :lyricist)

      expect(credits.size).to eq 1
    end

    it "appends the credit" do
      expect(credits.add(bach, :lyricist).map { |credit| credit.role.key }).to eq %i[composer lyricist]
    end
  end

  describe "#for and #names" do
    subject(:credits) { described_class.new(:work).add(bach, :composer).add(segovia, :composer).add(bach, :lyricist) }

    it "selects by role" do
      expect(credits.for(:composer).size).to eq 2
    end

    it "selects by translated role name" do
      expect(credits.for("Komponist").size).to eq 2
    end

    it "answers the full names for a role" do
      expect(credits.names(:composer)).to eq ["Johann Sebastian Bach", "Andrés Segovia"]
    end

    it "answers an empty array for an uncredited role" do
      expect(credits.names(:librettist)).to eq []
    end
  end

  describe "serialization" do
    it "writes an array of credit hashes" do
      expect(credits.to_h).to eq [composer_credit.to_h]
    end

    it "round trips" do
      expect(described_class.from_h(credits.to_h, level: :work)).to eq credits
    end

    it "reads nil as empty" do
      expect(described_class.from_h(nil, level: :work)).to be_empty
    end

    it "enforces the level when reading" do
      hash = [HeadMusic::Content::Credit.new(person: segovia, role: :arranger).to_h]

      expect { described_class.from_h(hash, level: :work) }.to raise_error(ArgumentError)
    end

    it "accepts hashes directly" do
      expect(described_class.new(:work, [composer_credit.to_h])).to eq credits
    end
  end

  describe "equality" do
    specify { expect(credits).to eq described_class.new(:work, [composer_credit]) }
    specify { expect(credits).not_to eq described_class.new(:work) }
    specify { expect(credits).not_to eq described_class.new(:project) }

    it "hashes by level and credits" do
      expect([credits, described_class.new(:work, [composer_credit])].uniq.size).to eq 1
    end
  end
end
