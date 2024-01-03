require "spec_helper"

describe HeadMusic::Style::Mark do
  subject(:mark) {
    described_class.new(
      HeadMusic::Content::Position.new(composition, "3:2:480"),
      HeadMusic::Content::Position.new(composition, "4:1"),
      fitness: 0.9
    )
  }

  let(:composition) { HeadMusic::Content::Composition.new }

  its(:code) { is_expected.to eq "3:2:480 to 4:1:000" }
  its(:to_s) { is_expected.to eq "3:2:480 to 4:1:000" }
  its(:fitness) { is_expected.to eq 0.9 }

  describe ".for_all" do
    let(:voice) { HeadMusic::Content::Voice.new }
    let(:note) { HeadMusic::Content::Placement.new(voice, "5:3", :quarter, "D5") }
    let(:rest) { HeadMusic::Content::Placement.new(voice, "5:4", :quarter) }

    context "given a single note" do
      subject(:mark) { described_class.for_all(note) }

      its(:placements) { are_expected.to eq [note] }
      its(:code) { is_expected.to eq "5:3:000 to 5:4:000" }
    end

    context "given multiple placements" do
      subject(:mark) { described_class.for_all([note, rest]) }

      its(:placements) { are_expected.to eq [note, rest] }
      its(:code) { is_expected.to eq "5:3:000 to 6:1:000" }
    end
  end
end
