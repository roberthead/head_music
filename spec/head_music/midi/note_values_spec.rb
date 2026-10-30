require "spec_helper"

describe HeadMusic::MIDI::NoteValues do
  subject(:note_values) { described_class.new(layout) }

  let(:layout) { HeadMusic::MIDI::BarLayout.new([], division: 480, end_tick: 0) }
  let(:bar_meters) { %w[4/4 4/4 4/4] }
  let(:pickup) { nil }

  before do
    allow(layout).to receive(:bars).and_return(bar_list)
  end

  def bar_list
    list = []
    start = 0r
    if pickup
      list << HeadMusic::MIDI::BarLayout::Bar.new(number: 0, start: start, length: pickup, meter: meter(bar_meters.first))
      start += pickup
    end
    bar_meters.each.with_index(1) do |identifier, number|
      length = Rational(meter(identifier).top_number, meter(identifier).bottom_number)
      list << HeadMusic::MIDI::BarLayout::Bar.new(number: number, start: start, length: length, meter: meter(identifier))
      start += length
    end
    list
  end

  def meter(identifier)
    HeadMusic::Rudiment::Meter.get(identifier)
  end

  def value(name)
    HeadMusic::Rudiment::RhythmicDuration.get(name)
  end

  def triplet(name)
    HeadMusic::Rudiment::RhythmicDuration.get(name, tuplet: "3:2")
  end

  def rest_list(from, to)
    note_values.rests(from, to).map { |time, rhythmic_duration| [time, rhythmic_duration.to_s] }
  end

  describe "#rhythmic_duration" do
    it "ties a triplet into the binary value after the beat" do
      expect(note_values.rhythmic_duration(Rational(1, 12), Rational(1, 2))).to eq triplet(:quarter).tied_to(value(:quarter))
    end

    it "keeps a dotted value whole within a bar and ties it over the barline" do
      expect(note_values.rhythmic_duration(Rational(1, 4), Rational(7, 4))).to eq value("dotted half").tied_to(value("dotted half"))
    end

    context "with a pickup bar" do
      let(:pickup) { Rational(1, 4) }

      it "cuts at the barline after it" do
        expect(note_values.rhythmic_duration(0, Rational(1, 2))).to eq value(:quarter).tied_to(value(:quarter))
      end
    end

    context "with a meter change" do
      let(:bar_meters) { %w[4/4 6/8] }

      it "fills each bar by its own meter" do
        expect(note_values.rhythmic_duration(Rational(1, 2), Rational(7, 4))).to eq value(:half).tied_to(value("dotted half"))
      end
    end

    it "raises, naming the bar, when no rhythmic value spans the length" do
      expect { note_values.rhythmic_duration(1, Rational(1025, 1024)) }
        .to raise_error(HeadMusic::MIDI::UnsupportedFeatureError, /in bar 2/)
    end

    context "with a note held across 2,000 bars" do
      let(:bar_meters) { Array.new(2000, "4/4") }

      it "writes one whole note per bar" do
        values = note_values.rhythmic_duration(0, 2000).values

        expect([values.length, values.map(&:to_s).uniq]).to eq [2000, ["whole"]]
      end
    end
  end

  describe "#rests" do
    it "writes a gap of a third as a triplet eighth and a quarter" do
      expect(rest_list(Rational(1, 6), Rational(1, 2))).to eq [[Rational(1, 6), "triplet eighth"], [Rational(1, 4), "quarter"]]
    end

    it "cuts a gap at beats within its bar and fills the empty bar after it with one rest" do
      expect(rest_list(Rational(1, 8), 2)).to eq [[Rational(1, 8), "eighth"], [Rational(1, 4), "quarter"], [Rational(1, 2), "half"], [1r, "whole"]]
    end

    it "writes beat 2 to the barline as a quarter and a half, and beat 3 to the barline as one half" do
      expect([rest_list(Rational(1, 4), 1), rest_list(Rational(1, 2), 1)])
        .to eq [[[Rational(1, 4), "quarter"], [Rational(1, 2), "half"]], [[Rational(1, 2), "half"]]]
    end

    it "writes beat 2 to beat 4 as two quarters" do
      expect(rest_list(Rational(1, 4), Rational(3, 4))).to eq [[Rational(1, 4), "quarter"], [Rational(1, 2), "quarter"]]
    end

    context "with a pickup bar" do
      let(:pickup) { Rational(3, 8) }

      it "counts its beats back from its end" do
        expect(rest_list(0, Rational(1, 4))).to eq [[0r, "eighth"], [Rational(1, 8), "eighth"]]
      end
    end

    context "with a meter change" do
      let(:bar_meters) { %w[4/4 6/8] }

      it "cuts at the beats of each bar's own meter" do
        expect(rest_list(Rational(9, 8), Rational(7, 4))).to eq [[Rational(9, 8), "quarter"], [Rational(11, 8), "dotted quarter"]]
      end
    end

    context "with compound beats" do
      let(:bar_meters) { %w[12/8] }

      it "aligns whole dotted-quarter beats from the downbeat" do
        expect(rest_list(Rational(3, 8), Rational(3, 2))).to eq [[Rational(3, 8), "dotted quarter"], [Rational(3, 4), "dotted half"]]
      end
    end
  end
end
