require "spec_helper"

describe HeadMusic::Notation::MEI::WrittenItems do
  def abc(body)
    HeadMusic::Notation::ABC.parse("X:1\nT:Items\nM:4/4\nL:1/4\nK:C\n#{body}\n")
  end

  def items_for(flow)
    described_class.new(HeadMusic::Notation::MEI::RenderPlan.new(flow))
  end

  subject(:written_items) { items_for(flow) }

  let(:flow) { abc("C2 D2-|D2 E2|]") }
  let(:voice) { flow.voices.first }

  describe "#items" do
    it "ties the pieces of a note split at the barline" do
      expect([1, 2].map { |bar| written_items.items(voice, bar).map(&:tie) }).to eq [[nil, "i"], ["t", nil]]
    end

    it "ids a piece that resumes after a barline by its downbeat" do
      expect(written_items.items(voice, 2).first.id).to eq "m1-p1v1-b2c1"
    end

    it "makes a rest that fills its bar a measure rest" do
      flow = abc("z4|C4|]")
      expect(items_for(flow).items(flow.voices.first, 1).map(&:measure_rest)).to eq [true]
    end

    it "is empty for a bar the voice places nothing in" do
      expect(written_items.items(voice, 3)).to eq []
    end
  end

  describe "#items_of" do
    it "lists every piece of a voice event across bars" do
      expect(written_items.items_of(voice.voice_events[1]).map(&:id)).to eq %w[m1-p1v1-b1c3 m1-p1v1-b2c1]
    end
  end

  describe "an item's ties through its grace notes" do
    let(:flow) { HeadMusic::Content::Flow.new(meter: "4/4") }
    let(:pitch) { HeadMusic::Rudiment::Pitch.get("C5") }
    let(:item) { written_items.items(voice, 1).first }

    before do
      note_event = flow.add_voice.place("1:1", :whole, "C5")
      note_event.add_grace_note("C5", :eighth, tied: true)
      note_event.add_grace_note("C5", :eighth, tied: true)
    end

    it "ties a pitch into a grace note from the grace note before it" do
      expect([0, 1].map { |index| item.tied_from_grace?(index, pitch) }).to eq [false, true]
    end

    it "counts the item itself as the piece after its grace notes" do
      expect(item.tied_into?(2, pitch)).to be true
    end

    it "stops on the item a tie its last grace note starts" do
      expect(item.note_tie(pitch)).to eq "t"
    end

    it "leaves an untied pitch's tie as the item's own" do
      expect(item.note_tie(HeadMusic::Rudiment::Pitch.get("D5"))).to be_nil
    end
  end

  describe ".segment_length" do
    it "is the part of the voice event's length in the segment's bar" do
      segment = HeadMusic::Notation::MEI::RenderPlan.new(flow).segments_by_bar(voice)[2].first
      expect(described_class.segment_length(segment)).to eq Rational(1, 2)
    end
  end
end
