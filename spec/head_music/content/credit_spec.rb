require "spec_helper"

describe HeadMusic::Content::Credit do
  subject(:credit) { described_class.new(person: bach, role: :composer) }

  let(:bach) { HeadMusic::Content::Person.new(full_name: "Johann Sebastian Bach") }

  its(:person) { is_expected.to eq bach }
  its(:role) { is_expected.to eq HeadMusic::Content::Role.get(:composer) }
  its(:to_s) { is_expected.to eq "Johann Sebastian Bach (composer)" }

  it { is_expected.to be_frozen }

  describe "role coercion" do
    it "accepts a string" do
      expect(described_class.new(person: bach, role: "arranger").role.key).to eq :arranger
    end

    it "accepts a role" do
      role = HeadMusic::Content::Role.get(:editor)

      expect(described_class.new(person: bach, role: role).role).to be role
    end

    it "accepts a translated name" do
      expect(described_class.new(person: bach, role: "Verleger").role.key).to eq :publisher
    end

    it "raises for an unknown role" do
      expect { described_class.new(person: bach, role: :producer) }.to raise_error(ArgumentError)
    end
  end

  describe "person coercion" do
    it "accepts a hash" do
      credit = described_class.new(person: {"full_name" => "Andrés Segovia"}, role: :arranger)

      expect(credit.person.full_name).to eq "Andrés Segovia"
    end

    it "accepts a string" do
      expect(described_class.new(person: "Trad.", role: :composer).person.full_name).to eq "Trad."
    end
  end

  describe "value semantics" do
    let(:twin) { described_class.new(person: bach, role: "composer") }

    specify { expect(credit).to eq twin }
    specify { expect([credit, twin].uniq.size).to eq 1 }
    specify { expect(credit).not_to eq described_class.new(person: bach, role: :lyricist) }
  end

  describe "serialization" do
    let(:person_hash) do
      {
        "full_name" => "Johann Sebastian Bach",
        "sort_name" => "Johann Sebastian Bach",
        "birth_year" => nil,
        "death_year" => nil
      }
    end

    specify { expect(credit.to_h).to eq("role" => "composer", "person" => person_hash) }
    specify { expect(described_class.from_h(credit.to_h)).to eq credit }

    it "reads symbol keys" do
      expect(described_class.from_h(person: {full_name: "Erik Satie"}, role: :composer).role.key).to eq :composer
    end
  end
end
