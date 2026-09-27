require "spec_helper"

describe HeadMusic::Notation::MusicXML::DirectionWriter do
  subject(:writer) { described_class.new(plan) }

  let(:plan) { HeadMusic::Notation::MusicXML::RenderPlan.new(flow) }

  def dynamics_written(lines)
    lines.grep(/<dynamics>/).map { |line| line[%r{<dynamics><(\w+)/>}, 1] }
  end

  def offset_in(lines)
    lines.grep(/<offset>/).map { |line| line[/<offset>(\d+)</, 1].to_i }
  end

  describe "#part_lines" do
    let(:flow) do
      flow = HeadMusic::Content::Flow.new(name: "Part Dynamics", meter: "4/4")
      flow.add_voice.place("1:1", :whole, "C4")
      flow.parts.first.place_dynamic("1:1", :p)
      flow.parts.first.place_dynamic("1:3", :f)
      flow
    end

    it "writes a direction for each dynamic event in the bar" do
      expect(dynamics_written(writer.part_lines(flow.parts.first, 1))).to eq %w[p f]
    end

    it "omits the offset for a dynamic at the bar's own start" do
      lines = writer.part_lines(flow.parts.first, 1)
      expect(offset_in(lines)).to eq [2 * plan.divisions]
    end

    it "gives a mid-bar dynamic an offset from the bar's own start" do
      lines = writer.part_lines(flow.parts.first, 1)
      expect(lines.grep(/<offset>/).length).to eq 1
    end

    it "writes neither a voice nor a staff on a part event" do
      lines = writer.part_lines(flow.parts.first, 1)
      expect(lines.grep(%r{<voice>|<staff>})).to be_empty
    end

    it "writes nothing for a bar with no part dynamic" do
      flow.add_voice.place("2:1", :whole, "D4")
      expect(writer.part_lines(flow.parts.first, 2)).to eq []
    end
  end

  describe "#voice_lines" do
    let(:voice) { flow.voices.first }
    let(:segment) { plan.segments_by_bar(voice)[1].first }

    context "with a dynamic exactly at the segment's own start" do
      let(:flow) do
        flow = HeadMusic::Content::Flow.new(name: "On the Beat", meter: "4/4")
        voice = flow.add_voice
        voice.place("1:1", :whole, "C4")
        voice.place_dynamic("1:1", :p)
        flow
      end

      it "writes the dynamic with no offset" do
        lines = writer.voice_lines(voice, 1, segment)
        expect([dynamics_written(lines), offset_in(lines)]).to eq [%w[p], []]
      end
    end

    context "with a dynamic under a held note" do
      let(:flow) do
        flow = HeadMusic::Content::Flow.new(name: "Held", meter: "4/4")
        voice = flow.add_voice
        voice.place("1:1", :whole, "C4")
        voice.place_dynamic("1:3", :f)
        flow
      end

      it "offsets the dynamic from the note's own start" do
        lines = writer.voice_lines(voice, 1, segment)
        expect(offset_in(lines)).to eq [2 * plan.divisions]
      end
    end

    context "with a dynamic under a rest" do
      let(:flow) do
        flow = HeadMusic::Content::Flow.new(name: "Silent", meter: "4/4")
        voice = flow.add_voice
        voice.place("1:1", :whole)
        voice.place_dynamic("1:1", :mf)
        flow
      end

      it "still writes the dynamic on the rest's segment" do
        expect(dynamics_written(writer.voice_lines(voice, 1, segment))).to eq %w[mf]
      end
    end

    context "with voice and staff numbers" do
      let(:flow) do
        flow = HeadMusic::Content::Flow.new(name: "Numbered", meter: "4/4")
        voice = flow.add_voice
        voice.place("1:1", :whole, "C4")
        voice.place_dynamic("1:1", :p)
        flow
      end

      it "writes the given voice and staff numbers" do
        lines = writer.voice_lines(voice, 1, segment, voice_number: 2, staff_number: 1)
        expect(lines.map(&:strip)).to include("<voice>2</voice>", "<staff>1</staff>")
      end
    end

    context "with a note split across a bar line" do
      let(:flow) do
        flow = HeadMusic::Content::Flow.new(name: "Split", meter: "4/4")
        voice = flow.add_voice
        voice.place("1:4", :half, "C4")
        voice.place_dynamic("2:1", :f)
        flow
      end

      it "puts the second bar's dynamic on the second bar's segment, not the first's" do
        first_segment = plan.segments_by_bar(voice)[1].first
        second_segment = plan.segments_by_bar(voice)[2].first
        expect([writer.voice_lines(voice, 1, first_segment), dynamics_written(writer.voice_lines(voice, 2, second_segment))])
          .to eq [[], %w[f]]
      end
    end
  end

  describe "#trailing_lines" do
    let(:flow) do
      flow = HeadMusic::Notation::ABC.parse("X:1\nL:1/4\nM:4/4\nK:C\nC D|\n")
      flow.voices.first.place_dynamic("1:3", :f)
      flow.voices.first.place_dynamic("1:4", :p)
      flow
    end

    it "offsets each dynamic after the voice's last note from where the voice ends" do
      lines = writer.trailing_lines(flow.voices.first, 1)
      expect([dynamics_written(lines), offset_in(lines)]).to eq [%w[f p], [plan.divisions]]
    end

    it "writes nothing for a dynamic under the last note" do
      flow = HeadMusic::Notation::ABC.parse("X:1\nL:1/4\nM:4/4\nK:C\nC D2|\n")
      flow.voices.first.place_dynamic("1:3", :f)
      expect(described_class.new(HeadMusic::Notation::MusicXML::RenderPlan.new(flow)).trailing_lines(flow.voices.first, 1)).to eq []
    end
  end

  describe "#voice_rest_lines" do
    let(:flow) do
      flow = HeadMusic::Content::Flow.new(name: "Silent Bar", meter: "4/4")
      soprano = flow.add_voice(role: "Soprano")
      bass = flow.add_voice(role: "Bass")
      soprano.place("1:1", :whole, "E5")
      soprano.place("2:1", :whole, "D5")
      bass.place("1:1", :whole, "C3")
      bass.place_dynamic("2:3", :mp)
      flow
    end

    it "offsets a dynamic in a bar the voice has no notes in from the bar's own start" do
      bass = flow.voices.last
      expect(offset_in(writer.voice_rest_lines(bass, 2))).to eq [2 * plan.divisions]
    end
  end
end
