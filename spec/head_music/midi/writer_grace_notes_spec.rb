require "spec_helper"

describe HeadMusic::MIDI::Writer do
  subject(:sequence) { render_midi(flow) }

  def abc(body, meter: "4/4")
    HeadMusic::Notation::ABC.parse("X:1\nT:Graced\nM:#{meter}\nL:1/4\nK:C\n#{body}\n")
  end

  def notes
    sequence.notes.map { |note| [note.key, note.on, note.off] }.sort_by { |key, on, _off| [on, key] }
  end

  describe "TupletFixtures.grace_notes_before_downbeat" do
    let(:flow) { TupletFixtures.grace_notes_before_downbeat }

    it "sounds a grace chord on the beat, taking its time from the main note" do
      expect(notes[2, 3]).to eq [[69, 960, 1200], [72, 960, 1200], [67, 1200, 1440]]
    end

    it "re-strikes a main note's key for the next note's grace note" do
      expect(notes[5, 2]).to eq [[67, 1440, 1680], [65, 1680, 1920]]
    end

    it "sounds an acciaccatura as a thirty-second" do
      expect(notes[7, 2]).to eq [[65, 1920, 1980], [64, 1980, 3840]]
    end

    it "holds a tied grace note through its main note" do
      expect(notes.last(2)).to eq [[62, 3840, 3900], [60, 3900, 5760]]
    end

    it "strikes the main note's key once when its last grace note is tied to it" do
      expect(notes.count { |key, on, _off| key == 60 && on >= 3840 }).to eq 1
    end

    it "keeps the division exact" do
      expect(sequence.division).to eq 480
    end
  end

  describe "TupletFixtures.grace_notes_in_pickup" do
    let(:flow) { TupletFixtures.grace_notes_in_pickup }

    it "starts the pickup with its grace note at tick 0" do
      expect(notes.first).to eq [57, 0, 240]
    end

    it "sounds the grace notes on their beats" do
      expect(notes).to eq [[57, 0, 240], [55, 240, 480], [59, 480, 960], [59, 960, 1020], [60, 1020, 2880]]
    end
  end

  describe "an acciaccatura on a flow's first note" do
    let(:flow) do
      abc("C D E F |]").tap { |graced| graced.voices.first.note_events.first.add_grace_note("B3", :eighth, slashed: true) }
    end

    it "falls on tick 0 without shifting the bar" do
      expect([notes.first[1], sequence.tracks.last.events.last.tick]).to eq [0, 1920]
    end

    it "sounds as a thirty-second before the main note" do
      expect(notes.first(2)).to eq [[59, 0, 60], [60, 60, 480]]
    end
  end

  describe "articulation length" do
    let(:flow) { HeadMusic::Content::Flow.new(name: "Articulated") }
    let(:voice) { flow.add_voice }

    it "releases a staccato note at half its value" do
      voice.place("1:1", :whole, "C4").articulate(:staccato)
      expect(notes).to eq [[60, 0, 960]]
    end

    it "shortens the last link of a chain tied over the barline, in the next bar" do
      voice.place("1:1", :half)
      voice.place("1:3", "half tied to half", "C4").articulate(:staccatissimo)
      expect(notes).to eq [[60, 960, 2160]]
    end
  end
end
