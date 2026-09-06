require "spec_helper"

describe HeadMusic::Content::Staff do
  subject(:staff) { described_class.new(clef: :bass_clef) }

  its(:line_count) { is_expected.to eq 5 }
  its(:clef) { is_expected.to eq HeadMusic::Rudiment::Clef.get(:bass_clef) }
  its(:to_s) { is_expected.to eq "bass clef 5-line" }

  # Nil rather than a guess: choosing a clef from a voice's range needs a
  # voice, and a staff has no back-reference to one.
  describe "a staff with no authored clef" do
    subject(:staff) { described_class.new }

    it "answers no clef rather than inventing one" do
      expect(staff.clef_at(1)).to be_nil
    end
  end

  describe "#change_clef" do
    before { staff.change_clef(5, :alto_clef) }

    it "leaves the bars before it alone" do
      expect(staff.clef_at(4)).to eq HeadMusic::Rudiment::Clef.get(:bass_clef)
    end

    it "takes effect from its bar" do
      expect(staff.clef_at(5)).to eq HeadMusic::Rudiment::Clef.get(:alto_clef)
    end

    it "stays in force afterwards" do
      expect(staff.clef_at(50)).to eq HeadMusic::Rudiment::Clef.get(:alto_clef)
    end

    it "reports the bars a clef was authored in" do
      expect(staff.clef_changes.keys).to eq [5]
    end

    it "serializes the changes alongside the opening clef" do
      expect(staff.to_h).to eq("clef" => "bass_clef", "clef_changes" => [{"number" => 5, "clef" => "alto_clef"}])
    end
  end

  # A staff whose clef never changes serializes as its clef alone.
  describe "#to_h" do
    it "omits clef changes where there are none" do
      expect(staff.to_h).to eq("clef" => "bass_clef")
    end
  end

  describe "a staff realizing a catalog staff" do
    subject(:staff) { described_class.new(instruments_staff: catalog_staff) }

    let(:catalog_staff) { HeadMusic::Instruments::Instrument.get("snare drum").default_staves.first }

    it "keeps the reference rather than copying the mappings" do
      expect(staff.instruments_staff).to be catalog_staff
    end
  end

  describe "a staff with no catalog staff" do
    it "has no instrument at a percussion position" do
      expect(described_class.new.instrument_for_position(0)).to be_nil
    end
  end
end
