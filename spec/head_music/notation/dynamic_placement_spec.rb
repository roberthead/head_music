require "spec_helper"

describe HeadMusic::Notation::DynamicPlacement do
  subject(:placement) { described_class.new(voice) }

  let(:flow) { HeadMusic::Content::Flow.new }
  let(:voice) { flow.add_voice }
  let(:voice_events) { voice.voice_events }

  before do
    voice.place("1:1", :half, "C5")
    voice.place("1:3", :half)
    voice.place("2:1", :whole, "D5")
  end

  def written
    placement.levels.map { |voice_event, level| [voice_event.position.to_s, level.name_key] }
  end

  it "places a dynamic on the note it falls on" do
    voice.place_dynamic("1:1", :p)
    expect(written).to eq [["1:1:000", "p"]]
  end

  it "places a dynamic that falls on a rest on the rest" do
    voice.place_dynamic("1:3", :p)
    expect(written).to eq [["1:3:000", "p"]]
  end

  it "moves a dynamic in the middle of a note to the next voice event" do
    voice.place_dynamic("1:2", :f)
    expect(written).to eq [["1:3:000", "f"]]
  end

  it "leaves out a dynamic with nothing after it" do
    voice.place_dynamic("2:2", :ff)
    expect(written).to eq []
  end

  it "keeps the later of two that land on one voice event" do
    voice.place_dynamic("1:1", :p)
    voice.place_dynamic("1:2", :mf)
    voice.place_dynamic("1:3", :f)
    expect(written).to eq [["1:1:000", "p"], ["1:3:000", "f"]]
  end

  it "answers the level for a voice event" do
    voice.place_dynamic("2:1", :mp)
    expect(placement.level_for(voice_events.last).name_key).to eq "mp"
  end

  it "answers nil for a voice event with no dynamic" do
    expect(placement.level_for(voice_events.first)).to be_nil
  end

  it "ignores the part's dynamics by default" do
    voice.part.place_dynamic("1:1", :p)
    expect(written).to eq []
  end

  context "when including the part's dynamics" do
    subject(:placement) { described_class.new(voice, include_part: true) }

    it "places them" do
      voice.part.place_dynamic("2:1", :p)
      expect(written).to eq [["2:1:000", "p"]]
    end

    it "prefers the voice's own at the same position" do
      voice.part.place_dynamic("2:1", :p)
      voice.place_dynamic("2:1", :ff)
      expect(written).to eq [["2:1:000", "ff"]]
    end

    it "prefers the later of a part's and a voice's that land on one note" do
      voice.place_dynamic("1:2", :p)
      voice.part.place_dynamic("1:3", :f)
      expect(written).to eq [["1:3:000", "f"]]
    end
  end

  describe "the shared fixtures" do
    it "builds the marked melody" do
      expect(MarkingFixtures.marked_melody.voices.first.dynamic_at("4:3").name_key).to eq "p"
    end

    it "builds the grand-staff piano" do
      left_hand = MarkingFixtures.grand_staff_piano_with_dynamics.voices.last
      expect(%w[1:1 2:3 4:1].map { |position| left_hand.dynamic_at(position).name_key }).to eq %w[p f mp]
    end
  end
end
