require "spec_helper"

describe HeadMusic::MIDI::NotePairing do
  def sequence(*tracks)
    HeadMusic::MIDI::Reader::Sequence.new(1, 96, tracks.map { |events| HeadMusic::MIDI::Reader::Track.new(events, true) })
  end

  def on(tick, key, channel: 0)
    HeadMusic::MIDI::NoteOn.new(tick, channel, key, 80)
  end

  def off(tick, key, channel: 0)
    HeadMusic::MIDI::NoteOff.new(tick, channel, key, 64)
  end

  def spans(paired)
    paired.tracks.map { |track| track.notes.map { |note| [note.track, note.key, note.on, note.off] } }
  end

  it "pairs a note off with the earliest sounding note on of its channel and key" do
    paired = described_class.new(sequence([on(0, 60), on(10, 60), off(20, 60), off(30, 60)])).sequence
    expect(spans(paired)).to eq [[[0, 60, 0, 20], [0, 60, 10, 30]]]
  end

  it "pairs across tracks, keeping the note in the track of its note on" do
    paired = described_class.new(sequence([on(0, 60)], [off(48, 60)])).sequence
    expect(spans(paired)).to eq [[[0, 60, 0, 48]], []]
  end

  it "keeps channels apart" do
    paired = described_class.new(sequence([on(0, 60), on(0, 60, channel: 1), off(10, 60, channel: 1), off(20, 60)])).sequence
    expect(paired.tracks.first.notes.map { |note| [note.channel, note.off] }).to eq [[0, 20], [1, 10]]
  end

  it "ends a note never released at its own track's last tick" do
    paired = described_class.new(sequence([on(0, 60), HeadMusic::MIDI::EndOfTrack.new(96)], [HeadMusic::MIDI::EndOfTrack.new(192)])).sequence
    expect(spans(paired)).to eq [[[0, 60, 0, 96]], []]
  end

  it "ignores a note off with nothing sounding" do
    expect(spans(described_class.new(sequence([off(0, 60)])).sequence)).to eq [[]]
  end

  it "keeps the tracks' events and format" do
    original = sequence([on(0, 60), off(10, 60)])
    paired = described_class.new(original).sequence
    expect([paired.format, paired.division, paired.tracks.first.events]).to eq [1, 96, original.tracks.first.events]
  end
end
