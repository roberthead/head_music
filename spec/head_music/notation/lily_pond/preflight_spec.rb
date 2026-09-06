require "spec_helper"

describe HeadMusic::Notation::LilyPond::Preflight do
  render_error = HeadMusic::Notation::LilyPond::RenderError

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

    context "with a first placement that does not start its bar" do
      let(:flow) do
        flow = HeadMusic::Content::Flow.new
        flow.add_voice.place("1:2", :quarter, "C4")
        flow
      end

      it "raises a render error" do
        expect { described_class.check!(flow) }
          .to raise_error(render_error, /first placement must start its bar/)
      end
    end

    context "with a positional gap between placements" do
      let(:flow) do
        flow = HeadMusic::Content::Flow.new
        voice = flow.add_voice
        voice.place("1:1", :quarter, "C4")
        voice.place("1:4", :quarter, "E4")
        flow
      end

      it "raises a render error" do
        expect { described_class.check!(flow) }
          .to raise_error(render_error, /insert explicit rests to fill gaps/)
      end
    end

    context "with a note that crosses its barline" do
      let(:flow) do
        flow = HeadMusic::Content::Flow.new
        voice = flow.add_voice
        %w[C4 D4 E4].each_with_index { |pitch, index| voice.place("1:#{index + 1}", :quarter, pitch) }
        voice.place("1:4", :half, "F4")
        flow
      end

      it "raises a render error" do
        expect { described_class.check!(flow) }
          .to raise_error(render_error, /crosses its barline/)
      end
    end

    context "with a voice that ends mid-bar" do
      let(:flow) do
        flow = HeadMusic::Content::Flow.new
        flow.add_voice.place("1:1", :whole, "E5")
        flow.add_voice.place("1:1", :quarter, "C3")
        flow
      end

      it "raises a render error rather than emitting an underfilled bar" do
        expect { described_class.check!(flow) }
          .to raise_error(render_error, /ends mid-bar at 1:2.*insert explicit rests to fill the final bar/)
      end
    end

    context "with an unpitched sound" do
      let(:flow) do
        HeadMusic::Content::Flow.new.tap do |flow|
          flow.add_voice.place("1:1", :whole, HeadMusic::Rudiment::UnpitchedSound.get("snare drum"))
        end
      end

      it "raises a render error naming the sound and position" do
        expect { described_class.check!(flow) }.to raise_error(
          render_error,
          /cannot render unpitched sound "snare drum" at 1:1.*percussion rendering is not yet supported/
        )
      end
    end
  end
end
