require "spec_helper"

describe HeadMusic::MIDI::HairpinRamps do
  subject(:hairpins) { described_class.new(voice, HeadMusic::MIDI::LevelMarks.of(voice)) }

  let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nT:Ramps\nM:4/4\nL:1/4\nK:C\n#{body}\n") }
  let(:voice) { flow.voices.first }

  def ramp_shape(ramp)
    [ramp.from.to_s, ramp.to.to_s, ramp.start.name_key, ramp.target.name_key]
  end

  context "with a crescendo to a level" do
    let(:body) { "!p!!<(!C D E F|!<)!!f!G4|" }

    it "ramps from the level at its start to the level at its end" do
      expect(hairpins.ramps.map { |ramp| ramp_shape(ramp) }).to eq [[flow.position("1:1").to_s, flow.position("2:1").to_s, "p", "f"]]
    end

    it "leaves no follow-through level" do
      expect(hairpins.follow_through).to eq []
    end
  end

  context "with a crescendo to no level" do
    let(:body) { "!p!!<(!C D E F|!<)!G4|" }

    it "ramps one level beyond its start and leaves that level in force" do
      expect([hairpins.ramps.first.target.name_key, hairpins.follow_through.map { |mark| [mark.position.to_s, mark.level.name_key] }])
        .to eq ["mp", [[flow.position("2:1").to_s, "mp"]]]
    end
  end

  context "with a level placed inside a hairpin" do
    let(:body) { "!pp!!<(!C D !p!E F|!<)!!f!G4|" }

    it "cuts the hairpin there" do
      expect(hairpins.ramps.map { |ramp| [ramp.start.name_key, ramp.target.name_key] }).to eq [%w[pp p], %w[p f]]
    end
  end

  describe "#governing" do
    let(:body) { "!p!C !<(!D E F|!<)!!f!G4|" }

    it "answers the ramp covering each voice event, and none outside every ramp" do
      governing = hairpins.governing
      expect(voice.voice_events.map { |voice_event| governing[voice_event] ? :ramp : nil }).to eq [nil, :ramp, :ramp, :ramp, nil]
    end

    it "prefers the voice's hairpin over the part's" do
      voice.part.add_span(:diminuendo, from: "1:2", to: "2:1")
      expect(hairpins.governing[voice.voice_events[2]].owner_rank).to eq HeadMusic::MIDI::LevelMarks::VOICE_RANK
    end
  end
end
