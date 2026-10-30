require "spec_helper"

describe HeadMusic::Notation::LilyPond::RenderPlan do
  def build_flow(key_signature: "C major", meter: "4/4")
    HeadMusic::Content::Flow.new(name: "Plan", key_signature: key_signature, meter: meter)
  end

  # A voice event's tokens in each bar it sounds in, joined as bar checks.
  def tokens_for(flow, voice_event)
    described_class.new(flow).tokens_by_segment
      .select { |segment, _| segment.voice_event.equal?(voice_event) }.values.join(" | ")
  end

  describe "#tokens_by_segment" do
    it "renders a pitched note as pitch plus duration" do
      flow = build_flow
      voice_event = flow.add_voice.place("1:1", :quarter, "G4")
      expect(tokens_for(flow, voice_event)).to eq "g'4"
    end

    it "renders a rest with its duration" do
      flow = build_flow
      voice_event = flow.add_voice.place("1:1", :half)
      expect(tokens_for(flow, voice_event)).to eq "r2"
    end

    it "joins the links of a tied chain with tie marks" do
      flow = build_flow
      value = HeadMusic::Rudiment::RhythmicDuration.get("half tied to eighth")
      voice_event = flow.add_voice.place("1:1", value, "C4")
      expect(tokens_for(flow, voice_event)).to eq "c'2~ c'8"
    end

    it "renders a tied chain of rests as consecutive untied rests" do
      flow = build_flow
      value = HeadMusic::Rudiment::RhythmicDuration.get("half tied to eighth")
      voice_event = flow.add_voice.place("1:1", value)
      expect(tokens_for(flow, voice_event)).to eq "r2 r8"
    end

    it "renders simultaneous pitches as a chord, low to high" do
      flow = build_flow
      voice_event = flow.add_voice.place("1:1", :quarter, %w[G4 C4 E4])
      expect(tokens_for(flow, voice_event)).to eq "<c' e' g'>4"
    end

    it "ties the whole chord across a tied chain" do
      flow = build_flow
      value = HeadMusic::Rudiment::RhythmicDuration.get("half tied to eighth")
      voice_event = flow.add_voice.place("1:1", value, %w[C4 E4])
      expect(tokens_for(flow, voice_event)).to eq "<c' e'>2~ <c' e'>8"
    end

    it "forces a clashing chord's accidentals on its first link alone" do
      flow = build_flow
      flow.add_voice.place("1:1", :dotted_half, "C4")
      voice_event = flow.voices.first.place("1:4", "half tied to quarter", %w[F4 F#4])
      expect(tokens_for(flow, voice_event)).to eq "<fis'! f'!>4~ | <fis' f'>2"
    end

    it "ends the piece before a barline with a tie mark" do
      flow = build_flow
      flow.add_voice.place("1:1", :dotted_half, "C4")
      voice_event = flow.voices.first.place("1:4", :half, "D4")
      expect(tokens_for(flow, voice_event)).to eq "d'4~ | d'4"
    end

    it "splits a tied chain at the barline between different durations" do
      flow = build_flow
      flow.add_voice.place("1:1", :half, "C4")
      voice_event = flow.voices.first.place("1:3", "whole tied to quarter", "D4")
      expect(tokens_for(flow, voice_event)).to eq "d'2~ | d'2."
    end

    it "ties each piece of a chord across the barline" do
      flow = build_flow
      flow.add_voice.place("1:1", :dotted_half, "C4")
      voice_event = flow.voices.first.place("1:4", :half, %w[E4 G4])
      expect(tokens_for(flow, voice_event)).to eq "<e' g'>4~ | <e' g'>4"
    end

    it "splits a rest at the barline without a tie" do
      flow = build_flow
      flow.add_voice.place("1:1", :dotted_half, "C4")
      voice_event = flow.voices.first.place("1:4", :half)
      expect(tokens_for(flow, voice_event)).to eq "r4 | r4"
    end
  end

  describe "#short_final_bar_fraction" do
    it "is nil where the final bar is full" do
      flow = build_flow
      flow.add_voice.place("1:1", :whole, "C4")
      expect(described_class.new(flow).short_final_bar_fraction).to be_nil
    end

    it "is the length the voices fill of a final bar they end short of" do
      flow = build_flow(meter: "3/4")
      flow.add_voice.place("1:1", :half, "C4")
      expect(described_class.new(flow).short_final_bar_fraction).to eq Rational(1, 2)
    end

    it "is nil where a dynamic follows the music, so the bar is written full" do
      flow = build_flow(meter: "3/4")
      flow.add_voice.place("1:1", :half, "C4")
      flow.parts.first.place_dynamic("1:3", :f)
      plan = described_class.new(flow)
      expect([plan.short_final_bar_fraction, plan.music_end_fraction, plan.filled_final_bar?(1)]).to eq [nil, Rational(1, 2), true]
    end

    it "is nil where a voice hairpin ends after the music but before the final barline" do
      flow = build_flow(meter: "3/4")
      flow.add_voice.place("1:1", :half, "C4")
      flow.voices.first.add_span(:crescendo, from: "1:1", to: "1:3")
      expect(described_class.new(flow).short_final_bar_fraction).to be_nil
    end

    it "stays short where a voice hairpin ends only on the final barline" do
      flow = build_flow(meter: "3/4")
      flow.add_voice.place("1:1", :half, "C4")
      flow.voices.first.add_span(:crescendo, from: "1:1", to: "2:1")
      expect(described_class.new(flow).short_final_bar_fraction).to eq Rational(1, 2)
    end
  end

  describe "#bar_length" do
    it "is the meter's length of a full bar" do
      flow = build_flow(meter: "3/4")
      flow.add_voice.place("1:1", :half, "C4")
      flow.voices.first.place("2:1", :half, "D4")
      expect(described_class.new(flow).bar_length(1)).to eq Rational(3, 4)
    end

    it "is the length the voices fill of a short final bar" do
      flow = build_flow(meter: "3/4")
      flow.add_voice.place("1:1", :half, "C4")
      expect(described_class.new(flow).bar_length(1)).to eq Rational(1, 2)
    end
  end

  describe "#dynamics_bars" do
    let(:flow) do
      HeadMusic::Notation::ABC.parse("X:1\nT:Plan\nL:1/4\nM:4/4\nK:C\nC4|D4|\n").tap do |flow|
        flow.parts.first.add_span(:crescendo, from: "1:2", to: "2:3")
        flow.parts.first.add_span(:diminuendo, from: "2:3", to: "3:1")
      end
    end
    let(:plan) { described_class.new(flow) }

    it "reaches each hairpin mark with spacers, ending the last on the final barline" do
      expect(plan.dynamics_bars(flow.parts.first)).to eq(1 => "s4 s2.\\<", 2 => "s2 s2\\!\\> <>\\!")
    end

    it "counts a part with hairpins and no levels as having dynamics" do
      expect(plan.dynamics?(flow.parts.first)).to be true
    end
  end

  describe "#final_barline_marks" do
    it "ends an owner's hairpin on the final barline with a marker" do
      flow = build_flow
      flow.add_voice.place("1:1", :whole, "C4")
      flow.voices.first.add_span(:diminuendo, from: "1:2", to: "2:1")
      expect(described_class.new(flow).final_barline_marks(flow.voices.first)).to eq "<>\\!"
    end

    it "is nil for an owner whose hairpins end before it, and for a staff nobody is written on" do
      flow = build_flow
      flow.add_voice.place("1:1", :whole, "C4")
      flow.voices.first.add_span(:diminuendo, from: "1:2", to: "1:4")
      plan = described_class.new(flow)
      expect([plan.final_barline_marks(flow.voices.first), plan.final_barline_marks(nil)]).to eq [nil, nil]
    end
  end

  describe "#tokens_by_segment with hairpins" do
    let(:flow) do
      HeadMusic::Notation::ABC.parse("X:1\nT:Plan\nL:1/4\nM:4/4\nK:C\nC2 !p!!sf!D2|\n").tap do |flow|
        flow.voices.first.add_span(:crescendo, from: "1:1", to: "1:3")
        flow.voices.first.add_span(:diminuendo, from: "1:3", to: "2:1")
      end
    end

    it "writes a hairpin's end, then a level and an accent, then the next start, on one note" do
      expect(tokens_for(flow, flow.voices.first.voice_events.last)).to eq "d'2\\!\\p\\sf\\>"
    end
  end

  describe "#tokens_by_segment with tuplets" do
    it "opens a bracket before a group's first note and closes it after its last" do
      flow = TupletFixtures.triplets
      first, _, third = flow.voices.first.voice_events
      expect([tokens_for(flow, first), tokens_for(flow, third)]).to eq ["\\tuplet 3/2 { c'8", "e'8 }"]
    end

    it "closes a bracket after a split note's tie, in the bar after the one it opens in" do
      flow = TupletFixtures.tuplet_crossing_barline
      expect(tokens_for(flow, flow.voices.first.voice_events[2])).to eq "e'8~ | e'8"
    end

    it "closes a bracket partway through a chain, after the tie, and a slur on the chain's last link" do
      flow = TupletFixtures.triplet_tied_out
      flow.voices.first.add_span(:slur, from: "1:1", to: flow.voices.first.voice_events[2].position)
      expect(tokens_for(flow, flow.voices.first.voice_events[2])).to eq "e'8~ } e'4)"
    end
  end

  describe "#tuplet_edges" do
    it "keys each bracket's opening and closing by the segment and link it starts and ends on" do
      flow = TupletFixtures.tuplet_crossing_barline
      plan = described_class.new(flow)
      edges = plan.tuplet_edges(flow.voices.first)
      expect([edges[:opens].values, edges[:closes].values]).to eq [["\\tuplet 3/2 { "], [" }"]]
      expect(edges[:closes].keys.first.first.bar_number).to eq 2
    end
  end

  describe "signature tracking" do
    let(:flow) do
      flow = build_flow(key_signature: "G major")
      voice = flow.add_voice
      voice.place("1:1", :whole, "G4")
      voice.place("2:1", :whole, "A4")
      voice.place("3:1", "dotted half", "D4")
      flow.change_key_signature(3, "D major")
      flow.change_meter(3, "3/4")
      HeadMusic::Notation::LilyPond::Preflight.check!(flow)
      flow
    end
    let(:plan) { described_class.new(flow) }

    it "tokenizes the first measure key" do
      expect(plan.first_measure_key).to eq "\\key g \\major"
    end

    it "records the key change token at its bar" do
      expect(plan.measure_key_changes).to eq(3 => "\\key d \\major")
    end

    it "records the meter change at its bar" do
      expect(plan.measure_time_changes.keys).to eq [3]
    end

    it "reports the effective meter after the change" do
      expect(plan.effective_meter(3).to_s).to eq "3/4"
    end

    it "reports the flow meter before the change" do
      expect(plan.effective_meter(2).to_s).to eq "4/4"
    end
  end

  describe "eager validation" do
    it "raises at construction for an unmappable key signature" do
      flow = build_flow(key_signature: "C harmonic_minor")
      flow.add_voice.place("1:1", :whole, "C4")
      expect { described_class.new(flow) }
        .to raise_error(HeadMusic::Notation::LilyPond::RenderError, /scale type/i)
    end
  end
end
