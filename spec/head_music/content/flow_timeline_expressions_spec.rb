require "spec_helper"

describe HeadMusic::Content::Flow do
  subject(:flow) { described_class.new(tempo: allegro) }

  let(:allegro) { HeadMusic::Rudiment::Tempo.new("quarter", 120, text: "Allegro") }

  def tempo(beats_per_minute, beat_value = "quarter", **options)
    HeadMusic::Rudiment::Tempo.new(beat_value, beats_per_minute, **options)
  end

  def seconds_at(code)
    flow.conductor.musical_to_clock(flow.position(code)).nanoseconds/1_000_000_000r
  end

  describe "#add_tempo_ramp" do
    it "keeps a ramp between two of the flow's positions, with its target and text" do
      ramp = flow.add_tempo_ramp(from: "12:1", to: "13:1", to_tempo: tempo(80), text: "rit.")
      expect([ramp.from.code, ramp.to.code, ramp.to_tempo, ramp.text]).to eq ["12:1:000", "13:1:000", tempo(80), "rit."]
    end

    it "lists its ramps in order" do
      later = flow.add_tempo_ramp(from: "20:1", to: "21:1")
      earlier = flow.add_tempo_ramp(from: "12:2:480", to: "13:3")
      expect(flow.tempo_ramps).to eq [earlier, later]
    end

    it "takes bar numbers" do
      expect(flow.add_tempo_ramp(from: 3, to: 4).from.code).to eq "3:1:000"
    end

    it "takes a target named in words" do
      expect(flow.add_tempo_ramp(from: 3, to: 4, to_tempo: "adagio").to_tempo.beats_per_minute).to eq 60
    end

    it "allocates the bars it reaches, a pickup included" do
      flow.add_tempo_ramp(from: "0:3", to: "1:1")
      expect(flow.earliest_bar_number).to eq 0
    end

    it "refuses a position in another flow" do
      expect { flow.add_tempo_ramp(from: described_class.new.position("2:1"), to: "3:1") }
        .to raise_error(ArgumentError, /different flow/)
    end
  end

  describe "#add_a_tempo" do
    it "says a tempo" do
      expect(flow.add_a_tempo("14:2").text).to eq "a tempo"
    end

    it "keeps other text" do
      expect(flow.add_a_tempo("14:1", text: "Tempo primo").text).to eq "Tempo primo"
    end

    it "lists its points" do
      point = flow.add_a_tempo("14:1")
      expect(flow.a_tempos).to eq [point]
    end

    it "refuses a second at the same position" do
      flow.add_a_tempo("14:1")
      expect { flow.add_a_tempo("14:1") }.to raise_error(ArgumentError, /overlaps/)
    end
  end

  describe "#add_fermata" do
    it "holds a rhythmic value's span from its position" do
      fermata = flow.add_fermata("4:3", :half)
      expect([fermata.from.code, fermata.to.code, fermata.stretch]).to eq ["4:3:000", "5:1:000", 2]
    end

    it "runs to a later position" do
      expect(flow.add_fermata("4:3", to: "4:4:480").to.code).to eq "4:4:480"
    end

    it "keeps its stretch" do
      expect(flow.add_fermata("4:3", :quarter, stretch: 3).stretch).to eq 3
    end

    it "lists its fermatas" do
      fermata = flow.add_fermata("4:3", :quarter)
      expect(flow.fermatas).to eq [fermata]
    end

    it "raises with both a span and an end" do
      expect { flow.add_fermata("4:3", :quarter, to: "5:1") }.to raise_error(ArgumentError, /not both/)
    end

    it "raises with neither a span nor an end" do
      expect { flow.add_fermata("4:3") }.to raise_error(ArgumentError, /a span or a to: position/)
    end
  end

  describe "the removers" do
    it "removes and answers a ramp by its start" do
      ramp = flow.add_tempo_ramp(from: "12:1", to: "13:1")
      expect([flow.remove_tempo_ramp("12:1"), flow.tempo_ramps]).to eq [ramp, []]
    end

    it "removes and answers an a tempo by its position" do
      point = flow.add_a_tempo("14:1")
      expect([flow.remove_a_tempo("14:1"), flow.a_tempos]).to eq [point, []]
    end

    it "removes and answers a fermata by its start" do
      fermata = flow.add_fermata("4:3", :half)
      expect([flow.remove_fermata("4:3"), flow.fermatas]).to eq [fermata, []]
    end

    it "answers nil where nothing starts" do
      flow.add_fermata("4:3", :half)
      expect(flow.remove_fermata("4:4")).to be_nil
    end

    it "restores the tempo a removed ramp ended in" do
      flow.add_tempo_ramp(from: 3, to: 4, to_tempo: tempo(80))
      flow.remove_tempo_ramp(3)
      expect(flow.tempo_at(5)).to eq allegro
    end
  end

  describe "the invariants" do
    it "raises for ramps that overlap" do
      flow.add_tempo_ramp(from: "12:1", to: "13:3")
      expect { flow.add_tempo_ramp(from: "13:2", to: "14:1") }.to raise_error(ArgumentError, /overlaps/)
    end

    it "raises for fermatas that overlap" do
      flow.add_fermata("4:3", :half)
      expect { flow.add_fermata("4:4", :quarter) }.to raise_error(ArgumentError, /overlaps/)
    end

    it "raises for a tempo change strictly inside a ramp" do
      flow.add_tempo_ramp(from: "12:3", to: "13:3")
      expect { flow.change_tempo(13, tempo(90)) }
        .to raise_error(ArgumentError, "a tempo change at bar 13 falls inside the tempo ramp from 12:3:000 to 13:3:000")
    end

    it "raises for a ramp around a tempo change" do
      flow.change_tempo(13, tempo(90))
      expect { flow.add_tempo_ramp(from: "12:3", to: "13:3") }.to raise_error(ArgumentError, /would hold the tempo set at 13:1/)
    end

    it "raises for an a tempo strictly inside a ramp" do
      flow.add_tempo_ramp(from: 12, to: 14)
      expect { flow.add_a_tempo("13:2") }.to raise_error(ArgumentError, /an a tempo at 13:2:000 falls inside the tempo ramp/)
    end

    it "raises for a ramp around an a tempo" do
      flow.add_a_tempo("13:2")
      expect { flow.add_tempo_ramp(from: 12, to: 14) }.to raise_error(ArgumentError, /would hold the tempo set at 13:2:000/)
    end

    it "raises for a ramp that ends where it begins" do
      expect { flow.add_tempo_ramp(from: 12, to: 12) }.to raise_error(ArgumentError, /ends after it begins/)
    end

    it "raises for a ramp that ends before it begins" do
      expect { flow.add_tempo_ramp(from: 13, to: 12) }.to raise_error(ArgumentError, /ends after it begins/)
    end

    it "raises for a target of no beats per minute" do
      expect { flow.add_tempo_ramp(from: 12, to: 13, to_tempo: tempo(0)) }.to raise_error(ArgumentError, /faster than zero/)
    end

    it "raises for a stretch below 1" do
      expect { flow.add_fermata("4:3", :half, stretch: 0.9) }.to raise_error(ArgumentError, /at least 1/)
    end

    it "allows ramps that touch" do
      flow.add_tempo_ramp(from: 12, to: "13:3")
      expect { flow.add_tempo_ramp(from: "13:3", to: 14) }.not_to raise_error
    end

    it "allows fermatas that touch" do
      flow.add_fermata("4:3", :quarter)
      expect { flow.add_fermata("4:4", :quarter) }.not_to raise_error
    end

    it "allows a fermata inside a ramp" do
      flow.add_tempo_ramp(from: 12, to: 14)
      expect { flow.add_fermata("13:2", :quarter) }.not_to raise_error
    end

    it "allows a fermata across a ramp's end" do
      flow.add_tempo_ramp(from: 12, to: 14)
      expect { flow.add_fermata("13:4", :half) }.not_to raise_error
    end

    it "allows a tempo change at a ramp's start" do
      flow.add_tempo_ramp(from: 12, to: 13)
      expect { flow.change_tempo(12, tempo(100)) }.not_to raise_error
    end

    it "allows a tempo change at a ramp's end" do
      flow.add_tempo_ramp(from: 12, to: 13)
      expect { flow.change_tempo(13, tempo(60)) }.not_to raise_error
    end

    it "allows an a tempo at a ramp's end" do
      flow.add_tempo_ramp(from: 12, to: 13)
      expect { flow.add_a_tempo(13) }.not_to raise_error
    end

    it "allows a meter change inside a ramp" do
      flow.add_tempo_ramp(from: 12, to: 14)
      expect { flow.change_meter(13, "3/4") }.not_to raise_error
    end

    describe "re-checking positions when the meter changes" do
      before { flow.add_fermata("4:4", :quarter) }

      it "refuses a meter that leaves a fermata on a count its bar no longer has" do
        expect { flow.change_meter(4, "3/4") }.to raise_error(ArgumentError, "the meter would leave no 4:4:000 for the fermata from 4:4:000 to 5:1:000")
      end

      it "keeps the meter it had when it refuses" do
        flow.change_meter(4, "3/4")
      rescue ArgumentError
        expect([flow.meter_at(4).to_s, flow.meter_changes]).to eq ["4/4", {}]
      end

      it "keeps a meter change it replaced when it refuses" do
        flow.change_meter(4, HeadMusic::Rudiment::Meter.common_time)
        expect { flow.change_meter(4, "2/4") }.to raise_error(ArgumentError)
        expect(flow.meter_change_at(4).symbol).to eq :common
      end

      it "allows a meter that leaves it in place" do
        expect { flow.change_meter(4, "5/4") }.not_to raise_error
      end

      it "refuses removing a meter change that leaves a fermata on a missing count" do
        flow.remove_fermata("4:4")
        flow.change_meter(4, "5/4")
        flow.add_fermata("4:5", :quarter)
        expect { flow.remove_meter_change(4) }.to raise_error(ArgumentError, /no 4:5:000/)
        expect(flow.meter_at(4).to_s).to eq "5/4"
      end

      it "re-checks ramps and a tempo points too" do
        flow.add_a_tempo("6:4")
        expect { flow.change_meter(6, "3/4") }.to raise_error(ArgumentError, "the meter would leave no 6:4:000 for the a tempo at 6:4:000")
      end
    end
  end

  describe "#tempo_at, the authored tempo" do
    it "answers the start tempo in a bar that begins inside a ramp" do
      flow.add_tempo_ramp(from: 12, to: 14, to_tempo: tempo(80))
      expect([flow.tempo_at(12), flow.tempo_at(13)]).to eq [allegro, allegro]
    end

    it "answers the target at and after the ramp's end" do
      flow.add_tempo_ramp(from: 12, to: 14, to_tempo: tempo(80))
      expect([flow.tempo_at(14), flow.tempo_at(20)]).to eq [tempo(80), tempo(80)]
    end

    it "answers the start tempo in a bar whose downbeat a mid-bar ramp covers" do
      flow.add_tempo_ramp(from: "12:3", to: "14:3", to_tempo: tempo(80))
      expect([12, 13, 14, 15].map { |bar| flow.tempo_at(bar).beats_per_minute }).to eq [120, 120, 120, 80]
    end

    it "answers a ramp's default target, recorded as not written" do
      flow.add_tempo_ramp(from: 12, to: 13, text: "rit.")
      expect(flow.tempo_at(13)).to eq tempo(90, metronome_mark: false)
    end

    it "answers an accelerando's default target" do
      flow.add_tempo_ramp(from: 12, to: 13, text: "accelerando")
      expect(flow.tempo_at(13).beats_per_minute).to eq 160
    end

    it "answers the tempo change at a ramp's end as its target when none was given" do
      flow.add_tempo_ramp(from: 12, to: 13, text: "rit.")
      flow.change_tempo(13, tempo(72))
      expect(flow.tempo_at(13)).to eq tempo(72)
    end

    it "answers the tempo change at a ramp's end after a different given target" do
      flow.add_tempo_ramp(from: 12, to: 13, to_tempo: tempo(80))
      flow.change_tempo(13, tempo(72))
      expect(flow.tempo_at(13)).to eq tempo(72)
    end

    it "answers the restored tempo at and after an a tempo" do
      flow.add_tempo_ramp(from: "12:1", to: "13:1", to_tempo: tempo(80), text: "rit.")
      flow.add_a_tempo("14:1")
      expect([13, 14, 15].map { |bar| flow.tempo_at(bar) }).to eq [tempo(80), allegro, allegro]
    end

    it "restores the tempo in force at the start of the latest ramp" do
      flow.add_tempo_ramp(from: 3, to: 4, to_tempo: tempo(80))
      flow.change_tempo(5, tempo(100))
      flow.add_tempo_ramp(from: 6, to: 7, to_tempo: tempo(60))
      flow.add_a_tempo(8)
      expect(flow.tempo_at(8)).to eq tempo(100)
    end

    it "restores at a ramp's end, in place of its target" do
      flow.add_tempo_ramp(from: 12, to: 13, to_tempo: tempo(80))
      flow.add_a_tempo(13)
      expect(flow.tempo_at(13)).to eq allegro
    end

    it "changes nothing at an a tempo with no ramp before it" do
      flow.change_tempo(3, tempo(100))
      flow.add_a_tempo(5)
      expect(flow.tempo_at(5)).to eq tempo(100)
    end

    it "lets a tempo change win over an a tempo at its downbeat" do
      flow.add_tempo_ramp(from: 12, to: 13, to_tempo: tempo(80))
      flow.add_a_tempo(14)
      flow.change_tempo(14, tempo(66))
      expect(flow.tempo_at(14)).to eq tempo(66)
    end

    it "starts a touching ramp from the first's target" do
      flow.add_tempo_ramp(from: 12, to: 13, to_tempo: tempo(80))
      flow.add_tempo_ramp(from: 13, to: 14)
      expect(flow.tempo_at(14).beats_per_minute).to eq 60
    end

    it "is unchanged by a fermata" do
      flow.add_fermata("4:3", :half)
      expect([flow.tempo_at(4), flow.tempo_at(5)]).to eq [allegro, allegro]
    end

    it "keeps only step changes in #tempo_changes" do
      flow.add_tempo_ramp(from: 12, to: 13, to_tempo: tempo(80))
      expect(flow.tempo_changes).to eq({})
    end
  end

  describe "#sounding_tempo_at" do
    before { flow.add_tempo_ramp(from: "12:1", to: "13:1", to_tempo: tempo(80), text: "rit.") }

    it "interpolates inside a ramp" do
      expect(flow.sounding_tempo_at("12:3").beats_per_minute).to eq 100
    end

    it "answers the authored tempo before a ramp" do
      expect(flow.sounding_tempo_at("11:2")).to eq allegro
    end

    it "answers the target after a ramp" do
      expect(flow.sounding_tempo_at("13:2")).to eq tempo(80)
    end
  end

  describe "#conductor" do
    it "is a Conductor" do
      expect(flow.conductor).to be_a HeadMusic::Time::Conductor
    end

    it "keeps time as the flow's tempo and meter say" do
      flow.change_meter(3, "3/4")
      flow.change_tempo(5, tempo(60))
      expect(seconds_at("6:1")).to eq 4 + 1.5 + 1.5 + 3
    end

    it "starts its clock at the downbeat of a pickup bar" do
      flow.add_voice.place("0:4", :quarter, "C4")
      expect(seconds_at("1:1")).to eq 2
    end

    it "times the story's example" do
      flow.add_tempo_ramp(from: "12:1", to: "13:1", to_tempo: tempo(80), text: "rit.")
      flow.add_a_tempo("14:1")
      flow.add_fermata("4:3", :half)
      expect(flow.conductor.musical_to_clock(flow.position("15:1")).nanoseconds).to eq 30_432_790_649
    end

    it "ramps to a resolved target" do
      flow.add_tempo_ramp(from: 1, to: 2, text: "rit.")
      expect(flow.conductor.tempo_ramps.first.to_tempo).to eq tempo(90, metronome_mark: false)
    end

    it "gives the Conductor musical positions" do
      flow.add_tempo_ramp(from: "1:2", to: 2)
      flow.add_fermata("3:1", :quarter)
      conductor = flow.conductor
      expect([conductor.tempo_ramps.first.from, conductor.fermatas.first.to]).to all(be_a(HeadMusic::Time::MusicalPosition))
    end

    it "restores the tempo at an a tempo in the middle of a bar" do
      flow.add_tempo_ramp(from: 1, to: 2, to_tempo: tempo(60))
      flow.add_a_tempo("2:3")
      expect(seconds_at("3:1") - seconds_at("2:1")).to eq 2 + 1
    end

    it "lengthens the clock through a fermata" do
      flow.add_fermata("1:4", :quarter, stretch: 3)
      expect(seconds_at("2:1")).to eq 1.5 + 1.5
    end

    it "lets a step change win where a ramp ends" do
      flow.add_tempo_ramp(from: 1, to: 2, to_tempo: tempo(80))
      flow.change_tempo(2, tempo(60))
      expect(seconds_at("3:1") - seconds_at("2:1")).to eq 4
    end
  end
end
