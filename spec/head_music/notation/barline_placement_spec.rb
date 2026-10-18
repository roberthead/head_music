require "spec_helper"

describe HeadMusic::Notation::BarlinePlacement do
  let(:record_class) do
    placement = described_class
    Data.define(:last, :mid_bar) { include placement }
  end

  it "answers whether the record is in the last bar" do
    expect([true, false].map { |last| record_class.new(last: last, mid_bar: false).last? }).to eq [true, false]
  end

  it "answers whether the record falls inside a bar" do
    expect([true, false].map { |mid_bar| record_class.new(last: false, mid_bar: mid_bar).mid_bar? }).to eq [true, false]
  end
end
