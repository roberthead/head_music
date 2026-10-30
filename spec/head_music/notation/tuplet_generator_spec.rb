require "spec_helper"

describe TupletGenerator do
  def check(flow)
    restored = HeadMusic::Content::Flow.from_json(flow.to_json)
    {
      gaps: flow.voices.map(&:first_gap).compact,
      ends: flow.voices.map(&:next_position).uniq.length,
      brackets: flow.voices.map { |voice| HeadMusic::Notation::TupletBrackets.for(voice).length },
      round_trip: restored.to_h == flow.to_h
    }
  end

  def well_formed(flow)
    check(flow).merge(brackets: nil)
  end

  let(:healthy) { {gaps: [], ends: 1, brackets: nil, round_trip: true} }

  def features(flows)
    voices = flows.flat_map(&:voices)
    {
      ratios: voices.flat_map(&:voice_events).filter_map { |event| event.rhythmic_duration.values.first.tuplet_ratio&.to_s }.uniq.sort,
      ungrouped: voices.any? { |voice| voice.voice_events.any? { |event| event.rhythmic_duration.tuplet? && voice.tuplet_at(event.position).nil? } },
      crossing: voices.any? { |voice| HeadMusic::Notation::TupletBrackets.for(voice).any?(&:crosses_barline?) },
      graces: voices.flat_map(&:note_events).flat_map(&:grace_notes).map(&:slashed?).uniq.sort_by(&:to_s),
      grace_slurs: voices.flat_map(&:spans).any?(&:from_grace?),
      meters: flows.map { |flow| flow.meter.to_s }.uniq.sort,
      pickup: flows.any? { |flow| flow.voices.first.voice_events.first.position.bar_number.zero? }
    }
  end

  it "makes the same flow from the same seed" do
    first, second = Array.new(2) { described_class.flow(7).to_h }
    expect(second).to eq first
  end

  it "makes every ratio, groups and ungrouped runs, crossings, pickups, grace notes, and grace slurs across the seeds" do
    flows = described_class::SEEDS.first(40).map { |seed| described_class.flow(seed) }
    expect(features(flows)).to eq(
      ratios: %w[5:4 6:4 7:4 triplet], ungrouped: true, crossing: true, graces: [false, true], grace_slurs: true, meters: %w[4/4 6/8], pickup: true
    )
  end

  it "makes flows with no crossings, ungrouped runs, grace notes, or pickups when asked" do
    options = {voices: 1, cross_barlines: false, ungrouped: false, graces: false, pickup: false, meters: %w[4/4]}
    flows = described_class::SEEDS.first(20).map { |seed| described_class.flow(seed, **options) }
    expect(features(flows).slice(:ungrouped, :crossing, :graces, :grace_slurs, :meters, :pickup))
      .to eq(ungrouped: false, crossing: false, graces: [], grace_slurs: false, meters: %w[4/4], pickup: false)
  end

  described_class::SEEDS.each do |seed|
    it "makes a gapless flow with valid groups that round-trips through JSON, seed #{seed}" do
      expect(well_formed(described_class.flow(seed))).to eq healthy
    end
  end

  [{voices: 1, pickup: false, cross_barlines: false, meters: %w[4/4]}, {meters: %w[6/8], ratios: %w[3:2 2:3 7:4]}].each do |options|
    described_class::SEEDS.first(10).each do |seed|
      it "makes a well-formed flow with #{options.keys.join(", ")} set, seed #{seed}" do
        expect(well_formed(described_class.flow(seed, **options))).to eq healthy
      end
    end
  end

  TupletFixtures.all.each do |fixture|
    it "makes the #{fixture} fixture gapless and round-trippable through JSON" do
      expect(well_formed(TupletFixtures.public_send(fixture))).to eq healthy
    end
  end
end
