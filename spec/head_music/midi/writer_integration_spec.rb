require "spec_helper"

# Loudness, timing, instruments, and lyrics were built apart, so these
# render one note through more than one of them.
describe HeadMusic::MIDI::Writer do
  subject(:sequence) { render_midi(flow) }

  let(:flow) { HeadMusic::Content::Flow.new(name: "Integration") }

  def notes
    sequence.notes.map { |note| [note.channel, note.key, note.on, note.off, note.velocity] }
  end

  describe "a grace note before an accented forte note" do
    before do
      voice = flow.add_voice
      voice.place_dynamic("1:1", :f)
      voice.place("1:1", :quarter, "C4").articulate(:accent).add_grace_note("D4", :sixteenth, slashed: true)
    end

    it "sounds the grace note at forte, and the main note at forte with the accent" do
      expect(notes).to eq [[0, 62, 0, 60, 96], [0, 60, 60, 480, 112]]
    end
  end

  describe "an unpitched grace note" do
    it "sounds on channel 10 before a drum's note" do
      flow.add_part(instrument: "snare_drum").add_voice.place("1:1", :quarter, "snare drum").add_grace_note("snare drum", :sixteenth, slashed: true)
      expect(notes.map { |note| note.first(4) }).to eq [[9, 38, 0, 60], [9, 38, 60, 480]]
    end

    it "sounds on channel 10 in a pitched part's track" do
      flow.add_voice.place("1:1", :quarter, "C4").add_grace_note("snare drum", :sixteenth, slashed: true)
      expect([sequence.tracks.length, notes.map { |note| note.first(4) }]).to eq [2, [[9, 38, 0, 60], [0, 60, 60, 480]]]
    end
  end

  describe "a lyric on a staccato note" do
    before do
      voice = flow.add_voice
      voice.place("1:1", :quarter, "C4")
      voice.place("1:2", :half, "D4").articulate(:staccato).sing("la")
    end

    it "sings at the note's onset, though the note releases early" do
      lyric = sequence.tracks.last.lyrics.map { |text| [text.tick, text.text] }
      expect([lyric, notes.last[2, 2]]).to eq [[[480, "la"]], [480, 960]]
    end
  end
end
