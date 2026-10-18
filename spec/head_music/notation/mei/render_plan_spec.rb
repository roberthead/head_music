require "spec_helper"

describe HeadMusic::Notation::MEI::RenderPlan do
  def abc(body, key: "C", meter: "4/4")
    HeadMusic::Notation::ABC.parse("X:1\nT:Plan\nM:#{meter}\nL:1/4\nK:#{key}\n#{body}\n")
  end

  def summary(items)
    items.map { |item| [item.id, item.link.rhythmic_value.single_value_name, item.tie] }
  end

  subject(:plan) { described_class.new(flow) }

  let(:flow) { abc("C2 D2-|D2 E2|]") }
  let(:voice) { flow.voices.first }

  describe "#items" do
    it "ties the pieces of a note split at the barline" do
      expect(summary(plan.items(voice, 1)).last).to eq ["m1-p1v1-b1c3", "half", "i"]
      expect(summary(plan.items(voice, 2)).first).to eq ["m1-p1v1-b2c1", "half", "t"]
    end

    it "ties the links of a chain within a bar" do
      flow = abc("C3/2-C/2 D2|]")
      expect(summary(described_class.new(flow).items(flow.voices.first, 1)).first(2))
        .to eq [["m1-p1v1-b1c1", "dotted quarter", "i"], ["m1-p1v1-b1c1-k1", "eighth", "t"]]
    end

    it "ties the middle of a chain both ways" do
      flow = abc("z2 C2-|C4-|C4|]")
      ties = (1..3).map { |bar| described_class.new(flow).items(flow.voices.first, bar).last.tie }
      expect(ties).to eq %w[i m t]
    end

    it "is empty for a bar the voice places nothing in" do
      expect(plan.items(voice, 3)).to eq []
    end

    it "makes a rest that fills its bar a measure rest" do
      flow = abc("z4|C4|]")
      expect(described_class.new(flow).items(flow.voices.first, 1).map(&:measure_rest)).to eq [true]
    end

    it "makes one measure rest of a rest whose chain fills its bar" do
      flow = HeadMusic::Content::Flow.new(meter: "5/4")
      flow.add_voice.place("1:1", "half tied to dotted half")
      expect(described_class.new(flow).items(flow.voices.first, 1).map(&:measure_rest)).to eq [true]
    end

    it "leaves a shorter rest a rest" do
      flow = abc("z2 C2|]")
      expect(described_class.new(flow).items(flow.voices.first, 1).map(&:measure_rest)).to eq [false, false]
    end

    it "gives a voice event's grace notes to its first piece only" do
      flow = abc("z2|]")
      flow.voices.first.place("1:3", "half tied to whole", "C4").add_grace_note("B4", :eighth)
      items = [1, 2].flat_map { |bar| described_class.new(flow).items(flow.voices.first, bar) }
      expect(items.map { |item| item.graces.length }).to eq [0, 1, 0]
    end

    it "tells apart events at one position in different voices" do
      flow = HeadMusic::Content::Flow.new(meter: "4/4")
      flow.add_voice.place("1:1", :whole, "E5")
      flow.add_part.add_voice.place("1:1", :whole, "C4")
      plan = described_class.new(flow)
      expect(flow.voices.map { |voice| plan.items(voice, 1).first.id }).to eq %w[m1-p1v1-b1c1 m1-p2v1-b1c1]
    end
  end

  describe "#note_ids" do
    it "names a lone note by its event" do
      expect(plan.note_ids(plan.items(voice, 1).first).map(&:last)).to eq ["m1-p1v1-b1c1"]
    end

    it "names the notes of a chord low to high" do
      flow = HeadMusic::Content::Flow.new(meter: "4/4")
      flow.add_voice.place("1:1", :whole, %w[G4 C4 E4])
      plan = described_class.new(flow)
      expect(plan.note_ids(plan.items(flow.voices.first, 1).first).map { |pitch, id| [pitch.to_s, id] })
        .to eq [%w[C4 m1-p1v1-b1c1-h1], %w[E4 m1-p1v1-b1c1-h2], %w[G4 m1-p1v1-b1c1-h3]]
    end
  end

  describe "#first_measure_key" do
    it "writes flats, sharps, and none as MEI keysigs" do
      expect(%w[Bb D C].map { |key| described_class.new(abc("C4|]", key: key)).first_measure_key }).to eq %w[2f 2s 0]
    end
  end

  describe "#underfull?" do
    it "is true of a final bar the music does not fill" do
      expect(described_class.new(abc("C4|D2|]")).underfull?(2)).to be true
    end

    it "is false of a full final bar" do
      expect(plan.underfull?(2)).to be false
    end

    it "is false of a bar before the last" do
      expect(described_class.new(abc("C4|D2|]")).underfull?(1)).to be false
    end
  end

  describe "#written_key_event" do
    let(:flow) do
      HeadMusic::Content::Flow.new(key_signature: "F major").tap do |flow|
        flow.add_part(instrument: "clarinet").add_voice.place("1:1", :whole, "C4")
        flow.change_key_signature(2, "D major")
      end
    end

    it "is the sounding key in force at the bar" do
      expect([1, 2].map { |bar| plan.written_key_event(flow.parts.first, bar).signature }).to eq [-1, 2]
    end

    it "is the instrument's written key in a transposed plan" do
      plan = described_class.new(flow, transposed: true)
      expect([1, 2].map { |bar| plan.written_key_event(flow.parts.first, bar).signature }).to eq [1, 4]
    end
  end

  describe "#midi_bpm" do
    it "counts quarters per minute" do
      expect(plan.midi_bpm(HeadMusic::Rudiment::Tempo.new("dotted quarter", 60))).to eq "90"
    end
  end

  describe "#staff_entries" do
    it "numbers every staff through the score" do
      flow = LilyPondFixtures.piano_and_melody
      entries = described_class.new(flow).staff_entries
      expect(entries.map { |entry| [entry.number, entry.part_number, entry.index_in_part] }).to eq [[1, 1, 0], [2, 1, 1], [3, 2, 0]]
    end
  end

  describe "staves of voices" do
    let(:flow) { LilyPondFixtures.cross_staff_piano }
    let(:left_hand) { flow.voices.last }

    it "numbers the staff a voice is written on in each bar" do
      expect((1..4).map { |bar| plan.staff_number(left_hand, bar) }).to eq [2, 1, 1, 2]
    end

    it "names the staff and layer a voice is written in" do
      expect(plan.staff_and_layer(left_hand, 2)).to eq("staff" => 1, "layer" => 2)
    end

    it "names the top staff of a part" do
      expect(plan.top_staff_number(left_hand.part)).to eq 1
    end

    it "lists the voices written on a staff in a bar" do
      expect(plan.layer_voices(plan.staff_entries.first, 2)).to eq flow.voices
    end
  end

  describe "#items_of" do
    it "lists every piece of a voice event across bars" do
      expect(plan.items_of(voice.voice_events[1]).map(&:id)).to eq %w[m1-p1v1-b1c3 m1-p1v1-b2c1]
    end
  end

  describe "#source" do
    let(:source_class) do
      Class.new do
        attr_reader :plan

        def initialize(plan) = @plan = plan
      end
    end

    it "builds one instance of a source class for the plan" do
      expect(plan.source(source_class)).to equal plan.source(source_class)
    end

    it "builds every registered source while the plan is built" do
      allow(HeadMusic::Notation::MEI::MeasureWriter).to receive(:control_sources).and_return([source_class])
      allow(source_class).to receive(:new).and_call_original
      plan
      expect(source_class).to have_received(:new).with(plan)
    end

    it "raises while the plan is built for a source that cannot be built" do
      failing = Class.new { def initialize(_plan) = raise(HeadMusic::Notation::MEI::RenderError, "no") }
      allow(HeadMusic::Notation::MEI::SectionWriter).to receive(:bar_group).and_return(failing)
      expect { plan }.to raise_error(HeadMusic::Notation::MEI::RenderError, "no")
    end
  end

  it "raises at construction for a duration MEI cannot write" do
    allow(HeadMusic::Notation::MEI::Durations).to receive(:dur).and_raise(HeadMusic::Notation::MEI::RenderError, "no")
    expect { plan }.to raise_error(HeadMusic::Notation::MEI::RenderError)
  end
end
