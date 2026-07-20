require "spec_helper"

describe HeadMusic::Notation::MusicXML::Preflight do
  render_error = HeadMusic::Notation::MusicXML::RenderError

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

    context "with bar markers authored as strings" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new
        voice = composition.add_voice
        voice.place("1:1", :whole, "C4")
        composition.change_meter(1, "4/4")
        composition.change_key_signature(1, "D major")
        composition
      end

      before { described_class.check!(composition) }

      it "coerces the bar meter to a Meter in place" do
        expect(composition.bars.find(&:meter).meter).to be_a HeadMusic::Rudiment::Meter
      end

      it "coerces the bar key signature to a KeySignature in place" do
        expect(composition.bars.find(&:key_signature).key_signature).to be_a HeadMusic::Rudiment::KeySignature
      end
    end

    context "with no voices" do
      let(:composition) { HeadMusic::Content::Composition.new }

      it "raises a render error" do
        expect { described_class.check!(composition) }.to raise_error(render_error, /no voices/)
      end
    end

    context "with a control character in a text field" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new(name: "Bad#{7.chr}Name")
        composition.add_voice
        composition
      end

      it "raises a render error" do
        expect { described_class.check!(composition) }.to raise_error(render_error, /control characters/)
      end
    end

    context "with a gap between placements" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new
        voice = composition.add_voice
        voice.place("1:1", :quarter, "C4")
        voice.place("1:3", :quarter, "D4")
        composition
      end

      it "raises a render error naming the expected position" do
        expect { described_class.check!(composition) }.to raise_error(render_error, /expected a placement at 1:2:000/)
      end
    end

    context "with a note that crosses its barline" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new
        voice = composition.add_voice
        voice.place("1:1", "double whole", "C4")
        composition
      end

      it "raises a render error" do
        expect { described_class.check!(composition) }.to raise_error(render_error, /crosses its barline/)
      end
    end
  end
end
