require "spec_helper"

describe HairpinGenerator do
  it "makes the same flow from the same seed" do
    first, second = Array.new(2) { described_class.flow(7).to_h }
    expect(second).to eq first
  end

  it "puts hairpins on voices and parts across the seeds" do
    owners = described_class::SEEDS.first(30).flat_map do |seed|
      flow = described_class.flow(seed)
      [flow.parts.first, *flow.voices].select { |owner| owner.spans.any?(&:hairpin?) }.map(&:class)
    end
    expect(owners.uniq).to contain_exactly(HeadMusic::Content::Part, HeadMusic::Content::Voice)
  end

  it "ends some hairpins on the final barline" do
    ends = described_class::SEEDS.first(30).flat_map do |seed|
      flow = described_class.flow(seed)
      (flow.parts + flow.voices).flat_map(&:spans).map(&:to).select { |position| position == flow.final_barline_position }
    end
    expect(ends).not_to be_empty
  end

  described_class::SEEDS.first(20).each do |seed|
    it "makes flows every format can write, from seed #{seed}" do
      flows = [described_class.flow(seed), described_class.flow(seed, voices: 1, one_line: true, pickup: false)]
      expect { flows.each { |flow| %i[to_lilypond to_musicxml to_kern].each { |method| flow.public_send(method) } } }.not_to raise_error
    end

    it "makes single-voice flows ABC can write, from seed #{seed}" do
      expect { described_class.flow(seed, voices: 1, one_line: true, pickup: false).to_abc }.not_to raise_error
    end
  end

  HairpinFixtures.all.each do |fixture|
    it "makes the #{fixture} fixture writable as MusicXML" do
      expect { HairpinFixtures.public_send(fixture).to_musicxml }.not_to raise_error
    end
  end
end
