require "spec_helper"

describe HeadMusic::Analysis::NoteInput do
  let(:note_class) { HeadMusic::Analysis::UnspelledNote }

  def timing(input)
    input.notes.map { |note| [note.number, note.onset, note.duration] }
  end

  describe ".for" do
    context "with tuples" do
      subject(:input) { described_class.for([[60, 0, :quarter], [62, Rational(1, 4), "dotted half", :soprano]]) }

      it "reads key numbers, onsets, and rhythmic values" do
        expect(timing(input)).to eq [[60, 0, Rational(1, 4)], [62, Rational(1, 4), Rational(3, 4)]]
      end

      it "reads an optional voice" do
        expect(input.notes.map(&:voice)).to eq [nil, :soprano]
      end

      it "makes the whole input one bar" do
        expect(input.bar_starts).to eq(1 => 0)
      end

      it "has no flow and no addresses" do
        expect(input.flow).to be_nil
        expect(input.addresses).to eq [nil, nil]
      end

      it "takes a Rational duration as whole notes" do
        expect(described_class.for([[60, 0, Rational(3, 8)]]).notes.first.duration).to eq Rational(3, 8)
      end

      it "refuses an unknown rhythmic value" do
        expect { described_class.for([[60, 0, :bogus]]) }.to raise_error(ArgumentError, /unknown duration/)
      end

      it "refuses an element that is neither a note nor a tuple" do
        expect { described_class.for([60]) }.to raise_error(ArgumentError)
      end
    end

    context "with UnspelledNotes" do
      let(:notes) { [note_class.new(number: 60, onset: 0, duration: 1)] }

      it "keeps them as given" do
        expect(described_class.for(notes).notes).to eq notes
      end
    end

    context "with a NoteInput" do
      let(:input) { described_class.for([[60, 0, :whole]]) }

      it "answers it" do
        expect(described_class.for(input)).to be input
      end
    end

    context "with no notes" do
      subject(:input) { described_class.for([]) }

      it "answers no notes in one bar" do
        expect(input.notes).to eq []
        expect(input.bar_starts).to eq(1 => 0)
      end
    end

    context "with a meter" do
      subject(:input) do
        described_class.for(
          [[60, "1:1", :quarter], [62, "1:2", :quarter], [63, "1:3", :quarter], [65, "1:4", :quarter], [67, "2:1", :half]],
          meter: "4/4"
        )
      end

      it "reads bar:count onsets" do
        expect(input.notes.map(&:onset)).to eq [0, Rational(1, 4), Rational(1, 2), Rational(3, 4), 1]
      end

      it "lays uniform bars over the input" do
        expect(input.bar_starts).to eq(1 => 0, 2 => 1)
      end

      it "counts bar:count in the meter's beat" do
        input = described_class.for([[60, "2:4", :eighth]], meter: "6/8")
        expect(input.notes.first.onset).to eq Rational(9, 8)
      end

      it "numbers the bars from first_bar" do
        input = described_class.for([[67, "0:4", :quarter], [72, "1:1", :whole]], meter: "4/4", first_bar: 0)
        expect(input.notes.map(&:onset)).to eq [Rational(3, 4), 1]
        expect(input.bar_starts).to eq(0 => 0, 1 => 1)
      end
    end

    it "refuses a meter whose bars have no length" do
      expect { described_class.for([[60, 0, :quarter]], meter: "0/4") }.to raise_error(ArgumentError, /no length/)
    end

    it "refuses a bar:count onset without a meter" do
      expect { described_class.for([[60, "1:1", :quarter]]) }.to raise_error(ArgumentError, /meter/)
    end

    it "refuses an onset string that is not bar:count" do
      expect { described_class.for([[60, "soon", :quarter]], meter: "4/4") }.to raise_error(ArgumentError, /unreadable/)
    end

    context "with bars" do
      subject(:input) do
        described_class.for([[67, 0, :quarter], [72, Rational(1, 4), :half], [71, Rational(3, 4), :half]],
          bars: [0, Rational(1, 4), Rational(3, 4)], first_bar: 0)
      end

      it "numbers the listed downbeats from first_bar" do
        expect(input.bar_starts).to eq(0 => 0, 1 => Rational(1, 4), 2 => Rational(3, 4))
      end

      it "places bar:count onsets from the listed downbeats" do
        input = described_class.for([[60, "2:2", :quarter]], meter: "4/4", bars: [0, Rational(1, 4), Rational(5, 4)], first_bar: 0)
        expect(input.notes.first.onset).to eq Rational(3, 2)
      end

      it "refuses a bar:count onset in a bar the list does not hold" do
        expect { described_class.for([[60, "7:1", :quarter]], meter: "4/4", bars: [0, 1]) }.to raise_error(ArgumentError, /bar 7/)
      end

      it "refuses downbeats out of order" do
        expect { described_class.for([], bars: [0, 1, 1]) }.to raise_error(ArgumentError, /increasing/)
      end

      it "refuses an empty list" do
        expect { described_class.for([], bars: []) }.to raise_error(ArgumentError)
      end
    end

    it "refuses bars for a flow, which has its own" do
      flow = HeadMusic::Content::Flow.new
      expect { described_class.for(flow, meter: "3/4") }.to raise_error(ArgumentError, /flow/)
    end
  end

  describe "#bar_at" do
    subject(:input) { described_class.for([], bars: [0, Rational(1, 4), Rational(5, 4)], first_bar: 0) }

    it "answers the bar sounding at an onset" do
      expect([0, Rational(1, 8), Rational(1, 4), 1, Rational(5, 4), 9].map { |onset| input.bar_at(onset) }).to eq [0, 0, 1, 1, 2, 2]
    end

    it "puts an onset before the first downbeat in the first bar" do
      expect(input.bar_at(-1)).to eq 0
    end
  end

  context "with a flow" do
    subject(:input) { described_class.for(flow) }

    context "with a pickup" do
      let(:flow) { LilyPondFixtures.pickup_and_short_final_bar }

      it "sounds the pickup from its first note, as MIDI export does" do
        expect(timing(input)).to eq [[67, 0, Rational(1, 4)], [72, Rational(1, 4), Rational(3, 4)], [71, 1, Rational(1, 2)]]
      end

      it "starts the pickup bar at 0" do
        expect(input.bar_starts).to eq(0 => 0, 1 => Rational(1, 4), 2 => 1)
      end

      it "places each note in its bar" do
        expect(input.notes.map { |note| input.bar_at(note.onset) }).to eq [0, 1, 2]
      end

      it "answers the flow" do
        expect(input.flow).to be flow
      end
    end

    context "with a meter change and a tie across it" do
      let(:flow) { LilyPondFixtures.tie_into_meter_change }

      it "sums the bars across the change" do
        expect(input.bar_starts).to eq(1 => 0, 2 => 1, 3 => Rational(7, 4))
      end

      it "gives a tied chain its whole length" do
        expect(timing(input).find { |number, _, _| number == 69 }).to eq [69, Rational(1, 2), 1]
      end

      it "labels each voice by its part and its place in the part" do
        expect(input.notes.map(&:voice).uniq).to eq [[0, 0], [1, 0]]
      end
    end

    context "with grace notes, rests, and unpitched sounds" do
      let(:flow) do
        HeadMusic::Content::Flow.new.tap do |flow|
          voice = flow.add_voice
          voice.place("1:1", :quarter)
          voice.place("1:2", :quarter, "D4").add_grace_note(%w[C#4 E4], :sixteenth)
          voice.place("1:3", :quarter, HeadMusic::Rudiment::UnpitchedSound.get("snare drum"))
          voice.place("1:4", :quarter, [HeadMusic::Rudiment::UnpitchedSound.get("snare drum"), "F4"])
        end
      end

      it "takes pitched sounds only, with grace notes at the main note's onset taking no time" do
        expect(timing(input)).to eq [
          [61, Rational(1, 4), 0], [64, Rational(1, 4), 0], [62, Rational(1, 4), Rational(1, 4)], [65, Rational(3, 4), Rational(1, 4)]
        ]
      end

      it "addresses each note's sound in the flow's hash" do
        voice_events = ["parts", 0, "voices", 0, "voice_events"]
        expect(input.addresses).to eq [
          [*voice_events, 1, "grace_notes", 0, "sounds", 0], [*voice_events, 1, "grace_notes", 0, "sounds", 1],
          [*voice_events, 1, "sounds", 0], [*voice_events, 3, "sounds", 1]
        ]
      end

      it "addresses the pitch string of each note" do
        hash = flow.to_h
        expect(input.addresses.map { |address| hash.dig(*address) }).to eq %w[C♯4 E4 D4 F4]
      end
    end

    context "with a repeat" do
      let(:flow) do
        HeadMusic::Content::Flow.new.tap do |flow|
          voice = flow.add_voice
          voice.place("1:1", :whole, "C4")
          voice.place("2:1", :whole, "D4")
          flow.bars(2).last.ends_repeat_after_num_plays = 2
        end
      end

      it "reads the bars as written, once each" do
        expect(timing(input)).to eq [[60, 0, 1], [62, 1, 1]]
      end
    end

    context "with no voices" do
      let(:flow) { HeadMusic::Content::Flow.new }

      it "answers no notes" do
        expect(input.notes).to eq []
        expect(input.bar_starts).to eq(1 => 0)
      end
    end
  end
end
