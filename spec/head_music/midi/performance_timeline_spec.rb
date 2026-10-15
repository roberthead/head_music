require "spec_helper"

describe HeadMusic::MIDI::PerformanceTimeline do
  subject(:timeline) { described_class.new(flow) }

  def abc(body, meter: "4/4")
    HeadMusic::Notation::ABC.parse("X:1\nT:Timeline\nM:#{meter}\nL:1/4\nK:C\n#{body}\n")
  end

  context "with a plain flow" do
    let(:flow) { abc("C D E F | G A B c | c4 |]") }

    it "lays the bars end to end" do
      expect(timeline.spans.map { |span| [span.bar_number, span.start, span.length] }).to eq [[1, 0, 1], [2, 1, 1], [3, 2, 1]]
    end

    it "ends where the last bar does" do
      expect(timeline.finish).to eq 3
    end

    it "places an offset into a bar at its file time" do
      expect(timeline.spans[1].time_at(Rational(1, 4))).to eq Rational(5, 4)
    end
  end

  context "with NavigationFixtures.da_capo_al_fine" do
    let(:flow) { NavigationFixtures.da_capo_al_fine }

    it "follows the performance order" do
      expect(timeline.spans.map(&:bar_number)).to eq flow.performance_order.map(&:number)
    end

    it "starts each played bar where the one before it ends" do
      expect(timeline.spans.map(&:start)).to eq((0...timeline.spans.length).map { |index| index * Rational(3, 4) })
    end

    it "keeps each played bar's pass" do
      expect(timeline.spans.first(4).map(&:pass)).to eq [1, 1, 2, 2]
    end
  end

  context "with a tie into a first ending that the repeat skips" do
    let(:flow) { abc("|: C4- |[1 C4 :|[2 E4 |]") }

    it "plays the first ending on the first pass only" do
      expect(timeline.spans.map(&:bar_number)).to eq [1, 2, 1, 3]
    end

    it "carries the tie into the next bar of the score" do
      expect(timeline.continues_after?(0)).to be true
    end

    it "releases at the barline when the next played bar is not the next in the score" do
      expect(timeline.continues_after?(2)).to be false
    end

    it "releases at the end of the music" do
      expect(timeline.continues_after?(3)).to be false
    end
  end

  context "with a pickup" do
    let(:flow) { TupletFixtures.grace_notes_in_pickup }

    it "starts the file at the pickup's first note, past the rest that pads its bar" do
      expect(timeline.spans.first).to have_attributes(bar_number: 0, start: 0, window_from: Rational(1, 2), length: Rational(1, 2))
    end

    it "places the pickup's first note at the start of the file" do
      expect(timeline.spans.first.time_at(Rational(1, 2))).to eq 0
    end

    it "follows the pickup with bar 1" do
      expect(timeline.spans[1]).to have_attributes(bar_number: 1, start: Rational(1, 2), window_from: 0)
    end

    it "knows the pickup" do
      expect(timeline.spans.map(&:pickup?)).to eq [true, false]
    end
  end

  context "with a pickup inside a repeat" do
    let(:flow) do
      HeadMusic::Content::Flow.new(meter: "3/4").tap do |pickup|
        voice = pickup.add_voice
        voice.place("0:3", :quarter, "G4")
        voice.place("1:1", "dotted half", "C5")
        pickup.bar(0).starts_repeat = true
        pickup.bar(1).ends_repeat_after_num_plays = 2
      end
    end

    it "trims the pickup on every pass" do
      expect(timeline.spans.map { |span| [span.bar_number, span.start, span.length] }).to eq [
        [0, 0, Rational(1, 4)], [1, Rational(1, 4), Rational(3, 4)], [0, 1, Rational(1, 4)], [1, Rational(5, 4), Rational(3, 4)]
      ]
    end
  end

  context "with a pickup bar holding no notes" do
    let(:flow) do
      HeadMusic::Content::Flow.new.tap do |pickup|
        voice = pickup.add_voice
        voice.place("0:1", :whole)
        voice.place("1:1", :whole, "C4")
      end
    end

    it "plays nothing of it" do
      expect(timeline.spans.first).to have_attributes(bar_number: 0, length: 0)
    end
  end

  it "reads a bar's length from its meter" do
    flow = HeadMusic::Content::Flow.new(meter: "6/8")
    expect(described_class.bar_length(flow, 1)).to eq Rational(3, 4)
  end
end
