require "spec_helper"

describe HeadMusic::Content::Flow::Bars do
  subject(:bars) { described_class.new(flow) }

  let(:flow) { HeadMusic::Content::Flow.new }

  describe "#span" do
    it "answers the bars from first to last, numbered" do
      expect(bars.span(2, 4).map(&:number)).to eq [2, 3, 4]
    end

    it "answers the same bar each time it is asked for" do
      expect(bars.span(3, 3).first).to equal bars.span(1, 3).last
    end
  end

  describe "#first_number" do
    it "is nil before any bar is allocated" do
      expect(bars.first_number).to be_nil
    end

    it "is the lowest allocated bar number" do
      bars.span(3, 4)
      bars.span(0, 0)
      expect(bars.first_number).to eq 0
    end
  end

  describe "#serialize" do
    it "leaves out a bar with nothing to say" do
      bars.span(1, 3)
      expect(bars.serialize).to eq []
    end

    it "writes a bar's repeat structure under its number" do
      bars.span(5, 5).first.starts_repeat = true
      expect(bars.serialize).to eq [{"number" => 5, "starts_repeat" => true}]
    end
  end
end
