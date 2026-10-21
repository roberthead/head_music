require "spec_helper"

describe HeadMusic::Time::ATempo do
  let(:position) { HeadMusic::Time::MusicalPosition.new(14, 2) }

  it "says a tempo unless told otherwise" do
    expect(described_class.new(position: position).text).to eq "a tempo"
  end

  it "keeps other text" do
    expect(described_class.new(position: position, text: "Tempo I").text).to eq "Tempo I"
  end

  it "begins and ends at its position" do
    expect(described_class.new(position: position)).to have_attributes(from: position, to: position)
  end
end
