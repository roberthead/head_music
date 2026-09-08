require "spec_helper"

describe HeadMusic::Content::Person do
  subject(:person) { described_class.new(full_name: "Johann Sebastian Bach", birth_year: 1685, death_year: 1750) }

  its(:full_name) { is_expected.to eq "Johann Sebastian Bach" }
  its(:birth_year) { is_expected.to eq 1685 }
  its(:death_year) { is_expected.to eq 1750 }
  its(:to_s) { is_expected.to eq "Johann Sebastian Bach" }

  it { is_expected.to be_frozen }

  context "with only a full name" do
    subject(:person) { described_class.new(full_name: "Hildegard von Bingen") }

    its(:sort_name) { is_expected.to eq "Hildegard von Bingen" }
    its(:birth_year) { is_expected.to be_nil }
    its(:death_year) { is_expected.to be_nil }
  end

  context "with a sort name" do
    subject(:person) { described_class.new(full_name: "Manuel de Falla", sort_name: "Falla, Manuel de") }

    its(:sort_name) { is_expected.to eq "Falla, Manuel de" }
  end

  context "with only a birth year" do
    subject(:person) { described_class.new(full_name: "Kaija Saariaho", birth_year: 1952) }

    its(:birth_year) { is_expected.to eq 1952 }
    its(:death_year) { is_expected.to be_nil }
  end

  context "with only a death year" do
    subject(:person) { described_class.new(full_name: "Anonymous", death_year: 1400) }

    its(:birth_year) { is_expected.to be_nil }
    its(:death_year) { is_expected.to eq 1400 }
  end

  context "when the death year precedes the birth year" do
    it "raises" do
      expect { described_class.new(full_name: "Impossible", birth_year: 1900, death_year: 1800) }
        .to raise_error(ArgumentError, /precedes birth year/)
    end
  end

  context "when the death year equals the birth year" do
    it "does not raise" do
      expect { described_class.new(full_name: "Brief", birth_year: 1900, death_year: 1900) }.not_to raise_error
    end
  end

  context "without a full name" do
    it "raises" do
      expect { described_class.new(full_name: nil) }.to raise_error ArgumentError, /full name/
    end
  end

  describe "value semantics" do
    let(:twin) { described_class.new(full_name: "Johann Sebastian Bach", birth_year: 1685, death_year: 1750) }

    specify { expect(person).to eq twin }
    specify { expect([person, twin].uniq.size).to eq 1 }
    specify { expect(person).not_to eq described_class.new(full_name: "Johann Christian Bach") }

    it "answers a new person from #with" do
      expect(person.with(full_name: "J. S. Bach").death_year).to eq 1750
    end
  end

  describe "serialization" do
    specify { expect(person.to_h.keys).to contain_exactly("full_name", "sort_name", "birth_year", "death_year") }
    specify { expect(described_class.from_h(person.to_h)).to eq person }

    it "reads symbol keys" do
      expect(described_class.from_h(full_name: "Erik Satie", birth_year: 1866).full_name).to eq "Erik Satie"
    end

    it "writes every key even when the optional values are absent" do
      expect(described_class.new(full_name: "Anon").to_h)
        .to eq("full_name" => "Anon", "sort_name" => "Anon", "birth_year" => nil, "death_year" => nil)
    end
  end
end
