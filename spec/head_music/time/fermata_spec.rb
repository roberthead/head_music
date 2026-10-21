require "spec_helper"

describe HeadMusic::Time::Fermata do
  let(:from) { HeadMusic::Time::MusicalPosition.new(4, 3) }
  let(:to) { HeadMusic::Time::MusicalPosition.new(5) }

  it "doubles its span's clock time by default" do
    expect(described_class.new(from: from, to: to).stretch).to eq 2
  end

  it "keeps another stretch" do
    expect(described_class.new(from: from, to: to, stretch: 1.5).stretch).to eq 1.5
  end

  it "allows a stretch of 1, which holds nothing" do
    expect(described_class.new(from: from, to: to, stretch: 1).stretch).to eq 1
  end

  it "raises for a stretch below 1" do
    expect { described_class.new(from: from, to: to, stretch: 0.5) }.to raise_error(ArgumentError, /at least 1/)
  end

  it "raises for a stretch that is not a number" do
    expect { described_class.new(from: from, to: to, stretch: "2") }.to raise_error(ArgumentError)
  end

  it "raises when it does not end after it begins" do
    expect { described_class.new(from: to, to: from) }.to raise_error(ArgumentError, /ends after it begins/)
  end
end
