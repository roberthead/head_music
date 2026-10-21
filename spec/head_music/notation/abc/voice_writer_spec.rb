require "spec_helper"

describe HeadMusic::Notation::ABC::VoiceWriter do
  subject(:voice_writer) { described_class.new(voice, plan) }

  let(:plan) { HeadMusic::Notation::ABC::RenderPlan.new(flow) }
  let(:voice) { flow.voices.first }

  def tune(key, body)
    HeadMusic::Notation::ABC.parse("X:1\nT:Voice\nM:4/4\nL:1/8\nK:#{key}\n#{body}\n")
  end

  describe "#bars" do
    let(:flow) { tune("G", "|:GABc dedB|dedB d4-|d8:|") }

    it "writes each bar the voice sounds in with its bar lines" do
      expect(voice_writer.bars).to eq ["|:GABc dedB|", "dedB d4-|", "d8:|"]
    end

    context "with a voice that is not the first" do
      let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nT:Voice\nM:4/4\nL:1/8\nK:C\nV:1\nC8|C8|]\nV:2\nE4 G4|c8|]\n") }
      let(:voice) { flow.voices.last }

      it "writes that voice's bars" do
        expect(voice_writer.bars).to eq ["E4 G4|", "c8|]"]
      end
    end

    context "with a key signature" do
      let(:flow) { tune("D", "DEFG ABcd|]") }

      it "writes no accidental the key already implies" do
        expect(voice_writer.bars).to eq ["DEFG ABcd|]"]
      end
    end

    context "when transposed for a B-flat clarinet" do
      let(:plan) { HeadMusic::Notation::ABC::RenderPlan.new(flow, transposed: true) }
      let(:flow) { tune("C", "D^F A2 d4|]").tap { |flow| flow.parts.first.change_instrument(1, "clarinet") } }

      it "spells the pitches in the part's written key" do
        expect(voice_writer.bars).to eq ["DF A2 d4|]"]
      end
    end
  end

  describe "#validate!" do
    let(:flow) { tune("C", "C3/2 D/ E2 F4|]").tap { |flow| flow.voices.first.place_dynamic("1:1:001", :p) } }

    it "refuses a mark no binary note value reaches, before writing anything" do
      expect { voice_writer.validate! }
        .to raise_error HeadMusic::Notation::ABC::RenderError, /cannot place the dynamic p at 1:1:001/
    end
  end
end
