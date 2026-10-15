require "spec_helper"

describe HeadMusic::MIDI::Writer do
  subject(:sequence) { render_midi(flow) }

  let(:flow) { HeadMusic::Content::Flow.new(name: "Instruments") }

  def notes(track = sequence.tracks.last)
    track.notes.map { |note| [note.channel, note.key, note.on, note.off] }
  end

  def programs(track = sequence.tracks.last)
    track.program_changes.map { |change| [change.tick, change.channel, change.program] }
  end

  def percussion_part(instrument, sound = instrument)
    flow.add_part(instrument: instrument).tap { |part| part.add_voice.place("1:1", :quarter, sound) }
  end

  describe "a drum part" do
    before { percussion_part("snare_drum", "snare drum") }

    it "strikes channel 10 at its instrument's GM percussion key" do
      expect(notes).to eq [[9, 38, 0, 480]]
    end

    it "writes no program" do
      expect(programs).to eq []
    end
  end

  it "strikes the generic unpitched sound at the default percussion key" do
    flow.add_voice.place("1:1", :quarter, HeadMusic::Rudiment::UnpitchedSound.generic)
    expect(notes).to eq [[9, HeadMusic::MIDI::DEFAULT_PERCUSSION_KEY, 0, 480]]
  end

  it "strikes a drum kit, which names no single key, at the default percussion key" do
    percussion_part("drum_kit")
    expect(notes).to eq [[9, 76, 0, 480]]
  end

  describe "two percussion parts on the same key at once" do
    before do
      percussion_part("snare_drum", "snare drum")
      flow.add_part(instrument: "snare_drum").add_voice.place("1:1", :half, "snare drum")
    end

    it "strikes the shared key once, sounding until the later release" do
      expect(sequence.notes.map { |note| [note.channel, note.key, note.on, note.off] }).to eq [[9, 38, 0, 960]]
    end

    it "keeps a track for each part" do
      expect(sequence.tracks.length).to eq 3
    end
  end

  describe "a part with pitched and unpitched sounds" do
    let(:part) { flow.add_part(instrument: "violin") }

    before do
      voice = part.add_voice
      voice.place("1:1", :quarter, "A4")
      voice.place("1:2", :quarter, "snare drum")
      voice.place("1:3", :quarter, HeadMusic::Rudiment::UnpitchedSound.generic)
    end

    it "sends its unpitched sounds to channel 10 within its own track" do
      expect(notes).to eq [[0, 69, 0, 480], [9, 38, 480, 960], [9, 76, 960, 1440]]
    end

    it "writes its program on its pitched channel only" do
      expect(programs).to eq [[0, 0, 41]]
    end
  end

  describe "programs" do
    it "writes the instrument's GM program at the start of a pitched part" do
      flow.add_part(instrument: "flute").add_voice.place("1:1", :whole, "C5")
      expect(programs).to eq [[0, 0, 74]]
    end

    it "writes 1 for an instrument with no GM program" do
      flow.add_part(instrument: "theremin").add_voice.place("1:1", :whole, "C5")
      expect(programs).to eq [[0, 0, 1]]
    end

    it "writes 1 for a part with no instrument" do
      flow.add_voice.place("1:1", :whole, "C5")
      expect(programs).to eq [[0, 0, 1]]
    end

    context "with the clarinet changing to clarinet in A and then to flute" do
      let(:flow) { MuseScoreFixtures.clarinet_changes.flows.first }

      it "writes a program only where it changes" do
        expect(programs).to eq [[0, 0, 72], [7680, 0, 74]]
      end
    end

    context "with an instrument change before a D.C." do
      let(:flow) do
        NavigationFixtures.da_capo_al_fine.tap do |flow|
          flow.parts.first.change_instrument(1, "flute")
          flow.parts.first.change_instrument(4, "oboe")
        end
      end

      it "restores the first program where the D.C. returns to the start" do
        expect(programs).to eq [[0, 0, 74], [5760, 0, 69], [11_520, 0, 74]]
      end
    end
  end
end
