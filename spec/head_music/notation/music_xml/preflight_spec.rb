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
        expect { described_class.check!(flow) }.to raise_error(render_error, /characters XML forbids/)
      end
    end

    context "with a control character in a text the writer writes" do
      bad = "Bad#{7.chr}Text"

      def flow_with(name: "Tune", composer: nil, work: nil, role: nil)
        HeadMusic::Content::Flow.new(name: name, composer: composer, work: work).tap do |flow|
          flow.add_part(instrument: "flute").add_voice(role: role).place("1:1", :whole, "C4")
        end
      end

      {
        "flow name" => -> { flow_with(name: bad) },
        "composer" => -> { flow_with(composer: bad) },
        "voice role" => -> { flow_with(role: bad) },
        "syllable" => -> { flow_with.tap { |flow| flow.voices.first.voice_events.first.sing(bad) } },
        "player name" => -> { flow_with.tap { |flow| flow.parts.first.player = HeadMusic::Content::Player.new(name: bad) } },
        "instrument name" => -> { flow_with.tap { |flow| allow(flow.parts.first.instrument).to receive(:name).and_return(bad) } },
        "rehearsal mark" => -> { flow_with.tap { |flow| flow.bar(1).rehearsal_mark = bad } },
        "work title" => -> { flow_with(work: HeadMusic::Content::Work.new(title: bad)) },
        "work credit" => -> {
          credit = HeadMusic::Content::Credit.new(person: bad, role: :composer)
          flow_with(work: HeadMusic::Content::Work.new(title: "Suite", credits: [credit]))
        }
      }.each do |text, build|
        it "raises a render error for the #{text}" do
          flow = instance_exec(&build)
          expect { described_class.check!(flow) }.to raise_error(render_error, /characters XML forbids in "Bad\\aText"/)
        end
      end

      it "raises a render error for a text the writer is given" do
        expect { described_class.check!(flow_with, [bad]) }.to raise_error(render_error, /characters XML forbids/)
      end
    end

    context "with a gap between voice events" do
      let(:flow) do
        flow = HeadMusic::Content::Flow.new
        voice = flow.add_voice
        voice.place("1:1", :quarter, "C4")
        voice.place("1:3", :quarter, "D4")
        flow
      end

      it "raises a render error naming the expected position" do
        expect { described_class.check!(flow) }.to raise_error(render_error, /expected a voice event at 1:2:000/)
      end
    end

    context "with a note that crosses its barline" do
      let(:flow) do
        flow = HeadMusic::Content::Flow.new
        voice = flow.add_voice
        voice.place("1:1", "double whole", "C4")
        flow
      end

      it "passes, leaving the writer to split the note at the barline" do
        expect { described_class.check!(flow) }.not_to raise_error
      end
    end
  end
end
