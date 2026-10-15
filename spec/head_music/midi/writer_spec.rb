require "spec_helper"

describe HeadMusic::MIDI::Writer do
  subject(:sequence) { render_midi(flow) }

  let(:flow) { HeadMusic::Content::Flow.new(name: "Writer") }

  def abc(body, meter: "4/4", title: "Tune")
    HeadMusic::Notation::ABC.parse("X:1\nT:#{title}\nM:#{meter}\nL:1/4\nK:C\n#{body}\n")
  end

  def notes
    sequence.notes.map { |note| [note.key, note.on, note.off] }
  end

  describe "the file" do
    let(:flow) { abc("C D E F | G4 |]") }
    let(:bytes) { described_class.new(flow).to_s }

    it "is format 1, with a conductor track and one track per part" do
      expect(sequence).to have_attributes(format: 1, tracks: have_attributes(length: 2))
    end

    it "counts 480 ticks to the quarter for plain values" do
      expect(sequence.division).to eq 480
    end

    it "is a binary string" do
      expect(bytes.encoding).to eq Encoding::BINARY
    end

    it "is what HeadMusic::MIDI.render and Flow#to_midi answer" do
      expect([HeadMusic::MIDI.render(flow), flow.to_midi]).to eq [bytes, bytes]
    end

    it "names the sequence for the flow" do
      expect(sequence.tracks.first.name).to eq "Tune"
    end

    it "ends every track together, at the end of the last bar" do
      expect(sequence.tracks.map { |track| track.events.last }).to all(eq HeadMusic::MIDI::EndOfTrack.new(3840))
    end
  end

  describe "track names" do
    let(:project) { LayoutFixtures.mixed_ensemble }
    let(:flow) { project.flows.first }

    it "names each part's track for its player" do
      expect(sequence.tracks.drop(1).map(&:name)).to eq %w[Violin Clarinet Singer Flute]
    end

    it "names a part with no player for its instrument" do
      flow.add_part(instrument: "oboe").add_voice.place("1:1", :whole, "C5")
      expect(sequence.tracks.last.name).to eq "oboe"
    end

    it "names a part with neither for its first voice's role" do
      flow.add_part.add_voice(role: "descant").place("1:1", :whole, "C5")
      expect(sequence.tracks.last.name).to eq "descant"
    end

    it "leaves a part with none of them unnamed" do
      flow.add_part.add_voice.place("1:1", :whole, "C5")
      expect(sequence.tracks.last.name).to be_nil
    end

    it "writes a track for a part with no notes" do
      flow.add_part(instrument: "tuba").add_voice.place("1:1", :whole)
      expect(sequence.tracks.last).to have_attributes(name: "tuba", notes: [])
    end
  end

  describe "notes" do
    let(:voice) { flow.add_voice }

    it "strikes each pitch of a chord" do
      voice.place("1:1", :half, %w[C4 E4 G4])
      expect(notes).to eq [[60, 0, 960], [64, 0, 960], [67, 0, 960]]
    end

    it "writes nothing for a rest" do
      voice.place("1:1", :half)
      voice.place("1:3", :half, "D4")
      expect(notes).to eq [[62, 960, 1920]]
    end

    it "sounds a tie within a bar as one note" do
      voice.place("1:1", "half tied to quarter", "C4")
      expect(notes).to eq [[60, 0, 1440]]
    end

    it "sounds a tie over the barline as one note" do
      voice.place("1:3", :whole, "C4")
      voice.place("2:3", :half, "D4")
      expect(notes).to eq [[60, 960, 2880], [62, 2880, 3840]]
    end
  end

  describe "two voices on one key" do
    let(:part) { flow.add_part(instrument: "piano") }
    let(:upper) { part.add_voice }
    let(:lower) { part.add_voice }

    it "re-strikes the key where an inner note begins under a held one, and holds to the later release" do
      lower.place("1:1", :whole, "C4")
      upper.place("1:2", :quarter, "C4")
      expect(notes).to eq [[60, 0, 480], [60, 480, 1920]]
    end

    it "strikes touching notes twice" do
      lower.place("1:1", :half, "C4")
      upper.place("1:3", :half, "C4")
      expect(notes).to eq [[60, 0, 960], [60, 960, 1920]]
    end

    it "strikes notes that begin together once, to the later release" do
      lower.place("1:1", :whole, "C4")
      upper.place("1:1", :half, "C4")
      expect(notes).to eq [[60, 0, 1920]]
    end
  end

  describe "order of play" do
    it "unfolds a repeat" do
      flow = abc("|: C D E F :|")
      expect(render_midi(flow).notes.map { |note| [note.key, note.on] }).to eq(
        [60, 62, 64, 65, 60, 62, 64, 65].each_with_index.map { |key, index| [key, index * 480] }
      )
    end

    context "with a tie into a first ending that the repeat skips" do
      let(:flow) { abc("|: C4- |[1 C4 :|[2 E4 |]") }

      it "sounds the tie through on the first pass and releases it at the barline on the second" do
        expect(notes).to eq [[60, 0, 3840], [60, 3840, 5760], [64, 5760, 7680]]
      end
    end

    context "with a D.S. back into the second half of a tie" do
      let(:flow) { abc("C4- | !segno! C2 D2 | E4 !D.S.!|]") }

      it "strikes the tie's continuation afresh where the jump arrives" do
        expect(notes.select { |key, _on, _off| key == 60 }).to eq [[60, 0, 2880], [60, 5760, 6720]]
      end
    end

    context "with a final note tied over the barline" do
      let(:voice) { flow.add_voice }

      it "plays the bar the tie reaches, to the end of the note" do
        voice.place("1:3", :whole, "C4")
        expect(notes).to eq [[60, 960, 2880]]
        expect(sequence.tracks.first.events.last.tick).to eq 3840
      end
    end
  end

  context "with a pickup" do
    let(:flow) { TupletFixtures.grace_notes_in_pickup }

    it "begins the file at the pickup's first note" do
      expect(notes.map { |key, on, _off| [key, on] }).to eq [[55, 0], [59, 480], [60, 960]]
    end
  end

  describe "empty flows" do
    it "refuses a flow with no voice events" do
      flow.add_voice
      expect { flow.to_midi }.to raise_error(HeadMusic::MIDI::RenderError, /no voice events/)
    end

    it "renders a flow of rests as a file with no notes" do
      flow.add_voice.place("1:1", :whole)
      expect(sequence.notes).to eq []
    end
  end

  describe "channels" do
    let(:instruments) do
      %w[violin viola cello double_bass flute oboe clarinet bassoon french_horn trumpet trombone tuba harp piano celesta glockenspiel]
    end

    def add_parts(names)
      names.each_with_index { |name, index| flow.add_part(instrument: name).add_voice.place("1:1", :whole, HeadMusic::Rudiment::Pitch.get(60 + index)) }
    end

    it "refuses sixteen distinct pitched parts, naming how many it needs" do
      add_parts(instruments)
      expect { flow.to_midi }.to raise_error(HeadMusic::MIDI::RenderError, /needs 16 pitched channels/)
    end

    it "shares one channel among sixteen violin parts, each on its own track" do
      add_parts(["violin"] * 16)
      expect(sequence.tracks.drop(1).map { |track| track.notes.map { |note| [note.channel, note.key] } }).to eq(
        (0...16).map { |index| [[0, 60 + index]] }
      )
    end

    it "gives distinct instruments their own channels, around the percussion channel" do
      add_parts(instruments.first(11))
      expect(sequence.notes.map(&:channel)).to eq [0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11]
    end

    it "strikes one shared key once when two parts sound it together" do
      %w[violin violin].each { |name| flow.add_part(instrument: name).add_voice.place("1:1", :whole, "C4") }
      expect(sequence.notes.map { |note| [note.channel, note.key, note.on, note.off] }).to eq [[0, 60, 0, 1920]]
    end
  end

  context "when transposed" do
    let(:flow) { MuseScoreFixtures.clarinet_changes.flows.first }

    it "sounds each written pitch through the instrument in force at its bar" do
      sequence = render_midi(flow, transposed: true)
      expect(sequence.notes.map(&:key)).to eq [58, 60, 61, 62, 67, 69]
    end

    it "sounds the pitches as they are when not transposed" do
      expect(sequence.notes.map(&:key)).to eq [60, 62, 64, 65, 67, 69]
    end

    it "keeps the key signature concert" do
      sequence = render_midi(flow, transposed: true)
      expect(sequence.tracks.first.of(HeadMusic::MIDI::KeySignature).map(&:fifths)).to eq [0]
    end
  end

  describe "determinism" do
    let(:flow) { NavigationFixtures.da_capo_al_fine }

    it "renders the same bytes twice" do
      first = flow.to_midi
      expect(flow.to_midi).to eq first
    end

    it "renders the same bytes after a round trip through the flow's hash" do
      expect(HeadMusic::Content::Flow.from_h(flow.to_h).to_midi).to eq flow.to_midi
    end
  end
end
