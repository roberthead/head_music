require "spec_helper"

describe HeadMusic::MIDI::TrackReader do
  def reader(*bytes, events_before: 0)
    data = bytes.flatten.pack("C*")
    described_class.new(data, 0, data.bytesize, division: 96, events_before: events_before)
  end

  let(:end_of_track) { [0x00, 0xFF, 0x2F, 0x00] }

  it "reads events at their absolute ticks, ending at the end of track" do
    track = reader(0x00, 0x90, 60, 80, 0x60, 0x80, 60, 64, *end_of_track).track
    expect(track.events).to eq [
      HeadMusic::MIDI::NoteOn.new(0, 0, 60, 80), HeadMusic::MIDI::NoteOff.new(96, 0, 60, 64), HeadMusic::MIDI::EndOfTrack.new(96)
    ]
    expect(track.terminated).to be true
  end

  it "reads running status and a note on at velocity 0 as a note off" do
    expect(reader(0x00, 0x91, 60, 80, 0x10, 62, 0).track.events.last).to eq HeadMusic::MIDI::NoteOff.new(16, 1, 62, 0)
  end

  it "reads a program change 1-based" do
    expect(reader(0x00, 0xC2, 52).track.events).to eq [HeadMusic::MIDI::ProgramChange.new(0, 2, 53)]
  end

  it "skips a sysex and the channel messages a flow cannot hold" do
    expect(reader(0x00, 0xF0, 0x02, 0x01, 0xF7, 0x00, 0xB0, 7, 100, 0x00, 0xE0, 0, 64).track.events).to eq []
  end

  it "marks a track with no end of track as unterminated" do
    expect(reader(0x00, 0xC0, 0).track.terminated).to be false
  end

  it "counts every event it reads, skipped ones too" do
    track_reader = reader(0x00, 0xF0, 0x00, 0x00, 0xC0, 0, *end_of_track)
    track_reader.track
    expect(track_reader.event_count).to eq 3
  end

  it "raises at the event over the file's limit, counting earlier tracks' events" do
    stub_const("HeadMusic::MIDI::Reader::MAX_EVENTS", 3)
    expect { reader(0x00, 0xC0, 0, 0x00, 0xC0, 1, events_before: 2).track }.to raise_error(HeadMusic::MIDI::ParseError, "more than 3 events (byte 3)")
  end

  it "raises on a data byte with no running status" do
    expect { reader(0x00, 60, 80).track }.to raise_error(HeadMusic::MIDI::ParseError, /no running status/)
  end
end
