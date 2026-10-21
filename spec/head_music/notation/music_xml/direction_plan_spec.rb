require "spec_helper"

describe HeadMusic::Notation::MusicXML::DirectionPlan do
  subject(:direction_plan) { plan.direction_plan(flow.parts.first) }

  let(:plan) { HeadMusic::Notation::MusicXML::RenderPlan.new(flow) }
  let(:flow) do
    HeadMusic::Content::Flow.new(name: "Slots", meter: "4/4").tap do |flow|
      piano = flow.add_part(instrument: "piano", staff_system: HeadMusic::Content::StaffSystem.grand_staff)
      right_hand = piano.add_voice(role: "right hand")
      left_hand = piano.add_voice(role: "left hand")
      right_hand.place("1:1", :half, "E4")
      right_hand.place("1:3", :half, "F4")
      right_hand.place("2:1", :whole, "G4")
      left_hand.place("1:1", :whole, "C3")
    end
  end
  let(:right_hand) { flow.voices.first }
  let(:left_hand) { flow.voices.last }

  def kinds(slots)
    slots.map { |slot| [slot.kind, slot.voice && flow.voices.index(slot.voice)] }
  end

  describe "#slots" do
    it "lists each bar's slots in document order, closing the last bar after every voice" do
      expect(kinds(direction_plan.slots)).to eq [
        [:part, nil], [:segment, 0], [:segment, 0], [:trailing, 0], [:segment, 1], [:trailing, 1],
        [:part, nil], [:segment, 0], [:trailing, 0], [:whole_measure_rest, 1], [:trailing, 1], [:closing, nil]
      ]
    end
  end

  describe "#marks" do
    it "puts a voice's dynamic in the slot of the segment sounding there" do
      right_hand.place_dynamic("1:4", :p)
      slot = direction_plan.bar(1).voice_slots.first.last[1]
      expect(direction_plan.marks(slot).map { |mark| mark.item.name_key }).to eq %w[p]
    end

    it "puts a voice's dynamic in a bar it does not play in before its whole-measure rest" do
      left_hand.place_dynamic("2:2", :f)
      slot = direction_plan.bar(2).voice_slots.last.last.first
      expect([slot.kind, direction_plan.marks(slot).length]).to eq [:whole_measure_rest, 1]
    end
  end

  describe "#start" do
    it "starts a segment's slot where the notes before it end" do
      slot = direction_plan.bar(1).voice_slots.first.last[1]
      expect(direction_plan.start(slot)).to eq 2 * plan.divisions
    end

    it "starts the closing slot where the last voice's notes end" do
      expect(direction_plan.start(direction_plan.bar(2).closing_slot)).to eq 4 * plan.divisions
    end
  end

  describe "Slot#voices" do
    it "is the slot's own voice, or every voice of the part for a part slot" do
      voice_slot = direction_plan.bar(1).voice_slots.last.last.first
      expect([voice_slot.voices, direction_plan.bar(1).part_slot.voices]).to eq [[left_hand], [right_hand, left_hand]]
    end
  end
end
