require "spec_helper"

describe HeadMusic::MIDI::Reader do
  subject(:sequence) { described_class.new(bytes).read }

  def header(tracks: 1, division: 480)
    ["MThd", 6, 1, tracks, division].pack("a4Nnnn")
  end

  def track(*bytes)
    body = bytes.flatten.pack("C*")
    ["MTrk", body.bytesize].pack("a4N") + body
  end

  let(:end_of_track) { [0x00, 0xFF, 0x2F, 0x00] }

  context "with events the writer writes" do
    let(:conductor_events) do
      [
        HeadMusic::MIDI::Text.new(0, :sequence_name, "Air"),
        HeadMusic::MIDI::TimeSignature.new(0, 6, 8, 36),
        HeadMusic::MIDI::KeySignature.new(0, -2, true),
        HeadMusic::MIDI::Tempo.new(0, 666_667),
        HeadMusic::MIDI::EndOfTrack.new(960)
      ]
    end

    let(:bytes) do
      HeadMusic::MIDI::SMF.file(
        division: 960,
        tracks: [
          conductor_events,
          [
            HeadMusic::MIDI::Text.new(0, :track_name, "Voice"),
            HeadMusic::MIDI::ProgramChange.new(0, 3, 53),
            HeadMusic::MIDI::NoteOn.new(0, 3, 64, 80),
            HeadMusic::MIDI::Text.new(0, :lyric, "Ça"),
            HeadMusic::MIDI::NoteOff.new(tick: 480, channel: 3, key: 64),
            HeadMusic::MIDI::EndOfTrack.new(960)
          ]
        ]
      )
    end

    it "reads the format, division, and tracks" do
      expect(sequence).to have_attributes(format: 1, division: 960)
      expect(sequence.tracks.length).to eq 2
    end

    it "reads the conductor's events back as written" do
      expect(sequence.tracks.first.events).to eq conductor_events
    end

    it "names each track" do
      expect(sequence.tracks.map(&:name)).to eq %w[Air Voice]
    end

    it "pairs notes" do
      expect(sequence.tracks.last.notes).to eq [described_class::Note.new(3, 64, 80, 0, 480)]
    end

    it "measures a note" do
      expect(sequence.tracks.last.notes.first.duration).to eq 480
    end

    it "reads lyrics as UTF-8" do
      expect(sequence.tracks.last.lyrics.map(&:text)).to eq ["Ça"]
    end

    it "reads program changes 1-based" do
      expect(sequence.tracks.last.program_changes.map(&:program)).to eq [53]
    end
  end

  context "with running status and a note on at velocity 0" do
    let(:bytes) { header + track(0x00, 0x90, 60, 100, 0x00, 62, 100, 0x60, 60, 0, 0x00, 62, 0, end_of_track) }

    it "reads the notes" do
      expect(sequence.tracks.first.notes.map { |note| [note.key, note.on, note.off] }).to eq [[60, 0, 96], [62, 0, 96]]
    end
  end

  context "with an unknown chunk" do
    let(:bytes) { header + ["XFIH", 2, 1, 2].pack("a4NCC") + track(end_of_track) }

    it "skips it" do
      expect(sequence.tracks.length).to eq 1
    end
  end

  context "with a sysex and a controller" do
    let(:bytes) { header + track(0x00, 0xF0, 0x02, 0x7E, 0xF7, 0x00, 0xB0, 7, 100, end_of_track) }

    it "skips them" do
      expect(sequence.tracks.first.events).to eq [HeadMusic::MIDI::EndOfTrack.new(0)]
    end
  end

  describe "malformed files" do
    def error_for(bytes)
      described_class.new(bytes).read
    rescue HeadMusic::MIDI::ParseError => error
      error
    end

    it "raises without a header" do
      expect(error_for(track(end_of_track))).to have_attributes(message: /no MThd/, offset: 0)
    end

    it "raises on an over-long variable-length quantity, naming its offset" do
      expect(error_for(header + track(0x80, 0x80, 0x80, 0x80, 0x00, end_of_track))).to have_attributes(message: /over-long/, offset: 22)
    end

    it "raises on a chunk that overruns the file" do
      bytes = header + ["MTrk", 10].pack("a4N") + end_of_track.pack("C*")
      expect(error_for(bytes)).to have_attributes(message: /overruns/, offset: 14)
    end

    it "raises on a track with no end-of-track" do
      expect(error_for(header + track(0x00, 0x90, 60, 100))).to have_attributes(message: /missing end-of-track/, offset: 26)
    end

    it "raises on an unknown status byte" do
      expect(error_for(header + track(0x00, 0xF4, end_of_track))).to have_attributes(message: /unknown status byte 0xF4/, offset: 23)
    end

    it "raises on a data byte with no running status" do
      expect(error_for(header + track(0x00, 0x3C, 0x40, end_of_track))).to have_attributes(message: /no running status/, offset: 23)
    end

    it "raises on an event cut off by the chunk's end" do
      expect(error_for(header + track(0x00, 0x90, 60))).to have_attributes(message: /unexpected end/)
    end

    it "raises when the header's track count disagrees" do
      expect(error_for(header(tracks: 2) + track(end_of_track))).to have_attributes(message: /expected 2 tracks, found 1/)
    end

    it "raises a notation parse error" do
      expect(error_for(track(end_of_track))).to be_a HeadMusic::Notation::ParseError
    end
  end
end
