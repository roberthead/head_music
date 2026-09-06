require "spec_helper"

describe HeadMusic::Content::StaffSystem do
  describe ".single_staff" do
    subject(:system) { described_class.single_staff }

    its(:length) { is_expected.to eq 1 }
    its(:bracket) { is_expected.to eq :none }
    its(:to_s) { is_expected.to eq "1-staff none" }
  end

  describe ".grand_staff" do
    subject(:system) { described_class.grand_staff }

    its(:length) { is_expected.to eq 2 }
    its(:bracket) { is_expected.to eq :brace }

    it "puts the treble staff above the bass" do
      expect(system.staves.map { |staff| staff.clef.to_s }).to eq ["treble clef", "bass clef"]
    end

    it "answers the treble staff first" do
      expect(system.first_staff).to be system.staves.first
    end
  end

  describe "#include?" do
    subject(:system) { described_class.grand_staff }

    it "recognizes its own staves" do
      expect(system).to include system.staves.last
    end

    # By identity, not equality: two five-line treble staves are the same
    # description of different staves.
    it "does not recognize a staff merely like one of its own" do
      expect(system).not_to include HeadMusic::Content::Staff.new(clef: :treble_clef)
    end
  end

  it "falls back to one staff when given none" do
    expect(described_class.new(staves: []).length).to eq 1
  end

  it "refuses a bracket it does not know" do
    expect { described_class.new(bracket: :squiggle) }
      .to raise_error ArgumentError, /bracket must be one of/
  end
end
