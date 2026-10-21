require "spec_helper"

describe HeadMusic::Notation::FermataMarks do
  subject(:marks) { described_class.new }

  def satb(soprano, bass)
    HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/4\nV:S\nV:B\nK:C\nV:S\n#{soprano}\nV:B\n#{bass}\n")
  end

  def event(voice_index, code)
    flow.voices[voice_index].voice_event_at(flow.position(code))
  end

  def fermata_spans
    flow.fermatas.map { |fermata| [fermata.from.to_s, fermata.to.to_s] }
  end

  context "with a soprano quarter over a bass eighth pair" do
    let(:flow) { satb("c d e2|", "C D/ E/ F2|") }

    it "holds from the latest start to the earliest end of the marked events" do
      marks.add(event(0, "1:2"))
      marks.add(event(1, "1:2:480"))
      marks.apply(flow)
      expect(fermata_spans).to eq [["1:2:480", "1:3:000"]]
    end

    it "holds the whole flow for a mark in one voice only" do
      marks.add(event(0, "1:2"))
      marks.apply(flow)
      expect(fermata_spans).to eq [["1:2:000", "1:3:000"]]
    end
  end

  context "with a held half note over a moving quarter" do
    let(:flow) { satb("c2 d2|", "C D E2|") }

    it "holds the span the marked events share" do
      marks.add(event(0, "1:1"))
      marks.add(event(1, "1:2"))
      marks.apply(flow)
      expect(fermata_spans).to eq [["1:2:000", "1:3:000"]]
    end
  end

  context "with a general pause" do
    let(:flow) { satb("c2 z2|", "C2 z2|") }

    it "holds on rests as on notes" do
      marks.add(event(0, "1:3"))
      marks.add(event(1, "1:3"))
      marks.apply(flow)
      expect(fermata_spans).to eq [["1:3:000", "2:1:000"]]
    end
  end

  context "with a note tied into a later bar" do
    let(:flow) { satb("c4-|c4|", "C4-|C4|") }

    it "starts a mark on the later link at that link" do
      marks.add(event(0, "1:1"), from: flow.position("2:1"))
      marks.apply(flow)
      expect(fermata_spans).to eq [["2:1:000", "3:1:000"]]
    end
  end

  context "with marks that do not overlap" do
    let(:flow) { satb("c d e f|", "C D E F|") }

    it "forms a fermata for each" do
      marks.add(event(0, "1:2"))
      marks.add(event(1, "1:3"))
      marks.apply(flow)
      expect(fermata_spans).to eq [["1:2:000", "1:3:000"], ["1:3:000", "1:4:000"]]
    end
  end

  context "with duplicate marks" do
    let(:flow) { satb("c d e f|", "C D E F|") }

    it "forms one fermata" do
      2.times { marks.add(event(0, "1:4")) }
      marks.apply(flow)
      expect(fermata_spans).to eq [["1:4:000", "2:1:000"]]
    end
  end

  describe "#add_moment" do
    let(:flow) { satb("c2 d2|", "C D E2|") }

    it "marks each event sounding at the moment in the voices, from the moment" do
      marks.add_moment(flow.position("1:2"), flow.voices)
      marks.apply(flow)
      expect(fermata_spans).to eq [["1:2:000", "1:3:000"]]
    end

    it "passes over a voice with nothing sounding there" do
      marks.add_moment(flow.position("2:1"), flow.voices)
      marks.apply(flow)
      expect(fermata_spans).to be_empty
    end
  end

  context "with a fermata already on the timeline" do
    let(:flow) { satb("c d e f|", "C D E F|").tap { |held| held.add_fermata("1:2", to: "1:4") } }

    it "drops a fermata the timeline refuses and keeps the rest" do
      marks.add(event(0, "1:3"))
      marks.add(event(0, "1:4"))
      marks.apply(flow)
      expect(fermata_spans).to eq [["1:2:000", "1:4:000"], ["1:4:000", "2:1:000"]]
    end
  end

  describe ".carriers" do
    context "with a fermata under a soprano quarter and a bass eighth" do
      let(:flow) { satb("c d e2|", "C D/ E/ F2|").tap { |flow| flow.add_fermata("1:2:480", :eighth) } }

      it "answers each voice's event sounding where the fermata begins, those that began before it included" do
        expect(described_class.carriers(flow).keys.map(&:to_s)).to eq ["quarter D5 at 1:2:000", "eighth E4 at 1:2:480"]
      end

      it "maps each carrier to its fermata" do
        expect(described_class.carriers(flow).values.uniq).to eq flow.fermatas
      end

      it "reads back the fermata it marks" do
        reread = satb("c d e2|", "C D/ E/ F2|")
        described_class.carriers(flow).each_key { |carrier| marks.add(reread_event(reread, carrier)) }
        marks.apply(reread)
        expect(reread.fermatas.map { |fermata| [fermata.from.to_s, fermata.to.to_s] }).to eq [["1:2:480", "1:3:000"]]
      end

      def reread_event(reread, voice_event)
        reread.voices[flow.voices.index(voice_event.voice)].voice_event_at(reread.position(voice_event.position.to_s))
      end
    end

    it "marks rests" do
      flow = satb("c2 z2|", "C2 z2|").tap { |general_pause| general_pause.add_fermata("1:3", :half) }
      expect(described_class.carriers(flow).keys.map(&:rest?)).to eq [true, true]
    end

    it "answers no carrier in a voice that has stopped" do
      flow = satb("c d e f|", "C2|").tap { |shorter| shorter.add_fermata("1:4", :quarter) }
      expect(described_class.carriers(flow).keys.map(&:to_s)).to eq ["quarter F5 at 1:4:000"]
    end
  end
end
