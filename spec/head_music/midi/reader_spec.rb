require "spec_helper"

describe HeadMusic::MIDI::Reader do
  subject(:sequence) { described_class.new(bytes).read }

  def header(format: 1, tracks: 1, division: 480, extra: "")
    ["MThd", 6 + extra.bytesize, format, tracks, division].pack("a4Nnnn") + extra.b
  end

  def track(*bytes)
    body = bytes.flatten.pack("C*")
    ["MTrk", body.bytesize].pack("a4N") + body
  end

  def meta(type, *data)
    [0x00, 0xFF, type, data.length, *data]
  end

  def text(type, string)
    meta(type, *string.b.bytes)
  end

  def note_on(key, delta: 0, channel: 0)
    [delta, 0x90 | channel, key, 100]
  end

  def note_off(key, delta: 0, channel: 0)
    [delta, 0x80 | channel, key, 0]
  end

  def error_for(bytes)
    described_class.new(bytes).read
  rescue HeadMusic::MIDI::ParseError => error
    error
  end

  def spans(notes)
    notes.map { |note| [note.track, note.key, note.on, note.off] }
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

    it "names the sequence" do
      expect(sequence.name).to eq "Air"
    end

    it "finds a track's first text of any given kind" do
      expect(sequence.tracks.last.text(:instrument_name, :lyric, :track_name)).to eq "Voice"
    end

    it "finds no text of a kind a track lacks" do
      expect(sequence.tracks.last.text(:instrument_name)).to be_nil
    end

    it "pairs notes, naming the track of each note on" do
      expect(sequence.tracks.last.notes).to eq [described_class::Note.new(3, 64, 80, 0, 480, 1)]
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

    it "marks each track as terminated" do
      expect(sequence.tracks.map(&:terminated)).to eq [true, true]
    end

    it "freezes the tracks, their events, and their notes" do
      track = sequence.tracks.last
      expect([sequence.tracks, track.events, track.notes]).to all be_frozen
    end
  end

  context "with running status and a note on at velocity 0" do
    let(:bytes) { header + track(0x00, 0x90, 60, 100, 0x00, 62, 100, 0x60, 60, 0, 0x00, 62, 0, end_of_track) }

    it "reads the notes" do
      expect(sequence.tracks.first.notes.map { |note| [note.key, note.on, note.off] }).to eq [[60, 0, 96], [62, 0, 96]]
    end
  end

  context "with running status across a meta event" do
    let(:bytes) { header + track(note_on(60), text(0x01, "x"), 0x60, 60, 0, end_of_track) }

    it "keeps the running status" do
      expect(spans(sequence.notes)).to eq [[0, 60, 0, 96]]
    end
  end

  context "with an MThd longer than 6 bytes" do
    let(:bytes) { header(extra: "\x00\x00") + track(note_on(60), note_off(60, delta: 96), end_of_track) }

    it "reads the tracks after it" do
      expect(spans(sequence.notes)).to eq [[0, 60, 0, 96]]
    end
  end

  context "with more tracks than declared" do
    let(:bytes) { header(tracks: 1) + track(end_of_track) + track(note_on(60), note_off(60, delta: 96), end_of_track) }

    it "reads every track" do
      expect(spans(sequence.notes)).to eq [[1, 60, 0, 96]]
    end
  end

  context "with trailing bytes after the declared tracks" do
    let(:bytes) { header + track(end_of_track) + "\x00\x01\x02".b }

    it "ignores them" do
      expect(sequence.tracks.length).to eq 1
    end
  end

  context "with a truncated chunk after the declared tracks" do
    let(:bytes) { header + track(end_of_track) + ["MTrk", 100].pack("a4N") + end_of_track.pack("C*") }

    it "ignores it" do
      expect(sequence.tracks.length).to eq 1
    end
  end

  context "with a track that ends without an end-of-track" do
    let(:bytes) { header + track(note_on(60), text(0x01, "x"), 0x40, 0xFF, 0x01, 0x00) }

    it "ends the track at the end of its chunk" do
      expect(sequence.tracks.first).to have_attributes(terminated: false, events: [HeadMusic::MIDI::NoteOn.new(0, 0, 60, 100), HeadMusic::MIDI::Text.new(0, :text, "x"), HeadMusic::MIDI::Text.new(64, :text, "")])
    end

    it "ends a note still sounding at the track's last tick" do
      expect(spans(sequence.notes)).to eq [[0, 60, 0, 64]]
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

  context "with pitch bend, aftertouch, and unrecognized meta events" do
    let(:bytes) do
      header + track(
        0x00, 0xE0, 0x00, 0x40, 0x00, 0xA0, 60, 10, 0x00, 0xD0, 20,
        meta(0x7F, 0x00, 0x00, 0x41), meta(0x21, 0x00), meta(0x09, 0x41), end_of_track
      )
    end

    it "skips them" do
      expect(sequence.tracks.first.events).to eq [HeadMusic::MIDI::EndOfTrack.new(0)]
    end
  end

  context "with a sysex between a note on and a data byte" do
    let(:bytes) { header + track(note_on(60), 0x00, 0xF0, 0x01, 0xF7, 0x00, 60, 0, end_of_track) }

    it "clears the running status" do
      expect(error_for(bytes)).to have_attributes(message: /no running status/, offset: 31)
    end
  end

  describe "text" do
    def texts(*strings)
      described_class.new(header + track(*strings.map { |string| text(0x05, string) }, end_of_track)).read.tracks.first.lyrics.map(&:text)
    end

    it "reads valid UTF-8 as UTF-8" do
      expect(texts("Ça")).to eq ["Ça"]
    end

    it "reads other bytes as Windows-1252" do
      expect(texts("caf\xE9", "\x93Ah\x94")).to eq ["café", "“Ah”"]
    end

    it "replaces bytes Windows-1252 leaves undefined, without raising" do
      expect(texts("a\x81b")).to eq ["a�b"]
    end

    it "answers UTF-8 strings" do
      expect(texts("caf\xE9").first.encoding).to eq Encoding::UTF_8
    end

    it "strips NULs" do
      expect(texts("la\x00")).to eq ["la"]
    end
  end

  describe "the sequence name" do
    def read(format:, first_track:)
      described_class.new(header(format: format, tracks: 2) + track(text(0x03, "Name"), *first_track, end_of_track) + track(text(0x03, "Second"), end_of_track)).read
    end

    it "is track 0's name in format 1 when track 0 holds no notes" do
      expect(read(format: 1, first_track: []).name).to eq "Name"
    end

    it "is not track 0's name in format 1 when track 0 holds notes" do
      sequence = read(format: 1, first_track: [note_on(60), note_off(60, delta: 96)])
      expect([sequence.name, sequence.tracks.first.name]).to eq [nil, "Name"]
    end

    it "is the track name in format 0, even with notes" do
      expect(read(format: 0, first_track: [note_on(60), note_off(60, delta: 96)]).name).to eq "Name"
    end

    it "is never a later track's name" do
      expect(read(format: 1, first_track: []).tracks.last.events.first.kind).to eq :track_name
    end
  end

  describe "pairing" do
    def read(*tracks)
      described_class.new(header(tracks: tracks.length) + tracks.map { |events| track(*events, end_of_track) }.join).read
    end

    it "pairs a note off in another track with the note on, which keeps its track" do
      sequence = read([note_on(60), [0x60, 0xFF, 0x01, 0x00]], [note_off(60, delta: 0x60)])
      expect([spans(sequence.tracks.first.notes), sequence.tracks.last.notes]).to eq [[[0, 60, 0, 96]], []]
    end

    it "pairs first in, first out per channel and key" do
      sequence = read([note_on(60), note_on(60, delta: 10), note_on(60, delta: 0, channel: 1), note_off(60, delta: 10), note_off(60, delta: 10)])
      expect(spans(sequence.notes)).to eq [[0, 60, 0, 20], [0, 60, 10, 30], [0, 60, 10, 30]]
    end

    it "skips a note off that matches no sounding note" do
      expect(read([note_off(60), note_on(62), note_off(62, delta: 96)]).notes.map(&:key)).to eq [62]
    end

    it "ends a note never released at its own track's last tick" do
      sequence = read([note_on(60), [0x30, 0xFF, 0x01, 0x00]], [[0x60, 0xFF, 0x01, 0x00]])
      expect(spans(sequence.notes)).to eq [[0, 60, 0, 48]]
    end
  end

  it "raises ArgumentError for input that is not a String" do
    expect { described_class.new([0x4D]) }.to raise_error(ArgumentError, /String/)
  end

  describe "malformed files" do
    it "raises without a header" do
      expect(error_for(track(end_of_track))).to have_attributes(message: /no MThd/, offset: 0)
    end

    it "raises on an empty file" do
      expect(error_for("")).to have_attributes(message: /no MThd/, offset: 0)
    end

    it "raises on an MThd shorter than 6 bytes" do
      expect(error_for(["MThd", 4, 1, 1].pack("a4Nnn") + track(end_of_track))).to have_attributes(message: /shorter than 6/, offset: 4)
    end

    it "raises on an over-long variable-length quantity, naming its offset" do
      expect(error_for(header + track(0x80, 0x80, 0x80, 0x80, 0x00, end_of_track))).to have_attributes(message: /over-long/, offset: 22)
    end

    it "raises on a chunk that overruns the file" do
      bytes = header + ["MTrk", 10].pack("a4N") + end_of_track.pack("C*")
      expect(error_for(bytes)).to have_attributes(message: /overruns/, offset: 14)
    end

    it "raises on an unknown status byte" do
      expect(error_for(header + track(0x00, 0xF4, end_of_track))).to have_attributes(message: /unknown status byte 0xF4/, offset: 23)
    end

    it "raises on a data byte with no running status" do
      expect(error_for(header + track(0x00, 0x3C, 0x40, end_of_track))).to have_attributes(message: /no running status/, offset: 23)
    end

    it "raises on an event cut off by the chunk's end" do
      expect(error_for(header + track(0x00, 0x90, 60))).to have_attributes(message: /unexpected end/, offset: 25)
    end

    it "raises on a delta time with no event before the chunk's end" do
      expect(error_for(header + track(0x00) + track(end_of_track))).to have_attributes(message: /unexpected end/, offset: 23)
    end

    it "raises when the file holds fewer tracks than declared" do
      expect(error_for(header(tracks: 2) + track(end_of_track))).to have_attributes(message: /expected 2 tracks, found 1/, offset: 26)
    end

    it "raises on a division of 0" do
      expect(error_for(header(division: 0) + track(end_of_track))).to have_attributes(message: /division of 0/, offset: 12)
    end

    it "raises on a format above 2" do
      expect(error_for(header(format: 3) + track(end_of_track))).to have_attributes(message: /format 3/, offset: 8)
    end

    it "raises on a tempo of 0" do
      expect(error_for(header + track(meta(0x51, 0, 0, 0), end_of_track))).to have_attributes(message: /tempo of 0/, offset: 23)
    end

    {"tempo" => [0x51, 0x07, 0xA1], "time signature" => [0x58, 4, 2, 24], "key signature" => [0x59, 0]}.each do |name, (type, *data)|
      it "raises on a #{name} shorter than its type" do
        expect(error_for(header + track(meta(type, *data), end_of_track))).to have_attributes(message: /needs #{data.length + 1} bytes, not #{data.length}/, offset: 23)
      end
    end

    it "reads only the prefix of meta data longer than its type" do
      bytes = header + track(meta(0x51, 0x07, 0xA1, 0x20, 0x99), meta(0x58, 3, 2, 24, 8, 0x99), meta(0x59, 1, 0, 0x99), end_of_track)
      expect(described_class.new(bytes).read.tracks.first.events.first(3)).to eq [
        HeadMusic::MIDI::Tempo.new(0, 500_000), HeadMusic::MIDI::TimeSignature.new(0, 3, 4, 24), HeadMusic::MIDI::KeySignature.new(0, 1, false)
      ]
    end

    it "raises on a key signature above 7 fifths" do
      expect(error_for(header + track(meta(0x59, 8, 0), end_of_track))).to have_attributes(message: /8 fifths/, offset: 23)
    end

    it "raises on a key signature below -7 fifths" do
      expect(error_for(header + track(meta(0x59, 0xF8, 0), end_of_track))).to have_attributes(message: /-8 fifths/, offset: 23)
    end

    it "raises on a key signature mode other than 0 or 1" do
      expect(error_for(header + track(meta(0x59, 0, 2), end_of_track))).to have_attributes(message: /mode 2/, offset: 23)
    end

    it "raises on a time-signature numerator of 0" do
      expect(error_for(header + track(meta(0x58, 0, 2, 24, 8), end_of_track))).to have_attributes(message: /numerator of 0/, offset: 23)
    end

    it "raises a notation parse error" do
      expect(error_for(track(end_of_track))).to be_a HeadMusic::Notation::ParseError
    end
  end

  describe "unsupported files" do
    it "raises on format 2" do
      expect(error_for(header(format: 2) + track(end_of_track))).to have_attributes(class: HeadMusic::MIDI::UnsupportedFeatureError, message: /format 2/, offset: 8)
    end

    it "raises on an SMPTE time division" do
      expect(error_for(header(division: 0xE728) + track(end_of_track))).to have_attributes(class: HeadMusic::MIDI::UnsupportedFeatureError, message: /SMPTE/, offset: 12)
    end

    it "raises on a time-signature denominator above 64" do
      expect(error_for(header + track(meta(0x58, 4, 7, 24, 8), end_of_track))).to have_attributes(class: HeadMusic::MIDI::UnsupportedFeatureError, message: /2\^7/, offset: 23)
    end

    it "accepts a denominator of 64" do
      expect(described_class.new(header + track(meta(0x58, 3, 6, 24, 8), end_of_track)).read.tracks.first.events.first.denominator).to eq 64
    end

    it "raises an error that is a parse error" do
      expect(HeadMusic::MIDI::UnsupportedFeatureError.ancestors).to include HeadMusic::MIDI::ParseError
    end
  end

  describe "limits" do
    it "raises on a file longer than MAX_BYTES" do
      stub_const("#{described_class}::MAX_BYTES", 30)
      expect(error_for(header + track(end_of_track) + track(end_of_track))).to have_attributes(message: /longer than 30 bytes/, offset: 30)
    end

    it "raises on more than MAX_EVENTS events, at the event over the limit" do
      stub_const("#{described_class}::MAX_EVENTS", 2)
      expect(error_for(header + track(note_on(60), note_off(60), end_of_track))).to have_attributes(message: /more than 2 events/, offset: 30)
    end

    it "raises on an event beyond MAX_WHOLE_NOTES whole notes" do
      delta = HeadMusic::MIDI::SMF.vlq(4 * described_class::MAX_WHOLE_NOTES + 1).bytes
      expect(error_for(header(division: 1) + track(note_on(60), note_off(60, delta: 0x01), delta, 0xFF, 0x2F, 0x00))).to have_attributes(message: /beyond 10000 whole notes/, offset: 30)
    end

    it "reads an event at MAX_WHOLE_NOTES whole notes" do
      delta = HeadMusic::MIDI::SMF.vlq(4 * described_class::MAX_WHOLE_NOTES).bytes
      expect(described_class.new(header(division: 1) + track(delta, 0xFF, 0x2F, 0x00)).read.tracks.first.events.last.tick).to eq 40_000
    end
  end
end
