require "spec_helper"

describe HeadMusic::Notation::LilyPond::Preflight do
  render_error = HeadMusic::Notation::LilyPond::RenderError

  describe ".check!" do
    context "with a renderable composition" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new(name: "Tune")
        voice = composition.add_voice
        %w[C4 D4 E4 F4].each_with_index { |pitch, index| voice.place("1:#{index + 1}", :quarter, pitch) }
        composition
      end

      it "returns without raising" do
        expect { described_class.check!(composition) }.not_to raise_error
      end
    end

    context "with no voices" do
      let(:composition) { HeadMusic::Content::Composition.new }

      it "raises a render error" do
        expect { described_class.check!(composition) }.to raise_error(render_error, /no voices/)
      end
    end

    context "with a first placement that does not start its bar" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new
        composition.add_voice.place("1:2", :quarter, "C4")
        composition
      end

      it "raises a render error" do
        expect { described_class.check!(composition) }
          .to raise_error(render_error, /first placement must start its bar/)
      end
    end

    context "with a positional gap between placements" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new
        voice = composition.add_voice
        voice.place("1:1", :quarter, "C4")
        voice.place("1:4", :quarter, "E4")
        composition
      end

      it "raises a render error" do
        expect { described_class.check!(composition) }
          .to raise_error(render_error, /insert explicit rests to fill gaps/)
      end
    end

    context "with a note that crosses its barline" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new
        voice = composition.add_voice
        %w[C4 D4 E4].each_with_index { |pitch, index| voice.place("1:#{index + 1}", :quarter, pitch) }
        voice.place("1:4", :half, "F4")
        composition
      end

      it "raises a render error" do
        expect { described_class.check!(composition) }
          .to raise_error(render_error, /crosses its barline/)
      end
    end

    context "with a voice that ends mid-bar" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new
        composition.add_voice.place("1:1", :whole, "E5")
        composition.add_voice.place("1:1", :quarter, "C3")
        composition
      end

      it "raises a render error rather than emitting an underfilled bar" do
        expect { described_class.check!(composition) }
          .to raise_error(render_error, /ends mid-bar at 1:2.*insert explicit rests to fill the final bar/)
      end
    end

    context "with an unpitched sound" do
      let(:composition) do
        HeadMusic::Content::Composition.new.tap do |composition|
          composition.add_voice.place("1:1", :whole, HeadMusic::Rudiment::UnpitchedSound.get("snare drum"))
        end
      end

      it "raises a render error naming the sound and position" do
        expect { described_class.check!(composition) }.to raise_error(
          render_error,
          /cannot render unpitched sound "snare drum" at 1:1.*percussion rendering is not yet supported/
        )
      end
    end
  end
end
