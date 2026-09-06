require "spec_helper"

describe HeadMusic::Notation::MusicXML::Preflight do
  render_error = HeadMusic::Notation::MusicXML::RenderError

  describe ".check!" do
    context "with a renderable flow" do
      let(:flow) do
        flow = HeadMusic::Content::Flow.new(name: "Tune")
        voice = flow.add_voice
        %w[C4 D4 E4 F4].each_with_index { |pitch, index| voice.place("1:#{index + 1}", :quarter, pitch) }
        flow
      end

      it "returns without raising" do
        expect { described_class.check!(flow) }.not_to raise_error
      end
    end

    context "with no voices" do
      let(:flow) { HeadMusic::Content::Flow.new }

      it "raises a render error" do
        expect { described_class.check!(flow) }.to raise_error(render_error, /no voices/)
      end
    end

    context "with a control character in a text field" do
      let(:flow) do
        flow = HeadMusic::Content::Flow.new(name: "Bad#{7.chr}Name")
        flow.add_voice
        flow
      end

      it "raises a render error" do
        expect { described_class.check!(flow) }.to raise_error(render_error, /control characters/)
      end
    end

    context "with a gap between placements" do
      let(:flow) do
        flow = HeadMusic::Content::Flow.new
        voice = flow.add_voice
        voice.place("1:1", :quarter, "C4")
        voice.place("1:3", :quarter, "D4")
        flow
      end

      it "raises a render error naming the expected position" do
        expect { described_class.check!(flow) }.to raise_error(render_error, /expected a placement at 1:2:000/)
      end
    end

    context "with a note that crosses its barline" do
      let(:flow) do
        flow = HeadMusic::Content::Flow.new
        voice = flow.add_voice
        voice.place("1:1", "double whole", "C4")
        flow
      end

      it "raises a render error" do
        expect { described_class.check!(flow) }.to raise_error(render_error, /crosses its barline/)
      end
    end
  end
end
