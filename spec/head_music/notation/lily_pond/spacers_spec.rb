require "spec_helper"

describe HeadMusic::Notation::LilyPond::Spacers do
  subject(:spacers) { described_class.new }

  let(:flow) { HeadMusic::Content::Flow.new(key_signature: "C major", meter: "4/4") }
  let(:voice) { flow.add_voice }

  def spacer(fraction)
    HeadMusic::Notation::LilyPond::VoiceStream::Event.new(kind: :spacer, line: 1, fraction: fraction)
  end

  it "answers the voice's next position where it has read no spacers" do
    voice.place("1:1", :half, "C4")
    expect(spacers.position(voice)).to eq flow.position("1:3")
  end

  it "moves the voice's position past the spacers it holds, without placing events" do
    spacers.hold(voice, spacer(Rational(1, 4)))
    spacers.hold(voice, spacer(Rational(1, 2)))
    expect([spacers.position(voice), voice.voice_events]).to eq [flow.position("1:4"), []]
  end

  it "rounds a run of spacers from where it reached exactly" do
    start = flow.position("1:1")
    reached = spacers.after(spacers.after(start, spacer(Rational(1, 28))), spacer(Rational(3, 28)))
    septuplet_sixteenths = Rational(HeadMusic::Rudiment::Rhythm::SUBTICKS_PER_WHOLE, 7)
    expect(reached).to eq start.advance(subticks: septuplet_sixteenths.round)
  end

  it "turns the spacers music follows into rests" do
    spacers.hold(voice, spacer(Rational(1, 4)))
    spacers.rest(voice)
    expect([voice.voice_events.map(&:rest?), spacers.position(voice)]).to eq [[true], flow.position("1:2")]
  end

  it "raises where a spacer has no rest to stand for it" do
    spacers.hold(voice, spacer(Rational(1, 3)))
    expect { spacers.rest(voice) }.to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, %r{1/3 whole notes})
  end

  describe "#finish" do
    before { voice.place("1:1", :half, "C4") }

    it "leaves the spacers in the bar where the music ends" do
      spacers.hold(voice, spacer(Rational(1, 2)))
      spacers.finish
      expect(voice.voice_events.length).to eq 1
    end

    it "rests the spacers that reach a later bar" do
      spacers.hold(voice, spacer(Rational(3, 4)))
      spacers.finish
      expect(voice.voice_events.map(&:rest?)).to eq [false, true]
    end
  end
end
