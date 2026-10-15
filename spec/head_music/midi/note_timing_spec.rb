require "spec_helper"

describe HeadMusic::MIDI::NoteTiming do
  subject(:timing) { described_class.new(voice_event, resolver) }

  let(:flow) { HeadMusic::Content::Flow.new(name: "Timing") }
  let(:voice) { flow.add_voice }
  let(:resolver) { instance_double(HeadMusic::MIDI::VelocityResolver, velocity: 90, grace_velocity: 70) }
  let(:voice_event) { voice.place("1:1", :quarter, "C4") }

  def spans
    timing.pieces.map { |piece| [piece.sounds.map(&:to_s), piece.from, piece.to] }
  end

  def r(numerator, denominator)
    Rational(numerator, denominator)
  end

  describe "a plain note" do
    it "sounds whole, as one piece at the note's velocity" do
      expect(timing.pieces).to eq [described_class::Piece.new(voice_event.sounds, 0, r(1, 4), 90, 0)]
    end
  end

  describe "a chord" do
    let(:voice_event) { voice.place("1:1", :half, %w[C4 E4 G4]) }

    it "strikes every pitch in one piece" do
      expect(spans).to eq [[%w[C4 E4 G4], 0, r(1, 2)]]
    end
  end

  describe "articulation length" do
    {
      staccatissimo: Rational(1, 16),
      staccato: Rational(1, 8),
      tenuto: Rational(1, 4),
      accent: Rational(1, 4)
    }.each do |articulation, release|
      it "releases a #{articulation} quarter at #{release}" do
        voice_event.articulate(articulation)
        expect(timing.pieces.first.to).to eq release
      end
    end

    it "sounds staccato with tenuto, as portato, for three quarters" do
      voice_event.articulate(:staccato, :tenuto)
      expect(timing.pieces.first.to).to eq r(3, 16)
    end

    it "lets the shortest factor win" do
      voice_event.articulate(:staccato, :staccatissimo)
      expect(timing.length_factor).to eq r(1, 4)
    end

    context "with staccatissimo, staccato and tenuto on a whole note" do
      let(:voice_event) { voice.place("1:1", :whole, "C4") }

      it "sounds staccatissimo, for a quarter, rather than portato" do
        voice_event.articulate(:staccatissimo, :staccato, :tenuto)
        expect(timing.pieces.first.to).to eq r(1, 4)
      end
    end

    it "lets staccatissimo win over tenuto" do
      voice_event.articulate(:staccatissimo, :tenuto)
      expect(timing.length_factor).to eq r(1, 4)
    end

    context "with a tied chain" do
      let(:voice_event) { voice.place("1:1", "half tied to quarter", "C4") }

      it "shortens only the last link" do
        voice_event.articulate(:staccato)
        expect(timing.pieces.first.to).to eq r(5, 8)
      end
    end
  end

  describe "grace notes" do
    it "sounds a lone acciaccatura as a thirty-second on the beat" do
      voice_event.add_grace_note("D4", :eighth, slashed: true)
      expect(spans).to eq [[%w[C4], r(1, 32), r(1, 4)], [%w[D4], 0, r(1, 32)]]
    end

    it "gives a lone appoggiatura half the main note's first link" do
      tied = voice.place("1:1", "half tied to quarter", "C4").add_grace_note("D4", :eighth)
      expect(described_class.new(tied, resolver).pieces.map { |piece| [piece.from, piece.to] }).to eq [[r(1, 4), r(3, 4)], [0, r(1, 4)]]
    end

    it "sounds each note of a group as a thirty-second" do
      voice_event.add_grace_note("E4", :sixteenth).add_grace_note("D4", :sixteenth)
      expect(spans).to eq [[%w[C4], r(1, 16), r(1, 4)], [%w[E4], 0, r(1, 32)], [%w[D4], r(1, 32), r(1, 16)]]
    end

    it "shares half the main note equally when a group would take more" do
      short = voice.place("1:1", :sixteenth, "C4")
      %w[F4 E4 D4].each { |pitch| short.add_grace_note(pitch, :thirty_second) }
      expect(described_class.new(short, resolver).pieces.map(&:from)).to eq [r(1, 32), 0, r(1, 96), r(1, 48)]
    end

    it "caps a lone acciaccatura at half the main note" do
      short = voice.place("1:1", :thirty_second, "C4").add_grace_note("D4", :eighth, slashed: true)
      expect(described_class.new(short, resolver).pieces.map { |piece| [piece.from, piece.to] }).to eq [[r(1, 64), r(1, 32)], [0, r(1, 64)]]
    end

    it "gives a grace chord one piece per pitch" do
      voice_event.add_grace_note(%w[E4 G4], :sixteenth, slashed: true)
      expect(spans.drop(1)).to eq [[%w[E4], 0, r(1, 32)], [%w[G4], 0, r(1, 32)]]
    end

    it "strikes grace notes at the grace velocity" do
      voice_event.add_grace_note("D4", :eighth, slashed: true)
      expect(timing.pieces.map(&:velocity)).to eq [90, 70]
    end

    it "asks for the grace velocity of each grace note" do
      voice_event.add_grace_note("D4", :eighth, slashed: true)
      timing.pieces
      expect(resolver).to have_received(:grace_velocity).with(voice_event, voice_event.grace_notes.first)
    end

    it "numbers the pieces uniquely" do
      voice_event.add_grace_note(%w[E4 G4], :sixteenth).add_grace_note("D4", :sixteenth)
      expect(timing.pieces.map(&:id)).to eq [0, 1, 2, 3]
    end

    it "keeps every piece at or after the onset" do
      voice_event.add_grace_note(%w[E4 G4], :sixteenth).add_grace_note("D4", :sixteenth, slashed: true)
      expect(timing.pieces.map(&:from)).to all(be >= 0)
    end

    it "keeps a staccato main note sounding past its grace notes" do
      short = voice.place("1:1", :sixteenth, "C4").articulate(:staccato).add_grace_note("D4", :eighth)
      expect(described_class.new(short, resolver).pieces.first).to have_attributes(from: r(1, 32), to: r(3, 64))
    end

    context "when the last grace note is tied to the main note's key" do
      before { voice_event.add_grace_note("D4", :sixteenth).add_grace_note("C4", :sixteenth, tied: true) }

      it "sounds the grace note through the main note's release, which is not struck again" do
        expect(spans).to eq [[%w[D4], 0, r(1, 32)], [%w[C4], r(1, 32), r(1, 4)]]
      end

      it "holds it only to the articulated release" do
        voice_event.articulate(:staccato)
        expect(spans.last).to eq [%w[C4], r(1, 32), r(1, 8)]
      end
    end

    it "strikes the main note's other pitches when a tied grace note holds one" do
      chord = voice.place("1:1", :quarter, %w[C4 E4]).add_grace_note("C4", :sixteenth, tied: true)
      pieces = described_class.new(chord, resolver).pieces
      expect(pieces.map { |piece| [piece.sounds.map(&:to_s), piece.from, piece.to] }).to eq [[%w[E4], r(1, 8), r(1, 4)], [%w[C4], 0, r(1, 4)]]
    end

    it "ignores a tie from a grace note on another key" do
      voice_event.add_grace_note("D4", :sixteenth, slashed: true, tied: true)
      expect(spans).to eq [[%w[C4], r(1, 32), r(1, 4)], [%w[D4], 0, r(1, 32)]]
    end
  end
end
