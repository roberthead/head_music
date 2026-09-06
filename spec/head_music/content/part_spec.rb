require "spec_helper"

describe HeadMusic::Content::Part do
  subject(:part) { flow.add_part }

  let(:flow) { HeadMusic::Content::Flow.new(name: "Sonata") }

  it "belongs to the flow that made it" do
    expect(part.flow).to be flow
  end

  it "refuses to exist without a flow" do
    expect { described_class.new(flow: nil) }.to raise_error ArgumentError, /belongs to a flow/
  end

  describe "#add_voice" do
    it "returns a voice in this part" do
      expect(part.add_voice(role: "cantus firmus").part).to be part
    end

    it "collects the voices it makes" do
      part.add_voice(role: "cantus firmus")
      part.add_voice(role: "counterpoint")
      expect(part.voices.map(&:role)).to eq ["cantus firmus", "counterpoint"]
    end

    it "puts the voices in the flow" do
      voice = part.add_voice
      expect(flow.voices).to eq [voice]
    end
  end

  describe "the player" do
    it "is absent by default, which makes the part a staff of music" do
      expect(part).not_to be_player
    end

    it "is present when the part was made for one" do
      player = HeadMusic::Content::Project.new.add_player(name: "Piano")
      expect(flow.add_part(player: player)).to be_player
    end
  end

  describe "#to_s" do
    it "counts the voices" do
      part.add_voice
      expect(part.to_s).to eq "1 voice"
    end

    it "names the player when there is one" do
      player = HeadMusic::Content::Project.new.add_player(name: "Piano")
      named_part = flow.add_part(player: player)
      named_part.add_voice
      named_part.add_voice
      expect(named_part.to_s).to eq "Piano: 2 voices"
    end
  end

  # Nothing seeds an instrument map, and the two commonest parts in this gem --
  # a counterpoint part and a part of a standalone flow -- have no instrument
  # at all. So the map answers nil rather than guessing, and the staff system
  # falls back to a single staff rather than reading one off a nil instrument.
  describe "a part that was never given an instrument" do
    it "has no instrument" do
      expect(part.instrument_at(1)).to be_nil
    end

    it "lists no instruments" do
      expect(part.instruments).to be_empty
    end

    it "is still written on a staff" do
      expect(part.staff_system_at(1).length).to eq 1
    end

    it "answers the same staff system every time" do
      expect(part.staff_system_at(1)).to be part.staff_system_at(99)
    end
  end

  describe "#change_instrument" do
    subject(:part) { flow.add_part(instrument: "flute") }

    before { part.change_instrument(9, "piccolo") }

    it "leaves the bars before it alone" do
      expect(part.instrument_at(8).name).to eq "flute"
    end

    it "takes effect from its bar" do
      expect(part.instrument_at(9).name).to eq "piccolo flute"
    end

    # The point of a part being per-flow and a player being per-project: the
    # instrument changes and it is still one part, still one player.
    it "remains a single part" do
      expect(flow.parts).to eq [part]
    end

    it "lists every instrument it plays, in order" do
      expect(part.instruments.map(&:name)).to eq ["flute", "piccolo flute"]
    end
  end

  describe "#change_staff_system" do
    subject(:part) { flow.add_part(staff_system: HeadMusic::Content::StaffSystem.grand_staff) }

    before { part.change_staff_system(9, HeadMusic::Content::StaffSystem.single_staff(clef: :treble_clef)) }

    it "starts on the authored system" do
      expect(part.staff_system_at(8).length).to eq 2
    end

    it "changes to the new one" do
      expect(part.staff_system_at(9).length).to eq 1
    end

    it "reports the bars a system was authored in" do
      expect(part.staff_system_changes.keys).to eq [9]
    end

    it "serializes the changes alongside the opening system" do
      hash = part.to_h
      expect(hash["staff_system"]["staves"].length).to eq 2
      expect(hash["staff_system_changes"]).to eq [
        {"number" => 9, "staff_system" => {"bracket" => "none", "staves" => [{"clef" => "treble_clef"}]}}
      ]
    end
  end
end
