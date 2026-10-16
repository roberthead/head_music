require "spec_helper"

describe HeadMusic::Analysis::KeyRegion do
  subject(:region) { described_class.new(bar_number: 5, onset: 4, key: key) }

  let(:key) { HeadMusic::Rudiment::Key.get("G major") }

  it "names the bar it begins in, its onset, and its key" do
    expect([region.bar_number, region.onset, region.key]).to eq [5, 4, key]
  end
end
